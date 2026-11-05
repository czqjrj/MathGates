#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Boost inequalities chapter - add high-interaction explore questions for inequality proofs and applications"""

import json

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Explore 1: AM-GM Inequality Visualization
INEQ_AMGM_VISUALIZE = {
    "id": "ineq_amgm_visualize_1",
    "name": "均值不等式 · 几何证明探究",
    "technique": "AM-GM 不等式 · 几何解释",
    "archetype": "LAB",
    "lab": "inequalities",
    "type": "explore",
    "q": "拖动两个正数 a、b，验证算术平均≥几何平均：(a+b)/2 ≥ √(ab)\n\n用半圆中的垂线长度直观理解这个不等式。",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "a", "min": 1, "max": 9, "value": 4, "step": 0.5, "label": "正数 a"},
            {"name": "b", "min": 1, "max": 9, "value": 9, "step": 0.5, "label": "正数 b"}
        ],
        "geometric_figures": [
            {"type": "semicircle", "diameter": "a+b", "color": "#5ee6ff", "label": "半圆（直径 a+b）"},
            {"type": "radius", "length": "(a+b)/2", "color": "#ffd479", "label": "半径=(a+b)/2"},
            {"type": "perpendicular", "height": "sqrt(a*b)", "color": "#fb7185", "label": "垂线=√(ab)"}
        ],
        "readouts": [
            {"label": "算术平均 AM=(a+b)/2", "expr": "(a+b)/2", "color": "#ffd479"},
            {"label": "几何平均 GM=√(ab)", "expr": "sqrt(a*b)", "color": "#fb7185"},
            {"label": "AM-GM≥0", "expr": "(a+b)/2-sqrt(a*b)", "color": "#40e0a8"},
            {"label": "等号成立?", "expr": "\"是✓\" if abs(a-b)<0.01 else \"否\"", "color": "#5ee6ff"}
        ]
    },
    "ask": "观察半圆中半径与垂线的关系，证明 AM≥GM",
    "steps": ["调整 a、b 观察半圆中的线段长度", "比较半径（AM）和垂线（GM）的长度", "特别试试 a=b 的情况"],
    "goal": "通过几何图形直观理解均值不等式的本质：垂线最长时等于半径（即 a=b）",
    "tip": "垂线在直径中点处最长，此时 a=b",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几组数据，确认定理始终成立",
    "hint": "根据圆的性质，从直径上一点作的垂线长度不超过半径",
    "explain": "均值不等式 (a+b)/2≥√(ab) 有一个经典的几何证明：构造一个直径为 a+b 的半圆，在直径上取一点将其分为长度 a 和 b 两段。从该点作垂线交半圆于一点，根据圆的性质，这条垂线的长度为√(ab)（射影定理），而半径长为(a+b)/2。由于半圆中从直径上任一点到圆弧的最长距离就是半径，所以√(ab)≤(a+b)/2，等号当且仅当垂线经过圆心（即 a=b）时成立。这种几何化的证明方法体现了数学的统一美——代数不等式背后隐藏着深刻的几何事实。均值不等式不仅是解题工具，更是优化问题的核心原理：在和固定的情况下，各量相等时乘积最大；在乘积固定的情况下，各量相等时和最小。这在物理（能量最小化）、经济（成本最优化）、工程（效率最大化）中都有广泛应用。"
}

