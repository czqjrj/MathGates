class_name StageBase
extends Control
## 2D「闯关式」关卡共享骨架：顶栏 HUD、左侧答题面板、选项行、结算面板与上下关导航。
##
## 子类只需实现：_load()/_build_view()/_load_q()/_on_confirm()/_build_interact()/
## _build_explore()，并按需覆写配置钩子
## (_module/_pet_message/_wrong_text/_default_color/_default_title/_use_rich_text 等)。

## 关卡选项内联公式图的缩放系数(单一来源 UI)。
const CHOICE_FORMULA_SCALE := UI.CHOICE_FORMULA_SCALE

# ---------------------------------------------------------------- 数据
var _all: Dictionary = {}
var _id := ""
var _cfg: Dictionary = {}
var _stages: Array = []
var _pet: Pet

# ---------------------------------------------------------------- HUD
var _ui: Control
var _top_fill: ColorRect
var _prog: Label
var _coins: Label
var _panel: PanelContainer
var _title: Label
var _q: RichTextLabel
var _ans: VBoxContainer
var _feed: Control
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

# ---------------------------------------------------------------- 选项
var _opt_btns: Array[Button] = []
var _opt_panels: Array[PanelContainer] = []
var _opt_badges: Array[PanelContainer] = []
var _opt_contents: Array[Control] = []
var _opt_marks: Array[Label] = []

# ---------------------------------------------------------------- 状态
var _idx := 0
var _clean: Array[int] = []
var _wrongs := 0
var _hint_used := false
var _solved := false
var _done := false
var _trap_missed := false
var _q_recorded := false
var _last_picked := -1
var _explore_done := false

func _ready() -> void:
	_load()
	add_child(TechBg.new())
	_build_view()
	_build_ui()
	_add_pet()
	_reset()

# ================================================================ 配置钩子(子类覆写)
func _module() -> String: return ""
func _pet_message() -> String: return "加油！卡住就点提示～"
func _wrong_text() -> String: return "不对，再想想。"
func _victory_text(passed: bool) -> String:
	return "推演通关" if passed else "推演失败 · 请复盘"
func _default_color() -> String: return "#5ee6ff"
func _default_title() -> String: return ""
func _back_text() -> String: return "← 知识体系"
func _back_row_text() -> String: return "返回知识体系"
func _back_scene() -> String: return "res://scenes/TheoremTree.tscn"
func _panel_label() -> String: return "QUERY"
func _report_label() -> String: return "MISSION REPORT"
func _prog_prefix() -> String: return "SEQ"
## true 时题干/反馈走内联公式(RichTextLabel)，否则纯文本(Label)。
func _use_rich_text() -> bool: return false
## 答对时的面板脉冲反馈(部分关卡没有)。
func _level_ok_fx() -> void: pass
func _next_min_width() -> int: return 200
func _bottom_half_width() -> int: return 300

# ================================================================ 子类必须实现
func _load() -> void: pass
func _build_view() -> void: pass
func _load_q() -> void: pass

## 进入追问阶段：把标题/题干切换为追问问题(可选字段 ask，缺省给通用提示)。
func _set_followup_question(s: Dictionary) -> void:
	var ask := str(s.get("ask", ""))
	if ask.is_empty():
		ask = "根据刚才的观察，选出正确结论："
	_title.text = "追问"
	if _use_rich_text():
		_q.text = UI.inline_formulas(ask)
		UI.tts_say(UI.strip_formulas(ask))
	else:
		_q.text = ask
		UI.tts_say(ask)

# ================================================================ 萌宠
func _add_pet() -> void:
	_pet = Pet.spawn(self, _pet_message())
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

func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.0005:
		return str(int(roundf(v)))
	return "%.2f" % v

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
		_wrong(_wrong_text())

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
			tex_r.modulate = Color(1, 1, 1, 1) if i == correct else (Color(1, 0.55, 0.6, 0.95) if i == picked else Color(1, 1, 1, 0.32))

