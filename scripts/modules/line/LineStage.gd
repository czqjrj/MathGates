extends StageBase
## 直线方程 · 知识体系闯关：左侧答题面板 + 右侧可交互坐标平面。
## 由知识体系进入：按 GameData.current_level["line"] 载入对应小关。
## 规则：每关 3 题，首次答对计为「无失误」；≥80% 三星，≥60% 二星，否则失败；
##       踩中陷阱题额外扣一星，规避陷阱奖励金币。

const DATA_PATH := "res://data/line_levels.json"

var _view: Control
var _plane: LinePlane
var _tilt: TiltExplorer
var _slope: SlopeExplorer
var _curve: SlopeCurve
var _lineeq: LineEqExplorer
var _dual: DualLineExplorer
var _dist: DistanceExplorer

# ---------------------------------------------------------------- 配置钩子
func _module() -> String: return "line"
func _pet_message() -> String: return "加油！卡住就点提示～"
func _wrong_text() -> String: return "不对，再想想——可以看右侧图形辅助分析。"
func _default_title() -> String: return "直线方程"
func _use_rich_text() -> bool: return true
func _next_min_width() -> int: return 210
func _bottom_half_width() -> int: return 330

## 答对时的面板脉冲反馈
func _level_ok_fx() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate", Color(1.15, 1.15, 1.1), 0.08)
	tw.tween_property(_panel, "modulate", Color.WHITE, 0.25)

func _load() -> void:
	if FileAccess.file_exists(DATA_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if typeof(data) == TYPE_DICTIONARY:
			_all = data
	var lv: Dictionary = GameData.current_level
	if lv.has("line"):
		_id = str(lv["line"])
	if not _all.has(_id):
		_id = str(_all.keys()[0]) if _all.size() > 0 else "line_1_1"
	if _all.has(_id):
		_cfg = _all[_id]
		_stages = _cfg.get("levels", [])

func _build_view() -> void:
	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.offset_left = float(UI.stage_layout()["view_left"])
	_view.offset_top = 66.0
	_view.offset_right = -14.0
	_view.offset_bottom = -96.0
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	_plane = LinePlane.new()
	_plane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_plane.param_changed.connect(func(v: float) -> void:
		if _live != null:
			_live.text = "当前 %s = %s" % [_plane.param_label, _fmt(v)]
	)
	_plane.point_moved.connect(func(p: Vector2) -> void:
		if _live != null:
			_live.text = "当前 P(%s, %s)" % [_fmt(p.x), _fmt(p.y)]
	)
	_view.add_child(_plane)

func _ensure_tilt() -> void:
	if _tilt != null:
		return
	_tilt = TiltExplorer.new()
	_tilt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tilt.visible = false
	_tilt.angle_changed.connect(func(d: float) -> void:
		if _live != null:
			_live.text = "当前 α = %s°" % _fmt(d)
	)
	_view.add_child(_tilt)

func _ensure_slope() -> void:
	if _slope != null:
		return
	_slope = SlopeExplorer.new()
	_slope.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slope.visible = false
	_view.add_child(_slope)

func _ensure_curve() -> void:
	if _curve != null:
		return
	_curve = SlopeCurve.new()
	_curve.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curve.visible = false
	_view.add_child(_curve)

func _ensure_lineeq() -> void:
	if _lineeq != null:
		return
	_lineeq = LineEqExplorer.new()
	_lineeq.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lineeq.visible = false
	_view.add_child(_lineeq)

func _ensure_dual() -> void:
	if _dual != null:
		return
	_dual = DualLineExplorer.new()
	_dual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dual.visible = false
	_dual.goal_reached.connect(func() -> void:
		if _feed != null:
			(_feed as RichTextLabel).text = "[color=#%s]达到目标！[/color]" % UI.COL_SUCCESS.to_html(false)
	)
	_view.add_child(_dual)

func _hide_views() -> void:
	_plane.visible = false
	if _tilt != null:
		_tilt.visible = false
	if _slope != null:
		_slope.visible = false
	if _curve != null:
		_curve.visible = false
	if _lineeq != null:
		_lineeq.visible = false
	if _dual != null:
		_dual.visible = false
	if _dist != null:
		_dist.visible = false

func _ensure_dist() -> void:
	if _dist != null:
		return
	_dist = DistanceExplorer.new()
	_dist.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dist.visible = false
	_view.add_child(_dist)

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
	_feed_clear()
	_hint.disabled = false
	_next.disabled = true
	_next.text = "下一关 →" if _idx < _stages.size() - 1 else "生成报告"
	for c in _ans.get_children():
		c.queue_free()
	_live = null
	_clear_opts()

	var sc: Dictionary = s.get("scene", {})
	var t := str(s.get("type", "choice"))
	if sc.has("tilt_explorer"):
		_hide_views()
		_ensure_tilt()
		_tilt.visible = true
		if t == "explore":
			_tilt.setup_task(sc, float(s.get("target", 0.0)), float(s.get("tol", 2.5)), str(s.get("task", "")))
			_build_explore(s)
		else:
			_tilt.setup(sc)
			_build_choices(s)
	elif sc.has("slope_explorer"):
		_hide_views()
		_ensure_slope()
		_slope.visible = true
		_slope.setup(sc)
		_build_choices(s)
	elif sc.has("slope_curve"):
		_hide_views()
		_ensure_curve()
		_curve.visible = true
		_curve.setup(sc)
		_build_choices(s)
	elif sc.has("lineeq_explorer"):
		_hide_views()
		_ensure_lineeq()
		_lineeq.visible = true
		_lineeq.setup(sc)
		_build_choices(s)
	elif sc.has("dual_explorer"):
		_hide_views()
		_ensure_dual()
		_dual.visible = true
		_dual.setup(sc)
		if t == "explore":
			_build_explore(s)
		else:
			_build_choices(s)
	elif sc.has("distance_explorer"):
		_hide_views()
		_ensure_dist()
		_dist.visible = true
		_dist.setup(sc)
		_build_choices(s)
	else:
		_hide_views()
		_plane.visible = true
		_plane.set_scene(sc)
		if t == "interact" and str(s.get("kind", "")) == "slider":
			_plane.begin_slider(s)
			_build_interact(s, "拖动滑块调整，满意后点击确认")
		elif t == "interact" and str(s.get("kind", "")) == "drag":
			_plane.begin_drag(s)
			_build_interact(s, "拖动图中金点 P，放到最佳位置后确认")
		elif t == "explore":
			# 实验探究式：先在坐标平面上拖动探究，再回答追问
			var task: Dictionary = s.get("task", {})
			_plane.begin_drag(task)
			_plane.derive_cfg = s.get("derive", {})
			_build_explore(s)
		else:
			_plane.mode = ""
			# 纯选择题也可提供探究：场景带 slider/drag 配置时启用滑块或可拖动动点
			if sc.has("slider"):
				_plane.begin_slider(sc["slider"])
				_plane.param_explore = true
				_live = UI.mono_label("当前 %s = %s" % [_plane.param_label, _fmt(_plane.param)], 16, Color("#ffd479"))
				_ans.add_child(_live)
			elif sc.has("drag"):
				_plane.begin_drag(sc["drag"])
			_build_choices(s)

	# 面板入场动画
	_ans.modulate.a = 0.0
	_q.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_ans, "modulate:a", 1.0, 0.28)
	tw.tween_property(_q, "modulate:a", 1.0, 0.22)
	_update_hud()

