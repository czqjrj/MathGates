# -*- coding: utf-8 -*-
"""formula_repair 单元样测：从真实数据抓问题字符串，打印修复前后。"""
import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
import formula_repair as F   # 内部已包装 stdout 为 utf-8

SAMPLES = [
    ("trig",  "已知 $$\\\\sin\\\\\\\\alpha$$=3/5，$\\\\\\\\alpha$$$$\\\\\\\\in$$($$\\\\\\\\pi$$/2, $$\\\\\\\\pi$$)，则 sin($$\\\\\\\\pi$$+$$\\\\\\\\alpha$$)=？（填数值）"),
    ("trig2", "不随 $$\\\\\\\\\\\\theta$$ 变化"),
    ("pi",    "T=2$$\\\\\\\\\\\\pi$$/ω；A 决定振幅，ω 决定周期，二者互不影响。"),
    ("rv",    "$$$$P(X\\\\g$$e_{3}$$)=C_4^{3}\\\\time$$s_{0}$$.9^{3}\\\\time$$s_{0}$$.1+0.9^{4}=0.2916+0.6561\\\\appro$$x_{0}$$.948$$。"),
    ("prob",  "条件概率 $$P(A|B) 是在 B 发生的条件下 A 的占比，即缩小后的样本空间中求比例。"),
    ("prob2", "独立事件 $$P(AB)=$$P(A)$$P(B)。"),
    ("prob3", "承上，$$D(X)=$$\\sum$$(x−$$E(X))²$$P(x)，其值为？（填数值）"),
    ("prob4", "在上一题情境中（掷骰子，已知奇数点），$$P(点数=3 | 奇数点) 应按哪个思路计算？"),
    ("func",  "某物理量的计算式为 $$y=\\ln x + \x0crac{\\sqrt{3-x}}{x^2-1}$$，要使 $y$ 有意义，$x$ 的取值范围是？"),
    ("vec",   "已知 $$\\\\vec{a}=$(3,4)$$、$\\\\vec{b}=$(5,0)$$，则 b 在 a 方向上的投影长度是？（填数值）"),
    ("vec2",  "基底要求不共线（且均非零）。$$\\\\vec{a}=$(1,2)、$$\\\\vec{b}=$(2,4) 与 $$\\\\vec{a}=$(2,3)、$$\\\\vec{b}=$(4,6) 这两组都满足 $$\\\\vec{b}=$2a$$ 因而共线；含零向量的那组也不行；只有 $$e_1$$、$$e_2$$ 这一组不共线。"),
    ("cx",    "复数 $z=3+4i$ 对应的点到原点的距离是多少？"),
    ("cx2",   "$i^{2023}=$？"),
    ("uni",   "递推 aₙ₊₁=2aₙ，a₁=1，则通项 aₙ=？"),
    ("uni2",  "集合 A∩B={3,7}，则满足 A∪B={1,2,3,5,6,7} 的 C 有？"),
    ("uni3",  "y=sinx+√3·cosx 的最小正周期是 2π。"),
    ("ok",    "这是一句没有公式的普通文案，只有中文与 123 数字。"),
    ("boss",  "Boss · 星数门槛 30★"),
    ("dot",   "振幅 |A|=2，最小正周期 T=2π/3。"),
    ("th",    "由 $$(\\sin\\theta+\\cos\\theta)^{2}=1+2\\sin\\theta\\cos\\theta=\\left(\\frac{1}{2}\\right)^{2}=\\frac{1}{4}$$，\n得 $$2\\sin\\theta\\cos\\theta=\\frac{1}{4}-1=-\\frac{3}{4}$$。"),
]

out = []
for name, s in SAMPLES:
    log = []
    r = F.repair_string(s, log)
    out.append("== [%s]" % name)
    out.append("  IN : %r" % s)
    out.append("  OUT: %r" % r)
    out.append("  改变: %s %s" % (r != s, ("LOG:" + str(log) if log else "")))
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "test_repair_out.txt"), "w", encoding="utf-8") as f:
    f.write("\n".join(out))
print("written test_repair_out.txt")