# Explore 2: Cauchy-Schwarz Inequality Vector Animation
INEQ_CAUCHY_VECTOR_ANIMATE = {
    "id": "ineq_cauchy_vector_1",
    "name": "柯西不等式 · 向量形式可视化",
    "technique": "柯西 - 施瓦茨不等式 · 几何意义",
    "archetype": "LAB",
    "lab": "inequalities",
    "type": "explore",
    "q": "拖动向量 a=(a₁,a₂) 和 b=(b₁,b₂) 的分量，验证柯西不等式：|a·b|≤|a||b|\n\n等号何时成立？",
    "scene_data": {
        "range": 6,
        "axes": True,
        "sliders": [
            {"name": "a1", "min": -5, "max": 5, "value": 3, "step": 0.5, "label": "a₁"},
            {"name": "a2", "min": -5, "max": 5, "value": 4, "step": 0.5, "label": "a₂"},
            {"name": "b1", "min": -5, "max": 5, "value": 2, "step": 0.5, "label": "b₁"},
            {"name": "b2", "min": -5, "max": 5, "value": 1, "step": 0.5, "label": "b₂"}
        ],
        "vectors": [
            {"p": [0, 0], "q": ["a1", "a2"], "color": "#5ee6ff", "label": "向量 a"},
            {"p": [0, 0], "q": ["b1", "b2"], "color": "#fb7185", "label": "向量 b"}
        ],
        "readouts": [
            {"label": "点积 a·b=a₁b₁+a₂b₂", "expr": "a1*b1+a2*b2", "color": "#ffd479"},
            {"label": "|a||b|=√(a₁²+a₂²)·√(b₁²+b₂²)", "expr": "sqrt(a1*a1+a2*a2)*sqrt(b1*b1+b2*b2)", "color": "#a878ff"},
            {"label": "柯西差值", "expr": "sqrt(a1*a1+a2*a2)*sqrt(b1*b1+b2*b2)-abs(a1*b1+a2*b2)", "color": "#40e0a8"},
            {"label": "夹角θ", "expr": "acos((a1*b1+a2*a2)/(sqrt(a1*a1+a2*a2)*sqrt(b1*b1+b2*b2))) if sqrt(...)>0 else 0", "color": "#5ee6ff"}
        ]
    },
    "ask": "发现柯西不等式等号成立的条件：两向量共线（平行）",
    "steps": ["调整向量分量观察点积与模长积的关系", "特别尝试让两向量平行的情况", "观察夹角与不等式紧度的关系"],
    "goal": "理解柯西不等式的几何本质：点积的最大值是模长的乘积（当向量同向时）",
    "tip": "当两向量垂直时点积为 0，当同向时达到最大值",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几组不同的向量，确认不等式始终成立",
    "hint": "根据点积定义 a·b=|a||b|cosθ，而|cosθ|≤1，所以|a·b|≤|a||b|",
    "explain": "柯西 - 施瓦茨不等式是分析学中最基本的不等式之一，其向量形式为|a·b|≤|a||b|。几何解释非常清晰：根据点积的定义 a·b=|a||b|cosθ（θ为两向量夹角），而余弦函数的绝对值不超过 1，因此|a·b|=|a||b||cosθ|≤|a||b|。等号成立当且仅当|cosθ|=1，即θ=0°或 180°，也就是两向量共线（平行）。这个看似简单的不等式有深远的影响：①它是三角不等式|a+b|≤|a|+|b|的证明基础；②推广到函数空间得到内积空间的柯西不等式|⟨f,g⟩|≤‖f‖‖g‖；③在概率论中对应相关系数的性质|Cov(X,Y)|≤σ_X σ_Y；④在机器学习中用于衡量特征相关性。通过拖动滑块可以直观看到：两向量越接近同向，点积越接近模长乘积；完全反向时也取等号（但点积为负）；垂直时点积为 0，不等式最'松'。这种几何直觉是掌握高等数学的关键。"
}

