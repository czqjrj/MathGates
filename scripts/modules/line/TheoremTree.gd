extends Control
## 知识体系 · 地图方式：以「单元」为区域、知识点为地图节点，沿蜿蜒路径逐点点亮。
## 只展示知识体系章节(curriculum.json 中 "kind":"knowledge")；
## 方法推演(专题方法实验)在「方法推演」地图 WorldMap 中,两边不混排。
## 有独立 scene 的关卡走对应场景,其余进入通用战斗场景 Battle;新增章节只需写进 curriculum.json 即会自动出现。
## 顶部标签切换模块，点击节点弹出关卡面板进入。

## 各模块主题(单元)名，与关卡名 "N-M xxx" 的 N 对应(1 起)
const GROUP_TITLES := {
	"line_eq": ["倾斜角 · 斜率", "直线方程的四种形式", "平行与垂直", "距离公式", "直线系方程", "对称与最值"],
	"space":  ["空间向量基础", "方向向量 · 位置关系", "空间角", "距离问题", "三垂线 · 翻折", "球与最值"],
	"vector": ["基础本源", "共线与线性运算", "基底与坐标", "数量积与夹角", "投影与几何恒等式", "最值与范围"],
	"ellipse": ["椭圆定义与轨迹", "标准方程与几何性质", "焦半径与焦点三角形", "中点弦 · 点差法", "直线与椭圆 · 硬解定理"],
}

const NODE_W := 208.0
const NODE_H := 182.0
const BOSS_W := 240.0
const BOSS_H := 204.0
const TOP_MARGIN := 220.0
const ROW_H := 208.0
const BOTTOM_MARGIN := 240.0
const MIN_W := 1120.0

## 沿路径流动的脉冲点
class Pulse extends Control:
	var color := Color("#5ee6ff")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 14.0, Color(color, 0.10))
		draw_circle(c, 5.5, Color(color, 0.9))
		draw_circle(c, 2.4, Color(1, 1, 1, 0.95))

