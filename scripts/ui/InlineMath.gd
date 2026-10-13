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

## MicroTeX 运行时渲染：-1 未探测 / 0 不可用 / 1 可用。可用时优先走 LaTeX 渲染，
## 否则回退到旧的预烘焙 PNG（见 _inline_gap）。
static var _mt_state := -1
## 进程内渲染尺寸缓存：md5(latex|h|color) -> Vector2i(像素宽高)。
static var _mt_cache: Dictionary = {}
## bbcode 内联公式的默认颜色（深色玻璃面板上的正文色）。
static var MT_COLOR := Color("#eaf2ff")
## 渲染缓存版本：后端排版/字体有变时 +1，使旧的 mt_cache 失效。
const MT_CACHE_VERSION := "v2"
## .mttex 资源加载器是否已注册(去重)。
static var _mt_loader_added := false
## MicroTeX 运行时资源目录（res:// 开发态直接读；导出态先用内置 zip 解压到 user://）。
const MT_RES_DIR := "res://gdextension/res"
const MT_RES_ZIP := "res://gdextension/res.bin"
static var _mt_res_path := ""

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
	var bb := _formula_bbcode(info, h)
	if bb == "":
		return gap
	var lead := gap.substr(0, gap.find(core))
	var trail := gap.substr(lead.length() + core.length())
	return lead + bb + trail

## 为一个映射项生成内联 bbcode：优先 LaTeX 运行时渲染，缺失/失败时回退旧 PNG。
static func _formula_bbcode(info: Dictionary, h: int) -> String:
	var latex := str(info.get("latex", ""))
	if latex != "" and _mt_ready():
		var bb := _mt_inline_bbcode(latex, h, MT_COLOR)
		if bb != "":
			return bb
	# 回退：预烘焙 PNG
	var path := str(info.get("p", ""))
	if path == "" or not ResourceLoader.exists(path):
		return ""
	var iw := int(float(str(info.get("w", 0))))
	var ih := int(float(str(info.get("h", 0))))
	if ih <= 0:
		return ""
	var w := int(round(float(h) * float(iw) / float(ih)))
	return "[img=%dx%d]%s[/img]" % [w, h, path]

static func _inline_trim(t: String) -> String:
	# 与生成脚本 mathgen/gen_inline.py 的 trim_math 保持一致：只去首尾空白与 ,;:.!?
	var p := ",;:.!?"
	var s := t.strip_edges()
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

# ---------------------------------------------------------------- MicroTeX 运行时
## 探测扩展是否可用(懒加载，一次)。可用时注册 .mttex 资源加载器。
static func _mt_ready() -> bool:
	if _mt_state != -1:
		return _mt_state == 1
	_mt_state = 0
	if not Engine.has_singleton("MathTeX"):
		return false
	_ensure_mt_loader()
	var mt = Engine.get_singleton("MathTeX")
	# 注意：res 是目录，ResourceLoader.exists() 对目录恒为 false，必须直接 configure。
	var res_path := _mt_resolve()
	if res_path == "":
		return false
	mt.configure(res_path)
	if mt.is_ready():
		_mt_state = 1
	return _mt_state == 1

## 解析 MicroTeX 资源目录的真实文件系统路径。
## - 开发态：res:// 映射到真实目录，直接返回（改动即时生效）。
## - 导出态：res:// 在 PCK/APK 内，扩展的 std::ifstream 读不到，改为把内置的
##   gdextension/res.bin 解压到真实文件系统再交给扩展。
##   注意：MicroTeX/FreeType 在 Windows 用 ANSI 窄路径读文件，user:// 会落在含中文的
##   工程名目录下而失败，故解压到 OS 临时目录（ASCII）。
static func _mt_resolve() -> String:
	if _mt_res_path != "":
		return _mt_res_path
	var direct := ProjectSettings.globalize_path(MT_RES_DIR)
	if FileAccess.file_exists(direct + "/.clatexmath-res_root"):
		_mt_res_path = direct
		return _mt_res_path
	var cache_dir := _mt_cache_dir()
	var marker := cache_dir + "/.clatexmath-res_root"
	var want_md5 := FileAccess.get_md5(MT_RES_ZIP)
	var have_md5 := ""
	if FileAccess.file_exists(cache_dir + "/.source_md5"):
		have_md5 = FileAccess.get_file_as_string(cache_dir + "/.source_md5").strip_edges()
	if not FileAccess.file_exists(marker) or (want_md5 != "" and have_md5 != want_md5):
		if not _mt_extract_zip(MT_RES_ZIP, cache_dir):
			return ""
		var w := FileAccess.open(cache_dir + "/.source_md5", FileAccess.WRITE)
		if w != null:
			w.store_string(want_md5)
			w.close()
	_mt_res_path = cache_dir
	return _mt_res_path

## MicroTeX 运行时资源的真实目录（ASCII，避开中文工程名导致的 ANSI 路径问题）。
static func _mt_cache_dir() -> String:
	return OS.get_temp_dir().path_join("mathtex_res")

## 把 zip 里的全部条目解压到 dst_dir（res:// 相对路径直接落到 user://）。
static func _mt_extract_zip(zip_path: String, dst_dir: String) -> bool:
	if not FileAccess.file_exists(zip_path):
		return false
	var zr := ZIPReader.new()
	if zr.open(zip_path) != OK:
		return false
	for f in zr.get_files():
		var out_path := dst_dir + "/" + f
		DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
		var w := FileAccess.open(out_path, FileAccess.WRITE)
		if w != null:
			w.store_buffer(zr.read_file(f))
			w.close()
	zr.close()
	return true

static func _ensure_mt_loader() -> void:
	if _mt_loader_added:
		return
	ResourceLoader.add_resource_format_loader(MtTextureLoader.new())
	_mt_loader_added = true

## 用 MicroTeX 渲染 latex → 写入 user://mt_cache/<hash>.mttex → 返回 bbcode。
## 渲染尺寸与颜色进入缓存键；同键复用磁盘缓存，避免重复光栅化。
static func _mt_inline_bbcode(latex: String, h: int, color: Color) -> String:
	var key := "%s|%s|%d|%s" % [MT_CACHE_VERSION, latex, h, color.to_html(true)]
	var hash := key.md5_text()
	var disk := "user://mt_cache/%s.mttex" % hash
	var size: Vector2i = _mt_cache.get(hash, Vector2i.ZERO)
	if size == Vector2i.ZERO:
		if FileAccess.file_exists(disk):
			var bytes := FileAccess.get_file_as_bytes(disk)
			var img := Image.new()
			if img.load_png_from_buffer(bytes) == OK and not img.is_empty():
				size = Vector2i(img.get_width(), img.get_height())
		if size == Vector2i.ZERO:
			var mt = Engine.get_singleton("MathTeX")
			var rendered: Image = mt.render(latex, float(maxi(8, h)), color)
			if rendered == null or rendered.is_empty():
				return ""
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://mt_cache"))
			rendered.save_png(disk)
			size = Vector2i(rendered.get_width(), rendered.get_height())
		_mt_cache[hash] = size
	return "[img=%dx%d]%s[/img]" % [size.x, size.y, disk]
