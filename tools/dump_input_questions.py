#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Dump all input questions (full content) to a text file for conversion."""

import json
import os
import sys

files = [
    'set_logic_levels.json',
    'function_lab_levels.json',
    'sequences_levels.json',
    'inequalities_levels.json',
    'trig_levels.json',
]

out = []
for filename in files:
    filepath = os.path.join(r'E:\MathGates-main\data', filename)
    data = json.load(open(filepath, 'r', encoding='utf-8'))
    out.append("=" * 80)
    out.append("FILE: " + filename)
    out.append("=" * 80)
    idx = 0
    for sec_key, section in data.items():
        for q in section.get('levels', []):
            if q.get('type') == 'input':
                idx += 1
                out.append(f"\n--- [{idx}] section={sec_key} ---")
                out.append("name: " + str(q.get('name')))
                out.append("q: " + str(q.get('q')))
                out.append("ans: " + str(q.get('ans')))
                out.append("tol: " + str(q.get('tol')))
                out.append("hint: " + str(q.get('hint')))
                out.append("explain: " + str(q.get('explain')))
                out.append("opts: " + str(q.get('opts')))

with open(r'E:\MathGates-main\tools\_input_dump.txt', 'w', encoding='utf-8') as f:
    f.write("\n".join(out))

print("dumped", len(out), "lines")
