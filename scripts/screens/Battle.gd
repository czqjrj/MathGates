extends Control
## 战斗场景 · 极简未来风：六边形头像 + 分段能量条 + 徽章选项 + 玻璃结算

class HexAvatar extends Control:
	var letter := "?"
	var col := Color("#5ee6ff")
	var fs := 30

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 3.0
		if r <= 1.0:
			return
		var pts := PackedVector2Array()
		for i in range(6):
			var a := -PI / 2.0 + float(i) * TAU / 6.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Color(0.05, 0.07, 0.12, 0.78))
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(col, 0.85), 2.0, true)
		var inner := PackedVector2Array()
		for i in range(6):
			var a := -PI / 2.0 + float(i) * TAU / 6.0
			inner.append(c + Vector2(cos(a), sin(a)) * (r * 0.8))
		inner.append(inner[0])
		draw_polyline(inner, Color(col, 0.22), 1.0, true)
		var f := UI.font()
		var w := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, c + Vector2(-w * 0.5, fs * 0.35), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.COL_TEXT)

class HpBar extends Control:
	var value := 5
	var max_value := 5

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func set_hp(v: int) -> void:
		value = v
		queue_redraw()

	func _draw() -> void:
		var track := StyleBoxFlat.new()
		track.bg_color = Color(0, 0, 0, 0.4)
		track.set_corner_radius_all(4)
		track.set_border_width_all(1)
		track.border_color = Color(1, 1, 1, 0.16)
		draw_style_box(track, Rect2(Vector2.ZERO, size))

		var ratio := clampf(float(value) / float(maxi(1, max_value)), 0.0, 1.0)
		if ratio > 0.01:
			var hot := ratio <= 0.34
			var fc: Color = UI.COL_DANGER if hot else UI.COL_ACCENT
			var fill := StyleBoxFlat.new()
			fill.bg_color = fc
			fill.set_corner_radius_all(4)
			fill.shadow_color = Color(fc, 0.5)
			fill.shadow_size = 12
			fill.shadow_offset = Vector2.ZERO
			draw_style_box(fill, Rect2(Vector2(2, 2), Vector2(maxf((size.x - 4.0) * ratio, 1.0), size.y - 4.0)))

		if max_value > 1:
			for i in range(1, max_value):
				var x := size.x * float(i) / float(max_value)
				draw_rect(Rect2(x - 1.0, 6.0, 2.0, size.y - 12.0), Color(0, 0, 0, 0.5))

const CHOICE_FORMULA_SCALE := UI.CHOICE_FORMULA_SCALE

var _level: Dictionary = {}
var _questions: Array = []
var _idx: int = 0
var _correct: int = 0
var _answered: bool = false

var _top_fill: ColorRect
var _prog_lbl: Label
var _hud_lbl: Label
var _q_lbl: Label
var _opts_box: VBoxContainer
var _rows: Array[Control] = []
var _btns: Array[Button] = []
var _panels: Array[PanelContainer] = []
var _badges: Array[PanelContainer] = []
var _contents: Array[Control] = []
var _texts: Array[String] = []
var _explain_panel: PanelContainer
var _explain_lbl: Label
var _next_btn: Button
var _hp: HpBar

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	Pet.spawn(self, "先审题，再选答案！")
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.02, 0.05, 0.32)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	UI.full_rect(veil)

	_level = GameData.current_level
	_questions = GameData.questions_for(GameData.current_level_id())
	_build_topbar()
	_build_topline()
	if _questions.is_empty():
		_build_empty()
	else:
		_build_ui()
		_load_question()

# ---------------------------------------------------------------- 顶部进度线
func _build_topline() -> void:
	var tl := Control.new()
	tl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tl.offset_bottom = 3
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tl)

	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.07)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(track)
	tl.add_child(track)

	_top_fill = ColorRect.new()
	_top_fill.color = UI.COL_ACCENT
	_top_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top_fill.anchor_right = 0.0
	tl.add_child(_top_fill)

func _set_top_progress(ratio: float) -> void:
	if _top_fill == null or not is_instance_valid(_top_fill):
		return
	var tw := create_tween()
	tw.tween_property(_top_fill, "anchor_right", clampf(ratio, 0.0, 1.0), 0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------- 顶栏
func _build_topbar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.topbar_box())
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 66)
	bar.offset_bottom = 66
	add_child(bar)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	bar.add_child(hb)

	hb.add_child(UI.ghost_button("← 返回区域", func() -> void:
		Scene.goto("res://scenes/WorldMap.tscn")
	))
	hb.add_child(_hairline(Vector2(1, 18)))
	hb.add_child(UI.make_label(str(_level.get("name", "推演节点")), 22))

	var arch := str(_level.get("archetype", ""))
	var tech := str(_level.get("technique", ""))
	if arch != "" or tech != "":
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel",
			UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(UI.COL_ACCENT, 0.3), 1, 10))
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ct := arch + (" · " if arch != "" and tech != "" else "") + tech
		var cl := UI.mono_label(ct, 13, Color(UI.COL_ACCENT, 0.85))
		cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.add_child(cl)
		hb.add_child(chip)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)

	_prog_lbl = UI.mono_label("Q 00 / 00", 17, UI.COL_ACCENT)
	_prog_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_prog_lbl)

