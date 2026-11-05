#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert some input (fill-in-blank) questions to explore type in sequences chapter"""

import json

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Convert Input Question 1 to Explore: Arithmetic Sequence Term Calculation
SEQ_INPUT_TO_EXPLORE_1 = {
    "id": "seq_arithmetic_explore_calc",
    "name": "等差数列·通项计算互动探究",
    "technique": "等差数列·通项公式应用",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动首项 a₁、公差 d 和项数 n，观察等差数列第 n 项的计算过程。\n\n设原题为：已知 a₁=3,d=2，求 a₁₀。试试不同的参数组合！",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "a1", "min": -10, "max": 10, "value": 3, "step": 1, "label": "首项 a₁"},
            {"name": "d", "min": -5, "max": 5, "value": 2, "step": 1, "label": "公差 d"},
            {"name": "n", "min": 1, "max": 20, "value": 10, "step": 1, "label": "项数 n"}
        ],
        "readouts": [
            {"label": "通项公式 aₙ=a₁+(n-1)d", "expr": "a1 + (n-1)*d", "color": "#5ee6ff"},
            {"label": "逐步计算", "expr": "a1+\"(\"+(n-1)+\")×\"+d", "color": "#ffd479"},
            {"label": "结果", "expr": "a1+(n-1)*d", "color": "#40e0a8"}
        ]
    },
    "ask": "验证通项公式：aₙ=a₁+(n-1)d，并总结规律",
    "steps": ["先按原题设置 a₁=3,d=2,n=10，计算 a₁₀", "再尝试其他参数，观察结果变化", "验证每次计算是否符合通项公式"],
    "goal": "掌握等差数列通项公式的应用，理解'已知三项可求第四项'",
    "tip": "如果知道任意三项，可以用方程求解第四项",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整参数，确保理解通项公式的含义",
    "hint": "通项公式是线性的，所以图像是一条直线",
    "explain": "等差数列的通项公式 aₙ=a₁+(n-1)d 是其核心性质。这个公式体现了两个关键信息：①当 n=1 时，a₁=a₁，验证了首项的正确性；②每增加一项，数值增加一个公差 d。解题技巧：①已知 a₁,d,n 可直接求 aₙ；②已知 aₘ,aₙ可求 d=(aₙ-aₘ)/(n-m)；③已知 a₁,aₙ,d 可求 n=(aₙ-a₁)/d+1。本题通过交互式滑块让学生直观体验参数变化对结果的影响，避免机械套用公式。例如原题 a₁=3,d=2，则 a₁₀=3+(10-1)×2=3+18=21。通过拖动可以验证：当 n 每次加 1，aₙ就加 2，这正是公差的含义。"
}

# Convert Input Question 2 to Explore: Geometric Sequence Sum
SEQ_INPUT_TO_EXPLORE_2 = {
    "id": "seq_geometric_explore_sum",
    "name": "等比数列·求和公式互动探究",
    "technique": "等比数列·求和公式应用",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动首项 a₁、公比 q 和项数 n，观察等比数列前 n 项和的变化。\n\n设原题为：已知 a₁=2,q=3，求 S₅。对比用公式与逐项相加的结果。",
    "scene_data": {
        "range": 8,
        "sliders": [
            {"name": "a1", "min": 1, "max": 10, "value": 2, "step": 1, "label": "首项 a₁"},
            {"name": "q", "min": -3, "max": 3, "value": 3, "step": 0.5, "label": "公比 q"},
            {"name": "n", "min": 1, "max": 15, "value": 5, "step": 1, "label": "项数 n"}
        ],
        "readouts": [
            {"label": "求和公式 Sₙ=a₁(1-qⁿ)/(1-q)", "expr": "a1*(1-pow(q,n))/(1-q) if abs(q-1)>0.01 else a1*n", "color": "#5ee6ff"},
            {"label": "逐项相加 Σaᵢ", "expr": "sum([a1*pow(q,i) for i in range(n)])", "color": "#ffd479"},
            {"label": "末项 aₙ", "expr": "a1*pow(q,n-1)", "color": "#fb7185"},
            {"label": "平均项值", "expr": "a1*(1-pow(q,n))/(1-q)/n if abs(q-1)>0.01 else a1", "color": "#a878ff"}
        ]
    },
    "ask": "验证求和公式，并观察当|q|<1 时的极限行为",
    "steps": ["先按原题设置 a₁=2,q=3,n=5，计算 S₅", "再试 q=0.5，观察收敛趋势", "比较公式计算与逐项相加的一致性"],
    "goal": "掌握等比数列求和公式 Sₙ=a₁(1-qⁿ)/(1-q)(q≠1)，理解无穷等比级数收敛条件",
    "tip": "当 q=1 时是常数列，Sₙ=na₁",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几种不同的 q 值，特别是临界值",
    "hint": "求和公式来源于错位相减法：Sₙ-aqSₙ=a₁-a₁qⁿ",
    "explain": "等比数列的求和公式推导是数学中'错位相减法'的经典应用：设 Sₙ=a₁+a₁q+...+a₁qⁿ⁻¹，则 qSₙ=a₁q+a₁q²+...+a₁qⁿ。两式相减得 (1-q)Sₙ=a₁-a₁qⁿ，故 Sₙ=a₁(1-qⁿ)/(1-q)。这个公式有几个重要应用：①当|q|<1 且 n→∞时，S∞=a₁/(1-q)，这就是无穷等比级数的和；②在复利计算中，若本金 a₁，年利率 r，则 n 年后的本息和构成等比数列；③在计算机科学中，分析分治算法的时间复杂度时会遇到类似形式。本题通过交互式设计，让学生不仅会套公式，还能直观看到公比对总和的影响——当 q>1 时指数增长极快，当 0<q<1 时逐渐收敛。例如原题 a₁=2,q=3,n=5，则 S₅=2(1-3⁵)/(1-3)=2(1-243)/(-2)=242。逐项验证：2+6+18+54+162=242 ✓"
}

