#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""替换 inequalities_levels.json 中的 ineq_basic（1-2 基本不等式）章节。

设计要点：
  * 全部 13 题均为 explore：先拖滑块观察，再回答建构追问（两段式）。
  * 每题 >= 2 个滑块 + 3~4 个实时读数，全部读数表达式符合 LabPlane 白名单
    （数字/滑块名/ + - * / ^ / sqrt abs sin cos tan），不含比较、三元、**。
  * 去掉柯西不等式，补齐：等号条件、三元均值、换元、乘 1 法、系数配凑、建模。
  * 用 json.load -> 改字典 -> json.dump 整体写回，绝不手工拼接字符串。
"""
import json
import sys

PATH = r'E:\MathGates-main\data\inequalities_levels.json'


def q(name, qtext, scene, ask, steps, goal, tip, hint, explain,
      success, opts, ans, retry):
    return {
        "name": name,
        "type": "explore",
        "q": qtext,
        "scene": scene,
        "ask": ask,
        "steps": steps,
        "goal": goal,
        "tip": tip,
        "confirm": "看解析",
        "gate": False,
        "answers": {},
        "retry": retry,
        "hint": hint,
        "explain": explain,
        "success": success,
        "opts": opts,
        "ans": ans,
    }


def slider(name, lo, hi, value, step, label):
    return {"name": name, "min": lo, "max": hi, "value": value,
            "step": step, "label": label}


def readout(label, expr, color=None):
    d = {"label": label, "expr": expr}
    if color:
        d["color"] = color
    return d


levels = [
    # ---------------------------------------------------------------- L1 建构
    q(
        name="2-1 建构：a²+b²≥2ab 的本质",
        qtext="拖动滑块改变实数 a、b（允许取负），观察 a²+b²、2ab 与 (a−b)² 的变化：哪一个读数永远不小于 0？",
        scene={
            "range": 8,
            "sliders": [
                slider("a", -4, 4, 3, 0.5, "实数 a"),
                slider("b", -4, 4, -2, 0.5, "实数 b"),
            ],
            "readouts": [
                readout("a²+b²", "a*a+b*b"),
                readout("2ab", "2*a*b"),
                readout("(a−b)²", "(a-b)*(a-b)", "#40e0a8"),
                readout("(a²+b²) − 2ab", "a*a+b*b-2*a*b", "#ffd479"),
            ],
        },
        ask="a²+b² 与 2ab 的大小关系会随 a、b 改变吗？差 (a−b)² 什么时候等于 0？",
        steps=[
            "把 a²+b²−2ab 配方：a²−2ab+b²=(a−b)²",
            "平方数恒非负，所以 (a−b)²≥0",
            "移项得 a²+b²≥2ab，当且仅当 a=b 时取等号",
        ],
        goal="用平方非负性发现并证明 a²+b²≥2ab",
        tip="先让 b 取负数，再让 b 等于 a，对比两次的读数差。",
        hint="把 a²+b²−2ab 看成一个完全平方式，它等于哪一个平方？",
        explain="拖动滑块可以发现：(a−b)² 恒大于等于 0，因此 a²+b²−2ab≥0，即 a²+b²≥2ab。"
                "它对任意实数 a、b 都成立，等号当且仅当 a=b 时成立——这正是基本不等式最原始的形式。",
        success="很好！你从读数里发现了 (a−b)²≥0 这条源头。",
        opts=[
            "对任意实数 a、b 都有 a²+b²≥2ab，且 a=b 时取等号",
            "只有当 a、b 都是正数时才有 a²+b²≥2ab",
            "a、b 异号时 a²+b² 可能小于 2ab",
            "a²+b² 与 2ab 的大小无法比较",
        ],
        ans=0,
        retry="继续拖动 a、b（试试异号和同号），看哪个读数始终不为负。",
    ),
    q(
        name="2-2 建构：算术平均 ≥ 几何平均",
        qtext="拖动正数 a、b，比较算术平均 (a+b)/2 与几何平均 √(ab)，并观察最后一行的平方差。",
        scene={
            "range": 10,
            "sliders": [
                slider("a", 0.2, 10, 4, 0.5, "正数 a"),
                slider("b", 0.2, 10, 7, 0.5, "正数 b"),
            ],
            "readouts": [
                readout("算术平均 (a+b)/2", "(a+b)/2"),
                readout("几何平均 √(ab)", "sqrt(a*b)", "#40e0a8"),
                readout("((a+b)/2) − √(ab)", "(a+b)/2-sqrt(a*b)", "#ffd479"),
                readout("(√a − √b)²", "(sqrt(a)-sqrt(b))*(sqrt(a)-sqrt(b))", "#fb7185"),
            ],
        },
        ask="两个平均值谁大？它们的差什么时候恰好为 0？",
        steps=[
            "把差乘以 2：(a+b)−2√(ab)=(√a−√b)²",
            "平方非负，所以 (a+b)/2≥√(ab)",
            "当且仅当 √a=√b 即 a=b 时取等号",
        ],
        goal="从平方差发现 AM-GM 不等式及其取等条件",
        tip="让 a、b 从相差很大逐渐调到相等，盯住第三行读数怎么变。",
        hint="把 √a、√b 看成两个数，它们的完全平方差是多少？",
        explain="拖动滑块会看到 ((a+b)/2)−√(ab) 始终不小于 0，且只在 a=b 时为 0。"
                "因为 2√(ab)≤a+b 等价于 (√a−√b)²≥0。这就是算术—几何平均不等式，使用前提是 a、b 均为正数。",
        success="很好！AM-GM 的差可以写成 (√a−√b)²/2。",
        opts=[
            "几何平均总是不小于算术平均",
            "只有 a、b 都是整数时不等式才成立",
            "两个正数的算术平均不小于几何平均，a=b 时取等号",
            "两个平均值永远相等",
        ],
        ans=2,
        retry="把 a、b 调得一大一小再调成相等，观察差值的变化方向。",
    ),
    q(
        name="2-3 实验：等号成立的条件（三相等）",
        qtext="拖动 t 和 k，观察 f(t)=t+k/t 与下界 2√k 的差：差值什么时候变成 0？此时 t 与 √k 有什么关系？",
        scene={
            "x": [0, 10],
            "y": [-1, 14],
            "sliders": [
                slider("t", 0.2, 8, 2, 0.1, "正数 t"),
                slider("k", 0.5, 9, 4, 0.5, "正数 k"),
            ],
            "curves": [
                {"fn": "linear", "a": 1, "b": 0, "color": "#5ee6ff", "label": "y=t"},
                {"fn": "recip", "a": "k", "b": 0, "color": "#ffd479", "label": "y=k/t"},
                {"fn": "const", "a": "2*sqrt(k)", "color": "#fb7185", "label": "下界 2√k"},
            ],
            "points": [
                {"p": ["sqrt(k)", "2*sqrt(k)"], "color": "#f2637b", "label": "取等点"},
            ],
            "readouts": [
                readout("f(t)=t+k/t", "t+k/t", "#40e0a8"),
                readout("下界 2√k", "2*sqrt(k)", "#ffd479"),
                readout("f(t) − 2√k", "t+k/t-2*sqrt(k)", "#fb7185"),
                readout("|t − √k|", "abs(t-sqrt(k))"),
            ],
        },
        ask="等号在 t 等于多少时成立？改变 k 后，取等点怎样移动？",
        steps=[
            "由 AM-GM：t+k/t≥2√(t·k/t)=2√k",
            "等号要求 t=k/t，即 t²=k",
            "因为 t>0，所以 t=√k",
        ],
        goal="掌握『三相等』：先算出下界，再解取等条件",
        tip="把 t 拖近 √k，看差值与 |t−√k| 是否同时归零。",
        hint="等号成立时 t 与 k/t 必须相等，解这个方程试试。",
        explain="实验中可以看到 f(t)−2√k 只在 t=√k 时为 0，此时曲线 y=t 与 y=k/t 正好相交。"
                "用基本不等式算出下界后，必须回到取等条件 t=k/t 检验它能否取到，这就是口诀中的『三相等』。",
        success="对！取等条件是 t=√k，下界 2√k 才真正能取到。",
        opts=[
            "等号在 t=k 时成立",
            "下界永远取不到，只能无限接近",
            "k 改变时取等点保持不动",
            "当 t=√k 时等号成立，下界 2√k 才能取到",
        ],
        ans=3,
        retry="把 t 拖到 √k 附近，同时盯住最后一行 |t−√k|。",
    ),
    # ---------------------------------------------------------------- L2 基础
    q(
        name="2-4 巩固：和定积最大",
        qtext="固定两数之和 S（拖动 S 可改），拖动 x 让两数变化，观察乘积 xy 与上界 S²/4 的关系。",
        scene={
            "x": [0, 12],
            "y": [-2, 40],
            "sliders": [
                slider("x", 0.2, 6.0, 3, 0.1, "正数 x"),
                slider("S", 7, 12, 10, 0.5, "两数之和 S"),
            ],
            "curves": [
                {"fn": "quad", "a": -1, "b": "S", "c": 0, "color": "#ffd479", "label": "y=x(S−x)"},
            ],
            "readouts": [
                readout("y=S−x", "S-x"),
                readout("xy", "x*(S-x)", "#40e0a8"),
                readout("上界 S²/4", "S*S/4", "#ffd479"),
                readout("S²/4 − xy", "S*S/4-x*(S-x)", "#fb7185"),
            ],
        },
        ask="xy 在什么时候最大？最大值与 S 有什么关系？",
        steps=[
            "由 xy≤((x+y)/2)²",
            "代入 x+y=S 得 xy≤S²/4",
            "等号当 x=y=S/2 时成立",
        ],
        goal="掌握『和定积最大』及其取等条件",
        tip="把 x 调到 S 的一半，看最后一行差值是否归零。",
        hint="当两数相等时，它们的乘积会落在抛物线的什么位置？",
        explain="拖动 x 可以看到抛物线 y=x(S−x) 的最高点在 x=S/2，此时 xy=S²/4。"
                "由基本不等式 xy≤((x+y)/2)² 也能直接得到这个上界，等号要求 x=y。",
        success="对！和定时两数相等，乘积最大为 S²/4。",
        opts=[
            "两数差距越大，乘积越大",
            "当 x=y=S/2 时 xy 最大，最大值为 S²/4",
            "xy 没有最大值",
            "xy 的最大值恒等于 S/4",
        ],
        ans=1,
        retry="把 x 从 0 拖到 S，观察抛物线最高点出现在哪里。",
    ),
    q(
        name="2-5 巩固：积定和最小",
        qtext="固定两数之积 P，拖动 x 观察和 x+y 与下界 2√P 的差。",
        scene={
            "x": [0, 10],
            "y": [0, 14],
            "sliders": [
                slider("x", 0.5, 8, 2, 0.1, "正数 x"),
                slider("P", 1, 16, 4, 0.5, "两数之积 P"),
            ],
            "curves": [
                {"fn": "linear", "a": 1, "b": 0, "color": "#5ee6ff", "label": "y=x"},
                {"fn": "recip", "a": "P", "b": 0, "color": "#ffd479", "label": "y=P/x"},
            ],
            "points": [
                {"p": ["sqrt(P)", "sqrt(P)"], "color": "#f2637b", "label": "交点"},
            ],
            "readouts": [
                readout("y=P/x", "P/x"),
                readout("x+y", "x+P/x", "#40e0a8"),
                readout("下界 2√P", "2*sqrt(P)", "#ffd479"),
                readout("x+y − 2√P", "x+P/x-2*sqrt(P)", "#fb7185"),
            ],
        },
        ask="和的最小值是多少？在什么条件下取到？",
        steps=[
            "由 x+y≥2√(xy)",
            "代入 xy=P 得 x+y≥2√P",
            "等号当 x=y=√P 时成立",
        ],
        goal="掌握『积定和最小』及其取等条件",
        tip="把 x 拖到两条曲线的交点附近，看最后一行读数。",
        hint="两数相等时，和会落在什么位置？",
        explain="拖动 x 观察两条曲线 y=x 与 y=P/x 的交点：当 x=√P 时两线相交，和最小为 2√P。"
                "这也正是 x+y≥2√(xy) 取等号的时刻。",
        success="对！积定时两数相等，和最小为 2√P。",
        opts=[
            "x 越大，x+y 越小",
            "x+y 可以小于 2√P",
            "当 x=y=√P 时 x+y 最小，最小值为 2√P",
            "最小值恒为 P",
        ],
        ans=2,
        retry="让 x 从小拖到大，观察交点两侧 x+y 是升还是降。",
    ),
    # ---------------------------------------------------------------- L3 技巧
    q(
        name="2-6 迁移：配凑法",
        qtext="求 f(x)=x+k/(x−1)（x>1）的最小值：拖动 x、k，观察 f 与下界的差。",
        scene={
            "range": 10,
            "sliders": [
                slider("x", 1.1, 8, 3, 0.05, "x（x>1）"),
                slider("k", 0.5, 8, 4, 0.5, "正数 k"),
            ],
            "readouts": [
                readout("x−1", "x-1"),
                readout("f(x)=x+k/(x−1)", "x+k/(x-1)", "#40e0a8"),
                readout("下界 1+2√k", "1+2*sqrt(k)", "#ffd479"),
                readout("f − 下界", "x+k/(x-1)-(1+2*sqrt(k))", "#fb7185"),
            ],
        },
        ask="为什么要先把 x 拆成 (x−1)+1？最小值与 k 有什么关系？",
        steps=[
            "x+k/(x−1)=(x−1)+k/(x−1)+1",
            "由 AM-GM：(x−1)+k/(x−1)≥2√k",
            "所以 f≥2√k+1，等号当 x−1=√k 即 x=1+√k",
        ],
        goal="学会『配凑』：把 x 拆出与分母相同的 (x−1)",
        tip="把 x 拖到 1+√k，看最后一行差值归零。",
        hint="分子上的 x 与分母的 x−1 差 1，怎样拆才能让两项乘积为定值？",
        explain="直接把 x 与 k/(x−1) 相乘得不到定值，所以把 x 写成 (x−1)+1。"
                "于是 f=(x−1)+k/(x−1)+1≥2√k+1，等号在 x−1=√k 时成立。拖动 x 到 1+√k 可验证差值归零。",
        success="对！配凑后最小值为 2√k+1。",
        opts=[
            "直接对 x 与 k/(x−1) 用不等式，最小值为 2√k",
            "先拆成 (x−1)+k/(x−1)+1，最小值为 2√k+1",
            "f(x) 没有最小值",
            "最小值在 x=1 处取得",
        ],
        ans=1,
        retry="注意 x>1，先把 x 改写成 (x−1)+1 再试。",
    ),
    q(
        name="2-7 迁移：乘 1 法（1 的代换）",
        qtext="已知 a>0、b>0 且 a+b=s，求 1/a+1/b 的最小值。拖动 a、s 观察它与下界 4/s 的差。",
        scene={
            "range": 10,
            "sliders": [
                slider("a", 0.2, 4.8, 1, 0.05, "正数 a"),
                slider("s", 5, 9, 6, 0.5, "a+b=s"),
            ],
            "readouts": [
                readout("b=s−a", "s-a"),
                readout("1/a+1/b", "1/a+1/(s-a)", "#40e0a8"),
                readout("下界 4/s", "4/s", "#ffd479"),
                readout("差", "1/a+1/(s-a)-4/s", "#fb7185"),
            ],
        },
        ask="怎样利用 a+b=s 这个『定值』构造不等式？",
        steps=[
            "1/a+1/b=(a+b)(1/a+1/b)/s",
            "展开得 (2+a/b+b/a)/s",
            "由 a/b+b/a≥2 得 ≥4/s，等号当 a=b=s/2",
        ],
        goal="掌握『乘 1 法』：把已知定值乘进去，制造 a/b 与 b/a",
        tip="把 a 调到 s/2，看最后一行差值是否归零。",
        hint="把 1/a+1/b 乘以 (a+b) 再除以 s，展开后会出现哪两个互为倒数的项？",
        explain="把定值乘进去再展开：因为 a+b=s，所以 1/a+1/b=((a+b)/s)(1/a+1/b)=(2+a/b+b/a)/s。"
                "而 a/b+b/a≥2，故原式≥4/s；拖动 a 到 s/2，可以看到差值归零。",
        success="对！乘 1 后代换，最小值为 4/s。",
        opts=[
            "直接令 a=b 即可，最小值是 2/s",
            "1/a+1/b 没有最小值",
            "把 a+b=s 乘进去，化为 (2+a/b+b/a)/s，最小值为 4/s",
            "最小值是 4s",
        ],
        ans=2,
        retry="先把 1 写成 (a+b)/s，再与 1/a+1/b 相乘展开。",
    ),
    q(
        name="2-8 迁移：系数配凑（2x+y=s）",
        qtext="已知 x>0、y>0 且 2x+y=s，求 1/x+1/y 的最小值。拖动 x、s，观察它与下界 (3+2√2)/s 的差。",
        scene={
            "range": 10,
            "sliders": [
                slider("x", 0.2, 2.4, 1, 0.05, "正数 x"),
                slider("s", 5, 8, 6, 0.5, "2x+y=s"),
            ],
            "readouts": [
                readout("y=s−2x", "s-2*x"),
                readout("1/x+1/y", "1/x+1/(s-2*x)", "#40e0a8"),
                readout("下界 (3+2√2)/s", "(3+2*sqrt(2))/s", "#ffd479"),
                readout("差", "1/x+1/(s-2*x)-(3+2*sqrt(2))/s", "#fb7185"),
            ],
        },
        ask="约束里的系数 2 会怎样改变展开后的常数项？",
        steps=[
            "1/x+1/y=((2x+y)/s)(1/x+1/y)",
            "展开得 (3+y/x+2x/y)/s",
            "由 y/x+2x/y≥2√2 得 ≥(3+2√2)/s",
        ],
        goal="把『乘 1 法』推广到带系数的约束",
        tip="把 x 拖到使 y/x 接近 √2 的位置，看差值变化。",
        hint="先写出 (2x+y)(1/x+1/y)，展开后常数项是多少？再用一次 AM-GM。",
        explain="先展开再观察常数项：把约束 2x+y=s 乘进去，"
                "1/x+1/y=((2x+y)/s)(1/x+1/y)=(3+y/x+2x/y)/s。"
                "由 AM-GM，y/x+2x/y≥2√2，所以最小值为 (3+2√2)/s；拖动 x 到使 y/x=√2 的位置，差值归零。",
        success="很好！系数配凑后最小值是 (3+2√2)/s。",
        opts=[
            "系数 2 不影响结果，最小值仍是 4/s",
            "展开后常数项为 3，最小值为 (3+2√2)/s",
            "最小值为 (1+√2)/s",
            "无法用基本不等式求解",
        ],
        ans=1,
        retry="注意 2x+y=s，除以 s 后整体等于 1，可以乘进目标式。",
    ),
    # ---------------------------------------------------------------- L4 综合
    q(
        name="2-9 迁移：换元法",
        qtext="求 f(x)=x²+k/x²（x≠0）的最小值。拖动 x、k，观察 f 与 2√k 的差。",
        scene={
            "range": 10,
            "sliders": [
                slider("x", 0.4, 4, 1.5, 0.05, "正数 x"),
                slider("k", 0.5, 9, 4, 0.5, "正数 k"),
            ],
            "readouts": [
                readout("t=x²", "x*x"),
                readout("f=t+k/t", "x*x+k/(x*x)", "#40e0a8"),
                readout("下界 2√k", "2*sqrt(k)", "#ffd479"),
                readout("差", "x*x+k/(x*x)-2*sqrt(k)", "#fb7185"),
            ],
        },
        ask="为什么要令 t=x²？换元后 t 的范围是什么？",
        steps=[
            "令 t=x²>0，则 f=t+k/t",
            "由 AM-GM：t+k/t≥2√k",
            "等号当 t=√k 时成立，x 有正负两个对称解",
        ],
        goal="掌握换元法：把高次结构化为 t+k/t",
        tip="不管 x 取正还是负，t=x² 都为正——这正是换元的关键。",
        hint="x² 与 k/x² 相乘是定值吗？把 x² 整体看成一个新变量。",
        explain="换元后观察：令 t=x²，因为 x≠0 所以 t>0，原式化为 t+k/t≥2√k。"
                "拖动 x 改变 t，可以看到等号在 t=√k 时成立，此时 x 可取正负两个对称的解。",
        success="对！换元后最小值为 2√k。",
        opts=[
            "x² 可正可负，不能用基本不等式",
            "最小值为 k",
            "令 t=x²>0，化为 t+k/t，最小值为 2√k",
            "换元后最小值变为 2k",
        ],
        ans=2,
        retry="先把 x² 看成整体 t，再判断 t 的取值范围。",
    ),
    q(
        name="2-10 迁移：三元均值不等式",
        qtext="拖动三个正数 a、b、c，比较算术平均 (a+b+c)/3 与几何平均 ∛(abc)，它们的差何时为 0？",
        scene={
            "range": 10,
            "sliders": [
                slider("a", 0.5, 10, 2, 0.5, "正数 a"),
                slider("b", 0.5, 10, 4, 0.5, "正数 b"),
                slider("c", 0.5, 10, 8, 0.5, "正数 c"),
            ],
            "readouts": [
                readout("算术平均 (a+b+c)/3", "(a+b+c)/3"),
                readout("几何平均 ∛(abc)", "(a*b*c)^(1/3)", "#40e0a8"),
                readout("差", "(a+b+c)/3-(a*b*c)^(1/3)", "#ffd479"),
                readout("ab+bc+ca", "a*b+b*c+c*a"),
            ],
        },
        ask="三元均值不等式的取等条件是什么？",
        steps=[
            "(a+b+c)/3≥∛(abc) 对任意正数成立",
            "当且仅当 a=b=c 时取等号",
            "二元 AM-GM 是它在 n=2 时的特例",
        ],
        goal="把 AM-GM 从二元推广到三元",
        tip="把三个滑块调成同一个值，看中间一行差值。",
        hint="三个数要满足什么关系，算术平均才会正好等于几何平均？",
        explain="三元均值不等式 (a+b+c)/3≥∛(abc) 对任意正数 a、b、c 成立，等号当且仅当 a=b=c。"
                "拖动滑块可以看到差值始终不小于 0，且只在三数相等时归零。",
        success="对！三元情形的取等条件仍是各数相等。",
        opts=[
            "只对两两不相等的正数成立",
            "对任意正数 a、b、c 成立，a=b=c 时取等号",
            "等号在 a+b+c=0 时成立",
            "几何平均可能大于算术平均",
        ],
        ans=1,
        retry="先把 a、b 调到相等，再调 c，观察差值怎样缩小。",
    ),
    q(
        name="2-11 综合：多次使用不等式",
        qtext="拖动 a、b、c，观察 (a+b+c)(1/a+1/b+1/c) 与 9 的差。这个乘积为什么不可能小于 9？",
        scene={
            "range": 10,
            "sliders": [
                slider("a", 0.5, 8, 2, 0.5, "正数 a"),
                slider("b", 0.5, 8, 3, 0.5, "正数 b"),
                slider("c", 0.5, 8, 5, 0.5, "正数 c"),
            ],
            "readouts": [
                readout("a+b+c", "a+b+c"),
                readout("1/a+1/b+1/c", "1/a+1/b+1/c"),
                readout("乘积", "(a+b+c)*(1/a+1/b+1/c)", "#40e0a8"),
                readout("乘积 − 9", "(a+b+c)*(1/a+1/b+1/c)-9", "#ffd479"),
            ],
        },
        ask="证明过程中两次使用基本不等式，等号能同时成立吗？",
        steps=[
            "a+b+c≥3∛(abc)",
            "1/a+1/b+1/c≥3∛(1/(abc))",
            "两式相乘得乘积≥9，a=b=c 时同时取等",
        ],
        goal="学会对两组量分别用不等式再相乘",
        tip="把三数调成相等，看最后一行差值归零。",
        hint="分别对 a+b+c 与 1/a+1/b+1/c 使用三元均值不等式，再相乘。",
        explain="分别对两组量使用三元均值不等式：a+b+c≥3∛(abc)，1/a+1/b+1/c≥3∛(1/(abc))。"
                "两式相乘得乘积≥9。拖动三数使它们相等，可以看到差值为 0——两次取等条件都是 a=b=c，"
                "可以同时成立，所以下界 9 能取到。",
        success="对！两次取等条件一致，9 可以取到。",
        opts=[
            "两式相乘得 ≥9，且两次取等条件都是 a=b=c，可以同时成立",
            "只能得到 ≥3",
            "两次取等条件矛盾，9 取不到",
            "乘积可以小于 9",
        ],
        ans=0,
        retry="把乘积展开成 9 项，看看哪些项可以两两配对。",
    ),
    # ---------------------------------------------------------------- L5 应用
    q(
        name="2-12 综合：围栏面积最大（建模）",
        qtext="用长 P 的篱笆围一个矩形菜园，拖动长 l 与周长 P，观察面积与最大面积 P²/16 的差。",
        scene={
            "x": [0, 20],
            "y": [0, 110],
            "sliders": [
                slider("l", 0.5, 9.5, 6, 0.1, "长 l"),
                slider("P", 20, 38, 24, 0.5, "篱笆总长（周长）P"),
            ],
            "curves": [
                {"fn": "quad", "a": -1, "b": "P/2", "c": 0, "color": "#ffd479", "label": "面积 l·w"},
            ],
            "readouts": [
                readout("宽 w=P/2−l", "P/2-l"),
                readout("面积 lw", "l*(P/2-l)", "#40e0a8"),
                readout("最大 (P/4)²", "P*P/16", "#ffd479"),
                readout("最大 − 面积", "P*P/16-l*(P/2-l)", "#fb7185"),
            ],
        },
        ask="周长固定时，怎样的矩形面积最大？",
        steps=[
            "设长 l、宽 w，则 2(l+w)=P，即 l+w=P/2",
            "面积 lw≤((l+w)/2)²=P²/16",
            "等号当 l=w=P/4，即正方形时成立",
        ],
        goal="把『和定积最大』用于围栏建模",
        tip="把长拖到 P/4，看最后一行差值是否归零。",
        hint="长与宽的和是定值吗？固定和时乘积在什么情况下最大？",
        explain="拖动长 l 观察面积变化：周长固定意味着 l+w=P/2 为定值，"
                "于是 lw≤((l+w)/2)²=P²/16，等号当 l=w=P/4 时成立。所以周长固定时正方形面积最大。",
        success="对！正方形时面积最大，为 P²/16。",
        opts=[
            "长宽差距越大面积越大",
            "面积没有最大值",
            "最大值为 P²/8",
            "周长固定时正方形面积最大，最大值为 P²/16",
        ],
        ans=3,
        retry="先写出长与宽的关系，再看两数之和是否为定值。",
    ),
    q(
        name="2-13 综合：靠墙围栏（建模）",
        qtext="用长 L 的篱笆靠墙围一个矩形，墙这一边不用篱笆。拖动宽 w 与总长 L，观察面积与最大面积 L²/8 的差。",
        scene={
            "x": [0, 20],
            "y": [0, 60],
            "sliders": [
                slider("w", 0.5, 5, 3, 0.1, "宽 w"),
                slider("L", 12, 20, 16, 0.5, "篱笆总长 L"),
            ],
            "curves": [
                {"fn": "quad", "a": -2, "b": "L", "c": 0, "color": "#ffd479", "label": "面积 w(L−2w)"},
            ],
            "readouts": [
                readout("长 l=L−2w", "L-2*w"),
                readout("面积 lw", "w*(L-2*w)", "#40e0a8"),
                readout("最大 L²/8", "L*L/8", "#ffd479"),
                readout("最大 − 面积", "L*L/8-w*(L-2*w)", "#fb7185"),
            ],
        },
        ask="为什么靠墙时最大面积不是 L²/16？",
        steps=[
            "只有三条边用篱笆：l+2w=L",
            "面积 lw=w(L−2w)",
            "由 2w+(L−2w)=L 为定值得 lw≤L²/8，等号当 l=2w=L/2",
        ],
        goal="在真实情境中识别定值，选择正确的配凑方式",
        tip="注意篱笆只围三条边：长加两个宽等于 L。",
        hint="三条边总长固定，面积 w·l 中 l=L−2w，把 2w 与 (L−2w) 看成两数。",
        explain="对着滑块数一数篱笆围了几条边：靠墙时只有三条边用篱笆，即 l+2w=L。"
                "面积 wl=w(L−2w)=(1/2)·2w·(L−2w)≤(1/2)(L/2)²=L²/8，"
                "拖动 w 到 L/4 可看到面积达到最大，此时 l=2w=L/2。可见最大面积是封闭围栏的两倍。",
        success="对！靠墙时最大面积为 L²/8，是封闭围栏的两倍。",
        opts=[
            "与封闭围栏相同，最大值仍为 L²/16",
            "面积没有最大值",
            "l+2w=L，面积最大值为 L²/8，此时 l=2w",
            "最大值在 w=L 时取得",
        ],
        ans=2,
        retry="数一数篱笆围了几条边，再写出长与宽的关系。",
    ),
]

section = {
    "title": "基本不等式",
    "method": "基本不等式 · 均值不等式（AM-GM）",
    "color": "#F6BD16",
    "summary": "从平方非负性出发认识 a²+b²≥2ab 与 AM-GM，探究取等条件，再迁移到配凑、乘 1 法、换元与建模求最值。",
    "levels": levels,
}

with open(PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

data["ineq_basic"] = section

with open(PATH, "w", encoding="utf-8", newline="\n") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("OK: ineq_basic -> %d questions" % len(levels))
