#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Dump all input questions of given *_levels.json files.

Usage: python dump_inputs.py vectors_levels.json conics_levels.json
"""
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

DATA = r'E:\MathGates-main\data'

for filename in sys.argv[1:]:
    path = os.path.join(DATA, filename)
    data = json.load(open(path, 'r', encoding='utf-8'))
    print("=" * 80)
    print("FILE:", filename)
    print("=" * 80)
    idx = 0
    for sec_key, sec in data.items():
        if not isinstance(sec, dict):
            continue
        for q in sec.get('levels', []):
            if q.get('type') != 'input':
                continue
            idx += 1
            print(f"\n--- [{idx}] section={sec_key} ---")
            print("name:", q.get('name'))
            print("q:", q.get('q'))
            print("ans:", q.get('ans'))
            print("tol:", q.get('tol'))
            print("hint:", q.get('hint'))
            print("explain:", q.get('explain'))
            print("opts:", q.get('opts'))
            print("keys:", list(q.keys()))
    print(f"\n>>> total input in {filename}: {idx}\n")
