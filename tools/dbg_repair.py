# -*- coding: utf-8 -*-
import sys, io, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import formula_repair as F

out = io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "dbg.txt"), "w", encoding="utf-8")

cases = [
    "振幅 |A|=2，最小正周期 T=2π/3。",
    "要求 $y>=0$ 且形式上给出",
    "已知 $$y>=0$$ 恒成立",
    "递推 aₙ₊₁=2aₙ，a₁=1，则通项 aₙ=？",
    "条件概率 $$P(A|B) 是在 B 发生的条件下 A 的占比，即缩小后的样本空间中求比例。",
    "在上一题情境中（掷骰子，已知奇数点），$$P(点数=3 | 奇数点) 应按哪个思路计算？",
    "满足 $|z-(1+i)|=2$ 的复数 $z$ 在复平面上的轨迹是？",
    "$$(-1,0)\\cup(0,1)\\cup(1,3]$$",
    "值域 $[1,+\\infty)$。",
    "比较 $$0.5^{0.3}$$ 与 $$1$$ 的大小",
]
for s in cases:
    log = []
    out.write(repr(s) + "\n  -> " + repr(F.repair_string(s, log)) + "\n")

# gap_convert 细节
for g in [" |A|=2", " y>=0 ", " a₁=1", " [1,+\\infty)", " P(A|B)", " =3 | ", " P(", ") "]:
    core = F.rt_trim(g)
    out.write("gap %r core=%r covered=%s strong=%s -> %r\n" % (
        g, core, core in F.COVERED, F.has_math_char(core), F.gap_convert(g)))
out.close()
print("ok")
