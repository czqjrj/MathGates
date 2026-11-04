# -*- coding: utf-8 -*-
"""从 MicroTeX 源码提取支持的 LaTeX 命令名单 → mt_commands.txt"""
import re, os, glob

root = r"E:\MathGates-main\third_party\MicroTeX\src"
cmds = set()
for f in glob.glob(os.path.join(root, "res", "sym", "*.def.cpp")):
    with open(f, encoding="utf-8", errors="replace") as fh:
        for m in re.finditer(r"E\(\s*\d+\s*,\s*\d+\s*,\s*(\w+)\s*\)", fh.read()):
            cmds.add(m.group(1))
for f in glob.glob(os.path.join(root, "res", "builtin", "*.res.cpp")):
    with open(f, encoding="utf-8", errors="replace") as fh:
        txt = fh.read()
        for m in re.finditer(r'L"\\+([A-Za-z]+)"', txt):
            cmds.add(m.group(1))
        for m in re.finditer(r'insert\(\s*{\s*L"([A-Za-z]+)"', txt):
            cmds.add(m.group(1))
        for m in re.finditer(r'\{\s*L"([A-Za-z]+)"\s*,', txt):
            cmds.add(m.group(1))
# 常见补充（映射/宏形式，静态难提取）
extra = """frac dfrac tfrac sqrt text mathrm mathbf mathit mathbb vec hat bar tilde dot
times div cdot pm mp le leq ge geq ne neq approx equiv sim simeq cong propto in notin subset subseteq supset supseteq
cup cap emptyset varnothing forall exists neg to rightarrow leftarrow Rightarrow Leftrightarrow mapsto
ldots cdots dots prime circ angle deg sin cos tan cot sec csc arcsin arccos arctan lim log ln lg max min sup abs norm
sum prod int oint quad qquad left right big Big bigg Bigg bracket brace floor ceil langle rangle lvert rvert lVert rVert
alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi pi rho sigma tau upsilon phi chi psi omega
Gamma Delta Theta Lambda Xi Pi Sigma Upsilon Phi Psi Omega varphi vartheta varepsilon varpi varrho varsigma vartheta
begin end matrix pmatrix bmatrix vmatrix Bmatrix cases aligned array tabular binom choose overline underline
widehat widetilde overrightarrow stackrel substack limsup liminf argmin argmax mod pmod gcd lcm deg
lll lld leqq Geeq gtr sim nequal cong not ne
"""
cmds.update(extra.split())
out = r"E:\MathGates-main\mt_commands.txt"
with open(out, "w", encoding="utf-8") as fh:
    fh.write("\n".join(sorted(cmds)))
print(len(cmds), "commands ->", out)
