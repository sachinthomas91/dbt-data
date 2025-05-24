import os
import pandas as pd
from unidecode import unidecode

# Prompt for file path
csv_path = input("Enter the CSV file path from root (seeds/<file_name.csv>) : ")

if not os.path.exists(csv_path):
    print(f"File not found: {csv_path}")
    exit(1)

# Generate a unique output path that does not overwrite existing files
base, ext = os.path.splitext(csv_path)
output_path = f"{base}_utf8{ext}"
count = 1
while os.path.exists(output_path):
    output_path = f"{base}_utf8_{count}{ext}"
    count += 1

# Load CSV (try 'utf-8' first, fallback to 'latin1' if needed)
try:
    df = pd.read_csv(csv_path, encoding='utf-8')
except UnicodeDecodeError:
    df = pd.read_csv(csv_path, encoding='latin1')
except Exception as e:
    print(f"Error reading CSV: {e}")
    exit(1)

def clean_text(text):
    if pd.isna(text):
        return text
    clean = unidecode(str(text))
    clean = ''.join(c for c in clean if 32 <= ord(c) <= 126)
    return clean

# Clean all columns in the DataFrame (Text columns only)
for col in df.select_dtypes(include=['object']).columns:
    df[col] = df[col].apply(clean_text)

try:
    df.to_csv(output_path, index=False, encoding='utf-8')
    print(f"Cleaned UTF-8 CSV written to: {output_path}")
except Exception as e:
    print(f"Error writing CSV: {e}")