extends Control
## G2 · 关卡作者工具链：关卡预览器（编辑态雏形）。
##
## 运行（编辑器 / 本机，需 GUI）：
##   godot --path . res://tools/LevelPreview.tscn
## headless 自检（CI 用，不写盘）：
##   godot --headless --path . res://tools/LevelPreview.tscn -- --smoke
##
## 能力（对应 TODO G2 做法 1/2）：
##   1. 左侧选「章节 → 关卡 → 轮次」，右侧用**真实舞台**（LabStage/Lab3DStage/SequenceStage/
##      ConicStage/SolidChallenge）渲染该轮，所见即学生所见；
##   2. **热重载**：数据文件（data/*_levels.json / curriculum.json）被外部修改后 ~0.7s 自动刷新；
##   3. **编辑态**：改 q / ask / opts / ans / hint / explain / scene → 「写回 JSON」——
##      走 tools/json_text.gd 的文本级修改，只动目标字段，不重排文件（diff 最小）；
##   4. **校验**：内置 A5 校验器的轻量版（轮次编号 / ans 范围 / 选项重复 / 题干缺失与重复），
##      选关即显示，写回后自动复检。
##   代码驱动的遗留关（SolidChallenge 方法关 / ConicStage C1~C3）只读预览，不可写回。
##
## 说明：舞台内「下一关/返回」按钮会走真实导航离开预览器，属预期（预览器只负责「选关→看→改→存」闭环）。

const JsonText = preload("res://tools/json_text.gd")
const PREVIEW_USER := "g2preview"

var _ci := 0
var _li := 0
var _res: Dictionary = {}          ## { file, key, ro }
var _stage: Node = null
var _initial: Dictionary = {}      ## 表单初值（判断是否改动）
var _mtime_data := 0.0
var _mtime_curr := 0.0
var _smoke := false

# UI 控件
var _chap_btn: OptionButton
var _level_btn: OptionButton
var _round_btn: OptionButton
var _host: Control
var _status: Label
var _valid_box: RichTextLabel
var _path_label: Label
var _ro_label: Label
var _q_edit: TextEdit
var _ask_edit: TextEdit
var _opts_edit: TextEdit
var _ans_spin: SpinBox
var _hint_edit: TextEdit
var _explain_edit: TextEdit
var _scene_edit: TextEdit
var _save_btn: Button
var _ask_row: Control
var _opts_row: Control
var _ans_row: Control
var _scene_row: Control

const COL_ERR := Color("#ff6b6b")
const COL_WARN := Color("#ffd479")
const COL_OK := Color("#5AD8A6")

func _ready() -> void:
	_smoke = OS.get_cmdline_user_args().has("--smoke")
	if not _smoke:
		get_window().title = "衍数阁 · 关卡预览器（G2 作者工具链）"
		get_window().size = Vector2i(1720, 980)
	GameData.create_user(PREVIEW_USER, "player")
	GameData.login(PREVIEW_USER)
	await get_tree().process_frame
	_build_ui()
	_reload_all()
	if _smoke:
		await _run_smoke()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_logout()
	if what == NOTIFICATION_PREDELETE:
		_logout()

var _logged_out := false

func _logout() -> void:
	if _logged_out:
		return
	_logged_out = true
	GameData.logout()
	GameData.delete_user(PREVIEW_USER)

