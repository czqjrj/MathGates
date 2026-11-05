#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 ineq_quad 的 1-1「抛物线在 x 轴上下」改成双滑块动态实验。

原来这一关是静态图（没有 sliders），validate_explore 会报
"scene has no interactive block"。这里用两根 r1、r2 驱动抛物线
y = x² − (r1+r2)x + r1r2，学生拖动两根即可看到『小于取中间』。
"""
import json

PATH = r'E:\MathGates-main\data\inequalities_levels.json'


def slider(name, lo, hi, value, step, label):
    return {"name": name, "min": lo, "max": hi, "value": value,
            "step": step, "label": label}


new_level = {
    "name": "1-1 实验：抛物线在 x 轴上下",
    "type": "explore",
    "q": "拖动两根 r₁、r₂，观察抛物线 y=x²−(r₁+r₂)x+r₁r₂ 与 x 轴的两个交点：它在哪一段位于 x 轴下方？",
    "scene": {
        "x": [-6, 8],
        "y": [-8, 8],
        "range": 8,
        "sliders": [
            slider("r1", -4, 4, -1, 0.5, "根 r₁"),
            slider("r2", -4, 4, 3, 0.5, "根 r₂"),
        ],
        "curves": [
            {"fn": "quad", "a": 1, "b": "-(r1+r2)", "c": "r1*r2",
             "color": "#F6BD16", "label": "y=x²−(r₁+r₂)x+r₁r₂"},
        ],
        "points": [
            {"p": ["r1", 0], "color": "#5ee6ff", "label": "r₁"},
            {"p": ["r2", 0], "color": "#5ee6ff", "label": "r₂"},
        ],
        "regions": [
            {"points": [["r1", 0], ["r2", 0], ["r2", -8], ["r1", -8]],
             "color": "#F6BD16", "alpha": 0.12, "outline": False},
        ],
        "readouts": [
            {"label": "两根之和 r₁+r₂", "expr": "r1+r2"},
            {"label": "两根之积 r₁·r₂", "expr": "r1*r2"},
            {"label": "解集宽度 |r₁−r₂|", "expr": "abs(r1-r2)", "color": "#40e0a8"},
            {"label": "判别式 Δ=(r₁−r₂)²", "expr": "(r1-r2)*(r1-r2)", "color": "#ffd479"},
        ],
    },
    "ask": "当抛物线开口向上（二次项系数为 1）时，不等式 x²−(r₁+r₂)x+r₁r₂<0 的解集是？",
    "opts": [
        "两根之间（r₁ 与 r₂ 之间）",
        "两根之外（小于较小根或大于较大根）",
        "全体实数 R",
        "空集 ∅",
    ],
    "ans": 0,
    "goal": "拖动两根，发现『小于取中间、大于取两边』的图像规律",
    "steps": [
        "抛物线开口向上，与 x 轴交于 x=r₁、x=r₂ 两点",
        "在两根之间，图像位于 x 轴下方，函数值为负",
        "在两根之外，图像位于 x 轴上方，函数值为正",
    ],
    "tip": "拖动 r₁、r₂ 改变两根的位置，盯住黄色阴影区域——它始终落在两根之间。",
    "gate": False,
    "answers": {},
    "hint": "先看图像哪一段在 x 轴下方，再把这一段投影到 x 轴上。",
    "explain": "拖动两根可以看到：开口向上的抛物线只在两根之间低于 x 轴，"
               "所以 x²−(r₁+r₂)x+r₁r₂<0 的解集是两根之间（r₁, r₂）。这就是『小于取中间』。",
    "success": "对！『小于取中间』，解集在两根之间。",
}


def main():
    with open(PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)

    levels = data['ineq_quad']['levels']
    old = levels[0]
    assert old['name'] == new_level['name'], 'unexpected first level: ' + old['name']
    levels[0] = new_level

    with open(PATH, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print('OK: ineq_quad 1-1 -> 2 sliders + 4 readouts')


if __name__ == '__main__':
    main()
