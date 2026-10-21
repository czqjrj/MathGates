extends StageBase
## 数列「递推 → 通项公式」实验探究关卡（A1：已收口到 StageBase）。
## 由「方法推演」世界地图进入：按 GameData.current_level["sequence"] 载入 res://data/recurrence_levels.json。
##
## 本类只做「数列专属」的部分：
##   数据载入 / 右侧 SequencePlane 画布 / explore 两段式（先动手再回答追问）；
## 其余（HUD、选项乱序、连击条、限时降星、三星引导、BOSS 层、C1/C2 结算）由 StageBase 统一提供。

const DATA_PATH := "res://data/recurrence_levels.json"
const BACK_SCENE := "res://scenes/WorldMap.tscn"

var _view: Control
var _plane: SequencePlane

# ---------------------------------------------------------------- 配置钩子
func _module() -> String: return "sequence"
func _pet_message() -> String: return "动手试试，再回答追问～"
func _wrong_text() -> String: return "不对，再想想——看看右侧实验图形给出的规律。"
func _default_title() -> String: return "实验探究"
func _default_color() -> String: return "#FF99C3"
func _use_rich_text() -> bool: return true
func _panel_label() -> String: return "EXPERIMENT"
func _report_label() -> String: return "EXPERIMENT REPORT"
func _prog_prefix() -> String: return "EXP"
func _next_min_width() -> int: return 210
func _bottom_half_width() -> int: return 330
func _victory_text(passed: bool) -> String: return "实验通关" if passed else "实验失败 · 请复盘"
func _back_text() -> String: return "← " + Scene.origin_label("方法推演")
func _back_row_text() -> String: return "返回" + Scene.origin_label("方法推演")
func _back_scene() -> String: return BACK_SCENE

func _level_ok_fx() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate", Color(1.15, 1.15, 1.1), UI.DUR_TINY)
	tw.tween_property(_panel, "modulate", Color.WHITE, UI.DUR_NORMAL)

# ---------------------------------------------------------------- 数据 / 视图
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
	_plane.param_changed.connect(func(_v: float) -> void: _refresh_live())
	_view.add_child(_plane)

func _refresh_live() -> void:
	if _live == null or _plane == null:
		return
	if _plane.mode == "slider":
		_live.text = "当前 %s = %s　（拖动下方滑块调整）" % [_plane.param_label, _fmt(_plane.param)]

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
	_set_q(str(s.get("q", "")))
	UI.tts_say(_q_speak)
	_feed_clear()
	_hint.disabled = false
	_next.disabled = true
	_next.text = "下一关 →" if _idx < _stages.size() - 1 else "生成报告"
	for c in _ans.get_children():
		c.queue_free()
	_live = null
	_clear_opts()

	_plane.visible = true
	_plane.set_scene(s.get("scene", {}))
	var t := str(s.get("type", "choice"))
	if t == "explore":
		_build_explore(s)
	elif t == "interact":
		_build_interact(s)
	elif t == "input":
		_build_input(s)
	else:
		_build_choices(s)

	_ans.modulate.a = 0.0
	_q.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_ans, "modulate:a", 1.0, UI.DUR_SLOW)
	tw.tween_property(_q, "modulate:a", 1.0, UI.DUR_NORMAL)
	_update_hud()

# ---------------------------------------------------------------- 交互区(explore / interact)
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

func _build_interact(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	_refresh_live()
	var tip := UI.make_label(str(s.get("tip", "拖动画布下方的滑块，观察数列的变化，调到目标后点击确认。")), 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var b := Button.new()
	b.text = str(s.get("confirm", "确认"))
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(150, 50)
	b.pressed.connect(_on_confirm)
	box.add_child(b)

func _plane_ok() -> bool:
	return _plane == null or _plane.is_param_correct()

## 两段式：explore 先动手完成实验（gate 可要求参数正确），再回答追问(建构)。
func _on_confirm() -> void:
	if _solved or _done or _stages.is_empty():
		return
	_last_picked = -1
	var s := _current()
	if str(s.get("type", "")) == "explore" and not _explore_done:
		var gate := bool((s.get("task", {}) as Dictionary).get("gate", false))
		if (not gate) or _plane_ok():
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
	if _plane_ok():
		_level_ok()
	else:
		_wrong("参数还不对，再调调看——想想递推式是怎样变形的。")