func _level_ok() -> void:
	if _solved:
		return
	_solved = true
	if _wrongs == 0:
		_clean[_idx] = 1
	if not _q_recorded:
		_q_recorded = true
		GameData.record_answer(GameData.current_level_id(), _idx, str(_current().get("name", "")), true, -1, -1, _module())
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
	_level_ok_fx()

func _wrong(msg: String) -> void:
	if _solved or _done:
		return
	_wrongs += 1
	if bool(_current().get("trap", false)):
		_trap_missed = true
	if not _q_recorded:
		_q_recorded = true
		GameData.record_answer(GameData.current_level_id(), _idx, str(_current().get("name", "")), false, _last_picked, int(_current().get("ans", -1)), _module())
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
	_v_title.text = _victory_text(passed)
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
	tc.tween_method(func(v: float) -> void: _v_coins.text = "金币  +%d" % int(v), 0.0, float(reward), 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.tween_callback(func() -> void:
		if is_instance_valid(_v_coins):
			_v_coins.text = "金币  +%d      (共 %d)" % [reward, GameData.coins])

func _show_feed(msg: String, col: Color) -> void:
	if _feed == null:
		return
	if _feed is RichTextLabel:
		(_feed as RichTextLabel).text = "[color=#%s]%s[/color]" % [col.to_html(false), UI.inline_formulas(msg)]
		UI.tts_say(UI.strip_formulas(msg))
	else:
		(_feed as Label).text = msg
		(_feed as Label).add_theme_color_override("font_color", col)
		UI.tts_say(msg)

## 清空反馈区(供子类 _load_q 使用)。
func _feed_clear() -> void:
	if _feed is RichTextLabel:
		(_feed as RichTextLabel).text = ""
	elif _feed is Label:
		(_feed as Label).text = ""

func _update_hud() -> void:
	if _prog == null:
		return
	_prog.text = "%s %02d / %02d" % [_prog_prefix(), _idx + 1, _stages.size()]
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
	_top_fill.color = Color(str(_cfg.get("color", _default_color())))
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
	hb.add_child(UI.ghost_button(_back_text(), func() -> void:
		Scene.goto(_back_scene())
	))
	var vl := ColorRect.new()
	vl.color = UI.COL_LINE
	vl.custom_minimum_size = Vector2(1, 18)
	vl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vl)
	hb.add_child(UI.make_label(str(_cfg.get("title", _default_title())), 21))
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
	_prog = UI.mono_label("%s 00 / 00" % _prog_prefix(), 17, UI.COL_ACCENT)
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
	pv.add_child(UI.mono_label(_panel_label(), 13, UI.COL_ACCENT))
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
	if _use_rich_text():
		var fr := RichTextLabel.new()
		fr.bbcode_enabled = true
		fr.fit_content = true
		fr.scroll_active = false
		fr.selection_enabled = false
		fr.focus_mode = Control.FOCUS_NONE
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fr.custom_minimum_size = Vector2(0, 44)
		fr.add_theme_font_override("normal_font", UI.font())
		fr.add_theme_font_override("bold_font", UI.font())
		fr.add_theme_font_size_override("normal_font_size", UI.fs(15))
		fr.add_theme_color_override("default_color", UI.COL_TEXT_DIM)
		fr.add_theme_constant_override("line_separation", 4)
		_feed = fr
	else:
		var fl := UI.make_label("", 15, UI.COL_TEXT_DIM)
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fl.custom_minimum_size = Vector2(0, 44)
		_feed = fl
	pv.add_child(_feed)

	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.offset_left = -_bottom_half_width()
	bottom.offset_right = _bottom_half_width()
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
	bh.add_child(UI.ghost_button("重新挑战", func() -> void: _reset(), 16))
	_next = Button.new()
	_next.text = "下一关 →"
	_next.custom_minimum_size = Vector2(_next_min_width(), 52)
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
	vv.add_child(UI.mono_label(_report_label(), 13, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	_v_title = UI.make_label(_victory_text(true), 30, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_title)
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
	row.add_child(UI.ghost_button(_back_row_text(), func() -> void:
		Scene.goto(_back_scene())
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
	Confetti.spawn(_ui)
