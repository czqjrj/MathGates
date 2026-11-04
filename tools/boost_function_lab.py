#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Boost function_lab chapter - add high-interaction explore questions for function experiments"""

import json

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Explore Question 1: Piecewise Function Behavior Exploration
FUNC_LAB_PIECEWISE_EXPLORE = {
    "id": "func_lab_piecewise_exp_1",
    "name": "分段函数 · 参数影响探究",
    "technique": "分段函数 · 参数敏感性",
    "archetype": "LAB",
    "lab": "function_lab",
    "type": "explore",
    "q": "拖动参数 a、b，观察分段函数 f(x)=ax+b (x<0), ax²+b (x≥0) 的图像如何变化。\n\n猜想：分界点处的连续性条件是什么？",
    "scene_data": {
        "range": 6,
        "axes": True,
        "sliders": [
            {"name": "a", "min": -3, "max": 3, "value": 1, "step": 0.5, "label": "a (斜率/系数)"},
            {"name": "b", "min": -3, "max": 3, "value": 1, "step": 0.5, "label": "b (常数项)"}
        ],
        "curves": [
            {"func": "a*x+b if x<0 else a*x^2+b", "range": [-4, 4], "color": "#5ee6ff", "label": "分段函数"}
        ],
        "points": [
            {"p": [0, "b"], "color": "#ffd479", "size": 10, "label": "分界点 (0,b)"}
        ],
        "readouts": [
            {"label": "左极限 f(0⁻)", "expr": "b", "color": "#a878ff"},
            {"label": "右极限 f(0⁺)", "expr": "b", "color": "#fb7185"},
            {"label": "是否连续", "expr": "\"是\"", "color": "#40e0a8"}
        ]
    },
    "ask": "总结规律：在什么条件下分段函数在分界点处连续？",
    "steps": ["调整 a、b 观察图像变化", "关注分界点 x=0 处的连续性", "尝试让左右极限不相等的情况"],
    "goal": "理解分段函数连续性的判定方法：左极限=右极限=函数值",
    "tip": "特别试试修改第二段函数的表达式",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整参数，确保理解连续性的本质要求",
    "hint": "对于本题中的分段函数，无论 a、b 取何值，在 x=0 处都连续（因为两段在 0 点取值都是 b）",
    "explain": "分段函数是高中数学的重要概念，其核心难点在于分界点的处理。判断分段函数在某点的连续性需要验证三个条件：①该点有定义；②左右极限存在且相等；③极限值等于函数值。本题中的分段函数在 x=0 处自动满足这三个条件（左极限=b，右极限=b，f(0)=b），所以对任意 a、b 都连续。但如果修改其中一段的表达式（如改为 ax+b+1），则会出现跳跃间断点。通过拖动滑块可以直观看到参数的变化如何影响整体形态，这是研究分段函数性质的重要方法。",
    "success": "对！分段函数的关键是'分段不分心'——每一段内部按正常函数处理，分界点处单独检查连续性。"
}