## 地图上的知识点节点：科技环形节点(细环 + 进度弧 + 等宽编号)
class MapNode extends Control:
	signal activated

	var li := -1
	var code := ""
	var title := ""
	var sub := ""
	var color := Color("#5B8FF9")
	var unlocked := true
	var stars := 0
	var max_stars := 3
	var is_boss := false

	var _hover := false
	var _t := 0.0

	var _press := false
	var _press_pos := Vector2.ZERO
	var _press_scroll := 0.0

	func _ready() -> void:
		# PASS:让触摸拖动穿透到外层 ScrollContainer,手机上才能上下滑动
		mouse_filter = Control.MOUSE_FILTER_PASS
		custom_minimum_size = size
		mouse_entered.connect(func() -> void: _hover = true; queue_redraw())
		mouse_exited.connect(func() -> void: _hover = false; queue_redraw())
		set_process(true)

	func _scroll_v() -> float:
		var n := get_parent()
		while n != null:
			if n is ScrollContainer:
				return (n as ScrollContainer).scroll_vertical
			n = n.get_parent()
		return 0.0

	func _process(delta: float) -> void:
		if not UI.animations:
			return
		_t += delta
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		# 在「抬起且未拖动/未滚屏」时才激活,避免滑动地图时误进关卡;
		# 不 accept_event(),让事件继续传到 ScrollContainer 以支持触摸滚动。
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
					activated.emit()

	func _draw() -> void:
		var f := UI.font()
		var mf := UI.mono_font()
		var cx := size.x * 0.5
		var cy := 54.0 + sin(_t * 1.5 + float(li)) * 3.0
		var R := 54.0 if is_boss else 46.0
		var base_col := color
		if not unlocked:
			base_col = Color("#4a4f63")

		if unlocked and _hover:
			draw_circle(Vector2(cx, cy), R + 16.0, Color(UI.COL_ACCENT.r, UI.COL_ACCENT.g, UI.COL_ACCENT.b, 0.10))

		draw_circle(Vector2(cx, cy), R, Color(0.05, 0.07, 0.12, 0.82))
		draw_arc(Vector2(cx, cy), R, 0.0, TAU, 64, Color(base_col, 0.75 if unlocked else 0.30), 2.4, true)

		var prog := 0.0
		if max_stars > 0:
			prog = clampf(float(stars) / float(max_stars), 0.0, 1.0)
		if unlocked and prog > 0.001:
			draw_arc(Vector2(cx, cy), R, -PI / 2.0, -PI / 2.0 + TAU * prog, 64, UI.COL_ACCENT, 3.0, true)

		if unlocked and _hover:
			draw_arc(Vector2(cx, cy), R + 5.0, 0.0, TAU, 64, Color(UI.COL_ACCENT, 0.55), 1.5, true)

		if is_boss and unlocked:
			var ph := 0.5 + 0.5 * sin(_t * 3.0)
			draw_arc(Vector2(cx, cy), R + ph * 14.0, 0.0, TAU, 48, Color(1.0, 0.45, 0.52, 0.4 * (1.0 - ph)), 2.0, true)

		var num_col := Color(1, 1, 1, 0.94) if unlocked else Color(1, 1, 1, 0.40)
		_center(mf, code, cx, cy + 10.0, 26, num_col)
		if is_boss:
			_center(mf, "BOSS", cx, cy - R - 8.0, 11, Color("#fb7185", 0.95))

		if not unlocked:
			_draw_lock(Vector2(cx + R - 14.0, cy - R + 8.0), Color(1, 1, 1, 0.5))

		var tcol := UI.COL_TEXT if unlocked else Color(UI.COL_TEXT_DIM, 0.75)
		_center(f, title, cx, cy + R + 24.0, 16, tcol)
		if sub != "":
			_center(mf, sub, cx, cy + R + 42.0, 11, Color(UI.COL_TEXT_DIM, 0.85))
		_draw_stars(cx, size.y - 12.0)

	func _draw_lock(at: Vector2, col: Color) -> void:
		draw_arc(at + Vector2(0, -4), 5.0, PI, TAU, 20, col, 2.0, true)
		draw_rect(Rect2(at + Vector2(-7, -4), Vector2(14, 10)), col, true)

	func _draw_stars(cx: float, baseline_y: float) -> void:
		var sz := 16.0
		var gap := 4.0
		var total := 3.0 * sz + 2.0 * gap
		var x := cx - total * 0.5
		var top := baseline_y - sz
		for i in 3:
			var full := i < stars
			var tex := UI.icon("icon_star_full" if full else "icon_star_empty", int(sz),
				UI.COL_ACCENT if unlocked else Color("#3c4a66"))
			if tex != null:
				var mod := Color(1, 1, 1, 1) if unlocked else Color(0.5, 0.53, 0.62)
				draw_texture_rect(tex, Rect2(Vector2(x, top), Vector2(sz, sz)), false, mod)
			else:
				var f := UI.font()
				draw_string(f, Vector2(x, baseline_y), "★" if full else "☆",
					HORIZONTAL_ALIGNMENT_LEFT, -1, int(UI.fs(int(sz))),
					UI.COL_ACCENT if full else Color("#3c4a66"))
			x += sz + gap

	func _center(f: Font, text: String, cx: float, by: float, size_px: int, col: Color) -> void:
		var px := UI.fs(size_px)
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var pos := Vector2(cx - w * 0.5, by)
		draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(2, int(px * 0.22)), Color(0, 0, 0, 0.7))
		draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

