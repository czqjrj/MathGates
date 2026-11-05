#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert recurrence_levels.json (数列递推) input questions to explore."""
import sys
sys.stdout.reconfigure(encoding='utf-8')

from convert_lib import S, R, convert

specs = {}

specs["1-5 综合：差是等比型的累加"] = {
    "sliders": [S("a1", 0, 5, 1, 1, "首项 a₁"),
                S("ratio", 1, 4, 2, 1, "公比 r (差为 rⁿ)")],
    "readouts": [R("a₂=a₁+r¹", "a1+ratio", "#ffd479"),
                 R("a₃=a₂+r²", "a1+ratio+ratio*ratio", "#40e0a8"),
                 R("a₄=a₃+r³", "a1+ratio+ratio*ratio+ratio**3", "#fb7185")],
    "ask": "拖动首项和公比，观察累加法求数列的通项",
    "steps": ["a_{n+1}−a_n=rⁿ", "累加得 a_n=a₁+(r¹+r²+⋯+r^{n−1})", "a₄=1+(2+4+8)=15"],
    "goal": "掌握差为等比型的累加法求数列",
    "tip": "注意累加时指数从 1 开始",
    "success": "对！a₄=15。",
}

specs["递推数列 · 迭代法求通项"] = {
    "sliders": [S("a1", 1, 10, 1, 1, "首项 a₁"),
                S("k", 1, 5, 2, 1, "系数 k (a_{n+1}=ka_n+c)"),
                S("c", 0, 5, 1, 1, "常数 c")],
    "readouts": [R("a₁", "a1", "#ffd479"),
                 R("a₂=ka₁+c", "k*a1+c", "#40e0a8"),
                 R("a₃=ka₂+c", "k*(k*a1+c)+c", "#fb7185")],
    "ask": "拖动参数，观察迭代法求递推数列的规律",
    "steps": ["a_{n+1}=ka_n+c", "迭代计算前几项找规律", "a₁=1、k=2、c=1 时 a_n=2ⁿ−1"],
    "goal": "掌握用迭代法求递推数列的通项",
    "tip": "先计算前几项，再归纳猜想通项",
    "success": "对！通项为 a_n=2ⁿ−1。",
}

specs["2-4 巩固：常比值的累乘"] = {
    "sliders": [S("a1", 1, 10, 3, 1, "首项 a₁"),
                S("ratio", 1, 5, 2, 1, "公比 q")],
    "readouts": [R("a₁", "a1", "#ffd479"),
                 R("a₂=a₁q", "a1*ratio", "#40e0a8"),
                 R("a₃=a₁q²", "a1*ratio*ratio", "#fb7185"),
                 R("a₄=a₁q³", "a1*ratio**3", "#5ee6ff")],
    "ask": "拖动首项和公比，观察等比数列的累乘规律",
    "steps": ["a_{n+1}=qa_n ⇒ a_n=a₁·q^{n−1}", "a₄=a₁·q³", "a₁=3、q=2 时 a₄=3×8=24"],
    "goal": "掌握等比数列的累乘法",
    "tip": "等比数列每项都是前一项乘以公比",
    "success": "对！a₄=24。",
}

specs["3-4 巩固：不动点的计算"] = {
    "sliders": [S("k", 1, 5, 3, 1, "系数 k (a_{n+1}=ka_n+c)"),
                S("c", -10, 10, -4, 1, "常数 c")],
    "readouts": [R("不动点满足 λ=kλ+c", "c/(1-k)", "#ffd479"),
                 R("解方程：λ(1−k)=c，得λ=c/(1−k)", "c/(1-k)", "#40e0a8"),
                 R("验证：代入递推式", "c/(1-k)", "#fb7185")],
    "ask": "拖动参数，观察递推数列的不动点计算",
    "steps": ["不动点定义：a_{n+1}=a_n=λ", "代入得λ=kλ+c，解出λ=c/(1−k)", "k=3、c=−4 时λ=−4/(1−3)=2"],
    "goal": "理解递推数列不动点的概念与计算",
    "tip": "不动点是递推关系稳定时的值",
    "success": "对！不动点λ=2。",
}

specs["4-4 巩固：等差部分的公差"] = {
    "sliders": [S("a1", 0.5, 5, 1, 0.5, "首项 a₁"),
                S("m", 1, 5, 3, 1, "分母系数 m (a_{n+1}=a_n/(ma_n+1))")],
    "readouts": [R("取倒数：1/a_{n+1}=(ma_n+1)/a_n=m+1/a_n", "m", "#ffd479"),
                 R("新数列 b_n=1/a_n 是等差数列", "m", "#40e0a8"),
                 R("公差 d=m", "m", "#fb7185")],
    "ask": "拖动参数，观察取倒数后数列变为等差数列",
    "steps": ["a_{n+1}=a_n/(ma_n+1)", "两边取倒数得 1/a_{n+1}=m+1/a_n", "故{1/a_n}是公差为 m 的等差数列", "m=3 时公差为 3"],
    "goal": "掌握通过取倒数转化递推数列为等差数列",
    "tip": "这类倒数型递推很常见",
    "success": "对！公差为 3。",
}

specs["5-4 巩固：取对数后的公差"] = {
    "sliders": [S("a1", 0.1, 10, 1, 0.5, "首项 a₁ (>0)"),
                S("p", 1, 4, 2, 1, "指数 p (a_{n+1}=a_n^p)")],
    "readouts": [R("取对数：log a_{n+1}=p·log a_n", "p", "#ffd479"),
                 R("若 a₁=1 则 log a₁=0", "0", "#40e0a8"),
                 R("故 log a_n≡0（常数列）", "0", "#fb7185")],
    "ask": "拖动参数，观察取对数后数列的性质",
    "steps": ["a_{n+1}=a_n^p", "取对数得 log a_{n+1}=p·log a_n", "若 a₁=1 则 log a₁=0，故 log a_n≡0", "公差为 0"],
    "goal": "掌握通过对数转化指数型递推数列",
    "tip": "当 a₁=1 时数列所有项都为 1",
    "success": "对！公差为 0。",
}

specs["6-4 巩固：由 Sn 求具体项"] = {
    "sliders": [S("n", 1, 10, 3, 1, "项数 n"),
                S("power", 1, 3, 2, 1, "Sn 的幂次")],
    "readouts": [R("S_n=n^power", "n**power", "#ffd479"),
                 R("S_{n-1}=(n-1)^power", "(n-1)**power", "#40e0a8"),
                 R("a_n=S_n−S_{n-1}", "n**power-(n-1)**power", "#fb7185")],
    "ask": "拖动 n 和幂次，观察由前 n 项和求具体项的方法",
    "steps": ["a_n=S_n−S_{n−1}(n≥2)", "已知 S_n=n²", "a₃=S₃−S₂=9−4=5"],
    "goal": "掌握由 S_n 求 a_n 的方法",
    "tip": "注意 n=1 时 a₁=S₁",
    "success": "对！a₃=5。",
}

if __name__ == '__main__':
    convert('recurrence_levels.json', 'recurrence', specs)
