#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""B11 Phase 2 Day 3 (cont): Boost remaining P0 chapters"""

import json

BASE_PATH = r'E:\MathGates-main\data'

def add_question(chapter_file, new_q):
    filepath = f"{BASE_PATH}\\{chapter_file}"
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    section_key = list(data.keys())[0]
    data[section_key]['levels'].append(new_q)
    
    total_after = sum(len(s['levels']) for s in data.values())
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    return total_after

# Questions
INEQ_CAUCHY_GEO_EXP = {
    "id": "ineq_cauchy_geo_1", "name": "柯西不等式 · 向量几何解释",
    "type": "explore",
    "q": "拖动向量 a 和 b，观察|a·b|与|a||b|的大小关系",
    "explain": "柯西不等式|a·b|≤|a||b|，等号当 a、b 共线时成立"
}

THINK_CONSTRUCTION = {
    "id": "think_construct_1", "name": "构造法 · 辅助函数技巧",
    "type": "input",
    "q": "用构造法证明不等式：若 a+b+c=0，则 a²+b²+c²≥ab+bc+ca",
    "explain": "构造 f(x)=Σ(x-a)²，利用判别式Δ≤0 得结论"
}

SEQ_TELESCOPING = {
    "id": "seq_telescope_1", "name": "裂项相消求和 · 规律探究",
    "type": "explore", 
    "q": "拖动 n 观察数列 1/[k(k+1)] 的前 n 项和如何变化",
    "explain": "裂项相消：1/[k(k+1)]=1/k-1/(k+1)，S_n=1-1/(n+1)→1"
}

CORR_SCATTER = {
    "id": "corr_scatter_1", "name": "相关系数 · 散点图互动",
    "type": "explore",
    "q": "拖动数据点，观察相关系数 r 的变化",
    "explain": "r≈1 强正相关，r≈-1 强负相关，r≈0 无线性相关"
}

RECUR_ITERATION = {
    "id": "recur_iter_1", "name": "递推数列 · 迭代法求通项",
    "type": "input",
    "q": "已知 a₁=1, a_{n+1}=2a_n+1，用迭代法求通项",
    "explain": "计算前几项发现规律：a_n=2ⁿ-1，再用数学归纳法证明"
}

print("="*60)
print("B11 Phase 2 Day 3: Boosting P0 chapters")
print("="*60)

chapters = [
    ("inequalities_levels.json", INEQ_CAUCHY_GEO_EXP),
    ("thinking_levels.json", THINK_CONSTRUCTION),
    ("sequences_levels.json", SEQ_TELESCOPING),
    ("corr_data_levels.json", CORR_SCATTER),
    ("recurrence_levels.json", RECUR_ITERATION),
]

for chapter_file, new_q in chapters:
    try:
        total = add_question(chapter_file, new_q)
        print(f"[OK] {chapter_file}: Added '{new_q['name'][:30]}...' (Total: {total})")
    except Exception as e:
        print(f"[ERROR] {chapter_file}: {e}")

print("\n" + "="*60)
print("Phase 2 Day 3 complete!")
print("="*60)