# ================================================================ UI 搭建

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#0d1220")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var split := HBoxContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 10)
	add_child(split)

	# ---- 左侧：选择 + 编辑
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(470, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.enable_touch_scroll(scroll)
	split.add_child(scroll)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	scroll.add_child(left)

	left.add_child(UI.mono_label("G2 关卡预览器", 20, UI.COL_ACCENT))
	_chap_btn = OptionButton.new()
	_level_btn = OptionButton.new()
	_round_btn = OptionButton.new()
	for b in [_chap_btn, _level_btn, _round_btn]:
		b.custom_minimum_size = Vector2(0, 40)
		left.add_child(b)
	_chap_btn.item_selected.connect(func(i: int) -> void:
		_ci = i
		_li = 0
		_fill_levels()
		_on_selection_changed())
	_level_btn.item_selected.connect(func(i: int) -> void:
		_li = i
		_fill_rounds()
		_on_selection_changed())
	_round_btn.item_selected.connect(func(_i: int) -> void:
		_on_selection_changed())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	left.add_child(row)
	_add_btn(row, "重建舞台", _on_rebuild)
	_add_btn(row, "重读数据", _on_reload_pressed)
	_add_btn(row, "校验本组", func() -> void: _refresh_valid())

	_path_label = UI.mono_label("", 12, UI.COL_TEXT_DIM)
	_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_path_label)
	_ro_label = UI.mono_label("", 13, COL_WARN)
	_ro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ro_label.visible = false
	left.add_child(_ro_label)

	left.add_child(UI.hairline(Vector2(0, 1)))

	_q_edit = _add_field(left, "题干 q", 74)
	_ask_row = _add_field_row(left, "追问 ask", 44)
	_ask_edit = _ask_row.get_child(1)
	_opts_row = _add_field_row(left, "选项 opts（每行一个）", 74)
	_opts_edit = _opts_row.get_child(1)
	_ans_row = _add_ans_row(left)
	_hint_edit = _add_field(left, "提示 hint（只给方法，不给答案）", 44)
	_explain_edit = _add_field(left, "解析 explain", 64)
	_scene_row = _add_field_row(left, "scene（JSON，改滑块/曲线参数）", 120)
	_scene_edit = _scene_row.get_child(1)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	left.add_child(row2)
	_save_btn = _add_btn(row2, "写回 JSON", _on_save)
	UI.primary_button(_save_btn)
	_save_btn.custom_minimum_size = Vector2(170, 46)
	_add_btn(row2, "还原表单", func() -> void: _fill_form())

	_status = UI.mono_label("就绪。", 13, UI.COL_TEXT_DIM)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_status)

	left.add_child(UI.mono_label("校验（A5 轻量版）", 13, UI.COL_ACCENT))
	_valid_box = RichTextLabel.new()
	_valid_box.bbcode_enabled = true
	_valid_box.fit_content = true
	_valid_box.custom_minimum_size = Vector2(0, 80)
	_valid_box.add_theme_font_size_override("normal_font_size", 13)
	left.add_child(_valid_box)

	# ---- 右侧：舞台
	_host = Control.new()
	_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_host.clip_contents = true
	split.add_child(_host)

	# ---- 热重载轮询
	var t := Timer.new()
	t.wait_time = 0.7
	t.timeout.connect(_poll_mtime)
	add_child(t)
	t.start()

func _add_btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := UI.ghost_button(text, cb, 14)
	b.custom_minimum_size = Vector2(0, 38)
	parent.add_child(b)
	return b

func _add_field(parent: Control, title: String, h: int) -> TextEdit:
	var row := _add_field_row(parent, title, h)
	return row.get_child(1)

func _add_field_row(parent: Control, title: String, h: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	box.add_child(UI.mono_label(title, 12, UI.COL_TEXT_DIM))
	var te := TextEdit.new()
	te.custom_minimum_size = Vector2(0, h)
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.add_theme_font_size_override("font_size", 14)
	box.add_child(te)
	return box

func _add_ans_row(parent: Control) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)
	box.add_child(UI.mono_label("正确答案 ans", 12, UI.COL_TEXT_DIM))
	var sp := SpinBox.new()
	sp.min_value = 0
	sp.max_value = 9
	sp.custom_minimum_size = Vector2(100, 34)
	sp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(sp)
	return box

# ================================================================ 数据定位

func _current_level() -> Dictionary:
	var chs: Array = GameData.chapters
	if _ci < 0 or _ci >= chs.size():
		return {}
	var levels: Array = chs[_ci].get("levels", [])
	if _li < 0 or _li >= levels.size():
		return {}
	return levels[_li]

## 由 curriculum 关卡条目解析出数据文件与 key；代码驱动遗留关标记只读。
func _resolve(lv: Dictionary) -> Dictionary:
	if lv.has("lab"):
		return {"file": "res://data/%s_levels.json" % str(lv["lab"]), "key": str(lv.get("lab_ref", lv.get("id", ""))), "ro": false}
	if lv.has("sequence"):
		return {"file": "res://data/recurrence_levels.json", "key": str(lv["sequence"]), "ro": false}
	if lv.has("conic"):
		return {"file": "res://data/conic_levels.json", "key": str(lv["conic"]), "ro": true}
	if lv.has("method"):
		return {"file": "res://data/solid_methods.json", "key": str(lv["method"]), "ro": true}
	return {}