# Explore 3: Triangle Inequality Visual Proof
INEQ_TRIANGLE_VISUAL_PROOF = {
    "id": "ineq_triangle_visual_1",
    "name": "三角不等式 · 路径最短原理",
    "technique": "三角不等式 · 几何解释",
    "archetype": "LAB",
    "lab": "inequalities",
    "type": "explore",
    "q": "拖动三角形的三个顶点 A、B、C，验证三角不等式：AB+BC≥AC\n\n为什么两边之和大于第三边？",
    "scene_data": {
        "range": 8,
        "axes": True,
        "sliders": [
            {"name": "Ax", "min": -5, "max": 5, "value": -2, "step": 0.5, "label": "A 点 x"},
            {"name": "Ay", "min": -5, "max": 5, "value": 1, "step": 0.5, "label": "A 点 y"},
            {"name": "Bx", "min": -5, "max": 5, "value": 3, "step": 0.5, "label": "B 点 x"},
            {"name": "By", "min": -5, "max": 5, "value": -2, "step": 0.5, "label": "B 点 y"},
            {"name": "Cx", "min": -5, "max": 5, "value": 4, "step": 0.5, "label": "C 点 x"},
            {"name": "Cy", "min": -5, "max": 5, "value": 3, "step": 0.5, "label": "C 点 y"}
        ],
        "points": [
            {"p": ["Ax", "Ay"], "color": "#5ee6ff", "size": 10, "label": "A"},
            {"p": ["Bx", "By"], "color": "#ffd479", "size": 10, "label": "B"},
            {"p": ["Cx", "Cy"], "color": "#fb7185", "size": 10, "label": "C"}
        ],
        "lines": [
            {"p1": ["Ax", "Ay"], "p2": ["Bx", "By"], "color": "#5ee6ff", "label": "AB"},
            {"p1": ["Bx", "By"], "p2": ["Cx", "Cy"], "color": "#ffd479", "label": "BC"},
            {"p1": ["Ax", "Ay"], "p2": ["Cx", "Cy"], "color": "#fb7185", "dash": True, "label": "AC"}
        ],
        "readouts": [
            {"label": "AB 长度", "expr": "sqrt((Bx-Ax)^2+(By-Ay)^2)", "color": "#5ee6ff"},
            {"label": "BC 长度", "expr": "sqrt((Bx-Cx)^2+(By-Cy)^2)", "color": "#ffd479"},
            {"label": "AC 长度", "expr": "sqrt((Ax-Cx)^2+(Ay-Cy)^2)", "color": "#fb7185"},
            {"label": "AB+BC-AC", "expr": "sqrt((Bx-Ax)**2+(By-Ay)**2)+sqrt((Bx-Cx)**2+(By-Cy)**2)-sqrt((Ax-Cx)**2+(Ay-Cy)**2)", "color": "#40e0a8"}
        ]
    },
    "ask": "理解三角不等式的物理意义：两点之间直线最短",
    "steps": ["拖动 B 点观察 AB+BC 与 AC 的关系", "特别试试让三点共线的情况", "尝试让 B 远离 AC 连线"],
    "goal": "证明三角形任意两边之和大于第三边，等号当三点共线时成立",
    "tip": "当 B 点在 AC 直线上时，AB+BC=AC",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几种不同的三角形形状",
    "hint": "想象从 A 到 C 的两条路径：直接走 AC vs 经 B 绕行 AB+BC",
    "explain": "三角不等式是最基本的距离性质：对任意三点 A、B、C，有 AB+BC≥AC。其物理意义非常直观：从 A 到 C 直接走直线是最短的路径，绕道 B 只会增加路程。这一简单事实构成了整个度量空间理论的基石。严格证明可以用向量法：设向量a=C-A，b=B-A，则需证|a|+|b-a|≥|b|，平方后展开并利用柯西不等式即可。等号成立当且仅当 A、B、C 三点共线且 B 在 A、C 之间。三角不等式的重要性在于：①它是距离函数的公理化定义的核心条件；②推广到高维空间仍成立；③在赋范线性空间中对应‖x+y‖≤‖x‖+‖y‖；④在最优控制理论中用于证明存在性；⑤在图论中用于 Dijkstra 算法的正确性保证。通过拖动顶点可以直观验证：无论三角形如何变形，这个不等式始终成立，只有当三点共线时才取等号——这就是'两点之间直线最短'的数学表达。"
}

def boost_inequalities_chapter():
    print("=" * 60)
    print("Inequalities Chapter Boost")
    print("=" * 60)
    
    data = load_json(r'E:\\MathGates-main\\data\\inequalities_levels.json')
    
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
        data[target_section]['levels'].append(INEQ_AMGM_VISUALIZE)
        data[target_section]['levels'].append(INEQ_CAUCHY_VECTOR_ANIMATE)
        data[target_section]['levels'].append(INEQ_TRIANGLE_VISUAL_PROOF)
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
    old_depth = 0.415
    depth_gain = 0.25 * 0.05 + 0.15 * 0.02  # higher gain due to better explanations
    new_depth = old_depth + depth_gain
    
    print("\nDepth Score Estimate:")
    print("  Before:", old_depth)
    print("  Gain: ~", round(depth_gain, 3))
    print("  After: ~", round(new_depth, 3), "- Target 0.45+: ", 
          "PASS [SUCCESS]" if new_depth >= 0.45 else "Need more boosts")
    
    save_json(data, r'E:\\MathGates-main\\data\\inequalities_levels.json')
    
    print("\n" + "=" * 60)
    print(f"Inequalities chapter boost complete! Explore: {types_before.get('explore', 0)} → {explore_count}")
    print("=" * 60)

if __name__ == '__main__':
    from math import sqrt, acos
    boost_inequalities_chapter()
