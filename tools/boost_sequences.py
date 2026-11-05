#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Boost sequences chapter - add high-interaction explore questions for arithmetic and geometric sequences"""

import json

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Explore 1: Arithmetic Sequence Visualization
SEQ_ARITHMETIC_VISUALIZE = {
    "id": "seq_arithmetic_visual_1",
    "name": "等差数列 · 通项公式可视化探究",
    "technique": "等差数列 · 通项与求和",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动参数 a₁（首项）和 d（公差），观察等差数列的通项公式 aₙ=a₁+(n-1)d 如何变化。\n\n猜想：当 d>0、d=0、d<0 时，数列分别呈现什么趋势？",
    "scene_data": {
        "range": 8,
        "sliders": [
            {"name": "a1", "min": -10, "max": 10, "value": 2, "step": 1, "label": "首项 a₁"},
            {"name": "d", "min": -3, "max": 3, "value": 1, "step": 0.5, "label": "公差 d"}
        ],
        "points": [
            {"func": "(n, a1 + (n-1)*d)", "n_range": [1, 10], "color": "#5ee6ff", "label": "数列点列"}
        ],
        "lines": [
            {"func": "a1 + (x-1)*d", "range": [0, 11], "color": "#ffd479", "dash": True, "label": "直线 y=a₁+(x-1)d"}
        ],
        "readouts": [
            {"label": "第 n 项 aₙ", "expr": "a1 + (5-1)*d", "color": "#a878ff"},
            {"label": "前 n 项和 S₅", "expr": "5*(a1 + a1+4*d)/2", "color": "#fb7185"},
            {"label": "增长趋势", "expr": "\"递增\" if d>0 else \"常数\" if d==0 else \"递减\"", "color": "#40e0a8"}
        ]
    },
    "ask": "总结规律：等差数列的通项是关于 n 的一次函数，斜率等于公差 d",
    "steps": ["先固定 a₁=2，只调整 d 看递增/递减/常数三种情况", "观察散点为何落在一条直线上", "尝试用求和公式验证计算结果"],
    "goal": "理解等差数列的本质特征：相邻两项之差恒定，通项是线性函数",
    "tip": "特别试试 d=0 的情况，这是常数列",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整参数，确保理解公差对数列形态的决定作用",
    "hint": "等差数列的图像特征是：所有点都在同一条直线上",
    "explain": "等差数列是最基本的数列类型之一，其核心定义是：从第二项起，每一项与前一项的差等于同一个常数 d（公差）。由此可推导出通项公式 aₙ=a₁+(n-1)d，这是一个关于 n 的一次函数，斜率为 d。几何上，数列的点 (n, aₙ) 恰好落在直线 y=a₁+(d)(x-1) 上。前 n 项和公式 Sₙ=na₁+n(n-1)d/2 或 Sₙ=n(a₁+aₙ)/2，前者强调了首项和公差的作用，后者则利用了对称性（倒序相加法）。通过拖动滑块可以直观看到：d>0 时数列递增收敛于正无穷，d<0 时递减收敛于负无穷，d=0 时为常数列。这些性质在后续学习极限、级数时会反复用到。"
}

