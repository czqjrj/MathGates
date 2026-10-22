#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""B1 参数母版脚手架 → 引擎方言修正器（TODO B1 接入前置第一步）。

用法：
    python tools/fix_param_master_dialect.py --dry-run      # 只看会改什么
    python tools/fix_param_master_dialect.py --apply        # 落地
    python tools/fix_param_master_dialect.py --apply --no-t2s   # 只修读数，不做繁转简

为什么需要：`data/param_master_*.json` / `data/*_param_auto.json` 是 B1 自动生成的脚手架，
生成时没照 `LabPlane` 的真实解析口径写，`tools/check_param_masters.gd` 实测到 155 条方言不兼容。
本脚本先做**不需要设计决策**的两类（其余三类要等「改数据 vs 扩 LabPlane」拍板）：

1. **E_READOUT_CMP（51 条）**：读数表达式写了比较式（`abs(a-1)<0.15`、`k>=0`）。
   `LabPlane._ex_expr()` 只支持 `+ - * / ^` 括号与 sqrt/abs/sin/cos/tan，**没有比较运算**，
   解析失败会**静默回退兜底值** → 「a≈1?」这类读数永远显示 0，学生看不出自己离达标多远。
   改法：把「是否达标」改成「**当前偏差**」——`abs(a-1)<0.15` → `abs(a-1)`，label 同步改写成
   「a 与 1 的偏差」。这不是将就：关卡的 `tol` 本来就是达标阈值，「偏差 < 0.15 即过关」
   比一个恒为 0 的布尔读数更有用。`k>=0` 这类无偏差可说的，退回显示 `k` 本身，
   条件写进 label（label 是纯文本，引擎不参与求值）。

2. **W_TRAD（51 关繁体）**：生成的文案是繁体，全项目口径为简体。
   **只逐字转换汉字**（Unicode CJK 区间），不碰标点——否则「」会被换成 “”，
   与全项目引号口径打架；LaTeX 命令是 ASCII，天然不受影响。