func _disk_group() -> Dictionary:
	if _res.is_empty():
		return {}
	if not FileAccess.file_exists(_res["file"]):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(_res["file"]))
	if typeof(data) != TYPE_DICTIONARY or not data.has(_res["key"]):
		return {}
	var g = data[_res["key"]]
	return g if typeof(g) == TYPE_DICTIONARY else {}

## 定位 (key, 轮次 ri) 在原始文本里的 span。
func _round_span(raw: String, ri: int) -> Dictionary:
	var f := JsonText.find_key(raw, str(_res["key"]))
	if f.is_empty() or raw[int(f["v"])] != "{":
		return {}
	var gend := JsonText.match_bracket(raw, int(f["v"]))
	if gend < 0:
		return {}
	var lf := JsonText.find_key(raw, "levels", int(f["v"]), gend)
	if lf.is_empty() or raw[int(lf["v"])] != "[":
		return {}
	return JsonText.nth_element(raw, int(lf["v"]), ri)

# ================================================================ 下拉填充 / 选择

func _reload_all() -> void:
	GameData._load_curriculum()
	_fill_chapters()
	_fill_levels()
	_fill_rounds()
	_on_selection_changed()
	_mtime_curr = _mtime("res://data/curriculum.json")

func _fill_chapters() -> void:
	_chap_btn.clear()
	for ci in GameData.chapters.size():
		var ch: Dictionary = GameData.chapters[ci]
		_chap_btn.add_item("%d · %s（%s）" % [ci + 1, str(ch.get("title", "")), str(ch.get("kind", ""))])
	_chap_btn.selected = clampi(_ci, 0, _chap_btn.item_count - 1)
	_ci = _chap_btn.selected

func _fill_levels() -> void:
	_level_btn.clear()
	if _ci >= GameData.chapters.size():
		return
	var levels: Array = GameData.chapters[_ci].get("levels", [])
	for li in levels.size():
		var lv: Dictionary = levels[li]
		_level_btn.add_item("%s（%s）" % [str(lv.get("name", "")), str(lv.get("id", ""))])
	_level_btn.selected = clampi(_li, 0, _level_btn.item_count - 1)
	_li = _level_btn.selected

func _fill_rounds() -> void:
	_round_btn.clear()
	var g := _disk_group()
	var rounds: Array = g.get("levels", [])
	for ri in rounds.size():
		var s: Dictionary = rounds[ri]
		_round_btn.add_item("轮%d · %s" % [ri + 1, str(s.get("name", "(无标签)"))])
	if _round_btn.item_count > 0:
		_round_btn.selected = clampi(_round_btn.selected, 0, _round_btn.item_count - 1)
	_round_btn.visible = _round_btn.item_count > 0

func _on_selection_changed() -> void:
	_res = _resolve(_current_level())
	var lv := _current_level()
	_path_label.text = "%s : %s%s" % [str(_res.get("file", "?")), str(_res.get("key", "?")),
		("  ·  scene=" + str(lv.get("scene", ""))) if lv.has("scene") else ""]
	var ro := bool(_res.get("ro", false))
	_ro_label.visible = ro
	_ro_label.text = "只读：该关为代码驱动的遗留模块（A2/A16），不可写回 JSON。"
	_save_btn.disabled = ro or _res.is_empty()
	if _res.has("file"):
		_mtime_data = _mtime(str(_res["file"]))
	_fill_form()
	_refresh_valid()
	_spawn_stage()

# ================================================================ 舞台

func _clear_stage() -> void:
	if _stage != null and is_instance_valid(_stage):
		_stage.queue_free()
		_stage = null

func _on_rebuild() -> void:
	_spawn_stage()

func _spawn_stage() -> void:
	_clear_stage()
	var lv := _current_level()
	if lv.is_empty() or _res.is_empty():
		return
	if not GameData.start_level(_ci, _li):
		_set_status("start_level 失败（chapter=%d level=%d）" % [_ci, _li], COL_ERR)
		return
	var scene_path := str(lv.get("scene", "res://scenes/LabStage.tscn"))
	if not ResourceLoader.exists(scene_path):
		_set_status("scene 不存在：%s（回退 LabStage）" % scene_path, COL_WARN)
		scene_path = "res://scenes/LabStage.tscn"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_set_status("无法加载 scene：%s" % scene_path, COL_ERR)
		return
	_stage = packed.instantiate()
	_host.add_child(_stage)
	await get_tree().process_frame
	await get_tree().process_frame
	await _jump_round()

