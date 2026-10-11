class_name UI
extends RefCounted
## 极简未来 · 玻璃拟态 设计系统
## 面板/按钮/背景全部由代码绘制；仅图标与星星仍可走 art/(自动单色染色)。

# ---- 设计令牌 ----
const COL_BG := Color("#05080f")
const COL_BG2 := Color("#0a1020")
const COL_TEXT := Color("#eaf2ff")
const COL_TEXT_DIM := Color("#8fa3c8")
const COL_ACCENT := Color("#5ee6ff")
const COL_ACCENT_DK := Color("#1c7f96")
const COL_DANGER := Color("#fb7185")
const COL_SUCCESS := Color("#34d399")
const COL_LINE := Color(1, 1, 1, 0.12)
const COL_PANEL := Color(1, 1, 1, 0.05)
const COL_PANEL2 := Color(1, 1, 1, 0.09)
const COL_PANEL_BRD := Color(1, 1, 1, 0.14)
const COL_GLASS := Color(0.043, 0.062, 0.106, 0.82)

## 关卡选项内联公式图的缩放系数(各关卡共用，单一来源)。
const CHOICE_FORMULA_SCALE := 0.42

## 全局 UI 放大系数：手机/小屏时调大可读性。美术稿按 1280x720 设计，
## 需更大字号时调高此值(字号/控件尺寸统一经 fs() 换算)。
## 运行期由 Settings 注入(见 Settings.set_font_scale)，故为可变的静态变量。
static var S := 1.4
## 界面动效开关，由 Settings 注入；UI 不直接依赖 Settings，避免与自动加载形成循环引用。
static var animations := true

## 当前弹出的确认框根节点(供返回键优先关闭)。null 表示没有弹窗。
static var _active_confirm: Control = null

static var _font: Font
static var _mono: Font
static var _title_font: Font
static var _panel_style: StyleBox
static var _icon_cache: Dictionary = {}

# ---------------------------------------------------------------- 字体
static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray([
			"Microsoft YaHei UI", "Microsoft YaHei", "SimHei",
			"PingFang SC", "Noto Sans CJK SC", "Segoe UI", "sans-serif"
		])
		_font = f
	return _font

## 等宽字体栈(数字/代号用)，缺字形时回落到中文字体
static func mono_font() -> Font:
	if _mono == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray([
			"Cascadia Mono", "Consolas", "JetBrains Mono",
			"SFMono-Regular", "DejaVu Sans Mono", "Menlo",
			"Microsoft YaHei UI", "Microsoft YaHei", "PingFang SC", "sans-serif"
		])
		_mono = f
	return _mono

## 内置标题字体候选(显式路径)。导出后源码 .ttf 不在包内(只有 .fontdata + .import),
## 目录枚举可能拿不到,故必须按路径尝试,才能保证手机端也生效。
const BUILTIN_TITLE_FONTS := [
	"res://art/fonts/aidianqianfengxingshu.ttf",
]

## 首页品牌标题字体(行书/行楷)。
## 优先级:① 项目内置字体(res://art/fonts/,显式路径优先,兼容任意 ttf/otf);
##        ② 系统行书/行楷(华文行楷等);③ 退回楷体。
static func title_font() -> Font:
	if _title_font != null:
		return _title_font
	# ① 显式路径(导出后仍可靠)
	for p in BUILTIN_TITLE_FONTS:
		var fe := _try_font(p)
		if fe != null:
			_title_font = fe
			return _title_font
	# ①' 扫描 res://art/fonts(兼容 .ttf.import / .ttf.remap 形式)
	for p in _font_files("res://art/fonts"):
		var fs := _try_font(p)
		if fs != null:
			_title_font = fs
			return _title_font
	# ② 系统行书/行楷,最后退到楷体
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray([
		"STXingkai", "华文行楷", "方正行楷", "汉仪行楷", "叶根友行书", "行楷",
		"Zhi Mang Xing", "Ma Shan Zheng",
		"STKaiti", "Kaiti SC", "KaiTi", "楷体",
		"Source Han Serif SC Heavy", "Noto Serif CJK SC", "serif",
	])
	_title_font = sf
	return _title_font

