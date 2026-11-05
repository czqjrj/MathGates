# -*- coding: utf-8 -*-
"""B11 Phase 2: Boost conic chapter - add 1 high-interaction explore question"""

import json
from copy import deepcopy

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# New explore question for conic chapter
CONIC_LINE_INTERSECT_EXPLORATION = {
    "id": "conic_line_intersect_1",
    "name": "3-4 直线与圆锥曲线 · 交点个数探索",
    "technique": "数形结合 · 判别式法",
    "archetype": "LAB",
    "lab": "conic",
    "lab_ref": "conic_line_intersect_1", 
    "scene": "res://scenes/LabStage.tscn",
    "type": "explore",
    "q": "拖动参数 k，观察直线 y=kx 与椭圆 x²/4 + y² = 1 的交点个数如何变化？\n\n猜想：什么时候有 2 个交点？1 个（相切）？0 个？",
    "scene_data": {
        "range": 6,
        "axes": True,
        "sliders": [
            {"name": "k", "min": -2, "max": 2, "value": 0.5, "step": 0.1, "label": "斜率 k"}
        ],
        "lines": [
            {"p1": [-4, "-4*k"], "p2": [4, "4*k"], "color": "#5ee6ff", "dash": False, "label": "y=kx"}
        ],
        "curves": [
            {"func": "2*sqrt(1-x*x/4)", "range": [-2, 2], "color": "#ffd479", "label": "上半椭圆"},
            {"func": "-2*sqrt(1-x*x/4)", "range": [-2, 2], "color": "#ffd479", "label": "下半椭圆"}
        ],
        "readouts": [
            {"label": "判别式 Δ", "expr": "k*k - (1+k*k/4)*1", "color": "#a878ff"}
        ]
    },
    "ask": "观察并总结：Δ 的正负与交点个数的关系",
    "steps": ["拖动 k 改变直线斜率", "观察直线与椭圆的交点", "看判别式 Δ 的值变化", "总结规律"],
    "goal": "发现Δ>0 时 2 交点，Δ=0 时相切，Δ<0 时 0 交点",
    "tip": "尝试 k=0（水平线）、k=1、k=1.5 等特殊值",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整 k，特别是让直线刚好碰到椭圆边缘的情况",
    "hint": "联立方程得到一元二次方程，其判别式决定交点个数",
    "explain": "数形结合的思想在圆锥曲线中非常重要。将 y=kx 代入椭圆方程 x²/4 + y² = 1，整理后得到关于 x 的一元二次方程。该方程的判别式Δ决定了直线与椭圆的交点个数：Δ>0 时有两个不同交点（直线穿过椭圆），Δ=0 时恰好一个交点（直线与椭圆相切），Δ<0 时无交点（直线在椭圆外）。拖动 k 可以直观验证这个结论。",
    "success": "正确！这就是典型的'代数问题几何化'思想，通过图像观察简化复杂讨论。"
}

def boost_conic_chapter():
    print("=" * 60)
    print("B11 Phase 2: Conic Chapter Quick Boost")
    print("=" * 60)
    
    data = load_json(r'E:\\MathGates-main\\data\\conic_levels.json')
    
    total_before = sum(len(s['levels']) for s in data.values())
    types_before = {}
    for s in data.values():
        for l in s['levels']:
            t = l.get('type', 'choice')  # conic uses 'choice' not 'pick'
            types_before[t] = types_before.get(t, 0) + 1
    
    print("\nBefore:")
    print("  Total:", total_before)
    print("  Types:", types_before)
    
    # Add new explore question to an appropriate section
    print("\n[Adding high-interaction explore question...]")
    
    # Find the first section with line/conic intersection content
    target_section = None
    for key in data:
        if 'line' in key.lower() or 'intersect' in key.lower():
            target_section = data[key]
            break
    
    if target_section is None:
        # Use first section as fallback
        target_section = data[list(data.keys())[0]]
    
    target_section['levels'].append(CONIC_LINE_INTERSECT_EXPLORATION)
    print("  [OK] Added: Line-Ellipse Intersection Exploration")
    
    # Recalculate
    total_after = sum(len(s['levels']) for s in data.values())
    types_after = {}
    for s in data.values():
        for l in s['levels']:
            t = l.get('type', 'choice')
            types_after[t] = types_after.get(t, 0) + 1
    
    explore_count = types_after.get('explore', 0)
    input_count = types_after.get('input', 0)
    non_pick_ratio = (explore_count + input_count) / total_after if total_after > 0 else 0
    
    print("\nAfter:")
    print("  Total:", total_after, "(+", total_after-total_before, ")")
    print("  Types:", types_after)
    print("  Non-pick ratio:", round(non_pick_ratio*100, 1), "%")
    
    # Estimate
    old_depth = 0.451
    depth_gain = 0.25 * 0.05 + 0.15 * 0.05  # Small gain from one explore
    new_depth = old_depth + depth_gain
    
    print("\nDepth Score Estimate:")
    print("  Before:", old_depth)
    print("  After: ~", round(new_depth, 3))
    
    save_json(data, r'E:\\MathGates-main\\data\\conic_levels.json')
    
    print("\n" + "=" * 60)
    print("Conic chapter boost complete!")
    print("=" * 60)

if __name__ == '__main__':
    boost_conic_chapter()