func _jump_round() -> void:
	if _stage == null or not is_instance_valid(_stage):
		return
	var stages = _stage.get("_stages")
	if stages is Array and not stages.is_empty() and _round_btn.selected >= 0:
		_stage.set("_idx", clampi(_round_btn.selected, 0, stages.size() - 1))
		if _stage.has_method("_load_q"):
			_stage._load_q()

# ================================================================ 表单

func _fill_form() -> void:
	var g := _disk_group()
	var rounds: Array = g.get("levels", [])
	var ri := _round_btn.selected
	var editable := not bool(_res.get("ro", false)) and ri >= 0 and ri < rounds.size()
	_initial = {}
	if not editable:
		for te in [_q_edit, _ask_edit, _opts_edit, _hint_edit, _explain_edit, _scene_edit]:
			te.text = ""
			te.editable = false
		_ans_spin.editable = false
		return
	var s: Dictionary = rounds[ri]
	_q_edit.editable = true
	_ans_spin.editable = true
	_q_edit.text = str(s.get("q", ""))
	_ask_edit.text = str(s.get("ask", ""))
	var opts: Array = s.get("opts", [])
	var opt_lines: Array[String] = []
	for o in opts:
		opt_lines.append(str(o))
	_opts_edit.text = "\n".join(opt_lines)
	_ans_spin.max_value = maxi(0, opts.size() - 1)
	_ans_spin.value = float(s["ans"]) if typeof(s.get("ans", null)) == TYPE_INT else 0.0
	_hint_edit.text = str(s.get("hint", ""))
	_explain_edit.text = str(s.get("explain", ""))
	_scene_edit.text = JSON.stringify(s["scene"], "  ") if s.has("scene") else ""
	var t := str(s.get("type", "choice"))
	_ask_row.visible = s.has("ask") or t == "explore"
	_opts_row.visible = s.has("opts") or t in ["choice", "explore"]
	_ans_row.visible = _opts_row.visible or t == "input"
	_scene_row.visible = s.has("scene")
	_initial = _form_snapshot()

func _form_snapshot() -> Dictionary:
	return {
		"q": _q_edit.text, "ask": _ask_edit.text, "opts": _opts_edit.text,
		"ans": int(_ans_spin.value), "hint": _hint_edit.text,
		"explain": _explain_edit.text, "scene": _scene_edit.text,
	}

# ================================================================ 写回

func _on_save() -> void:
	if bool(_res.get("ro", false)) or _res.is_empty():
		return
	var path := str(_res["file"])
	var key := str(_res["key"])
	var ri := _round_btn.selected
	var raw := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY or not data.has(key):
		_set_status("写回失败：数据组 %s 不在 %s" % [key, path], COL_ERR)
		return
	# 选项：按行拆分并预检
	var new_opts: Array[String] = []
	for line in _opts_edit.text.split("\n"):
		var t := line.strip_edges()
		if t != "":
			new_opts.append(t)
	var snap := _form_snapshot()
	var new_raw := raw
	# 逐字段文本级替换（每次重新定位，span 随文本变化）
	if snap["q"] != _initial.get("q", "") or (snap["q"] != "" and not _field_exists(new_raw, "q", ri)):
		new_raw = _edit_str(new_raw, ri, "q", snap["q"])
	if _ask_row.visible and snap["ask"] != _initial.get("ask", ""):
		new_raw = _edit_str(new_raw, ri, "ask", snap["ask"])
	if _opts_row.visible and snap["opts"] != _initial.get("opts", ""):
		if new_opts.size() < 2:
			_set_status("写回失败：选项至少 2 个（当前 %d）" % new_opts.size(), COL_ERR)
			return
		new_raw = _edit_value(new_raw, ri, "opts", new_opts)
	if _ans_row.visible and int(snap["ans"]) != int(_initial.get("ans", 0)):
		var lim := new_opts.size() if _opts_row.visible else _current_ans_limit()
		if int(snap["ans"]) < 0 or int(snap["ans"]) >= maxi(lim, 1):
			_set_status("写回失败：ans=%d 超出选项范围（0..%d）" % [int(snap["ans"]), maxi(lim, 1) - 1], COL_ERR)
			return
		new_raw = _edit_value(new_raw, ri, "ans", int(snap["ans"]))
	if snap["hint"] != _initial.get("hint", ""):
		new_raw = _edit_str(new_raw, ri, "hint", snap["hint"])
	if snap["explain"] != _initial.get("explain", ""):
		new_raw = _edit_str(new_raw, ri, "explain", snap["explain"])
	if _scene_row.visible and snap["scene"] != _initial.get("scene", ""):
		var sc = JSON.parse_string(str(snap["scene"]))
		if typeof(sc) != TYPE_DICTIONARY:
			_set_status("写回失败：scene 不是合法 JSON 对象", COL_ERR)
			return
		new_raw = _edit_value(new_raw, ri, "scene", sc)
	# 终检：可解析 + 组数/轮数不变
	var chk = JSON.parse_string(new_raw)
	var old_groups: Dictionary = data
	var ok_parse := typeof(chk) == TYPE_DICTIONARY and (chk as Dictionary).size() == old_groups.size()
	var ok_rounds := false
	if ok_parse:
		var nr: Variant = (chk as Dictionary).get(key, {}).get("levels", null)
		ok_rounds = nr is Array and nr.size() == (old_groups[key].get("levels", []) as Array).size()
	if not ok_parse or not ok_rounds:
		_set_status("写回失败：文本级修改未通过结构校验（未写盘）", COL_ERR)
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_set_status("写回失败：无法打开 %s 写入" % path, COL_ERR)
		return
	f.store_string(new_raw)
	f.close()
	_mtime_data = _mtime(path)
	_set_status("已写回 %s : %s · 轮%d" % [path.get_file(), key, ri + 1], COL_OK)
	_fill_rounds()
	_fill_form()
	_refresh_valid()
	_spawn_stage()