## 章节卡片：卡片化外观 + 可拖拽排序 + 悬停/呼吸动画。
class TabCard extends Control:
	var owner_tree: Control
	var mi := 0
	var num := 0
	var title := ""
	var color := Color("#5B8FF9")
	var active := false
	var locked := false
	var stars := 0
	var max_stars := 0

	var _hover := false
	var _t := 0.0
	var _drag_begun := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(func() -> void: pivot_offset = size * 0.5)
		mouse_entered.connect(func() -> void: _hover = true; _lift(true))
		mouse_exited.connect(func() -> void: _hover = false; _lift(false))
		set_process(true)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_DRAG_BEGIN:
			_drag_begun = true
		elif what == NOTIFICATION_DRAG_END:
			_drag_begun = false

	func _process(delta: float) -> void:
		if not UI.animations:
			return
		_t += delta
		if active:
			queue_redraw()

	func _lift(on: bool) -> void:
		var target := Vector2(1.045, 1.045) if on else Vector2.ONE
		if not UI.animations:
			scale = target
			return
		pivot_offset = size * 0.5
		var tw := create_tween()
		tw.tween_property(self, "scale", target, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_drag_begun = false
				elif not _drag_begun:
					owner_tree.call("_select_module", mi)
					accept_event()

	# 拖拽排序：整张卡片可作为拖拽源/放置目标
	func _get_drag_data(_at: Vector2) -> Variant:
		_drag_begun = true
		var pv := PanelContainer.new()
		pv.add_theme_stylebox_override("panel", UI.glass_box(Color(color, 0.4), 10, color, 2, 14))
		var l := UI.make_label(title, 16, UI.COL_TEXT)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv.add_child(l)
		pv.custom_minimum_size = Vector2(150, 42)
		set_drag_preview(pv)
		return { "type": "chapter_tab", "mi": mi }

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and str((data as Dictionary).get("type", "")) == "chapter_tab"

	func _drop_data(_at: Vector2, data: Variant) -> void:
		owner_tree.call("_reorder_cards", int((data as Dictionary).get("mi", mi)), mi)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var accent := color if not locked else Color(0.42, 0.45, 0.52)

		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(14)
		sb.set_border_width_all(2 if active else 1)
		if locked:
			sb.bg_color = Color(0.13, 0.15, 0.2, 0.62)
			sb.border_color = Color(1, 1, 1, 0.10)
		elif active:
			sb.bg_color = Color(color.r, color.g, color.b, 0.20)
			sb.border_color = Color(color.r, color.g, color.b, 0.9)
			var pulse := 0.5 + 0.5 * sin(_t * 2.6)
			sb.shadow_color = Color(color.r, color.g, color.b, 0.18 + 0.22 * pulse)
			sb.shadow_size = int(8 + 6 * pulse)
			sb.shadow_offset = Vector2.ZERO
		else:
			sb.bg_color = Color(1, 1, 1, 0.09 if _hover else 0.05)
			sb.border_color = Color(1, 1, 1, 0.28 if _hover else 0.14)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))

		# 左侧色条
		draw_rect(Rect2(0, 14, 4, h - 28), accent, true)

		var mf := UI.mono_font()
		# 章节编号
		draw_string(mf, Vector2(16, 30), "%02d" % num, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(15), Color(accent, 0.95))
		# 状态标
		if active:
			draw_string(UI.font(), Vector2(w - 76, 30), "正在学习", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(13), Color(color, 0.98))
		elif locked:
			draw_string(UI.font(), Vector2(w - 58, 30), "未解锁", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(12), Color(1, 1, 1, 0.4))
		else:
			draw_string(UI.font(), Vector2(w - 58, 30), "已解锁", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(11), Color(UI.COL_TEXT_DIM, 0.7))
		# 标题
		var tcol := UI.COL_TEXT if not locked else Color(UI.COL_TEXT_DIM, 0.7)
		draw_string(UI.font(), Vector2(16, 58), title, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(18), tcol)
		# 星数
		draw_string(mf, Vector2(16, h - 18), "★ %d / %d" % [stars, max_stars], HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(12), Color(UI.COL_TEXT_DIM, 0.95))
		# 进度条
		var bar := Rect2(16, h - 10, w - 32, 6)
		draw_rect(bar, Color(0, 0, 0, 0.35), true)
		var ratio := 0.0
		if max_stars > 0:
			ratio = clampf(float(stars) / float(max_stars), 0.0, 1.0)
		if ratio > 0.001:
			var fb := StyleBoxFlat.new()
			fb.bg_color = accent
			fb.set_corner_radius_all(4)
			draw_style_box(fb, Rect2(bar.position, Vector2(maxf(bar.size.x * ratio, 4.0), bar.size.y)))

		# 拖拽把手
		for k in 3:
			draw_circle(Vector2(w - 16, h * 0.5 - 10 + k * 10), 1.8, Color(1, 1, 1, 0.4))

