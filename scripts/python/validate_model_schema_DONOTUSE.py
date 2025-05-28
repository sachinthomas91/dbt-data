import os
import re
import sys
import yaml
import glob
from typing import Set, Dict, List

# Pedning fixes. Work in progress. Do not use yet.

def extract_columns_from_yaml(yaml_file: str) -> Set[str]:
    """Extract column names from a YAML schema file."""
    try:
        with open(yaml_file, 'r', encoding='utf-8') as f:
            schema = yaml.safe_load(f)
        
        if not schema:
            print(f"⚠️ Warning: Empty or invalid YAML file: {yaml_file}")
            return set()
        
        columns = set()
        model_found = False
        
        # Look for column definitions in the YAML
        for model in schema.get('models', []):
            # Check if this is the right model definition
            if 'name' in model:
                model_found = True
                print(f"\nDebug - YAML File: {yaml_file}")
                print(f"Processing model: {model['name']}")
            
            for column in model.get('columns', []):
                col_name = column.get('name', '').strip()
                if col_name:  # Only add non-empty column names
                    columns.add(col_name.lower())  # Convert to lowercase for consistency
                    
        if not model_found:
            print(f"⚠️ Warning: No model definitions found in {yaml_file}")
        
        print(f"Found YAML columns: {sorted(columns)}")
        return columns
    except Exception as e:
        print(f"❌ Error processing YAML file {yaml_file}: {str(e)}")
        return set()

def find_corresponding_files(base_path: str) -> List[Dict[str, str]]:
    """Find corresponding SQL and YAML files.
    
    Looks for schema files in a 'schema' subdirectory within the same model category.
    For example:
    - SQL file: models/staging/olist/stg_closed_deals.sql
    - Schema file: models/staging/schema/olist/stg_closed_deals.yml
    """
    pairs = []
    
    # Find all SQL files in the models directory
    sql_files = glob.glob(os.path.join(base_path, 'models', '**', '*.sql'), recursive=True)
    
    for sql_file in sql_files:
        # Get the model name without extension
        model_name = os.path.splitext(os.path.basename(sql_file))[0]
        
        # Get the relative path from the models directory
        models_dir = os.path.join(base_path, 'models')
        rel_path = os.path.relpath(sql_file, models_dir)
        model_category = os.path.dirname(rel_path).split(os.sep)[0]  # e.g., 'staging'
        
        # Look for corresponding YAML file in the schema directory
        # First try the exact parallel structure with 'schema' folder
        yaml_patterns = [
            # Pattern 1: models/staging/schema/olist/stg_closed_deals.yml
            os.path.join(base_path, 'models', model_category, 'schema', '*', f'{model_name}.yml'),
            # Pattern 2: models/staging/schema/stg_closed_deals.yml
            os.path.join(base_path, 'models', model_category, 'schema', f'{model_name}.yml'),
            # Pattern 3: Legacy/fallback pattern
            os.path.join(base_path, 'models', '**', 'schema', f'*{model_name}.yml')
        ]
        
        for pattern in yaml_patterns:
            yaml_files = glob.glob(pattern, recursive=True)
            if yaml_files:
                pairs.append({
                    'sql': sql_file,
                    'yaml': yaml_files[0],
                    'model_name': model_name,
                    'category': model_category
                })
                break
        else:
            print(f"⚠️ Warning: No schema file found for {model_name} in {model_category}")
    
    return pairs

def validate_models_and_schemas(base_path: str):
    """Main validation function."""
    print("Starting validation of models and schemas...")
    
    file_pairs = find_corresponding_files(base_path)
    
    for pair in file_pairs:
        print(f"\nValidating {pair['model_name']}...")
        print(f"SQL file: {pair['sql']}")
        print(f"YAML file: {pair['yaml']}")
        
        sql_columns = extract_columns_from_sql(pair['sql'])
        yaml_columns = extract_columns_from_yaml(pair['yaml'])
        
        # Compare sets
        missing_in_yaml = sql_columns - yaml_columns
        missing_in_sql = yaml_columns - sql_columns
        
        if not missing_in_yaml and not missing_in_sql:
            print("✅ All columns match!")
        else:
            print("\n⚠️ Discrepancies found:")
            if missing_in_yaml:
                print("\nColumns in SQL but missing in YAML:")
                for col in sorted(missing_in_yaml):
                    print(f"  - {col}")
            
            if missing_in_sql:
                print("\nColumns in YAML but missing in SQL:")
                for col in sorted(missing_in_sql):
                    print(f"  - {col}")

