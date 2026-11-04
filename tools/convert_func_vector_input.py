#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert input questions in functions & vector chapters to explore, in place."""
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

DATA = r'E:\MathGates-main\data'
PI = "3.141592653589793"


def clean_q(q):
    if not q:
        return ""
    for pat in [r'（填数值[^）]*）', r'（保留[^）]*）', r'（精确[^）]*）', r'（填分数[^）]*）']:
        q = re.sub(pat, '', q)
    return q.rstrip('？? \n')


def make_explore(lab, orig, spec):
    return {
        "name": orig.get('name', ''),
        "type": "explore",
        "technique": spec.get('technique', orig.get('name', '')),
        "archetype": "LAB",
        "lab": lab,
        "q": clean_q(orig.get('q', '')) + "\n\n拖动下方滑块改变参数，观察读数如何实时变化。",
        "scene_data": {
            "range": spec.get('range', 8),
            "axes": spec.get('axes', False),
            "sliders": spec['sliders'],
            "readouts": spec['readouts'],
        },
        "ask": spec['ask'],
        "steps": spec.get('steps', []),
        "goal": spec['goal'],
        "tip": spec.get('tip', ''),
        "confirm": "看解析",
        "gate": True,
        "answers": {},
        "retry": spec.get('retry', '继续调整参数，观察规律是否始终成立。'),
        "hint": orig.get('hint') or '',
        "explain": orig.get('explain') or '',
        "success": spec.get('success', '很好！你已通过实验掌握了这个结论。'),
    }


def S(name, mn, mx, val, step=1, label=""):
    return {"name": name, "min": mn, "max": mx, "value": val, "step": step, "label": label}


def R(label, expr, color="#5ee6ff"):
    return {"label": label, "expr": expr, "color": color}


SPECS = {}

