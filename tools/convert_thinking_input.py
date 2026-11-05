#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert thinking_levels.json (数学思想综合) input questions to explore."""
import sys
sys.stdout.reconfigure(encoding='utf-8')

from convert_lib import S, R, convert

specs = {}

specs["构造法 · 辅助函数技巧"] = {
    "sliders": [S("a", -4, 4, 1, 1, "a"),
                S("b", -4, 4, 2, 1, "b")],
    "readouts": [R("c=−a−b", "-a-b"),
                 R("a²+b²+c²", "a*a+b*b+(a+b)*(a+b)", "#ffd479"),
                 R("ab+bc+ca", "a*b+b*(-a-b)+(-a-b)*a", "#fb7185"),
                 R("两者之差（≥0）", "(a*a+b*b+(a+b)*(a+b))-(a*b+b*(-a-b)+(-a-b)*a)", "#40e0a8")],
    "ask": "拖动 a、b（c 由 a+b+c=0 确定），观察平方和始终不小于两两乘积和",
    "steps": ["由 a+b+c=0 得 c=−a−b", "平方和 − 两两积 = (a−b)²+(b−c)²+(c−a)² 的一半", "所以差恒 ≥0，等号在 a=b=c=0 时成立"],
    "goal": "掌握用配方法/构造法证明不等式",
    "tip": "把差写成平方和，符号自然清楚",
    "success": "对！a²+b²+c²≥ab+bc+ca 恒成立。",
}

specs["2-3 转化化归 · 分式分解待定系数"] = {
    "sliders": [S("A", -3, 5, 2, 1, "待定系数 A"),
                S("B", -3, 5, 1, 1, "待定系数 B")],
    "readouts": [R("A+B（应等于 3）", "A+B"),
                 R("2A+B（应等于 5）", "2*A+B", "#ffd479"),
                 R("x 系数残差", "A+B-3", "#fb7185"),
                 R("常数项残差", "2*A+B-5", "#40e0a8")],
    "ask": "拖动 A、B，找使两个残差同时为 0 的系数",
    "steps": ["通分得 3x+5=(A+B)x+(2A+B)", "比较系数：A+B=3，2A+B=5", "解得 A=2，B=1，验证 2/(x+1)+1/(x+2) 正好还原"],
    "goal": "掌握待定系数法（转化化归思想）",
    "tip": "两个系数对应两个方程，解方程组即可",
    "success": "对！A=2，B=1。",
    "hint": "通分后比较 x 的系数与常数项。",
    "explain": "转化化归：把复杂分式拆成简单分式之和。通分得 3x+5=(A+B)x+(2A+B)，比较系数得 A+B=3、2A+B=5，解得 A=2、B=1。验证：2/(x+1)+1/(x+2)=(2(x+2)+(x+1))/((x+1)(x+2))=(3x+5)/((x+1)(x+2))，与原式一致。",
}

specs["2-4 反证法 · √2 是无理数证明"] = {
    "sliders": [S("p", 1, 12, 2, 1, "分子 p（p,q 互质）"),
                S("q", 1, 12, 1, 1, "分母 q")],
    "readouts": [R("p²", "p*p"),
                 R("2q²", "2*q*q", "#ffd479"),
                 R("p²−2q²（若为 0 就找到反例）", "p*p-2*q*q", "#fb7185"),
                 R("p²/2（p 为偶数时为整数）", "p*p/2", "#40e0a8")],
    "ask": "拖动 p、q，观察找不到使 p²=2q² 的非零整数解",
    "steps": ["反设 √2=p/q（p、q 互质）", "平方得 p²=2q²，故 p² 为偶数 ⇒ p 为偶数", "设 p=2k 代回得 q 也为偶数，与互质矛盾"],
    "goal": "掌握反证法的完整推理链：反设→归谬→结论",
    "tip": "关键是推出“p、q 都是偶数”与“互质”矛盾",
    "success": "对！矛盾说明 √2 不能写成两个整数的比，即是无理数。",
    "hint": "若 p²=2q²，右边是偶数，所以 p² 也是偶数。",
}

if __name__ == '__main__':
    convert('thinking_levels.json', 'thinking', specs)
