extends StageBase
## 圆 · 知识体系闯关：左侧答题面板 + 右侧静态坐标平面(CirclePlane)。
## 由知识体系进入：按 GameData.current_level["circle"] 载入对应小关。
## 每关 3 题，均为选择题；右侧画布按题目的 scene 字段绘制圆/直线/点/线段辅助分析。

const DATA_PATH := "res://data/circle_levels.json"

var _view: Control
var _plane: CirclePlane

# ---------------------------------------------------------------- 配置钩子
func _module() -> String: return "circle"
func _pet_message() -> String: return "圆的每个性质都有图可依，卡住就点提示～"
func _wrong_text() -> String: return "不对，再想想——对照右侧图形再推一遍。"
func _default_title() -> String: return "圆"
func _default_color() -> String: return "#FFB35C"
func _use_rich_text() -> bool: return true
func _next_min_width() -> int: return 210
func _bottom_half_width() -> int: return 330

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
	if lv.has("circle"):
		_id = str(lv["circle"])
	if not _all.has(_id):
		_id = str(_all.keys()[0]) if _all.size() > 0 else "circle_1_1"
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
	_plane = CirclePlane.new()
	_plane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.add_child(_plane)

func _load_q() -> void:
	_wrongs = 0
	_hint_used = false
	_solved = false
	_explore_done = false
	_q_recorded = false
	_last_picked = -1
	var s := _current()
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
	_clear_opts()
	var sc: Dictionary = s.get("scene", {})
	_plane.set_scene(sc)
	_build_choices(s)
