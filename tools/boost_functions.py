#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""B11 Phase 3 Day 1 (cont): Boost functions chapter - add high-interaction explore questions"""

import json

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# New Question 1: Function Transformations Interactive
FUNC_TRANSFORM_EXPLORE = {
    "id": "func_transform_explore_1",
    "name": "函数变换 · 平移伸缩可视化探究",
    "technique": "函数变换 · 图像性质",
    "archetype": "LAB",
    "lab": "functions",
    "type": "explore",
    "q": "拖动参数 a、h、k，观察函数 y=a·f(x-h)+k 的图像如何变化。\n\n猜想：每个参数分别控制什么变换？",
    "scene_data": {
        "range": 8,
        "axes": True,
        "sliders": [
            {"name": "a", "min": -2, "max": 2, "value": 1, "step": 0.1, "label": "a (伸缩)"},
            {"name": "h", "min": -3, "max": 3, "value": 0, "step": 0.1, "label": "h (左右平移)"},
            {"name": "k", "min": -3, "max": 3, "value": 0, "step": 0.1, "label": "k (上下平移)"}
        ],
        "curves": [
            {"func": "x^2", "range": [-4, 4], "color": "#ffd479", "dash": True, "label": "原函数 y=x²"},
            {"func": "a*(x-h)^2+k", "range": [-4, 4], "color": "#5ee6ff", "label": "变换后 y=a(x-h)²+k"}
        ],
        "readouts": [
            {"label": "顶点坐标", "expr": "(h,k)", "color": "#a878ff"},
            {"label": "开口方向", "expr": "\"向上\" if a>0 else \"向下\"", "color": "#fb7185"},
            {"label": "开口大小", "expr": "|a|", "color": "#40e0a8"}
        ]
    },
    "ask": "总结规律：a、h、k 分别控制什么类型的变换？",
    "steps": ["先固定 h=k=0，只调整 a 观察伸缩效果", "再固定 a=1，调整 h 看左右平移", "最后调整 k 看上下平移"],
    "goal": "理解函数变换的基本规律：y=f(x-h) 右移 h，y=f(x)+k 上移 k，y=af(x) 纵向伸缩",
    "tip": "特别试试负的 a、h、k 值",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整参数，确保理解每个参数的作用",
    "hint": "注意记忆口诀：左加右减，上加下减；a>1 拉伸，0<a<1 压缩，a<0 翻转",
    "explain": "函数图像的三种基本变换：①水平平移：y=f(x-h) 将图像向右平移 h 个单位（h<0 时左移）；②垂直平移：y=f(x)+k 将图像向上平移 k 个单位（k<0 时下移）；③纵向伸缩：y=af(x)，当|a|>1 时拉伸，0<|a|<1 时压缩，a<0 时还需关于 x 轴翻转。这三种变换的组合可以描述任何二次函数的图像位置。通过拖动滑块可以直观看到每个参数的独立影响，这是研究函数性质的重要方法，后续学习三角函数、指数函数等都会用到这些变换技巧。",
    "success": "对！函数变换的思想贯穿整个高中数学，务必熟练掌握。"
}

# New Question 2: Function Composition Exploration
FUNC_COMPOSITION_EXPLORATION = {
    "id": "func_composition_exploration_1",
    "name": "复合函数 · 分层映射互动探究",
    "technique": "复合函数 · 链式法则",
    "archetype": "LAB",
    "lab": "functions",
    "type": "explore",
    "q": "拖动输入 x，观察复合函数 f(g(x)) 的分层计算过程。\n\n设 g(x)=2x+1，f(u)=u²，求 f(g(x))=___",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "x", "min": -3, "max": 3, "value": 1, "step": 0.1, "label": "输入 x"},
            {"name": "g_coef", "min": -3, "max": 3, "value": 2, "step": 0.5, "label": "g(x)=ax+b 的系数 a"},
            {"name": "g_const", "min": -3, "max": 3, "value": 1, "step": 0.5, "label": "g(x)=ax+b 的常数 b"}
        ],
        "readouts": [
            {"label": "中间层 u=g(x)", "expr": "g_coef*x+g_const", "color": "#ffd479"},
            {"label": "输出层 y=f(u)=u²", "expr": "pow(g_coef*x+g_const, 2)", "color": "#5ee6ff"},
            {"label": "直接计算 f(g(x))", "expr": "pow(g_coef*x+g_const, 2)", "color": "#a878ff"}
        ]
    },
    "ask": "推导 f(g(x)) 的表达式，并与链式法则验证",
    "steps": ["先计算内层 u=g(x)", "再将 u 代入 f(u)", "得到复合函数表达式"],
    "goal": "理解复合函数的'由内到外'计算顺序，掌握展开技巧",
    "tip": "尝试不同的 g(x) 形式：一次函数、二次函数",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整参数，观察复合结果的变化规律",
    "hint": "若 g(x)=ax+b，则 f(g(x))=(ax+b)²，展开后是二次函数",
    "explain": "复合函数 f(g(x)) 的计算遵循'由内到外'原则：先将 x 代入 g(x) 得到中间值 u，再将 u 代入 f(u) 得到最终结果 y。本题中 g(x)=2x+1，f(u)=u²，所以 f(g(x))=(2x+1)²=4x²+4x+1。这是一个典型的'函数嵌套'结构，外层函数决定整体形态（抛物线），内层函数决定位置和变形。复合函数思想在微积分中有重要应用（链式法则求导），在学习分段函数、反函数时也会频繁使用。关键是理解'逐层计算'的顺序和中间变量的意义。",
    "success": "完美！复合函数是构建复杂函数的基础模块，后续学习导数、积分时会大量使用。"
}

def boost_functions_chapter():
    print("=" * 60)
    print("B11 Phase 3 Day 1 (cont): Functions Chapter Boost")
    print("=" * 60)
    
    data = load_json(r'E:\\MathGates-main\\data\\functions_levels.json')
    
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
        data[target_section]['levels'].append(FUNC_TRANSFORM_EXPLORE)
        data[target_section]['levels'].append(FUNC_COMPOSITION_EXPLORATION)
        print(f"\n[OK] Added 2 high-interaction explore questions to '{target_section}'")
    
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
    print("  Total:", total_after, "(+2)")
    print("  Types:", types_after)
    print("  Non-pick ratio:", round(non_pick_ratio*100, 1), "%")
    
    # Estimate improvement
    old_depth = 0.434
    depth_gain = 0.25 * 0.03 + 0.15 * 0.02  # interaction + explanation
    new_depth = old_depth + depth_gain
    
    print("\nDepth Score Estimate:")
    print("  Before:", old_depth)
    print("  Gain: ~", round(depth_gain, 3))
    print("  After: ~", round(new_depth, 3), "- Target 0.45+: ", 
          "PASS [OK]" if new_depth >= 0.45 else "Need more")
    
    save_json(data, r'E:\\MathGates-main\\data\\functions_levels.json')
    
    print("\n" + "=" * 60)
    print("Functions chapter boost complete!")
    print("=" * 60)

if __name__ == '__main__':
    boost_functions_chapter()
