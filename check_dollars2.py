with open('data/vectors_levels.json', 'r', encoding='utf-8') as f:
    content = f.read()

import re
# Find 4 or more consecutive $ 
matches = re.findall(r'\${4,}', content)
print('Four plus $ signs:', len(matches))

# Find $$ that might be malformed
for i,m in enumerate(re.finditer(r'\$\$\$\$', content)):
    start = max(0, m.start()-40)
    end = min(len(content), m.end()+40)
    print(f'---{i}---')
    print(content[start:end].replace('\n',' '))
    print()