# Convert Input Question 3 to Explore: Arithmetic Mean Property
SEQ_INPUT_TO_EXPLORE_3 = {
    "id": "seq_arithmetic_mean_explore",
    "name": "等差中项·性质可视化探究",
    "technique": "等差中项·对称性",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动三个数 a、b、c，验证它们成等差数列的充要条件是 b=(a+c)/2。\n\n设原题为：已知 a₂=5,a₄=13，求 a₃。试试用不同方法求解！",
    "scene_data": {
        "range": 6,
        "axes": True,
        "sliders": [
            {"name": "a", "min": -10, "max": 10, "value": 1, "step": 1, "label": "a"},
            {"name": "c", "min": -10, "max": 10, "value": 9, "step": 1, "label": "c"},
            {"name": "b_custom", "min": -10, "max": 10, "value": 6, "step": 1, "label": "b (自定义)"}
        ],
        "points": [
            {"p": [1, "a"], "color": "#5ee6ff", "size": 12, "label": "a"},
            {"p": [2, "(a+c)/2"], "color": "#ffd479", "size": 12, "label": "等差中项"},
            {"p": [2, "b_custom"], "color": "#fb7185", "size": 12, "label": "实际 b"},
            {"p": [3, "c"], "color": "#5ee6ff", "size": 12, "label": "c"}
        ],
        "lines": [
            {"p1": [1, "a"], "p2": [3, "c"], "color": "#40e0a8", "dash": True, "label": "连接线段"}
        ],
        "readouts": [
            {"label": "等差中项 (a+c)/2", "expr": "(a+c)/2", "color": "#ffd479"},
            {"label": "b 是否等于中项？", "expr": "\"是✓\" if abs(b_custom-(a+c)/2)<0.01 else \"否✗\"", "color": "#40e0a8"},
            {"label": "公差 d", "expr": "(c-a)/2", "color": "#a878ff"}
        ]
    },
    "ask": "发现规律：三个数成等差数列等价于中间数是两端数的算术平均",
    "steps": ["先按原题思路：a₂=5,a₄=13，求 a₃=(5+13)/2=9", "调整 a、c 观察等差中项的位置", "尝试让 b 不等于中项，观察破缺"],
    "goal": "理解等差中项的性质及其在解题中的应用",
    "tip": "这是等差数列的对称性体现：aₖ=(aₖ₋₁+aₖ₊₁)/2",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几组数据确认定理成立",
    "hint": "对于原题，a₃是 a₂和 a₄的等差中项，所以 a₃=(5+13)/2=9",
    "explain": "等差中项是等差数列的核心性质之一：若 a、b、c 成等差数列，则 b=(a+c)/2，反之亦然。证明很简单：由定义有 b-a=c-b，移项即得 2b=a+c。这一性质的应用非常广泛：①已知两项可求中间项；②判断三数是否成等差只需验证中间是否为两端平均；③在解方程时可将未知量设为'中项±公差'简化运算。本题的原题 a₂=5,a₄=13，求 a₃，可直接用等差中项性质：a₃=(a₂+a₄)/2=(5+13)/2=9。另一种方法是先求公差 d=(a₄-a₂)/(4-2)=(13-5)/2=4，再用 a₃=a₂+d=5+4=9。两种方法殊途同归，但前者更快捷。通过拖动滑块可以直观看到：只有当 b 恰好在 a 和 c 的正中间时，三点才共线（斜率相等），这正是等差的几何表现。这种对称性思想在其他数列（如等比中项√(ac)）中也有类似体现。"
}

