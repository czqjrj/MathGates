#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert parabola_levels.json (抛物线) input questions to explore."""
import sys
sys.stdout.reconfigure(encoding='utf-8')

from convert_lib import S, R, convert

specs = {}

specs["3-3 迁移：焦准距"] = {
    "sliders": [S("p", 1, 6, 2, 0.5, "参数 p（y²=2px）")],
    "readouts": [R("抛物线 y²=2px", "2*p"),
                 R("焦点 F(p/2, 0)", "p/2", "#ffd479"),
                 R("准线 x=−p/2", "-p/2", "#40e0a8"),
                 R("焦准距（焦点到准线距离）", "p", "#fb7185")],
    "ask": "拖动参数 p，观察抛物线的焦点、准线和焦准距的关系",
    "steps": ["抛物线 y²=2px 中 2p 为一次项系数", "焦点 F(p/2, 0)，准线 x=−p/2", "焦准距=p；y²=4x 时 p=2，焦准距=2"],
    "goal": "理解抛物线焦准距的几何意义",
    "tip": "焦准距决定了抛物线的开口大小",
    "success": "对！焦准距为 2。",
}

specs["8-2 建构：求斜率"] = {
    "sliders": [S("p", 1, 6, 2, 0.5, "参数 p（y²=2px）"),
                S("y0", -6, 6, 2, 0.5, "中点 M 的纵坐标 y₀")],
    "readouts": [R("中点 M 的纵坐标 y₀", "y0"),
                 R("k_AB=p/y₀", "p/y0", "#ffd479"),
                 R("验证 k=y₂−y₁/x₂−x₁", "p/y0", "#40e0a8")],
    "ask": "拖动 p 和中点的纵坐标，观察中点弦斜率的计算",
    "steps": ["抛物线 y²=2px 被点 M(x₀,y₀) 平分的弦", "斜率 k=p/y₀", "p=2、y₀=2 时 k=2/2=1"],
    "goal": "掌握抛物线中点弦斜率的性质",
    "tip": "与椭圆、双曲线的中点弦性质不同",
    "success": "对！斜率为 1。",
}

specs["9-2 建构：判断交点个数"] = {
    "sliders": [S("p", 1, 6, 2, 0.5, "参数 p（y²=2px）"),
                S("line_k", -3, 3, 1, 0.5, "直线斜率 k"),
                S("line_b", -5, 5, 1, 0.5, "直线截距 b")],
    "readouts": [R("联立 y=kx+b 与 y²=2px", "line_k + 'x+(' + line_b + ')²'"),
                 R("得到关于 x 的二次方程", "line_k*line_k", "#ffd479"),
                 R("判别式Δ决定交点数", "line_k*line_k*p*(p-2*line_b)", "#40e0a8")],
    "ask": "拖动直线斜率和截距，观察与抛物线的交点情况",
    "steps": ["将直线代入抛物线方程得二次方程", "Δ<0 无交点，Δ=0 一个交点，Δ>0 两个交点", "本题Δ=32>0，故有 2 个交点"],
    "goal": "掌握用判别式判断直线与抛物线的交点个数",
    "tip": "注意区分相切（一个交点）和相交（两个交点）",
    "success": "对！交点个数为 2。",
}

if __name__ == '__main__':
    convert('parabola_levels.json', 'parabola', specs)
