#!/usr/bin/env python3
import csv
import sys
import re

def generate_markdown_table(csv_file: str) -> str:
    expected_columns = {'operator', 'ip', 'location'}
    headers = ["Operator", "Root IP", "Location"]

    peers = []
    with open(csv_file, 'r', newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)

        if not expected_columns.issubset(set(reader.fieldnames)):
            raise Exception(f"CSV must have columns: {', '.join(expected_columns)}")

        for row in reader:
            peers.append({
                'operator': row['operator'].strip(),
                'ip': row['ip'].strip(),
                'location': row['location'].strip(),
            })

    # Sort by operator name for consistency
    # TODO: maybe? discuss in PR
    #peers.sort(key=lambda p: p['operator'].lower())

    max_operator_len = len(headers[0])
    max_ip_len = len(headers[1])
    max_location_len = len(headers[2])

    for peer in peers:
        max_operator_len = max(max_operator_len, len(peer['operator']))
        max_ip_len = max(max_ip_len, len(peer['ip']))
        max_location_len = max(max_location_len, len(peer['location']))

    # Generate aligned table
    def format_row(col1: str, col2: str, col3: str) -> str:
        return f"| {col1.ljust(max_operator_len)} | {col2.ljust(max_ip_len)} | {col3.ljust(max_location_len)} |"

    lines = [
        format_row(headers[0], headers[1], headers[2]),
        f"| {'-' * max_operator_len} | {'-' * max_ip_len} | {'-' * max_location_len} |"
    ]

    for peer in peers:
        lines.append(format_row(peer['operator'], peer['ip'], peer['location']))

    return "\n".join(lines)

def update_readme_table(readme_file: str, new_table: str) -> bool:
    with open(readme_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern to match the seed peers section and its table
    # Matches from the section header through the table content
    pattern = r'(## Mainnet Non-Validator Seed Peers\s*\n.*?:\s*\n\s*\n)(\|.*?\n(?:\|.*?\n)*)'

    if not re.search(r'## Mainnet Non-Validator Seed Peers', content):
        print("Could not find 'Mainnet Non-Validator Seed Peers' section", file=sys.stderr)
        return False

    new_content = re.sub(pattern, lambda m: m.group(1) + new_table.strip() + "\n", content, flags=re.DOTALL)
    if new_content == content:
        print("No changes", file=sys.stderr)
        return False

    with open(readme_file, 'w', encoding='utf-8') as f:
        f.write(new_content)

    return True

def main():
    (csv_file, readme_file) = sys.argv[1:]

    new_table = generate_markdown_table(csv_file)

    if update_readme_table(readme_file, new_table):
        print(f"Successfully updated {readme_file}")
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
