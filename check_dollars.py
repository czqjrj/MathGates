with open('data/vectors_levels.json', 'r', encoding='utf-8') as f:
    content = f.read()

# Look for issues
import re
# Find 4 or more consecutive $ 
matches = re.findall(r'\${4,}', content)
print('Four plus $ signs:', len(matches))

# Find $$ that might be malformed
# Look for patterns like $$$$ or $$ $$ with issues
# Check specific locations
for m in re.finditer(r'\$\$\$\$', content):
    start = max(0, m.start()-60)
    end = min(len(content), m.end()+60)
    print('---')
    print(content[start:end])
    print('---')
