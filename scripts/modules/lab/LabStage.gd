extends StageBase
## 知识体系「实验探究」通用关卡：左侧答题面板 + 右侧可交互实验室(LabPlane)。
## 由知识体系进入：章节关卡在 curriculum.json 中带 "lab"（数据模块名）与 "lab_ref"（数据键），
## 数据文件形如 res://data/<lab>_levels.json。新增章节只需补数据文件，无需再写 Stage 代码。
##
## 每关 3 轮，按「实验探究 → 建构知识 → 迁移应用」组织：
##   type="explore"  先动手调参/拖动完成实验，再回答追问(建构结论)；
##   type="choice"   直接选择（建构/迁移）。
## 通过 GIF 级别的实时重绘（曲线随滑块变化）呈现交互动画。

var _view: Control
var _plane: LabPlane
var _lab := ""
var _demo_btn: Button

# ---------------------------------------------------------------- 配置钩子
func _module() -> String: return _lab if _lab != "" else "lab"
func _pet_message() -> String: return "先动手调一调，再总结规律，最后学以致用～"
func _wrong_text() -> String: return "再想想——对照右侧实验现象再推一次。"
func _default_title() -> String: return "实验探究"
func _default_color() -> String: return "#5AD8A6"
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

func _build_view() -> void:
	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.offset_left = float(UI.stage_layout()["view_left"])
	_view.offset_top = 66.0
	_view.offset_right = -14.0
	_view.offset_bottom = -96.0
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	_plane = LabPlane.new()
	_plane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_plane.slider_changed.connect(func(_n: String, _v: float) -> void: _refresh_live())
	_plane.point_moved.connect(func(_p: Vector2) -> void: _refresh_live())
	_view.add_child(_plane)
	# 右上：演示按钮（仅当本轮 scene 带 anim 时显示，见 D2）
	_demo_btn = UI.ghost_button("▶ 演示", func() -> void: _play_demo(), 15)
	_demo_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_demo_btn.offset_left = -118.0
	_demo_btn.offset_right = -14.0
	_demo_btn.offset_top = 8.0
	_demo_btn.offset_bottom = 42.0
	_demo_btn.visible = false
	_view.add_child(_demo_btn)

## 播放本轮 scene.anim；未配置时按钮本身不显示。
func _play_demo() -> void:
	var s := _current()
	var a: Variant = s.get("anim", null)
	if a == null:
		a = s.get("scene", {}).get("anim", null)
	if a is Array and not (a as Array).is_empty():
		_plane.play_anim(a)
		_show_feed("演示中……可随时拖动滑块自己再试一次。", UI.COL_ACCENT)
	elif a is Dictionary:
		_plane.play_anim([a])

func _has_anim(s: Dictionary) -> bool:
	if s.has("anim"):
		return true
	var sc: Variant = s.get("scene", {})
	return sc is Dictionary and (sc as Dictionary).has("anim")

func _refresh_live() -> void:
	if _live == null:
		return
	if _plane.mode == "break":
		var st := _plane.coverage_status()
		_live.text = _plane.slider_summary() + ("    " + st if st != "" else "")
	elif _plane.mode == "sliders":
		_live.text = _plane.slider_summary()
	elif _plane.mode == "drag":
		_live.text = "P(%s, %s)" % [_fmt(_plane.drag_pos.x), _fmt(_plane.drag_pos.y)]

func _load_q() -> void:
	if _stages.is_empty():
		return
	_solved = false
	_wrongs = 0
	_hint_used = false
	_explore_done = false
	_q_recorded = false
	_last_picked = -1
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

	var sc: Dictionary = s.get("scene", {})
	_plane.set_scene(sc)
	if _demo_btn != null:
		_demo_btn.visible = _has_anim(s)
	var t := str(s.get("type", "choice"))
	var has_interactive := sc.has("sliders") or sc.has("drag") or sc.has("break")
	if t == "explore" and has_interactive:
		_begin_interactive(s)
		_build_explore(s)
	elif t == "interact" and has_interactive:
		_begin_interactive(s)
		_build_interact(s)
	elif t == "input":
		_build_input(s)
	else:
		if has_interactive:
			_begin_interactive(s)
		_build_choices(s)

	_ans.modulate.a = 0.0
	_q.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_ans, "modulate:a", 1.0, 0.28)
	tw.tween_property(_q, "modulate:a", 1.0, 0.22)
	_update_hud()

func _begin_interactive(s: Dictionary) -> void:
	var sc: Dictionary = s.get("scene", {})
	if sc.has("break"):
		_plane.begin_break(sc["break"])
	elif sc.has("sliders"):
		_plane.begin_sliders(sc["sliders"], s.get("answers", sc.get("answers", {})), s.get("tol", sc.get("tol", {})))
	elif sc.has("drag"):
		_plane.begin_drag(sc["drag"])

func _build_explore(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	_refresh_live()
	var goal := str(s.get("goal", ""))
	if goal != "":
		var gl := UI.make_label("目标：" + goal, 15, Color(UI.COL_ACCENT, 0.95))
		gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(gl)
	var steps: Array = s.get("steps", [])
	if not steps.is_empty():
		box.add_child(UI.mono_label("实验步骤", 13, Color(UI.COL_ACCENT, 0.9)))
		for i in steps.size():
			var step := UI.make_label(str(steps[i]), 14, Color(UI.COL_TEXT_DIM, 0.95))
			step.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(step)
	var tip_text := str(s.get("tip", "拖动下方滑块，观察图形随参数如何变化，再点击确认。"))
	var tip := UI.make_label(tip_text, 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var b := Button.new()
	b.text = str(s.get("confirm", "确认"))
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(150, 50)
	b.pressed.connect(_on_confirm)
	box.add_child(b)

func _build_interact(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	_refresh_live()
	var tip := UI.make_label(str(s.get("tip", "调整到目标状态后点击确认。")), 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var b := Button.new()
	b.text = str(s.get("confirm", "确认"))
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(150, 50)
	b.pressed.connect(_on_confirm)
	box.add_child(b)

func _interactive_ok() -> bool:
	if _plane.mode == "drag":
		return _plane.is_point_correct()
	if _plane.mode == "break":
		return _plane.is_break_correct()
	if _plane.mode == "sliders":
		return _plane.is_sliders_correct()
	return true

func _on_confirm() -> void:
	if _solved or _done or _stages.is_empty():
		return
	_last_picked = -1
	var s := _current()
	var sc: Dictionary = s.get("scene", {})
	# 两段式：先动手完成实验，再回答追问(建构知识)
	if str(s.get("type", "")) == "explore" and not _explore_done:
		var gate := bool(s.get("gate", sc.get("gate", false)))
		var ok := _interactive_ok()
		if (not gate) or ok:
			_explore_done = true
			Sound.play("correct")
			_set_followup_question(s)
			for c in _ans.get_children():
				c.queue_free()
			_live = null
			_plane.mode = ""
			_build_choices(s)
			_show_feed(str(s.get("success", "很好！现在回答下面的追问。")), UI.COL_SUCCESS)
		else:
			_wrong(str(s.get("retry", "还不对，再调整试试。")))
		return
	if _interactive_ok():
		_level_ok()
	else:
		_wrong("还没到目标状态，再调调看——观察参数与图形的关系。")