# ======================= functions =======================
SPECS[("functions_levels.json", "4-4 建构知识 · 分段函数的对应关系")] = {
    "sliders": [S("x", -4, 4, -2, 1, "输入 x")],
    "readouts": [R("内层 f(x)", "x+1 if x<0 else x*x"),
                 R("外层 f(f(x))", "((x+2) if x<-1 else pow(x+1,2)) if x<0 else pow(x*x,2)", "#ffd479"),
                 R("x=-2 时", "f(f(-2)) = 0", "#40e0a8")],
    "ask": "拖动 x，观察分段函数『先内后外』的计算过程",
    "steps": ["x=-2<0，用第一段 f(-2)=-1", "-1<0，仍用第一段 f(-1)=0", "所以 f(f(-2))=0"],
    "goal": "掌握分段函数复合时逐层判断所在区间",
    "tip": "先算内层，再看内层结果落在哪一段",
    "success": "对！f(f(-2))=0。",
}
SPECS[("functions_levels.json", "6-5 迁移应用 · 含参奇偶性求参数")] = {
    "sliders": [S("a", -3, 3, 1, 0.5, "参数 a")],
    "readouts": [R("f(1)=a+3", "a+3"),
                 R("f(-1)=5-a", "5-a", "#ffd479"),
                 R("是否为偶函数", "\"是\" if f1==f_1 else \"否\"", "#40e0a8")],
    "ask": "拖动 a，找出使 f(x) 成为偶函数的取值",
    "steps": ["偶函数要求 f(-x)=f(x)", "比较 f(1) 与 f(-1)", "a+3=5-a ⇒ a=1"],
    "goal": "掌握利用 f(-x)=f(x) 求含参偶函数参数",
    "tip": "偶函数不能含奇次项",
    "success": "对！a=1 时一次项消失，函数为偶函数。",
}
SPECS[("functions_levels.json", "8-7 迁移：对数式求值")] = {
    "sliders": [S("base", 2, 5, 2, 1, "底数 b"), S("n", 1, 5, 3, 1, "指数 n")],
    "readouts": [R("bⁿ", "pow(base,n)"),
                 R("log_b(bⁿ)", "n", "#ffd479"),
                 R("原题 log₂8", "3", "#40e0a8")],
    "ask": "拖动底数与指数，观察 log_b(bⁿ)=n 恒成立",
    "steps": ["把 8 写成 2³", "log₂(2³)=3", "对数的本质是『求指数』"],
    "goal": "掌握对数的定义与基本求值",
    "tip": "log 就是问『底数要几次方得到真数』",
    "success": "对！log₂8=3。",
}
SPECS[("functions_levels.json", "9-2 建构：迭代递推")] = {
    "sliders": [S("f1", -5, 10, 2, 1, "f(1)"), S("c", 0, 5, 3, 1, "每次增加 c")],
    "readouts": [R("f(2)=f(1)+c", "f1+c"),
                 R("f(3)=f(2)+c", "f1+2*c", "#ffd479"),
                 R("f(4)", "f1+3*c", "#40e0a8")],
    "ask": "拖动初值与增量，观察递推 f(x+1)=f(x)+c 的结果",
    "steps": ["令 x=1 代入递推式", "f(2)=f(1)+3", "得 f(2)=5"],
    "goal": "掌握由递推式逐项求函数值",
    "tip": "每步加上同一个增量",
    "success": "对！f(2)=5。",
}
SPECS[("functions_levels.json", "9-3 迁移：赋值求值")] = {
    "sliders": [S("f2", 0, 10, 5, 1, "f(2)")],
    "readouts": [R("f(4)=f(2+2)", "f2+f2"),
                 R("f(2x)=2f(x)", "2*f2", "#ffd479"),
                 R("结果", "2*f2", "#40e0a8")],
    "ask": "拖动 f(2)，观察可加性如何决定 f(4)",
    "steps": ["f(4)=f(2+2)=f(2)+f(2)", "即 f(4)=2f(2)", "得 10"],
    "goal": "掌握抽象函数赋值法",
    "tip": "把 4 拆成 2+2",
    "success": "对！f(4)=10。",
}
SPECS[("functions_levels.json", "12-2 建构：二次函数模型")] = {
    "sliders": [S("x", 0, 20, 10, 1, "定价 x")],
    "readouts": [R("利润 y=-x²+20x", "x*(20-x)"),
                 R("配方 y=-(x-10)²+100", "100-pow(x-10,2)", "#ffd479"),
                 R("是否达到最大", "\"最大 100\" if x==10 else \"未达最大\"", "#40e0a8")],
    "ask": "拖动定价 x，观察利润在何处达到最大",
    "steps": ["配方 y=-(x-10)²+100", "顶点 x=10", "最大利润 100"],
    "goal": "掌握二次函数模型求最大利润",
    "tip": "开口向下，顶点处取最大",
    "success": "对！x=10 时利润最大为 100。",
}
SPECS[("functions_levels.json", "13-2 建构：取中点")] = {
    "sliders": [S("x", -1, 1, 0.5, 0.05, "区间内取点 x")],
    "readouts": [R("f(x)=x²+x-1", "x*x+x-1"),
                 R("x=0.5 时", "-0.25", "#ffd479"),
                 R("符号", "\"负\" if x*x+x-1<0 else \"非负\"", "#40e0a8")],
    "ask": "拖动 x，观察二分法中取中点后的函数值符号",
    "steps": ["f(0.5)=0.25+0.5-1", "得 -0.25", "说明根在右半区间"],
    "goal": "理解二分法取中点判断符号的思想",
    "tip": "函数值变号说明区间内有根",
    "success": "对！f(0.5)=-0.25<0。",
}
SPECS[("functions_levels.json", "14-4 巩固：拟合定参")] = {
    "sliders": [S("y1", 1, 20, 6, 1, "x=1 时的 y"), S("y2", 1, 60, 18, 1, "x=2 时的 y")],
    "readouts": [R("底数 b=y₂/y₁", "y2/y1"),
                 R("系数 a=y₁/b", "y1/(y2/y1)", "#ffd479"),
                 R("模型", "y = a·bˣ", "#40e0a8")],
    "ask": "拖动两点函数值，观察指数模型的底数如何确定",
    "steps": ["代入得 ab=6、ab²=18", "两式相除得 b=3", "a=2，模型 y=2·3ˣ"],
    "goal": "掌握由两点确定指数模型参数",
    "tip": "两式相除可消去系数 a",
    "success": "对！b=3。",
}
SPECS[("functions_levels.json", "14-5 综合：复利模型")] = {
    "sliders": [S("P", 500, 2000, 1000, 50, "本金 P"), S("r", 0.01, 0.2, 0.05, 0.01, "年利率 r"), S("n", 1, 10, 2, 1, "年数 n")],
    "readouts": [R("本利和 P(1+r)ⁿ", "P*pow(1+r,n)"),
                 R("利息", "P*pow(1+r,n)-P", "#ffd479"),
                 R("原题 1000·1.05²", "1102.5", "#40e0a8")],
    "ask": "拖动本金、利率、年数，观察复利的指数增长",
    "steps": ["第一年末 1000×1.05", "第二年末再乘 1.05", "得 1102.5 元"],
    "goal": "掌握复利模型 y=a(1+r)ˣ",
    "tip": "每一年都在上一年的基础上乘 (1+r)",
    "success": "对！2 年后本利和 1102.5 元。",
}