# Explore 2: Geometric Sequence Growth Comparison
SEQ_GEOMETRIC_GROWTH_EXPLORE = {
    "id": "seq_geometric_growth_1",
    "name": "等比数列 · 增长率对比探究",
    "technique": "等比数列 · 指数增长",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动公比 q，观察等比数列 aₙ=a₁·qⁿ⁻¹的增长速度如何变化。\n\n猜想：当 q>1、q=1、0<q<1、q<0 时，数列分别有什么特点？",
    "scene_data": {
        "range": 8,
        "sliders": [
            {"name": "a1", "min": 1, "max": 5, "value": 2, "step": 1, "label": "首项 a₁"},
            {"name": "q", "min": -2, "max": 2, "value": 1.5, "step": 0.2, "label": "公比 q"}
        ],
        "points": [
            {"func": "(n, a1 * pow(q, n-1))", "n_range": [1, 12], "color": "#5ee6ff", "label": "等比数列点列"}
        ],
        "readouts": [
            {"label": "第 n 项 aₙ", "expr": "a1 * pow(q, 10-1)", "color": "#a878ff"},
            {"label": "前 n 项和 S₁₀", "expr": "a1*(1-pow(q,10))/(1-q) if abs(q-1)>0.001 else a1*10", "color": "#fb7185"},
            {"label": "数列行为", "expr": "\"发散→+∞\" if q>1 else \"常数列\" if abs(q-1)<0.001 else \"趋于 0\" if abs(q)<1 else \"震荡发散\"", "color": "#40e0a8"}
        ]
    },
    "ask": "分类讨论：不同 q 值范围下数列的收敛性与增长特征",
    "steps": ["先试 q=2，观察快速增长", "再试 q=0.5，观察逐渐衰减", "最后试 q=-1，观察震荡现象"],
    "goal": "理解等比数列的核心特征：相邻两项之比为常数 q，具有指数级增长/衰减特性",
    "tip": "注意 q 为负数时的正负交替现象",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几个不同的 q 值，特别是临界值 q=1 和 q=-1",
    "hint": "等比数列的通项是指数函数形式，增长速度远快于等差数列",
    "explain": "等比数列的定义是从第二项起，每一项与前一项的比等于同一个常数 q（公比）。其通项公式为 aₙ=a₁·qⁿ⁻¹，呈现出指数函数的特征。根据 q 的不同取值，数列表现出完全不同的行为：①q>1 时，数列呈指数增长（如复利效应），迅速趋向无穷；②0<q<1 时，数列逐渐衰减趋近于 0（如放射性衰变）；③q=1 时为常数列；④-1<q<0 时，数列在正负之间震荡并逐渐趋于 0；⑤q≤-1 时，数列震荡发散。这种指数增长特性使得等比数列在经济学（复利）、物理学（衰变）、生物学（细胞分裂）等领域有广泛应用。前 n 项和公式 Sₙ=a₁(1-qⁿ)/(1-q)（q≠1）体现了'错位相减法'的巧妙思想。特别注意无穷等比级数只有当|q|<1 时才收敛，其和为 S=a₁/(1-q)。"
}

# Explore 3: Sequence Sum Visualization
SEQ_SUM_VISUALIZATION = {
    "id": "seq_sum_visualize_1",
    "name": "数列求和 · 几何意义探究",
    "technique": "数列求和 · 面积解释",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动首项 a₁和公差 d，观察等差数列前 n 项和 Sₙ的几何意义——矩形面积之和。\n\n设 n=5，比较直接相加与公式 Sₙ=n(a₁+aₙ)/2 的结果。",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "a1", "min": 1, "max": 10, "value": 3, "step": 1, "label": "首项 a₁"},
            {"name": "d", "min": 0, "max": 3, "step": 0.5, "value": 1, "label": "公差 d"},
            {"name": "n", "min": 3, "max": 10, "value": 5, "step": 1, "label": "项数 n"}
        ],
        "bars": [
            {"func": "a1 + (i-1)*d", "i_range": [1, 5], "color": "#5ee6ff", "label": "各项高度"}
        ],
        "readouts": [
            {"label": "末项 aₙ", "expr": "a1 + (n-1)*d", "color": "#ffd479"},
            {"label": "直接相加 Σaᵢ", "expr": "sum([a1+(i-1)*d for i in range(1,n+1)])", "color": "#a878ff"},
            {"label": "公式计算 n(a₁+aₙ)/2", "expr": "n*(a1+a1+(n-1)*d)/2", "color": "#fb7185"}
        ]
    },
    "ask": "理解求和公式的几何意义：Sₙ相当于梯形面积",
    "steps": ["观察柱状图形成的形状", "想象将右侧柱子移到左侧形成矩形", "验证公式计算的准确性"],
    "goal": "掌握等差数列求和的'倒序相加法'及其几何解释",
    "tip": "将数列正写一遍再倒写一遍，对应位置相加",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整参数，确认两种计算方法始终相等",
    "hint": "把 5 根柱子倒过来拼接，会形成一个规则的矩形",
    "explain": "等差数列求和有一个巧妙的几何解释：将各数列项视为矩形的宽度为 1、高度为该项值的矩形，那么总和就是这些矩形的面积。如果将这些矩形按大小排列，它们会形成一个'阶梯形'。关键洞察是：将这个阶梯形复制一份并倒置拼接，会形成一个完整的矩形（或平行四边形），其面积为 n×(a₁+aₙ)，因此原面积为一半，即 Sₙ=n(a₁+aₙ)/2。这就是'倒序相加法'的几何本质。另一种推导方式是利用平均数：等差数列的平均值为(a₁+aₙ)/2，乘以项数 n 即得总和。这个方法不仅适用于等差数列，其思想（平均数×数量=总和）也是统计学的基础。通过这个交互实验，学生可以直观地理解为什么求和公式长这个样子，而不是死记硬背。"
}