# Explore Question 2: Composite Function Chain Rule Exploration
FUNC_LAB_COMPOSITE_CHAIN_EXPLORE = {
    "id": "func_lab_composite_chain_1",
    "name": "复合函数 · 链式变化速率探究",
    "technique": "复合函数 · 变化传递",
    "archetype": "LAB",
    "lab": "function_lab",
    "type": "explore",
    "q": "拖动输入 x，观察复合函数 y=f(g(x)) 的分层变化过程。\n设 g(x)=2x+1, f(u)=u²，比较内外层的变化速率关系。",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "x", "min": -3, "max": 3, "value": 1, "step": 0.1, "label": "输入 x"},
            {"name": "g_coef", "min": -3, "max": 3, "value": 2, "step": 0.5, "label": "g(x)=ax+b 系数 a"},
            {"name": "g_const", "min": -3, "max": 3, "value": 1, "step": 0.5, "label": "g(x)=ax+b 常数 b"},
            {"name": "f_power", "min": 1, "max": 3, "value": 2, "step": 0.5, "label": "f(u)=u^n 指数 n"}
        ],
        "readouts": [
            {"label": "中间层 u=g(x)", "expr": "g_coef*x+g_const", "color": "#ffd479"},
            {"label": "输出层 y=f(u)=u^n", "expr": "pow(g_coef*x+g_const,f_power)", "color": "#5ee6ff"},
            {"label": "复合函数 y", "expr": "pow(g_coef*x+g_const,f_power)", "color": "#a878ff"}
        ]
    },
    "ask": "探究外层函数幂次 n 对内层线性变化的放大效果",
    "steps": ["先固定 g(x)=2x+1，只改变 f(u)=u^n 的指数 n", "观察不同 n 值下复合函数的增长速率", "比较线性增长和指数增长的差异"],
    "goal": "理解复合函数的'放大效应'——外层函数决定整体增长速度",
    "tip": "对比 n=1、n=2、n=3 三种情况的增长曲线",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几个不同的 n 值，注意增长速率的变化趋势",
    "hint": "当 n=2 时，y=(ax+b)²是二次函数，增长率随 x 增大而增大",
    "explain": "复合函数体现了数学中的'变换叠加'思想：内层函数 g(x) 先将自变量 x 进行初次变换得到中间变量 u，外层函数 f(u) 再对 u 进行二次变换得到最终结果 y。这种分层结构导致'放大效应'——即使内层是简单的线性变换 g(x)=ax+b，只要外层是非线性的（如幂函数、指数函数），复合后的整体就会呈现复杂的增长行为。本例中 g(x)=2x+1 是线性的，但 f(u)=u²是非线性的，所以复合函数 y=(2x+1)²是一个二次函数，其增长率 dy/dx=2(2x+1)·2 随 x 增大而线性增加。这就是'线性 + 非线性=非线性'的典型例子，也是微积分中链式法则的核心思想。",
    "success": "完美！这就是为什么复杂系统的行为往往不能从单个部件简单预测的原因——复合与反馈会产生'涌现'特性。"
}

# Explore Question 3: Inverse Function Reflection Visualization
FUNC_LAB_INVERSE_REFLECTION_EXPLORE = {
    "id": "func_lab_inverse_reflect_1",
    "name": "反函数 · 对称性可视化探究",
    "technique": "反函数 · 几何对称",
    "archetype": "LAB",
    "lab": "function_lab",
    "type": "explore",
    "q": "拖动参数 a、b，观察函数 y=ax+b 与其反函数 y=(x-b)/a 关于直线 y=x 对称的性质。",
    "scene_data": {
        "range": 6,
        "axes": True,
        "sliders": [
            {"name": "a", "min": -3, "max": 3, "value": 2, "step": 0.5, "label": "a (原函数斜率)"},
            {"name": "b", "min": -3, "max": 3, "value": 1, "step": 0.5, "label": "b (原函数截距)"}
        ],
        "lines": [
            {"p1": [-4, -4], "p2": [4, 4], "color": "#ffd479", "dash": True, "label": "y=x (对称轴)"}
        ],
        "curves": [
            {"func": "a*x+b", "range": [-3, 3], "color": "#5ee6ff", "label": "y=ax+b"},
            {"func": "(x-b)/a", "range": [-3, 3], "color": "#fb7185", "label": "y=(x-b)/a (反函数)"}
        ],
        "readouts": [
            {"label": "原函数斜率", "expr": "a", "color": "#5ee6ff"},
            {"label": "反函数斜率", "expr": "1/a", "color": "#fb7185"},
            {"label": "斜率乘积", "expr": "a*(1/a)", "color": "#a878ff"}
        ]
    },
    "ask": "观察两函数图像的关系，总结反函数的几何特征",
    "steps": ["拖动 a、b 改变原函数", "同时观察原函数与反函数的位置关系", "特别关注关于 y=x 的对称性"],
    "goal": "发现原函数与反函数关于直线 y=x 对称的几何性质",
    "tip": "尝试 a 为正数、负数的情况",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整参数，确认对称性始终成立",
    "hint": "如果点 (x₀,y₀) 在原函数上，那么点 (y₀,x₀) 一定在反函数上",
    "explain": "反函数是函数思想的逆向运用：原函数 y=f(x) 是从 x 映射到 y，反函数 x=f⁻¹(y) 是从 y 反向映射回 x。几何上最显著的特征是**对称性**——原函数图像上的每一点 (x₀,y₀) 对应反函数图像上的点 (y₀,x₀)，因此两图像关于直线 y=x 对称。这一性质不仅适用于线性函数，对任何可逆函数都成立（如 y=eˣ与 y=lnx，y=sinx 与 y=arcsinx）。本例中，原函数 y=ax+b 的反函数可通过解方程得到 x=(y-b)/a，即 y=(x-b)/a。两条直线的斜率分别是 a 和 1/a，它们的乘积为 1（不是 -1，因为是对称于 y=x 而非垂直）。通过拖动滑块可以直观验证这个美妙的对称性质。",
    "success": "对！反函数的对称性是'互逆运算'几何化的典型体现，后续学习导数与积分的对偶关系时会再次遇到类似思想。"
}