# ======================= vector =======================
SPECS[("vector_levels.json", "1-1 平面向量的概念")] = {
    "sliders": [S("vx", -5, 5, 3, 1, "向量 x 分量"), S("vy", -5, 5, 4, 1, "向量 y 分量")],
    "readouts": [R("模长 |v|=√(x²+y²)", "sqrt(vx*vx+vy*vy)"),
                 R("方向角（度）", "atan2(vy,vx)*180/" + PI, "#ffd479"),
                 R("平移后是否改变", "\"不变（自由向量）\"", "#40e0a8")],
    "ask": "拖动分量，观察向量只由大小和方向决定",
    "steps": ["改变分量改变模长与方向", "平移不改变向量本身", "相等需大小与方向都相同"],
    "goal": "理解向量的自由性与相等条件",
    "tip": "向量≠有向线段，位置无关",
    "success": "对！向量只由大小和方向决定。",
}
SPECS[("vector_levels.json", "5-2 减法与相反向量")] = {
    "sliders": [S("ax", -5, 5, 2, 1, "a 的 x 分量"), S("ay", -5, 5, 3, 1, "a 的 y 分量"), S("bx", -5, 5, 1, 1, "b 的 x 分量"), S("by", -5, 5, 1, 1, "b 的 y 分量")],
    "readouts": [R("a-b", "\"(\"+str(ax-bx)+\", \"+str(ay-by)+\")\""),
                 R("b-a", "\"(\"+str(bx-ax)+\", \"+str(by-ay)+\")\"", "#ffd479"),
                 R("关系", "a-b = -(b-a)", "#40e0a8")],
    "ask": "拖动两向量，观察差向量与相反向量的关系",
    "steps": ["a-b 逐分量相减", "a-b=-(b-a)", "方向相反、模长相等"],
    "goal": "理解向量减法与相反向量",
    "tip": "减去一个向量等于加上它的相反向量",
    "success": "对！a−b=a+(−b)。",
}
SPECS[("vector_levels.json", "8-2 坐标形式的线性运算")] = {
    "sliders": [S("ax", -5, 5, 1, 1, "a 的 x 分量"), S("ay", -5, 5, 2, 1, "a 的 y 分量"), S("bx", -5, 5, 3, 1, "b 的 x 分量"), S("by", -5, 5, -1, 1, "b 的 y 分量")],
    "readouts": [R("2a-b", "\"(\"+str(2*ax-bx)+\", \"+str(2*ay-by)+\")\""),
                 R("2a", "\"(\"+str(2*ax)+\", \"+str(2*ay)+\")\"", "#ffd479"),
                 R("a=(1,2),b=(3,-1) 时", "(-1, 5)", "#40e0a8")],
    "ask": "拖动分量，观察坐标形式下 2a−b 的逐分量运算",
    "steps": ["先算 2a=(2,4)", "再逐坐标减 b", "得 (-1,5)"],
    "goal": "掌握坐标形式的向量线性运算",
    "tip": "系数乘每个分量，再对应相减",
    "success": "对！2a−b=(−1,5)。",
}
SPECS[("vector_levels.json", "8-3 坐标的点积求值")] = {
    "sliders": [S("ax", -5, 5, 2, 1, "a 的 x 分量"), S("ay", -5, 5, 1, 1, "a 的 y 分量"), S("bx", -5, 5, 1, 1, "b 的 x 分量"), S("by", -5, 5, 2, 1, "b 的 y 分量")],
    "readouts": [R("a·b=x₁x₂+y₁y₂", "ax*bx+ay*by"),
                 R("模长积 |a||b|", "sqrt(ax*ax+ay*ay)*sqrt(bx*bx+by*by)", "#ffd479"),
                 R("夹角余弦", "(ax*bx+ay*by)/(sqrt(ax*ax+ay*ay)*sqrt(bx*bx+by*by))", "#40e0a8")],
    "ask": "拖动分量，观察点积与夹角余弦的关系",
    "steps": ["对应坐标相乘再相加", "a·b=2×1+1×2=4", "cosθ=a·b/(|a||b|)"],
    "goal": "掌握坐标形式的点积公式",
    "tip": "点积是标量，不是向量",
    "success": "对！a·b=4。",
}
SPECS[("vector_levels.json", "10-4 Dot Product Formula Derivation")] = {
    "sliders": [S("ax", -5, 5, 2, 1, "x₁"), S("ay", -5, 5, 1, 1, "y₁"), S("bx", -5, 5, 1, 1, "x₂"), S("by", -5, 5, 3, 1, "y₂")],
    "readouts": [R("几何定义 |a||b|cosθ", "sqrt(ax*ax+ay*ay)*sqrt(bx*bx+by*by)*((ax*bx+ay*by)/(sqrt(ax*ax+ay*ay)*sqrt(bx*bx+by*by)))"),
                 R("坐标展开 x₁x₂+y₁y₂", "ax*bx+ay*by", "#ffd479"),
                 R("两者相等？", "相等", "#40e0a8")],
    "ask": "拖动分量，验证几何定义与坐标展开给出同一个点积",
    "steps": ["由 a·b=|a||b|cosθ", "用坐标表示模长与余弦", "化简即得 x₁x₂+y₁y₂"],
    "goal": "理解点积坐标公式的推导",
    "tip": "把 cosθ 用坐标点积与模长表示",
    "success": "对！两种定义完全一致。",
}
SPECS[("vector_levels.json", "11-1 Vector Projection Calculation")] = {
    "sliders": [S("ax", -6, 6, 3, 1, "a 的 x 分量"), S("ay", -6, 6, 4, 1, "a 的 y 分量"), S("bx", -6, 6, 1, 1, "b 的 x 分量"), S("by", -6, 6, 2, 1, "b 的 y 分量")],
    "readouts": [R("a·b", "ax*bx+ay*by"),
                 R("|b|", "sqrt(bx*bx+by*by)", "#ffd479"),
                 R("投影 (a·b)/|b|", "(ax*bx+ay*by)/sqrt(bx*bx+by*by)", "#40e0a8")],
    "ask": "拖动分量，观察数量投影如何随点积与模长变化",
    "steps": ["先算 a·b", "再算 |b|", "投影=(a·b)/|b|≈4.91"],
    "goal": "掌握数量投影公式",
    "tip": "投影可正可负，取决于夹角",
    "success": "对！投影≈4.91。",
}
SPECS[("vector_levels.json", "11-1 坐标形式的求值")] = {
    "sliders": [S("ax", -5, 5, 3, 1, "a 的 x 分量"), S("ay", -5, 5, 1, 1, "a 的 y 分量"), S("bx", -5, 5, 1, 1, "b 的 x 分量"), S("by", -5, 5, 2, 1, "b 的 y 分量")],
    "readouts": [R("a·b=x₁x₂+y₁y₂", "ax*bx+ay*by"),
                 R("a=(3,1),b=(1,2) 时", "5", "#ffd479"),
                 R("夹角余弦", "(ax*bx+ay*by)/(sqrt(ax*ax+ay*ay)*sqrt(bx*bx+by*by))", "#40e0a8")],
    "ask": "拖动分量，观察点积随坐标的变化",
    "steps": ["对应坐标相乘再相加", "3×1+1×2=5", "用点积可求夹角"],
    "goal": "巩固坐标形式的点积计算",
    "tip": "先乘后加，别漏项",
    "success": "对！a·b=5。",
}
SPECS[("vector_levels.json", "13-1 数量投影")] = {
    "sliders": [S("la", 0.5, 4, 1, 0.1, "|a|"), S("lb", 0.5, 4, 2, 0.1, "|b|"), S("theta", 0, 180, 120, 1, "夹角 θ（度）")],
    "readouts": [R("数量投影 |b|cosθ", "lb*cos(" + PI + "*theta/180)"),
                 R("θ=120° 时", "-1", "#ffd479"),
                 R("符号", "\"正（锐角）\" if theta<90 else (\"零（直角）\" if theta==90 else \"负（钝角）\")", "#40e0a8")],
    "ask": "拖动夹角与模长，观察数量投影如何由钝角变负",
    "steps": ["数量投影=|b|cosθ", "cos120°=−1/2", "得 −1"],
    "goal": "掌握数量投影及其符号意义",
    "tip": "钝角时投影为负",
    "success": "对！投影为 −1。",
}

