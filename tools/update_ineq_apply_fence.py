#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 ineq_apply 的 5-1「围栏面积」改成双滑块动态实验。

原文写「观察面积随 l 的变化」，但 scene 里没有滑块（静态抛物线），
validate_explore 报 "scene has no interactive block"。
这里补上 l、P 两个滑块：l+w=P/2，S=l(P/2−l)，最高点 P²/16。
"""
import json

PATH = r'E:\MathGates-main\data\inequalities_levels.json'
LEVEL_NAME = '5-1 探究：围栏面积'


def slider(name, lo, hi, value, step, label):
    return {"name": name, "min": lo, "max": hi, "value": value,
            "step": step, "label": label}


new_level = {
    "name": LEVEL_NAME,
    "type": "explore",
    "q": "用长 P 米的篱笆围一个矩形，设长为 l、宽为 w（米），则 $$l+w=P/2$$。拖动 l、P，观察面积 $$S=lw$$ 随 l 的变化——面积的最大值是多少？",
    "scene": {
        "x": [0, 8],
        "y": [-2, 14],
        "sliders": [
            slider("l", 0.2, 3.8, 2, 0.1, "长 l"),
            slider("P", 8, 14, 8, 0.5, "篱笆总长 P"),
        ],
        "curves": [
            {"fn": "quad", "a": -1, "b": "P/2", "c": 0,
             "color": "#F6BD16", "label": "S=l(P/2−l)"},
        ],
        "points": [
            {"p": ["P/4", "P*P/16"], "color": "#f2637b", "label": "最高点"},
        ],
        "readouts": [
            {"label": "宽 w=P/2−l", "expr": "P/2-l"},
            {"label": "面积 S=lw", "expr": "l*(P/2-l)", "color": "#40e0a8"},
            {"label": "最大面积 P²/16", "expr": "P*P/16", "color": "#ffd479"},
            {"label": "最大 − 当前", "expr": "P*P/16-l*(P/2-l)", "color": "#fb7185"},
        ],
    },
    "ask": "当 $$l+w=P/2$$ 时，面积 $$lw$$ 的最大值是？",
    "opts": [
        "P²/8",
        "P²/16",
        "P/4",
        "P²/4",
    ],
    "ans": 1,
    "goal": "把『和定积最大』用于围栏建模，理解最大值为何是 P²/16",
    "steps": [
        "周长固定：2(l+w)=P，即 l+w=P/2 为定值",
        "由基本不等式 lw≤((l+w)/2)²=(P/4)²",
        "所以最大值是 P²/16，等号当 l=w=P/4 时成立",
    ],
    "tip": "把 l 拖到 P/4，盯住最后一行『最大 − 当前』是否归零。",
    "gate": False,
    "answers": {},
    "hint": "和一定时，两数相等则积最大。",
    "explain": "由基本不等式 $$lw\\le(\\frac{l+w}{2})^{2}=\\frac{P^{2}}{16}$$，"
               "当 l=w=P/4 时取到。拖动 l 到 P/4 可以看到差值归零。",
    "success": "对！和定时两数相等，面积最大为 P²/16。",
}


def main():
    with open(PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)

    levels = data['ineq_apply']['levels']
    idx = next((i for i, lv in enumerate(levels) if lv.get('name') == LEVEL_NAME), None)
    assert idx is not None, 'level not found: ' + LEVEL_NAME
    levels[idx] = new_level

    with open(PATH, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print('OK: %s -> 2 sliders + 4 readouts' % LEVEL_NAME)


if __name__ == '__main__':
    main()
