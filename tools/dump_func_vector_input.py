#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Dump input questions for functions and vector."""
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

for filename in ['functions_levels.json', 'vector_levels.json']:
    path = os.path.join(r'E:\MathGates-main\data', filename)
    data = json.load(open(path, 'r', encoding='utf-8'))
    print("=" * 80)
    print("FILE:", filename)
    print("=" * 80)
    idx = 0
    for sec_key, sec in data.items():
        for q in sec.get('levels', []):
            if q.get('type') == 'input':
                idx += 1
                print(f"\n--- [{idx}] section={sec_key} ---")
                print("name:", q.get('name'))
                print("q:", q.get('q'))
                print("ans:", q.get('ans'))
                print("hint:", q.get('hint'))
                print("explain:", q.get('explain'))
                print("keys:", list(q.keys()))
