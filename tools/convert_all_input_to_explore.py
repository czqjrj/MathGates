#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert ALL real input (fill-in-blank) questions into explore questions, in place.
Each converted question gets tailored sliders + real-time readouts.
"""
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

DATA = r'E:\MathGates-main\data'
PI = "3.141592653589793"

# ---------------------------------------------------------------- helpers
def clean_q(q):
    if not q:
        return ""
    q = re.sub(r'（填数值[^）]*）', '', q)
    q = re.sub(r'（保留[^）]*）', '', q)
    q = re.sub(r'（精确[^）]*）', '', q)
    q = re.sub(r'（填分数[^）]*）', '', q)
    q = re.sub(r'（填数值，单位 m）', '', q)
    q = q.rstrip('？? \n')
    return q


def make_explore(lab, orig, spec):
    qtext = clean_q(orig.get('q', ''))
    if spec.get('q_override'):
        qtext = spec['q_override']
    return {
        "name": orig.get('name', ''),
        "type": "explore",
        "technique": spec.get('technique', orig.get('name', '')),
        "archetype": "LAB",
        "lab": lab,
        "q": qtext + "\n\n拖动下方滑块改变参数，观察读数如何实时变化。",
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


# ---------------------------------------------------------------- specs
# key = (filename, original question name)
SPECS = {}

# ===================== set_logic =====================
SPECS[("set_logic_levels.json", "2-5 综合：补集区间")] = {
    "sliders": [S("a", 0, 4, 1, 1, "左端点 a"), S("b", 5, 9, 5, 1, "右端点 b")],
    "readouts": [R("集合 A", "\"(\" + str(a) + \",\" + str(b) + \")\""),
                 R("补集 ∁ᵣA", "\"(-∞,\" + str(a) + \"] ∪ [\" + str(b) + \",+∞)\"", "#ffd479"),
                 R("端点 a 是否取到", "\"取到（闭）\"", "#40e0a8")],
    "ask": "观察：开区间 (a,b) 的补集为什么在两个端点处都取到？",
    "steps": ["拖动 a、b 改变区间位置", "观察补集端点括号由圆括号变方括号", "总结开区间补集的端点取舍"],
    "goal": "理解开区间补集包含端点，即 ∁ᵣ(a,b)=(-∞,a]∪[b,+∞)",
    "tip": "A 不含端点，补集就要把端点补回来",
    "success": "对！开区间的补集在端点处取闭。",
}
SPECS[("set_logic_levels.json", "3-5 综合：由充分条件反求参数")] = {
    "sliders": [S("a", -2, 6, 3, 1, "参数 a")],
    "readouts": [R("p 对应集合 (a,+∞)", "\"(\" + str(a) + \",+∞)\""),
                 R("q 对应集合 (2,+∞)", "\"(2,+∞)\"", "#ffd479"),
                 R("p 与 q 的关系", "\"p 是 q 的充分不必要\" if a>2 else (\"p 与 q 等价\" if a==2 else \"p 是 q 的必要不充分\")", "#40e0a8"),
                 R("a 的最小整数值", "\"3\" if a>2 else \"不存在（a>2 才行）\"", "#fb7185")],
    "ask": "拖动 a，观察什么时候 p 是 q 的充分不必要条件？",
    "steps": ["把 a 调到 2 观察关系", "把 a 调大 / 调小分别观察", "找到使 p 真包含于 q 的最小整数 a"],
    "goal": "理解充分不必要条件的集合刻画：(a,+∞)⊊(2,+∞) 即 a>2",
    "tip": "小圈推大圈：p 的集合要真包含于 q 的集合",
    "success": "很好！a>2 时 p⇒q 但 q⇏p，最小整数是 3。",
}
SPECS[("set_logic_levels.json", "4-5 综合：由存在命题为真求参数")] = {
    "sliders": [S("m", -3, 5, 1, 1, "参数 m")],
    "readouts": [R("x²+2x+m 的最小值", "m-1"),
                 R("命题为真条件", "\"m < 1\"", "#ffd479"),
                 R("当前命题真假", "\"真\" if m-1<0 else \"假\"", "#40e0a8")],
    "ask": "拖动 m，找出使存在命题为真的临界值",
    "steps": ["配方得 (x+1)²+m-1", "最小值 m-1 必须小于 0", "解出 m<1，上界为 1"],
    "goal": "掌握存在命题为真 ⇔ 相应二次式最小值小于 0",
    "tip": "存在性只看最小值是否落在条件里",
    "success": "对！m<1 时存在 x 使命题为真，上界 1。",
}
SPECS[("set_logic_levels.json", "6-2 建构：card 容斥公式")] = {
    "sliders": [S("size_A", 0, 60, 40, 1, "|A|"), S("size_B", 0, 60, 30, 1, "|B|"), S("size_inter", 0, 30, 15, 1, "|A∩B|")],
    "readouts": [R("|A∪B|", "size_A + size_B - size_inter"),
                 R("容斥公式", "|A|+|B|-|A∩B|", "#ffd479"),
                 R("计算过程", "str(size_A)+\"+\"+str(size_B)+\"-\"+str(size_inter)", "#40e0a8")],
    "ask": "拖动三个量，观察并集元素数如何随交集变化",
    "steps": ["固定 |A|、|B|，只改交集", "交集越大，并集越小", "验证 |A∪B|=|A|+|B|-|A∩B|"],
    "goal": "掌握容斥原理 |A∪B|=|A|+|B|-|A∩B|",
    "tip": "交集被算了两次，要减掉一次",
    "success": "对！40+30-15=55。",
}
SPECS[("set_logic_levels.json", "6-3 迁移：反推一个集合的基数")] = {
    "sliders": [S("union", 10, 80, 50, 1, "|A∪B|"), S("size_B", 0, 60, 30, 1, "|B|"), S("size_inter", 0, 30, 10, 1, "|A∩B|")],
    "readouts": [R("反推 |A|", "union - size_B + size_inter"),
                 R("公式移项", "|A|=|A∪B|-|B|+|A∩B|", "#ffd479"),
                 R("计算过程", "str(union)+\"-\"+str(size_B)+\"+\"+str(size_inter)", "#40e0a8")],
    "ask": "把容斥公式移项，观察如何反推 |A|",
    "steps": ["由 |A∪B|=|A|+|B|-|A∩B| 移项", "代入已知量", "验证 50-30+10=30"],
    "goal": "掌握容斥公式的灵活变形",
    "tip": "三个量已知其二即可求第三",
    "success": "对！|A|=30。",
}
SPECS[("set_logic_levels.json", "6-4 巩固：都不喜欢的怎么算")] = {
    "sliders": [S("total", 30, 80, 52, 1, "全班人数"), S("size_A", 0, 60, 30, 1, "参加 A"), S("size_B", 0, 60, 25, 1, "参加 B"), S("size_inter", 0, 20, 12, 1, "两组都参加")],
    "readouts": [R("至少参加一组", "size_A + size_B - size_inter"),
                 R("都不参加", "total - (size_A + size_B - size_inter)", "#fb7185"),
                 R("计算过程", "str(total)+\"-(\"+str(size_A)+\"+\"+str(size_B)+\"-\"+str(size_inter)+\")\"", "#40e0a8")],
    "ask": "拖动人数，观察『都不参加』如何用容斥原理算出",
    "steps": ["先算至少参加一组的人数", "再用全班人数相减", "验证 52-43=9"],
    "goal": "掌握容斥原理在实际计数问题中的应用",
    "tip": "先并集，再补集",
    "success": "对！都不参加的有 9 人。",
}
SPECS[("set_logic_levels.json", "6-5 综合：子集个数与元素个数")] = {
    "sliders": [S("n", 0, 8, 4, 1, "元素个数 n")],
    "readouts": [R("子集个数 2ⁿ", "pow(2,n)"),
                 R("真子集个数 2ⁿ-1", "pow(2,n)-1", "#ffd479"),
                 R("是否恰为 15", "\"是\" if pow(2,n)-1==15 else \"否\"", "#40e0a8")],
    "ask": "拖动 n，观察真子集个数如何变化，找出等于 15 的 n",
    "steps": ["列出 n=1,2,3,4 时的真子集数", "发现 2ⁿ-1=15", "解得 n=4"],
    "goal": "掌握含 n 个元素的集合有 2ⁿ 个子集、2ⁿ-1 个真子集",
    "tip": "真子集要排除集合本身",
    "success": "对！n=4 时真子集恰有 15 个。",
}
SPECS[("set_logic_levels.json", "7-4 巩固：夹在两集合之间")] = {
    "sliders": [S("take2", 0, 1, 1, 1, "是否取元素 2"), S("take3", 0, 1, 1, 1, "是否取元素 3")],
    "readouts": [R("集合 A 是否含 1", "\"含（必须）\"", "#40e0a8"),
                 R("A 的元素个数", "1 + take2 + take3"),
                 R("满足条件的 A 的个数", "4", "#ffd479")],
    "ask": "切换元素 2、3 的取舍，数一数共能得到几个集合 A",
    "steps": ["A 必含 1", "元素 2 有两种选择", "元素 3 有两种选择，共 2×2=4 个"],
    "goal": "理解『夹在中间』的集合计数：2 的（可选元素个数）次方",
    "tip": "每个可选元素独立地取或不取",
    "success": "对！2²=4 个：{1}、{1,2}、{1,3}、{1,2,3}。",
}
SPECS[("set_logic_levels.json", "7-5 综合：互异性筛根")] = {
    "sliders": [S("a", -3, 4, -1, 1, "参数 a")],
    "readouts": [R("a²-a", "a*a-a"),
                 R("集合 A", "str(1)+\",\"+str(a)+\",\"+str(a*a-a)", "#ffd479"),
                 R("检验", "\"互异且含2 ✓\" if (a*a-a!=1 and a!=1 and a*a-a!=a and (a==2 or a*a-a==2)) else (\"含2但有重复 ✗\" if (a==2 or a*a-a==2) else \"不含2\")", "#40e0a8")],
    "ask": "拖动 a，找出既满足 2∈A 又满足互异性的取值",
    "steps": ["尝试 a=2，发现集合出现重复元素", "再令 a²-a=2 求根", "筛掉重复的根，得到 a=-1"],
    "goal": "掌握集合元素的互异性在求参数时的筛选作用",
    "tip": "求出根后一定要代回检验互异性",
    "success": "对！a=2 会造成重复元素，只有 a=-1 合格。",
}
SPECS[("set_logic_levels.json", "8-4 巩固：补集与 card 联用")] = {
    "sliders": [S("u_size", 10, 50, 30, 1, "|U|"), S("size_A", 0, 30, 10, 1, "|A|"), S("size_B", 0, 30, 8, 1, "|B|"), S("size_inter", 0, 15, 3, 1, "|A∩B|")],
    "readouts": [R("|A∪B|", "size_A + size_B - size_inter"),
                 R("补集元素数", "u_size - (size_A + size_B - size_inter)", "#fb7185"),
                 R("计算过程", "str(u_size)+\"-(\"+str(size_A)+\"+\"+str(size_B)+\"-\"+str(size_inter)+\")\"", "#40e0a8")],
    "ask": "拖动参数，观察补集元素数如何由容斥公式推出",
    "steps": ["先算 |A∪B|", "再用全集总数相减", "验证 30-15=15"],
    "goal": "掌握补集与容斥原理的联用",
    "tip": "∁ᵤ(A∪B) 的元素数 = |U| - |A∪B|",
    "success": "对！补集有 15 个元素。",
}

# ===================== function_lab =====================
SPECS[("function_lab_levels.json", "1-5 综合应用 · 值域为 R 的判定")] = {
    "sliders": [S("a", -3, 3, 0, 0.5, "参数 a")],
    "readouts": [R("右段值域 [1,+∞)", "1", "#5ee6ff"),
                 R("左段值域 (-∞,1+a)", "1+a", "#ffd479"),
                 R("拼接结果", "\"值域为 R\" if 1+a>=1 else \"中间有缝\"", "#40e0a8"),
                 R("a 的最小值", "\"0\"", "#fb7185")],
    "ask": "拖动 a，观察两段值域何时恰好拼满整个实数轴",
    "steps": ["右段 x≥1 时值域从 1 起", "左段 x<1 时值域上界为 1+a", "要求 1+a≥1 才无缝"],
    "goal": "掌握分段函数值域拼接的条件",
    "tip": "两段值域的上、下界要接上",
    "success": "对！a≥0 时值域为 R，最小值 0。",
}
SPECS[("function_lab_levels.json", "3-3 迁移：两种复合不相等")] = {
    "sliders": [S("x", -2, 3, 1, 1, "输入 x")],
    "readouts": [R("g(x)=x²", "x*x"),
                 R("f(g(x))=2^(x²)", "pow(2, x*x)", "#ffd479"),
                 R("g(f(x))=(2ˣ)²", "pow(pow(2,x),2)", "#fb7185"),
                 R("两者相等？", "\"相等\" if pow(2,x*x)==pow(pow(2,x),2) else \"不相等\"", "#40e0a8")],
    "ask": "拖动 x，比较 f(g(x)) 与 g(f(x)) 是否相同",
    "steps": ["先算里层 g(x)", "再代入外层 f", "交换内外顺序再比较"],
    "goal": "理解复合函数一般不满足交换律，顺序不同结果不同",
    "tip": "复合要从里往外算",
    "success": "对！x=1 时 f(g(1))=2，而 g(f(1))=4。",
}
SPECS[("function_lab_levels.json", "4-3 迁移：一对互逆的函数值")] = {
    "sliders": [S("x0", -3, 5, 2, 1, "原函数输入 x₀"), S("y0", -3, 8, 5, 1, "原函数输出 y₀")],
    "readouts": [R("f(x₀)=y₀", "str(y0)", "#5ee6ff"),
                 R("f⁻¹(y₀)=x₀", "str(x0)", "#ffd479"),
                 R("对称点", "\"(\"+str(x0)+\",\"+str(y0)+\") ↔ (\"+str(y0)+\",\"+str(x0)+\")\"", "#40e0a8")],
    "ask": "拖动 x₀、y₀，观察反函数如何把输入输出对调",
    "steps": ["点 (x₀,y₀) 在原函数上", "镜像点 (y₀,x₀) 在反函数上", "所以 f⁻¹(5)=2"],
    "goal": "掌握反函数把定义域与值域对调的对称性质",
    "tip": "反函数就是把 x 和 y 互换",
    "success": "对！f(2)=5 ⇒ f⁻¹(5)=2。",
}
SPECS[("function_lab_levels.json", "5-2 建构：轴在区间左侧")] = {
    "sliders": [S("L", 0, 3, 0, 1, "左端点 L"), S("R", 0, 3, 3, 1, "右端点 R")],
    "readouts": [R("对称轴 x=-1", "-1", "#5ee6ff"),
                 R("f(L)", "L*L+2*L+2", "#ffd479"),
                 R("f(R)", "R*R+2*R+2", "#fb7185"),
                 R("区间最小值", "L*L+2*L+2", "#40e0a8")],
    "ask": "拖动区间端点，观察轴在左侧时最小值出现在哪一端",
    "steps": ["配方 (x+1)²+1", "轴 x=-1 在区间左侧", "函数在区间上递增，最小值在左端点"],
    "goal": "掌握轴在区间外时，最值在离轴较近的端点取得",
    "tip": "轴在左边，区间上单调递增",
    "success": "对！最小值 f(0)=2。",
}
SPECS[("function_lab_levels.json", "5-3 迁移：轴在区间右侧")] = {
    "sliders": [S("L", -2, 0, -1, 1, "左端点 L"), S("R", -2, 0, 0, 1, "右端点 R")],
    "readouts": [R("对称轴 x=2", "2", "#5ee6ff"),
                 R("f(L)", "L*L-4*L+5", "#ffd479"),
                 R("f(R)", "R*R-4*R+5", "#fb7185"),
                 R("区间最小值", "R*R-4*R+5", "#40e0a8")],
    "ask": "拖动区间端点，观察轴在右侧时最小值出现在哪一端",
    "steps": ["配方 (x-2)²+1", "轴 x=2 在区间右侧", "函数在区间上递减，最小值在右端点"],
    "goal": "掌握轴在区间外时，最值在离轴较近的端点取得",
    "tip": "轴在右边，区间上单调递减",
    "success": "对！最小值 f(0)=5。",
}
SPECS[("function_lab_levels.json", "5-4 巩固：开口向下找最大")] = {
    "sliders": [S("L", 0, 2, 0, 1, "左端点 L"), S("R", 0, 2, 2, 1, "右端点 R")],
    "readouts": [R("对称轴 x=1", "1", "#5ee6ff"),
                 R("f(L)", "-L*L+2*L+3", "#ffd479"),
                 R("f(R)", "-R*R+2*R+3", "#fb7185"),
                 R("区间最大值", "4 if (L<=1<=R) else max(-L*L+2*L+3, -R*R+2*R+3)", "#40e0a8")],
    "ask": "拖动区间端点，观察开口向下时最大值的位置",
    "steps": ["配方为 -(x-1)²+4", "判断轴 x=1 是否在区间内", "在区间内则最大值 4"],
    "goal": "掌握开口向下时，轴在区间内则顶点取最大",
    "tip": "顶点纵坐标就是最大值候选",
    "success": "对！轴 x=1 在 [0,2] 内，最大值 f(1)=4。",
}
SPECS[("function_lab_levels.json", "5-5 综合：指定参数算最值")] = {
    "sliders": [S("a", -2, 4, 2, 0.5, "参数 a"), S("L", 1, 3, 1, 1, "左端点 L"), S("R", 1, 3, 3, 1, "右端点 R")],
    "readouts": [R("对称轴 x=a", "a"),
                 R("顶点值 3-a²", "3-a*a", "#ffd479"),
                 R("区间最小值", "3-a*a if (L<=a<=R) else min(L*L-2*a*L+3, R*R-2*a*R+3)", "#40e0a8")],
    "ask": "拖动 a 和区间，观察对称轴位置如何决定最小值",
    "steps": ["配方 f(x)=(x-a)²+3-a²", "轴 x=a 落在区间内取顶点", "否则比较两端点"],
    "goal": "掌握含参二次函数在给定区间上的最值讨论",
    "tip": "先看轴是否落在区间内",
    "success": "对！a=2 时轴在 [1,3] 内，最小值 f(2)=-1。",
}

# ===================== sequences =====================
SPECS[("sequences_levels.json", "1-3 迁移应用 · 代入通项")] = {
    "sliders": [S("n", 1, 10, 3, 1, "项数 n")],
    "readouts": [R("aₙ=n²-n", "n*n-n"),
                 R("代入过程", "str(n)+\"²-\"+str(n)", "#ffd479"),
                 R("a₃", "6", "#40e0a8")],
    "ask": "拖动 n，观察通项 aₙ=n²-n 的取值",
    "steps": ["把 n 调到 3", "计算 3²-3", "得到 a₃=6"],
    "goal": "掌握代入通项公式求指定项",
    "tip": "直接代入，注意运算顺序",
    "success": "对！a₃=6。",
}
SPECS[("sequences_levels.json", "2-3 迁移应用 · 任意两项关系")] = {
    "sliders": [S("a3", 0, 20, 7, 1, "a₃"), S("a8", 0, 40, 22, 1, "a₈")],
    "readouts": [R("公差 d=(a₈-a₃)/5", "(a8-a3)/5"),
                 R("计算过程", "\"(\"+str(a8)+\"-\"+str(a3)+\")/5\"", "#ffd479"),
                 R("是否整数", "\"是\" if (a8-a3)%5==0 else \"否\"", "#40e0a8")],
    "ask": "拖动 a₃、a₈，观察公差如何由任意两项决定",
    "steps": ["由 aₘ=aₙ+(m-n)d", "解出 d=(aₘ-aₙ)/(m-n)", "验证 (22-7)/5=3"],
    "goal": "掌握用任意两项求公差",
    "tip": "下标差对应公差的倍数",
    "success": "对！d=3。",
}
SPECS[("sequences_levels.json", "2-6 迁移应用 · 用性质求值")] = {
    "sliders": [S("sum28", 0, 30, 12, 1, "a₂+a₈")],
    "readouts": [R("下标和 2+8=2×5", "\"2×5\"", "#5ee6ff"),
                 R("a₅=(a₂+a₈)/2", "sum28/2", "#ffd479"),
                 R("a₂+a₈=2a₅", "\"恒成立\"", "#40e0a8")],
    "ask": "拖动 a₂+a₈ 的值，观察 a₅ 始终是它的一半",
    "steps": ["利用下标和性质 2+8=2×5", "得 a₂+a₈=2a₅", "所以 a₅=6"],
    "goal": "掌握等差数列的下标和性质",
    "tip": "下标成等差，对应项也成等差",
    "success": "对！a₅=6。",
}
SPECS[("sequences_levels.json", "3-2 建构知识 · 两个求和公式")] = {
    "sliders": [S("a1", -10, 20, 2, 1, "首项 a₁"), S("a10", 0, 40, 20, 1, "末项 a₁₀")],
    "readouts": [R("S₁₀=10(a₁+a₁₀)/2", "10*(a1+a10)/2"),
                 R("计算过程", "10*(" + "a1+a10" + ")/2", "#ffd479"),
                 R("结果", "10*(a1+a10)/2", "#40e0a8")],
    "ask": "拖动首末项，观察前 10 项和如何变化",
    "steps": ["用 Sₙ=n(a₁+aₙ)/2", "代入 a₁=2,a₁₀=20", "得 S₁₀=110"],
    "goal": "掌握等差数列求和公式 Sₙ=n(a₁+aₙ)/2",
    "tip": "首末配对，共 n 项",
    "success": "对！S₁₀=110。",
}
SPECS[("sequences_levels.json", "3-4 迁移应用 · 由 Sₙ 求公差")] = {
    "sliders": [S("A", -3, 3, 1, 0.5, "Sn=An²+Bn 的 A"), S("B", -5, 5, 2, 1, "Sn=An²+Bn 的 B")],
    "readouts": [R("公差 d=2A", "2*A"),
                 R("首项 a₁=A+B", "A+B", "#ffd479"),
                 R("验证 S₂-S₁", "(4*A+2*B)-(A+B)", "#40e0a8")],
    "ask": "拖动 A、B，观察 Sn 表达式中二次项系数与公差的关系",
    "steps": ["设 Sn=An²+Bn", "则 d=2A", "A=1 时 d=2"],
    "goal": "掌握由 Sn=An²+Bn 直接读出公差 d=2A",
    "tip": "二次项系数的两倍就是公差",
    "success": "对！d=2。",
}
SPECS[("sequences_levels.json", "3-5 建构知识 · 片段和性质")] = {
    "sliders": [S("S3", 0, 30, 9, 1, "S₃"), S("S6", 10, 60, 36, 1, "S₆")],
    "readouts": [R("S₆-S₃", "S6-S3"),
                 R("片段和成等差", "str(S3)+\",\"+str(S6-S3)+\",\"+str(S9-S6) if (S9:=3*(S6-S3)) else \"\"", "#ffd479"),
                 R("S₉=3(S₆-S₃)", "3*(S6-S3)", "#40e0a8")],
    "ask": "拖动 S₃、S₆，观察片段和 S₃、S₆-S₃、S₉-S₆ 的关系",
    "steps": ["S₃、S₆-S₃、S₉-S₆ 成等差数列", "由等差中项求 S₉-S₆", "得 S₉=81"],
    "goal": "掌握等差数列片段和性质",
    "tip": "片段和仍成等差数列",
    "success": "对！S₉=81。",
}
SPECS[("sequences_levels.json", "3-8 迁移应用 · 前n项和最值")] = {
    "sliders": [S("a1", 0, 30, 20, 1, "首项 a₁"), S("d", -5, 5, -3, 1, "公差 d"), S("n", 1, 15, 7, 1, "项数 n")],
    "readouts": [R("aₙ", "a1+(n-1)*d"),
                 R("Sₙ", "n*(2*a1+(n-1)*d)/2", "#ffd479"),
                 R("比较 Sₙ 与 Sₙ₊₁", "S_n if (S_n:=n*(2*a1+(n-1)*d)/2)>=((n+1)*(2*a1+n*d)/2) else \"还会增大\"", "#40e0a8")],
    "ask": "拖动 n，找出使 Sn 取最大值的项数",
    "steps": ["d<0 时找最后一个正项", "令 aₙ>0、aₙ₊₁≤0", "得 n=7"],
    "goal": "掌握 d<0 时前 n 项和最大值的求法",
    "tip": "找到最后一个非负项",
    "success": "对！n=7 时 Sₙ 最大。",
}
SPECS[("sequences_levels.json", "4-3 迁移应用 · 任意两项关系")] = {
    "sliders": [S("a2", 1, 20, 6, 1, "a₂"), S("a5", 1, 100, 48, 1, "a₅")],
    "readouts": [R("q³=a₅/a₂", "a5/a2"),
                 R("公比 q", "pow(a5/a2, 1/3)", "#ffd479"),
                 R("计算过程", "\"(\"+str(a5)+\"/\"+str(a2)+\")^(1/3)\"", "#40e0a8")],
    "ask": "拖动 a₂、a₅，观察公比如何由两项之比开立方得到",
    "steps": ["由 aₘ=aₙq^(m-n)", "得 q³=a₅/a₂", "验证 48/6=8 ⇒ q=2"],
    "goal": "掌握等比数列任意两项求公比",
    "tip": "下标差就是公比的指数",
    "success": "对！q=2。",
}
SPECS[("sequences_levels.json", "4-6 迁移应用 · 用性质求值")] = {
    "sliders": [S("prod", 1, 100, 16, 1, "a₃·a₇")],
    "readouts": [R("a₅²=a₃a₇", "prod"),
                 R("a₅=√(a₃a₇)", "sqrt(prod)", "#ffd479"),
                 R("各项为正取正根", "\"+\" + str(sqrt(prod))", "#40e0a8")],
    "ask": "拖动乘积，观察 a₅ 始终是它的正平方根",
    "steps": ["利用下标和 3+7=2×5", "得 a₃a₇=a₅²", "各项为正取 a₅=4"],
    "goal": "掌握等比数列下标和性质",
    "tip": "正项等比数列开方取正",
    "success": "对！a₅=4。",
}
SPECS[("sequences_levels.json", "5-3 迁移应用 · 求和公式")] = {
    "sliders": [S("a1", 1, 10, 2, 1, "首项 a₁"), S("q", -3, 3, 3, 0.5, "公比 q"), S("n", 1, 10, 4, 1, "项数 n")],
    "readouts": [R("Sₙ=a₁(1-qⁿ)/(1-q)", "a1*(1-pow(q,n))/(1-q) if abs(q-1)>0.001 else a1*n"),
                 R("逐项相加", "sum([a1*pow(q,i) for i in range(n)])", "#ffd479"),
                 R("末项 aₙ", "a1*pow(q,n-1)", "#40e0a8")],
    "ask": "拖动 a₁、q、n，观察求和公式与逐项相加是否一致",
    "steps": ["用公式 Sₙ=a₁(1-qⁿ)/(1-q)", "代入 a₁=2,q=3,n=4", "得 S₄=80"],
    "goal": "掌握等比数列求和公式",
    "tip": "q=1 时公式要换成 na₁",
    "success": "对！S₄=80。",
}
SPECS[("sequences_levels.json", "5-4 建构知识 · 片段和性质")] = {
    "sliders": [S("S3", 1, 20, 7, 1, "S₃"), S("S6", 10, 100, 63, 1, "S₆")],
    "readouts": [R("S₆-S₃", "S6-S3"),
                 R("片段和成等比", "str(S3)+\",\"+str(S6-S3)+\",\"+str(S9-S6) if (S9:=S6+pow(S6-S3,2)/S3) else \"\"", "#ffd479"),
                 R("S₉=S₆+(S₆-S₃)²/S₃", "S6+pow(S6-S3,2)/S3", "#40e0a8")],
    "ask": "拖动 S₃、S₆，观察片段和之间的等比关系",
    "steps": ["S₃、S₆-S₃、S₉-S₆ 成等比", "公比为 q³", "得 S₉=511"],
    "goal": "掌握等比数列片段和性质",
    "tip": "片段和仍成等比，公比是 q³",
    "success": "对！S₉=511。",
}
SPECS[("sequences_levels.json", "6-1 实验探究 · 逐步递推")] = {
    "sliders": [S("a1", -5, 10, 1, 1, "首项 a₁"), S("c", 1, 5, 3, 1, "每次增加 c"), S("n", 1, 10, 5, 1, "项数 n")],
    "readouts": [R("aₙ=a₁+(n-1)c", "a1+(n-1)*c"),
                 R("a₅", "a1+4*c", "#ffd479"),
                 R("逐项", "str(a1)+\",\"+str(a1+c)+\",\"+str(a1+2*c)+\",...\"", "#40e0a8")],
    "ask": "拖动参数，观察递推 aₙ₊₁=aₙ+c 生成的数列",
    "steps": ["逐项加 c", "得到 1,4,7,10,13", "a₅=13"],
    "goal": "理解递推关系逐项生成数列的过程",
    "tip": "每步加同一个常数就是等差数列",
    "success": "对！a₅=13。",
}
SPECS[("sequences_levels.json", "6-2 建构知识 · 累加求通项")] = {
    "sliders": [S("a1", -5, 10, 1, 1, "首项 a₁"), S("c", 1, 5, 2, 1, "每次增加 c"), S("n", 1, 20, 10, 1, "项数 n")],
    "readouts": [R("通项 aₙ=a₁+(n-1)c", "a1+(n-1)*c"),
                 R("a₁₀", "a1+9*c", "#ffd479"),
                 R("逐项", "str(a1)+\",\"+str(a1+c)+\",\"+str(a1+2*c)+\",...\"", "#40e0a8")],
    "ask": "拖动参数，观察累加法得到的通项公式",
    "steps": ["累加得 aₙ=a₁+(n-1)c", "代入 a₁=1,c=2", "a₁₀=19"],
    "goal": "掌握累加法求通项",
    "tip": "累加的结果是等差数列通项",
    "success": "对！a₁₀=19。",
}
SPECS[("sequences_levels.json", "6-3 迁移应用 · 变式累加")] = {
    "sliders": [S("a1", 0, 5, 1, 1, "首项 a₁"), S("n", 1, 10, 3, 1, "项数 n")],
    "readouts": [R("aₙ=a₁+n(n-1)/2", "a1+n*(n-1)/2"),
                 R("a₂", "a1+1", "#ffd479"),
                 R("a₃", "a1+3", "#40e0a8")],
    "ask": "拖动 n，观察 aₙ₊₁=aₙ+n 累加得到的通项",
    "steps": ["a₂=a₁+1", "a₃=a₂+2", "得 a₃=4"],
    "goal": "掌握变式累加法求通项",
    "tip": "累加的是前 n-1 个正整数和",
    "success": "对！a₃=4。",
}
SPECS[("sequences_levels.json", "7-1 实验探究 · 加上常数成等比")] = {
    "sliders": [S("a1", 0, 5, 1, 1, "首项 a₁"), S("p", 0, 3, 2, 0.5, "系数 p"), S("q", -2, 2, 1, 0.5, "常数 q")],
    "readouts": [R("a₂=p·a₁+q", "p*a1+q"),
                 R("a₃=p·a₂+q", "p*(p*a1+q)+q", "#ffd479"),
                 R("递推式 aₙ₊₁=paₙ+q", "\"aₙ₊₁ = p·aₙ + q\"", "#40e0a8")],
    "ask": "拖动参数，观察 aₙ₊₁=paₙ+q 如何生成数列",
    "steps": ["a₂=2×1+1=3", "a₃=2×3+1=7", "得到 1,3,7,..."],
    "goal": "理解构造等比型递推的生成过程",
    "tip": "先算前一项再代入",
    "success": "对！a₃=7。",
}
SPECS[("sequences_levels.json", "8-1 实验探究 · 积木累加")] = {
    "sliders": [S("n", 1, 12, 1, 1, "项数 n")],
    "readouts": [R("Sₙ=n²", "n*n"),
                 R("aₙ=Sₙ-Sₙ₋₁=2n-1", "2*n-1" if False else "2*n-1", "#ffd479"),
                 R("a₁=S₁", "1", "#40e0a8")],
    "ask": "拖动 n，观察 Sn=n² 时如何反求 aₙ",
    "steps": ["a₁=S₁=1", "aₙ=Sₙ-Sₙ₋₁=2n-1", "验证 a₁=1"],
    "goal": "掌握由前 n 项和 Sn 反求通项 aₙ",
    "tip": "aₙ=Sₙ-Sₙ₋₁（n≥2）",
    "success": "对！a₁=1。",
}
SPECS[("sequences_levels.json", "10-3 迁移应用 · 求极限")] = {
    "sliders": [S("n", 1, 100, 10, 1, "项数 n")],
    "readouts": [R("Sₙ=1-1/(n+1)", "1-1/(n+1)"),
                 R("与 1 的差距", "1/(n+1)", "#ffd479"),
                 R("n→∞ 时", "\"趋近于 1\"", "#40e0a8")],
    "ask": "把 n 拖大，观察 Sn 如何越来越接近 1",
    "steps": ["1/(n+1) 随 n 增大趋于 0", "Sn=1-1/(n+1)", "极限为 1"],
    "goal": "理解数列极限的直观意义",
    "tip": "分母越大，尾项越小",
    "success": "对！极限为 1。",
}

# ===================== inequalities =====================
SPECS[("inequalities_levels.json", "2-2 建构：配凑应用")] = {
    "sliders": [S("x", 0.2, 10, 2, 0.1, "正数 x")],
    "readouts": [R("x+4/x", "x+4/x"),
                 R("理论最小值 2√4", "4", "#ffd479"),
                 R("是否 ≥4", "\"是\" if x+4/x>=4 else \"否\"", "#40e0a8")],
    "ask": "拖动 x，观察 x+4/x 何时取到最小值",
    "steps": ["x·(4/x)=4 为定值", "由 AM-GM 得 ≥2√4=4", "x=2 时取等号"],
    "goal": "掌握配凑定值后用均值不等式求最小值",
    "tip": "两项之积为定值时，和有最小值",
    "success": "对！最小值 4，在 x=2 处取得。",
}
SPECS[("inequalities_levels.json", "2-3 迁移：1 的代换")] = {
    "sliders": [S("a", 0.02, 0.98, 0.5, 0.02, "正数 a（b=1-a）")],
    "readouts": [R("b=1-a", "1-a"),
                 R("1/a+1/b", "1/a+1/(1-a)"),
                 R("是否 ≥4", "\"是\" if 1/a+1/(1-a)>=4 else \"否\"", "#40e0a8")],
    "ask": "拖动 a，观察 1/a+1/b（a+b=1）何时最小",
    "steps": ["1/a+1/b=(a+b)(1/a+1/b)=2+a/b+b/a", "由 AM-GM 得 ≥2+2=4", "a=b=1/2 时取等号"],
    "goal": "掌握『1 的代换』技巧",
    "tip": "乘以 (a+b) 制造定值",
    "success": "对！最小值 4。",
}
SPECS[("inequalities_levels.json", "2-5 综合：配凑定值")] = {
    "sliders": [S("x", 1.05, 6, 2, 0.05, "x>1")],
    "readouts": [R("x+1/(x-1)", "x+1/(x-1)"),
                 R("配凑形式", "(x-1)+1/(x-1)+1", "#ffd479"),
                 R("是否 ≥3", "\"是\" if x+1/(x-1)>=3 else \"否\"", "#40e0a8")],
    "ask": "拖动 x，观察配凑后最小值何时出现",
    "steps": ["配成 (x-1)+1/(x-1)+1", "两项之积为定值 1", "x=2 时取最小值 3"],
    "goal": "掌握『配凑定值』技巧",
    "tip": "把 x 拆成 (x-1)+1",
    "success": "对！最小值 3，在 x=2 处取得。",
}
SPECS[("inequalities_levels.json", "2-6 建构：积定和有最小值")] = {
    "sliders": [S("x", 0.5, 8, 2, 0.1, "正数 x（y=4/x）")],
    "readouts": [R("y=4/x", "4/x"),
                 R("x+y", "x+4/x"),
                 R("是否 ≥4", "\"是\" if x+4/x>=4 else \"否\"", "#40e0a8")],
    "ask": "拖动 x，观察积定 xy=4 时和 x+y 的最小值",
    "steps": ["由 x+y≥2√(xy)", "代入 xy=4 得 ≥4", "x=y=2 时取等号"],
    "goal": "掌握积定时求和的最小值",
    "tip": "积定，和最小 = 2√(积)",
    "success": "对！最小值 4。",
}
SPECS[("inequalities_levels.json", "2-7 迁移：和定积有最大值")] = {
    "sliders": [S("x", 0, 10, 5, 0.5, "正数 x（y=10-x）")],
    "readouts": [R("y=10-x", "10-x"),
                 R("xy", "x*(10-x)"),
                 R("是否 ≤25", "\"是\" if x*(10-x)<=25 else \"否\"", "#40e0a8")],
    "ask": "拖动 x，观察和定 x+y=10 时积 xy 的最大值",
    "steps": ["由 xy≤((x+y)/2)²", "代入 x+y=10 得 ≤25", "x=y=5 时取等号"],
    "goal": "掌握和定时求积的最大值",
    "tip": "和定，积最大 = (和/2)²",
    "success": "对！最大值 25。",
}
SPECS[("inequalities_levels.json", "3-6 柯西不等式 · 向量形式应用")] = {
    "sliders": [S("x", 0, 1, 0.5, 0.05, "x（y=1-x）")],
    "readouts": [R("y=1-x", "1-x"),
                 R("x²+y²", "x*x+(1-x)*(1-x)"),
                 R("柯西下界 1/2", "0.5", "#ffd479"),
                 R("是否 ≥1/2", "\"是\" if x*x+(1-x)*(1-x)>=0.5 else \"否\"", "#40e0a8")],
    "ask": "拖动 x，观察 x²+y²（x+y=1）的最小值",
    "steps": ["构造向量 (x,y),(1,1)", "由柯西 (x²+y²)·2≥(x+y)²=1", "得 ≥1/2，x=y=1/2 取等"],
    "goal": "掌握柯西不等式的向量形式应用",
    "tip": "配成 (x²+y²)(1²+1²)≥(x+y)²",
    "success": "对！最小值 1/2。",
}
SPECS[("inequalities_levels.json", "4-5 综合：恒成立求最小值")] = {
    "sliders": [S("a", -2, 4, 1, 0.5, "参数 a")],
    "readouts": [R("配方 (x-1)²+a-1", "a-1"),
                 R("最小值 a-1", "a-1", "#ffd479"),
                 R("恒成立条件", "\"a≥1\" if a>=1 else \"不满足\"", "#40e0a8")],
    "ask": "拖动 a，找出使不等式恒成立的最小值",
    "steps": ["配方得 (x-1)²+a-1", "最小值 a-1≥0", "a≥1，最小值为 1"],
    "goal": "掌握恒成立问题转化为最值问题",
    "tip": "恒成立 ⇔ 最小值 ≥ 0",
    "success": "对！a 的最小值为 1。",
}
SPECS[("inequalities_levels.json", "5-2 建构：和定积最大")] = {
    "sliders": [S("x", 0, 10, 5, 0.5, "正数 x（y=10-x）")],
    "readouts": [R("y=10-x", "10-x"),
                 R("xy", "x*(10-x)"),
                 R("最大值 25", "25", "#ffd479")],
    "ask": "拖动 x，观察 xy 在 x=y 时达到最大",
    "steps": ["xy≤((x+y)/2)²", "x+y=10 ⇒ xy≤25", "x=y=5 取等号"],
    "goal": "掌握和定积最大的结论",
    "tip": "两数相等时积最大",
    "success": "对！最大值 25。",
}
SPECS[("inequalities_levels.json", "5-3 迁移：积定和最小")] = {
    "sliders": [S("x", 0.5, 16, 4, 0.1, "正数 x（y=16/x）")],
    "readouts": [R("y=16/x", "16/x"),
                 R("x+y", "x+16/x"),
                 R("是否 ≥8", "\"是\" if x+16/x>=8 else \"否\"", "#40e0a8")],
    "ask": "拖动 x，观察积定 xy=16 时和的最小值",
    "steps": ["x+y≥2√(xy)", "xy=16 ⇒ ≥8", "x=y=4 取等号"],
    "goal": "掌握积定和最小的结论",
    "tip": "积定，和最小 = 2√(积)",
    "success": "对！最小值 8。",
}
SPECS[("inequalities_levels.json", "5-5 综合：和的最小值")] = {
    "sliders": [S("x", 0.2, 6, 2, 0.1, "正数 x")],
    "readouts": [R("2x+8/x", "2*x+8/x"),
                 R("两项之积为定值 16", "16", "#ffd479"),
                 R("是否 ≥8", "\"是\" if 2*x+8/x>=8 else \"否\"", "#40e0a8")],
    "ask": "拖动 x，观察 2x+8/x 何时取到最小值",
    "steps": ["2x·(8/x)=16 为定值", "由 AM-GM 得 ≥2√16=8", "x=2 时取等号"],
    "goal": "掌握一般形式的积定求和最小值",
    "tip": "先确认两项之积为定值",
    "success": "对！最小值 8。",
}

# ===================== trig =====================
SPECS[("trig_levels.json", "1-3 迁移：化简求值")] = {
    "sliders": [S("s", 0, 1, 0.6, 0.05, "sinα（α 在第二象限）")],
    "readouts": [R("sin(π+α)=-sinα", "-s"),
                 R("诱导公式", "sin(π+α) = -sinα", "#ffd479"),
                 R("结果", "-s", "#40e0a8")],
    "ask": "拖动 sinα，观察 sin(π+α) 始终是它的相反数",
    "steps": ["用诱导公式 sin(π+α)=-sinα", "代入 sinα=3/5", "得 -3/5"],
    "goal": "掌握诱导公式 sin(π+α)=-sinα",
    "tip": "π+α 在第三象限，正弦为负",
    "success": "对！结果为 -3/5 = -0.6。",
}
SPECS[("trig_levels.json", "2-2 建构：sinθcosθ")] = {
    "sliders": [S("s", -1.5, 1.5, 0.5, 0.05, "sinθ+cosθ")],
    "readouts": [R("平方关系", "(sinθ+cosθ)²=1+2sinθcosθ", "#5ee6ff"),
                 R("sinθcosθ=(s²-1)/2", "(s*s-1)/2", "#ffd479"),
                 R("结果", "(s*s-1)/2", "#40e0a8")],
    "ask": "拖动 sinθ+cosθ，观察它与 sinθcosθ 的关系",
    "steps": ["两边平方：1+2sinθcosθ=s²", "解得 sinθcosθ=(s²-1)/2", "代入 s=1/2 得 -3/8"],
    "goal": "掌握 sinθ+cosθ 与 sinθcosθ 的平方关系",
    "tip": "平方后会出现 1+2sinθcosθ",
    "success": "对！sinθcosθ=-3/8。",
}
SPECS[("trig_levels.json", "2-3 迁移：齐次式")] = {
    "sliders": [S("t", -5, 5, 2, 0.5, "tanθ")],
    "readouts": [R("分子分母同除 cosθ", "(tanθ+1)/(tanθ-1)", "#5ee6ff"),
                 R("结果", "(t+1)/(t-1)", "#ffd479"),
                 R("t=2 时", "3", "#40e0a8")],
    "ask": "拖动 tanθ，观察齐次式的值如何变化",
    "steps": ["分子分母同除以 cosθ", "化为 (tanθ+1)/(tanθ-1)", "代入 tanθ=2 得 3"],
    "goal": "掌握齐次式化切求值的技巧",
    "tip": "同除 cosθ 把正余弦化成 tan",
    "success": "对！结果为 3。",
}
SPECS[("trig_levels.json", "8-2 建构：由点求值")] = {
    "sliders": [S("x", -5, 5, 3, 1, "点 P 的横坐标 x"), S("y", -5, 5, 4, 1, "点 P 的纵坐标 y")],
    "readouts": [R("r=√(x²+y²)", "sqrt(x*x+y*y)"),
                 R("sinα=y/r", "y/sqrt(x*x+y*y)", "#ffd479"),
                 R("cosα=x/r", "x/sqrt(x*x+y*y)", "#fb7185")],
    "ask": "拖动点 P 的坐标，观察三角函数值如何由坐标比值给出",
    "steps": ["先求 r=√(x²+y²)", "sinα=y/r，cosα=x/r", "P(3,4) 时 r=5，sinα=4/5"],
    "goal": "掌握由终边上的点求三角函数值",
    "tip": "r 是点到原点的距离",
    "success": "对！sinα=4/5=0.8。",
}
SPECS[("trig_levels.json", "10-3 迁移：$$\\sin 75^\\circ$$")] = {
    "sliders": [S("A", 0, 90, 45, 1, "角 A（度）"), S("B", 0, 90, 30, 1, "角 B（度）")],
    "readouts": [R("sin(A+B)", "sin(" + PI + "*(A+B)/180)"),
                 R("拆成两角和", "sinAcosB+cosAsinB", "#ffd479"),
                 R("验证公式", "sin(" + PI + "*A/180)*cos(" + PI + "*B/180)+cos(" + PI + "*A/180)*sin(" + PI + "*B/180)", "#40e0a8")],
    "ask": "拖动 A、B，验证两角和的正弦公式",
    "steps": ["把 75° 拆成 45°+30°", "用 sin(A+B)=sinAcosB+cosAsinB", "得 (√6+√2)/4≈0.9659"],
    "goal": "掌握两角和的正弦公式",
    "tip": "特殊角拆分是求非特殊角的关键",
    "success": "对！sin75°≈0.9659。",
}
SPECS[("trig_levels.json", "11-3 迁移：$$\\cos ^{2}15^\\circ - \\sin ^{2}15^\\circ$$")] = {
    "sliders": [S("a", 0, 90, 15, 1, "角 a（度）")],
    "readouts": [R("cos²a - sin²a", "pow(cos(" + PI + "*a/180),2)-pow(sin(" + PI + "*a/180),2)"),
                 R("等于 cos2a", "cos(2*" + PI + "*a/180)", "#ffd479"),
                 R("a=15° 时", "cos(" + PI + "*30/180)", "#40e0a8")],
    "ask": "拖动角 a，验证 cos²a-sin²a=cos2a",
    "steps": ["识别这是 cos2a 的展开", "2a=30°", "结果 √3/2≈0.866"],
    "goal": "掌握二倍角余弦公式",
    "tip": "cos²a-sin²a 就是 cos2a",
    "success": "对！结果 ≈0.866。",
}
SPECS[("trig_levels.json", "11-4 巩固：已知 sinα 求$$\\cos 2\\alpha$$")] = {
    "sliders": [S("s", 0, 1, 0.6, 0.05, "sinα")],
    "readouts": [R("cos2α=1-2sin²α", "1-2*s*s"),
                 R("只用到 sinα", "无需先求 cosα", "#5ee6ff"),
                 R("结果", "1-2*s*s", "#40e0a8")],
    "ask": "拖动 sinα，观察 cos2α 只由 sinα 决定",
    "steps": ["用 cos2α=1-2sin²α", "代入 sinα=3/5", "得 7/25=0.28"],
    "goal": "掌握二倍角余弦的降幂形式",
    "tip": "选择只含 sinα 的公式最省事",
    "success": "对！cos2α=0.28。",
}
SPECS[("trig_levels.json", "11-5 综合：半角求值")] = {
    "sliders": [S("c", 0, 1, 0.6, 0.05, "cosα")],
    "readouts": [R("sin²(α/2)=(1-cosα)/2", "(1-c)/2"),
                 R("sin(α/2)", "sqrt((1-c)/2)", "#ffd479"),
                 R("锐角取正值", "sqrt((1-c)/2)", "#40e0a8")],
    "ask": "拖动 cosα，观察半角正弦如何变化",
    "steps": ["用半角公式 sin²(α/2)=(1-cosα)/2", "代入 cosα=3/5", "得 √5/5≈0.447"],
    "goal": "掌握半角公式",
    "tip": "α/2 是锐角，取正根",
    "success": "对！sin(α/2)≈0.447。",
}
SPECS[("trig_levels.json", "12-2 建构：合并成一个正弦")] = {
    "sliders": [S("A", -5, 5, 3, 0.5, "系数 A"), S("B", -5, 5, 4, 0.5, "系数 B")],
    "readouts": [R("振幅 √(A²+B²)", "sqrt(A*A+B*B)"),
                 R("最大值", "sqrt(A*A+B*B)", "#ffd479"),
                 R("A=3,B=4 时", "5", "#40e0a8")],
    "ask": "拖动 A、B，观察合并后的振幅如何变化",
    "steps": ["化为 √(A²+B²)·sin(x+φ)", "最大值即振幅", "√(3²+4²)=5"],
    "goal": "掌握辅助角公式合并正弦",
    "tip": "振幅就是两个系数的平方和开根",
    "success": "对！最大值 5。",
}
SPECS[("trig_levels.json", "12-3 迁移：最大值")] = {
    "sliders": [S("B", 0, 3, 1.732, 0.1, "cosx 的系数 B（sinx 系数为 1）")],
    "readouts": [R("振幅 √(1+B²)", "sqrt(1+B*B)"),
                 R("合并为 sin(x+φ)", "sqrt(1+B*B)", "#ffd479"),
                 R("B=√3 时", "2", "#40e0a8")],
    "ask": "拖动 B，观察振幅如何随余弦系数增大",
    "steps": ["y=√(1+B²)sin(x+φ)", "振幅 √(1+B²)", "B=√3 时振幅 2"],
    "goal": "掌握 sinx+√3cosx 型函数的振幅",
    "tip": "最大值为 √(1²+B²)",
    "success": "对！最大值 2。",
}
SPECS[("trig_levels.json", "12-5 综合：最小值")] = {
    "sliders": [S("A", -3, 3, 2, 0.5, "sinx 系数 A"), S("B", -3, 3, -2, 0.5, "cosx 系数 B")],
    "readouts": [R("振幅 √(A²+B²)", "sqrt(A*A+B*B)"),
                 R("最小值 -√(A²+B²)", "-sqrt(A*A+B*B)", "#ffd479"),
                 R("A=2,B=-2 时", "-sqrt(8)", "#40e0a8")],
    "ask": "拖动 A、B，观察最小值始终是振幅的相反数",
    "steps": ["合并为 √(A²+B²)sin(x+φ)", "最小值 = -振幅", "得 -2√2≈-2.828"],
    "goal": "掌握 asinx+bcosx 型函数的最值",
    "tip": "最大值和最小值关于 0 对称",
    "success": "对！最小值 ≈ -2.828。",
}
SPECS[("trig_levels.json", "13-4 巩固：后退法测塔高")] = {
    "sliders": [S("a1", 10, 60, 30, 1, "第一次仰角（度）"), S("a2", 5, 50, 15, 1, "第二次仰角（度）"), S("dist", 5, 50, 20, 1, "后退距离 d（m）")],
    "readouts": [R("cot a₁", "1/tan(" + PI + "*a1/180)"),
                 R("cot a₂", "1/tan(" + PI + "*a2/180)", "#ffd479"),
                 R("塔高 h=d/(cot a₂-cot a₁)", "dist/(1/tan(" + PI + "*a2/180)-1/tan(" + PI + "*a1/180))", "#40e0a8")],
    "ask": "拖动两个仰角和后退距离，观察塔高如何被算出",
    "steps": ["设塔高 h，第一次距塔 x=h·cot30°", "第二次 x+d=h·cot15°", "相减得 h=d/(cot15°-cot30°)=10"],
    "goal": "掌握『后退法』测高模型（余切差）",
    "tip": "保持 a₁>a₂，否则公式无意义",
    "success": "对！塔高 10 m。",
}
SPECS[("trig_levels.json", "13-5 综合：不可达距离")] = {
    "sliders": [S("CD", 20, 120, 80, 1, "CD（m）"), S("angD", 30, 80, 60, 1, "∠ADC（度）")],
    "readouts": [R("△ACD 中 ∠C=90°", "cos∠D = CD/AD", "#5ee6ff"),
                 R("AD=CD/cos∠D", "CD/cos(" + PI + "*angD/180)", "#ffd479"),
                 R("CD=80,∠D=60° 时", "160", "#40e0a8")],
    "ask": "拖动 CD 与仰角，观察不可达距离 AD 如何计算",
    "steps": ["△ACD 是直角三角形", "cos∠D=邻边/斜边=CD/AD", "AD=80/cos60°=160"],
    "goal": "掌握不可达距离的三角测量",
    "tip": "找到直角三角形再用余弦",
    "success": "对！AD=160 m。",
}

# `if False else` trick fix for the 8-1 readout (avoid walrus confusion)
SPECS[("sequences_levels.json", "3-5 建构知识 · 片段和性质")]["readouts"][1]["expr"] = \
    "\"片段和成等差：\"+str(S3)+\", \"+str(S6-S3)+\", \"+str(S6-S3+(S6-S3-S3))"
SPECS[("sequences_levels.json", "5-4 建构知识 · 片段和性质")]["readouts"][1]["expr"] = \
    "\"片段和成等比：\"+str(S3)+\", \"+str(S6-S3)+\", \"+str(S6+pow(S6-S3,2)/S3-(S6))"
SPECS[("sequences_levels.json", "3-8 迁移应用 · 前n项和最值")]["readouts"][2]["expr"] = \
    "\"是最大\" if (n*(2*a1+(n-1)*d)/2)>=((n+1)*(2*a1+n*d)/2) else \"还会增大\""
SPECS[("sequences_levels.json", "8-1 实验探究 · 积木累加")]["readouts"][1]["expr"] = "2*n-1"

# ---------------------------------------------------------------- converter
LABMAP = {
    'set_logic_levels.json': 'set_logic',
    'function_lab_levels.json': 'function_lab',
    'sequences_levels.json': 'sequences',
    'inequalities_levels.json': 'inequalities',
    'trig_levels.json': 'trig',
}

def main():
    grand_before_input = 0
    grand_after_input = 0
    grand_converted = 0
    missing = []

    for filename, lab in LABMAP.items():
        path = os.path.join(DATA, filename)
        data = json.load(open(path, 'r', encoding='utf-8'))

        before = {}
        for sec in data.values():
            for q in sec.get('levels', []):
                t = q.get('type', 'choice')
                before[t] = before.get(t, 0) + 1
        total_before = sum(before.values())
        grand_before_input += before.get('input', 0)

        converted = 0
        for sec_key, sec in data.items():
            for i, q in enumerate(sec.get('levels', [])):
                if q.get('type') != 'input':
                    continue
                key = (filename, q.get('name'))
                spec = SPECS.get(key)
                if not spec:
                    missing.append(key)
                    continue
                sec['levels'][i] = make_explore(lab, q, spec)
                converted += 1

        after = {}
        for sec in data.values():
            for q in sec.get('levels', []):
                t = q.get('type', 'choice')
                after[t] = after.get(t, 0) + 1
        total_after = sum(after.values())

        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        grand_after_input += after.get('input', 0)
        grand_converted += converted

        print("=" * 66)
        print(filename)
        print(f"  total: {total_before}")
        print(f"  before: {before}")
        print(f"  after : {after}")
        print(f"  converted: {converted}")
        if after.get('input', 0):
            print(f"  remaining input: {after.get('input', 0)}")

    print("=" * 66)
    print(f"TOTAL converted: {grand_converted}")
    print(f"input before: {grand_before_input} -> after: {grand_after_input}")
    if missing:
        print("MISSING SPECS:")
        for m in missing:
            print("  ", m)
    else:
        print("All input questions have specs. [OK]")

if __name__ == '__main__':
    main()
