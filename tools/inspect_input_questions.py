#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Inspect actual input questions structure across chapters"""

import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

files = [
    'set_logic_levels.json',
    'function_lab_levels.json',
    'sequences_levels.json',
    'inequalities_levels.json',
    'trig_levels.json',
]

for filename in files:
    filepath = os.path.join(r'E:\MathGates-main\data', filename)
    data = json.load(open(filepath, 'r', encoding='utf-8'))
    print("=" * 70)
    print(filename)
    print("=" * 70)
    count = 0
    for sec_key, section in data.items():
        for q in section.get('levels', []):
            if q.get('type') == 'input':
                count += 1
                if count <= 2:
                    print(f"\n[section={sec_key}] id={q.get('id')} name={q.get('name')}")
                    print("  keys:", list(q.keys()))
                    print("  q:", str(q.get('q'))[:120])
                    print("  answers:", str(q.get('answers'))[:100])
    print(f"\n  -> total input: {count}\n")
