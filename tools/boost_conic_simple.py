#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Simple boost conic - just add questions directly"""

import json

with open(r'E:\\MathGates-main\\data\\conic_levels.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Get first section to add all new questions
first_key = list(data.keys())[0]
print("Adding to section:", first_key)

new_questions = [
    {
        "id": "conic_param_exp_1",
        "name": "参数方程探索题 1",
        "type": "explore",
        "q": "拖动角度θ观察椭圆参数方程 x=a·cosθ, y=b·sinθ的几何意义",
        "scene_data": {"range": 6, "sliders": [{"name": "theta", "min": 0, "max": 360, "value": 45, "step": 5, "label": "角度θ"}]},
        "explain": "参数方程将椭圆用单一参数表示，方便求解最值问题。拖动θ可以看到点沿椭圆运动。"
    },
    {
        "id": "conic_asymptote_exp_1", 
        "name": "渐近线斜率探究题 1",
        "type": "explore",
        "q": "拖动 a、b 观察双曲线渐近线 y=±(b/a)x 与开口的关系",
        "scene_data": {"range": 8, "sliders": [{"name": "a", "min": 1, "max": 4}, {"name": "b", "min": 1, "max": 4}]},
        "explain": "渐近线斜率 k=b/a 决定双曲线开口宽窄，k 越大开口越宽。"
    },
    {
        "id": "conic_focus_opt_1",
        "name": "焦点三角形最值题 1",
        "type": "input",
        "q": "椭圆焦点三角形面积最大值问题，用不等式求解",
        "explain": "当点在短轴端点时高最大，面积=bc。本题考查最值问题的基本思路。"
    },
    {
        "id": "conic_optical_prop_1",
        "name": "抛物线光学性质题 1",
        "type": "explore",
        "q": "拖动 P 点观察从焦点发出的光线反射后的方向特点",
        "scene_data": {"range": 8, "sliders": [{"name": "x_p", "min": 0, "max": 6}]},
        "explain": "抛物线的光学性质：从焦点发出的光经反射后平行于对称轴。这是卫星天线的原理。"
    }
]

for q in new_questions:
    data[first_key]['levels'].append(q)
    print("Added:", q['name'])

total_after = sum(len(s['levels']) for s in data.values())
with open(r'E:\\MathGates-main\\data\\conic_levels.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("\nTotal questions now:", total_after)
print("Saved successfully!")
