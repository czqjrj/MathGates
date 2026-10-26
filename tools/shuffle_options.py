#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""B8：把「正确项恒写在第 1 位」的存储顺序改成规范顺序。

背景
----
运行时会打乱选项（`StageRules.order_for`），所以这不是「漏答案」的问题；
但存量数据 90% 的 `ans==0` 说明**没人审过选项顺序**，而且一旦某题关掉乱序
（含「以上都对」等顺序相关措辞、或显式 shuffle:false），答案就恒在 A。

做法
----
不是「随机洗牌」，而是**按内容哈希定序**：
    order = sort(range(n), key=sha256("<文件>:<关卡>:<轮次下标>\0<选项原文>"))
好处是**幂等**——同一份内容无论跑几次结果都一样，不依赖随机种子，
也不需要在数据里记「已洗过」的标记。正确项落在哪个位置由内容决定，
对 838 题来说等价于均匀分布（实测 ans==0 ≈ 25%）。

关键约束
--------
1. **绝不重新序列化 JSON**。题库是手工排版的（小数组写在一行、scene 紧凑），
   整体 `json.dump` 会把 26 个文件全部重排，产生无法审阅的巨型 diff。
   这里只做**span 级替换**：只改 `opts` 数组内元素的排列与 `ans` 的数字，
   其余字节原样保留（含 CRLF/LF、缩进、逗号风格）。
2. **跳过关掉乱序的题**（与 `StageRules.SHUFFLE_MARKERS` 保持一致），
   否则「以上都不对」会被排到中间。
3. **多选题**（`ans` 为数组，如 `[0,1]`）按索引重映射，集合语义不变。

用法
----
    python tools/shuffle_options.py               # 预演（默认）
    python tools/shuffle_options.py --apply       # 落盘

