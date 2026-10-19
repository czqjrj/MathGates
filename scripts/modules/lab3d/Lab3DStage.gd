extends StageBase
## 立体几何「真实网格 3D」实验探究关卡：左侧答题面板 + 右侧可旋转/缩放的 3D 实验室。
##
## 由知识体系进入：关卡在 curriculum.json 中带 "lab"（数据模块名）与 "lab_ref"（数据键），
## 数据文件 res://data/<lab>_levels.json，每关 3 轮，按「实验探究 → 建构知识 → 迁移应用」组织：
##   type="explore"  先拖动滑块/旋转模型做实验，再回答追问（建构结论）；
##   type="choice"   直接选择（建构/迁移）。
## 3D 场景由 scene 描述：solids / points / segments / faces / vectors / planes / spheres /
## circles / labels / readouts / sliders / highlight / view / anim（详见 SolidBuilder）。

var _view_reg: Control
var _view3d: Lab3DView
var _slider_box: VBoxContainer
var _toolbar: HBoxContainer
var _readout_lbl: Label
var _steps_lbl: Label
var _lab := ""
var _vars: Dictionary = {}
var _sliders: Array = []
var _answers: Dictionary = {}
var _tol: Dictionary = {}
var _step_idx := 0
var _guide_btn: Button

# ---------------------------------------------------------------- 配置钩子
func _module() -> String: return _lab if _lab != "" else "lab3d"
func _pet_message() -> String: return "转动模型看看：先把立体图形转一转，再动滑块做实验，最后作答～"
func _wrong_text() -> String: return "再想想——旋转模型、对照右侧 3D 图形再推一次。"
func _default_title() -> String: return "立体几何 · 实验探究"
func _default_color() -> String: return "#7EC8FF"
func _use_rich_text() -> bool: return true
func _next_min_width() -> int: return 210
func _bottom_half_width() -> int: return 330

func _level_ok_fx() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate", Color(1.15, 1.15, 1.1), 0.08)
	tw.tween_property(_panel, "modulate", Color.WHITE, 0.25)

func _load() -> void:
	var lv: Dictionary = GameData.current_level
	var module := str(lv.get("lab", ""))
	var ref := str(lv.get("lab_ref", lv.get("id", "")))
	if module != "":
		var path := "res://data/%s_levels.json" % module
		if FileAccess.file_exists(path):
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(data) == TYPE_DICTIONARY:
				_all = data
	_id = ref
	if not _all.has(_id):
		_id = str(_all.keys()[0]) if _all.size() > 0 else ""
	if _all.has(_id):
		_cfg = _all[_id]
		_stages = _cfg.get("levels", [])
	_lab = module

# ---------------------------------------------------------------- 视图
func _build_view() -> void:
	_view_reg = Control.new()
	_view_reg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view_reg.offset_left = float(UI.stage_layout()["view_left"])
	_view_reg.offset_top = 66.0
	_view_reg.offset_right = -14.0
	_view_reg.offset_bottom = -96.0
	_view_reg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view_reg)

	_view3d = Lab3DView.new()
	_view3d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view_reg.add_child(_view3d)

	# 左上：实时读数
	_readout_lbl = UI.mono_label("", 16, Color("#ffd479"))
	_readout_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_readout_lbl.offset_left = 14.0
	_readout_lbl.offset_top = 10.0
	_readout_lbl.offset_right = 380.0
	_readout_lbl.offset_bottom = 120.0
	_readout_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_readout_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view_reg.add_child(_readout_lbl)

	# 右上：视角工具条
	_toolbar = HBoxContainer.new()
	_toolbar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toolbar.offset_left = -430.0
	_toolbar.offset_right = -12.0
	_toolbar.offset_top = 10.0
	_toolbar.offset_bottom = 48.0
	_toolbar.add_theme_constant_override("separation", 6)
	_toolbar.alignment = BoxContainer.ALIGNMENT_END
	_view_reg.add_child(_toolbar)
	_toolbar.add_child(_tool_button("正视图", func() -> void: _view3d.preset_view("front")))
	_toolbar.add_child(_tool_button("俯视图", func() -> void: _view3d.preset_view("top")))
	_toolbar.add_child(_tool_button("侧视图", func() -> void: _view3d.preset_view("side")))
	_toolbar.add_child(_tool_button("斜视图", func() -> void: _view3d.preset_view("iso")))
	_toolbar.add_child(_tool_button("重置", func() -> void: _view3d.reset_view(true)))
	_toolbar.add_child(_tool_button("自动旋转", func() -> void:
		_view3d.auto_rotate = not _view3d.auto_rotate
		if _view3d.auto_rotate:
			_view3d._auto_pause = 0.0
	))
	_guide_btn = _tool_button("▶ 演示", func() -> void: _play_demo())
	_toolbar.add_child(_guide_btn)

	# 左下：滑块面板
	_slider_box = VBoxContainer.new()
	_slider_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_slider_box.offset_left = 14.0
	_slider_box.offset_right = 330.0
	_slider_box.offset_top = -250.0
	_slider_box.offset_bottom = -12.0
	_slider_box.add_theme_constant_override("separation", 6)
	_view_reg.add_child(_slider_box)

	# 底部提示
	var tip := UI.mono_label("拖动旋转 · 滚轮缩放 · 双击重置", 13, Color(UI.COL_TEXT_DIM, 0.85))
	tip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tip.offset_left = -360.0
	tip.offset_right = -14.0
	tip.offset_top = -36.0
	tip.offset_bottom = -14.0
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view_reg.add_child(tip)

