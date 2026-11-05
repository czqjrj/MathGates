# -*- coding: utf-8 -*-
r"""
formula_repair.py —— data/*.json 数学公式显示问题批量修复器（文本级，保留排版）

用法:
    python tools/formula_repair.py                 # 预览全部受影响文件
    python tools/formula_repair.py trig_levels.json vectors_levels.json
    python tools/formula_repair.py --apply ...     # 写回

修复规则（与运行时 InlineMath/\$\$([^$]+)\$\$ + MicroTeX 口径对齐）:
 1. 反斜杠塌缩: 解析后 `\\+cmd` → `\cmd`（MicroTeX 把 `\\` 当换行，导致式子断行/漏字母）
 2. JSON 转义损伤还原: 单反斜杠 `\frac` 被 JSON 解成 FF+"rac" 等控制字符 → 复原为 `\frac`
 3. 定界符规范化: `$x$`→`$$x$$`、`$$$`→`$$`、相邻 `$$A$$$$B$$` 合并、无配对的 `$$` 重组
 4. 边界吸附: `sin$$\alpha$$`、`2$$\pi$$/ω` 这类「半个式子在图里半个在正文」→ 吸进同一个 `$$..$$`
 5. Unicode 数学片段 → LaTeX（上/下标、希腊字母、关系/集合/三角算符、√、°、函数名）
 6. 已知错误命令: `\time`→`\times`、`\appro`→`\approx`、artifact 模式（`\g$$e_{3}$$` 等）
"""
import json, re, sys, io, os, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MT_CMDS = set(open(os.path.join(ROOT, "mt_commands.txt"), encoding="utf-8").read().split())

# ---------------- 字符表 ----------------
SUP = {"⁰":"0","¹":"1","²":"2","³":"3","⁴":"4","⁵":"5","⁶":"6","⁷":"7","⁸":"8","⁹":"9",
       "⁺":"+","⁻":"-","ⁿ":"n","ⁱ":"i","ᵏ":"k","ᵐ":"m","ᵖ":"p","ˣ":"x","ˡ":"l","ᵗ":"t",
       "ᵤ":"u","ᵣ":"r","ˢ":"s","ᵃ":"a","ᵉ":"e","ʰ":"h","ᵧ":"y","ᵦ":"b","ᵟ":"d","ᵠ":"phi","ᵟ":"d"}
SUB = {"₀":"0","₁":"1","₂":"2","₃":"3","₄":"4","₅":"5","₆":"6","₇":"7","₈":"8","₉":"9",
       "₊":"+","₋":"-","ₙ":"n","ₘ":"m","ₚ":"p","ₛ":"s","ᵣ":"r","ₗ":"l","ₜ":"t","ᵤ":"u","ₓ":"x","ₖ":"k","ᵢ":"i","ⱼ":"j","ₐ":"a","ₑ":"e","ₒ":"o","ₕ":"h","ₔ":"e"}
SYM = {"α":"\\alpha ","β":"\\beta ","γ":"\\gamma ","δ":"\\delta ","ε":"\\varepsilon ","ζ":"\\zeta ",
       "η":"\\eta ","θ":"\\theta ","ι":"\\iota ","κ":"\\kappa ","λ":"\\lambda ","μ":"\\mu ","ν":"\\nu ",
       "ξ":"\\xi ","π":"\\pi ","ρ":"\\rho ","σ":"\\sigma ","τ":"\\tau ","υ":"\\upsilon ","φ":"\\varphi ",
       "χ":"\\chi ","ψ":"\\psi ","ω":"\\omega ","ϕ":"\\phi ","ε̵":"\\varepsilon ",
       "Γ":"\\Gamma ","Δ":"\\Delta ","Θ":"\\Theta ","Λ":"\\Lambda ","Ξ":"\\Xi ","Π":"\\Pi ","Σ":"\\Sigma ",
       "Υ":"\\Upsilon ","Φ":"\\Phi ","Ψ":"\\Psi ","Ω":"\\Omega ",
       "≤":"\\le ","≥":"\\ge ","≠":"\\ne ","≈":"\\approx ","≡":"\\equiv ","∼":"\\sim ","∽":"\\backsim ",
       "∞":"\\infty ","∈":"\\in ","∉":"\\notin ","⊆":"\\subseteq ","⊇":"\\supseteq ","⊂":"\\subset ","⊃":"\\supset ",
       "∪":"\\cup ","∩":"\\cap ","∅":"\\varnothing ","∀":"\\forall ","∃":"\\exists ","¬":"\\neg ",
       "→":"\\to ","←":"\\leftarrow ","⇒":"\\Rightarrow ","⇐":"\\Leftarrow ","⇔":"\\Leftrightarrow ",
       "∠":"\\angle ","ℓ":"\\ell ","±":"\\pm ","∓":"\\mp ","×":"\\times ","÷":"\\div ","∗":"* ",
       "≪":"\\ll ","≫":"\\gg ","∝":"\\propto ","−":"- ","–":"- ","⊥":"\\perp ","∥":"\\parallel ",
       "∑":"\\sum ","∏":"\\prod ","∧":"\\land ","∨":"\\lor ","∴":"\\therefore ","∵":"\\because ",
       "·":"\\cdot "}
