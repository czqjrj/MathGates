extends Control
## 世界地图 · 极简未来风：发丝路径 + 脉冲流动 + 科技环节点 + 玻璃关卡面板

const NODE_W := 180.0
const NODE_H := 200.0
const TOP_MARGIN := 170.0
const V_SPACING := 215.0
const BOTTOM_MARGIN := 220.0

class Pulse extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 13.0, Color("#5ee6ff", 0.10))
		draw_circle(c, 5.0, Color("#5ee6ff", 0.9))
		draw_circle(c, 2.2, Color(1, 1, 1, 0.95))

var _content: Control
var _scroll: ScrollContainer
var _panel_layer: CanvasLayer
var _star_lbl: Label
var _path_pts := PackedVector2Array()
var _pulse: Pulse
var _pulse_t: float = 0.0

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	if GameData.chapters.is_empty():
		var err := UI.make_label("推演数据未加载", 24, UI.COL_DANGER)
		err.position = Vector2(40, 40)
		add_child(err)
		return
	_build_topbar()
	_build_scroll()
	_build_map()
	_add_pet()
	GameData.progress_changed.connect(_build_map)
	set_process(true)

func _add_pet() -> void:
	Pet.spawn(self, "选一个区域，逐层解析命题吧～")

func _process(delta: float) -> void:
	if not UI.animations:
		return
	if _path_pts.size() < 2 or _pulse == null or not is_instance_valid(_pulse):
		return
	_pulse_t = fposmod(_pulse_t + delta * 0.05, 1.0)
	var idx := int(_pulse_t * (_path_pts.size() - 1))
	_pulse.position = _path_pts[idx] - Vector2(15, 15)

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
	hb.add_child(_hairline(Vector2(1, 18)))
	hb.add_child(UI.make_label("方法推演", 22))
	hb.add_child(UI.mono_label("METHOD SECTOR", 13, Color(UI.COL_TEXT_DIM, 0.7)))

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)

	_star_lbl = UI.mono_label("", 17, UI.COL_ACCENT)
	hb.add_child(_star_lbl)
	_refresh_topbar()

	hb.add_child(UI.ghost_button("重置推演", func() -> void:
		GameData.reset_progress()
		Toast.show_toast("推演档案已重置")
	, 14))

func _refresh_topbar() -> void:
	if _star_lbl != null:
		_star_lbl.text = "★ %d / %d" % [GameData.total_stars(), GameData.total_max_stars()]

# ---------------------------------------------------------------- 滚动区
func _build_scroll() -> void:
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = 64
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	UI.enable_touch_scroll(_scroll)
	UI.style_scrollbar(_scroll)

	_content = Control.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)

# ---------------------------------------------------------------- 地图
func _build_map() -> void:
	if _content == null:
		return
	for c in _content.get_children():
		c.queue_free()
	_path_pts = PackedVector2Array()
	_pulse = null

	# 方法推演地图:只显示专题方法实验体系("kind":"method")的章节,
	# 知识体系的章节在「知识体系」地图(TheoremTree)中,两边不混排。
	var vis: Array[int] = []
	for i in GameData.chapters.size():
		if GameData.chapter_kind(i) == "method":
			vis.append(i)
	var n := vis.size()
	var vp := get_viewport_rect().size
	var content_h := TOP_MARGIN + V_SPACING * maxi(0, n - 1) + BOTTOM_MARGIN
	_content.custom_minimum_size = Vector2(0, content_h)

	# 各章节中心点(蜿蜒 S 形)
	var centers := PackedVector2Array()
	for k in range(n):
		var x := vp.x * (0.5 + 0.24 * sin(k * PI * 0.5))
		var y := TOP_MARGIN + V_SPACING * k
		centers.append(Vector2(x, y))

	# 路径：暗底 + 青色辉光 + 亮芯
	var smooth := _catmull_rom(centers, 14)
	_path_pts = smooth
	_add_path(smooth, 16.0, Color(0, 0, 0, 0.45))
	_add_path(smooth, 6.0, Color(UI.COL_ACCENT, 0.14))
	_add_path(smooth, 2.0, Color(UI.COL_ACCENT, 0.5))

	# 沿路径流动的脉冲点
	_pulse = Pulse.new()
	_pulse.size = Vector2(30, 30)
	_pulse.custom_minimum_size = Vector2(30, 30)
	_content.add_child(_pulse)
	if smooth.size() > 0:
		_pulse.position = smooth[0] - Vector2(15, 15)

	# 章节节点（逐个从星点放大浮现，错峰入场）
	for k in range(n):
		var i := vis[k]
		var ch: Dictionary = GameData.chapters[i]
		var node := ChapterNode.new()
		node.chapter_index = i
		node.chapter_title = ch["title"]
		node.subtitle = ch.get("subtitle", "")
		node.color = Color(ch.get("color", "#5B8FF9"))
		node.unlocked = GameData.is_chapter_unlocked(i)
		node.stars = GameData.chapter_stars(ch)
		node.max_stars = GameData.chapter_max_stars(ch)
		node.size = Vector2(NODE_W, NODE_H)
		node.position = centers[k] - Vector2(NODE_W * 0.5, NODE_H * 0.5)
		node.selected.connect(_on_chapter_selected)
		_content.add_child(node)
		if UI.animations:
			node.modulate.a = 0.0
			node.scale = Vector2(0.4, 0.4)
			node.pivot_offset = node.size * 0.5
			var delay := 0.16 * float(k)
			var tw := node.create_tween().set_parallel(true)
			tw.tween_property(node, "modulate:a", 1.0, 0.3).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_property(node, "scale", Vector2.ONE, 0.42).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_refresh_topbar()
	# 方法推演入口若没有可进入的章节,给出提示
	if n == 0:
		_add_empty_hint()

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

