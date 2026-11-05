#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""补全 ineq_quad 里残缺的「柯西不等式 · 向量几何解释」。

原关卡 scene 为 null、选项是通用套话，validate_explore 报
"scene is not dict"。这里改成双滑块向量实验：
  * M      = |a||b|（取 |a|=|b|=√M）
  * theta  = 两向量夹角（0°~180°）
实时画出向量 a、b，并用读数对比 |a·b| 与 |a||b|，
让学生看到等号只在共线（0°/180°）时成立。
"""
import json

PATH = r'E:\MathGates-main\data\inequalities_levels.json'
LEVEL_ID = 'ineq_cauchy_geo_1'


def slider(name, lo, hi, value, step, label):
    return {"name": name, "min": lo, "max": hi, "value": value,
            "step": step, "label": label}


new_level = {
    "id": LEVEL_ID,
    "name": "柯西不等式 · 向量几何解释",
    "type": "explore",
    "q": "拖动夹角 θ 与模长乘积 |a||b|（本例取 |a|=|b|=√M），观察 |a·b| 与 |a||b| 的差：夹角是多少时两者相等？",
    "scene": {
        "range": 4,
        "sliders": [
            slider("M", 1, 10, 6, 0.5, "模长乘积 |a||b|"),
            slider("theta", 0, 180, 60, 5, "夹角 θ（°）"),
        ],
        "vectors": [
            {"from": [0, 0], "to": ["sqrt(M)", "0"],
             "color": "#5ee6ff", "label": "a"},
            {"from": [0, 0], "to": ["sqrt(M)*cos(theta)", "sqrt(M)*sin(theta)"],
             "color": "#ffd479", "label": "b"},
        ],
        "points": [
            {"p": [0, 0], "color": "#ffffff", "label": "O"},
        ],
        "readouts": [
            {"label": "|a||b|", "expr": "M"},
            {"label": "|a·b|", "expr": "M*abs(cos(theta))", "color": "#40e0a8"},
            {"label": "比值 |a·b|/(|a||b|)", "expr": "abs(cos(theta))", "color": "#ffd479"},
            {"label": "差 |a||b| − |a·b|", "expr": "M-M*abs(cos(theta))", "color": "#fb7185"},
        ],
    },
    "ask": "柯西不等式 |a·b| ≤ |a||b| 中，等号成立的条件是？",
    "opts": [
        "两向量垂直（θ=90°）时",
        "只要 |a||b| 足够大就取等",
        "两向量共线（θ=0° 或 180°）时",
        "任意夹角都取等号",
    ],
    "ans": 2,
    "goal": "用向量投影理解柯西不等式，并找到取等条件",
    "steps": [
        "a·b = |a||b|cosθ，所以 |a·b| = |a||b|·|cosθ|",
        "因为 |cosθ|≤1，所以 |a·b|≤|a||b|",
        "当 θ=0° 或 180°（两向量共线）时 |cosθ|=1，等号成立",
    ],
    "tip": "把 θ 从 90° 慢慢拖向 0° 或 180°，盯住最后一行的差值是否变成 0。",
    "gate": False,
    "answers": {},
    "hint": "|a·b| 比 |a||b| 少了哪个因子？这个因子的最大值是多少？",
    "explain": "拖动 θ 可以看到 |a·b|/(|a||b|)=|cosθ|，它始终不超过 1，所以 |a·b|≤|a||b|。"
               "当 θ=0° 或 180° 时 |cosθ|=1，两向量共线，等号成立。",
    "success": "对！柯西不等式取等当且仅当两向量共线。",
}


def main():
    with open(PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)

    levels = data['ineq_quad']['levels']
    idx = next((i for i, lv in enumerate(levels) if lv.get('id') == LEVEL_ID), None)
    assert idx is not None, 'level not found: ' + LEVEL_ID
    levels[idx] = new_level

    with open(PATH, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print('OK: %s -> 2 sliders + 2 vectors + 4 readouts' % LEVEL_ID)


if __name__ == '__main__':
    main()
