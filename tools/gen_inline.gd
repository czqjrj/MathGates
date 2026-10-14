extends Node
## 扩展 data/inline_math.json：为「含正文字体缺字形」或「明确是数学式子」的片段补充 latex 字段，
## 让它们经 MicroTeX 渲染成 LaTeX（而不是以原文 Unicode 显示导致缺字/错乱）。
## 幂等：已存在的键不动；新条目追加在文件末尾（保持原有平铺格式）。
## 用法： godot --path . res://tools/gen_inline.tscn

const OUT_PATH := "res://data/inline_math.json"
const REPORT := "res://build/gen_inline_report.txt"

## 含这些字符即视为「数学式子」（必映射）。
const STRONG := "=<>≤≥≠≈√×÷±∞→←⇒⇔∈∉⊆⊇⊂⊃∪∩∀∃∠°∑∫²³⁴⁵⁶⁷⁸⁹⁰¹−αβγδεθλμνπρσφϕωχψτκΔΩΣΓΛΦΠΘΨ"
const SYM := {
	"−": "-", "≤": "\\le ", "≥": "\\ge ", "≠": "\\ne ", "≈": "\\approx ", "≡": "\\equiv ",
	"±": "\\pm ", "×": "\\times ", "÷": "\\div ", "·": "\\cdot ", "∞": "\\infty ",
	"→": "\\to ", "←": "\\leftarrow ", "⇒": "\\Rightarrow ", "⇔": "\\Leftrightarrow ",
	"∈": "\\in ", "∉": "\\notin ", "⊆": "\\subseteq ", "⊇": "\\supseteq ",
	"⊂": "\\subset ", "⊃": "\\supset ", "∪": "\\cup ", "∩": "\\cap ", "∅": "\\varnothing ",
	"∀": "\\forall ", "∃": "\\exists ", "∠": "\\angle ", "≅": "\\cong ",
	"∥": "\\parallel ", "⊥": "\\perp ", "⊙": "\\odot ", "△": "\\triangle ", "□": "\\square ",
	"°": "^{\\circ}", "′": "'", "″": "''", "∑": "\\sum ", "∫": "\\int ", "∂": "\\partial ",
	"∴": "\\therefore ", "∵": "\\because ",
	"α": "\\alpha ", "β": "\\beta ", "γ": "\\gamma ", "δ": "\\delta ", "ε": "\\varepsilon ",
	"θ": "\\theta ", "λ": "\\lambda ", "μ": "\\mu ", "ν": "\\nu ", "π": "\\pi ",
	"ρ": "\\rho ", "σ": "\\sigma ", "φ": "\\varphi ", "ϕ": "\\phi ", "ω": "\\omega ",
	"χ": "\\chi ", "ψ": "\\psi ", "τ": "\\tau ", "κ": "\\kappa ",
	"Δ": "\\Delta ", "Ω": "\\Omega ", "Σ": "\\Sigma ", "Γ": "\\Gamma ", "Λ": "\\Lambda ",
	"Φ": "\\Phi ", "Π": "\\Pi ", "Θ": "\\Theta ", "Ψ": "\\Psi ",
	"…": "\\dots ", "↔": "\\leftrightarrow ", "⇄": "\\rightleftarrows ",
	"∁": "\\complement ", "⟨": "\\langle ", "⟩": "\\rangle ",
	"ŷ": "\\hat{y}", "â": "\\hat{a}", "Ā": "\\bar{A}", "ȳ": "\\bar{y}",
	"ī": "\\bar{i}", "ū": "\\bar{u}", "ō": "\\bar{o}", "ē": "\\bar{e}",
	"✓": "\\checkmark ",
}
const FRAC := {"½": "\\frac{1}{2}", "⅓": "\\frac{1}{3}", "⅔": "\\frac{2}{3}", "¼": "\\frac{1}{4}",
	"¾": "\\frac{3}{4}", "⅕": "\\frac{1}{5}", "⅖": "\\frac{2}{5}", "⅗": "\\frac{3}{5}", "⅘": "\\frac{4}{5}",
	"⅙": "\\frac{1}{6}", "⅚": "\\frac{5}{6}", "⅐": "\\frac{1}{7}", "⅛": "\\frac{1}{8}", "⅜": "\\frac{3}{8}",
	"⅝": "\\frac{5}{8}", "⅞": "\\frac{7}{8}", "⅑": "\\frac{1}{9}"}
## 装饰性字符：转 LaTeX 时直接丢弃（键仍保留原样）
const DROP := "“”„‟–—"
## 带圈数字 → (n)
const CIRC := {"①": "(1)", "②": "(2)", "③": "(3)", "④": "(4)", "⑤": "(5)", "⑥": "(6)", "⑦": "(7)",
	"⑧": "(8)", "⑨": "(9)", "⑩": "(10)", "⑪": "(11)", "⑫": "(12)", "⑬": "(13)", "⑭": "(14)",
	"⑮": "(15)", "⑯": "(16)", "⑰": "(17)", "⑱": "(18)", "⑲": "(19)", "⑳": "(20)"}
