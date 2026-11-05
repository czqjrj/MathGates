#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""逐题数值验证 ineq_basic：不等式方向、下界/上界是否可达、滑块范围内是否合法。"""
import itertools
import json
import math
import sys

sys.stdout.reconfigure(encoding='utf-8')
PATH = r'E:\MathGates-main\data\inequalities_levels.json'
sec = json.load(open(PATH, encoding='utf-8'))['ineq_basic']

# (题名前缀, 取值函数, 差值函数 >=0, 说明)
CHECKS = [
    ('2-1', ['a', 'b'], lambda a, b: a * a + b * b - 2 * a * b, 'a²+b²−2ab'),
    ('2-2', ['a', 'b'], lambda a, b: (a + b) / 2 - math.sqrt(a * b), 'AM−GM'),
    ('2-3', ['t', 'k'], lambda t, k: t + k / t - 2 * math.sqrt(k), 'f−2√k'),
    ('2-4', ['x', 'S'], lambda x, S: S * S / 4 - x * (S - x), 'S²/4−xy'),
    ('2-5', ['x', 'P'], lambda x, P: x + P / x - 2 * math.sqrt(P), 'x+y−2√P'),
    ('2-6', ['x', 'k'], lambda x, k: x + k / (x - 1) - (1 + 2 * math.sqrt(k)), 'f−下界'),
    ('2-7', ['a', 's'], lambda a, s: 1 / a + 1 / (s - a) - 4 / s, '目标−4/s'),
    ('2-8', ['x', 's'], lambda x, s: 1 / x + 1 / (s - 2 * x) - (3 + 2 * math.sqrt(2)) / s, '目标−下界'),
    ('2-9', ['x', 'k'], lambda x, k: x * x + k / (x * x) - 2 * math.sqrt(k), 'f−2√k'),
    ('2-10', ['a', 'b', 'c'], lambda a, b, c: (a + b + c) / 3 - (a * b * c) ** (1 / 3), 'AM−GM'),
    ('2-11', ['a', 'b', 'c'], lambda a, b, c: (a + b + c) * (1 / a + 1 / b + 1 / c) - 9, '乘积−9'),
    ('2-12', ['l', 'P'], lambda l, P: P * P / 16 - l * (P / 2 - l), '最大−面积'),
    ('2-13', ['w', 'L'], lambda w, L: L * L / 8 - w * (L - 2 * w), '最大−面积'),
]

problems = []
for prefix, names, fn, desc in CHECKS:
    q = next(x for x in sec['levels'] if x['name'].startswith(prefix))
    sl = {s['name']: s for s in q['scene']['sliders']}
    ranges = []
    for n in names:
        s = sl[n]
        lo, hi, st = float(s['min']), float(s['max']), float(s['step']) or 0.1
        vals, v = [], lo
        while v <= hi + 1e-9:
            vals.append(round(v, 6))
            v += st
        ranges.append(vals)
    lo_diff, hi_diff = None, None
    for combo in itertools.product(*ranges):
        try:
            d = fn(*combo)
        except ZeroDivisionError:
            problems.append((prefix, 'div0 @ %s' % (combo,)))
            continue
        if not math.isfinite(d):
            problems.append((prefix, 'nonfinite @ %s' % (combo,)))
            continue
        lo_diff = d if lo_diff is None else min(lo_diff, d)
        hi_diff = d if hi_diff is None else max(hi_diff, d)
        # 检查题面写出的读数也都能算
    if lo_diff is None:
        problems.append((prefix, 'no samples'))
        continue
    status = 'OK'
    if lo_diff < -1e-6:
        status = 'VIOLATION (min %.4g)' % lo_diff
        problems.append((prefix, '%s: %s 最小值为负 %.6g' % (desc, status, lo_diff)))
    if lo_diff > 1e-4:
        status += ' · 下界不可达 (min %.4g)' % lo_diff
        problems.append((prefix, '%s: 下界在滑块范围内取不到 (min %.6g)' % (desc, lo_diff)))
    print('%-6s %-14s min=%9.5f  max=%9.5f  %s' % (prefix, desc, lo_diff, hi_diff, status))

print('\nproblems:', len(problems))
for p in problems:
    print('  ', p)