func _build_interact(s: Dictionary, tip_text: String) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	if str(s.get("kind", "")) == "slider":
		_live.text = "当前 %s = %s" % [str(s.get("param", "k")), _fmt(_plane.param)]
	else:
		_live.text = "当前 P(%s, %s)" % [_fmt(_plane.drag_pos.x), _fmt(_plane.drag_pos.y)]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var tip := UI.make_label(tip_text, 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(tip)
	var b := Button.new()
	b.text = "确认"
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(110, 50)
	b.pressed.connect(_on_confirm)
	row.add_child(b)

func _build_explore(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	if _plane != null and _plane.visible and _plane.mode == "drag":
		_live.text = "当前 P(%s, %s)" % [_fmt(_plane.drag_pos.x), _fmt(_plane.drag_pos.y)]
	var tip_text := str(s.get("tip", ""))
	if tip_text.is_empty():
		tip_text = "拖动直线，把「直线向上的方向」逆时针转到 α = %s°，再点击确认。" % _fmt(float(s.get("target", 0.0)))
	var tip := UI.make_label(tip_text, 15, UI.COL_TEXT_DIM)
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
	# 两段式：先动手完成目标，再回答追问
	if str(s.get("type", "")) == "explore" and not _explore_done:
		var gok := false
		if _tilt != null and _tilt.visible:
			gok = _tilt.is_task_correct()
		elif _dual != null and _dual.visible:
			gok = _dual.is_goal_ok()
		elif _plane != null and _plane.visible:
			# 坐标平面的探究：默认不判定(gate=false)，纯自由探索，随时进入追问
			gok = (not bool((s.get("task", {}) as Dictionary).get("gate", true))) or _plane.is_point_correct()
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
	var ok := false
	if str(s.get("kind", "slider")) == "slider":
		ok = _plane.is_param_correct()
	else:
		ok = _plane.is_point_correct()
	if ok:
		_level_ok()
	else:
		_wrong("位置还不对，再调调看——想想公式或对称关系。")