func _current_ans_limit() -> int:
	var g := _disk_group()
	var rounds: Array = g.get("levels", [])
	var ri := _round_btn.selected
	if ri < 0 or ri >= rounds.size():
		return 4
	return (rounds[ri] as Dictionary).get("opts", []).size()

func _field_exists(raw: String, field: String, ri: int) -> bool:
	var span := _round_span(raw, ri)
	if span.is_empty():
		return false
	return not JsonText.find_key(raw, field, int(span["start"]), int(span["end"])).is_empty()

func _edit_str(raw: String, ri: int, field: String, text: String) -> String:
	return _edit_value(raw, ri, field, text)

func _edit_value(raw: String, ri: int, field: String, value: Variant) -> String:
	var span := _round_span(raw, ri)
	if span.is_empty():
		return raw
	var s := int(span["start"])
	var e := int(span["end"])
	var f := JsonText.find_key(raw, field, s, e)
	if f.is_empty():
		# 字段不存在 → 追加到该轮对象末尾
		var ind := JsonText.line_indent(raw, e)
		return JsonText.insert_into_object(raw, e, '"%s": %s' % [field, JsonText.embed(value, ind + "  ")])
	var v := int(f["v"])
	var vend := JsonText.value_end(raw, v)
	if vend < 0:
		return raw
	var text := JSON.stringify(value)
	if typeof(value) == TYPE_DICTIONARY or (typeof(value) == TYPE_ARRAY and (value as Array).size() > 1):
		text = JsonText.embed(value, JsonText.line_indent(raw, s))
	return raw.substr(0, v) + text + raw.substr(vend)

# ================================================================ 校验（A5 轻量版）

func _refresh_valid() -> void:
	var msgs := _validate_group()
	_valid_box.clear()
	if msgs.is_empty():
		_valid_box.append_text("[color=#5AD8A6]✓ 本组校验通过（轮次编号 / ans 范围 / 选项去重 / 题干）[/color]")
	else:
		for m in msgs:
			_valid_box.append_text("[color=#ff6b6b]· %s[/color]\n" % m)

