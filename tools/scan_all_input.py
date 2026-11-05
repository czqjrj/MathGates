#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Global scan: list input question counts in every *_levels.json."""
import json
import os
import sys
import glob

sys.stdout.reconfigure(encoding='utf-8')

DATA = r'E:\MathGates-main\data'
rows = []
for path in sorted(glob.glob(os.path.join(DATA, '*_levels.json'))):
    try:
        data = json.load(open(path, 'r', encoding='utf-8'))
    except Exception as e:
        print("SKIP", os.path.basename(path), e)
        continue
    counts = {}
    for sec in data.values():
        if not isinstance(sec, dict):
            continue
        for q in sec.get('levels', []):
            t = q.get('type', 'choice')
            counts[t] = counts.get(t, 0) + 1
    inp = counts.get('input', 0)
    if inp:
        rows.append((os.path.basename(path), inp, counts))

print("=" * 70)
print("仍含 input（填空题）的文件:")
print("=" * 70)
if not rows:
    print("无！所有 *_levels.json 的 input 题均已清零。")
for name, inp, counts in rows:
    print(f"  {name}: input={inp}  {counts}")
print("=" * 70)
print(f"涉及文件数: {len(rows)}")
