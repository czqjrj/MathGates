#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""针对 ineq_basic 的定向自检：滑块数、opts/ans、readout 白名单与数值可算性。"""
import json
import math
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
PATH = r'E:\MathGates-main\data\inequalities_levels.json'
CALL = re.compile(r'([A-Za-z_][A-Za-z_0-9]*)\s*\(')
OK = {'sqrt', 'abs', 'sin', 'cos', 'tan'}
TOKENS = ['<', '>', '==', '!=', '"', "'", '[', ']', ':', ',', ' if ', 'else']

data = json.load(open(PATH, encoding='utf-8'))
sec = data['ineq_basic']
bad = []

for q in sec['levels']:
    sc = q.get('scene', {})
    sl = sc.get('sliders', [])
    if len(sl) < 2:
        bad.append((q['name'], 'fewer than 2 sliders'))
    if not q.get('opts') or not isinstance(q.get('ans'), int) or not (0 <= q['ans'] < len(q['opts'])):
        bad.append((q['name'], 'bad opts/ans'))
    if q.get('type') != 'explore':
        bad.append((q['name'], 'not explore'))
    for rd in sc.get('readouts', []):
        e = str(rd.get('expr', ''))
        for t in TOKENS:
            if t in e:
                bad.append((q['name'], 'token %r in %s' % (t, e)))
        for fn in CALL.findall(e):
            if fn not in OK:
                bad.append((q['name'], 'fn %s in %s' % (fn, e)))

    combos = [{s['name']: float(s['value']) for s in sl}]
    for s in sl:
        for pick in ('min', 'max'):
            combos.append({x['name']: (float(x[pick]) if x['name'] == s['name'] else float(x['value'])) for x in sl})

    for combo in combos:
        env = dict(combo)
        env.update({'sqrt': math.sqrt, 'abs': abs, 'sin': math.sin,
                    'cos': math.cos, 'tan': math.tan})
        for rd in sc.get('readouts', []):
            e = str(rd.get('expr', ''))
            try:
                v = eval(e.replace('^', '**'), {'__builtins__': {}}, env)
                if not math.isfinite(float(v)):
                    bad.append((q['name'], 'nonfinite %s @ %s' % (e, combo)))
            except Exception as ex:
                bad.append((q['name'], 'eval error %s @ %s -> %s' % (e, combo, ex)))

print('questions:', len(sec['levels']))
print('problems :', len(bad))
for x in bad:
    print('  ', x)