func _validate_group() -> Array[String]:
	var out: Array[String] = []
	var g := _disk_group()
	if g.is_empty():
		if not _res.is_empty():
			out.append("数据组未找到：%s : %s" % [str(_res.get("file", "?")), str(_res.get("key", "?"))])
		return out
	var path := str(_res["file"])
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	var gno := 0
	var idx := 0
	for k in (data as Dictionary).keys():
		idx += 1
		if str(k) == str(_res["key"]):
			gno = idx
			break
	var rounds: Array = g.get("levels", [])
	var stems := {}
	for ri in rounds.size():
		var s: Dictionary = rounds[ri]
		var tag := "轮%d「%s」" % [ri + 1, str(s.get("name", "?"))]
		var nm := str(s.get("name", ""))
		if gno > 0 and not nm.begins_with("%d-%d " % [gno, ri + 1]):
			out.append("%s 标签编号应为 %d-%d（B9）" % [tag, gno, ri + 1])
		var t := str(s.get("type", "choice"))
		if s.has("opts") or t in ["choice", "explore"]:
			var opts: Array = s.get("opts", [])
			if opts.size() < 2:
				out.append("%s 选项数 <2" % tag)
			var seen := {}
			for o in opts:
				if seen.has(str(o)):
					out.append("%s 选项重复：%s" % [tag, str(o).left(16)])
				seen[str(o)] = true
			var ans = s.get("ans", null)
			if typeof(ans) == TYPE_INT and (ans < 0 or ans >= opts.size()):
				out.append("%s ans=%d 超出范围（0..%d）" % [tag, ans, opts.size() - 1])
		if t != "interact" and str(s.get("q", "")).strip_edges() == "" and not s.has("ask"):
			out.append("%s 缺题干 q" % tag)
		var q := str(s.get("q", "")).strip_edges()
		if q != "":
			if stems.has(q):
				out.append("%s 题干与轮%d重复" % [tag, int(stems[q]) + 1])
			stems[q] = ri
	return out

# ================================================================ 热重载

func _mtime(path: String) -> float:
	return FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0.0

func _poll_mtime() -> void:
	if _smoke:
		return
	var mc := _mtime("res://data/curriculum.json")
	if mc != _mtime_curr:
		_mtime_curr = mc
		_reload_all()
		_set_status("检测到 curriculum.json 变更，已重载。", COL_WARN)
		return
	if _res.is_empty() or not _res.has("file"):
		return
	var md := _mtime(str(_res["file"]))
	if md != _mtime_data and md != 0.0:
		_mtime_data = md
		_fill_rounds()
		_fill_form()
		_refresh_valid()
		_spawn_stage()
		_set_status("检测到 %s 变更，已刷新。" % str(_res["file"]).get_file(), COL_WARN)

func _on_reload_pressed() -> void:
	_reload_all()
	_set_status("已重读数据。", UI.COL_TEXT_DIM)

func _set_status(text: String, col: Color) -> void:
	_status.add_theme_color_override("font_color", col)
	_status.text = text

# ================================================================ headless 自检（CI）