依赖：Python 3.8+，无第三方库。
"""

import argparse
import glob
import hashlib
import json
import os
import re
import sys

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")

# 与 scripts/rules/StageRules.gd::SHUFFLE_MARKERS 保持一致
SHUFFLE_MARKERS = ["以上", "都对", "都错", "都正确", "都不正确", "上述", "以下"]


# ---------------------------------------------------------------- 带 span 的 JSON 解析
# 只需要「每个值的起止位置」，因此手写一个极简解析器；不构造值。
class Node:
    __slots__ = ("kind", "start", "end", "members", "items", "scalar")

    def __init__(self, kind, start):
        self.kind = kind          # "object" / "array" / "scalar"
        self.start = start
        self.end = start
        self.members = None       # object: [(key, key_start, value_node)]
        self.items = None         # array: [value_node]
        self.scalar = None        # int / bool / None 的 Python 值


_WS = " \t\r\n"


def _skip(s, i):
    while i < len(s) and s[i] in _WS:
        i += 1
    return i


def parse(s, i=0):
    i = _skip(s, i)
    if s[i] == "{":
        node = Node("object", i)
        node.members = []
        i = _skip(s, i + 1)
        if s[i] == "}":
            node.end = i + 1
            return node, i + 1
        while True:
            i = _skip(s, i)
            assert s[i] == '"', "expected key at %d" % i
            key, i = _parse_string(s, i)
            i = _skip(s, i)
            assert s[i] == ":", "expected ':' at %d" % i
            val, i = parse(s, i + 1)
            node.members.append((key, val))
            i = _skip(s, i)
            if s[i] == ",":
                i += 1
                continue
            assert s[i] == "}", "expected ',' or '}' at %d" % i
            node.end = i + 1
            return node, i + 1
    if s[i] == "[":
        node = Node("array", i)
        node.items = []
        i = _skip(s, i + 1)
        if s[i] == "]":
            node.end = i + 1
            return node, i + 1
        while True:
            val, i = parse(s, i)
            node.items.append(val)
            i = _skip(s, i)
            if s[i] == ",":
                i += 1
                continue
            assert s[i] == "]", "expected ',' or ']' at %d" % i
            node.end = i + 1
            return node, i + 1
    if s[i] == '"':
        start = i
        _text, i = _parse_string(s, i)
        node = Node("scalar", start)
        node.end = i
        return node, i
    # 数字 / true / false / null
    start = i
    while i < len(s) and s[i] not in ",]}" and s[i] not in _WS:
        i += 1
    node = Node("scalar", start)
    node.end = i
    raw = s[start:i]
    node.scalar = json.loads(raw)
    return node, i


def _parse_string(s, i):
    """返回 (解码后的字符串, 结束位置)。"""
    assert s[i] == '"'
    j = i + 1
    while s[j] != '"':
        if s[j] == "\\":
            j += 2
        else:
            j += 1
    return json.loads(s[i:j + 1]), j + 1


def _find_key(obj_node, key):
    for k, v in obj_node.members:
        if k == key:
            return v
    return None


# ---------------------------------------------------------------- 定序与重写
def canonical_order(texts, prefix):
    def h(i):
        return hashlib.sha256((prefix + "\x00" + texts[i]).encode("utf-8")).hexdigest()
    return sorted(range(len(texts)), key=h)


def rebuild_array(s, arr_node, order):
    """按 order 重排数组元素，保留原有的空白/逗号/换行——只换元素位置。"""
    parts = [s[arr_node.items[order[k]].start:arr_node.items[order[k]].end] for k in range(len(order))]
    gaps = []
    gaps.append(s[arr_node.start + 1:arr_node.items[0].start])
    for k in range(1, len(arr_node.items)):
        gaps.append(s[arr_node.items[k - 1].end:arr_node.items[k].start])
    gaps.append(s[arr_node.items[-1].end:arr_node.end - 1])
    out = "[" + gaps[0]
    for k, p in enumerate(parts):
        out += p + gaps[k + 1]
    return out + "]"


def shuffle_text(raw, label):
    """对单个文件做 span 级重写，返回 (新文本, 统计)。"""
    doc, _ = parse(raw, 0)
    assert doc.kind == "object", label + " 顶层不是对象"

    edits = []          # (start, end, replacement)
    skipped = []
    n = 0

    def visit(node, path):
        nonlocal n
        if node.kind == "object":
            opts = _find_key(node, "opts")
            ans = _find_key(node, "ans")
            if opts is not None and ans is not None and opts.kind == "array":
                texts = [raw[opts.items[i].start:opts.items[i].end] for i in range(len(opts.items))]
                plain = [json.loads(t) for t in texts]
                blocked = [m for m in SHUFFLE_MARKERS for t in plain if m in t]
                if len(plain) < 2 or blocked:
                    skipped.append((path, sorted(set(blocked))))
                else:
                    order = canonical_order(plain, label + ":" + path)
                    new_ans = order.index(_old_ans_index(ans, plain))
                    edits.append((opts.start, opts.end, rebuild_array(raw, opts, order)))
                    if ans.kind == "scalar":
                        edits.append((ans.start, ans.end, str(new_ans)))
                    else:
                        # 多选：ans 是索引数组，逐元素重映射（长度不变）
                        for idx, el in enumerate(ans.items):
                            old = int(el.scalar)
                            edits.append((el.start, el.end, str(order.index(old))))
                    n += 1
            for k, v in node.members:
                visit(v, path + "/" + k)
        elif node.kind == "array":
            for idx, v in enumerate(node.items):
                visit(v, path + "/" + str(idx))

    visit(doc, "")

    # 从后往前替换，避免位移
    edits.sort(key=lambda e: e[0], reverse=True)
    out = raw
    for start, end, rep in edits:
        out = out[:start] + rep + out[end:]
    return out, n, skipped


def _old_ans_index(ans_node, plain):
    """原答案所在下标（多选取第一个，仅用于单选的换位校验）。"""
    if ans_node.kind == "scalar":
        return int(ans_node.scalar)
    return int(ans_node.items[0].scalar)


# ---------------------------------------------------------------- 校验
def verify(old_raw, new_raw, label):
    """重读新旧文本，逐题确认：选项集合不变、正确项文本不变、其余字段不变。"""
    old = json.loads(old_raw)
    new = json.loads(new_raw)
    problems = []
    n_checked = 0

    def walk(o, nw, path):
        nonlocal n_checked
        if isinstance(o, dict):
            if "opts" in o and "ans" in o:
                n_checked += 1
                a, b = o["opts"], nw["opts"]
                if sorted(map(str, a)) != sorted(map(str, b)):
                    problems.append(path + " 选项集合变了")
                oa, nb = o["ans"], nw["ans"]
                if isinstance(oa, int):
                    if a[oa] != b[nb]:
                        problems.append(path + " 正确项文本变了")
                else:
                    if sorted(a[i] for i in oa) != sorted(b[i] for i in nb):
                        problems.append(path + " 多选正确项集合变了")
                rest_o = {k: v for k, v in o.items() if k not in ("opts", "ans")}
                rest_n = {k: v for k, v in nw.items() if k not in ("opts", "ans")}
                if rest_o != rest_n:
                    problems.append(path + " 其他字段被改动")
            for k in o:
                if k != "levels":
                    walk(o[k], nw[k], path + "/" + k)
                else:
                    for i in range(len(o[k])):
                        walk(o[k][i], nw[k][i], path + "/levels/%d" % i)
        elif isinstance(o, list):
            for i in range(len(o)):
                walk(o[i], nw[i], path + "/%d" % i)

    walk(old, new, "")
    return n_checked, problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="真正写回文件（默认只预演）")
    args = ap.parse_args()

    files = sorted(glob.glob(os.path.join(DATA_DIR, "*_levels.json")))
    total_q = 0
    total_files = 0
    ans_hist_before = {}
    ans_hist_after = {}
    all_problems = []

    for path in files:
        label = os.path.basename(path)
        raw = open(path, "rb").read().decode("utf-8")
        if "opts" not in raw:
            continue
        new, count, skipped = shuffle_text(raw, label)
        if new == raw:
            continue
        checked, problems = verify(raw, new, label)
        if problems:
            all_problems.extend(problems)
            print("!! %-30s 校验失败 %d 处" % (label, len(problems)))
            for p in problems[:5]:
                print("     " + p)
            continue
        # 统计前后分布
        for tag, text in (("before", raw), ("after", new)):
            doc = json.loads(text)
            hist = ans_hist_before if tag == "before" else ans_hist_after

            def count_ans(node):
                if isinstance(node, dict):
                    if "opts" in node and "ans" in node and isinstance(node["ans"], int):
                        hist[node["ans"]] = hist.get(node["ans"], 0) + 1
                    for v in node.values():
                        count_ans(v)
                elif isinstance(node, list):
                    for v in node:
                        count_ans(v)

            count_ans(doc)
        print("%-30s 重排 %3d 题  跳过 %d 题 %s" % (
            label, count, len(skipped),
            ("(顺序相关措辞)" if skipped else "")))
        total_q += count
        total_files += 1
        if args.apply:
            open(path, "wb").write(new.encode("utf-8"))

    print()
    print("文件 %d 个 / 重排 %d 题%s" % (
        total_files, total_q, "" if args.apply else "（预演，未写盘；加 --apply 落盘）"))
    for tag, hist in (("前", ans_hist_before), ("后", ans_hist_after)):
        n = sum(hist.values())
        if not n:
            continue
        print("ans 分布（%s）: %s   ans==0 = %d/%d (%.1f%%)" % (
            tag,
            "  ".join("ans%d=%d" % (k, hist[k]) for k in sorted(hist)),
            hist.get(0, 0), n, 100.0 * hist.get(0, 0) / n))
    if all_problems:
        print("\n有 %d 处校验失败，未写盘。" % len(all_problems))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
