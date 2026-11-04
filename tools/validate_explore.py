#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Structural validation for explore questions."""
import glob
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
DATA = r'E:\MathGates-main\data'
THREE_D = {'space_levels.json', 'solid_basic_levels.json'}
CALL = re.compile(r'([A-Za-z_][A-Za-z_0-9]*)\s*\(')
OK_FN_2D = {'sqrt', 'abs', 'sin', 'cos', 'tan'}

problems = []
count = 0
for path in sorted(glob.glob(os.path.join(DATA, '*_levels.json'))):
    fname = os.path.basename(path)
    data = json.load(open(path, 'r', encoding='utf-8'))
    for sec_key, sec in data.items():
        if not isinstance(sec, dict):
            continue
        for q in sec.get('levels', []):
            if not isinstance(q, dict) or q.get('type') != 'explore':
                continue
            count += 1
            sc = q.get('scene')
            if not isinstance(sc, dict):
                problems.append((fname, q.get('name'), 'scene is not dict'))
                continue
            if not any(k in sc for k in ('sliders', 'drag', 'break')):
                problems.append((fname, q.get('name'), 'scene has no interactive block'))
            opts = q.get('opts')
            if not (isinstance(opts, list) and opts):
                problems.append((fname, q.get('name'), 'no follow-up opts'))
            elif not isinstance(q.get('ans'), int) or not (0 <= q['ans'] < len(opts)):
                problems.append((fname, q.get('name'), 'bad ans index'))
            if fname not in THREE_D:
                for rd in sc.get('readouts', []) or []:
                    e = str(rd.get('expr', '')) if isinstance(rd, dict) else ''
                    if any(t in e for t in ['<', '>', '==', '!=', '"', "'", '[', ']', ':', ',', ' if ', 'else']):
                        problems.append((fname, q.get('name'), 'bad readout: ' + e[:50]))
                    for fn in CALL.findall(e):
                        if fn not in OK_FN_2D:
                            problems.append((fname, q.get('name'), 'bad fn %s in %s' % (fn, e[:50])))

print(f"explore questions: {count}")
print(f"problems         : {len(problems)}")
for p in problems[:60]:
    print("  ", p)