FUNCS = ["arcsin","arccos","arctan","sinh","cosh","tanh","sin","cos","tan","cot","sec","csc","log","ln","lg","max","min"]

# 数学可续接字符（边界吸附用；不含空格、不含 CJK/全角）
MR = set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-*/^_()=<>|.,;:!'") \
   | set(SYM) | set(SUP) | set(SUB) | set("√°∓±×÷≤≥≠≈∞∈∉⊆⊇∪∩∀∃→⇒⇔∠Δ∅∝∴∵∑∏√∥⊥−")
CJK = re.compile(r"[\u2e80-\u303f\u31c0-\u9fff\uf900-\ufaff\ufe30-\ufe4f\uff00-\uffef]")
MATH_FLAG = set("²³¹⁰⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₉√·×÷±≤≥≠≈∞∈∉⊆⊇∪∩→←⇒⇔∀∃∠°Δαβγθλμπ∅")
CTRLMAP = {"\x0c": "f", "\t": "t", "\n": "n", "\r": "r", "\x08": "b"}

def rt_trim(s):
    s = s.strip()
    while s and s[0] in ",;:.!?":
        s = s[1:]
    while s and s[-1] in ",;:.!?":
        s = s[:-1]
    return s

# ---------------- 阶段 1: 反斜杠/控制符 ----------------
def fix_ctrl(s, log):
    def rep(m):
        c, rest = m.group(1), m.group(2)
        if not rest:
            return m.group(0)
        cand = "\\" + CTRLMAP[c] + rest
        cmd = re.match(r"\\([A-Za-z]+)", cand)
        if cmd and cmd.group(1) in MT_CMDS:
            return cand + " "
        log.append("ctrl-uncertain: %r near %r" % (c, rest))
        return cand + " "
    return re.sub(r"([\x08\x0c\t\n\r])([A-Za-z]+)", rep, s)

def collapse_bs(s):
    # 解析后 2+ 个反斜杠 → 1 个（数据里无矩阵换行，`\\` 一律是转义事故）
    return re.sub(r"\\{2,}([A-Za-z])", r"\\\1", s)

# ---------------- 阶段 2: artifact 目标表 ----------------
ARTIFACTS = [
    (r"\\g\$\$e_\{(\d)\}\$\$",  r"\\ge \1"),
    (r"\\time\$\$s_\{(\d)\}\$\$", r"\\times \1"),
    (r"\\appro\$\$x_\{(\d)\}\$\$", r"\\approx \1"),
    (r"\\time(?![A-Za-z])", r"\\times "),
    (r"\\appro(?![A-Za-z])", r"\\approx "),
    (r"\$2a\b", r"2a"),  # vectors: $\vec{b}=$2a  → =2a
]
def fix_artifacts(s):
    for pat, r in ARTIFACTS:
        s = re.sub(pat, r, s)
    return s

# ---------------- 阶段 3: 定界符重组 ----------------
MR |= set("\\{}")