const SUP := {"⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4", "⁵": "5", "⁶": "6", "⁷": "7", "⁸": "8", "⁹": "9", "⁺": "+", "⁻": "-", "ⁿ": "n",
	"ˣ": "x", "ʸ": "y", "ᵃ": "a", "ᵇ": "b", "ᶜ": "c", "ᵈ": "d", "ᵉ": "e", "ᶠ": "f", "ᵍ": "g", "ʰ": "h",
	"ⁱ": "i", "ʲ": "j", "ᵏ": "k", "ˡ": "l", "ᵐ": "m", "ᵒ": "o", "ᵖ": "p", "ʳ": "r", "ˢ": "s", "ᵗ": "t",
	"ᵘ": "u", "ᵛ": "v", "ʷ": "w", "ᶻ": "z"}
const SUB := {"₀": "0", "₁": "1", "₂": "2", "₃": "3", "₄": "4", "₅": "5", "₆": "6", "₇": "7", "₈": "8", "₉": "9", "₊": "+", "₋": "-", "ₐ": "a", "ₑ": "e", "ₒ": "o", "ₓ": "x", "ₕ": "h", "ₖ": "k", "ₗ": "l", "ₘ": "m", "ₙ": "n", "ₚ": "p", "ₛ": "s", "ₜ": "t",
	"ᵢ": "i", "ᵣ": "r", "ᵤ": "u", "ᵥ": "v"}

var _fn_re: RegEx
var _fold_res := {}

func _ready() -> void:
	var font: Font = UI.font()
	# 1) 收集全部非 CJK 片段
	var cjk := RegEx.new()
	cjk.compile("[\\x{2e80}-\\x{303f}\\x{31c0}-\\x{9fff}\\x{f900}-\\x{faff}\\x{fe30}-\\x{fe4f}\\x{ff00}-\\x{ffef}]+")
	var cores := {}
	var dir := DirAccess.open("res://data")
	var files: Array[String] = []
	for f in dir.get_files():
		if f.ends_with(".json") and f != "inline_math.json":
			files.append(f)
	files.sort()
	for f in files:
		var raw := FileAccess.get_file_as_string("res://data/" + f)
		if raw == "":
			continue
		var data = JSON.parse_string(raw)
		if data == null:
			continue
		_walk(data, cjk, cores)

	# 2) 现有映射
	var existing = JSON.parse_string(FileAccess.get_file_as_string(OUT_PATH))
	if typeof(existing) != TYPE_DICTIONARY:
		push_error("inline_math.json 解析失败")
		get_tree().quit(1)
		return

	# 3) 渲染器
	InlineMath._mt_ready()
	var mt = Engine.get_singleton("MathTeX")

	# 4) 生成
	var keys := cores.keys()
	keys.sort()
	var additions: Array = []
	var skipped: Array[String] = []
	for core in keys:
		var s := str(core)
		if s == "" or existing.has(s):
			continue
		if not _needs_map(s, font):
			continue
		var latex := _to_latex(s)
		if latex == "" or _has_unconverted(s):
			skipped.append(s + "  =>  " + latex)
			continue
		if mt != null:
			var img: Image = mt.render(latex, 26.0, InlineMath.MT_COLOR)
			if img == null:
				skipped.append("[render-null] " + s + "  =>  " + latex)
				continue
		additions.append([s, latex])

	# 5) 写回（追加，保持原平铺格式）
	if not additions.is_empty():
		var raw := FileAccess.get_file_as_string(OUT_PATH)
		var body := raw.substr(0, raw.rfind("}")).strip_edges(false, true)
		if body.ends_with(","):
			body = body.substr(0, body.length() - 1)
		var add := ""
		for i in additions.size():
			add += ",\n" + _jstr(str(additions[i][0])) + ": {\n\"latex\": " + _jstr(str(additions[i][1])) + "\n}"
		var fw := FileAccess.open(OUT_PATH, FileAccess.WRITE)
		fw.store_string(body + add + "\n}\n")
		fw.close()

	# 6) 报告
	var rep := "新增 %d 条；跳过 %d 条\n\n跳过明细：\n" % [additions.size(), skipped.size()]
	rep += "\n".join(skipped)
	DirAccess.make_dir_recursive_absolute("res://build")
	var rf := FileAccess.open(REPORT, FileAccess.WRITE)
	rf.store_string(rep)
	rf.close()
	print("GEN DONE: 新增 %d 条，跳过 %d 条，共扫描片段 %d" % [additions.size(), skipped.size(), keys.size()])
	get_tree().quit()

# ---------------------------------------------------------------- 判定
func _needs_map(s: String, font: Font) -> bool:
	for i in s.length():
		var c := s[i]
		if not font.has_char(c.unicode_at(0)):
			return true
	for i in s.length():
		if STRONG.find(s[i]) >= 0:
			return true
	return false