# ---------------------------------------------------------------- 主界面
func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 66
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel())
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	# 对战区：玩家 ↔ 能量条 ↔ 守关者
	var arena := HBoxContainer.new()
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 18)
	vb.add_child(arena)
	arena.add_child(_hex_avatar("推", UI.COL_ACCENT, 84))

	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 8)
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(mid)
	mid.add_child(UI.mono_label("VERIFIER // 校验体", 13, Color(UI.COL_ACCENT, 0.85), HORIZONTAL_ALIGNMENT_CENTER))
	mid.add_child(_make_hp_bar())
	_hud_lbl = UI.mono_label("", 15, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	mid.add_child(_hud_lbl)

	arena.add_child(_hex_avatar("验", UI.COL_DANGER, 84))

	# 题干卡
	var qcard := UI.card(true, UI.COL_ACCENT, Color(1, 1, 1, 0.045), Color(UI.COL_ACCENT, 0.28), 12, 16)
	vb.add_child(qcard)
	var qvb := VBoxContainer.new()
	qvb.add_theme_constant_override("separation", 10)
	qcard.add_child(qvb)

	var qhead := HBoxContainer.new()
	qhead.add_theme_constant_override("separation", 12)
	qvb.add_child(qhead)
	qhead.add_child(UI.mono_label("QUERY", 13, UI.COL_ACCENT))
	var qline := ColorRect.new()
	qline.color = UI.COL_LINE
	qline.custom_minimum_size = Vector2(0, 1)
	qline.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	qline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qhead.add_child(qline)
	qhead.add_child(UI.voice_button(func() -> void: UI.tts_say(_q_lbl.text), 14))

	_q_lbl = UI.make_label("", 23, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_q_lbl.custom_minimum_size = Vector2(0, 52)
	_q_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	qvb.add_child(_q_lbl)

	# 选项
	_opts_box = VBoxContainer.new()
	_opts_box.add_theme_constant_override("separation", 8)
	vb.add_child(_opts_box)

	# 解析
	_explain_panel = UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.04), UI.COL_LINE, 12, 12)
	_explain_panel.visible = false
	vb.add_child(_explain_panel)
	_explain_lbl = UI.make_label("", 17, UI.COL_TEXT)
	_explain_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_explain_lbl.custom_minimum_size = Vector2(0, 36)
	_explain_panel.add_child(_explain_lbl)

	# 主按钮
	_next_btn = Button.new()
	_next_btn.text = "继续推演"
	_next_btn.custom_minimum_size = Vector2(280, 52)
	UI.primary_button(_next_btn)
	_next_btn.pressed.connect(_on_next)
	var row := CenterContainer.new()
	row.add_child(_next_btn)
	vb.add_child(row)

func _make_hp_bar() -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(340, 26)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hp = HpBar.new()
	_hp.max_value = _questions.size()
	_hp.value = _questions.size()
	UI.full_rect(_hp)
	box.add_child(_hp)
	return box

func _hex_avatar(letter: String, col: Color, px: int) -> Control:
	var box := CenterContainer.new()
	box.custom_minimum_size = Vector2(px, px)
	var h := HexAvatar.new()
	h.letter = letter
	h.col = col
	h.custom_minimum_size = Vector2(px, px)
	box.add_child(h)
	return box

# ---------------------------------------------------------------- 出题
func _load_question() -> void:
	_answered = false
	for w in _rows:
		if is_instance_valid(w):
			w.queue_free()
	_rows.clear()
	_btns.clear()
	_panels.clear()
	_badges.clear()
	_contents.clear()
	_texts.clear()

	var q: Dictionary = _questions[_idx]
	_prog_lbl.text = "Q %02d / %02d" % [_idx + 1, _questions.size()]
	_set_top_progress(float(_idx) / float(_questions.size()))
	_hud_lbl.text = "解析正确 %d / %d" % [_correct, _questions.size()]
	_q_lbl.text = str(q.get("q", ""))
	UI.tts_say(_q_lbl.text)
	if _hp != null:
		_hp.max_value = _questions.size()
		_hp.set_hp(_questions.size() - _correct)

	_explain_lbl.text = ""
	_explain_panel.visible = false
	_next_btn.visible = false

	var opts: Array = q.get("opts", [])
	for k in range(opts.size()):
		_opts_box.add_child(_option_row(k, str(opts[k])))