# ---------------------------------------------------------------- 章节面板
func _on_chapter_selected(index: int) -> void:
	if not GameData.is_chapter_unlocked(index):
		Sound.play("error")
		Toast.show_toast("区域未解锁：请先完成前序推演")
		return
	Sound.play("select")
	_open_panel(index)

func _open_panel(index: int) -> void:
	_close_panel()
	var ch: Dictionary = GameData.chapters[index]

	_panel_layer = CanvasLayer.new()
	_panel_layer.layer = 50
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

	var panel := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.35), 14, 24, Color(UI.COL_ACCENT, 0.2))
	panel.custom_minimum_size = Vector2(624, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	# 标题行
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	vb.add_child(head)

	var bar := ColorRect.new()
	bar.color = Color(ch.get("color", "#5B8FF9"))
	bar.custom_minimum_size = Vector2(4, 24)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(bar)

	head.add_child(UI.make_label("%s" % ch["title"], 25, UI.COL_TEXT))
	head.add_child(UI.make_label(ch.get("subtitle", ""), 15, UI.COL_TEXT_DIM))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label("★ %d / %d" % [GameData.chapter_stars(ch), GameData.chapter_max_stars(ch)], 17, UI.COL_ACCENT))

	vb.add_child(_hairline(Vector2(0, 1)))

	# 关卡网格
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	vb.add_child(grid)

	var levels: Array = ch["levels"]
	for li in range(levels.size()):
		grid.add_child(_level_entry(index, li, levels[li], Color(ch.get("color", "#5B8FF9"))))

	UI.stagger_in(grid, 0.04, 0.26, 10)

	# 关闭
	var close_row := CenterContainer.new()
	vb.add_child(close_row)
	close_row.add_child(UI.ghost_button("关闭", _close_panel, 15))

	await get_tree().process_frame
	if _panel_layer != null and is_instance_valid(_panel_layer):
		UI.popup_in(panel)

func _level_entry(ch_i: int, li: int, lv: Dictionary, chapter_color: Color) -> Control:
	var unlocked := GameData.is_level_unlocked(ch_i, li)
	var s := int(GameData.stars.get(lv["id"], 0))

	var box := Control.new()
	box.custom_minimum_size = Vector2(272, 92)

	var fill := Color(1, 1, 1, 0.045) if unlocked else Color(0, 0, 0, 0.22)
	var border := Color(chapter_color, 0.5) if unlocked else Color(1, 1, 1, 0.07)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.glass_box(fill, 12, border, 1, 14))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(p)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)

	var name_col := UI.COL_TEXT if unlocked else Color(1, 1, 1, 0.35)
	vb.add_child(UI.make_label(str(lv["name"]), 17, name_col))

	var arch := str(lv.get("archetype", ""))
	var tech := str(lv.get("technique", ""))
	var sub := arch + (" · " if arch != "" and tech != "" else "") + tech
	if sub != "":
		vb.add_child(UI.mono_label(sub, 12, Color(UI.COL_TEXT_DIM, 0.85) if unlocked else Color(1, 1, 1, 0.25)))

	# 左侧章节色竖条
	var bar := ColorRect.new()
	bar.color = chapter_color if unlocked else Color(1, 1, 1, 0.15)
	bar.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	bar.offset_right = 3
	bar.offset_top = 8
	bar.offset_bottom = -8
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bar)

	# 右上角星级
	var star := UI.mono_label(_stars_str(s), 13,
		UI.COL_ACCENT if unlocked else Color(1, 1, 1, 0.25),
		HORIZONTAL_ALIGNMENT_RIGHT)
	star.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	star.offset_left = -92
	star.offset_right = -14
	star.offset_top = 10
	star.offset_bottom = 30
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(star)

	# 角标
	var mark_col := Color(chapter_color, 0.6) if unlocked else Color(1, 1, 1, 0.18)
	UI.corner_marks(box, 6, 10, 2, mark_col)

	# 覆盖热区按钮
	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.disabled = not unlocked
	btn.add_theme_stylebox_override("normal", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	btn.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.07), 12, Color(UI.COL_ACCENT, 0.55), 1, 0))
	btn.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.28), 12, Color(UI.COL_ACCENT, 0.8), 1, 0))
	btn.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, Color(UI.COL_ACCENT, 0.3), 1, 0))
	btn.add_theme_stylebox_override("disabled", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	if unlocked:
		btn.pressed.connect(func() -> void: _on_level_pressed(ch_i, li, lv))
	box.add_child(btn)
	return box

func _on_level_pressed(chapter_index: int, level_index: int, lv: Dictionary) -> void:
	if not GameData.start_level(chapter_index, level_index):
		Sound.play("error")
		Toast.show_toast("无法进入该推演节点")
		return
	Sound.play("begin")
	_close_panel()
	var target := str(lv.get("scene", "res://scenes/Battle.tscn"))
	Scene.goto(target)

func _close_panel() -> void:
	if _panel_layer != null and is_instance_valid(_panel_layer):
		_panel_layer.queue_free()
	_panel_layer = null

func _stars_str(s: int) -> String:
	return "★".repeat(s) + "☆".repeat(maxi(0, 3 - s))

func _add_empty_hint() -> void:
	var l := UI.make_label("暂无方法推演章节(curriculum 中未标记 kind=method)", 16, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, TOP_MARGIN)
	l.size = Vector2(get_viewport_rect().size.x, 28)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(l)

func _hairline(min_size: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.color = UI.COL_LINE
	r.custom_minimum_size = min_size
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if min_size.x <= 0.0:
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
