extends Control
## 圆锥曲线 · 游戏化闯关：左侧答题面板 + 右侧复用的原场景动画。
## 由世界地图进入：按 GameData.current_level["conic"] 载入 C1/C2/C3 对应场景。

const DATA_PATH := "res://data/conic_levels.json"

var _all: Dictionary = {}
var _id := "C1"
var _cfg: Dictionary = {}
var _stages: Array = []
var _scene: Node2D
var _pet: Pet

var _ui: Control
var _top_fill: ColorRect
var _prog: Label
var _coins: Label
var _panel: PanelContainer
var _title: Label
var _q: RichTextLabel
var _ans: VBoxContainer
var _feed: Label
var _next: Button
var _hint: Button
var _victory: PanelContainer
var _v_star_row: HBoxContainer
var _v_rate: Label
var _v_score: Label
var _v_coins: Label
var _dim: ColorRect
var _nav_prev: Button
var _nav_next: Button

var _opt_btns: Array[Button] = []
var _opt_panels: Array[PanelContainer] = []
var _opt_badges: Array[PanelContainer] = []
var _opt_contents: Array[Control] = []
var _opt_marks: Array[Label] = []

var _idx := 0
var _clean: Array[int] = []
var _wrongs := 0
var _hint_used := false
var _solved := false
var _done := false

func _ready() -> void:
	_load()
	add_child(TechBg.new())
	_load_scene()
	_build_ui()
	_reset()
	_pet = Pet.spawn(self, "圆锥曲线：看右侧动画找规律～")
	_pet.tap_provider = _pet_point

