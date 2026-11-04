with open('data/vectors_levels.json', 'r', encoding='utf-8') as f:
    content = f.read()

import re
new_content = re.sub(r'\$\$\$\$+', '$$', content)

with open('data/vectors_levels.json', 'w', encoding='utf-8') as f:
    f.write(new_content)

print('done')
