class_name InlineMath
extends RefCounted
## 内联数学公式子系统(从 UI 抽出，UI.inline*/strip_formulas 保留薄转发)。
## - {f:名称} → art/line/formulas/名称.png 的内联图片(bbcode)；
## - 非中文片段 → data/inline_math.json 映射的内联公式图。

static var _formula_size_cache: Dictionary = {}
static var _inline_re: RegEx

static var _inline_math: Dictionary = {}
static var _inline_math_loaded := false
static var _inline_cjk_re: RegEx

## 把文本里非中文(CJK)分隔出来的数学片段替换成 data/inline_math.json 里的内联公式图。
## 与生成脚本使用同一套 CJK 切分 + 首尾修剪(空白与 ,;:.!?[]\"'`)，保证键值一一对应。
static func inline(text: String, h: int = 26) -> String:
	if text.is_empty():
		return text
	if not _inline_math_loaded:
		_inline_math_loaded = true
		if ResourceLoader.exists("res://data/inline_math.json"):
			var raw := FileAccess.get_file_as_string("res://data/inline_math.json")
			if raw != "":
				var data = JSON.parse_string(raw)
				if typeof(data) == TYPE_DICTIONARY:
					_inline_math = data
	if _inline_math.is_empty():
		return text
	if _inline_cjk_re == null:
		_inline_cjk_re = RegEx.new()
		_inline_cjk_re.compile("[\\x{2e80}-\\x{303f}\\x{31c0}-\\x{9fff}\\x{f900}-\\x{faff}\\x{fe30}-\\x{fe4f}\\x{ff00}-\\x{ffef}]+")
	var out := ""
	var last := 0
	for m in _inline_cjk_re.search_all(text):
		out += _inline_gap(text.substr(last, m.get_start() - last), h)
		out += text.substr(m.get_start(), m.get_end() - m.get_start())
		last = m.get_end()
	out += _inline_gap(text.substr(last), h)
	return out

static func _inline_gap(gap: String, h: int) -> String:
	if gap.is_empty():
		return gap
	var core := _inline_trim(gap)
	if core.is_empty():
		return gap
	if not _inline_math.has(core):
		return gap
	var info: Dictionary = _inline_math[core]
	var path := str(info.get("p", ""))
	if path == "" or not ResourceLoader.exists(path):
		return gap
	var iw := int(float(str(info.get("w", 0))))
	var ih := int(float(str(info.get("h", 0))))
	if ih <= 0:
		return gap
	var w := int(round(float(h) * float(iw) / float(ih)))
	var lead := gap.substr(0, gap.find(core))
	var trail := gap.substr(lead.length() + core.length())
	return lead + "[img=%dx%d]%s[/img]" % [w, h, path] + trail

static func _inline_trim(t: String) -> String:
	var p := " ,;:.!?[]\"'`"
	var s := t
	while s.length() > 0 and s.left(1) in p:
		s = s.substr(1)
	while s.length() > 0 and s.right(1) in p:
		s = s.substr(0, s.length() - 1)
	return s

## 把文本里的 {f:名称} 替换为 art/line/formulas/名称.png 的内联 LaTeX 公式图。
## h 为目标显示高度(像素)，宽度按原图比例自动计算。
static func inline_formulas(text: String, h: int = 26) -> String:
	text = inline(text, h)
	if text.find("{f:") < 0:
		return text
	if _inline_re == null:
		_inline_re = RegEx.new()
		_inline_re.compile("\\{f:([A-Za-z0-9_]+)\\}")
	var out := ""
	var last := 0
	for m in _inline_re.search_all(text):
		out += text.substr(last, m.get_start() - last)
		var name := m.get_string(1)
		out += formula_img(name, h)
		last = m.get_end()
	out += text.substr(last)
	return out

## 去掉 {f:名称} 标记(用于朗读)，替换为"公式"
static func strip_formulas(text: String) -> String:
	if text.find("{f:") < 0:
		return text
	if _inline_re == null:
		_inline_re = RegEx.new()
		_inline_re.compile("\\{f:([A-Za-z0-9_]+)\\}")
	return _inline_re.sub(text, "公式", true)

## 生成单个公式的内联图片 bbcode
static func formula_img(name: String, h: int = 26) -> String:
	var path := "res://art/line/formulas/%s.png" % name
	var sz: Vector2i = _formula_size_cache.get(name, Vector2i.ZERO)
	if sz == Vector2i.ZERO:
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex != null:
				sz = tex.get_size()
		_formula_size_cache[name] = sz
	if sz.y <= 0:
		return ""
	var w := int(round(float(h) * float(sz.x) / float(sz.y)))
	return "[img=%dx%d]%s[/img]" % [w, h, path]
