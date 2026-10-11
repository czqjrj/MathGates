extends Control
## 数列「递推 → 通项公式」实验探究关卡：左侧答题面板 + 右侧可交互实验画布。
## 由「方法推演」世界地图进入：按 GameData.current_level["sequence"] 载入对应小关。
## 规则：每关 3 题，首次答对计「无失误」；≥80% 三星，≥60% 二星，否则失败；
##       踩中陷阱题额外扣一星，规避陷阱奖励金币。

const DATA_PATH := "res://data/recurrence_levels.json"
const BACK_SCENE := "res://scenes/WorldMap.tscn"
const CHOICE_FORMULA_SCALE := 0.42

var _all: Dictionary = {}
var _id := "recur_add"
var _cfg: Dictionary = {}
var _stages: Array = []
var _view: Control
var _plane: SequencePlane
var _pet: Pet

var _ui: Control
var _top_fill: ColorRect
var _prog: Label
var _coins: Label
var _panel: PanelContainer
var _title: Label
var _q: RichTextLabel
var _ans: VBoxContainer
var _feed: RichTextLabel
var _next: Button
var _hint: Button
var _victory: PanelContainer
var _v_title: Label
var _v_star_row: HBoxContainer
var _v_rate: Label
var _v_score: Label
var _v_coins: Label
var _dim: ColorRect
var _nav_prev: Button
var _nav_next: Button
var _live: Label

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
var _trap_missed := false
var _explore_done := false
var _q_recorded := false
var _last_picked := -1

func _ready() -> void:
	_load()
	add_child(TechBg.new())
	_build_view()
	_build_ui()
	_add_pet()
	_reset()

func _add_pet() -> void:
	_pet = Pet.spawn(self, "动手试试，再回答追问～")
	_pet.tap_provider = _pet_point

func _pet_point() -> String:
	var s := _current()
	if s.has("point"):
		return str(s["point"])
	var method := str(_cfg.get("method", ""))
	var summary := str(_cfg.get("summary", ""))
	var hint := str(s.get("hint", ""))
	if hint != "":
		return "【%s】%s\n方法：%s" % [method, summary, hint]
	return "【%s】%s" % [method, summary]

func _ask_pet() -> void:
	if _pet == null:
		return
	_pet.respond(_pet_point())
	Sound.play("select")

func _load() -> void:
	if FileAccess.file_exists(DATA_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if typeof(data) == TYPE_DICTIONARY:
			_all = data
	var lv: Dictionary = GameData.current_level
	if lv.has("sequence"):
		_id = str(lv["sequence"])
	elif lv.has("id"):
		_id = str(lv["id"])
	if not _all.has(_id):
		_id = str(_all.keys()[0]) if _all.size() > 0 else "recur_add"
	if _all.has(_id):
		_cfg = _all[_id]
		var arr = _cfg.get("levels", [])
		if arr is Array:
			_stages = arr

func _build_view() -> void:
	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.offset_left = float(UI.stage_layout()["view_left"])
	_view.offset_top = 66.0
	_view.offset_right = -14.0
	_view.offset_bottom = -96.0
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	_plane = SequencePlane.new()
	_plane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_plane.param_changed.connect(_on_param_changed)
	_view.add_child(_plane)

func _current() -> Dictionary:
	if _stages.is_empty():
		return {}
	return _stages[clampi(_idx, 0, _stages.size() - 1)]

# ---------------------------------------------------------------- 流程
func _reset() -> void:
	_idx = 0
	_wrongs = 0
	_hint_used = false
	_solved = false
	_done = false
	_trap_missed = false
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
	var s := _current()
	_solved = false
	_wrongs = 0
	_hint_used = false
	_explore_done = false
	_q_recorded = false
	_last_picked = -1
	_title.text = str(s.get("name", ""))
	var qraw := str(s.get("q", ""))
	_q.text = UI.inline_formulas(qraw)
	UI.tts_say(UI.strip_formulas(qraw))
	_feed.text = ""
	_hint.disabled = false
	_next.disabled = true
	_next.text = "下一关 →" if _idx < _stages.size() - 1 else "生成报告"
	for c in _ans.get_children():
		c.queue_free()
	_live = null
	_clear_opts()

	var sc: Dictionary = s.get("scene", {})
	var t := str(s.get("type", "choice"))
	_plane.visible = true
	_plane.set_scene(sc)

	if t == "explore":
		_build_explore(s)
	elif t == "interact":
		_build_interact(s)
	else:
		_build_choices(s)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_ans, "modulate:a", 1.0, 0.28).from(0.0)
	tw.tween_property(_q, "modulate:a", 1.0, 0.22).from(0.0)
	_update_hud()

