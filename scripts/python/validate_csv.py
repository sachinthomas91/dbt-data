import csv

# Prompt the user to enter the CSV file path from the root of the project
csv_path = input("Enter the CSV file path from root (seeds/<file_name.csv>) : ")

# Open the specified CSV file with UTF-8 encoding
with open(csv_path, encoding='utf-8') as f:
    reader = csv.reader(f)
    # Read the header row to determine the expected number of columns
    header = next(reader)
    expected_len = len(header)
    print(f"Header columns: {header}")
    errors = 0
    # Iterate through each row and check for column count mismatches
    for i, row in enumerate(reader, start=2):
        if len(row) != expected_len:
            print(f"Row {i} has {len(row)} columns, expected {expected_len}: {row}")
            errors += 1
        if errors >= 20:
            print("...more errors truncated...")
            break
    # Print summary of results
    if errors == 0:
        print("No row length errors found!")
    else:
        print(f"Total rows with errors: {errors}")
