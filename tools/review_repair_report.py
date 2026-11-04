# -*- coding: utf-8 -*-
"""审查 formula_repair_report.txt 的变更对，找可疑输出。"""
import io, sys, re, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
D = os.path.dirname(os.path.abspath(__file__))
rep = open(os.path.join(D, "formula_repair_report.txt"), encoding="utf-8").read().splitlines()

pairs = []
cur_file = ""
for i, l in enumerate(rep):
    if l.startswith("========"):
        cur_file = l.strip("= ").split("(")[0].strip()
    if l.startswith("  - "):
        before = l[4:]
        path = rep[i-1][4:] if i > 0 and rep[i-1].startswith("  [") else ""
        after = rep[i+1][4:] if i+1 < len(rep) and rep[i+1].startswith("  + ") else ""
        pairs.append((cur_file, path, before, after))

print("pairs:", len(pairs))
def show(t, lst, n=10):
    print("----", t, len(lst))
    for f, p, a, b in lst[:n]:
        print(" *", f, p)
        print("   -", a[:150])
        print("   +", b[:150])

DOLLAR = "$" + "$"
bad = [(f,p,a,b) for f,p,a,b in pairs if b.count(DOLLAR) % 2 == 1]
show("修复后奇数 $$（不该出现）", bad)
bad = [(f,p,a,b) for f,p,a,b in pairs if DOLLAR + " " + DOLLAR in b or DOLLAR+DOLLAR in b]
show("残留相邻/空段", bad)
bad = [(f,p,a,b) for f,p,a,b in pairs if re.search(r"\\\\[A-Za-z]", b)]
show("残留双反斜杠", bad)
bad = [(f,p,a,b) for f,p,a,b in pairs if re.search(r"(?<!\$)\$(?!\$)", b)]
show("残留单$", bad)
bad = [(f,p,a,b) for f,p,a,b in pairs if "\uE000" in b]
show("哨兵残留", bad)
bad = [(f,p,a,b) for f,p,a,b in pairs if "\x0c" in b or "\x08" in b]
show("控制符残留", bad)
# 无 $ 的纯文本被改动但看起来像误伤（没有任何数学字符）
bad = [(f,p,a,b) for f,p,a,b in pairs if DOLLAR not in a and DOLLAR in b and not re.search(r"[√≤≥≠≈∞∈∉⊆⊇∪∩→⇒∀∃∠°Δαβγθλμπ∅²³¹⁰⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₹]", a)]
show("纯文本被包（无强符号，需人工复核）", bad, 20)
# LOG 行
logs = [l for l in rep if "[LOG]" in l]
print("---- LOG 行", len(logs))
for l in logs[:15]:
    print(l)
