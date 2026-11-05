#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert ellipse_levels.json (椭圆) input questions to explore."""
import sys
sys.stdout.reconfigure(encoding='utf-8')

from convert_lib import S, R, convert

specs = {}

specs["4-2 建构知识 · 由方程读 a、b、c"] = {
    "sliders": [S("a_sq", 9, 36, 25, 1, "a²"),
                S("b_sq", 9, 30, 16, 1, "b²")],
    "readouts": [R("a=√a²", "sqrt(a_sq)"),
                 R("b=√b²", "sqrt(b_sq)", "#ffd479"),
                 R("c=√(a²−b²)", "sqrt(a_sq-b_sq)", "#40e0a8"),
                 R("焦距 2c", "2*sqrt(a_sq-b_sq)", "#fb7185")],
    "ask": "拖动 a²、b²，观察如何从椭圆方程读出 a、b、c 及焦距",
    "steps": ["椭圆 x²/a² + y²/b² = 1 中 a>b", "c²=a²−b²", "焦距=2c；a²=25、b²=16 时 c=3，焦距=6"],
    "goal": "掌握由椭圆标准方程读取几何参数的方法",
    "tip": "记得区分哪个分母大，大的对应长轴",
    "success": "对！焦距为 6。",
}

specs["5-3 迁移应用 · 参数决定形状"] = {
    "sliders": [S("a_sq", 9, 30, 16, 1, "a²"),
                S("e", 0.1, 0.9, 0.5, 0.05, "离心率 e")],
    "readouts": [R("a=√a²", "sqrt(a_sq)"),
                 R("c=ae", "sqrt(a_sq)*e", "#ffd479"),
                 R("c²", "a_sq*e*e", "#40e0a8"),
                 R("b²=a²−c²", "a_sq-a_sq*e*e", "#fb7185")],
    "ask": "拖动 a²和离心率，观察如何反求 b²",
    "steps": ["e=c/a，得 c=ae", "b²=a²−c²=a²(1−e²)", "a²=16、e=1/2 时 b²=16×(1−1/4)=12"],
    "goal": "掌握用离心率和已知参数求解未知量",
    "tip": "离心率越大，椭圆越扁",
    "success": "对！m=12。",
}

specs["6-2 建构知识 · 由 a、c 求离心率"] = {
    "sliders": [S("axis_len", 6, 20, 10, 1, "长轴长 2a"),
                S("focus_dist", 2, 18, 8, 1, "焦距 2c")],
    "readouts": [R("a=2a/2", "axis_len/2"),
                 R("c=2c/2", "focus_dist/2", "#ffd479"),
                 R("离心率 e=c/a", "(focus_dist/2)/(axis_len/2)", "#40e0a8")],
    "ask": "拖动长轴长和焦距，观察离心率的计算",
    "steps": ["长轴 2a=10，得 a=5", "焦距 2c=8，得 c=4", "e=c/a=4/5=0.8"],
    "goal": "理解离心率的定义及其计算方法",
    "tip": "离心率反映椭圆的扁平程度",
    "success": "对！离心率 e=0.8。",
}

specs["6-3 迁移应用 · 由关系求离心率"] = {
    "sliders": [S("ratio", 0.2, 0.9, 0.75, 0.05, "b²/a²的比值")],
    "readouts": [R("b²/a²", "ratio"),
                 R("e²=1−b²/a²", "1-ratio", "#ffd479"),
                 R("离心率 e=√(1−b²/a²)", "sqrt(1-ratio)", "#40e0a8")],
    "ask": "拖动 b²与 a²的比值，观察如何求离心率",
    "steps": ["e²=1−b²/a²", "b²=3/4·a²时 b²/a²=3/4", "e²=1−3/4=1/4，故 e=1/2"],
    "goal": "掌握用 b²与 a²的关系求离心率",
    "tip": "记住 e²=1−b²/a²这个常用公式",
    "success": "对！离心率 e=0.5。",
}

