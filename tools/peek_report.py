# -*- coding: utf-8 -*-
"""抽查 formula_repair_report.txt 指定文件的变更对。"""
import io, sys, re, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
D = os.path.join(os.path.dirname(os.path.abspath(__file__)))
rep = open(os.path.join(D, "formula_repair_report.txt"), encoding="utf-8").read().splitlines()
want = sys.argv[1] if len(sys.argv) > 1 else "trig_levels"
lim = int(sys.argv[2]) if len(sys.argv) > 2 else 30
cur = -1
n = 0
for i, l in enumerate(rep):
    if l.startswith("========"):
        cur = i
    if i > cur and want in rep[cur] and l.startswith("  - ") and n < lim:
        print(rep[i][4:])
        print("  " + rep[i+1][4:] if i+1 < len(rep) else "")
        print()
        n += 1