def _is_mr(ch):
    return ch in MR

def rebuild_dollars(s):
    """把字符串按 $ 串切分为 [kind, text] 序列（kind: 'm' math / 't' text）。"""
    toks = re.split(r"(\$+)", s)
    pieces = []
    mode = "t"
    n = len(s)
    for i, tk in enumerate(toks):
        if not re.fullmatch(r"\$+", tk or ""):
            if tk == "":
                continue
            pieces.append([mode, tk])
            continue
        # 判定该 $ 串翻转几次：依据左右邻字符
        left = s[max(0, 0):]  # 占位，改用索引计算
        lpos = i - 1
        rpos = i + 1
        left_ch = toks[lpos][-1] if lpos >= 0 and toks[lpos] else ""
        right_ch = toks[rpos][0] if rpos < len(toks) and toks[rpos] else ""
        L = bool(left_ch) and left_ch in MR
        R = bool(right_ch) and right_ch in MR
        ln = len(tk)
        if ln == 1:
            flips = 1
        elif ln == 2:
            flips = 1
        elif ln == 3:
            flips = 2 if (L and R) else 1
        else:  # >=4
            flips = 2 if (L and R) else 1
        for _ in range(flips):
            mode = "m" if mode == "t" else "t"
    # 若最终仍在 math（末尾 $ 未闭合）→ 在最后一个非 MR/CJK 处截断为文本
    if mode == "m" and pieces:
        last = pieces[-1]
        if last[0] == "m":
            j = len(last[1])
            while j > 0 and not _is_mr(last[1][j - 1]):
                j -= 1
            if j < len(last[1]):
                pieces[-1] = ["t", last[1][j:]]
                if j > 0:
                    pieces.insert(len(pieces) - 1, ["m", last[1][:j]])
    return pieces

FW_PUNCT = set("，。？！；、：）】》“”‘’（【《〉》")

def cut_cjk_in_math(pieces):
    """math 岛里出现 CJK → 按 CJK 切块：纯数学块（结构成立的）保留为岛，其余降级为受保护文本。
    岛尾/岛头的全角标点先剥离为文本，不算 CJK 混杂（如 `0.1，`）。"""
    out = []
    demoted = []
    for kind, c in pieces:
        if kind == "t" or not c:
            out.append([kind, c]); continue
        lead = ""
        while c and c[0] in FW_PUNCT:
            lead += c[0]; c = c[1:]
        trail = ""
        while c and c[-1] in FW_PUNCT:
            trail = c[-1] + trail; c = c[:-1]
        if lead:
            out.append(["t", lead])
        if c:
            if not CJK.search(c):
                out.append(["m", c])
            else:
                pos = 0
                for m in CJK.finditer(c):
                    chunk = c[pos:m.start()]
                    _push_chunk(chunk, m.group(0), out, demoted)
                    pos = m.end()
                _push_chunk(c[pos:], "", out, demoted)
        if trail:
            out.append(["t", trail])
    merged = []
    for k, c in out:
        if merged and merged[-1][0] == k:
            merged[-1][1] = _mjoin(merged[-1][1], c) if k == "m" else merged[-1][1] + c
        else:
            merged.append([k, c])
    return merged, demoted

def _push_chunk(chunk, cjk_after, out, demoted):
    """混合岛切出的非 CJK 块：结构成立则成岛，否则原文降级（保留空白，由 gap 规则再处理）。"""
    s = chunk.strip()
    if not s:
        if chunk:
            out.append(["t", chunk + cjk_after])
        elif cjk_after:
            out.append(["t", cjk_after])
        return
    if _junk_math(s):
        out.append(["t", chunk + cjk_after])
        return
    lead = chunk[:chunk.index(s[0])]
    trail = chunk[len(lead) + len(s):]
    if lead:
        out.append(["t", lead])
    out.append(["m", s])
    if trail or cjk_after:
        out.append(["t", trail + cjk_after])