排版：全程**行级定点替换**，不重序列化 JSON（这批文件 CRLF/LF 混用，
`json.dumps` 整体重写会产生几百行无关 diff）。与 `tools/fix_labels.gd` 同一口径。
"""

import glob
import json
import os
import re
import sys

try:
    from zhconv import convert as _t2s
except ImportError:
    _t2s = None

DRY = True
DO_T2S = True

# 表达式内的子串改写：把引擎没有的写法换成等价的、引擎能算的写法。
# 必须和 READOUT_FIX **同一趟**做：`abs(2*pow(q,3)-16)<0.1` 同时中了比较式与未知函数，
# 只剥比较式的话剩下来的 expr 仍带 pow，闸门会把「修完的结果」报成一条新问题。
EXPR_REWRITE = {
    "pow(q,3)": "q*q*q",
}

# 比较式读数 → (新 expr, 新 label)。键是引擎读不了的旧表达式原文。
READOUT_FIX = {
    "abs(1+4*d-9)<0.1": ("abs(1+4*d-9)", "a5 与 9 的偏差"),
    "abs(10*p-6)<0.1": ("abs(10*p-6)", "E(X) 与 6 的偏差"),
    "abs(2*pow(q,3)-16)<0.1": ("abs(2*q*q*q-16)", "a4 与 16 的偏差"),
    "abs(a--1)<0.15": ("abs(a+1)", "a 与 -1 的偏差"),
    "abs(a-1)<0.15": ("abs(a-1)", "a 与 1 的偏差"),
    "abs(a-2)<0.15": ("abs(a-2)", "a 与 2 的偏差"),
    "abs(a/2-2)<0.2": ("abs(a/2-2)", "斜率 a/2 与 2 的偏差"),
    "abs(b-2)<0.15": ("abs(b-2)", "b 与 2 的偏差"),
    "abs(b-3)<0.15": ("abs(b-3)", "b 与 3 的偏差"),
    "abs(e-0.6)<0.05": ("abs(e-0.6)", "e 与 0.6 的偏差"),
    "abs(k-2)<0.15": ("abs(k-2)", "k 与 2 的偏差"),
    "abs(r-3)<0.2": ("abs(r-3)", "r 与 3 的偏差"),
    "k>=0": ("k", "k（需 ≥ 0）"),
}

RE_EXPR = re.compile(r'("expr"\s*:\s*")([^"]*)(")')
RE_LABEL = re.compile(r'("label"\s*:\s*")([^"]*)(")')
# 汉字区间（基本区 + 扩展 A + 兼容表意文字）——只有这些字符参与繁转简。
# 用码位写死，避免把 「」 ‘’ ！? ， 之类标点一起换掉（全项目引号口径是「」）。
CJK = re.compile("[\\u3400-\\u4dbf\\u4e00-\\u9fff\\uf900-\\ufaff]")


def scaffold_files():
    out = []
    for pat in ("data/param_master*.json", "data/*_param_auto.json",
                "data/function_lab_param_master.json", "data/function_lab_levels_param.json"):
        out += sorted(glob.glob(pat))
    return out


def fix_readouts(lines):
    """行级：① 比较式 expr 换成偏差 expr 并回头改同一对象的 label；
    ② 所有 expr 一律套用 EXPR_REWRITE（引擎没有的写法换成等价写法）。"""
    n_expr = n_label = n_rw = 0
    for i, ln in enumerate(lines):
        m = RE_EXPR.search(ln)
        if not m:
            continue
        old = m.group(2)
        new = old
        if old in READOUT_FIX:
            new, new_label = READOUT_FIX[old]
            n_expr += 1
            for j in range(i - 1, max(-1, i - 4), -1):
                lm = RE_LABEL.search(lines[j])
                if lm:
                    lines[j] = RE_LABEL.sub(lambda mm, l=new_label: mm.group(1) + l + mm.group(3),
                                            lines[j], count=1)
                    n_label += 1
                    break
        for a, b in EXPR_REWRITE.items():
            if a in new:
                new = new.replace(a, b)
                n_rw += 1
        if new != old:
            lines[i] = RE_EXPR.sub(lambda mm, v=new: mm.group(1) + v + mm.group(3), ln, count=1)
    return n_expr, n_label, n_rw


def convert_cjk(text):
    """逐字繁转简，仅作用于汉字。映射结果不是单字的一律跳过（防止改动 JSON 结构）。"""
    out = []
    changed = 0
    skipped = []
    for ch in text:
        if not CJK.match(ch):
            out.append(ch)
            continue
        s = _t2s(ch, "zh-cn")
        if len(s) != 1:
            skipped.append(ch)
            out.append(ch)
            continue
        if s != ch:
            changed += 1
        out.append(s)
    if skipped:
        print("   [跳过 %d 个非单字映射：%s]" % (len(skipped), "".join(sorted(set(skipped)))))
    return "".join(out), changed


def main():
    global DRY, DO_T2S
    args = sys.argv[1:]
    if "--apply" in args:
        DRY = False
    if "--no-t2s" in args:
        DO_T2S = False
    if DO_T2S and _t2s is None:
        print("缺 zhconv（pip install zhconv），本次跳过繁转简；只修读数。")
        DO_T2S = False

    tot_e = tot_l = tot_han = tot_rw = 0
    files = scaffold_files()
    for path in files:
        with open(path, encoding="utf-8", newline="") as f:
            raw = f.read()
        lines = raw.splitlines(keepends=True)
        ne, nl, nrw = fix_readouts(lines)
        text = "".join(lines)
        han = 0
        if DO_T2S:
            text, han = convert_cjk(text)
        if ne or nl or han or nrw:
            tot_e += ne
            tot_l += nl
            tot_han += han
            tot_rw += nrw
            print("%-42s 读数 %2d 条 / label %2d 处 / 函数改写 %2d 处 / 汉字转简 %4d"
                  % (path, ne, nl, nrw, han))
            if not DRY:
                with open(path, "w", encoding="utf-8", newline="") as f:
                    f.write(text)
    print("=" * 70)
    print("%s：读数 %d 条 / label %d 处 / 汉字 %d 个，涉及 %d 个文件"
          % ("预演（未写盘）" if DRY else "已落地", tot_e, tot_l, tot_han, len(files)))
    # 落盘后自检：JSON 必须仍然可解析
    if not DRY:
        bad = []
        for path in files:
            try:
                with open(path, encoding="utf-8") as f:
                    json.load(f)
            except Exception as e:
                bad.append("%s: %s" % (path, e))
        print("JSON 可解析自检：%s" % ("全部通过" if not bad else "失败 → " + "; ".join(bad)))
        if bad:
            sys.exit(1)


if __name__ == "__main__":
    main()
