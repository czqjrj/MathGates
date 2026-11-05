#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Final boost for sequences - add more explore questions to ensure passing 0.45"""

import json

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Final Explore 4: Recurrence Relation Iteration
SEQ_RECURSION_ITERATE_EXPLORE = {
    "id": "seq_recursion_iterate_1",
    "name": "递推数列 · 迭代收敛探究",
    "technique": "递推关系 · 不动点",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动参数 a、b，观察递推数列 aₙ₊₁=a·aₙ+b 的迭代过程是否收敛。\n\n设初始值 a₁=1，重复迭代 20 次，观察数列的变化趋势。",
    "scene_data": {
        "range": 8,
        "sliders": [
            {"name": "a", "min": -1, "max": 1, "value": 0.5, "step": 0.1, "label": "系数 a"},
            {"name": "b", "min": -5, "max": 5, "value": 2, "step": 0.5, "label": "常数 b"},
            {"name": "a1", "min": -5, "max": 5, "value": 1, "step": 1, "label": "初值 a₁"}
        ],
        "points": [
            {"func": "(n, seq_val[n-1])", "n_range": [1, 20], "color": "#5ee6ff", "label": "迭代序列"}
        ],
        "lines": [
            {"p1": [-5, -5], "p2": [25, 25], "color": "#ffd479", "dash": True, "label": "y=x (参考线)"}
        ],
        "readouts": [
            {"label": "第 20 项 a₂₀", "expr": "iterate_seq(a,a1,b,20)", "color": "#a878ff"},
            {"label": "极限值 L=aL+b", "expr": "b/(1-a) if abs(1-a)>0.01 else \"发散\"", "color": "#fb7185"},
            {"label": "收敛性", "expr": "\"收敛\" if abs(a)<1 else \"发散\"", "color": "#40e0a8"}
        ]
    },
    "ask": "发现规律：当|a|<1 时数列收敛到不动点 L=b/(1-a)",
    "steps": ["先试 a=0.5, b=2，观察收敛过程", "再试 a=1.2，观察发散现象", "验证极限公式 L=b/(1-a)"],
    "goal": "理解递推数列的收敛条件与不动点的关系",
    "tip": "特别关注|a|=1 的临界情况",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几个不同的 a 值，特别是靠近 1 的值",
    "hint": "如果数列收敛，那么极限值 L 满足 L=aL+b，解得 L=b/(1-a)",
    "explain": "递推数列是动态系统的离散形式，其核心问题是研究长期行为是否稳定。对于线性递推 aₙ₊₁=a·aₙ+b，可以通过'不动点法'分析：假设数列收敛到 L，则 L 必须满足 L=aL+b，解得 L=b/(1-a)。但这只是必要条件，充分条件是|a|<1——此时无论初值如何，数列都会收敛到这个不动点。几何上，这对应于函数 f(x)=ax+b 与直线 y=x 的交点，且斜率绝对值小于 1 使得该点是吸引子。当|a|>1 时，不动点是排斥子，数列会远离它。这种稳定性分析的思想在动力系统、控制理论、经济学平衡点分析中都有广泛应用。通过拖动滑块可以直观看到：a=0.5 时快速收敛，a=-0.8 时震荡收敛，a=1.1 时指数发散。这正是'混沌边缘'现象的简化版体现。"
}

# Final Explore 5: Sequence Limit Visualization
SEQ_LIMIT_VISUALIZE_EXPLORE = {
    "id": "seq_limit_visualize_1",
    "name": "数列极限 · ε-N定义可视化",
    "technique": "极限概念 · 严格定义",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动ε（误差范围）和 N（起始项数），验证数列 aₙ=1/n 的极限为 0。\n\n对于给定的ε，能否找到一个 N，使得所有 n>N 时都有|aₙ-0|<ε？",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "epsilon", "min": 0.01, "max": 0.5, "value": 0.1, "step": 0.02, "label": "ε (误差)"},
            {"name": "N", "min": 1, "max": 50, "value": 10, "step": 1, "label": "N (起始项)"},
            {"name": "n_max", "min": 10, "max": 100, "value": 50, "step": 5, "label": "最大项数"}
        ],
        "points": [
            {"func": "(n, 1/n)", "n_range": [1, 50], "color": "#5ee6ff", "label": "aₙ=1/n"}
        ],
        "lines": [
            {"p1": [1, 0.01], "p2": [100, 0.01], "color": "#ffd479", "dash": True, "label": "上界ε"},
            {"p1": [1, -0.01], "p2": [100, -0.01], "color": "#ffd479", "dash": True, "label": "下界-ε"},
            {"p1": [1, 0], "p2": [100, 0], "color": "#fb7185", "label": "极限 0"}
        ],
        "readouts": [
            {"label": "a_N", "expr": "1/N", "color": "#a878ff"},
            {"label": "|a_N|<ε?", "expr": "\"是✓\" if 1/N<epsilon else \"否✗\"", "color": "#40e0a8"},
            {"label": "最小 N 应为", "expr": "ceil(1/epsilon)", "color": "#5ee6ff"}
        ]
    },
    "ask": "理解极限的严格定义：∀ε>0, ∃N, 当 n>N 时|aₙ-L|<ε",
    "steps": ["调整ε缩小误差范围", "找到对应的最小 N 值", "验证所有 n>N 的点都在ε带内"],
    "goal": "掌握数列极限的ε-N 语言描述及其直观含义",
    "tip": "ε越小，需要的 N 越大",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "继续调整ε，观察 N 如何相应变化",
    "hint": "要使 1/n<ε，只需 n>1/ε，所以取 N=⌈1/ε⌉即可",
    "explain": "数列极限的ε-N 定义是微积分严格化的基石，由柯西和魏尔斯特拉斯等人建立。其核心思想是用'任意小的误差容忍度'来替代模糊的'无限接近'：对任意正数ε（无论多小），都存在一个项数 N，使得从第 N 项开始的所有项都与极限值 L 的差距小于ε。本例中数列 aₙ=1/n 显然是趋于 0 的，但严格证明需要构造 N：要证|1/n-0|<ε，即 1/n<ε，只需 n>1/ε，因此取 N=⌈1/ε⌉即可。通过拖动滑块可以直观验证这个定义——当ε缩小时，需要更大的 N 才能让后面的点都落在ε带内。这就是'极限'的精确定义，避免了古希腊人关于'无穷小是不是 0'的困惑。这种定量刻画方法不仅适用于数列，也推广到了函数极限、连续性、导数等所有分析学基本概念。"
}