specs["8-2 建构知识 · 余弦定理与面积"] = {
    "sliders": [S("a", 3, 10, 5, 0.5, "长半轴 a"),
                S("c", 1, 8, 4, 0.5, "半焦距 c"),
                S("angle", 30, 150, 90, 10, "∠F₁PF₂（度）")],
    "readouts": [R("2a", "2*a"),
                 R("2c", "2*c", "#ffd479"),
                 R("|PF₁|+|PF₂|=2a", "2*a", "#40e0a8")],
    "ask": "拖动 a、c 和夹角，观察焦点三角形的边长关系",
    "steps": ["|PF₁|+|PF₂|=2a=10", "|F₁F₂|=2c=8", "当∠F₁PF₂=90°时用勾股定理得 |PF₁|·|PF₂|=(10²−8²)/2=18"],
    "goal": "掌握椭圆焦点三角形的几何性质",
    "tip": "结合椭圆定义和余弦定理解题",
    "success": "对！|PF₁|·|PF₂|=18。",
}

specs["8-3 迁移应用 · 由面积求角"] = {
    "sliders": [S("product", 5, 30, 18, 1, "|PF₁|·|PF₂|"),
                S("theta", 30, 150, 90, 10, "∠F₁PF₂（度）")],
    "readouts": [R("S=½·|PF₁|·|PF₂|·sinθ", "0.5*product*sin(theta)"),
                 R("当θ=90°时 sinθ=1", "0.5*product", "#ffd479"),
                 R("也等于 b²·tan(θ/2)", "9", "#40e0a8")],
    "ask": "拖动乘积值和夹角，观察焦点三角形面积的计算",
    "steps": ["S=½·|PF₁|·|PF₂|·sinθ", "θ=90°时 sinθ=1，S=½·18=9", "也等于 b²·tan45°=9"],
    "goal": "掌握椭圆焦点三角形面积的计算公式",
    "tip": "记住 S=b²·tan(θ/2) 这个结论",
    "success": "对！面积为 9。",
}

specs["9-2 建构知识 · 焦半径公式应用"] = {
    "sliders": [S("a", 3, 10, 5, 0.5, "长半轴 a"),
                S("pf1", 1, 10, 3, 0.5, "|PF₁|")],
    "readouts": [R("2a", "2*a"),
                 R("|PF₁|+|PF₂|=2a", "2*a", "#ffd479"),
                 R("|PF₂|=2a−|PF₁|", "2*a-pf1", "#40e0a8")],
    "ask": "拖动 a 和到左焦点的距离，观察如何求到右焦点的距离",
    "steps": ["由椭圆定义 |PF₁|+|PF₂|=2a", "2a=10，|PF₁|=3", "|PF₂|=10−3=7"],
    "goal": "掌握椭圆上点到两焦点距离之和恒为 2a",
    "tip": "这是椭圆的基本定义",
    "success": "对！|PF₂|=7。",
}

specs["11-3 迁移应用 · 中点弦的定点特征"] = {
    "sliders": [S("a_sq", 4, 40, 16, 1, "a²"),
                S("b_sq", 1, 20, 4, 1, "b²")],
    "readouts": [R("-b²/a²", "-b_sq/a_sq"),
                 R("k_AB·k_OM 的定值", "-b_sq/a_sq", "#ffd479"),
                 R("a²=16、b²=4 时", "-0.25", "#40e0a8")],
    "ask": "拖动 a²、b²，观察中点弦斜率与 OM 斜率乘积的定值",
    "steps": ["对于椭圆 x²/a²+y²/b²=1", "若 M 是弦 AB 的中点，则 k_AB·k_OM=−b²/a²", "a²=16、b²=4 时乘积=−4/16=−0.25"],
    "goal": "掌握椭圆中点弦的斜率乘积性质",
    "tip": "这是一个重要的定点特征",
    "success": "对！乘积恒为 −0.25。",
}

if __name__ == '__main__':
    convert('ellipse_levels.json', 'ellipse', specs)
