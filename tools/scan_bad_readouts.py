#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Scan explore readouts for expressions the Godot NumExpr/LabPlane parser cannot handle.

LabPlane supports: numbers, slider names, + - * / ^ ( ), sqrt abs sin cos tan (degrees), pi/e.
"""
import glob
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

DATA = r'E:\MathGates-main\data'
ALLOWED = {'sqrt', 'abs', 'sin', 'cos', 'tan'}

CALL = re.compile(r'([A-Za-z_][A-Za-z_0-9]*)\s*\(')
IDENT = re.compile(r'[A-Za-z_][A-Za-z_0-9]*')


def bad(expr):
    e = str(expr)
    reasons = []
    for op in ['<', '>', '==', '!=', '"', "'", '[', ']', ':', ',', 'str', ' if ', ' else ', '(', ']']:
        pass
    if any(t in e for t in ['<', '>', '==', '!=', '"', "'", '[', ']', ':', ',', 'if ', 'else ']):
        reasons.append('comparison/string/list/conditional')
    for fn in CALL.findall(e):
        if fn not in ALLOWED:
            reasons.append('func:' + fn)
    return reasons


rows = []
for path in sorted(glob.glob(os.path.join(DATA, '*_levels.json'))):
    data = json.load(open(path, 'r', encoding='utf-8'))
    for sec_key, sec in data.items():
        if not isinstance(sec, dict):
            continue
        for q in sec.get('levels', []):
            if not isinstance(q, dict):
                continue
            sd = q.get('scene_data') or q.get('scene') or {}
            if not isinstance(sd, dict):
                continue
            for rd in sd.get('readouts', []) or []:
                if not isinstance(rd, dict):
                    continue
                rs = bad(rd.get('expr', ''))
                if rs:
                    rows.append((os.path.basename(path), sec_key, q.get('name'), rd.get('label'), rd.get('expr'), rs))

out = []
out.append("=" * 100)
out.append("BAD READOUTS: %d" % len(rows))
out.append("=" * 100)
cur = None
for f, sec, name, label, expr, rs in rows:
    if f != cur:
        out.append("\n### " + f)
        cur = f
    out.append(f"  [{sec}] {name}")
    out.append(f"      label={label!r} expr={expr!r} -> {rs}")

text = "\n".join(out)
print(text)
with open(os.path.join(r'E:\MathGates-main\tools', '_bad_readouts.txt'), 'w', encoding='utf-8') as fh:
    fh.write(text)