func _run_smoke() -> void:
	var ok := 0
	var fail := 0
	# ---- A. 定位器全量回归：每个 *_levels.json 的每个组/轮/字段
	var d := DirAccess.open("res://data")
	var files: Array[String] = []
	for f in d.get_files():
		if f.ends_with("_levels.json"):
			files.append("res://data/" + f)
	files.sort()
	for path in files:
		var raw := FileAccess.get_file_as_string(path)
		var data = JSON.parse_string(raw)
		if typeof(data) != TYPE_DICTIONARY:
			fail += 1
			print("  [FAIL] 解析失败 ", path)
			continue
		ok += 1
		if JsonText.top_close(raw) < 0:
			fail += 1
			print("  [FAIL] 找不到顶层 } ", path)
		for key in (data as Dictionary).keys():
			var fv := JsonText.find_key(raw, str(key))
			if fv.is_empty() or raw[int(fv["v"])] != "{":
				fail += 1
				print("  [FAIL] 组定位失败 ", path, " ", key)
				continue
			ok += 1
			var gend := JsonText.match_bracket(raw, int(fv["v"]))
			var lf := JsonText.find_key(raw, "levels", int(fv["v"]), gend)
			if lf.is_empty() or raw[int(lf["v"])] != "[":
				fail += 1
				print("  [FAIL] levels 定位失败 ", path, " ", key)
				continue
			ok += 1
			var rounds: Array = data[key].get("levels", [])
			for ri in rounds.size():
				var span := JsonText.nth_element(raw, int(lf["v"]), ri)
				if span.is_empty():
					fail += 1
					print("  [FAIL] 轮定位失败 ", path, " ", key, " #", ri)
					continue
				ok += 1
				var s: Dictionary = rounds[ri]
				var st := int(span["start"])
				var en := int(span["end"])
				for field in ["name", "q", "ask", "hint", "explain"]:
					if s.has(field):
						var got := JsonText.key_string(raw, field, st, en)
						if got != str(s[field]):
							fail += 1
							print("  [FAIL] 字段定位失败 ", path, " ", key, " #", ri, " ", field)
						else:
							ok += 1
				for field in ["opts", "scene"]:
					if s.has(field):
						var fv2 := JsonText.find_key(raw, field, st, en)
						var want := "[" if field == "opts" else "{"
						if fv2.is_empty() or raw[int(fv2["v"])] != want:
							fail += 1
							print("  [FAIL] ", field, " 定位失败 ", path, " ", key, " #", ri)
						else:
							ok += 1
				if typeof(s.get("ans", null)) == TYPE_INT:
					var fv3 := JsonText.find_key(raw, "ans", st, en)
					if fv3.is_empty():
						fail += 1
						print("  [FAIL] ans 定位失败 ", path, " ", key, " #", ri)
					else:
						var v := int(fv3["v"])
						var lit := raw.substr(v, JsonText.value_end(raw, v) - v)
						if int(JSON.parse_string(lit)) != int(s["ans"]):
							fail += 1
							print("  [FAIL] ans 值不一致 ", path, " ", key, " #", ri)
						else:
							ok += 1
	# ---- B. 内存编辑往返（不写盘）：替换 q 后可解析、结构不变、题干生效
	var test_file := "res://data/circle_levels.json"
	var raw2 := FileAccess.get_file_as_string(test_file)
	var data2 = JSON.parse_string(raw2)
	var key2 := str(data2.keys()[0])
	var f2 := JsonText.find_key(raw2, key2)
	var g2end := JsonText.match_bracket(raw2, int(f2["v"]))
	var lf2 := JsonText.find_key(raw2, "levels", int(f2["v"]), g2end)
	var span2 := JsonText.nth_element(raw2, int(lf2["v"]), 0)
	var saved := _res
	_res = {"file": test_file, "key": key2}
	var edited := _edit_str(raw2, 0, "q", "【smoke】题干替换自检")
	_res = saved
	var chk = JSON.parse_string(edited)
	var ok_edit := false
	if typeof(chk) == TYPE_DICTIONARY and (chk as Dictionary).size() == (data2 as Dictionary).size() and not span2.is_empty():
		var f2b := JsonText.find_key(edited, key2)
		if not f2b.is_empty():
			var g2b := JsonText.match_bracket(edited, int(f2b["v"]))
			var lfb := JsonText.find_key(edited, "levels", int(f2b["v"]), g2b)
			var spanb := JsonText.nth_element(edited, int(lfb["v"]), 0)
			ok_edit = JsonText.key_string(edited, "q", int(spanb["start"]), int(spanb["end"])) == "【smoke】题干替换自检"
	if ok_edit:
		ok += 1
	else:
		fail += 1
		print("  [FAIL] 内存编辑往返")
	# ---- C. 校验器自身：对26 个文件逐组跑 _validate_group 的纯数据版
	for path in files:
		var data3 = JSON.parse_string(FileAccess.get_file_as_string(path))
		for key in (data3 as Dictionary).keys():
			var rounds3: Array = data3[key].get("levels", [])
			for ri in rounds3.size():
				var s3: Dictionary = rounds3[ri]
				if typeof(s3.get("ans", null)) == TYPE_INT and s3.has("opts"):
					var n: int = (s3["opts"] as Array).size()
					if int(s3["ans"]) >= 0 and int(s3["ans"]) < n:
						ok += 1
					else:
						fail += 1
						print("  [FAIL] ans 越界（存量）", path, " ", key, " #", ri)
	# ---- D. 舞台构建：每类场景抽样 spawn
	var picks := {}
	for ci in GameData.chapters.size():
		var levels: Array = GameData.chapters[ci].get("levels", [])
		for li in levels.size():
			var sc := str(levels[li].get("scene", ""))
			if not picks.has(sc):
				picks[sc] = []
			if (picks[sc] as Array).size() < 2:
				(picks[sc] as Array).append([ci, li])
	for sc in picks:
		for p in (picks[sc] as Array):
			_ci = p[0]
			_li = p[1]
			_res = _resolve(_current_level())
			await _spawn_stage()
			await get_tree().process_frame
			var stages = _stage.get("_stages") if _stage != null else null
			if _stage != null and (stages == null or (stages is Array and not stages.is_empty())):
				ok += 1
			else:
				fail += 1
				print("  [FAIL] 舞台构建 ", sc, " ", _current_level().get("id", ""))
			_clear_stage()
			await get_tree().process_frame
	print("LEVEL-PREVIEW-SMOKE: %d ok, %d fail" % [ok, fail])
	_logout()
	get_tree().quit(1 if fail > 0 else 0)
