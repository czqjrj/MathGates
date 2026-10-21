class_name SpeechRules
## 朗读/口播文案规则(B13 第一步,从 InlineMath 迁出并扩展;A4 规则层)。
## 职责:把「显示文本」($$LaTeX$$ / {f:名称} / Unicode 数学符号)统一转成可朗读中文,
## 供 StageBase/LabStage/Lab3DStage 等所有 tts 出口共用——**一条路径**,
## 禁止一处 strip、一处不 strip(B13 的事故形态)。
## 纯函数:命名公式映射(FORMULA_SPEECH/FORMULA_LATEX)留在 InlineMath,由调用方传入。

## LaTeX 命令口播表(转换器认识的命令;校验器按 KNOWN_COMMANDS 统计「口播盲点」)。
const CMD := {
	"\\geq": "大于等于", "\\ge": "大于等于", "\\leq": "小于等于", "\\le": "小于等于",
	"\\neq": "不等于", "\\ne": "不等于", "\\approx": "约等于",
	"\\to": "到", "\\rightarrow": "到", "\\Rightarrow": "推出", "\\Leftrightarrow": "等价于",
	"\\infty": "无穷",
	"\\cup": "并", "\\cap": "交", "\\cdot": "点乘", "\\times": "乘以",
	"\\div": "除以", "\\pm": "正负", "\\in": "属于", "\\sum": "求和",
	"\\forall": "对任意", "\\exists": "存在", "\\angle": "角",
	"\\cdots": "点点点", "\\triangle": "三角形", "\\varnothing": "空集", "\\circ": "度",
	"\\alpha": "阿尔法", "\\beta": "贝塔", "\\gamma": "伽马", "\\theta": "西塔",
	"\\pi": "派", "\\Delta": "德尔塔", "\\lambda": "兰姆达", "\\chi": "卡方",
	"\\left": "", "\\right": "",
	">": "大于", "<": "小于",
}

## \mathbb{字母} → 集合名(高中高频)。
const BB := { "R": "实数集", "Z": "整数集", "N": "自然数集", "Q": "有理数集", "C": "复数集" }

## 转换器认识的 LaTeX 命令名(不含反斜杠);校验器用它统计盲点命令。
const KNOWN_COMMANDS := [
	"geq", "ge", "leq", "le", "neq", "ne", "approx", "to", "rightarrow", "Rightarrow",
	"Leftrightarrow", "infty", "cup", "cap", "cdot", "times", "div", "pm", "in", "sum",
	"forall", "exists", "angle", "alpha", "beta", "gamma", "theta", "pi", "Delta",
	"lambda", "chi", "left", "right", "frac", "dfrac", "sqrt", "vec", "bar", "hat",
	"mathbb", "lg", "log", "ln", "sin", "cos", "tan", "max", "min", "lim",
	"circ", "cdots", "triangle", "varnothing", "overline",
]

## Unicode 数学符号 → 口播(B 类旧数据与正文残留;A10 起新内容禁用,此表兜底)。
const UNICODE := {
	"⁰": "的0次方", "¹": "的1次方", "²": "的平方", "³": "的立方", "⁴": "的4次方",
	"⁵": "的5次方", "⁶": "的6次方", "⁷": "的7次方", "⁸": "的8次方", "⁹": "的9次方",
	"₀": "下标0", "₁": "下标1", "₂": "下标2", "₃": "下标3", "₄": "下标4",
	"₅": "下标5", "₆": "下标6", "₇": "下标7", "₈": "下标8", "₉": "下标9",
	"ₐ": "下标a", "ₑ": "下标e", "ₕ": "下标h", "ᵢ": "下标i", "ⱼ": "下标j",
	"ₖ": "下标k", "ₗ": "下标l", "ₘ": "下标m", "ₙ": "下标n", "ₒ": "下标o",
	"ₚ": "下标p", "ₛ": "下标s", "ₜ": "下标t", "ᵤ": "下标u", "ᵥ": "下标v", "ₓ": "下标x",
	"≤": "小于等于", "≥": "大于等于", "≠": "不等于", "≈": "约等于",
	"×": "乘以", "÷": "除以", "±": "正负", "·": "乘",
	"√": "根号", "∞": "无穷", "∈": "属于", "∉": "不属于",
	"⊆": "包含于", "⊇": "包含", "∪": "并", "∩": "交",
	"→": "推出", "⇒": "推出", "⇔": "等价于", "∀": "对任意", "∃": "存在",
	"∠": "角", "°": "度", "π": "派", "∅": "空集",
	"α": "阿尔法", "β": "贝塔", "γ": "伽马", "θ": "西塔", "λ": "兰姆达", "μ": "缪", "Δ": "德尔塔",
}

## 统一入口：$${..}$$ / {f:名称} / Unicode 数学符号 → 可朗读中文。
static func strip_formulas(text: String, formula_speech: Dictionary, formula_latex: Dictionary) -> String:
	text = _dollar_speech(text)
	text = _named_speech(text, formula_speech, formula_latex)
	return unicode_speech(text)

## Unicode 数学符号 → 口播文本(不含 $$ / {f:} 处理)。
static func unicode_speech(text: String) -> String:
	for k in UNICODE:
		text = text.replace(k, str(UNICODE[k]))
	return text

