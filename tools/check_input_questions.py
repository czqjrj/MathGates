#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Check the number of input (fill-in-blank) questions in each chapter"""

import json
import os

files = [
    'set_logic_levels.json',
    'functions_levels.json', 
    'function_lab_levels.json',
    'sequences_levels.json',
    'inequalities_levels.json'
]

print("=" * 70)
print("高一章节 input(填空题) 数量统计")
print("=" * 70)

total_input = 0
total_questions = 0

for filename in files:
    filepath = os.path.join(r'E:\MathGates-main\data', filename)
    
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    types = {}
    total = 0
    for section in data.values():
        for question in section['levels']:
            qtype = question.get('type', 'choice')
            types[qtype] = types.get(qtype, 0) + 1
            total += 1
    
    input_count = types.get('input', 0)
    explore_count = types.get('explore', 0)
    
    total_input += input_count
    total_questions += total
    
    chapter_name = filename.replace('_levels.json', '')
    print(f"\n{chapter_name}:")
    print(f"  总题数：{total}")
    print(f"  题型分布：{types}")
    print(f"  → input 占比：{input_count/total*100:.1f}%")
    print(f"  → explore 占比：{explore_count/total*100:.1f}%")
    
    if input_count > 0:
        status = "[!] 仍有填空题" if input_count/total > 0.2 else "[OK] input 占比<=20%"
        print(f"  {status}")

print("\n" + "=" * 70)
print(f"合计：{total_input} 道填空题，占总题数 {total_questions} 的 {total_input/total_questions*100:.1f}%")
print("=" * 70)

if total_input > 50:
    print("\n[!] 警告：仍有大量填空题未转换为交互题！")
    print("建议：创建转换脚本，将部分 input 题目改为 explore 类型")
else:
    print("\n[OK] 填空题比例已控制在合理范围内")
