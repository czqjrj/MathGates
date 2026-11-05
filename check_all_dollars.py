import json
import re
from pathlib import Path

issues = []
for p in Path('data').glob('*.json'):
    try:
        with open(p, 'r', encoding='utf-8') as f:
            content = f.read()
        try:
            data = json.loads(content)
        except Exception as e:
            issues.append((str(p), f'JSON parse error: {e}'))
            continue
        dollar_count = content.count('$$')
        if dollar_count % 2 != 0:
            issues.append((str(p), f'Odd number of $$: {dollar_count}'))
        # Check for 4+ consecutive
        if re.search(r'\${4,}', content):
            issues.append((str(p), f'Has 4+ consecutive $'))
    except Exception as e:
        issues.append((str(p), f'Error: {e}'))

for i in issues:
    print(i[0], ':', i[1])
print('done')