static func _try_font(path: String) -> Font:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Font

static func _font_files(dir_path: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	for f in d.get_files():
		var res := dir_path.path_join(f)
		# 导出后目录里可能出现的是 xxx.ttf.import / xxx.ttf.remap,还原成资源路径
		if res.ends_with(".import"):
			res = res.trim_suffix(".import")
		elif res.ends_with(".remap"):
			res = res.trim_suffix(".remap")
		var ext := res.get_extension().to_lower()
		if ext == "ttf" or ext == "otf" or ext == "ttc" or ext == "woff" or ext == "woff2":
			if not out.has(res):
				out.append(res)
	return out

## 把设计稿字号换算成实际字号(始终取整，至少 1px)
static func fs(n: int) -> int:
	return maxi(1, int(round(float(n) * S)))

# ---------------------------------------------------------------- LaTeX 公式内联(实现见 InlineMath)
static func inline(text: String, h: int = 26) -> String:
	return InlineMath.inline(text, h)

static func inline_formulas(text: String, h: int = 26) -> String:
	return InlineMath.inline_formulas(text, h)

static func strip_formulas(text: String) -> String:
	return InlineMath.strip_formulas(text)

static func formula_img(name: String, h: int = 26) -> String:
	return InlineMath.formula_img(name, h)

# ---------------------------------------------------------------- 样式盒
static func stylebox(bg: Color, radius: int = 14, border: Color = Color(0, 0, 0, 0), bw: int = 0, margin: int = 12, shadow: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(bw)
	if border.a > 0.0:
		sb.border_color = border
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = maxi(margin - 2, 4)
	sb.content_margin_bottom = margin
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 12
		sb.shadow_offset = Vector2(0, 5)
	return sb

## 玻璃样式：半透明填充 + 发丝描边 + 可选辉光
static func glass_box(fill: Color = COL_PANEL, radius: int = 12, border: Color = COL_PANEL_BRD, bw: int = 1, margin: int = 16, glow: Color = Color(0, 0, 0, 0), glow_size: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(bw)
	if bw > 0:
		sb.border_color = border
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = maxi(margin - 2, 4)
	sb.content_margin_bottom = margin
	if glow_size > 0 and glow.a > 0.0:
		sb.shadow_color = glow
		sb.shadow_size = glow_size
		sb.shadow_offset = Vector2.ZERO
	return sb

## 顶栏：通栏深玻璃 + 底部青色发丝线
static func topbar_box() -> StyleBoxFlat:
	var sb := glass_box(Color(0.028, 0.045, 0.085, 0.88), 0, COL_PANEL_BRD, 1, 0)
	sb.set_border_width_all(0)
	sb.border_width_bottom = 1
	sb.border_color = Color(COL_ACCENT, 0.28)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	return sb

## 深玻璃面板(弹层/大面板)
static func panel() -> StyleBox:
	if _panel_style == null:
		_panel_style = glass_box(COL_GLASS, 14, COL_PANEL_BRD, 1, 20)
		_panel_style.shadow_color = Color(0, 0, 0, 0.45)
		_panel_style.shadow_size = 16
		_panel_style.shadow_offset = Vector2(0, 8)
	return _panel_style

# ---------------------------------------------------------------- 角标
class Marks extends Control:
	var length: float = 12.0
	var thick: float = 2.0
	var col: Color = Color("#5ee6ff")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var L := length
		var t := thick
		var w := size.x
		var h := size.y
		if w < L * 2.0 or h < L * 2.0:
			return
		draw_rect(Rect2(0, 0, L, t), col)
		draw_rect(Rect2(0, 0, t, L), col)
		draw_rect(Rect2(w - L, 0, L, t), col)
		draw_rect(Rect2(w - t, 0, t, L), col)
		draw_rect(Rect2(0, h - t, L, t), col)
		draw_rect(Rect2(0, h - L, t, L), col)
		draw_rect(Rect2(w - L, h - t, L, t), col)
		draw_rect(Rect2(w - t, h - L, t, L), col)

## 四角 L 形科技角标。parent 为 PanelContainer 时铺在内容区边缘，
## 否则铺满父级并向内缩进 inset。
static func corner_marks(parent: Control, inset: float = 6.0, length: float = 12.0, thick: float = 2.0, col: Color = COL_ACCENT) -> Marks:
	var m := Marks.new()
	m.length = length
	m.thick = thick
	m.col = col
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(m)
	if parent is PanelContainer:
		return m
	full_rect(m)
	m.offset_left = inset
	m.offset_top = inset
	m.offset_right = -inset
	m.offset_bottom = -inset
	return m

## 玻璃卡片(可选四角角标 / 外发光)
static func card(marks: bool = true, mark_col: Color = COL_ACCENT, fill: Color = COL_GLASS, border: Color = COL_PANEL_BRD, radius: int = 14, margin: int = 18, glow: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", glass_box(fill, radius, border, 1, margin, glow, 18 if glow.a > 0.0 else 0))
	if marks:
		corner_marks(p, 0.0, clampf(margin * 0.6, 8.0, 14.0), 2.0, mark_col)
	return p

# ---------------------------------------------------------------- 按钮
## 幽灵按钮：透明底，hover 时浮现玻璃层
static func ghost_button(text: String, on_press: Callable, font_size: int = 15) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", fs(font_size))
	b.add_theme_stylebox_override("normal", stylebox(Color(0, 0, 0, 0), 10, COL_LINE, 1, 14))
	b.add_theme_stylebox_override("hover", glass_box(Color(1, 1, 1, 0.07), 10, Color(COL_ACCENT, 0.5), 1, 14))
	b.add_theme_stylebox_override("pressed", glass_box(Color(0, 0, 0, 0.25), 10, COL_ACCENT, 1, 14))
	b.add_theme_stylebox_override("disabled", stylebox(Color(0, 0, 0, 0), 10, Color(1, 1, 1, 0.06), 1, 14))
	b.add_theme_stylebox_override("focus", stylebox(Color(0, 0, 0, 0), 10, Color(COL_ACCENT, 0.3), 1, 14))
	b.add_theme_color_override("font_color", COL_TEXT_DIM)
	b.add_theme_color_override("font_hover_color", COL_TEXT)
	b.add_theme_color_override("font_pressed_color", COL_ACCENT)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.25))
	b.pressed.connect(on_press)
	press_fx(b, 0.96)
	return b

## 语音朗读按钮：点击时调用 provider(通常重播当前题干)。设备无语音引擎时禁用。
static func voice_button(provider: Callable, font_size: int = 15) -> Button:
	var b := ghost_button("🔊 朗读", provider, font_size)
	if not tts_available():
		b.disabled = true
		b.tooltip_text = "当前设备无可用的语音引擎"
	return b

## 青色荧光 CTA 按钮
static func primary_button(b: Button) -> Button:
	b.add_theme_stylebox_override("normal", glass_box(Color(COL_ACCENT, 0.14), 12, COL_ACCENT, 1, 18, Color(COL_ACCENT, 0.30), 14))
	b.add_theme_stylebox_override("hover", glass_box(Color(COL_ACCENT, 0.26), 12, COL_ACCENT, 1, 18, Color(COL_ACCENT, 0.5), 18))
	b.add_theme_stylebox_override("pressed", glass_box(Color(COL_ACCENT, 0.4), 12, Color(COL_ACCENT, 0.8), 1, 18, Color(COL_ACCENT, 0.2), 10))
	b.add_theme_stylebox_override("focus", glass_box(Color(COL_ACCENT, 0.2), 12, COL_ACCENT, 1, 18, Color(COL_ACCENT, 0.4), 16))
	b.add_theme_color_override("font_color", COL_ACCENT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
	press_fx(b, 0.95)
	return b

# ---------------------------------------------------------------- 动效反馈
## 按钮按压反馈：按下缩小、松开回弹(触屏/鼠标通用)。缩放为纯视觉，不影响布局。
static func _scale_to(b: Control, s: float, dur: float, trans: int, ease_type: int) -> void:
	if not is_instance_valid(b):
		return
	if b.has_meta("_fx_tw"):
		var old: Variant = b.get_meta("_fx_tw")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	b.pivot_offset = b.size * 0.5
	var tw := b.create_tween()
	b.set_meta("_fx_tw", tw)
	tw.tween_property(b, "scale", Vector2(s, s), dur).set_trans(trans).set_ease(ease_type)

static func press_fx(b: Button, amount: float = 0.95) -> void:
	if not animations:
		return
	b.button_down.connect(func() -> void: _scale_to(b, amount, 0.07, Tween.TRANS_QUAD, Tween.EASE_OUT))
	b.button_up.connect(func() -> void: _scale_to(b, 1.0, 0.16, Tween.TRANS_BACK, Tween.EASE_OUT))
	b.mouse_exited.connect(func() -> void: _scale_to(b, 1.0, 0.16, Tween.TRANS_BACK, Tween.EASE_OUT))

## 悬停抬升：src 收到悬停时放大 target(卡片的覆盖热区按钮作为 src)
static func hover_scale(target: Control, src: Control, up: float = 1.03) -> void:
	if not animations:
		return
	src.mouse_entered.connect(func() -> void: _scale_to(target, up, 0.14, Tween.TRANS_QUAD, Tween.EASE_OUT))
	src.mouse_exited.connect(func() -> void: _scale_to(target, 1.0, 0.18, Tween.TRANS_QUAD, Tween.EASE_OUT))

## 按压下沉：src 按下时轻微缩小 target
static func press_scale(target: Control, src: Control, amount: float = 0.985) -> void:
	if not animations:
		return
	src.button_down.connect(func() -> void: _scale_to(target, amount, 0.07, Tween.TRANS_QUAD, Tween.EASE_OUT))
	src.button_up.connect(func() -> void: _scale_to(target, 1.0, 0.16, Tween.TRANS_BACK, Tween.EASE_OUT))

## 容器子项依次淡入(cap 限制参与动画的最大序号，避免超长列表拖沓)
static func stagger_in(container: Node, step: float = 0.05, dur: float = 0.28, cap: int = 12) -> void:
	if container == null or not is_instance_valid(container):
		return
	var i := 0
	for c in container.get_children():
		if not (c is Control):
			continue
		var ctl := c as Control
		if ctl.is_queued_for_deletion():
			continue
		if not animations:
			ctl.modulate.a = 1.0
			continue
		ctl.modulate.a = 0.0
		var tw := ctl.create_tween()
		tw.tween_interval(step * float(mini(i, cap)))
		tw.tween_property(ctl, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		i += 1

## 卡牌入场：由窄到宽的"翻牌"展开 + 淡入，依次错峰(适合主城功能卡)。
static func card_stagger_in(container: Node, step: float = 0.08, dur: float = 0.42, cap: int = 12) -> void:
	if container == null or not is_instance_valid(container):
		return
	var i := 0
	for c in container.get_children():
		if not (c is Control):
			continue
		var ctl := c as Control
		if ctl.is_queued_for_deletion():
			continue
		if not animations:
			ctl.modulate.a = 1.0
			ctl.scale = Vector2.ONE
			continue
		ctl.modulate.a = 0.0
		ctl.scale = Vector2(0.25, 0.92)
		ctl.pivot_offset = ctl.custom_minimum_size * 0.5
		ctl.resized.connect(func() -> void: ctl.pivot_offset = ctl.size * 0.5, CONNECT_ONE_SHOT)
		var delay := step * float(mini(i, cap))
		var tw := ctl.create_tween().set_parallel(true)
		tw.tween_property(ctl, "modulate:a", 1.0, dur * 0.55).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(ctl, "scale", Vector2.ONE, dur).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1

static func _rotate_to(c: Control, r: float, dur: float) -> void:
	if not is_instance_valid(c):
		return
	if c.has_meta("_fx_rot"):
		var old: Variant = c.get_meta("_fx_rot")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween()
	c.set_meta("_fx_rot", tw)
	tw.tween_property(c, "rotation", r, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## 卡牌悬停：跟随光标轻微倾斜 + 抬升，离开平滑复位。
static func card_tilt(target: Control, src: Control, max_deg: float = 6.0, lift: float = 1.035) -> void:
	if not animations:
		return
	src.mouse_entered.connect(func() -> void:
		_scale_to(target, lift, 0.16, Tween.TRANS_QUAD, Tween.EASE_OUT))
	src.mouse_exited.connect(func() -> void:
		_scale_to(target, 1.0, 0.22, Tween.TRANS_BACK, Tween.EASE_OUT)
		_rotate_to(target, 0.0, 0.22))
	src.gui_input.connect(func(e: InputEvent) -> void:
		if not (e is InputEventMouseMotion):
			return
		var sz := src.size
		if sz.x <= 0.0 or sz.y <= 0.0:
			return
		var m := (e as InputEventMouseMotion).position
		var nx := clampf((m.x / sz.x - 0.5) * 2.0, -1.0, 1.0)
		var ny := clampf((m.y / sz.y - 0.5) * 2.0, -1.0, 1.0)
		target.pivot_offset = target.size * 0.5
		target.rotation = deg_to_rad(-nx * max_deg - ny * max_deg * 0.25))

## 整体淡入
static func fade_in(c: Control, dur: float = 0.4) -> void:
	if c == null or not is_instance_valid(c):
		return
	if not animations:
		c.modulate.a = 1.0
		return
	c.modulate.a = 0.0
	c.create_tween().tween_property(c, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------- 主题
static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = fs(20)
	t.set_color("font_color", "Label", COL_TEXT)

	t.set_stylebox("normal", "Button", glass_box())
	t.set_stylebox("hover", "Button", glass_box(COL_PANEL2, 12, Color(COL_ACCENT, 0.5), 1, 16))
	t.set_stylebox("pressed", "Button", glass_box(Color(0, 0, 0, 0.25), 12, Color(COL_ACCENT, 0.75), 1, 16))
	t.set_stylebox("disabled", "Button", glass_box(Color(1, 1, 1, 0.02), 12, Color(1, 1, 1, 0.06), 1, 16))
	t.set_stylebox("focus", "Button", glass_box(Color(0, 0, 0, 0), 12, Color(COL_ACCENT, 0.35), 1, 16))
	t.set_color("font_color", "Button", COL_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", COL_ACCENT)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.3))
	t.set_font_size("font_size", "Button", fs(19))

	t.set_stylebox("panel", "PanelContainer", panel())

	# 细窄滚动条(青色悬浮块)
	var thumb := Image.create(6, 26, false, Image.FORMAT_RGBA8)
	thumb.fill(Color(COL_ACCENT, 0.55))
	var thumb_hi := Image.create(6, 26, false, Image.FORMAT_RGBA8)
	thumb_hi.fill(Color(COL_ACCENT, 0.9))
	t.set_icon("grabber", "VScrollBar", ImageTexture.create_from_image(thumb))
	t.set_icon("grabber_highlight", "VScrollBar", ImageTexture.create_from_image(thumb_hi))
	t.set_stylebox("grabber_area", "VScrollBar", stylebox(Color(0, 0, 0, 0), 3))
	t.set_stylebox("grabber_area_highlight", "VScrollBar", stylebox(Color(0, 0, 0, 0), 3))
	t.set_stylebox("scroll", "VScrollBar", stylebox(Color(0, 0, 0, 0.18), 3))

	# 滑块(HSlider)：青色轨道 + 圆形滑钮
	t.set_stylebox("slider", "HSlider", stylebox(Color(1, 1, 1, 0.10), 4, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber_area", "HSlider", stylebox(Color(COL_ACCENT, 0.85), 4, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", stylebox(Color(COL_ACCENT, 1.0), 4, Color(0, 0, 0, 0), 0, 0))
	var knob := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	knob.fill(Color(0, 0, 0, 0))
	for y in 20:
		for x in 20:
			var d := Vector2(float(x) - 9.5, float(y) - 9.5).length()
			if d <= 7.5:
				var c: Color = COL_ACCENT
				if d > 5.5:
					c = COL_ACCENT.darkened(0.25)
				elif d <= 3.0:
					c = COL_ACCENT.lightened(0.35)
				knob.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	var knob_tex := ImageTexture.create_from_image(knob)
	t.set_icon("grabber", "HSlider", knob_tex)
	t.set_icon("grabber_highlight", "HSlider", knob_tex)
	return t

# ---------------------------------------------------------------- 图标(单色染色)
## 把 art/<name>.png 缩放并染成单色调(保留明暗层次与透明度)。
static func icon(name: String, size: int, tint: Color) -> Texture2D:
	var key := "%s#%d#%s" % [name, size, tint.to_html()]
	if _icon_cache.has(key):
		return _icon_cache[key]
	var t := Art.tex_sized(name, size)
	var out: Texture2D = t
	if t != null:
		var img := t.get_image()
		if img != null and not img.is_empty():
			img = img.duplicate()
			img.convert(Image.FORMAT_RGBA8)
			for y in range(img.get_height()):
				for x in range(img.get_width()):
					var c := img.get_pixel(x, y)
					if c.a > 0.01:
						var luma := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
						var k := 0.3 + 0.7 * luma
						img.set_pixel(x, y, Color(tint.r * k, tint.g * k, tint.b * k, c.a))
			out = ImageTexture.create_from_image(img)
	_icon_cache[key] = out
	return out

# ---------------------------------------------------------------- 辅助
static func outlined(l: Label, size: int = 4, col: Color = Color(0, 0, 0, 0.45)) -> Label:
	l.add_theme_constant_override("outline_size", size)
	l.add_theme_color_override("font_outline_color", col)
	return l

static func make_label(text: String, size: int = 20, color: Color = COL_TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", fs(size))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l

static func make_label_dim(text: String, size: int = 18) -> Label:
	return make_label(text, size, COL_TEXT_DIM)

## 等宽读数标签
static func mono_label(text: String, size: int = 16, color: Color = COL_TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := make_label(text, size, color, align)
	l.add_theme_font_override("font", mono_font())
	return l

static func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## 关卡「左文字 / 右图形」布局度量：文字面板宽度随字号缩放，保证题干舒展、不再拥挤。
## 返回 left(面板左边界) / width(面板宽度) / view_left(右侧图形区左边界)。
static func stage_layout() -> Dictionary:
	var left := 16.0
	var width := clampf(420.0 * S, 410.0, 600.0)
	var gap := 14.0
	return {
		"left": left,
		"width": width,
		"gap": gap,
		"view_left": left + width + gap,
	}

## 触摸拖动滚动:Godot 的 ScrollContainer 在触摸落在子控件(STOP)上时收不到拖动,
## 手机端会完全无法滑动。这里给 ScrollContainer 挂一个辅助节点,在 _input(早于 GUI)
## 统一接管触摸拖动并滚动;鼠标滚轮仍由 ScrollContainer 自身处理。
class TouchScroll extends Node:
	var target: ScrollContainer
	var tracking := false
	var dragging := false
	var suppress := false
	var last := Vector2.ZERO
	var moved := 0.0
	const DEADZONE := 10.0

	func _input(event: InputEvent) -> void:
		if target == null or not is_instance_valid(target):
			return
		if event is InputEventScreenTouch:
			var t := event as InputEventScreenTouch
			if t.pressed:
				tracking = target.get_global_rect().has_point(t.position)
				dragging = false
				suppress = false
				moved = 0.0
				last = t.position
			else:
				tracking = false
				# 不清 suppress:等随后的模拟鼠标抬起一起吞掉,避免滑动误触按钮
		elif event is InputEventScreenDrag and tracking:
			var d := event as InputEventScreenDrag
			var rel := d.position - last
			last = d.position
			moved += rel.length()
			if not dragging and moved > DEADZONE:
				dragging = true
				suppress = true
			if dragging:
				target.scroll_vertical = int(float(target.scroll_vertical) - rel.y)
				target.scroll_horizontal = int(float(target.scroll_horizontal) - rel.x)
				get_viewport().set_input_as_handled()
		elif suppress and (event is InputEventMouseButton or event is InputEventMouseMotion):
			get_viewport().set_input_as_handled()
			if event is InputEventMouseButton and not (event as InputEventMouseButton).pressed:
				suppress = false

## 让一个 ScrollContainer 支持触摸拖动(幂等)
static func enable_touch_scroll(sc: ScrollContainer) -> void:
	if sc == null:
		return
	for c in sc.get_children():
		if c is TouchScroll:
			return
	var ts := TouchScroll.new()
	ts.name = "TouchScroll"
	ts.target = sc
	sc.add_child(ts)

## 弹层入场：淡入 + 轻微回弹缩放(需在布局完成后调用)
static func popup_in(c: Control, dur: float = 0.2) -> void:
	if not animations:
		c.modulate.a = 1.0
		c.scale = Vector2.ONE
		return
	c.pivot_offset = c.size * 0.5
	c.modulate.a = 0.0
	c.scale = Vector2(0.96, 0.96)
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## 通用确认弹窗：半透明遮罩 + 玻璃面板 + 「取消 / 确定」。on_yes 在确认后调用。
static func confirm(root: Node, title: String, msg: String, on_yes: Callable, ok_text: String = "确定") -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	_active_confirm = dim
	dim.tree_exiting.connect(func() -> void:
		if _active_confirm == dim:
			_active_confirm = null
	)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.add_child(center)

	var pan := card(true, COL_ACCENT, COL_GLASS, Color(COL_ACCENT, 0.35), 14, 22, Color(COL_ACCENT, 0.22))
	pan.custom_minimum_size = Vector2(460.0 * S, 0)
	center.add_child(pan)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	pan.add_child(vb)
	vb.add_child(make_label(title, 24, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(make_label(msg, 17, COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vb.add_child(row)
	row.add_child(ghost_button("取消", func() -> void: dim.queue_free(), 17))
	var ok := Button.new()
	ok.text = ok_text
	ok.custom_minimum_size = Vector2(150, 48)
	UI.primary_button(ok)
	ok.pressed.connect(func() -> void:
		dim.queue_free()
		on_yes.call()
	)
	row.add_child(ok)
	popup_in(center)

# ---------------------------------------------------------------- 语音朗读(TTS，实现见 Tts)
static func tts_available() -> bool:
	return Tts.available()

static func tts_list_voices() -> Array:
	return Tts.list_voices()

static func tts_configure(p_enabled: bool, p_rate: float, p_volume: float = 1.0, p_voice_id: String = "", p_engine: String = "system", p_provider: String = "baidu") -> void:
	Tts.configure(p_enabled, p_rate, p_volume, p_voice_id, p_engine, p_provider)

static func tts_say(text: String, interrupt: bool = true, cute: bool = false) -> void:
	Tts.say(text, interrupt, cute)

static func tts_repeat() -> void:
	Tts.repeat()

static func tts_stop() -> void:
	Tts.stop()

static func tts_sanitize(text: String) -> String:
	return Tts.sanitize(text)