def boost_sequences_chapter():
    print("=" * 60)
    print("Sequences Chapter Boost")
    print("=" * 60)
    
    data = load_json(r'E:\\MathGates-main\\data\\sequences_levels.json')
    
    total_before = sum(len(s['levels']) for s in data.values())
    types_before = {}
    for s in data.values():
        for l in s['levels']:
            t = l.get('type', 'choice')
            types_before[t] = types_before.get(t, 0) + 1
    
    print("\nBefore:")
    print("  Total:", total_before)
    print("  Types:", types_before)
    print("  Explore ratio:", round(types_before.get('explore', 0)/total_before*100, 1), "%")
    
    # Add new explore questions to first section
    section_keys = list(data.keys())
    target_section = section_keys[0] if section_keys else None
    
    if target_section:
        data[target_section]['levels'].append(SEQ_ARITHMETIC_VISUALIZE)
        data[target_section]['levels'].append(SEQ_GEOMETRIC_GROWTH_EXPLORE)
        data[target_section]['levels'].append(SEQ_SUM_VISUALIZATION)
        print(f"\n[OK] Added 3 high-interaction explore questions to '{target_section}'")
    
    # Recalculate
    total_after = sum(len(s['levels']) for s in data.values())
    types_after = {}
    for s in data.values():
        for l in s['levels']:
            t = l.get('type', 'choice')
            types_after[t] = types_after.get(t, 0) + 1
    
    explore_count = types_after.get('explore', 0)
    explore_ratio = explore_count / total_after * 100 if total_after > 0 else 0
    non_pick_ratio = (explore_count + types_after.get('input', 0)) / total_after if total_after > 0 else 0
    
    print("\nAfter:")
    print("  Total:", total_after, "(+3)")
    print("  Types:", types_after)
    print("  Explore ratio:", round(explore_ratio, 1), "% (+", round(explore_ratio-types_before.get('explore',0)/total_before*100, 1), "%)")
    print("  Non-pick ratio:", round(non_pick_ratio*100, 1), "%")
    
    # Estimate improvement
    old_depth = 0.423
    depth_gain = 0.25 * 0.04 + 0.15 * 0.02  # interaction + explanation
    new_depth = old_depth + depth_gain
    
    print("\nDepth Score Estimate:")
    print("  Before:", old_depth)
    print("  Gain: ~", round(depth_gain, 3))
    print("  After: ~", round(new_depth, 3), "- Target 0.45+: ", 
          "PASS [SUCCESS]" if new_depth >= 0.45 else "Need more boosts")
    
    save_json(data, r'E:\\MathGates-main\\data\\sequences_levels.json')
    
    print("\n" + "=" * 60)
    print("Sequences chapter boost complete!")
    print("=" * 60)

if __name__ == '__main__':
    boost_sequences_chapter()