func _tool_button(text: String, cb: Callable) -> Button:
	var b := UI.ghost_button(text, cb, 14)
	b.focus_mode = Control.FOCUS_NONE
	return b

# ---------------------------------------------------------------- 血条/读数
func _refresh_live() -> void:
	if _readout_lbl == null:
		return
	var parts: PackedStringArray = []
	for s in _sliders:
		parts.append("%s = %s" % [str(s["label"]), NumExpr.fmt(float(s["value"]))])
	_readout_lbl.text = "，".join(parts)
	# readouts 表达式
	var sc: Dictionary = _current().get("scene", {})
	for rd in _as_array(sc.get("readouts", [])):
		if not (rd is Dictionary):
			continue
		var d: Dictionary = rd
		var v := NumExpr.num(d.get("expr", 0.0), _vars, 0.0)
		_readout_lbl.text += "\n%s = %s" % [str(d.get("label", "值")), NumExpr.fmt(v)]

func _as_array(v: Variant) -> Array:
	return v if v is Array else []

func _slider_summary() -> String:
	var parts: PackedStringArray = []
	for s in _sliders:
		parts.append("%s = %s" % [str(s["label"]), NumExpr.fmt(float(s["value"]))])
	return "，".join(parts)

# ---------------------------------------------------------------- 关卡载入
func _load_q() -> void:
	if _stages.is_empty():
		return
	_solved = false
	_wrongs = 0
	_hint_used = false
	_explore_done = false
	_q_recorded = false
	_last_picked = -1
	_step_idx = 0
	var s := _current()
	_title.text = str(s.get("name", ""))
	var qraw := str(s.get("q", ""))
	_set_q(qraw)
	UI.tts_say(UI.strip_formulas(qraw))
	_feed_clear()
	_hint.disabled = false
	_next.disabled = true
	_next.text = "下一关 →" if _idx < _stages.size() - 1 else "生成报告"
	for c in _ans.get_children():
		c.queue_free()
	_live = null
	_clear_opts()
	_clear_sliders()

	var sc: Dictionary = s.get("scene", {})
	# 初始变量：滑块默认值
	_vars = {}
	_sliders = []
	_answers = {}
	_tol = {}
	for item in _as_array(sc.get("sliders", [])):
		if not (item is Dictionary):
			continue
		var d: Dictionary = item
		var lo := NumExpr.num(d.get("min", -5.0), _vars, -5.0)
		var hi := NumExpr.num(d.get("max", 5.0), _vars, 5.0)
		var val := NumExpr.num(d.get("value", lo), _vars, lo)
		var rec := {
			"name": str(d.get("name", "a")), "min": lo, "max": hi,
			"value": clampf(val, lo, hi), "step": NumExpr.num(d.get("step", 0.0), _vars, 0.0),
			"label": str(d.get("label", d.get("name", "a"))),
		}
		_sliders.append(rec)
		_vars[rec["name"]] = rec["value"]
	_answers = s.get("answers", sc.get("answers", {}))
	_tol = s.get("tol", sc.get("tol", {}))

	_view3d.set_scene(sc, _vars)
	_guide_btn.visible = s.has("anim") or sc.has("anim")
	if bool(s.get("autoplay", sc.get("autoplay", false))):
		_play_demo()

	var t := str(s.get("type", "choice"))
	var has_interactive := not _sliders.is_empty()
	if t == "explore":
		if has_interactive:
			_begin_interactive(s)
		_refresh_live()
		_build_explore(s)
	elif t == "interact" and has_interactive:
		_begin_interactive(s)
		_build_interact(s)
	elif t == "input":
		_build_input(s)
	else:
		if has_interactive:
			_begin_interactive(s)
		_refresh_live()
		_build_choices(s)

	_ans.modulate.a = 0.0
	_q.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_ans, "modulate:a", 1.0, 0.28)
	tw.tween_property(_q, "modulate:a", 1.0, 0.22)
	_update_hud()