func _load() -> void:
	if FileAccess.file_exists(DATA_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if typeof(data) == TYPE_DICTIONARY:
			_all = data
	var lv: Dictionary = GameData.current_level
	if lv.has("conic"):
		_id = str(lv["conic"])
	if not _all.has(_id):
		_id = "C1"
	if _all.has(_id):
		_cfg = _all[_id]
		_stages = _cfg.get("levels", [])

func _pet_point() -> String:
	var title := str(_cfg.get("title", "圆锥曲线"))
	var summary := str(_cfg.get("summary", ""))
	var hint := ""
	if not _stages.is_empty():
		hint = str(_stages[clampi(_idx, 0, _stages.size() - 1)].get("hint", ""))
	if hint != "":
		return "【%s】%s\n提示：%s" % [title, summary, hint]
	return "【%s】%s" % [title, summary]

func _load_scene() -> void:
	var path := str(_cfg.get("topic", ""))
	var scr := load(path) as GDScript
	if scr == null:
		return
	_scene = scr.new() as Node2D
	add_child(_scene)
	_scene.set_process_unhandled_key_input(false)
	_scene.set_process_unhandled_input(false)
	# 复用原场景：等比缩放到右侧图形区并居中，左侧让位给文字面板。
	var lay := UI.stage_layout()
	var view_left := float(lay["view_left"])
	var vp := get_viewport_rect().size
	var region_w := vp.x - 14.0 - view_left
	var region_h := vp.y - 96.0 - 66.0
	var s := clampf(minf(region_w / 1280.0, region_h / 720.0), 0.45, 0.82)
	_scene.scale = Vector2(s, s)
	_scene.position = Vector2(
		view_left + (region_w - 1280.0 * s) * 0.5,
		66.0 + (region_h - 720.0 * s) * 0.5)

# ---------------------------------------------------------------- 流程
func _reset() -> void:
	_idx = 0
	_wrongs = 0
	_hint_used = false
	_solved = false
	_done = false
	_clean.clear()
	for i in _stages.size():
		_clean.append(0)
	if _victory != null:
		_victory.visible = false
	if _dim != null:
		_dim.visible = false
	_load_q()

func _load_q() -> void:
	if _stages.is_empty():
		return
	var s: Dictionary = _stages[_idx]
	_solved = false
	_wrongs = 0
	_hint_used = false
	_title.text = str(s.get("name", ""))
	_q.text = str(s.get("q", ""))
	UI.tts_say(_q.text)
	_feed.text = ""
	_hint.disabled = false
	_next.disabled = true
	_next.text = "下一关 →" if _idx < _stages.size() - 1 else "生成报告"
	for c in _ans.get_children():
		c.queue_free()
	_opt_btns.clear()
	_opt_panels.clear()
	_opt_badges.clear()
	_opt_contents.clear()
	_opt_marks.clear()
	for k in (s.get("opts", []) as Array).size():
		_ans.add_child(_choice_row(k, str((s.get("opts", []) as Array)[k])))
	# 切换动画模式并重播
	if _scene != null and s.has("mode"):
		_scene.call("_set_mode", int(s["mode"]))
	_update_hud()

func _choice_row(k: int, opt: String) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(0, 54)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.04), 12, Color(1, 1, 1, 0.13), 1, 12))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(p)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	p.add_child(hb)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(UI.COL_ACCENT, 0.5), 1, 0))
	badge.custom_minimum_size = Vector2(34, 32)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bl := UI.mono_label("ABCD".substr(k, 1), 16, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	hb.add_child(badge)

	var content: Control
	if opt.begins_with("res://") and ResourceLoader.exists(opt):
		var tex := load(opt) as Texture2D
		var tex_r := TextureRect.new()
		tex_r.texture = tex
		tex_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_r.stretch_mode = TextureRect.STRETCH_SCALE
		if tex != null:
			tex_r.custom_minimum_size = tex.get_size() * 0.46
		tex_r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content = tex_r
	else:
		var l := UI.make_label(opt, 19, UI.COL_TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content = l
	hb.add_child(content)

	var mark := UI.make_label("", 20, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	mark.custom_minimum_size = Vector2(26, 0)
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(mark)

	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.set_meta("sfx_click", "none")
	btn.add_theme_stylebox_override("normal", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	btn.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.07), 12, Color(UI.COL_ACCENT, 0.55), 1, 0))
	btn.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.28), 12, Color(UI.COL_ACCENT, 0.8), 1, 0))
	btn.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, Color(UI.COL_ACCENT, 0.3), 1, 0))
	btn.add_theme_stylebox_override("disabled", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	btn.pressed.connect(_on_choice.bind(k))
	box.add_child(btn)

	_opt_btns.append(btn)
	_opt_panels.append(p)
	_opt_badges.append(badge)
	_opt_contents.append(content)
	_opt_marks.append(mark)
	return box

func _on_choice(k: int) -> void:
	if _solved or _done or _stages.is_empty():
		return
	var correct := int(_stages[_idx].get("ans", -1))
	_reveal_choices(k, correct)
	if k == correct:
		_level_ok()
	else:
		_wrong("不对，再想想——看看右侧图形。")

func _reveal_choices(picked: int, correct: int) -> void:
	for i in _opt_btns.size():
		_opt_btns[i].disabled = true
		if i == correct:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_SUCCESS, 0.15), 12, UI.COL_SUCCESS, 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_SUCCESS, 0.35), 8, UI.COL_SUCCESS, 1, 0))
			_opt_marks[i].text = "✓"
			_opt_marks[i].add_theme_color_override("font_color", UI.COL_SUCCESS)
		elif i == picked:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_DANGER, 0.15), 12, UI.COL_DANGER, 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_DANGER, 0.35), 8, UI.COL_DANGER, 1, 0))
			_opt_marks[i].text = "✗"
			_opt_marks[i].add_theme_color_override("font_color", UI.COL_DANGER)
		else:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(0, 0, 0, 0.18), 12, Color(1, 1, 1, 0.06), 1, 12))
			_opt_marks[i].modulate.a = 0.0
		if _opt_contents[i] is Label:
			(_opt_contents[i] as Label).add_theme_color_override("font_color", UI.COL_TEXT if i == correct else Color(1, 1, 1, 0.32))

func _level_ok() -> void:
	if _solved:
		return
	_solved = true
	if _wrongs == 0:
		_clean[_idx] = 1
	Sound.play("correct")
	_show_feed("回答正确！", UI.COL_SUCCESS)
	_next.disabled = false

func _wrong(msg: String) -> void:
	if _solved or _done:
		return
	_wrongs += 1
	Sound.play("wrong")
	_show_feed(msg, UI.COL_DANGER)

func _use_hint() -> void:
	if _solved or _done or _hint_used or _stages.is_empty():
		return
	_hint_used = true
	_wrongs += 1
	_hint.disabled = true
	_show_feed("[提示] " + str(_stages[_idx].get("hint", "")), Color("#ffd479"))

