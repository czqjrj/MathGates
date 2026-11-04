#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Repair readouts produced by earlier conversions.

Engine facts (LabPlane / LabStage):
  * readouts[].expr must be a pure numeric expression;
  * supported functions are only sqrt/abs/sin/cos/tan (角度制);
  * comparison, string concatenation, conditional expressions, lists,
    pow/atan/atan2/min/max/ceil are NOT supported and silently render 0.

This script installs curated numeric readouts for the questions we converted
from input -> explore, and drops un-repairable legacy readouts so the panel
never shows a fake 0.
"""
import glob
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

DATA = r'E:\MathGates-main\data'
ALLOWED = {'sqrt', 'abs', 'sin', 'cos', 'tan'}
CALL = re.compile(r'([A-Za-z_][A-Za-z_0-9]*)\s*\(')


def R(label, expr, color="#5ee6ff"):
    return {"label": label, "expr": expr, "color": color}


def valid(expr):
    e = str(expr)
    if any(t in e for t in ['<', '>', '==', '!=', '"', "'", '[', ']', ':', ',',
                            ' if ', 'else', 'str(', '{', '}']):
        return False
    for fn in CALL.findall(e):
        if fn not in ALLOWED:
            return False
    # bare identifiers are slider names / pi / e; allow them
    return True


FIX = {}

# ---------------- function_lab ----------------
FIX[('function_lab_levels.json', '1-5 综合应用 · 值域为 R 的判定')] = [
    R("右段值域下界", "1"),
    R("左段值域上界 1+a", "1+a", "#ffd479"),
    R("a（≥0 时值域为 R）", "a", "#40e0a8"),
]
FIX[('function_lab_levels.json', '3-3 迁移：两种复合不相等')] = [
    R("g(x)=x²", "x*x"),
    R("f(g(x))=2^(x²)", "2^(x*x)", "#ffd479"),
    R("g(f(x))=(2ˣ)²", "(2^x)^2", "#fb7185"),
    R("两者之差（0 即相等）", "2^(x*x)-(2^x)^2", "#40e0a8"),
]
FIX[('function_lab_levels.json', '4-3 迁移：一对互逆的函数值')] = [
    R("f(x₀)=y₀", "y0"),
    R("f⁻¹(y₀)=x₀", "x0", "#ffd479"),
]
FIX[('function_lab_levels.json', '5-4 巩固：开口向下找最大')] = [
    R("f(L)", "-L*L+2*L+3"),
    R("f(R)", "-R*R+2*R+3", "#ffd479"),
    R("顶点值 f(1)", "4", "#40e0a8"),
]
FIX[('function_lab_levels.json', '5-5 综合：指定参数算最值')] = [
    R("对称轴 x=a", "a"),
    R("顶点值 3−a²", "3-a^2", "#ffd479"),
    R("f(L)", "L*L-2*a*L+3", "#fb7185"),
    R("f(R)", "R*R-2*a*R+3", "#40e0a8"),
]

# ---------------- functions ----------------
FIX[('functions_levels.json', '4-4 建构知识 · 分段函数的对应关系')] = [
    R("内层 f(x)=x+1（x<0）", "x+1"),
    R("外层 f(f(x))=x+2", "x+2", "#ffd479"),
]
FIX[('functions_levels.json', '6-5 迁移应用 · 含参奇偶性求参数')] = [
    R("f(1)=a+3", "a+3"),
    R("f(−1)=5−a", "5-a", "#ffd479"),
    R("|f(1)−f(−1)|（0 即偶）", "abs((a+3)-(5-a))", "#40e0a8"),
]
FIX[('functions_levels.json', '8-7 迁移：对数式求值')] = [
    R("bⁿ", "base^n"),
    R("log_b(bⁿ)=n", "n", "#ffd479"),
    R("log₂8", "3", "#40e0a8"),
]
FIX[('functions_levels.json', '12-2 建构：二次函数模型')] = [
    R("利润 y=x(20−x)", "x*(20-x)"),
    R("配方值 100−(x−10)²", "100-(x-10)^2", "#ffd479"),
]
FIX[('functions_levels.json', '13-2 建构：取中点')] = [
    R("f(x)=x²+x−1", "x*x+x-1"),
    R("f(0.5)", "0.5*0.5+0.5-1", "#ffd479"),
]
FIX[('functions_levels.json', '14-5 综合：复利模型')] = [
    R("本利和 P(1+r)ⁿ", "P*(1+r)^n"),
    R("利息", "P*(1+r)^n-P", "#ffd479"),
    R("原题 1000·1.05²", "1000*1.05^2", "#40e0a8"),
]

# ---------------- inequalities ----------------
FIX[('inequalities_levels.json', '2-2 建构：配凑应用')] = [
    R("x+4/x", "x+4/x"),
    R("理论最小值 4", "4", "#ffd479"),
    R("与下界的差", "x+4/x-4", "#40e0a8"),
]
FIX[('inequalities_levels.json', '2-3 迁移：1 的代换')] = [
    R("b=1−a", "1-a"),
    R("1/a+1/b", "1/a+1/(1-a)", "#ffd479"),
    R("与下界的差", "1/a+1/(1-a)-4", "#40e0a8"),
]
FIX[('inequalities_levels.json', '2-5 综合：配凑定值')] = [
    R("x+1/(x−1)", "x+1/(x-1)"),
    R("配凑形式", "(x-1)+1/(x-1)+1", "#ffd479"),
    R("与下界的差", "x+1/(x-1)-3", "#40e0a8"),
]
FIX[('inequalities_levels.json', '2-6 建构：积定和有最小值')] = [
    R("y=4/x", "4/x"),
    R("x+y", "x+4/x", "#ffd479"),
    R("与下界的差", "x+4/x-4", "#40e0a8"),
]
FIX[('inequalities_levels.json', '2-7 迁移：和定积有最大值')] = [
    R("y=10−x", "10-x"),
    R("xy", "x*(10-x)", "#ffd479"),
    R("25−xy（≥0 成立）", "25-x*(10-x)", "#40e0a8"),
]
FIX[('inequalities_levels.json', '3-6 柯西不等式 · 向量形式应用')] = [
    R("y=1−x", "1-x"),
    R("x²+y²", "x*x+(1-x)*(1-x)", "#ffd479"),
    R("与 1/2 的差", "x*x+(1-x)*(1-x)-0.5", "#40e0a8"),
]
FIX[('inequalities_levels.json', '4-5 综合：恒成立求最小值')] = [
    R("最小值 a−1", "a-1"),
    R("a（≥1 时恒成立）", "a", "#40e0a8"),
]
FIX[('inequalities_levels.json', '5-3 迁移：积定和最小')] = [
    R("y=16/x", "16/x"),
    R("x+y", "x+16/x", "#ffd479"),
    R("与下界的差", "x+16/x-8", "#40e0a8"),
]
FIX[('inequalities_levels.json', '5-5 综合：和的最小值')] = [
    R("2x+8/x", "2*x+8/x"),
    R("两项之积（定值 16）", "2*x*(8/x)", "#ffd479"),
    R("与下界的差", "2*x+8/x-8", "#40e0a8"),
]

# ---------------- sequences ----------------
FIX[('sequences_levels.json', '1-3 迁移应用 · 代入通项')] = [
    R("aₙ=n²−n", "n*n-n"),
    R("n²", "n*n", "#ffd479"),
    R("a₃", "6", "#40e0a8"),
]
FIX[('sequences_levels.json', '2-3 迁移应用 · 任意两项关系')] = [
    R("公差 d=(a₈−a₃)/5", "(a8-a3)/5"),
    R("a₈−a₃", "a8-a3", "#ffd479"),
]
FIX[('sequences_levels.json', '2-6 迁移应用 · 用性质求值')] = [
    R("a₅=(a₂+a₈)/2", "sum28/2"),
    R("a₂+a₈", "sum28", "#ffd479"),
]
FIX[('sequences_levels.json', '3-2 建构知识 · 两个求和公式')] = [
    R("S₁₀=10(a₁+a₁₀)/2", "10*(a1+a10)/2"),
    R("a₁+a₁₀", "a1+a10", "#ffd479"),
    R("平均项", "(a1+a10)/2", "#40e0a8"),
]
FIX[('sequences_levels.json', '3-5 建构知识 · 片段和性质')] = [
    R("S₆−S₃", "S6-S3"),
    R("S₉−S₆", "S6-S3-S3", "#ffd479"),
    R("S₉=3(S₆−S₃)", "3*(S6-S3)", "#40e0a8"),
]
FIX[('sequences_levels.json', '3-8 迁移应用 · 前n项和最值')] = [
    R("aₙ", "a1+(n-1)*d"),
    R("Sₙ", "n*(2*a1+(n-1)*d)/2", "#ffd479"),
]
FIX[('sequences_levels.json', '4-3 迁移应用 · 任意两项关系')] = [
    R("q³=a₅/a₂", "a5/a2"),
    R("公比 q", "(a5/a2)^(1/3)", "#ffd479"),
]
FIX[('sequences_levels.json', '4-6 迁移应用 · 用性质求值')] = [
    R("a₅²=a₃a₇", "prod"),
    R("a₅=√(a₃a₇)", "sqrt(prod)", "#ffd479"),
]
FIX[('sequences_levels.json', '5-3 迁移应用 · 求和公式')] = [
    R("Sₙ=a₁(1−qⁿ)/(1−q)", "a1*(1-q^n)/(1-q)"),
    R("末项 aₙ", "a1*q^(n-1)", "#ffd479"),
    R("公比 q", "q", "#40e0a8"),
]
FIX[('sequences_levels.json', '5-4 建构知识 · 片段和性质')] = [
    R("S₆−S₃", "S6-S3"),
    R("S₉=S₆+(S₆−S₃)²/S₃", "S6+(S6-S3)^2/S3", "#ffd479"),
]
FIX[('sequences_levels.json', '6-1 实验探究 · 逐步递推')] = [
    R("aₙ=a₁+(n−1)c", "a1+(n-1)*c"),
    R("a₅", "a1+4*c", "#ffd479"),
    R("公差 c", "c", "#40e0a8"),
]
FIX[('sequences_levels.json', '6-2 建构知识 · 累加求通项')] = [
    R("通项 aₙ=a₁+(n−1)c", "a1+(n-1)*c"),
    R("a₁₀", "a1+9*c", "#ffd479"),
]
FIX[('sequences_levels.json', '7-1 实验探究 · 加上常数成等比')] = [
    R("a₂=p·a₁+q", "p*a1+q"),
    R("a₃=p·a₂+q", "p*(p*a1+q)+q", "#ffd479"),
]
FIX[('sequences_levels.json', '10-3 迁移应用 · 求极限')] = [
    R("Sₙ=1−1/(n+1)", "1-1/(n+1)"),
    R("与 1 的差距", "1/(n+1)", "#ffd479"),
]

# ---------------- set_logic ----------------
FIX[('set_logic_levels.json', '2-5 综合：补集区间')] = [
    R("左端点 a（补集取到）", "a"),
    R("右端点 b（补集取到）", "b", "#ffd479"),
    R("区间长度 b−a", "b-a", "#40e0a8"),
]
FIX[('set_logic_levels.json', '3-5 综合：由充分条件反求参数')] = [
    R("参数 a", "a"),
    R("a−2（>0 时充分不必要）", "a-2", "#ffd479"),
    R("最小整数值", "3", "#40e0a8"),
]
FIX[('set_logic_levels.json', '4-5 综合：由存在命题为真求参数')] = [
    R("最小值 m−1", "m-1"),
    R("m（<1 时命题为真）", "m", "#40e0a8"),
]
FIX[('set_logic_levels.json', '6-2 建构：card 容斥公式')] = [
    R("|A∪B|", "size_A+size_B-size_inter"),
    R("|A|+|B|", "size_A+size_B", "#ffd479"),
    R("|A∩B|", "size_inter", "#40e0a8"),
]
FIX[('set_logic_levels.json', '6-3 迁移：反推一个集合的基数')] = [
    R("|A|", "union-size_B+size_inter"),
    R("|A∪B|−|B|", "union-size_B", "#ffd479"),
    R("|A∩B|", "size_inter", "#40e0a8"),
]
FIX[('set_logic_levels.json', '6-4 巩固：都不喜欢的怎么算')] = [
    R("至少参加一组", "size_A+size_B-size_inter"),
    R("都不参加", "total-(size_A+size_B-size_inter)", "#fb7185"),
]
FIX[('set_logic_levels.json', '6-5 综合：子集个数与元素个数')] = [
    R("子集个数 2ⁿ", "2^n"),
    R("真子集个数 2ⁿ−1", "2^n-1", "#ffd479"),
]
FIX[('set_logic_levels.json', '7-4 巩固：夹在两集合之间')] = [
    R("A 的元素个数", "1+take2+take3"),
    R("满足条件的 A 的个数", "4", "#40e0a8"),
]
FIX[('set_logic_levels.json', '7-5 综合：互异性筛根')] = [
    R("a²−a", "a*a-a"),
    R("a−2（=0 时 a=2）", "a-2", "#ffd479"),
    R("a²−a−2（=0 时含 2）", "a*a-a-2", "#40e0a8"),
]
FIX[('set_logic_levels.json', '8-4 巩固：补集与 card 联用')] = [
    R("|A∪B|", "size_A+size_B-size_inter"),
    R("补集元素数", "u_size-(size_A+size_B-size_inter)", "#fb7185"),
]

# ---------------- trig ----------------
FIX[('trig_levels.json', '1-3 迁移：化简求值')] = [
    R("sin(π+α)=−sinα", "-s"),
    R("sinα", "s", "#ffd479"),
]
FIX[('trig_levels.json', '2-2 建构：sinθcosθ')] = [
    R("sinθcosθ=(s²−1)/2", "(s*s-1)/2"),
    R("s²−1", "s*s-1", "#ffd479"),
]
FIX[('trig_levels.json', '2-3 迁移：齐次式')] = [
    R("(tanθ+1)/(tanθ−1)", "(t+1)/(t-1)"),
    R("tanθ", "t", "#ffd479"),
]
FIX[('trig_levels.json', '11-3 迁移：$$\\cos ^{2}15^\\circ - \\sin ^{2}15^\\circ$$')] = [
    R("cos²a−sin²a", "cos(a)^2-sin(a)^2"),
    R("cos2a", "cos(2*a)", "#ffd479"),
]

# ---------------- vector ----------------
FIX[('vector_levels.json', '1-1 平面向量的概念')] = [
    R("模长 |v|", "sqrt(vx*vx+vy*vy)"),
    R("斜率 vy/vx（方向）", "vy/vx", "#ffd479"),
]
FIX[('vector_levels.json', '5-2 减法与相反向量')] = [
    R("a−b 的 x 分量", "ax-bx"),
    R("a−b 的 y 分量", "ay-by", "#ffd479"),
    R("b−a 的 x 分量", "bx-ax", "#fb7185"),
    R("b−a 的 y 分量", "by-ay", "#40e0a8"),
]
FIX[('vector_levels.json', '8-2 坐标形式的线性运算')] = [
    R("2a−b 的 x 分量", "2*ax-bx"),
    R("2a−b 的 y 分量", "2*ay-by", "#ffd479"),
    R("2a 的 x 分量", "2*ax", "#fb7185"),
    R("2a 的 y 分量", "2*ay", "#40e0a8"),
]
FIX[('vector_levels.json', '13-1 数量投影')] = [
    R("数量投影 |b|cosθ", "lb*cos(theta)"),
    R("θ−90（>0 为钝角）", "theta-90", "#ffd479"),
    R("|b|", "lb", "#40e0a8"),
]

# ---------------- vectors ----------------
FIX[('vectors_levels.json', '1-5 综合：加法与减法的几何')] = [
    R("AC 的 x 分量", "abx+adx"),
    R("AC 的 y 分量", "aby+ady", "#ffd479"),
    R("BD 的 x 分量", "adx-abx", "#fb7185"),
    R("BD 的 y 分量", "ady-aby", "#40e0a8"),
]
FIX[('vectors_levels.json', '2-4 巩固：由模长反求参数')] = [
    R("3²+m²", "9+m*m"),
    R("|a|", "sqrt(9+m*m)", "#ffd479"),
    R("m²−16（=0 时 |a|=5）", "m*m-16", "#40e0a8"),
]
FIX[('vectors_levels.json', '2-5 综合：中点坐标')] = [
    R("M 的横坐标", "(ax+bx)/2"),
    R("M 的纵坐标", "(ay+by)/2", "#ffd479"),
]
FIX[('vectors_levels.json', '3-3 迁移：垂直条件')] = [
    R("a·b=x−2", "1*x+2*(-1)"),
    R("x（=2 时垂直）", "x", "#ffd479"),
]
FIX[('vectors_levels.json', '4-2 建构：平行轨迹求参数')] = [
    R("b 的纵坐标 m", "m"),
    R("叉积 x₁y₂−x₂y₁", "1*m-2*2", "#ffd479"),
    R("m−4（=0 时平行）", "m-4", "#40e0a8"),
]
FIX[('vectors_levels.json', '4-3 迁移：垂直求参')] = [
    R("a·b=2+2m", "1*2+2*m"),
    R("m+1（=0 时垂直）", "m+1", "#40e0a8"),
]
FIX[('vectors_levels.json', '4-5 综合：三点共线')] = [
    R("AC 的纵坐标 m−1", "m-1"),
    R("叉积 1·(m−1)−2·2", "1*(m-1)-2*2", "#ffd479"),
]
FIX[('vectors_levels.json', '7-4 巩固：收绳拉船的速度分解')] = [
    R("收绳速度", "vrope"),
    R("船速 v=v绳/cosθ", "vrope/cos(theta)", "#ffd479"),
    R("θ（度）", "theta", "#40e0a8"),
]

# Lab3D files use NumExpr (supports pow/min/max/atan), so leave them alone.
THREE_D = {'space_levels.json', 'solid_basic_levels.json'}


def main():
    fixed = 0
    dropped = 0
    kept = 0
    for path in sorted(glob.glob(os.path.join(DATA, '*_levels.json'))):
        fname = os.path.basename(path)
        if fname in THREE_D:
            continue
        data = json.load(open(path, 'r', encoding='utf-8'))
        changed = False
        for sec in data.values():
            if not isinstance(sec, dict):
                continue
            for q in sec.get('levels', []):
                if not isinstance(q, dict):
                    continue
                sc = q.get('scene')
                if not isinstance(sc, dict):
                    continue
                key = (fname, q.get('name'))
                if key in FIX:
                    sc['readouts'] = FIX[key]
                    changed = True
                    fixed += 1
                    continue
                rds = sc.get('readouts')
                if not isinstance(rds, list):
                    continue
                new = []
                for rd in rds:
                    if isinstance(rd, dict) and valid(rd.get('expr', '')):
                        new.append(rd)
                        kept += 1
                    else:
                        dropped += 1
                if len(new) != len(rds):
                    sc['readouts'] = new
                    changed = True
        if changed:
            json.dump(data, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)

    print(f"questions with curated readouts : {fixed}")
    print(f"legacy readouts kept            : {kept}")
    print(f"un-repairable readouts dropped  : {dropped}")


if __name__ == '__main__':
    main()