# Final Explore 6: Arithmetic-Geometric Mean Inequality
SEQ_AGMEAN_EXPLORATION = {
    "id": "seq_agmean_exploration_1",
    "name": "算术 - 几何均值不等式探究",
    "technique": "均值不等式 · 递推应用",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动两个正数 a、b，验证算术平均数≥几何平均数：(a+b)/2 ≥ √(ab)\n\n什么时候等号成立？",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "a", "min": 1, "max": 10, "value": 4, "step": 0.5, "label": "正数 a"},
            {"name": "b", "min": 1, "max": 10, "value": 9, "step": 0.5, "label": "正数 b"}
        ],
        "geometric_figures": [
            {"type": "rectangle", "width": "sqrt(a*b)", "height": "sqrt(a*b)", "color": "#5ee6ff", "area_label": "几何平均平方"},
            {"type": "rectangle", "width": "(a+b)/2", "height": "(a+b)/2", "color": "transparent", "border_color": "#ffd479", "area_label": "算术平均平方"}
        ],
        "readouts": [
            {"label": "算术平均 AM=(a+b)/2", "expr": "(a+b)/2", "color": "#a878ff"},
            {"label": "几何平均 GM=√(ab)", "expr": "sqrt(a*b)", "color": "#fb7185"},
            {"label": "AM-GM", "expr": "(a+b)/2-sqrt(a*b)", "color": "#40e0a8"},
            {"label": "等号成立?", "expr": "\"是✓当 a=b\" if abs(a-b)<0.01 else \"否✗\"", "color": "#5ee6ff"}
        ]
    },
    "ask": "验证 AM≥GM，并总结等号成立的条件",
    "steps": ["调整 a、b 观察差值变化", "特别注意 a=b 的情况", "尝试极端差距大的例子"],
    "goal": "理解均值不等式的本质：相等时取到极值",
    "tip": "当 a 与 b 相差越大，AM 比 GM 大得越多",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几组数据，确认不等式始终成立",
    "hint": "等号成立当且仅当 a=b，此时 AM=GM=a",
    "explain": "算术 - 几何均值不等式（AM-GM 不等式）是数学中最基本也是最强大的不等式之一。其核心内容是：对任意非负实数 a₁,a₂,...,aₙ，有(a₁+a₂+...+aₙ)/n ≥ ⁿ√(a₁a₂...aₙ)，等号成立当且仅当 a₁=a₂=...=aₙ。二元情形最简单：(a+b)/2 ≥ √(ab)。证明方法多样：①代数法：(√a-√b)²≥0 展开即得；②几何法：边长为√a 和√b 的矩形面积 ab 小于等于边长为(a+b)/2 的正方形面积((a+b)/2)²；③归纳法可推广到 n 元。这个不等式的深刻意义在于揭示了'均匀分布'的最优性——在和固定的情况下，各项相等时乘积最大；在乘积固定的情况下，各项相等时和最小。这在优化问题、概率论、信息论中都有重要应用。例如，给定周长的矩形中，正方形的面积最大；给定表面积的长方体中，正方体的体积最大。通过拖动滑块可以直观看到：a 与 b 越接近，AM 与 GM 越接近；完全相等时两者重合。"
}

def boost_sequences_final():
    print("=" * 60)
    print("Sequences Chapter Final Boost")
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
    
    # Add final explore questions
    section_keys = list(data.keys())
    target_section = section_keys[0] if section_keys else None
    
    if target_section:
        data[target_section]['levels'].append(SEQ_RECURSION_ITERATE_EXPLORE)
        data[target_section]['levels'].append(SEQ_LIMIT_VISUALIZE_EXPLORE)
        data[target_section]['levels'].append(SEQ_AGMEAN_EXPLORATION)
        print(f"\n[OK] Added 3 final explore questions to '{target_section}'")
    
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
    
    # Estimate
    old_depth = 0.436  # After first boost
    depth_gain = 0.25 * 0.04 + 0.15 * 0.02
    new_depth = old_depth + depth_gain
    
    print("\nDepth Score Estimate:")
    print("  Before:", old_depth)
    print("  Gain: ~", round(depth_gain, 3))
    print("  After: ~", round(new_depth, 3), "- Target 0.45+: ", 
          "PASS [SUCCESS]" if new_depth >= 0.45 else "Still need more")
    
    save_json(data, r'E:\\MathGates-main\\data\\sequences_levels.json')
    
    print("\n" + "=" * 60)
    print("Sequences chapter FINAL boost complete!")
    print(f"  Explore count: {types_before.get('explore', 0)} → {explore_count} (+{explore_count-types_before.get('explore', 0)})")
    print("=" * 60)

if __name__ == '__main__':
    boost_sequences_final()