func _on_param_changed(_v: float) -> void:
	if _live != null and is_instance_valid(_live):
		_live.text = "当前 %s = %s　（拖动下方滑块调整）" % [_plane.param_label, _plane._fmt(_plane.param)]

func _clear_opts() -> void:
	_opt_btns.clear()
	_opt_panels.clear()
	_opt_badges.clear()
	_opt_contents.clear()
	_opt_marks.clear()

func _build_choices(s: Dictionary) -> void:
	var opts: Array = s.get("opts", [])
	for k in opts.size():
		_ans.add_child(_choice_row(k, str(opts[k])))

func _build_interact(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	_live.text = "当前 %s = %s" % [_plane.param_label, _plane._fmt(_plane.param)]
	var tip_text := str(s.get("tip", "拖动画布下方的滑块，观察数列的变化，调到目标后点击确认。"))
	var tip := UI.make_label(tip_text, 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var b := Button.new()
	b.text = str(s.get("confirm", "确认"))
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(150, 50)
	b.pressed.connect(_on_confirm)
	box.add_child(b)

func _build_explore(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	_live.text = "当前 %s = %s" % [_plane.param_label, _plane._fmt(_plane.param)]
	var tip_text := str(s.get("tip", "动手做实验：拖动滑块改变参数，观察右侧图形的变化，再点击按钮进入追问。"))
	var tip := UI.make_label(tip_text, 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var b := Button.new()
	b.text = str(s.get("confirm", "实验完成，回答追问"))
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(210, 50)
	b.pressed.connect(_on_confirm)
	box.add_child(b)

func _choice_row(k: int, opt: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.04), 12, Color(1, 1, 1, 0.13), 1, 12))
	p.custom_minimum_size = Vector2(0, 52)
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
		tex_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if tex != null:
			tex_r.custom_minimum_size = tex.get_size() * CHOICE_FORMULA_SCALE
		tex_r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content = tex_r
	else:
		var l := UI.make_label(opt, 18, UI.COL_TEXT)
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
	p.add_child(btn)

	_opt_btns.append(btn)
	_opt_panels.append(p)
	_opt_badges.append(badge)
	_opt_contents.append(content)
	_opt_marks.append(mark)
	return p

func _on_choice(k: int) -> void:
	if _solved or _done or _stages.is_empty():
		return
	_last_picked = k
	var correct := int(_current().get("ans", -1))
	_reveal_choices(k, correct)
	if k == correct:
		_level_ok()
	else:
		_wrong("不对，再想想——看看右侧实验图形给出的规律。")

func _set_followup_question(s: Dictionary) -> void:
	var ask := str(s.get("ask", ""))
	if ask.is_empty():
		ask = "根据刚才的实验观察，选出正确结论："
	_title.text = "追问"
	_q.text = UI.inline_formulas(ask)
	UI.tts_say(UI.strip_formulas(ask))

func _on_confirm() -> void:
	if _solved or _done or _stages.is_empty():
		return
	_last_picked = -1
	var s := _current()
	if str(s.get("type", "")) == "explore" and not _explore_done:
		var gate := bool((s.get("task", {}) as Dictionary).get("gate", false))
		var gok := (not gate) or _plane.is_param_correct()
		if gok:
			_explore_done = true
			Sound.play("correct")
			_set_followup_question(s)
			for c in _ans.get_children():
				c.queue_free()
			_live = null
			_build_choices(s)
			_show_feed(str(s.get("success", "很好！现在回答下面的追问。")), UI.COL_SUCCESS)
		else:
			_wrong(str(s.get("retry", "还不对，再调整试试。")))
		return
	if _plane.is_param_correct():
		_level_ok()
	else:
		_wrong("参数还不对，再调调看——想想递推式是怎样变形的。")

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
		elif _opt_contents[i] is TextureRect:
			var tex_r := _opt_contents[i] as TextureRect
			if i == correct:
				tex_r.modulate = Color(1, 1, 1, 1)
			elif i == picked:
				tex_r.modulate = Color(1, 0.55, 0.6, 0.95)
			else:
				tex_r.modulate = Color(1, 1, 1, 0.32)

func _level_ok() -> void:
	if _solved:
		return
	_solved = true
	if _wrongs == 0:
		_clean[_idx] = 1
	if not _q_recorded:
		_q_recorded = true
		GameData.record_answer(GameData.current_level_id(), _idx, str(_current().get("name", "")), true, -1, -1, "sequence")
	Sound.play("correct")
	if _pet != null:
		_pet.cheer()
	var s := _current()
	var msg := "回答正确！"
	if bool(s.get("trap", false)):
		msg = "漂亮，成功规避陷阱！"
	if s.has("explain"):
		msg += "  " + str(s["explain"])
	_show_feed(msg, UI.COL_SUCCESS)
	_next.disabled = false
	var tw := create_tween()
	tw.tween_property(_panel, "modulate", Color(1.15, 1.15, 1.1), 0.08)
	tw.tween_property(_panel, "modulate", Color.WHITE, 0.25)

func _wrong(msg: String) -> void:
	if _solved or _done:
		return
	_wrongs += 1
	if bool(_current().get("trap", false)):
		_trap_missed = true
	if not _q_recorded:
		_q_recorded = true
		GameData.record_answer(GameData.current_level_id(), _idx, str(_current().get("name", "")), false, _last_picked, int(_current().get("ans", -1)), "sequence")
	Sound.play("wrong")
	if _pet != null:
		_pet.comfort()
	if _current().has("explain"):
		msg += "\n[复盘] " + str(_current()["explain"])
	_show_feed(msg, UI.COL_DANGER)

func _use_hint() -> void:
	if _solved or _done or _hint_used or _stages.is_empty():
		return
	_hint_used = true
	_wrongs += 1
	_hint.disabled = true
	_show_feed("[提示] " + str(_current().get("hint", "")), Color("#ffd479"))

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
	if ratio >= 0.8:
		st = 3
	elif ratio >= 0.6:
		st = 2
	if _trap_missed and st > 0:
		st -= 1
	var lv0 := GameData.player_level()
	if GameData.current_level_id() != "":
		GameData.grant_stars(GameData.current_level_id(), st)
		GameData.record_level_result(GameData.current_level_id(), st, clean, total, _trap_missed)
	var lv1 := GameData.player_level()
	var reward := 30 + clean * 15 + st * 20
	if st >= 3:
		reward += 60
	if not _trap_missed:
		reward += 30
	GameData.add_coins(reward)
	_update_hud()

	var pct := int(round(ratio * 100.0))
	var passed := st > 0
	if passed and _pet != null:
		var inten := 1.6 if st >= 3 else 1.0
		if lv1 > lv0:
			inten = maxf(inten, 1.5)
		_pet.celebrate(inten)
		if lv1 > lv0:
			_pet.say("升级啦！现在 Lv.%d，恭喜～" % lv1, 3.2)
	_v_title.text = "实验通关" if passed else "实验失败 · 请复盘"
	_v_title.add_theme_color_override("font_color", UI.COL_TEXT if passed else UI.COL_DANGER)
	if st >= 3:
		_v_rate.text = "正确率 %d%%   ·   完美通关！" % pct
		_v_rate.add_theme_color_override("font_color", Color("#ffd479"))
	else:
		_v_rate.text = "正确率 %d%%" % pct
		_v_rate.add_theme_color_override("font_color", UI.COL_ACCENT if passed else UI.COL_DANGER)
	_v_score.text = "无失误 %d / %d 关" % [clean, total]

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
	_v_coins.text = "金币  +0"
	Sound.play("complete" if passed else "error")
	_refresh_nav()
	_dim.visible = true
	_victory.visible = true
	if passed:
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
	_feed.text = "[color=#%s]%s[/color]" % [col.to_html(false), UI.inline_formulas(msg)]
	UI.tts_say(UI.strip_formulas(msg))

func _update_hud() -> void:
	if _prog == null:
		return
	_prog.text = "EXP %02d / %02d" % [_idx + 1, _stages.size()]
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
	_top_fill.color = Color(str(_cfg.get("color", "#FF99C3")))
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
	hb.add_child(UI.ghost_button("← 方法推演", func() -> void:
		Scene.goto(BACK_SCENE)
	))
	var vl := ColorRect.new()
	vl.color = UI.COL_LINE
	vl.custom_minimum_size = Vector2(1, 18)
	vl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vl)
	hb.add_child(UI.make_label(str(_cfg.get("title", "数列递推求通项公式")), 21))
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
	_prog = UI.mono_label("EXP 00 / 00", 17, UI.COL_ACCENT)
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
	pv.add_child(UI.mono_label("EXPERIMENT", 13, UI.COL_ACCENT))
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
	_feed = RichTextLabel.new()
	_feed.bbcode_enabled = true
	_feed.fit_content = true
	_feed.scroll_active = false
	_feed.selection_enabled = false
	_feed.focus_mode = Control.FOCUS_NONE
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed.custom_minimum_size = Vector2(0, 44)
	_feed.add_theme_font_override("normal_font", UI.font())
	_feed.add_theme_font_override("bold_font", UI.font())
	_feed.add_theme_font_size_override("normal_font_size", UI.fs(15))
	_feed.add_theme_color_override("default_color", UI.COL_TEXT_DIM)
	_feed.add_theme_constant_override("line_separation", 4)
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
	bh.add_child(UI.ghost_button("问萌宠", _ask_pet, 16))
	bh.add_child(UI.voice_button(func() -> void: UI.tts_say(_q.text), 16))
	bh.add_child(UI.ghost_button("重新实验", func() -> void: _reset(), 16))
	_next = Button.new()
	_next.text = "下一关 →"
	UI.primary_button(_next)
	_next.disabled = true
	_next.pressed.connect(_next_pressed)
	bh.add_child(_next)

	_victory = UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.3), 14, 18)
	_victory.anchor_top = 0.5
	_victory.anchor_bottom = 0.5
	_victory.anchor_left = 0.5
	_victory.anchor_right = 0.5
	_victory.offset_left = -280
	_victory.offset_right = 280
	_victory.offset_top = -200
	_victory.offset_bottom = 200
	_ui.add_child(_victory)
	var vv := VBoxContainer.new()
	vv.alignment = BoxContainer.ALIGNMENT_CENTER
	vv.add_theme_constant_override("separation", 12)
	_victory.add_child(vv)
	vv.add_child(UI.mono_label("EXPERIMENT REPORT", 13, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	_v_title = UI.make_label("实验通关", 30, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_title)
	_v_star_row = HBoxContainer.new()
	_v_star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_v_star_row.add_theme_constant_override("separation", 12)
	vv.add_child(_v_star_row)
	_v_rate = UI.make_label("", 20, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_rate)
	_v_score = UI.make_label("", 16, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_score)
	_v_coins = UI.make_label("", 22, Color("#ffd479"), HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_coins)
	var vsum := UI.make_label(str(_cfg.get("summary", "")), 14, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	vsum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vv.add_child(vsum)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vv.add_child(row)
	_nav_prev = UI.ghost_button("上一关", func() -> void: GameData.goto_prev_level(), 15)
	row.add_child(_nav_prev)
	row.add_child(UI.ghost_button("返回方法推演", func() -> void:
		Scene.goto(BACK_SCENE)
	, 16))
	var again := Button.new()
	again.text = "重新推演"
	again.custom_minimum_size = Vector2(160, 56)
	UI.primary_button(again)
	again.pressed.connect(func() -> void: _reset())
	row.add_child(again)
	_nav_next = UI.ghost_button("下一关", func() -> void: GameData.goto_next_level(), 15)
	row.add_child(_nav_next)
	_victory.visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	UI.full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_dim)
	_ui.move_child(_dim, _victory.get_index())
	_dim.visible = false
	_victory.visible = false

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

class Confetti extends Control:
	var _t := 0.0
	var _pieces: Array = []
	func _ready() -> void:
		for i in 90:
			_pieces.append({
				"p": Vector2(randf(), randf_range(-0.3, 0.0)),
				"v": Vector2(randf_range(-0.15, 0.15), randf_range(0.25, 0.7)),
				"c": Color.from_hsv(randf(), 0.7, 1.0),
				"s": randf_range(5.0, 12.0),
				"r": randf() * TAU,
			})
	func _process(delta: float) -> void:
		_t += delta
		for p in _pieces:
			p["p"] += p["v"] * delta
			p["r"] += delta * 3.0
		queue_redraw()
		if _t > 4.0:
			queue_free()
	func _draw() -> void:
		for p in _pieces:
			var pos: Vector2 = p["p"] * size
			draw_set_transform(pos, p["r"], Vector2.ONE)
			draw_rect(Rect2(Vector2(-p["s"] * 0.5, -p["s"] * 0.3), Vector2(p["s"], p["s"] * 0.6)), p["c"])
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
