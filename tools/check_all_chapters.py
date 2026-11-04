#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Check the number of input questions in all high school chapters"""

import json
import os

files = [
    'set_logic_levels.json',
    'functions_levels.json', 
    'function_lab_levels.json',
    'sequences_levels.json',
    'inequalities_levels.json',
    'trig_levels.json',
    'vector_levels.json'
]

print("=" * 70)
print("高一内容各章节 input 数量统计（更新后）")
print("=" * 70)

total_input = 0
total_questions = 0
chapters_needing_work = []

for filename in files:
    filepath = os.path.join(r'E:\MathGates-main\data', filename)
    
    if not os.path.exists(filepath):
        continue
    
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
    input_ratio = input_count/total*100 if total > 0 else 0
    
    print(f"\n{chapter_name}:")
    print(f"  总题数：{total}")
    print(f"  题型分布：explore={explore_count}, choice={types.get('choice', 0)}, input={input_count}")
    print(f"  → input 占比：{input_ratio:.1f}%")
    
    if input_ratio > 20:
        status = "[!] 仍超标 (>20%)"
        chapters_needing_work.append(chapter_name)
    else:
        status = "[OK] 达标 (<=" + str(int(input_ratio)) + "%)"
    
    print(f"  {status}")

print("\n" + "=" * 70)
print(f"合计：{total_input} 道填空题，占总题数 {total_questions} 的 {total_input/total_questions*100:.1f}%")
print("=" * 70)

if chapters_needing_work:
    print("\n以下章节仍需优化:")
    for ch in chapters_needing_work:
        print(f"  - {ch}")
else:
    print("\n[OK] 所有章节 input 占比均<=20%!")
