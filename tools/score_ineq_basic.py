#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""只针对 ineq_basic 章节计算 B11 深度指标（v2.1 / v3.0）。"""
import json
import sys

sys.path.insert(0, r'E:\MathGates-main\tools')
sys.stdout.reconfigure(encoding='utf-8')

from analyze_depth_v2_final import analyze_chapter_depth_v2 as v2
from analyze_depth_v3 import analyze_chapter_depth_v3 as v3

PATH = r'E:\MathGates-main\data\inequalities_levels.json'
data = json.load(open(PATH, encoding='utf-8'))
sec = {'ineq_basic': data['ineq_basic']}

for name, fn in (('v2.1', lambda s: v2(s)), ('v3.0', lambda s: v3(s, 'inequalities'))):
    r = fn(sec)
    print(name, 'depth=', r['depth_score'])
    print('  metrics:', r['metrics'])
    print('  stats  :', r['stats'])