var _star_lbl: Label
var _module_idx := 0
var _tabs: HBoxContainer
var _tab_scroll: ScrollContainer
var _content: Control
var _scroll: ScrollContainer
var _panel_layer: CanvasLayer
var _mods: Array = []
var _levels: Array = []
var _groups: Array = []
var _mod_col := Color.WHITE
var _chapter_index := -1
var _path_pts := PackedVector2Array()
var _pulse: Pulse
var _pulse_t := 0.0

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build_modules()
	# 从某关返回时,默认定位到该关卡所属章节(按 id 定位,顺序可能被拖拽重排过)
	var ci := GameData.last_chapter_index()
	if ci >= 0 and ci < GameData.chapters.size():
		var cid := str(GameData.chapters[ci].get("id", ""))
		_module_idx = maxi(0, _find_module(cid))
	_build_topbar()
	if GameData.chapters.is_empty():
		return
	_build_scroll()
	_build_map(true)
	Pet.spawn(self, "沿地图路径逐点点亮知识点吧！")
	GameData.progress_changed.connect(_on_progress)
	set_process(true)

func _on_progress() -> void:
	_refresh_star()
	_rebuild_tabs()
	_build_map(false)

func _process(delta: float) -> void:
	if not UI.animations:
		return
	if _path_pts.size() < 2 or _pulse == null or not is_instance_valid(_pulse):
		return
	_pulse_t = fposmod(_pulse_t + delta * 0.05, 1.0)
	var idx := int(_pulse_t * float(_path_pts.size() - 1))
	_pulse.position = _path_pts[idx] - Vector2(15, 15)



func _chapter_index_of(module_id: String) -> int:
	for i in GameData.chapters.size():
		if str(GameData.chapters[i].get("id", "")) == module_id:
			return i
	return -1

## 由课程表生成知识体系各模块(高中数学各章节),新增章节无需改代码。
## 顺序：自定义拖拽顺序优先；随后把「正在学习」的章节提到最前。
func _build_modules() -> void:
	_mods.clear()
	for ci in GameData.chapters.size():
		var ch: Dictionary = GameData.chapters[ci]
		if GameData.chapter_kind(ci) != "knowledge":
			continue
		_mods.append({
			"id": str(ch.get("id", "")),
			"title": str(ch.get("title", "")),
			"color": str(ch.get("color", "#5B8FF9")),
		})
	_apply_saved_order()
	_move_current_to_front()

## 按存档里的自定义顺序重排(未列出的章节按原顺序补在后面)
func _apply_saved_order() -> void:
	var order: Array = GameData.chapter_order
	if order.is_empty():
		return
	var by_id: Dictionary = {}
	for m in _mods:
		by_id[str(m["id"])] = m
	var out: Array = []
	for id in order:
		var key := str(id)
		if by_id.has(key):
			out.append(by_id[key])
			by_id.erase(key)
	for m in _mods:
		if by_id.has(str(m["id"])):
			out.append(m)
	_mods = out

## 把当前正在学习的章节卡片移到最前面
func _move_current_to_front() -> void:
	var ci := GameData.last_chapter_index()
	if ci < 0 or ci >= GameData.chapters.size():
		return
	var cid := str(GameData.chapters[ci].get("id", ""))
	for i in _mods.size():
		if str(_mods[i]["id"]) == cid:
			var m = _mods[i]
			_mods.remove_at(i)
			_mods.insert(0, m)
			return

func _find_module(id: String) -> int:
	for i in _mods.size():
		if str(_mods[i]["id"]) == id:
			return i
	return -1