func _clear_sliders() -> void:
	if _slider_box == null:
		return
	for c in _slider_box.get_children():
		c.queue_free()
	if _readout_lbl != null:
		_readout_lbl.text = ""

func _begin_interactive(_s: Dictionary) -> void:
	_build_sliders()

func _build_sliders() -> void:
	_clear_sliders()
	if _sliders.is_empty():
		return
	for i in _sliders.size():
		var s: Dictionary = _sliders[i]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var head := UI.make_label("%s = %s" % [str(s["label"]), NumExpr.fmt(float(s["value"]))], 15, UI.COL_TEXT)
		row.add_child(head)
		var sl := HSlider.new()
		sl.min_value = float(s["min"])
		sl.max_value = float(s["max"])
		sl.step = float(s["step"]) if float(s["step"]) > 0.0 else 0.01
		sl.value = float(s["value"])
		sl.custom_minimum_size = Vector2(0, 26)
		sl.mouse_filter = Control.MOUSE_FILTER_STOP
		sl.value_changed.connect(func(v: float) -> void:
			s["value"] = v
			head.text = "%s = %s" % [str(s["label"]), NumExpr.fmt(v)]
			_vars[str(s["name"])] = v
			_view3d.set_var(str(s["name"]), v)
			_refresh_live()
		)
		row.add_child(sl)
		_slider_box.add_child(row)
	_refresh_live()

func _play_demo() -> void:
	var s := _current()
	var a: Variant = s.get("anim", null)
	if a == null:
		a = s.get("scene", {}).get("anim", null)
	if a is Array and not (a as Array).is_empty():
		_view3d.play_anim(a)
		_show_feed("演示中……可继续拖动旋转观察。", UI.COL_ACCENT)
	elif a is Dictionary:
		_view3d.play_anim([a])

func _interactive_ok() -> bool:
	return _sliders_correct()

func _sliders_correct() -> bool:
	var checked := false
	for s in _sliders:
		var nm := str(s["name"])
		if _answers.has(nm):
			checked = true
			var av := NumExpr.num(_answers[nm], _vars, 0.0)
			if absf(float(s["value"]) - av) > NumExpr.num(_tol.get(nm, 0.02), _vars, 0.02):
				return false
	return checked

func _build_explore(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	var goal := str(s.get("goal", ""))
	if goal != "":
		var gl := UI.make_label("目标：" + goal, 15, Color(UI.COL_ACCENT, 0.95))
		gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(gl)
	var steps: Array = s.get("steps", [])
	if not steps.is_empty():
		box.add_child(UI.mono_label("实验步骤", 13, Color(UI.COL_ACCENT, 0.9)))
		for i in steps.size():
			var step := UI.make_label("%d. %s" % [i + 1, str(steps[i])], 14, Color(UI.COL_TEXT_DIM, 0.95))
			step.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(step)
	var tip_text := str(s.get("tip", "拖动左下角滑块改变参数，观察 3D 图形如何变化，再点击确认。"))
	var tip := UI.make_label(tip_text, 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 8)
	box.add_child(brow)
	var b := Button.new()
	b.text = str(s.get("confirm", "确认"))
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(150, 50)
	b.pressed.connect(_on_confirm)
	brow.add_child(b)
	if _has_anim(s):
		var db := UI.ghost_button("▶ 演示", func() -> void: _play_demo(), 16)
		db.custom_minimum_size = Vector2(110, 50)
		brow.add_child(db)

func _has_anim(s: Dictionary) -> bool:
	if s.has("anim"):
		return true
	var sc: Variant = s.get("scene", null)
	return sc is Dictionary and (sc as Dictionary).has("anim")

func _build_interact(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	var tip := UI.make_label(str(s.get("tip", "调整到目标状态后点击确认。")), 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var b := Button.new()
	b.text = str(s.get("confirm", "确认"))
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(150, 50)
	b.pressed.connect(_on_confirm)
	box.add_child(b)

func _on_confirm() -> void:
	if _solved or _done or _stages.is_empty():
		return
	_last_picked = -1
	var s := _current()
	if str(s.get("type", "")) == "explore" and not _explore_done:
		var gate := bool(s.get("gate", false))
		var ok := _interactive_ok()
		if (not gate) or ok:
			_explore_done = true
			Sound.play("correct")
			_set_followup_question(s)
			for c in _ans.get_children():
				c.queue_free()
			_live = null
			_build_choices(s)
			_show_feed(str(s.get("success", "很好！现在回答下面的追问。")), UI.COL_SUCCESS)
		else:
			_wrong(str(s.get("retry", "还不对，再调整滑块看看。")))
		return
	if _interactive_ok():
		_level_ok()
	else:
		_wrong("还没到目标状态，再调调看——观察参数与 3D 图形的关系。")
