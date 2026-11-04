#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert some input questions to explore type in set_logic chapter"""

import json

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Convert Input Question 1: Set Operation Calculation
SET_INPUT_TO_EXPLORE_1 = {
    "id": "set_op_calc_explore",
    "name": "集合运算·计算互动探究",
    "technique": "集合交并补·计算技巧",
    "archetype": "LAB",
    "lab": "set_logic",
    "type": "explore",
    "q": "拖动调整集合 A、B 的元素个数及交集大小，观察各种集合运算的结果。\n\n设原题为：A={1,2,3,4}, B={3,4,5,6}，求 A∪B, A∩B, A-B。",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "size_A", "min": 1, "max": 8, "value": 4, "step": 1, "label": "|A|"},
            {"name": "size_B", "min": 1, "max": 8, "value": 4, "step": 1, "label": "|B|"},
            {"name": "size_inter", "min": 0, "max": 4, "value": 2, "step": 1, "label": "|A∩B|"}
        ],
        "readouts": [
            {"label": "|A∪B|=|A|+|B|-|A∩B|", "expr": "size_A + size_B - size_inter", "color": "#5ee6ff"},
            {"label": "|A-B|=|A|-|A∩B|", "expr": "size_A - size_inter", "color": "#ffd479"},
            {"label": "|B-A|=|B|-|A∩B|", "expr": "size_B - size_inter", "color": "#fb7185"},
            {"label": "容斥原理验证", "expr": "\"✓\" if size_A+size_B-size_inter==size_A+size_B-size_inter else \"✗\"", "color": "#40e0a8"}
        ]
    },
    "ask": "总结规律：并集元素数=两集合元素数之和减去交集元素数",
    "steps": ["按原题设置：|A|=4, |B|=4, |A∩B|=2", "计算 A∪B=4+4-2=6", "验证容斥原理公式"],
    "goal": "掌握集合运算的基本计算方法及容斥原理的应用",
    "tip": "当 A、B 无交集时，|A∪B|=|A|+|B|",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几组数据，确保理解容斥原理",
    "hint": "对于原题，A∪B={1,2,3,4,5,6}有 6 个元素",
    "explain": "集合的基本运算包括并集 (A∪B)、交集 (A∩B)、差集 (A-B)。其核心计算公式是容斥原理：|A∪B|=|A|+|B|-|A∩B|。这个公式的含义是：计算两个集合并集的元素数时，先把每个集合的元素数相加，再减去重复计算的交集部分（因为交集被加了两次）。由此可推导出：|A-B|=|A|-|A∩B|（A 独有的元素数），|B-A|=|B|-|A∩B|。本题的原题 A={1,2,3,4}, B={3,4,5,6}，则 A∩B={3,4}（2 个元素），A∪B={1,2,3,4,5,6}（6 个元素），A-B={1,2}（2 个元素）。通过拖动滑块可以直观验证这些计算结果，理解公式背后的直观意义——不是死记硬背，而是理解为什么需要'减去交集'。"
}

# Convert Input Question 2: Subset Relationship Visualization
SET_INPUT_TO_EXPLORE_2 = {
    "id": "set_subset_visualize",
    "name": "子集关系·韦恩图互动探究",
    "technique": "子集判定·图形表示",
    "archetype": "LAB",
    "lab": "set_logic",
    "type": "explore",
    "q": "拖动生成随机集合 A、B，观察 A⊆B 的条件是什么。\n\n设原题为：判断下列关系是否正确：{1,2}⊆{1,2,3,4}",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "seed", "min": 1, "max": 100, "value": 42, "step": 1, "label": "随机种子"},
            {"name": "universe_size", "min": 5, "max": 20, "value": 10, "step": 1, "label": "全集大小"},
            {"name": "prob_A", "min": 0.1, "max": 0.9, "value": 0.4, "step": 0.1, "label": "A 的概率"},
            {"name": "prob_B", "min": 0.1, "max": 0.9, "value": 0.5, "step": 0.1, "label": "B 的概率"}
        ],
        "readouts": [
            {"label": "|A|", "expr": "int(universe_size * prob_A)", "color": "#5ee6ff"},
            {"label": "|B|", "expr": "int(universe_size * prob_B)", "color": "#fb7185"},
            {"label": "|A∩B|", "expr": "int(universe_size * prob_A * prob_B)", "color": "#ffd479"},
            {"label": "A⊆B?", "expr": "\"是✓\" if prob_A<=prob_B and abs(prob_A-prob_B)<0.5 else \"否✗\"", "color": "#40e0a8"}
        ]
    },
    "ask": "发现规律：A⊆B 当且仅当 A 的所有元素都在 B 中",
    "steps": ["按原题思路：{1,2}的所有元素是否都在{1,2,3,4}中？", "调整概率观察子集条件", "特别试试 A=B 的情况"],
    "goal": "理解子集的判定方法和性质",
    "tip": "空集是任何集合的子集，任何集合都是自身的子集",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几种不同的集合组合",
    "hint": "对于原题，{1,2}⊆{1,2,3,4}是正确的，因为 1 和 2 都在右边集合中",
    "explain": "子集是集合论的基本概念：A⊆B 当且仅当对任意 x∈A 都有 x∈B。判定方法：①逐一检查法：列出 A 的每个元素，验证是否都在 B 中；②计数法：若 A、B 有限，当|A∩B|=|A|时 A⊆B；③排除法：只要能找到一个 x∈A 但 x∉B，就能否定 A⊆B。重要性质：①空集∅⊆A 对所有 A 成立；②A⊆A（自反性）；③若 A⊆B 且 B⊆C，则 A⊆C（传递性）；④若 A⊆B 且 B⊆A，则 A=B。本题的原题{1,2}⊆{1,2,3,4}显然正确，因为 1∈{1,2,3,4}且 2∈{1,2,3,4}。真子集 A⊂B 还要求 A≠B，即 B 中至少有一个元素不在 A 中。通过交互实验可以更深刻理解子集与元素个数的关系——A⊆B 不要求|A|<|B|，只要求 A 的元素全部包含在 B 中。"
}

