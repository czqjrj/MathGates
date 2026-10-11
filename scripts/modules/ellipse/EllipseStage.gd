extends StageBase
## 圆锥曲线 · 椭圆 · 知识体系闯关：左侧答题面板 + 右侧 2D 椭圆演示画布。
## 规则与平面向量一致：每关 3 题，≥80% 三星、≥60% 二星，否则失败；陷阱题扣星。

const DATA_PATH := "res://data/ellipse_levels.json"

var _plane: EllipsePlane

# ---------------------------------------------------------------- 配置钩子
func _module() -> String: return "ellipse"
func _pet_message() -> String: return "椭圆：一条绳子、两枚钉子画出的最美曲线～"
func _wrong_text() -> String: return "不对，再想想——注意 a 与 c 的关系、焦点位置与陷阱提示。"
func _default_color() -> String: return "#FF7EA8"
func _default_title() -> String: return "圆锥曲线 · 椭圆"

func _load() -> void:
	if FileAccess.file_exists(DATA_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if typeof(data) == TYPE_DICTIONARY:
			_all = data
	var lv: Dictionary = GameData.current_level
	if lv.has("ellipse"):
		_id = str(lv["ellipse"])
	if not _all.has(_id):
		_id = str(_all.keys()[0]) if _all.size() > 0 else "ellipse_1_1"
	if _all.has(_id):
		_cfg = _all[_id]
		_stages = _cfg.get("levels", [])

func _build_view() -> void:
	_plane = EllipsePlane.new()
	_plane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_plane.offset_left = float(UI.stage_layout()["view_left"])
	_plane.offset_top = 66.0
	_plane.offset_right = -14.0
	_plane.offset_bottom = -96.0
	_plane.state_changed.connect(func(v: String) -> void:
		if _live != null and v != "":
			_live.text = v
	)
	add_child(_plane)

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
	_q.text = str(s.get("q", ""))
	UI.tts_say(_q.text)
	_feed_clear()
	_hint.disabled = false
	_next.disabled = true
	_next.text = "下一关 →" if _idx < _stages.size() - 1 else "生成报告"
	for c in _ans.get_children():
		c.queue_free()
	_live = null
	_clear_opts()
	_plane.set_scene(s.get("scene", {}))
	var t := str(s.get("type", "choice"))
	if t == "interact":
		_plane.begin_task(s.get("task", {}))
		_build_interact(s)
	elif t == "explore":
		_plane.begin_task(s.get("task", {}))
		_build_explore(s)
	else:
		_build_choices(s)
	_ans.modulate.a = 0.0
	_q.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_ans, "modulate:a", 1.0, 0.28)
	tw.tween_property(_q, "modulate:a", 1.0, 0.22)
	_update_hud()

func _build_interact(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	_live.text = _plane.readout()
	var tip := UI.make_label(str(s.get("tip", "拖动右侧金色手柄，让读数对准目标值，再点击确认。")), 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tip)
	var b := Button.new()
	b.text = "确认"
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(110, 50)
	b.pressed.connect(_on_confirm)
	box.add_child(b)

func _build_explore(s: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_ans.add_child(box)
	_live = UI.mono_label("", 16, Color("#ffd479"))
	box.add_child(_live)
	_live.text = _plane.readout()
	var tip := UI.make_label(str(s.get("tip", "先拖动右侧手柄完成画布目标，再用结论回答下面的问题。")), 15, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tip)
	var b := Button.new()
	b.text = "确认操作"
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
		if _plane.is_task_ok():
			_explore_done = true
			Sound.play("correct")
			_set_followup_question(s)
			for c in _ans.get_children():
				c.queue_free()
			_live = null
			_build_choices(s)
			_show_feed(str(s.get("success", "很好！现在用观察到的结论回答下面的追问。")), UI.COL_SUCCESS)
		else:
			_wrong(str(s.get("retry", "读数还没对准目标，再调整试试。")))
		return
	if _plane.is_task_ok():
		_level_ok()
	else:
		_wrong(str(s.get("retry", "读数还没对准目标，再想想公式与方向。")))
