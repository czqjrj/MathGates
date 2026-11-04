# -*- coding: utf-8 -*-
"""公式显示问题全库扫描器
口径与运行时一致：
- InlineMath._dollar_re = r"\$\$([^$]+)\$\$"  —— 内含 $ 的段不会被渲染（原文漏出）
- 相邻 $$$$ 会打断匹配
- 渲染端 MicroTeX 把解析后的 `\\` 当换行；JSON 源里 4 个反斜杠 = 解析后 2 个 = 坏
"""
import json, re, sys, io, os

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

DATA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")

# 运行时的匹配器：内容不能含 $
RUNTIME_DOLLAR = re.compile(r"\$\$([^$]+)\$\$")
CJK = re.compile(r"[\u2e80-\u303f\u31c0-\u9fff\uf900-\ufaff\ufe30-\ufe4f\uff00-\uffef]+")
# 视觉数学字符（同 check_inline）
MATH_CHARS = set("²³¹⁰⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₉√·×÷±≤≥≠≈∞∈∉⊆⊇∪∩→←⇒⇔∀∃∠°Δαβγθλμπ∅")
# MicroTeX 支持命令表（tools/extract_mt_cmds.py 从源码提取）
try:
    KNOWN_CMDS = set(open(os.path.join(os.path.dirname(DATA), "mt_commands.txt"), encoding="utf-8").read().split())
except Exception:
    KNOWN_CMDS = set()

issues = []          # (file, path, kind, detail, snippet)
def add(f, p, kind, detail, snip):
    issues.append((f, p, kind, detail, snip[:120]))

def walk(obj, f, p=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            walk(v, f, p + "." + str(k))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            walk(v, f, p + "[%d]" % i)
    elif isinstance(obj, str):
        check_string(obj, f, p)

def check_string(t, f, p):
    # 0) 控制字符（JSON \t 误伤产物）
    if re.search(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", t):
        add(f, p, "CTRL-CHAR", "含控制字符", t)
    # 1) $$ 数量奇偶（按连续 $ 串粗查不成对）
    n = t.count("$$")
    segs = list(RUNTIME_DOLLAR.finditer(t))
    # 找所有 $$ 出现位置
    dd = [m.start() for m in re.finditer(r"\$\$", t)]
    leftover = len(dd) - 2 * len(segs)
    if leftover != 0:
        # 判断是内容含 $ 还是不成对
        add(f, p, "UNMATCHED-$$", "%d 处 $$ 无法配对/内容含$" % leftover, t)
    # 2) 段内容问题
    for m in segs:
        s = m.group(1)
        problems = []
        if "\\\\" in s:
            problems.append("含\\\\(换行)")
        if "$" in s:
            problems.append("含$")
        # 反斜杠+非法命令
        for cm in re.findall(r"\\([A-Za-z]+)", s):
            if cm not in KNOWN_CMDS:
                problems.append("未知命令\\%s" % cm)
        for cm in re.findall(r"\\([^A-Za-z\\\\])", s):
            if cm not in "{}%$&_#,;!· ":
                problems.append("可疑转义\\%s(0x%02x)" % (cm, ord(cm)))
        if s != s.strip():
            problems.append("首尾空白")
        if "&" in s:
            problems.append("含&(align残留)")
        if "\\" not in s and not re.search(r"[A-Za-z0-9]", s):
            problems.append("段内无内容")
        if problems:
            add(f, p, "SEG:" + "|".join(sorted(set(problems))), "", s)
    # 3) 段外残留：单个 $、{f:}（$$段用中文占位，保证 gap 切分与运行时一致）
    outside = RUNTIME_DOLLAR.sub("一", t)
    if re.search(r"(?<!\$)\$(?!\$)", outside):
        add(f, p, "SINGLE-$", "裸 $ 分隔符（运行时不渲染）", outside)
    if "{f:" in outside:
        add(f, p, "FREF", "{f:} 引用", outside)
    # 4) Unicode 数学片段（段外）
    gaps = []
    last = 0
    for m in CJK.finditer(outside):
        gaps.append(outside[last:m.start()]); last = m.end()
    gaps.append(outside[last:])
    for g in gaps:
        core = rt_trim(g)
        if not core or core in COVERED:
            continue
        if _has_math_char(core) :
            add(f, p, "UNICODE-MATH", "", core)

def _has_math_char(s):
    for i, c in enumerate(s):
        if c == "·":
            prev_ws = i == 0 or s[i-1] == " "
            next_ws = i == len(s) - 1 or s[i+1] == " "
            if prev_ws or next_ws:
                continue
        if c in MATH_CHARS:
            return True
    return False

def load_coverage():
    """data/inline_math.json 已覆盖的片段（运行时 trim 规则同 _inline_trim）。"""
    cov = set()
    p = os.path.join(DATA, "inline_math.json")
    if os.path.exists(p):
        with open(p, encoding="utf-8") as fh:
            m = json.load(fh)
        for k in m:
            cov.add(k)
    return cov

COVERED = load_coverage()

def rt_trim(s):
    s = s.strip()
    while s and s[0] in ",;:.!?":
        s = s[1:]
    while s and s[-1] in ",;:.!?":
        s = s[:-1]
    return s

def main():
    files = sorted(f for f in os.listdir(DATA) if f.endswith(".json"))
    total = {}
    for f in files:
        if f == "inline_math.json":
            continue  # 覆盖表本身单独查
        try:
            with open(os.path.join(DATA, f), encoding="utf-8") as fh:
                data = json.load(fh)
        except Exception as e:
            add(f, "-", "JSON-ERROR", str(e), "")
            continue
        walk(data, f)
    # 汇总
    from collections import Counter
    kinds = Counter(k for _, _, k, _, _ in issues)
    print("==== 按类别汇总 ====")
    for k, c in kinds.most_common():
        print("%-28s %d" % (k, c))
    print("总计 %d 条（%d 个文件）" % (len(issues), len(files)))
    # 明细写文件
    with open("scan_formula_issues.txt", "w", encoding="utf-8") as out:
        cur = None
        for f, p, k, d, s in issues:
            out.write("%s | %s | %s %s | %s\n" % (f, p, k, ("[" + d + "]") if d else "", s))
    print("明细见 scan_formula_issues.txt")

if __name__ == "__main__":
    main()
