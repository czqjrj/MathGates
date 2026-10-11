class_name ChapterNode
extends Control
## 世界地图上的章节节点 · 科技环形节点(细环 + 进度弧 + 等宽序号)

signal selected(index: int)

const NODE_W := 180.0
const NODE_H := 200.0

var chapter_index: int = 0
var chapter_title: String = ""
var subtitle: String = ""
var color: Color = Color("#5B8FF9")
var unlocked: bool = true
var stars: int = 0
var max_stars: int = 3

var _hover: bool = false
var _t: float = 0.0
var _press := false
var _press_pos := Vector2.ZERO
var _press_scroll := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(NODE_W, NODE_H)
	size = Vector2(NODE_W, NODE_H)
	# PASS:让触摸拖动穿透到外层 ScrollContainer,手机上才能上下滑动
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw()
	)
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	# 抬起且未拖动/未滚屏时才选中,避免滑动地图时误开章节面板
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_press = true
			_press_pos = mb.global_position
			_press_scroll = _scroll_v()
		elif _press:
			_press = false
			var moved: float = (mb.global_position - _press_pos).length()
			if moved < 12.0 and absf(_scroll_v() - _press_scroll) < 4.0:
				selected.emit(chapter_index)

func _scroll_v() -> float:
	var n := get_parent()
	while n != null:
		if n is ScrollContainer:
			return (n as ScrollContainer).scroll_vertical
		n = n.get_parent()
	return 0.0

func _draw() -> void:
	var f := UI.font()
	var mf := UI.mono_font()
	var acc := UI.COL_ACCENT
	var float_y := sin(_t * 1.6 + chapter_index) * 4.0
	var c := Vector2(NODE_W * 0.5, 84.0 + float_y)

	var base := color
	if not unlocked:
		base = Color("#4a4f63")

	# hover 光晕
	if unlocked and _hover:
		draw_circle(c, 72.0, Color(acc.r, acc.g, acc.b, 0.10))

	# 底盘
	draw_circle(c, 56.0, Color(0.05, 0.07, 0.12, 0.8))

	# 外环(章节色)
	var ring_a := 0.6 if unlocked else 0.35
	draw_arc(c, 56.0, 0.0, TAU, 96, Color(base, ring_a), 2.0, true)

	# 进度弧(青色，从顶部顺时针)
	var prog := 0.0
	if max_stars > 0:
		prog = clampf(float(stars) / float(max_stars), 0.0, 1.0)
	if unlocked and prog > 0.001:
		draw_arc(c, 56.0, -PI / 2.0, -PI / 2.0 + TAU * prog, 96, acc, 3.0, true)

	# hover 亮环
	if unlocked and _hover:
		draw_arc(c, 61.0, 0.0, TAU, 96, Color(acc, 0.55), 1.5, true)

	# 等宽序号
	var num := str(chapter_index + 1)
	var nsz := UI.fs(34)
	var nw := mf.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x
	var npos := c + Vector2(-nw * 0.5, nsz * 0.3)
	var ncol := Color(1, 1, 1, 0.92) if unlocked else Color(1, 1, 1, 0.35)
	draw_string(mf, npos, num, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz, ncol)

	# 锁定：小锁图标
	if not unlocked:
		_draw_lock(c + Vector2(0, 30), Color(1, 1, 1, 0.45))

	# 标题
	var title_col := UI.COL_TEXT if unlocked else Color(UI.COL_TEXT_DIM, 0.7)
	_center_text(f, chapter_title, NODE_W * 0.5, 168.0, 20, title_col)

	# 星星
	_draw_stars(NODE_W * 0.5, 194.0)

func _draw_lock(at: Vector2, col: Color) -> void:
	# 锁梁
	draw_arc(at + Vector2(0, -4), 5.0, PI, TAU, 20, col, 2.0, true)
	# 锁体
	draw_rect(Rect2(at + Vector2(-7, -4), Vector2(14, 10)), col, true)

func _draw_stars(cx: float, baseline_y: float) -> void:
	# 章节星级总数 = 关卡数 × 3，可能远超节点宽度；过多时改用紧凑读数，避免溢成一条长条
	if max_stars > 5:
		var col := UI.COL_ACCENT if unlocked else Color("#3c4a66")
		_center_text(UI.mono_font(), "★ %d / %d" % [stars, max_stars], cx, baseline_y, 18, col)
		return
	var sz := 20.0
	var gap := 5.0
	var total := max_stars * sz + maxi(0, max_stars - 1) * gap
	var x := cx - total * 0.5
	var top := baseline_y - sz
	for i in range(max_stars):
		var full := i < stars
		var tex := UI.icon("icon_star_full" if full else "icon_star_empty", int(sz),
			UI.COL_ACCENT if unlocked else Color("#3c4a66"))
		if tex != null:
			var mod := Color(1, 1, 1, 1) if unlocked else Color(0.5, 0.53, 0.62)
			draw_texture_rect(tex, Rect2(Vector2(x, top), Vector2(sz, sz)), false, mod)
		else:
			var f := UI.font()
			var txt := "★" if full else "☆"
			draw_string(f, Vector2(x, baseline_y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(sz),
				UI.COL_ACCENT if unlocked else Color("#3c4a66"))
		x += sz + gap

func _center_text(f: Font, text: String, cx: float, baseline_y: float, size_px: int, col: Color) -> void:
	var px := UI.fs(size_px)
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var pos := Vector2(cx - w * 0.5, baseline_y)
	draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(2, int(px * 0.22)), Color(0, 0, 0, 0.7))
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
