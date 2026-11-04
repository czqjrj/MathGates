#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Shared helpers for converting input (fill-in) questions into explore questions."""
import json
import os
import re

DATA = r'E:\MathGates-main\data'
PI = "3.141592653589793"


def clean_q(q):
    if not q:
        return ""
    for pat in [r'（填数值[^）]*）', r'（保留[^）]*）', r'（精确[^）]*）',
                r'（填分数[^）]*）', r'（提示：[^）]*）']:
        q = re.sub(pat, '', q)
    return q.rstrip('？? \n')


def S(name, mn, mx, val, step=1, label=""):
    return {"name": name, "min": mn, "max": mx,
            "value": val, "step": step, "label": label}


def R(label, expr, color="#5ee6ff"):
    return {"label": label, "expr": expr, "color": color}


def make_explore(lab, orig, spec):
    qtext = spec.get('q_override') or clean_q(orig.get('q', ''))
    goal = spec['goal']
    followup = spec.get('opts') or [
        goal,
        "改变滑块后，这个结论就不再成立",
        "结论只对某一个特殊参数偶然成立",
        "不需要观察参数变化，直接套公式即可",
    ]
    return {
        "name": orig.get('name', ''),
        "type": "explore",
        "technique": spec.get('technique', orig.get('name', '')),
        "archetype": "LAB",
        "lab": lab,
        "q": qtext + "\n\n拖动下方滑块改变参数，观察读数如何实时变化。",
        "scene": {
            "range": spec.get('range', 8),
            "axes": spec.get('axes', False),
            "sliders": spec['sliders'],
            "readouts": spec['readouts'],
        },
        "ask": spec['ask'],
        "opts": followup,
        "ans": 0,
        "steps": spec.get('steps', []),
        "goal": goal,
        "tip": spec.get('tip', ''),
        "confirm": "看解析",
        "gate": False,
        "answers": {},
        "retry": spec.get('retry', '继续调整参数，观察规律是否始终成立。'),
        "hint": orig.get('hint') or '',
        "explain": orig.get('explain') or '',
        "success": spec.get('success', '很好！你已通过实验掌握了这个结论。'),
    }


def convert(filename, lab, specs, verbose=True):
    """Convert all input questions in one file whose (filename, name) is in specs."""
    path = os.path.join(DATA, filename)
    data = json.load(open(path, 'r', encoding='utf-8'))

    before = {}
    for sec in data.values():
        if not isinstance(sec, dict):
            continue
        for q in sec.get('levels', []):
            t = q.get('type', 'choice')
            before[t] = before.get(t, 0) + 1

    converted = 0
    missing = []
    for sec in data.values():
        if not isinstance(sec, dict):
            continue
        for i, q in enumerate(sec.get('levels', [])):
            if q.get('type') != 'input':
                continue
            spec = specs.get(q.get('name'))
            if not spec:
                missing.append(q.get('name'))
                continue
            sec['levels'][i] = make_explore(lab, q, spec)
            converted += 1

    after = {}
    for sec in data.values():
        if not isinstance(sec, dict):
            continue
        for q in sec.get('levels', []):
            t = q.get('type', 'choice')
            after[t] = after.get(t, 0) + 1

    json.dump(data, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)

    if verbose:
        print("=" * 66)
        print(filename)
        print("  before:", before)
        print("  after :", after)
        print("  converted:", converted)
        if missing:
            print("  MISSING SPECS:")
            for m in missing:
                print("    ", m)
        elif after.get('input', 0):
            print("  !! input remains:", after.get('input', 0))
        else:
            print("  OK: input -> 0")
    return converted, after.get('input', 0), missing