func _option_row(k: int, text: String) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(760, 48)

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel",
		UI.glass_box(Color(1, 1, 1, 0.04), 12, Color(1, 1, 1, 0.13), 1, 12))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(p)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	p.add_child(hb)

	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel",
		UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(UI.COL_ACCENT, 0.5), 1, 0))
	badge.custom_minimum_size = Vector2(34, 32)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bl := UI.mono_label(_letter(k), 16, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	hb.add_child(badge)

	var content: Control
	if text.begins_with("res://") and ResourceLoader.exists(text):
		var tex := load(text) as Texture2D
		var tex_r := TextureRect.new()
		tex_r.texture = tex
		tex_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if tex != null:
			tex_r.custom_minimum_size = tex.get_size() * CHOICE_FORMULA_SCALE
		tex_r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content = tex_r
	else:
		var l := UI.make_label(text, 17, UI.COL_TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content = l
	hb.add_child(content)

	UI.corner_marks(box, 6, 9, 2, Color(1, 1, 1, 0.22))

	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.set_meta("sfx_click", "none")
	btn.add_theme_stylebox_override("normal", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	btn.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.07), 12, Color(UI.COL_ACCENT, 0.55), 1, 0))
	btn.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.28), 12, Color(UI.COL_ACCENT, 0.8), 1, 0))
	btn.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, Color(UI.COL_ACCENT, 0.3), 1, 0))
	btn.add_theme_stylebox_override("disabled", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	btn.pressed.connect(_on_answer.bind(k))
	box.add_child(btn)

	_rows.append(box)
	_btns.append(btn)
	_panels.append(p)
	_badges.append(badge)
	_contents.append(content)
	_texts.append(text)
	return box

# ---------------------------------------------------------------- 作答
func _on_answer(k: int) -> void:
	if _answered:
		return
	_answered = true
	var q: Dictionary = _questions[_idx]
	var correct := int(q.get("ans", -1))
	for i in range(_btns.size()):
		_btns[i].disabled = true
		if i == correct:
			_panels[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(UI.COL_SUCCESS, 0.15), 12, UI.COL_SUCCESS, 1, 14))
			_badges[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(UI.COL_SUCCESS, 0.35), 8, UI.COL_SUCCESS, 1, 0))
			_apply_content_state(i, Color("#d8ffec"), true)
		elif i == k:
			_panels[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(UI.COL_DANGER, 0.15), 12, UI.COL_DANGER, 1, 14))
			_badges[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(UI.COL_DANGER, 0.35), 8, UI.COL_DANGER, 1, 0))
			_apply_content_state(i, Color("#ffe0e5"), false)
		else:
			_panels[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(0, 0, 0, 0.18), 12, Color(1, 1, 1, 0.06), 1, 14))
			_badges[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(0, 0, 0, 0.2), 8, Color(1, 1, 1, 0.1), 1, 0))
			if _contents[i] is Label:
				(_contents[i] as Label).add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
			elif _contents[i] is TextureRect:
				(_contents[i] as TextureRect).modulate = Color(1, 1, 1, 0.3)

	var pos: Vector2 = size * 0.5
	if k >= 0 and k < _panels.size():
		pos = Vfx.center_of(_panels[k], pos)
	if k == correct:
		_correct += 1
		Sound.play("correct")
		_explain_lbl.text = "推演正确！" + str(q.get("explain", ""))
		_explain_panel.add_theme_stylebox_override("panel",
			_bar_box(Color(UI.COL_SUCCESS, 0.10), UI.COL_SUCCESS))
		Vfx.burst(self, pos, UI.COL_SUCCESS)
		Vfx.float_text(self, pos, "推演正确", UI.COL_SUCCESS, 28)
		Vfx.screen_flash(self, UI.COL_SUCCESS, 0.10, 0.38)
	else:
		Sound.play("wrong")
		_explain_lbl.text = "推演偏差 · 正解为 %s。" % _letter(correct) + str(q.get("explain", ""))
		_explain_panel.add_theme_stylebox_override("panel",
			_bar_box(Color(UI.COL_DANGER, 0.10), UI.COL_DANGER))
		if k < _panels.size():
			Vfx.wobble(_panels[k])
		Vfx.ring(self, pos, UI.COL_DANGER, 96.0, 0.55)
		Vfx.float_text(self, pos, "偏差", UI.COL_DANGER, 24)
		Vfx.screen_flash(self, UI.COL_DANGER, 0.14, 0.4)
	_explain_panel.visible = true

	if _hp != null:
		_hp.set_hp(_questions.size() - _correct)
	_hud_lbl.text = "解析正确 %d / %d" % [_correct, _questions.size()]
	_set_top_progress(float(_idx + 1) / float(_questions.size()))

	_next_btn.text = "生成报告" if _idx + 1 >= _questions.size() else "继续推演"
	_next_btn.visible = true
	Sound.play("click")

