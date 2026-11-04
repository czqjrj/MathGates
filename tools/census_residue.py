# -*- coding: utf-8 -*-
"""普查当前 data/*.json（排除 legacy）里 $$..$$ 岛内与正文中的残留问题 token。"""
import io, sys, os, re, json, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MT = set(open(os.path.join(ROOT, "mt_commands.txt"), encoding="utf-8").read().split())

unknown = collections.Counter()
patterns = collections.Counter()
D = re.compile(r"\$\$([^$]+)\$\$")
CHECK_PATS = [
    r"\\thet(?![a-z])", r"\\lambd(?![a-z])", r"\\i\s+mplies", r"\{2,}",
    r"\$\\vec\{a\}=\$", r"\\sqrt\{\}", r"\\dfrac\{\}", r"\^\{?\}?\s*\+\$\$",
]
for fn in sorted(os.listdir(os.path.join(ROOT, "data"))):
    if not fn.endswith(".json") or fn == "inline_math.json":
        continue
    if fn.startswith("param_master") or fn.endswith("_param_auto.json"):
        continue
    txt = open(os.path.join(ROOT, "data", fn), encoding="utf-8").read()
    data = json.loads(txt)
    stack = []
    def walk(o, p):
        if isinstance(o, dict):
            for k, v in o.items():
                walk(v, p + "." + k)
        elif isinstance(o, list):
            for i, v in enumerate(o):
                walk(v, p + "[%d]" % i)
        elif isinstance(o, str):
            if "scene" in p.split("."):
                return
            for m in D.finditer(o):
                s = m.group(1)
                for cm in re.findall(r"\\([A-Za-z]+)", s):
                    if cm not in MT:
                        unknown[cm] += 1
                for pt in CHECK_PATS:
                    if re.search(pt, s):
                        patterns[pt + " @" + fn + p[:60]] += 1
            for pt in CHECK_PATS:
                if re.search(pt, o):
                    patterns["OUTSIDE:" + pt + " @" + fn + p[:60]] += 1
    walk(data, "")

print("== 未知命令（岛内） ==")
for k, v in unknown.most_common():
    print(" %-14s %d  (suggest=%s)" % (k, v, "yes" if (k + "a") in MT or (k + "e") in MT or (k + "s") in MT else "?"))
print("== 可疑模式 ==")
for k, v in patterns.most_common(40):
    print(" ", k, v)
