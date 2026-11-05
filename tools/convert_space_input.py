#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert space_levels.json (空间向量与立体几何) input questions to explore."""
import sys
sys.stdout.reconfigure(encoding='utf-8')

from convert_lib import S, R, convert

specs = {}

specs["3-2 建构：向量模长"] = {
    "sliders": [S("ax", -5, 5, 1, 1, "a 的 x 分量"),
                S("ay", -5, 5, 2, 1, "a 的 y 分量"),
                S("az", -5, 5, 2, 1, "a 的 z 分量")],
    "readouts": [R("a²+b²+c²", "ax*ax+ay*ay+az*az"),
                 R("|a|=√(x²+y²+z²)", "sqrt(ax*ax+ay*ay+az*az)", "#ffd479"),
                 R("a=(1,2,2) 时 |a|=3", "sqrt(1*1+2*2+2*2)", "#40e0a8")],
    "ask": "拖动三个分量，观察空间向量的模长如何由三维勾股定理给出",
    "steps": ["|a|=√(x²+y²+z²)", "代入 a=(1,2,2) 得 √(1+4+4)=√9=3"],
    "goal": "掌握空间向量模长的坐标计算公式",
    "tip": "这是平面勾股定理在三维的自然推广",
    "success": "对！|a|=3。",
}

specs["12-2 建构：点到平面距离公式应用"] = {
    "sliders": [S("px", -5, 5, 1, 1, "点 P 的 x 坐标"),
                S("py", -5, 5, 2, 1, "点 P 的 y 坐标"),
                S("pz", -5, 5, 3, 1, "点 P 的 z 坐标"),
                S("plane_z", -5, 5, 0, 1, "平面 z=k 的高度 k")],
    "readouts": [R("P 的 z 坐标", "pz"),
                 R("平面高度 k", "plane_z", "#ffd479"),
                 R("距离 d=|z−k|", "abs(pz-plane_z)", "#40e0a8")],
    "ask": "拖动点的坐标和平面高度，观察点到平面距离的计算",
    "steps": ["对于平面 z=0，法向量 n=(0,0,1)", "距离 d=|P·n|/|n|=|z|", "P(1,2,3) 到 z=0 的距离为 3"],
    "goal": "理解点到平面距离公式的应用",
    "tip": "特殊情况下可直接用坐标差计算",
    "success": "对！距离为 3。",
}

specs["12-3 迁移：平行平面的距离"] = {
    "sliders": [S("d1", -6, 6, -6, 1, "第一个平面常数 d₁"),
                S("d2", -6, 6, 3, 1, "第二个平面常数 d₂"),
                S("nx", -3, 3, 2, 1, "法向量 x 分量"),
                S("ny", -3, 3, 1, 1, "法向量 y 分量"),
                S("nz", -3, 3, 2, 1, "法向量 z 分量")],
    "readouts": [R("|n|=√(n_x²+n_y²+n_z²)", "sqrt(nx*nx+ny*ny+nz*nz)"),
                 R("|d₁−d₂|", "abs(d1-d2)", "#ffd479"),
                 R("距离 d=|d₁−d₂|/|n|", "abs(d1-d2)/sqrt(nx*nx+ny*ny+nz*nz)", "#40e0a8")],
    "ask": "拖动两个平面的常数和法向量，观察平行平面间距的计算",
    "steps": ["平行平面 Ax+By+Cz+d₁=0 与 Ax+By+Cz+d₂=0", "距离 d=|d₁−d₂|/√(A²+B²+C²)", "|−6−3|/3=9/3=3"],
    "goal": "掌握平行平面之间的距离公式",
    "tip": "两个平面的法向量必须相同（或成比例）",
    "success": "对！距离为 3。",
}

specs["18-3 迁移：正方体内切球"] = {
    "sliders": [S("edge", 1, 5, 2, 0.5, "正方体棱长")],
    "readouts": [R("棱长", "edge"),
                 R("内切球直径 = 棱长", "edge", "#ffd479"),
                 R("内切球半径 r=edge/2", "edge/2", "#40e0a8")],
    "ask": "拖动正方体棱长，观察内切球半径与棱长的关系",
    "steps": ["内切球与各面相切", "直径等于棱长", "棱长为 2 时半径 r=1"],
    "goal": "理解正方体内切球的几何性质",
    "tip": "内切球与外接球不同",
    "success": "对！内切球半径为 1。",
}

specs["19-2 Boss-2 综合：异面直线夹角"] = {
    "sliders": [S("edge", 1, 4, 2, 1, "正方体棱长")],
    "readouts": [R("AC 向量 (edge,edge,0)", "edge + ', ' + edge + ', 0'"),
                 R("BD₁向量 (−edge,edge,edge)", "-edge + ', ' + edge + ', ' + edge", "#ffd479"),
                 R("AC·BD₁=−edge²+edge²+0", "-edge*edge+edge*edge+0", "#40e0a8")],
    "ask": "拖动棱长，观察异面直线的方向向量及其点积",
    "steps": ["建立坐标系：A(0,0,0)、C(edge,edge,0)、B(edge,0,0)、D₁(0,edge,edge)", "AC=(edge,edge,0)，BD₁=(−edge,edge,edge)", "AC·BD₁=−edge²+edge²+0=0，故两向量垂直"],
    "goal": "掌握用向量法求异面直线夹角",
    "tip": "异面直线夹角等于它们方向向量的夹角",
    "success": "对！两向量垂直，所成角为 90°，cosθ=0。",
}

if __name__ == '__main__':
    convert('space_levels.json', 'space', specs)