func _next_pressed() -> void:
	if not _solved or _done:
		return
	if _idx < _stages.size() - 1:
		_idx += 1
		_load_q()
	else:
		_finish()

func _finish() -> void:
	_done = true
	var total := _stages.size()
	var clean := 0
	for c in _clean:
		clean += c
	var ratio := float(clean) / float(maxi(1, total))
	var st := 0
	if ratio >= 0.999:
		st = 3
	elif ratio >= 0.6:
		st = 2
	elif ratio >= 0.4:
		st = 1
	if GameData.current_level_id() != "":
		GameData.grant_stars(GameData.current_level_id(), st)
	var reward := 30 + clean * 15 + st * 20
	if st >= 3:
		reward += 60
	GameData.add_coins(reward)
	_update_hud()

	var pct := int(round(ratio * 100.0))
	if st >= 3:
		_v_rate.text = "推演胜率  %d%%   ·   完美通关！" % pct
		_v_rate.add_theme_color_override("font_color", Color("#ffd479"))
	else:
		_v_rate.text = "推演胜率  %d%%" % pct
	var _v_score_lbl := "无失误 %d / %d 关" % [clean, total]

	for c in _v_star_row.get_children():
		_v_star_row.remove_child(c)
		c.free()
	var tex_full := UI.icon("icon_star_full", 54, UI.COL_ACCENT)
	var tex_empty := UI.icon("icon_star_empty", 54, Color("#3c4a66"))
	for i in 3:
		var filled := i < st
		var tex_r := TextureRect.new()
		tex_r.texture = tex_full if (filled and tex_full != null) else tex_empty
		if tex_r.texture != null:
			tex_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_r.custom_minimum_size = Vector2(54, 54)
		tex_r.pivot_offset = Vector2(27, 27)
		tex_r.scale = Vector2(0.01, 0.01)
		tex_r.modulate.a = 0.0
		_v_star_row.add_child(tex_r)
		var delay := 0.35 + i * 0.2
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(tex_r, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(tex_r, "modulate:a", 1.0, 0.25)
		if filled:
			get_tree().create_timer(delay).timeout.connect(func() -> void: Sound.play("star"))
	_v_score.text = _v_score_lbl
	_v_coins.text = "金币  +0"
	Sound.play("complete")
	_refresh_nav()
	_dim.visible = true
	_victory.visible = true
	_spawn_confetti()
	await get_tree().process_frame
	if is_instance_valid(_victory):
		UI.popup_in(_victory)
	var tc := create_tween()
	tc.tween_interval(0.75)
	tc.tween_method(func(v: float) -> void: _v_coins.text = "金币  +%d" % int(v), 0.0, float(reward), 0.9) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.tween_callback(func() -> void:
		if is_instance_valid(_v_coins):
			_v_coins.text = "金币  +%d      (共 %d)" % [reward, GameData.coins])

func _show_feed(msg: String, col: Color) -> void:
	if _feed == null:
		return
	_feed.text = msg
	_feed.add_theme_color_override("font_color", col)
	UI.tts_say(msg)

func _update_hud() -> void:
	if _prog == null:
		return
	_prog.text = "SEQ %02d / %02d" % [_idx + 1, _stages.size()]
	if _coins != null:
		_coins.text = "◆ %d" % GameData.coins
	var total := maxi(1, _stages.size())
	var tw := create_tween()
	tw.tween_property(_top_fill, "anchor_right", float(_idx) / float(total), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------- UI
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.theme = UI.make_theme()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(_ui)
	layer.add_child(_ui)

	var tl := Control.new()
	tl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tl.offset_bottom = 3
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(tl)
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.07)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(track)
	tl.add_child(track)
	_top_fill = ColorRect.new()
	_top_fill.color = UI.COL_ACCENT
	_top_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top_fill.anchor_right = 0.0
	_top_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(_top_fill)

	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.topbar_box())
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 62)
	bar.offset_bottom = 62
	_ui.add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	bar.add_child(hb)
	hb.add_child(UI.ghost_button("← 返回区域", func() -> void:
		Scene.goto("res://scenes/WorldMap.tscn")
	))
	var vl := ColorRect.new()
	vl.color = UI.COL_LINE
	vl.custom_minimum_size = Vector2(1, 18)
	vl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vl)
	hb.add_child(UI.make_label(str(_cfg.get("title", "圆锥曲线")), 21))
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(UI.COL_ACCENT, 0.3), 1, 10))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cl := UI.mono_label(str(_cfg.get("method", "")), 13, Color(UI.COL_ACCENT, 0.85))
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(cl)
	hb.add_child(chip)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_coins = UI.mono_label("◆ 0", 16, Color("#ffd479"))
	_coins.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_coins)
	_prog = UI.mono_label("SEQ 00 / 00", 17, UI.COL_ACCENT)
	_prog.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_prog)

	_panel = UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.3), 14, 18)
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 1.0
	var lay := UI.stage_layout()
	_panel.offset_left = float(lay["left"])
	_panel.offset_right = float(lay["left"]) + float(lay["width"])
	_panel.offset_top = 62
	_panel.offset_bottom = -90
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 12)
	_panel.add_child(pv)
	pv.add_child(UI.mono_label("QUERY", 13, UI.COL_ACCENT))
	_title = UI.make_label("", 22, Color("#ffd479"))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(_title)
	var hl := ColorRect.new()
	hl.color = UI.COL_LINE
	hl.custom_minimum_size = Vector2(0, 1)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(hl)
	_q = RichTextLabel.new()
	_q.bbcode_enabled = true
	_q.fit_content = true
	_q.scroll_active = true
	_q.selection_enabled = false
	_q.focus_mode = Control.FOCUS_NONE
	_q.custom_minimum_size = Vector2(0, 124)
	_q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_q.add_theme_font_override("normal_font", UI.font())
	_q.add_theme_font_override("bold_font", UI.font())
	_q.add_theme_font_size_override("normal_font_size", UI.fs(18))
	_q.add_theme_font_size_override("bold_font_size", UI.fs(18))
	_q.add_theme_color_override("default_color", UI.COL_TEXT)
	_q.add_theme_constant_override("line_separation", 5)
	pv.add_child(_q)
	var ans_scroll := ScrollContainer.new()
	ans_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ans_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(ans_scroll)
	_ans = VBoxContainer.new()
	_ans.add_theme_constant_override("separation", 10)
	_ans.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ans_scroll.add_child(_ans)
	UI.enable_touch_scroll(ans_scroll)
	_feed = UI.make_label("", 16, UI.COL_TEXT_DIM)
	_feed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feed.custom_minimum_size = Vector2(0, 44)
	pv.add_child(_feed)

	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.offset_left = -330
	bottom.offset_right = 330
	bottom.offset_top = -88
	bottom.offset_bottom = -26
	bottom.add_theme_stylebox_override("panel", UI.glass_box(Color(0.03, 0.05, 0.09, 0.88), 12, Color(UI.COL_ACCENT, 0.25), 1, 12))
	bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(bottom)
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 14)
	bottom.add_child(bh)
	_hint = UI.ghost_button("提示 (−评分)", _use_hint, 16)
	bh.add_child(_hint)
	bh.add_child(UI.ghost_button("重新挑战", func() -> void: _reset(), 16))
	bh.add_child(UI.voice_button(func() -> void: UI.tts_say(_q.text), 16))
	_next = Button.new()
	_next.text = "下一关 →"
	_next.custom_minimum_size = Vector2(210, 52)
	UI.primary_button(_next)
	_next.disabled = true
	_next.pressed.connect(_next_pressed)
	bh.add_child(_next)

	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.02, 0.05, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_dim)
	_victory = UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.4), 16, 26)
	_victory.set_anchors_preset(Control.PRESET_CENTER)
	_victory.custom_minimum_size = Vector2(540, 0)
	_victory.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_victory.grow_vertical = Control.GROW_DIRECTION_BOTH
	_victory.offset_left = -270
	_victory.offset_right = 270
	_victory.offset_top = -190
	_victory.offset_bottom = 190
	_victory.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_victory)
	var vv := VBoxContainer.new()
	vv.alignment = BoxContainer.ALIGNMENT_CENTER
	vv.add_theme_constant_override("separation", 14)
	_victory.add_child(vv)
	vv.add_child(UI.mono_label("MISSION CLEAR", 13, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	vv.add_child(UI.make_label("圆锥曲线 · 通关", 30, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var vll := ColorRect.new()
	vll.color = UI.COL_LINE
	vll.custom_minimum_size = Vector2(0, 1)
	vll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vv.add_child(vll)
	_v_star_row = HBoxContainer.new()
	_v_star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_v_star_row.add_theme_constant_override("separation", 14)
	vv.add_child(_v_star_row)
	_v_rate = UI.make_label("", 20, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_rate)
	_v_score = UI.make_label("", 16, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_score)
	_v_coins = UI.make_label("", 22, Color("#ffd479"), HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_coins)
	vv.add_child(UI.make_label(str(_cfg.get("summary", "")), 15, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vv.add_child(row)
	_nav_prev = UI.ghost_button("上一关", func() -> void: GameData.goto_prev_level(), 15)
	row.add_child(_nav_prev)
	row.add_child(UI.ghost_button("返回区域", func() -> void:
		Scene.goto("res://scenes/WorldMap.tscn")
	, 16))
	var again := Button.new()
	again.text = "重新推演"
	again.custom_minimum_size = Vector2(180, 56)
	UI.primary_button(again)
	again.pressed.connect(func() -> void: _reset())
	row.add_child(again)
	_nav_next = UI.ghost_button("下一关", func() -> void: GameData.goto_next_level(), 15)
	row.add_child(_nav_next)
	_victory.visible = false
	_dim.visible = false

func _refresh_nav() -> void:
	if _nav_prev != null:
		_nav_prev.disabled = not GameData.has_prev_level()
	if _nav_next != null:
		_nav_next.disabled = not GameData.has_next_level()

func _spawn_confetti() -> void:
	var c := Confetti.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(c)
	UI.full_rect(c)
	c.begin()

# ---------------------------------------------------------------- 庆祝彩带
class Confetti extends Control:
	const COLS := [Color("#5ee6ff"), Color("#7fd8ff"), Color("#ffd479"), Color("#34d399"), Color("#a878ff"), Color("#fb7185")]
	var pieces: Array = []
	var _life := 0.0
	var _max_life := 4.5
	var _w := 1280.0
	var _h := 720.0

	func begin() -> void:
		_w = size.x if size.x > 1.0 else 1280.0
		_h = size.y if size.y > 1.0 else 720.0
		for i in 120:
			pieces.append(_new_piece(randf_range(-_h, -6.0)))
		set_process(true)

	func _new_piece(start_y: float) -> Dictionary:
		return {
			"pos": Vector2(randf_range(0.0, _w), start_y),
			"vel": Vector2(randf_range(-60.0, 60.0), randf_range(70.0, 190.0)),
			"rot": randf_range(0.0, TAU),
			"spin": randf_range(-7.0, 7.0),
			"size": Vector2(randf_range(6.0, 12.0), randf_range(9.0, 17.0)),
			"col": COLS[randi() % COLS.size()],
		}

	func _process(delta: float) -> void:
		_life += delta
		for p in pieces:
			var v: Vector2 = p["vel"]
			v.y += 260.0 * delta
			v.x *= (1.0 - minf(0.9 * delta, 0.9))
			p["vel"] = v
			p["pos"] = (p["pos"] as Vector2) + v * delta
			p["rot"] = float(p["rot"]) + float(p["spin"]) * delta
			if (p["pos"] as Vector2).y > _h + 50.0:
				if _life < _max_life:
					p["pos"] = Vector2(randf_range(0.0, _w), randf_range(-70.0, -10.0))
					p["vel"] = Vector2(randf_range(-60.0, 60.0), randf_range(70.0, 190.0))
				else:
					p["pos"] = Vector2((p["pos"] as Vector2).x, 1e9)
		if _life > _max_life + 3.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(1.0 - maxf(_life - _max_life, 0.0) / 3.0, 0.0, 1.0)
		for p in pieces:
			var base: Vector2 = p["pos"]
			if base.y > _h + 200.0:
				continue
			var s: Vector2 = p["size"]
			var c: Color = p["col"]
			c.a *= fade
			var r := float(p["rot"])
			var cs := cos(r)
			var sn := sin(r)
			var hx := s.x * 0.5
			var hy := s.y * 0.5
			var pts := PackedVector2Array()
			for cor in [Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)]:
				pts.append(base + Vector2(cor.x * cs - cor.y * sn, cor.x * sn + cor.y * cs))
			draw_colored_polygon(pts, c)