def _mjoin(a, b):
    """两段 math 拼接：运算符/括号边界免空格，其余补一个空格（防 `\sum`+`x` 粘连）。"""
    if not a:
        return b
    if not b:
        return a
    if a[-1] in "=+-*/^(,<>" or b[0] in ")]},;.!?":
        return a + b
    if a[-1] == " " or b[0] == " ":
        return a + b
    return a + " " + b

def absorb(pieces):
    """1) t 段按「数学字符+空白」与「非数学屏障(CJK/全角)」切细；
       2) 与 m 岛相连（含隔着纯数学片段）的内容运行级合并成一岛。
       运行级合并保证 `(`/`)` 这类 ASCII 标点不会拆到不同岛导致失衡。"""
    def flush(pl):
        out = []
        for k, c in pl:
            if out and out[-1][0] == k:
                out[-1][1] = _mjoin(out[-1][1], c) if k == "m" else out[-1][1] + c
            else:
                out.append([k, c])
        return out
    pieces = flush(pieces)
    frags = []
    for k, c in pieces:
        if k == "m":
            frags.append(["m", c])
            continue
        buf = ""
        for ch in c:
            if ch in MR or ch in " \t":
                buf += ch
            else:
                if buf:
                    frags.append(["f", buf]); buf = ""
                if frags and frags[-1][0] == "t":
                    frags[-1][1] += ch
                else:
                    frags.append(["t", ch])
        if buf:
            frags.append(["f", buf])
    out = []
    cur = None      # 正在积累 math 岛
    pend = None     # 岛前纯数学片段（后面接上 m 才成岛，否则还原文本）
    for k, c in frags:
        if k == "m":
            seg = (_mjoin(pend, c) if pend is not None else c)
            pend = None
            cur = _mjoin(cur, seg) if cur is not None else seg
        elif k == "f":
            if cur is not None:
                cur = _mjoin(cur, c)
            elif pend is not None:
                pend = pend + c
            else:
                pend = c
        else:  # 屏障文本
            if pend is not None:
                out.append(["t", pend]); pend = None
            if cur is not None:
                out.append(["m", cur]); cur = None
            out.append(["t", c])
    if pend is not None:
        out.append(["t", pend])
    if cur is not None:
        out.append(["m", cur])
    return flush(out)

# ---------------- 阶段 4: Unicode→LaTeX 转换 ----------------
def conv_math(s):
    # 结合变音符：z̄ → \bar{z}（共轭复数常见）；预组字符 Ā/ā 同理
    s = s.replace("Ā", "A\u0304").replace("ā", "a\u0304").replace("Ī", "I\u0304").replace("ī", "i\u0304")
    s = re.sub(r"([A-Za-z])\u0304", r"\\bar{\1}", s)
    s = re.sub(r"([A-Za-z])\u0302", r"\\hat{\1}", s)
    s = re.sub(r"([A-Za-z])\u0307", r"\\dot{\1}", s)
    out, i, n = [], 0, len(s)
    while i < n:
        c = s[i]
        if c in SUP:
            run = ""
            while i < n and s[i] in SUP:
                run += SUP[s[i]]; i += 1
            out.append("^{" + run + "}"); continue
        if c in SUB:
            run = ""
            while i < n and s[i] in SUB:
                run += SUB[s[i]]; i += 1
            out.append("_{" + run + "}"); continue
        if c == "√":
            i += 1
            if i < n and s[i] == "(":
                depth, arg = 1, ""
                i += 1
                while i < n and depth > 0:
                    if s[i] == "(": depth += 1
                    elif s[i] == ")":
                        depth -= 1
                        if depth == 0: i += 1; break
                    arg += s[i]; i += 1
                out.append("\\sqrt{" + arg + "}"); continue
            arg = ""
            while i < n and (s[i].isalnum() or s[i] in SUB or s[i] in SUP or s[i] == "−"):
                arg += s[i]; i += 1
            out.append("\\sqrt{" + conv_inline(arg) + "}"); continue
        if c == "°":
            out.append("^\\circ "); i += 1; continue
        if c in SYM:
            out.append(SYM[c]); i += 1; continue
        out.append(c); i += 1
    s = "".join(out)
    s = cleanup_math(s)
    return s