func _has_unconverted(s: String) -> bool:
	# 是否残留「映射无法消化」的非 ASCII 字符（MicroTeX 大概率不认识的字符）
	for i in s.length():
		var c := s[i]
		if c.unicode_at(0) > 127 and not _consumed(c):
			return true
	return false

func _consumed(c: String) -> bool:
	if SYM.has(c) or SUP.has(c) or SUB.has(c) or FRAC.has(c) or CIRC.has(c) or c == "√" or DROP.find(c) >= 0:
		return true
	var code := c.unicode_at(0)
	return code >= 0x0300 and code <= 0x036f # 组合附加符号

# ---------------------------------------------------------------- Unicode → LaTeX
func _to_latex(src: String) -> String:
	var s := _fold_combining(_replace_funcs(src))
	var out := ""
	var i := 0
	var n := s.length()
	while i < n:
		var c := s[i]
		if c == "√":
			var j := i + 1
			if j < n and (s[j] == "(" or s[j] == "["):
				var op := s[j]
				var cl := ")" if op == "(" else "]"
				var depth := 0
				var k := j
				while k < n:
					if s[k] == op:
						depth += 1
					elif s[k] == cl:
						depth -= 1
						if depth == 0:
							break
					k += 1
				out += "\\sqrt{" + _to_latex(s.substr(j + 1, k - (j + 1))) + "}"
				i = k + 1
			elif j < n:
				out += "\\sqrt{" + _one(s[j]) + "}"
				i = j + 1
			else:
				out += "\\sqrt{}"
				i += 1
		elif SUP.has(c):
			out += "^{" + str(SUP[c]) + "}"
			i += 1
		elif SUB.has(c):
			out += "_{" + str(SUB[c]) + "}"
			i += 1
		elif FRAC.has(c):
			out += str(FRAC[c])
			i += 1
		elif CIRC.has(c):
			out += str(CIRC[c])
			i += 1
		elif DROP.find(c) >= 0:
			i += 1
		elif c == "%":
			out += "\\%"
			i += 1
		elif c == "&":
			out += "\\&"
			i += 1
		else:
			out += _one(c)
			i += 1
	return out

func _one(c: String) -> String:
	if SYM.has(c):
		return str(SYM[c])
	return c

func _replace_funcs(s: String) -> String:
	if _fn_re == null:
		_fn_re = RegEx.new()
		_fn_re.compile("(?<![A-Za-z])(arcsin|arccos|arctan|sin|cos|tan|cot|sec|csc|log|ln|lg|max|min)(?![A-Za-z])")
	return _fn_re.sub(s, "\\\\$1 ", true)

# 把「基字母 + 组合附加符号」折叠成 \bar{x} / \hat{x} 等
func _fold_combining(s: String) -> String:
	if _fold_res.is_empty():
		var marks := {"\u0304": "bar", "\u0302": "hat", "\u0303": "tilde", "\u0305": "overline", "\u0307": "dot", "\u0308": "ddot"}
		for m in marks.keys():
			var re := RegEx.new()
			re.compile("([A-Za-z])" + str(m))
			_fold_res[m] = [re, str(marks[m])]
	var out := s
	for m in _fold_res.keys():
		var pair: Array = _fold_res[m]
		out = (pair[0] as RegEx).sub(out, "\\\\" + str(pair[1]) + "{$1}", true)
	return out

# ---------------------------------------------------------------- JSON 字符串（保留原始 UTF-8）
func _jstr(s: String) -> String:
	var out := "\""
	for i in s.length():
		var c := s[i]
		var code := c.unicode_at(0)
		if c == "\"":
			out += "\\\""
		elif c == "\\":
			out += "\\\\"
		elif code < 0x20:
			out += "\\u%04x" % code
		else:
			out += c
	out += "\""
	return out

# ---------------------------------------------------------------- 遍历
func _walk(v: Variant, cjk: RegEx, cores: Dictionary) -> void:
	match typeof(v):
		TYPE_DICTIONARY:
			for k in (v as Dictionary).keys():
				if k is String:
					_check(str(k), cjk, cores)
				_walk((v as Dictionary)[k], cjk, cores)
		TYPE_ARRAY:
			for e in (v as Array):
				_walk(e, cjk, cores)
		TYPE_STRING:
			_check(str(v), cjk, cores)

func _check(t: String, cjk: RegEx, cores: Dictionary) -> void:
	if t == "":
		return
	var last := 0
	for m in cjk.search_all(t):
		_core(t.substr(last, m.get_start() - last), cores)
		last = m.get_end()
	_core(t.substr(last), cores)

func _core(gap: String, cores: Dictionary) -> void:
	if gap.strip_edges() == "":
		return
	var core := InlineMath._inline_trim(gap)
	if core != "":
		cores[core] = true