def validate_schema(sql_file: str, yaml_file: str) -> List[str]:
    """Validate that SQL model columns match YAML schema definitions."""
    issues = []
      # Extract columns from SQL file
    sql_columns = extract_columns_from_sql(sql_file)
    
    # Extract columns from YAML
    yaml_columns = extract_columns_from_yaml(yaml_file)
    
    # Compare columns
    sql_set = {col.lower() for col in sql_columns}
    yaml_set = {col.lower() for col in yaml_columns}
    
    # Check for missing columns in YAML
    missing_in_yaml = sql_set - yaml_set
    if missing_in_yaml:
        issues.append(f"❌ Columns in SQL but missing in YAML: {', '.join(missing_in_yaml)}")
    
    # Check for extra columns in YAML
    extra_in_yaml = yaml_set - sql_set
    if extra_in_yaml:
        issues.append(f"❌ Columns in YAML but missing in SQL: {', '.join(extra_in_yaml)}")
    
    return issues

def extract_columns_from_sql(sql_file: str) -> Set[str]:
    """Extract column names from a SQL file."""
    with open(sql_file, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    # Remove comments to avoid false matches
    sql_content = re.sub(r'--.*$', '', sql_content, flags=re.MULTILINE)
    sql_content = re.sub(r'/\*.*?\*/', '', sql_content, flags=re.DOTALL)
    
    # Find all SELECT statements, focusing on the main or final CTE
    select_pattern = r"(?:with\s+.*\s+as\s*\([^)]+\)\s*,\s*)*(?:select|SELECT)\s+(.*?)(?:\s+from|\s+FROM|$)"
    matches = list(re.finditer(select_pattern, sql_content, re.DOTALL))
    
    if not matches:
        print(f"⚠️ Warning: No SELECT statement found in {sql_file}")
        return set()
    
    # Get the last SELECT statement (usually the main query or final CTE)
    last_select = matches[-1].group(1)
    
    # Extract column names or aliases
    columns = set()
    
    # Split into individual column expressions, handling nested functions
    depth = 0
    current = []
    
    for char in last_select:
        if char == '(':
            depth += 1
        elif char == ')':
            depth -= 1
        elif char == ',' and depth == 0:
            col_expr = ''.join(current).strip()
            if col_expr:
                columns.update(extract_column_name(col_expr))
            current = []
        else:
            current.append(char)
    
    # Don't forget the last column
    if current:
        col_expr = ''.join(current).strip()
        if col_expr:
            columns.update(extract_column_name(col_expr))
    
    # Debug output
    print(f"\nDebug - SQL File: {sql_file}")
    print(f"Found columns: {sorted(columns)}")
    
    return {col.lower() for col in columns if col}

def extract_column_name(col_expr: str) -> Set[str]:
    """Extract the column name or alias from a SQL column expression."""
    col_expr = col_expr.strip()
    result = set()
    
    # Handle CASE statements
    if col_expr.upper().startswith('CASE'):
        case_match = re.search(r'(?i)CASE\s+.*\s+END\s+as\s+([a-zA-Z_][a-zA-Z0-9_]*)', col_expr)
        if case_match:
            result.add(case_match.group(1))
        return result
    
    # Handle regular AS aliases
    if ' as ' in col_expr.lower():
        # Split on AS but keep quoted strings intact
        alias = col_expr.lower().split(' as ')[-1].strip()
        # Remove any remaining quotes or backticks
        alias = alias.strip('`"\' ')
        result.add(alias)
        return result
    
    # Handle custom functions like DATE_TRUNC, CAST, etc.
    if '(' in col_expr:
        func_match = re.search(r'(?i).*\)\s+as\s+([a-zA-Z_][a-zA-Z0-9_]*)', col_expr)
        if func_match:
            result.add(func_match.group(1))
            return result
    
    # Handle qualified names (table.column)
    parts = col_expr.split('.')
    col_name = parts[-1].strip('`"\' ')
    
    # Ignore SELECT * or table.*
    if col_name != '*':
        result.add(col_name)
    
    return result

# Removed duplicate implementation of extract_columns_from_yaml as it's already defined above

def main():
    base_path = os.getcwd()
    file_pairs = find_corresponding_files(base_path)
    
    total_issues = 0
    
    for pair in file_pairs:
        print(f"\nValidating {pair['model_name']} ({pair['category']})...")
        issues = validate_schema(pair['sql'], pair['yaml'])
        
        if issues:
            total_issues += len(issues)
            print('\n'.join(issues))
        else:
            print("✅ Schema validation passed!")
    
    if total_issues > 0:
        print(f"\n⚠️ Found {total_issues} issue(s) in total.")
        sys.exit(1)
    else:
        print("\n✅ All schemas are valid!")
        sys.exit(0)

if __name__ == "__main__":
    # Get the absolute path to the dbt project
    project_path = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    
    print(f"Checking dbt project at: {project_path}")
    validate_models_and_schemas(project_path)