def conv_inline(s):
    # 递归处理 sqrt 参数里的下标/上标/符号（轻量）
    return conv_math(s)

def _split_glued_cmds(s):
    """`\\sum`+`x` 粘连成未知命令 `\\sumx` 的保险丝：按最长前缀拆回已知命令。"""
    def rep(m):
        tok = m.group(1)
        if tok in MT_CMDS:
            return "\\" + tok
        for L in range(len(tok) - 1, 0, -1):
            if tok[:L] in MT_CMDS:
                return "\\" + tok[:L] + " " + tok[L:]
        return m.group(0)
    return re.sub(r"\\([A-Za-z]+)", rep, s)

def cleanup_math(s):
    s = _split_glued_cmds(s)
    # ASCII 关系方言：>= <= != → \ge \le \ne（MicroTeX 不识别 >=）
    s = re.sub(r"(?<![<>=!\\])>=", lambda m: " \\ge ", s)
    s = re.sub(r"(?<![<>=!\\])<=", lambda m: " \\le ", s)
    s = re.sub(r"(?<![<>=!\\])!=", lambda m: " \\ne ", s)
    # 条件概率竖线：字母/数字之间的裸 | → \mid（P(A|B) → P(A\mid B)），边缘悬挂的 | 留给 junk 判定
    s = re.sub(r"(?<=[A-Za-z0-9})\]])\|(?=[A-Za-z0-9({\[])", lambda m: " \\mid ", s)
    # 裸函数名 → \sin 等：整词、或后接字母（sinx → \sin x）。长名在前保证 sinh 不被拆。
    for f in FUNCS:
        for pat in (r"(?<![A-Za-z\\])" + f + r"(?![A-Za-z])",
                    r"(?<![A-Za-z\\])" + f + r"(?=[A-Za-z])"):
            cp = re.compile(pat)
            while True:
                m = cp.search(s)
                if not m:
                    break
                s = s[:m.start()] + "\\" + f + " " + s[m.end():]
    # `^2`/`_n` 未加花括号 → 补（仅单 token）
    s = re.sub(r"\^([0-9A-Za-z])", r"^{\1}", s)
    s = re.sub(r"_([0-9A-Za-z])", r"_{\1}", s)
    # 双花括号折叠 `^{^{a}}`
    s = re.sub(r"\^\{\{([^{}]*)\}\}", r"^{\1}", s)
    s = re.sub(r"_\{\{([^{}]*)\}\}", r"_{\1}", s)
    # 命令后多余空格
    s = re.sub(r"[ \t]{2,}", " ", s)
    s = re.sub(r"(\{)[ \t]+", r"\1", s)
    s = re.sub(r"[ \t]+\}", "}", s)
    return s.strip()

# ---------------- 阶段 5: gap 判定（是否值得包成 $$..$$） ----------------
def has_math_char(s):
    for i, c in enumerate(s):
        if c == "·":
            pw = i == 0 or s[i-1] == " "
            nw = i == len(s)-1 or s[i+1] == " "
            if pw or nw:
                continue
        if c in MATH_FLAG:
            return True
    return False

STRONG_OPS = set("=<>≤≥≠≈√∈∉⊆⊇∪∩∠°±×÷⇒⇔→")

def gap_convert(gap):
    """把非数学的 gap 原样返回；是数学式的转成 $$..$$"""
    if gap == "":
        return gap
    core = rt_trim(gap)
    if core == "":
        return gap
    idx = gap.find(core)
    lead = gap[:idx] if idx >= 0 else ""
    trail = gap[idx + len(core):]
    if "\uE000" in core:
        return gap
    # 覆盖表命中 → 运行时已渲染为公式图，显示没有错，不动（A10 冻结策略）
    if core in COVERED:
        return gap
    strong = has_math_char(core)
    expry = bool(re.search(r"[A-Za-z0-9]", core)) and (
        any(o in core for o in STRONG_OPS)
        or (("(" in core and ")" in core) or ("[" in core and "]" in core) or ("{" in core and "}" in core))
        or core.count("|") >= 2
        or bool(re.search(r"\\[A-Za-z]+", core)))
    if not (strong or expry):
        return gap
    # 纯英文单词/编号不包
    if not strong and re.fullmatch(r"[A-Za-z ,\.]+", core):
        return gap
    body = conv_math(core)
    lead2, core2, trail2 = _peel_ops(body)
    if core2.strip() == "" or _junk_math(core2):
        return gap
    return lead + lead2 + "$$" + core2 + "$$" + trail2 + trail

