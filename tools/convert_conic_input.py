#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert conic_levels.json (圆锥曲线) input questions to explore."""
import sys
sys.stdout.reconfigure(encoding='utf-8')

from convert_lib import S, R, convert

specs = {}

specs["焦点三角形最值题 1"] = {
    "sliders": [S("b", 1, 6, 4, 0.5, "短半轴 b"),
                S("c", 1, 6, 3, 0.5, "半焦距 c")],
    "readouts": [R("长半轴 a=√(b²+c²)", "sqrt(b*b+c*c)"),
                 R("△PF₁F₂底边 2c", "2*c", "#ffd479"),
                 R("面积最大值 bc", "b*c", "#40e0a8")],
    "ask": "拖动 b、c，观察椭圆焦点三角形面积何时最大",
    "steps": ["P 在短轴端点时高最大（等于 b）", "底边 = 2c", "面积 =bc"],
    "goal": "掌握椭圆焦点三角形面积的最大值问题",
    "tip": "当 P 在短轴端点时面积最大",
    "success": "对！面积最大值为 bc。",
}

specs["4-2 建构 · 由 a、b 求焦距"] = {
    "sliders": [S("a", 3, 10, 5, 0.5, "长半轴 a"),
                S("b", 2, 8, 4, 0.5, "短半轴 b")],
    "readouts": [R("c²=a²−b²", "a*a-b*b"),
                 R("c=√(a²−b²)", "sqrt(a*a-b*b)", "#ffd479"),
                 R("焦距 2c", "2*sqrt(a*a-b*b)", "#40e0a8")],
    "ask": "拖动 a、b，观察焦距如何由勾股关系给出",
    "steps": ["椭圆中 a²=b²+c²", "所以 c=√(a²−b²)", "a=5、b=4 时 c=3，焦距 2c=6"],
    "goal": "掌握椭圆中 a、b、c 的关系及焦距计算",
    "tip": "注意焦距是 2c 不是 c",
    "success": "对！|F₁F₂|=6。",
}

specs["4-3 迁移 · 由 e 与 a 求 c"] = {
    "sliders": [S("a", 2, 10, 4, 0.5, "长半轴 a"),
                S("e", 0.2, 0.95, 0.5, 0.05, "离心率 e")],
    "readouts": [R("c=ae", "a*e"),
                 R("b=√(a²−c²)", "sqrt(a*a-a*a*e*e)", "#ffd479"),
                 R("验证 c/a=e", "sqrt(a*a*e*e)/a", "#40e0a8")],
    "ask": "拖动 a、e，观察半焦距 c 如何随离心率变化",
    "steps": ["离心率定义 e=c/a", "所以 c=ae", "a=4、e=1/2 时 c=2"],
    "goal": "掌握用离心率和 a 求半焦距 c",
    "tip": "离心率越大，c 越接近 a",
    "success": "对！c=2。",
}

specs["4-5 综合 · 抛物线定义求坐标"] = {
    "sliders": [S("p", 2, 8, 4, 1, "参数 p（y²=2px）"),
                S("dist", 1, 10, 5, 0.5, "点 P 到焦点距离 |PF|")],
    "readouts": [R("焦点 F(p/2, 0)", "p/2"),
                 R("准线 x=−p/2", "-p/2", "#ffd479"),
                 R("P 的横坐标 x=|PF|−p/2", "dist-p/2", "#40e0a8")],
    "ask": "拖动 p 和 |PF|，观察抛物线定义如何给出坐标",
    "steps": ["抛物线定义：|PF|=P 到准线的距离", "准线 x=−p/2", "所以 x=|PF|−p/2；y²=8x、|PF|=5 时 x=3"],
    "goal": "掌握用抛物线定义求点坐标",
    "tip": "焦点到点的距离 = 点到准线的距离",
    "success": "对！P 的横坐标为 3。",
}

specs["6-4 巩固 · 双曲线定义求距离"] = {
    "sliders": [S("a", 1, 5, 2, 0.5, "实半轴 a"),
                S("c", 3, 10, 4, 0.5, "半焦距 c"),
                S("d1", 1, 15, 5, 0.5, "|PF₁|")],
    "readouts": [R("b=√(c²−a²)", "sqrt(c*c-a*a)"),
                 R("||PF₁|−|PF₂||=2a", "2*a", "#ffd479"),
                 R("|PF₂|=|d1±2a|", "abs(d1-2*a)", "#40e0a8")],
    "ask": "拖动 a、c、|PF₁|，观察双曲线上点到两焦点的距离关系",
    "steps": ["双曲线定义：||PF₁|−|PF₂||=2a", "另一距离可能是 d1+2a 或 |d1−2a|", "需满足≥c−a 的最小距离条件"],
    "goal": "掌握用双曲线定义求到另一焦点的距离",
    "tip": "要考虑几何可行性（最小距离限制）",
    "success": "对！另一距离为 9。",
}

if __name__ == '__main__':
    convert('conic_levels.json', 'conic', specs)