## {f:名称} → 口播文案：优先命名表；否则命名 LaTeX 走通用转换；再否则「公式」。
static func formula_speech(name: String, formula_speech: Dictionary, formula_latex: Dictionary) -> String:
	if formula_speech.has(name):
		return str(formula_speech[name])
	if formula_latex.has(name):
		return latex_to_speech(str(formula_latex[name]))
	return "公式"

## 文本里出现但转换器不认识的 LaTeX 命令(校验器「口播盲点」看板用)。
static func unmapped_commands(text: String) -> Array:
	var re := RegEx.new()
	re.compile("\\\\([a-zA-Z]+)")
	var out: Array = []
	for m in re.search_all(text):
		var c := m.get_string(1)
		if not KNOWN_COMMANDS.has(c) and not out.has(c):
			out.append(c)
	return out

# ---------------------------------------------------------------- 内部

static func _dollar_speech(text: String) -> String:
	if text.find("$$") < 0:
		return text
	var re := RegEx.new()
	re.compile("\\$\\$([^$]+)\\$\\$")
	var out := ""
	var last := 0
	for m in re.search_all(text):
		out += text.substr(last, m.get_start() - last)
		out += latex_to_speech(m.get_string(1))
		last = m.get_end()
	out += text.substr(last)
	return out

static func _named_speech(text: String, formula_speech: Dictionary, formula_latex: Dictionary) -> String:
	if text.find("{f:") < 0:
		return text
	var re := RegEx.new()
	re.compile("\\{f:([A-Za-z0-9_]+)\\}")
	var out := ""
	var last := 0
	for m in re.search_all(text):
		out += text.substr(last, m.get_start() - last)
		out += formula_speech(m.get_string(1), formula_speech, formula_latex)
		last = m.get_end()
	out += text.substr(last)
	return out

## 通用 LaTeX → 可朗读中文(分式/根号/幂/下标/向量记号/绝对值/常见命令)。
static func latex_to_speech(tex: String) -> String:
	var t := tex
	# 角度记号(须在幂替换前:90^{\circ} 不能被念成「的circ次方」)
	t = t.replace("^{\\circ}", "度").replace("^\\circ", "度")
	# 分式(含 \dfrac);嵌套由循环展开
	var frac := RegEx.new()
	frac.compile("\\\\d?frac\\{([^{}]+)\\}\\{([^{}]+)\\}")
	for _i in 3:
		t = frac.sub(t, "$2分之$1", true)
	var sq := RegEx.new()
	sq.compile("\\\\sqrt\\{([^{}]+)\\}")
	t = sq.sub(t, "根号$1", true)
	# 上标幂
	var pw := RegEx.new()
	pw.compile("\\^\\{([^{}]+)\\}")
	t = pw.sub(t, "的$1次方", true)
	# 下标(B13 修复:a_{n} 曾被剥成 "an",读作「安」)
	var sub1 := RegEx.new()
	sub1.compile("_\\{([^{}]+)\\}")
	t = sub1.sub(t, "下标$1", true)
	var sub2 := RegEx.new()
	sub2.compile("_(.)")
	t = sub2.sub(t, "下标$1", true)
	# 向量/均值横线/估计记号
	var vec := RegEx.new()
	vec.compile("\\\\vec\\{([^{}]+)\\}")
	t = vec.sub(t, "$1向量", true)
	var bar := RegEx.new()
	bar.compile("\\\\bar\\{([^{}]+)\\}")
	t = bar.sub(t, "$1拔", true)
	var hat := RegEx.new()
	hat.compile("\\\\hat\\{([^{}]+)\\}")
	t = hat.sub(t, "$1帽", true)
	# 复数共轭(当前题库 \overline 均为共轭;若出现几何用法再调)
	var ovl := RegEx.new()
	ovl.compile("\\\\overline\\{([^{}]+)\\}")
	t = ovl.sub(t, "$1的共轭", true)
	# 数集
	var bb := RegEx.new()
	bb.compile("\\\\mathbb\\{([^{}]+)\\}")
	var bb_out := ""
	var bb_last := 0
	for m in bb.search_all(t):
		bb_out += t.substr(bb_last, m.get_start() - bb_last)
		var letters := m.get_string(1)
		var names := ""
		for i in letters.length():
			var ch := letters[i]
			names += str(BB.get(ch, ch + "集合"))
		bb_out += names
		bb_last = m.get_end()
	t = bb_out + t.substr(bb_last)
	# 绝对值
	var absre := RegEx.new()
	absre.compile("\\|([^|]+)\\|")
	t = absre.sub(t, "$1的绝对值", true)
	# 常见命令与符号
	for k in CMD:
		t = t.replace(k, str(CMD[k]))
	t = t.replace("^2", "的平方").replace("^3", "的立方").replace("^", "的")
	t = t.replace("的2次方", "的平方").replace("的3次方", "的立方")   # x^{2} 也念「平方」
	t = t.replace("=-", "等于负").replace("(-", "负括号").replace("(", "").replace(")", "")
	t = t.replace("=", "等于").replace("+", "加").replace("-", "减")
	t = t.replace("{", "").replace("}", "").replace("\\", "")
	return t