# ---------------- 主修复 ----------------
def _junk_math(c):
    """结构上不成立的 math 碎片不成图。"""
    t = c.strip()
    if len(t) < 2:
        return True
    if t.count("{") != t.count("}"):
        return True
    # 圆/方括号在区间记号里可互配 ((a,b] / [a,b))，只查总数
    if t.count("(") + t.count("[") != t.count(")") + t.count("]"):
        return True
    if not re.search(r"[A-Za-z0-9\\]", t):
        return True
    if t.count("|") % 2 == 1:
        return True
    return False

def _peel_ops(c):
    """把悬挂在公式两端的关系符/标点放回正文：`=3/5` → `=` + `3/5`。"""
    lead = ""
    while c and c[0] in "=;:":
        lead += c[0]; c = c[1:]
    trail = ""
    while c and c[-1] in "=;:,.":
        trail = c[-1] + trail; c = c[:-1]
    return lead, c, trail

def repair_string(s, log):
    if s == "" or ("$" not in s and not has_math_char(s)):
        return s
    s = fix_ctrl(s, log)
    s = fix_artifacts(s)
    s = collapse_bs(s)
    merged, demoted = cut_cjk_in_math(rebuild_dollars(s))
    pieces = absorb(merged)
    res = ""
    for kind, c in pieces:
        if kind == "m":
            if c.strip() == "":
                res += c
                continue
            c2 = conv_math(c)
            if _junk_math(c2):
                res += c          # 碎片原样放回，交给后续 gap 规则
                continue
            lead, core, trail = _peel_ops(c2)
            if core.strip() == "" or _junk_math(core):
                res += c
                continue
            res += lead + "$$" + core + "$$" + trail
        else:
            res += c
    # 文本区里未覆盖的 Unicode 数学片段 → 转 $$..$$
    out, last = "", 0
    for m in re.finditer(r"\$\$[^$]+\$\$", res):
        out += split_gaps_and_convert(res[last:m.start()]) + m.group(0)
        last = m.end()
    out += split_gaps_and_convert(res[last:])
    # 合并仅以空白/无分隔相邻的两段（$$A$$ $$B$$ / $$A$$$$B$$ → $$A B$$）
    prev = None
    while prev != out:
        prev = out
        out = re.sub(r"\$\$([^$]+)\$\$ ?\$\$([^$]+)\$\$", r"$$\1 \2$$", out)
    out = re.sub(r"\$\$ +| +\$\$", "$$", out)
    # 还原混合岛（含中文的公式区段按纯文本展示）
    for i, txt in enumerate(demoted):
        out = out.replace("\uE000%d\uE001" % i, txt)
    return out

def split_gaps_and_convert(text):
    # 对非 $$ 区域的文本，按 CJK 切 gap，逐个 gap_convert
    out, last = "", 0
    for m in CJK.finditer(text):
        out += gap_convert(text[last:m.start()]) + text[m.start():m.end()]
        last = m.end()
    out += gap_convert(text[last:])
    return out

# ---------------- JSON 文本级替换（带路径状态机，只修显示字段，跳过 scene 子树） ----------------
DISPLAY_KEYS = {"q", "ask", "opts", "hint", "explain", "success", "goal", "tip", "steps",
                "name", "title", "subtitle", "technique", "retry", "summary", "desc", "caption", "speak"}
STR_TOKEN = re.compile(r'"(?:[^"\\]|\\.)*"')

