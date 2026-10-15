extends SceneTree
## 诊断：扫描 data/*.json 的文本，找出 data/inline_math.json 未覆盖的「数学片段」。
## 未覆盖片段会在运行时被原样输出（不走 MicroTeX 渲染），正是「数学式子显示不正确」的来源。
## 用法： godot --headless --path . --script res://tools/check_inline.gd

const MATH_CHARS := "²³¹⁰⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₉√·×÷±≤≥≠≈∞∈∉⊆⊇∪∩→←⇒⇔∀∃∠°Δαβγθλμπ∅∩∪"

func _initialize() -> void:
	InlineMath.inline("x", 24) # 触发 inline_math.json 加载 + 正则编译
	var cjk := RegEx.new()
	cjk.compile("[\\x{2e80}-\\x{303f}\\x{31c0}-\\x{9fff}\\x{f900}-\\x{faff}\\x{fe30}-\\x{fe4f}\\x{ff00}-\\x{ffef}]+")
	var dir := DirAccess.open("res://data")
	var files: Array[String] = []
	if dir != null:
		for f in dir.get_files():
			# inline_math.json 是「覆盖表」本身，不是展示文本；扫它只会产生自反伪影。
			if f.ends_with(".json") and f != "inline_math.json":
				files.append(f)
	files.sort()
	var grand := {}
	var lines: Array[String] = []
	for f in files:
		var raw := FileAccess.get_file_as_string("res://data/" + f)
		if raw == "":
			continue
		var data = JSON.parse_string(raw)
		if data == null:
			continue
		var miss := {}
		_walk(data, cjk, miss)
		if miss.is_empty():
			continue
		# 只报「视觉相关」：含特殊数学符号/上下标的片段
		var visual: Array = []
		for k in miss.keys():
			if _has_math_char(str(k)):
				visual.append(k)
		if visual.is_empty():
			continue
		visual.sort()
		lines.append("=== %s : %d 个未覆盖(含符号) ===" % [f, visual.size()])
		for k in visual:
			var n: int = int(miss[k])
			lines.append("   [x%d] <%s>" % [n, str(k)])
			grand[str(k)] = true
	var out := "合计：%d 个未覆盖片段(含特殊符号)\n\n" % grand.size()
	out += "\n".join(lines)
	DirAccess.make_dir_recursive_absolute("res://build")
	var fw := FileAccess.open("res://build/inline_report.txt", FileAccess.WRITE)
	if fw != null:
		fw.store_string(out)
		fw.close()
	print("报告已写入 res://build/inline_report.txt ；未覆盖(含符号)=%d" % grand.size())
	quit(0)

func _walk(v: Variant, cjk: RegEx, miss: Dictionary) -> void:
	match typeof(v):
		TYPE_DICTIONARY:
			for k in (v as Dictionary).keys():
				if k is String:
					_check(str(k), cjk, miss)
				_walk((v as Dictionary)[k], cjk, miss)
		TYPE_ARRAY:
			for e in (v as Array):
				_walk(e, cjk, miss)
		TYPE_STRING:
			_check(str(v), cjk, miss)

func _check(t: String, cjk: RegEx, miss: Dictionary) -> void:
	if t == "":
		return
	var last := 0
	for m in cjk.search_all(t):
		_gap(t.substr(last, m.get_start() - last), miss)
		last = m.get_end()
	_gap(t.substr(last), miss)

func _gap(gap: String, miss: Dictionary) -> void:
	if gap.strip_edges() == "":
		return
	var core := InlineMath._inline_trim(gap)
	if core == "":
		return
	if InlineMath._inline_math.has(core):
		return
	miss[core] = int(miss.get(core, 0)) + 1

func _has_math_char(s: String) -> bool:
	for i in s.length():
		var c := s[i]
		# 「·」两侧任一侧是空白时视为标题分隔符（如「Boss ·」「· 01」「· a」），不计入数学符号。
		if c == "·":
			var prev_ws := i == 0 or s[i - 1] == " "
			var next_ws := i == s.length() - 1 or s[i + 1] == " "
			if prev_ws or next_ws:
				continue
		if MATH_CHARS.find(c) >= 0:
			return true
	return false
