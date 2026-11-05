# -*- coding: utf-8 -*-
"""打印指定 data 文件中若干路径的当前字符串值（repr）。"""
import io, sys, os, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

WANT = {
    "vectors_levels.json": [
        "vec_dot.levels[0].q", "vec_dot.levels[1].explain",
        "vec_dot.levels[3].q", "vec_dot.levels[3].explain",
        "vec_collinear.levels[1].explain",
    ],
    "solid_methods.json": ["methods.complement.levels[6].hint"],
    "set_logic_levels.json": ["set_relation.levels[2].q"],
    "vector_levels.json": ["vector_4_3.levels[1].goal"],
    "trig_levels.json": ["trig_aux.levels[0].scene.readouts[1].label"],
}

def get(obj, path):
    import re
    cur = obj
    for seg in path.split("."):
        m = re.match(r"(\w+)\[(\d+)\]$", seg)
        if m:
            cur = cur[m.group(1)][int(m.group(2))]
        else:
            cur = cur[seg]
    return cur

for fn, paths in WANT.items():
    data = json.load(open(os.path.join(ROOT, "data", fn), encoding="utf-8"))
    for p in paths:
        v = get(data, p)
        print("### %s %s" % (fn, p))
        print(repr(v))
        print()