def iter_values(raw):
    """yield (start, end, value, path)。path 用 键名/`键[e]` 组装。"""
    stack = []
    i, n = 0, len(raw)
    def frame_seg(fr):
        if fr["t"] == "obj":
            return (fr.get("key") or "?")
        return (fr.get("key") or "?") + "[e]"
    while i < n:
        ch = raw[i]
        if ch in " \t\r\n":
            i += 1
            continue
        if ch == '"':
            m = STR_TOKEN.match(raw, i)
            if not m:
                i += 1
                continue
            val = json.loads(m.group(0))
            j = m.end()
            while j < n and raw[j] in " \t\r\n":
                j += 1
            nxt = raw[j] if j < n else ""
            if nxt == ":":
                if stack and stack[-1]["t"] == "obj":
                    stack[-1]["key"] = val
                i = j
            else:
                yield m.start(), m.end(), val, ".".join(frame_seg(f) for f in stack) or "?"
                i = m.end()
            continue
        if ch == "{":
            stack.append({"t": "obj", "key": None})
            i += 1
            continue
        if ch == "[":
            k = stack[-1].get("key") if stack and stack[-1]["t"] == "obj" else None
            stack.append({"t": "arr", "key": k})
            i += 1
            continue
        if ch in "}]":
            if stack:
                stack.pop()
            i += 1
            continue
        if ch in ":,":
            i += 1
            continue
        j = i
        while j < n and raw[j] not in ',}] \t\r\n':
            j += 1
        i = j
    return

def path_is_scene(path):
    for seg in path.split("."):
        k = seg.replace("[e]", "")
        if k == "scene":
            return True
    return False

def load_covered():
    p = os.path.join(ROOT, "data", "inline_math.json")
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

COVERED = load_covered()

def process_file(path, apply=False):
    with open(path, encoding="utf-8", newline="") as f:
        raw = f.read()
    changes = []
    out_parts, pos = [], 0
    for start, end, val, p in iter_values(raw):
        segs = p.split(".")
        leaf = segs[-1].replace("[e]", "")
        if path_is_scene(p) or leaf not in DISPLAY_KEYS:
            continue
        log = []
        fixed = repair_string(val, log)
        for e in log:
            changes.append(("LOG", p, e))
        if fixed != val:
            tok_new = json.dumps(fixed, ensure_ascii=False)
            changes.append((p, val, fixed))
            if apply:
                out_parts.append(raw[pos:start])
                out_parts.append(tok_new)
                pos = end
    newraw = raw if not apply else ("".join(out_parts) + raw[pos:])
    n_edit = sum(1 for c in changes if c[0] != "LOG")
    if n_edit and apply:
        try:
            json.loads(newraw)
        except Exception as e:
            print("!! JSON 解析失败(不写回):", path, e)
            return changes, False
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(newraw)
    return changes, True

def main():
    args = [a for a in sys.argv[1:] if a != "--apply"]
    apply = "--apply" in sys.argv[1:]
    files = args if args else sorted(f for f in os.listdir(os.path.join(ROOT, "data")) if f.endswith(".json"))
    # inline_math.json 是覆盖表本体；param_master*/*_param_auto 为 B1 合并后的离线遗产，运行时不加载
    files = [f for f in files if f != "inline_math.json"
             and not f.startswith("param_master") and not f.endswith("_param_auto.json")]
    total = 0
    report = []
    for f in files:
        p = os.path.join(ROOT, "data", f)
        changes, ok = process_file(p, apply)
        edits = [c for c in changes if c[0] != "LOG"]
        logs = [c for c in changes if c[0] == "LOG"]
        if not edits and not logs:
            continue
        total += len(edits)
        report.append("=" * 24 + " %s  (%d 处%s)" % (f, len(edits), "" if apply else " [dry-run]"))
        for _, _, e in logs:
            report.append("  [LOG] " + e)
        for path, before, after in edits:
            report.append("  [%s]" % path)
            report.append("  - " + before)
            report.append("  + " + after)
    with open(os.path.join(ROOT, "tools", "formula_repair_report.txt"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(report))
    print("共 %d 处字符串修改%s；报告 tools/formula_repair_report.txt" % (total, "（已写回）" if apply else "（dry-run 未写回）"))

if __name__ == "__main__":
    main()
