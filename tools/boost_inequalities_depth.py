#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""B11 Phase 2: Boost inequalities chapter - add AM-GM and Cauchy interactive questions"""

import json

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# New Question 1: AM-GM Visualization (explore type)
INEQ_AMGM_VISUAL = {
    "id": "ineq_amgm_visual_1",
    "name": "2-5 AM-GM 不等式 · 几何直观验证",
    "technique": "均值不等式 · 几何证明",
    "archetype": "LAB",
    "lab": "inequalities",
    "lab_ref": "ineq_amgm_visual_1",
    "scene": "res://scenes/LabStage.tscn",
    "type": "explore",
    "q": "拖动滑块改变 a、b 的值，观察算术平均数 (a+b)/2 与几何平均数√(ab) 的大小关系。\n\n猜想：什么时候两者相等？",
    "scene_data": {
        "range": 8,
        "axes": True,
        "sliders": [
            {"name": "a", "min": 0.5, "max": 5, "value": 2, "step": 0.1, "label": "a"},
            {"name": "b", "min": 0.5, "max": 5, "value": 4, "step": 0.1, "label": "b"}
        ],
        "rectangles": [
            {"x": 0, "y": 0, "width": "a", "height": "b", "color": "#5ee6ff33", "label": "矩形面积 ab"}
        ],
        "readouts": [
            {"label": "算术平均 (a+b)/2", "expr": "(a+b)/2", "color": "#5ee6ff"},
            {"label": "几何平均 √(ab)", "expr": "sqrt(a*b)", "color": "#ffd479"},
            {"label": "差值 (AM-GM)", "expr": "(a+b)/2 - sqrt(a*b)", "color": "#a878ff"}
        ]
    },
    "ask": "当 a=b 时，差值会怎样？尝试拖动 a 和 b 验证",
    "steps": ["拖动 a、b 改变数值", "观察算术平均和几何平均", "看差值何时为 0"],
    "goal": "发现当且仅当 a=b 时，(a+b)/2 = √(ab)",
    "tip": "尝试让 a=b，然后慢慢拉开差距",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整 a 和 b，特别试试 a=b 的情况",
    "hint": "基本不等式：(a+b)/2 ≥ √(ab)，等号当且仅当 a=b 时成立",
    "explain": "均值不等式（AM-GM）是最基本也最重要的不等式之一：对任意正数 a,b，有 (a+b)/2 ≥ √(ab)，等号当且仅当 a=b 时成立。这个不等式在求最值问题中应用极广。通过拖动 a、b 可以直观看到：当 a≠b 时算术平均严格大于几何平均，只有当 a=b 时两者相等。几何解释：固定面积的矩形中，正方形的周长最小。",
    "success": "正确！这就是'定积求和最小'或'定和求积最大'的经典工具。"
}

# New Question 2: Cauchy-Schwarz Interactive (input type)
INEQ_CAUCHY_APPLICATION = {
    "id": "ineq_cauchy_app_2", 
    "name": "3-6 柯西不等式 · 向量形式应用",
    "technique": "柯西 - 施瓦茨 · 向量证明",
    "archetype": "LAB",
    "lab": "inequalities",
    "lab_ref": "ineq_cauchy_app_2",
    "scene": "res://scenes/LabStage.tscn",
    "type": "input",
    "q": "用柯西不等式 (a²+b²)(c²+d²) ≥ (ac+bd)²求最小值：\n\n已知 x + y = 1，求 x² + y²的最小值。\n\n思路：构造向量 a=x, b=y, c=1, d=1，代入柯西不等式。\n\n(x²+y²)(1²+1²) ≥ (x·1 + y·1)²\n即：__·(x²+y²) ≥ __²",
    "steps": [
        "构造向量：(x,y) 和 (1,1)",
        "应用柯西：(x²+y²)(1+1) ≥ (x+y)²",
        "代入已知：x+y=1",
        "解出：x²+y² ≥ ___"
    ],
    "ask": "请填写推导过程中的空缺部分",
    "ans_factor": 2,
    "ans_sum": 1,
    "ans_min": 0.5,
    "tol": 0.01,
    "hint": "柯西不等式左边有两个因子：(x²+y²) 和 (1²+1²)=2",
    "explain": "柯西不等式（Cauchy-Schwarz Inequality）是分析学中最基础也最强大的工具之一。向量形式：|u·v| ≤ |u||v|，展开即 (a₁²+a₂²)(b₁²+b₂²) ≥ (a₁b₁+a₂b₂)²。本题中，令 u=(x,y), v=(1,1)，则 (x²+y²)·2 ≥ (x+y)² = 1² = 1，故 x²+y² ≥ 1/2。等号当且仅当 x:y = 1:1，即 x=y=1/2 时取得。",
    "success": "完美！柯西不等式将复杂的优化问题转化为简单的代数运算，这就是数学的美妙之处。"
}

def boost_inequalities_chapter():
    print("=" * 60)
    print("B11 Phase 2: Inequalities Chapter Boost")
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
    
    # Add new questions to appropriate sections
    print("\n[Adding AM-GM and Cauchy interactive questions...]")
    
    # Find suitable sections
    section_keys = list(data.keys())
    
    # Add AM-GM question
    if len(section_keys) > 0:
        data[section_keys[0]]['levels'].append(INEQ_AMGM_VISUAL)
        print("  [OK] Added: AM-GM Visual Exploration")
    
    # Add Cauchy question  
    if len(section_keys) > 1:
        data[section_keys[1]]['levels'].append(INEQ_CAUCHY_APPLICATION)
        print("  [OK] Added: Cauchy Application Input")
    
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
    old_depth = 0.197
    depth_gain = 0.30 * 0.2 + 0.25 * 0.1 + 0.15 * 0.05  # method + interaction + explanation
    new_depth = old_depth + depth_gain
    
    print("\nDepth Score Estimate:")
    print("  Before:", old_depth)
    print("  Gain: ~", round(depth_gain, 3))
    print("  After: ~", round(new_depth, 3), "- Target 0.45+: ", "PASS" if new_depth >= 0.45 else "NEED MORE")
    
    save_json(data, r'E:\\MathGates-main\\data\\inequalities_levels.json')
    
    print("\n" + "=" * 60)
    print("Inequalities chapter boost complete!")
    print("=" * 60)

if __name__ == '__main__':
    boost_inequalities_chapter()