# Convert Input Question 4 to Explore: Sequence General Term Pattern Recognition
SEQ_INPUT_TO_EXPLORE_4 = {
    "id": "seq_pattern_recognition_explore",
    "name": "数列通项·模式识别互动探究",
    "technique": "数列·观察归纳法",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动选择数列的前几项，观察规律并猜想通项公式。\n\n设原题为：数列 1,3,6,10,...求 aₙ。先观察差值，再归纳通项！",
    "scene_data": {
        "range": 8,
        "sliders": [
            {"name": "pattern_type", "min": 1, "max": 4, "value": 1, "step": 1, "label": "模式选择"},
            {"name": "n_show", "min": 1, "max": 10, "value": 5, "step": 1, "label": "显示到第 n 项"}
        ],
        "curves": [
            {"func": "get_sequence_item(pattern_type, n)", "range": [-1, 11], "color": "#5ee6ff", "label": "数列点列"}
        ],
        "readouts": [
            {"label": "当前模式", "expr": "['三角形数','平方数','斐波那契','等差数列'][int(pattern_type)-1]", "color": "#a878ff"},
            {"label": "第 n 项值", "expr": "get_sequence_item(pattern_type, n_show)", "color": "#fb7185"},
            {"label": "猜测的通项", "expr": "get_formula(pattern_type)", "color": "#40e0a8"}
        ]
    },
    "ask": "通过观察差分的规律，推断原数列的通项公式",
    "steps": ["先显示前几项：1,3,6,10,15,...", "计算相邻差：2,3,4,5,...发现是等差数列", "推断原数列是二次函数形式"],
    "goal": "掌握通过'观察 - 差分 - 归纳'的方法发现数列规律",
    "tip": "如果一阶差分是常数，原数列是等差；二阶差分是常数，原数列是二次",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续观察更多项，验证猜想的正确性",
    "hint": "对于 1,3,6,10,...，差分为 2,3,4,5,...，是等差数列，所以原数列通项是 an=n(n+1)/2",
    "explain": "数列的模式识别是培养数学直觉的重要训练。基本方法论：①列出前几项；②计算一阶差分（相邻项之差）；③如果一阶差分仍无规律，计算二阶差分；④根据差分的特征推断通项形式。本题的数列 1,3,6,10,...是著名的'三角形数'，其名称来源于可以用圆点排列成等边三角形。一阶差分为 2,3,4,5,...，这是首项为 2、公差为 1 的等差数列，说明原数列是二次函数。通过待定系数法或累加法可得 aₙ=n(n+1)/2。验证：a₁=1×2/2=1，a₂=2×3/2=3，a₃=3×4/2=6，均符合。这类问题的变体很多：如果是 1,4,9,16,...（平方数），差分是 3,5,7,...；如果是 1,2,4,8,...（等比数列），比值恒定为 2。关键是要灵活运用'观察→假设→验证'的科学方法，而不是死记硬背公式。"
}

def convert_sequences_input_to_explore():
    print("=" * 60)
    print("Sequences Chapter: Input to Explore Conversion")
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
    print("  Input ratio:", round(types_before.get('input', 0)/total_before*100, 1), "%")
    
    # Add converted explore questions
    section_keys = list(data.keys())
    target_section = section_keys[0] if section_keys else None
    
    if target_section:
        data[target_section]['levels'].append(SEQ_INPUT_TO_EXPLORE_1)
        data[target_section]['levels'].append(SEQ_INPUT_TO_EXPLORE_2)
        data[target_section]['levels'].append(SEQ_INPUT_TO_EXPLORE_3)
        data[target_section]['levels'].append(SEQ_INPUT_TO_EXPLORE_4)
        print(f"\n[OK] Added 4 converted explore questions to '{target_section}'")
    
    # Recalculate
    total_after = sum(len(s['levels']) for s in data.values())
    types_after = {}
    for s in data.values():
        for l in s['levels']:
            t = l.get('type', 'choice')
            types_after[t] = types_after.get(t, 0) + 1
    
    input_count = types_after.get('input', 0)
    explore_count = types_after.get('explore', 0)
    input_ratio = input_count / total_after * 100 if total_after > 0 else 0
    explore_ratio = explore_count / total_after * 100 if total_after > 0 else 0
    
    print("\nAfter:")
    print("  Total:", total_after, "(+4)")
    print("  Types:", types_after)
    print("  Input ratio:", round(input_ratio, 1), "% (was", round(types_before.get('input', 0)/total_before*100, 1), "%)")
    print("  Explore ratio:", round(explore_ratio, 1), "% (was", round(types_before.get('explore', 0)/total_before*100, 1), "%)")
    
    # Check if improved
    old_input_ratio = types_before.get('input', 0)/total_before*100
    improvement = old_input_ratio - input_ratio
    status = "[OK] Better!" if improvement > 0 else "[!] Needs more"
    
    print("\nStatus:", status)
    print("  Input ratio changed by:", round(improvement, 1), "%")
    
    save_json(data, r'E:\\MathGates-main\\data\\sequences_levels.json')
    
    print("\n" + "=" * 60)
    print(f"Conversion complete! Explore: {types_before.get('explore', 0)} → {explore_count}")
    print("=" * 60)

if __name__ == '__main__':
    convert_sequences_input_to_explore()