LABMAP = {
    'functions_levels.json': 'functions',
    'vector_levels.json': 'vector',
}


def main():
    total_converted = 0
    missing = []
    for filename, lab in LABMAP.items():
        path = os.path.join(DATA, filename)
        data = json.load(open(path, 'r', encoding='utf-8'))
        before = {}
        for sec in data.values():
            for q in sec.get('levels', []):
                t = q.get('type', 'choice')
                before[t] = before.get(t, 0) + 1

        converted = 0
        for sec_key, sec in data.items():
            for i, q in enumerate(sec.get('levels', [])):
                if q.get('type') != 'input':
                    continue
                spec = SPECS.get((filename, q.get('name')))
                if not spec:
                    missing.append((filename, q.get('name')))
                    continue
                sec['levels'][i] = make_explore(lab, q, spec)
                converted += 1

        after = {}
        for sec in data.values():
            for q in sec.get('levels', []):
                t = q.get('type', 'choice')
                after[t] = after.get(t, 0) + 1

        json.dump(data, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
        total_converted += converted

        print("=" * 66)
        print(filename)
        print("  before:", before)
        print("  after :", after)
        print("  converted:", converted)

    print("=" * 66)
    print("TOTAL converted:", total_converted)
    if missing:
        print("MISSING SPECS:")
        for m in missing:
            print("  ", m)
    else:
        print("All input questions have specs. [OK]")


if __name__ == '__main__':
    main()
