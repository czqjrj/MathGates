#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
B11 Phase 2: Remaining chapters boost (sequences, derivative, random_var, set_logic, vectors, complex)
"""

import json

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# New explore question for sequences - recurrence method
SEQ_FIXEDPOINT_EXPLORE = {
    "id": "seq_fixedpoint_expl_1",
    "name": "3-6 递推数列 · 特征根法探索",
    "technique": "递推法 · 特征方程",
    "archetype": "LAB",
    "lab": "sequences",
    "type": "explore",
    "q": "拖动参数 a 和 b，观察递推数列 a_{n+1} = a·a_n + b 的收敛情况。\n\n猜想：什么时候数列会收敛到某个固定值？",
    "scene_data": {
        "range": 6,
        "sliders": [
            {"name": "a", "min": -1.5, "max": 1.5, "value": 0.5, "step": 0.1, "label": "系数 a"},
            {"name": "b", "min": -2, "max": 2, "value": 1, "step": 0.1, "label": "常数 b"},
            {"name": "n_max", "min": 5, "max": 20, "value": 10, "step": 1, "label": "迭代次数"}
        ],
        "readouts": [
            {"label": "a_n (当前项)", "expr": "iter_seq[n]", "color": "#5ee6ff"},
            {"label": "固定点 x* = b/(1-a)", "expr": "b/(1-a)", "color": "#ffd479"}
        ]
    },
    "steps": ["设置 a 和 b", "拖动 n_max 增加迭代次数", "观察数列是否收敛"],
    "goal": "发现当|a|<1 时数列收敛，且收敛值接近 b/(1-a)",
    "hint": "设极限为 L，则 L = aL + b ⇒ L = b/(1-a)",
    "explain": "特征根法是求解递推数列的重要方法。对于 a_{n+1} = a·a_n + b，若数列收敛到 L，则 L = aL + b，解得 L = b/(1-a)。通过拖动滑块可以直观看到：当|a|<1 时数列确实收敛到该固定点；当|a|≥1 时数列可能发散或震荡。",
    "success": "正确！这就是'不动点理论'的简单应用。"
}

# New explore question for derivative - monotonicity visualization
DERIV_MONOTONIC_EXPLORATION = {
    "id": "deriv_monotonic_exp_1",
    "name": "2-7 导数与单调性 · 图像互动探究",
    "technique": "导数应用 · 单调判定",
    "archetype": "LAB",
    "lab": "derivative",
    "type": "explore",
    "q": "拖动参数 a、b、c，观察三次函数 f(x)=ax³+bx²+cx+d 的图像及其导数 f'(x)。\n\n猜想：f'(x)>0 时函数单调性如何？f'(x)<0 时呢？",
    "scene_data": {
        "range": 8,
        "axes": True,
        "sliders": [
            {"name": "a", "min": -1, "max": 1, "value": 0.2, "step": 0.1, "label": "a"},
            {"name": "b", "min": -2, "max": 2, "value": -0.5, "step": 0.1, "label": "b"},
            {"name": "c", "min": -2, "max": 2, "value": 1, "step": 0.1, "label": "c"}
        ],
        "curves": [
            {"func": "a*x^3+b*x^2+c*x", "range": [-3, 3], "color": "#5ee6ff", "label": "f(x)"},
            {"func": "3*a*x^2+2*b*x+c", "range": [-3, 3], "color": "#ffd479", "dash": True, "label": "f'(x)"}
        ],
        "readouts": [
            {"label": "f'(0)", "expr": "c", "color": "#a878ff"}
        ]
    },
    "ask": "观察原函数和导数曲线的关系，总结规律",
    "steps": ["调整 a,b,c 改变函数形状", "同时观察 f(x) 和 f'(x)", "寻找两者正负对应关系"],
    "goal": "发现 f'(x)>0 时 f(x) 递增，f'(x)<0 时 f(x) 递减",
    "tip": "特别关注导数为 0 的点（极值点）附近",
    "hint": "导数的几何意义是切线斜率，斜率为正则上升",
    "explain": "导数与单调性的关系是微积分的基本定理之一：在定义域内，若 f'(x)>0 则 f(x) 严格递增，若 f'(x)<0 则 f(x) 严格递减，f'(x)=0 的点是可能的极值点。拖动参数可以直观验证这个结论，这也是用导数研究函数性质的核心思想。",
    "success": "对！这就是'以导判增'的几何直觉。"
}

def boost_remaining_chapters():
    print("=" * 60)
    print("B11 Phase 2: Boost remaining chapters")
    print("=" * 60)
    
    chapters_to_boost = {
        'sequences': ('data/sequences_levels.json', SEQ_FIXEDPOINT_EXPLORE),
        'derivative': ('data/derivative_levels.json', DERIV_MONOTONIC_EXPLORATION),
    }
    
    total_added = 0
    
    for chapter_name, (filepath, new_q) in chapters_to_boost.items():
        print(f"\n[{chapter_name}]")
        
        data = load_json(r'E:\\MathGates-main\\' + filepath)
        
        # Add to first section
        section_keys = list(data.keys())
        if section_keys:
            data[section_keys[0]]['levels'].append(new_q)
            
            total_after = sum(len(s['levels']) for s in data.values())
            types_after = {}
            for s in data.values():
                for l in s['levels']:
                    t = l.get('type', 'pick')
                    types_after[t] = types_after.get(t, 0) + 1
            
            print(f"  Added: {new_q['name']}")
            print(f"  Total now: {total_after}")
            print(f"  Types: {types_after}")
            
            save_json(data, r'E:\\MathGates-main\\' + filepath)
            total_added += 1
    
    print("\n" + "=" * 60)
    print(f"Boost complete! Added {total_added} new questions.")
    print("=" * 60)

if __name__ == '__main__':
    boost_remaining_chapters()