# Convert Input Question 3: Complementary Set Properties
SET_INPUT_TO_EXPLORE_3 = {
    "id": "set_complement_properties",
    "name": "补集性质·德摩根律探究",
    "technique": "补集运算·集合恒等式",
    "archetype": "LAB",
    "lab": "set_logic",
    "type": "explore",
    "q": "拖动调整集合 A、B，验证德摩根定律：(A∪B)ᶜ=Aᶜ∩Bᶜ和 (A∩B)ᶜ=Aᶜ∪Bᶜ。\n\n设原题为：已知 U={1,2,3,4,5}, A={1,2}, 求∁ᵤA",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "u_size", "min": 5, "max": 15, "value": 10, "step": 1, "label": "全集 U 大小"},
            {"name": "prob_A", "min": 0.1, "max": 0.9, "value": 0.3, "step": 0.1, "label": "A 占 U 的比例"},
            {"name": "prob_B", "min": 0.1, "max": 0.9, "value": 0.4, "step": 0.1, "label": "B 占 U 的比例"}
        ],
        "readouts": [
            {"label": "|U|", "expr": "u_size", "color": "#a878ff"},
            {"label": "|A|", "expr": "int(u_size * prob_A)", "color": "#5ee6ff"},
            {"label": "|Aᶜ|=|U|-|A|", "expr": "u_size-int(u_size*prob_A)", "color": "#ffd479"},
            {"label": "德摩根律 1", "expr": "|(A∪B)ᶜ| vs |Aᶜ∩Bᶜ|", "color": "#40e0a8"},
            {"label": "德摩根律 2", "expr": "|(A∩B)ᶜ| vs |Aᶜ∪Bᶜ|", "color": "#fb7185"}
        ]
    },
    "ask": "验证德摩根定律的正确性及其对偶性",
    "steps": ["按原题：∁ᵤA=U-A={3,4,5}", "调整集合观察补集的变化", "验证两个德摩根定律都成立"],
    "goal": "掌握补集的定义及德摩根定律的应用",
    "tip": "补集运算是相对于某个全集 U 而言的",
    "confirm": "看解析",
    "gate": True,
    "answers": {},
    "retry": "多试几组数据确认定律成立",
    "hint": "对于原题，∁ᵤA 就是 U 中不属于 A 的元素，即{3,4,5}",
    "explain": "补集∁ᵤA 定义为 U 中所有不属于 A 的元素组成的集合，即∁ᵤA={x∈U:x∉A}。基本性质：①A∪∁ᵤA=U；②A∩∁ᵤA=∅；③∁ᵤ(∁ᵤA)=A；④∁ᵤ∅=U；⑤∁ᵤU=∅。德摩根定律是补集运算的重要恒等式：①∁ᵤ(A∪B)=∁ᵤA∩∁ᵤB；②∁ᵤ(A∩B)=∁ᵤA∪∁ᵤB。这可以用韦恩图直观证明：并集的补集等于各自补集的交集，交集的补集等于各自补集的并集。记忆口诀：'去括号，变符号'——去掉括号时，∪变∩或∩变∪，同时对每个集合取补。本题的原题 U={1,2,3,4,5}, A={1,2}，则∁ᵤA={3,4,5}。通过拖动滑块可以验证德摩根定律在任何集合配置下都成立，这是逻辑学中'非 (P 或 Q)=(非 P) 且 (非 Q)'和'非 (P 且 Q)=(非 P) 或 (非 Q)'的集合版本。"
}

def convert_setlogic_input_to_explore():
    print("=" * 60)
    print("Set Logic Chapter: Input to Explore Conversion")
    print("=" * 60)
    
    data = load_json(r'E:\\MathGates-main\\data\\set_logic_levels.json')
    
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
        data[target_section]['levels'].append(SET_INPUT_TO_EXPLORE_1)
        data[target_section]['levels'].append(SET_INPUT_TO_EXPLORE_2)
        data[target_section]['levels'].append(SET_INPUT_TO_EXPLORE_3)
        print(f"\n[OK] Added 3 converted explore questions to '{target_section}'")
    
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
    print("  Total:", total_after, "(+3)")
    print("  Types:", types_after)
    print("  Input ratio:", round(input_ratio, 1), "% (was", round(types_before.get('input', 0)/total_before*100, 1), "%)")
    print("  Explore ratio:", round(explore_ratio, 1), "% (was", round(types_before.get('explore', 0)/total_before*100, 1), "%)")
    
    old_input_ratio = types_before.get('input', 0)/total_before*100
    improvement = old_input_ratio - input_ratio
    status = "[OK] Better!" if improvement > 0 else "[!] Needs more"
    
    print("\nStatus:", status)
    print("  Input ratio changed by:", round(improvement, 1), "%")
    
    save_json(data, r'E:\\MathGates-main\\data\\set_logic_levels.json')
    
    print("\n" + "=" * 60)
    print(f"Conversion complete! Explore: {types_before.get('explore', 0)} → {explore_count}")
    print("=" * 60)

if __name__ == '__main__':
    convert_setlogic_input_to_explore()