# ---------------------------------------------------------------- 顶栏
func _build_topbar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.topbar_box())
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 64)
	bar.offset_bottom = 64
	add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	bar.add_child(hb)
	hb.add_child(UI.ghost_button("← 返回终端", func() -> void:
		Scene.goto("res://scenes/MainHub.tscn")
	))
	hb.add_child(UI.hairline(Vector2(1, 18)))
	hb.add_child(UI.make_label("知识体系", 22))
	hb.add_child(UI.mono_label("KNOWLEDGE MAP", 13, Color(UI.COL_TEXT_DIM, 0.7)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_star_lbl = UI.mono_label("", 17, UI.COL_ACCENT)
	hb.add_child(_star_lbl)
	_refresh_star()

	# 模块切换标签(固定在导图上方工具条):左右箭头翻页 + 可横向滑动,兼容鼠标与触摸
	var tab_bar := PanelContainer.new()
	tab_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tab_bar.offset_top = 64
	tab_bar.offset_bottom = 176
	tab_bar.add_theme_stylebox_override("panel", UI.glass_box(Color(0.03, 0.05, 0.09, 0.85), 0, Color(UI.COL_ACCENT, 0.2), 1, 8))
	tab_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(tab_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	tab_bar.add_child(row)
	row.add_child(_tab_arrow(-1))
	_tab_scroll = ScrollContainer.new()
	_tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_tab_scroll)
	row.add_child(_tab_arrow(1))
	_tabs = HBoxContainer.new()
	_tabs.alignment = BoxContainer.ALIGNMENT_BEGIN
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tabs.add_theme_constant_override("separation", 12)
	_tab_scroll.add_child(_tabs)
	# 说明：标签条不接管触摸拖动(交给卡片拖拽),横向浏览用左右箭头或鼠标滚轮。
	_rebuild_tabs()

## 翻页箭头:手机无鼠标滚轮,靠它切换被遮住的章节标签
func _tab_arrow(dir: int) -> Button:
	var b := UI.ghost_button("◀" if dir < 0 else "▶", func() -> void: _scroll_tabs(dir), 18)
	b.custom_minimum_size = Vector2(46, 0)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return b

func _scroll_tabs(dir: int) -> void:
	if _tab_scroll == null:
		return
	var page := maxf(_tab_scroll.size.x * 0.7, 220.0)
	_tab_scroll.scroll_horizontal = int(maxf(0.0, float(_tab_scroll.scroll_horizontal) + dir * page))

func _rebuild_tabs() -> void:
	for c in _tabs.get_children():
		c.queue_free()
	for mi in _mods.size():
		_tabs.add_child(_tab_card(mi))
	_tab_entrance()
	# 让当前选中的章节卡片自动滚动到可见位置
	if _tab_scroll != null and _module_idx >= 0 and _module_idx < _tabs.get_child_count():
		_tab_scroll.call_deferred("ensure_control_visible", _tabs.get_child(_module_idx))

## 把某章做成一张可拖拽的卡片(状态: 正在学习 / 已解锁 / 未解锁)
func _tab_card(mi: int) -> Control:
	var mod: Dictionary = _mods[mi]
	var card := TabCard.new()
	card.owner_tree = self
	card.mi = mi
	card.title = str(mod["title"])
	card.color = Color(str(mod["color"]))
	card.active = mi == _module_idx
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ci := _chapter_index_of(str(mod["id"]))
	if ci >= 0:
		card.num = ci + 1
		card.locked = not GameData.is_chapter_unlocked(ci)
		card.stars = GameData.chapter_stars(GameData.chapters[ci])
		card.max_stars = GameData.chapter_max_stars(GameData.chapters[ci])
	card.custom_minimum_size = Vector2(210, 96)
	card.size = Vector2(210, 96)
	return card

## 选中某章(切换地图)
func _select_module(mi: int) -> void:
	if mi < 0 or mi >= _mods.size() or mi == _module_idx:
		return
	_module_idx = mi
	Sound.play("select")
	_rebuild_tabs()
	_build_map(true)

## 卡片拖拽排序：把 from 位置的章节移动到 to 位置，并持久化顺序。
func _reorder_cards(from_mi: int, to_mi: int) -> void:
	if from_mi == to_mi or from_mi < 0 or from_mi >= _mods.size() or to_mi < 0 or to_mi >= _mods.size():
		return
	var selected_id := ""
	if _module_idx >= 0 and _module_idx < _mods.size():
		selected_id = str(_mods[_module_idx]["id"])
	var m = _mods[from_mi]
	_mods.remove_at(from_mi)
	_mods.insert(to_mi, m)
	var ids: Array = []
	for x in _mods:
		ids.append(str(x["id"]))
	GameData.set_chapter_order(ids)
	_module_idx = maxi(0, _find_module(selected_id))
	Sound.play("click")
	_rebuild_tabs()

## 卡片入场动画：轻微缩放 + 淡入，依次错峰
func _tab_entrance() -> void:
	if not UI.animations:
		return
	var i := 0
	for c in _tabs.get_children():
		if not (c is Control):
			continue
		var ctl := c as Control
		ctl.modulate.a = 0.0
		ctl.scale = Vector2(0.9, 0.9)
		ctl.pivot_offset = ctl.custom_minimum_size * 0.5
		var d := 0.03 * float(mini(i, 12))
		var tw := ctl.create_tween().set_parallel(true)
		tw.tween_property(ctl, "modulate:a", 1.0, 0.24).set_delay(d)
		tw.tween_property(ctl, "scale", Vector2.ONE, 0.34).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1

func _refresh_star() -> void:
	if _star_lbl != null:
		_star_lbl.text = "★ %d / %d" % [GameData.total_stars(), GameData.total_max_stars()]

# ---------------------------------------------------------------- 滚动区
func _build_scroll() -> void:
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = 176
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll)
	_content = Control.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(_content)
	UI.enable_touch_scroll(_scroll)
	UI.style_scrollbar(_scroll)

# ---------------------------------------------------------------- 地图
func _build_map(recenter_map: bool) -> void:
	if _content == null:
		return
	for c in _content.get_children():
		c.queue_free()
	_path_pts = PackedVector2Array()
	_pulse = null

	var mod: Dictionary = _mods[_module_idx]
	_mod_col = Color(str(mod["color"]))
	_chapter_index = _chapter_index_of(str(mod["id"]))
	if _chapter_index < 0:
		return
	_levels = GameData.chapters[_chapter_index]["levels"]
	_groups = _disasm_groups()

	var vp := get_viewport_rect().size
	var content_w := maxf(MIN_W, vp.x)
	var pad := clampf(content_w * 0.12, 96.0, 220.0)
	var rows := _groups.size()
	var content_h := TOP_MARGIN + maxf(0.0, float(rows - 1)) * ROW_H + BOTTOM_MARGIN
	_content.custom_minimum_size = Vector2(content_w, content_h)

	var tip := UI.mono_label("地图：沿单元路径逐点点亮知识点", 13, Color(UI.COL_TEXT_DIM, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	tip.position = Vector2(0, 76)
	tip.size = Vector2(content_w, 20)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(tip)

	var centers := PackedVector2Array()
	var infos: Array = []
	for gi in _groups.size():
		var g: Dictionary = _groups[gi]
		var items: Array = g["items"]
		var m := items.size()
		var y := TOP_MARGIN + float(gi) * ROW_H
		var reverse := (gi % 2) == 1
		_content.add_child(_unit_header(g, gi, content_w, y))
		for j in m:
			var it: Dictionary = items[j]
			var t := (float(j) + 1.0) / (float(m) + 1.0)
			if reverse:
				t = 1.0 - t
			var x := pad + t * (content_w - 2.0 * pad)
			centers.append(Vector2(x, y))
			infos.append({ "c": Vector2(x, y), "it": it, "boss": bool(g.get("boss", false)) })

	if centers.size() >= 2:
		var smooth := _catmull_rom(centers, 12)
		_path_pts = smooth
		_add_path(smooth, 18.0, Color(0, 0, 0, 0.42))
		_add_path(smooth, 7.0, Color(_mod_col, 0.16))
		_add_path(smooth, 2.2, Color(_mod_col, 0.55))
		var flag := Pulse.new()
		flag.color = _mod_col
		flag.size = Vector2(30, 30)
		flag.custom_minimum_size = Vector2(30, 30)
		_content.add_child(flag)
		flag.position = smooth[0] - Vector2(15, 15)
		_pulse = flag

	for info in infos:
		var c0: Vector2 = info["c"]
		var it0: Dictionary = info["it"]
		_add_level_node(c0, it0, int(it0["li"]), bool(info["boss"]))

	if UI.animations and recenter_map:
		_stagger_entrance(_content)

	_refresh_star()
	if recenter_map:
		_recenter()

func _unit_header(g: Dictionary, gi: int, content_w: float, y: float) -> Control:
	var boss := bool(g.get("boss", false))
	var title := str(g["title"])
	var prefix := "HIDDEN BOSS · " if boss else "UNIT %02d · " % (gi + 1)
	var col := Color("#fb7185") if boss else _mod_col
	var l := UI.mono_label(prefix + title, 15, Color(col, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, y - NODE_H * 0.5 - 30.0)
	l.size = Vector2(content_w, 22)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_meta("unit_label", true)
	return l

func _add_level_node(c: Vector2, it: Dictionary, li: int, boss: bool) -> void:
	var n := MapNode.new()
	n.li = li
	n.is_boss = boss
	n.code = str(it["code"])
	n.title = str(it["title"])
	n.sub = str(it["technique"])
	n.color = _mod_col
	n.unlocked = _level_unlocked(li)
	n.stars = int(GameData.stars.get(str(_levels[li]["id"]), 0))
	n.max_stars = 3
	var w := NODE_W
	var h := NODE_H
	if boss:
		w = BOSS_W
		h = BOSS_H
	n.size = Vector2(w, h)
	n.position = c - Vector2(w * 0.5, h * 0.5)
	n.activated.connect(func() -> void: _on_node_selected(li))
	_content.add_child(n)

## 知识点节点/单元标题逐个浮现（先轻微缩小淡入，再弹回原位）。
## 若刷新前后节点数一致，尽量让同一节点的旧位置不动（新增节点错峰补入）。
func _stagger_entrance(container: Control) -> void:
	var i := 0
	for c in container.get_children():
		if not (c is Control):
			continue
		if not (c is MapNode or (c as Control).has_meta("unit_label")):
			continue
		var ctl := c as Control
		if ctl.is_queued_for_deletion():
			continue
		ctl.pivot_offset = ctl.size * 0.5
		ctl.modulate.a = 0.0
		ctl.scale = Vector2(0.35, 0.35)
		var delay := 0.05 * float(i)
		var tw := ctl.create_tween().set_parallel(true)
		tw.tween_property(ctl, "modulate:a", 1.0, 0.28).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(ctl, "scale", Vector2.ONE, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1

func _add_path(points: PackedVector2Array, width: float, color: Color) -> void:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	_content.add_child(line)

func _catmull_rom(pts: PackedVector2Array, per_seg: int) -> PackedVector2Array:
	if pts.size() < 2:
		return pts
	var ext := PackedVector2Array()
	ext.append(pts[0])
	ext.append_array(pts)
	ext.append(pts[pts.size() - 1])
	var out := PackedVector2Array()
	for i in range(1, ext.size() - 2):
		var p0 := ext[i - 1]
		var p1 := ext[i]
		var p2 := ext[i + 1]
		var p3 := ext[i + 2]
		for s in range(per_seg):
			var t := float(s) / float(per_seg)
			var t2 := t * t
			var t3 := t2 * t
			var p := 0.5 * (
				(2.0 * p1)
				+ (-p0 + p2) * t
				+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			out.append(p)
	out.append(pts[pts.size() - 1])
	return out

func _recenter() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _scroll == null:
		return
	_scroll.scroll_horizontal = 0
	_scroll.scroll_vertical = 0

func _disasm_groups() -> Array:
	var gmap: Dictionary = {}
	var order: Array = []
	for li in _levels.size():
		var nm := str(_levels[li].get("name", ""))
		var is_boss := nm.contains("Boss") or nm.contains("隐藏")
		var key := ""
		var code := ""
		if is_boss:
			key = "b"
			code = "BOSS"
		else:
			# 关卡名形如 "1-2 平行判定" 时用 "1-2" 作节点编号并按单元分组;
			# 否则(如"集合的交并补")用顺序号,避免整段标题塞进节点圆环。
			var parts := nm.split(" ", false)
			var first := parts[0] if parts.size() > 0 else ""
			var np := first.split("-", false)
			if np.size() == 2 and np[0].is_valid_int() and np[1].is_valid_int():
				code = first
				key = str(int(np[0]) - 1)
			else:
				code = "%02d" % (li + 1)
				key = "0"
		if not gmap.has(key):
			gmap[key] = { "items": [] }
			order.append(key)
		var item_title := str(nm)
		if is_boss:
			item_title = nm.replace("隐藏Boss · ", "").strip_edges()
		gmap[key]["items"].append({
			"li": li, "code": code,
			"title": item_title,
			"technique": str(_levels[li].get("technique", "")),
		})

	var group_names: Array = GROUP_TITLES.get(str(_mods[_module_idx]["id"]), [])
	var out: Array = []
	for key in order:
		var boss: bool = key == "b"
		var title := "隐藏挑战"
		if not boss:
			var gidx := int(key)
			if gidx < group_names.size():
				title = str(group_names[gidx])
			elif order.size() == 1:
				title = str(_mods[_module_idx]["title"])
			else:
				title = "单元 %d" % (gidx + 1)
		out.append({ "title": title, "boss": boss, "items": gmap[key]["items"] })
	return out

# ---------------------------------------------------------------- 解锁与面板
func _level_unlocked(li: int) -> bool:
	if li <= 0:
		return true
	if li - 1 >= _levels.size():
		return false
	return int(GameData.stars.get(_levels[li - 1]["id"], 0)) >= 1

func _on_node_selected(li: int) -> void:
	if not _level_unlocked(li):
		Sound.play("error")
		Toast.show_toast("尚未解锁：先通关上一节点")
		return
	Sound.play("select")
	_open_panel(li)

func _open_panel(li: int) -> void:
	_close_panel()
	var lv: Dictionary = _levels[li]
	var mod: Dictionary = _mods[_module_idx]
	var col := Color(str(mod["color"]))

	_panel_layer = CanvasLayer.new()
	_panel_layer.layer = UiConst.LAYER_PANEL
	add_child(_panel_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.full_rect(dim)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_panel()
	)
	_panel_layer.add_child(dim)

	var center := CenterContainer.new()
	UI.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_layer.add_child(center)

	var panel := UI.card(true, col, UI.COL_GLASS, Color(col, 0.4), 14, 26)
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	vb.add_child(head)
	var bar := ColorRect.new()
	bar.color = col
	bar.custom_minimum_size = Vector2(4, 24)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(bar)
	head.add_child(UI.make_label(str(lv["name"]), 25, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label(_stars_str(int(GameData.stars.get(lv["id"], 0))), 17, UI.COL_ACCENT))

	vb.add_child(UI.hairline(Vector2(0, 1)))
	vb.add_child(UI.mono_label("%s · %s" % [str(mod["title"]), str(lv.get("technique", ""))], 14, UI.COL_TEXT_DIM))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vb.add_child(row)
	row.add_child(UI.ghost_button("关闭", _close_panel, 16))
	var enter := Button.new()
	enter.text = "进入推演 →"
	enter.custom_minimum_size = Vector2(200, 54)
	UI.primary_button(enter)
	enter.pressed.connect(func() -> void: _enter(li))
	row.add_child(enter)

	await get_tree().process_frame
	if _panel_layer != null and is_instance_valid(_panel_layer):
		UI.popup_in(panel)

func _enter(li: int) -> void:
	if not GameData.start_level(_chapter_index, li):
		Sound.play("error")
		Toast.show_toast("无法进入该节点")
		return
	Sound.play("begin")
	_close_panel()
	Scene.goto(str(_levels[li].get("scene", "res://scenes/Battle.tscn")))

func _close_panel() -> void:
	if _panel_layer != null and is_instance_valid(_panel_layer):
		_panel_layer.queue_free()
	_panel_layer = null

## 返回键：若关卡面板开着，先关面板；否则返回 false 让全局回退到上一场景
func _on_back_requested() -> bool:
	if _panel_layer != null and is_instance_valid(_panel_layer):
		_close_panel()
		return true
	return false

func _stars_str(s: int) -> String:
	return "★".repeat(s) + "☆".repeat(maxi(0, 3 - s))
