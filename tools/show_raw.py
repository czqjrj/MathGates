# -*- coding: utf-8 -*-
"""查看原始 JSON 文本中的问题片段（字节级 repr，不做任何修改）"""
import io, sys, re, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
targets = sys.argv[1:] or ["trig_levels.json"]
for fn in targets:
    p = os.path.join("data", fn)
    print("=" * 20, p)
    with open(p, encoding="utf-8") as f:
        for i, line in enumerate(f, 1):
            if re.search(r"\\\{|\\\|\\+|\$\$|\\\$|(^|[^$])\$([^$]|$)", line):
                pass
            # 只打印含反斜杠紧邻 $、或 3+ 连续 $、或 \xNN 控制符的行
            if re.search(r"\\\$|\$\\", line) or re.search(r"[\x00-\x08\x0b\x0c]", line) or re.search(r"\$\$\$", line) or re.search(r"\\\\\\", line):
                print("%5d: %s" % (i, repr(line.rstrip("\n"))[:220]))