func _apply_content_state(i: int, col: Color, correct: bool) -> void:
	if _contents[i] is Label:
		var lab := _contents[i] as Label
		lab.add_theme_color_override("font_color", col)
		lab.text = ("✓  " if correct else "✗  ") + _texts[i]
	elif _contents[i] is TextureRect:
		var tex_r := _contents[i] as TextureRect
		tex_r.modulate = Color(1, 1, 1, 1) if correct else Color(1, 0.55, 0.6, 0.95)

func _bar_box(fill: Color, bar: Color) -> StyleBoxFlat:
	var sb := UI.glass_box(fill, 12, bar, 1, 16)
	sb.set_border_width_all(0)
	sb.border_width_left = 3
	sb.border_color = bar
	sb.content_margin_left = 18
	return sb

func _on_next() -> void:
	_idx += 1
	if _idx >= _questions.size():
		_finish()
	else:
		Sound.play("click")
		_load_question()

# ---------------------------------------------------------------- 结算
func _finish() -> void:
	var total := _questions.size()
	var ratio := float(_correct) / float(maxi(1, total))
	var st := 0
	if ratio >= 0.999:
		st = 3
	elif ratio >= 0.6:
		st = 2
	elif ratio >= 0.4:
		st = 1
	GameData.grant_stars(GameData.current_level_id(), st)
	Sound.play("begin" if st > 0 else "error")

	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.76)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	UI.full_rect(dim)

	var center := CenterContainer.new()
	UI.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)

	var panel := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.4), 16, 26)
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	vb.add_child(UI.mono_label("DEDUCTION COMPLETE", 13, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(UI.make_label("推演完成", 30, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(_hairline(Vector2(0, 1)))

	var srow := HBoxContainer.new()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", 12)
	vb.add_child(srow)
	for i in range(3):
		var full := i < st
		var tex := UI.icon("icon_star_full" if full else "icon_star_empty", 46,
			UI.COL_ACCENT if full else Color("#3c4a66"))
		if tex != null:
			var iv := TextureRect.new()
			iv.texture = tex
			iv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			iv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			iv.custom_minimum_size = Vector2(46, 46)
			iv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			srow.add_child(iv)
		else:
			srow.add_child(UI.mono_label("★" if full else "☆", 40,
				UI.COL_ACCENT if full else Color("#3c4a66"), HORIZONTAL_ALIGNMENT_CENTER))

	vb.add_child(_hairline(Vector2(0, 1)))
	vb.add_child(UI.mono_label("解析正确 %d / %d 题" % [_correct, total], 18, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(UI.make_label(GameData.rank_title(), 15, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vb.add_child(row)
	var prev_b := UI.ghost_button("上一关", func() -> void: GameData.goto_prev_level(), 15)
	prev_b.disabled = not GameData.has_prev_level()
	row.add_child(prev_b)
	row.add_child(UI.ghost_button("返回区域", func() -> void:
		Scene.goto("res://scenes/WorldMap.tscn")
	, 16))
	var again := Button.new()
	again.text = "重新推演"
	again.custom_minimum_size = Vector2(180, 56)
	UI.primary_button(again)
	again.pressed.connect(func() -> void:
		get_tree().reload_current_scene()
	)
	row.add_child(again)
	var next_b := UI.ghost_button("下一关", func() -> void: GameData.goto_next_level(), 15)
	next_b.disabled = not GameData.has_next_level()
	row.add_child(next_b)

	await get_tree().process_frame
	if is_instance_valid(panel):
		UI.popup_in(panel)

# ---------------------------------------------------------------- 占位
func _build_empty() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 66
	add_child(center)
	var panel := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, UI.COL_PANEL_BRD, 14, 26)
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	vb.add_child(UI.make_label("该节点题面尚未录入", 22, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(UI.make_label("可先返回体验其他区域", 15, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row := CenterContainer.new()
	vb.add_child(row)
	row.add_child(UI.ghost_button("返回区域", func() -> void:
		Scene.goto("res://scenes/WorldMap.tscn")
	, 16))
	await get_tree().process_frame
	if is_instance_valid(panel):
		UI.popup_in(panel)

# ---------------------------------------------------------------- 工具
func _letter(k: int) -> String:
	return "ABCD".substr(k, 1) if k >= 0 and k < 4 else str(k + 1)

func _hairline(min_size: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.color = UI.COL_LINE
	r.custom_minimum_size = min_size
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if min_size.x <= 0.0:
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