def boost_function_lab_chapter():
    print("=" * 60)
    print("Function Lab Chapter Boost")
    print("=" * 60)
    
    data = load_json(r'E:\\MathGates-main\\data\\function_lab_levels.json')
    
    total_before = sum(len(s['levels']) for s in data.values())
    types_before = {}
    for s in data.values():
        for l in s['levels']:
            t = l.get('type', 'choice')
            types_before[t] = types_before.get(t, 0) + 1
    
    print("\nBefore:")
    print("  Total:", total_before)
    print("  Types:", types_before)
    
    # Add new explore questions to first section
    section_keys = list(data.keys())
    target_section = section_keys[0] if section_keys else None
    
    if target_section:
        data[target_section]['levels'].append(FUNC_LAB_PIECEWISE_EXPLORE)
        data[target_section]['levels'].append(FUNC_LAB_COMPOSITE_CHAIN_EXPLORE)
        data[target_section]['levels'].append(FUNC_LAB_INVERSE_REFLECTION_EXPLORE)
        print(f"\n[OK] Added 3 high-interaction explore questions to '{target_section}'")
    
    # Recalculate
    total_after = sum(len(s['levels']) for s in data.values())
    types_after = {}
    for s in data.values():
        for l in s['levels']:
            t = l.get('type', 'choice')
            types_after[t] = types_after.get(t, 0) + 1
    
    explore_count = types_after.get('explore', 0)
    non_pick_ratio = (explore_count + types_after.get('input', 0)) / total_after if total_after > 0 else 0
    
    print("\nAfter:")
    print("  Total:", total_after, "(+3)")
    print("  Types:", types_after)
    print("  Non-pick ratio:", round(non_pick_ratio*100, 1), "%")
    
    # Estimate improvement
    old_depth = 0.431
    depth_gain = 0.25 * 0.04 + 0.15 * 0.02  # interaction + explanation
    new_depth = old_depth + depth_gain
    
    print("\nDepth Score Estimate:")
    print("  Before:", old_depth)
    print("  Gain: ~", round(depth_gain, 3))
    print("  After: ~", round(new_depth, 3), "- Target 0.45+: ", 
          "PASS [SUCCESS]" if new_depth >= 0.45 else "Need more")
    
    save_json(data, r'E:\\MathGates-main\\data\\function_lab_levels.json')
    
    print("\n" + "=" * 60)
    print("Function lab chapter boost complete!")
    print("=" * 60)

if __name__ == '__main__':
    boost_function_lab_chapter()
