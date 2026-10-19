extends SceneTree
## G2 · 关卡作者工具链：关卡脚手架（TODO G2 做法 3/4）。
##
## 按 E2 的「每章固定流程」生成一个**符合规范的新关卡组骨架**，避免手抄 30 行样板：
##   - data/<file>_levels.json 追加关卡组（5 轮：探究→建构→迁移→巩固→综合，ans=0，
##     数学式子位置一律留 `$$…$$` 占位说明，不新增 Unicode 片段）；
##   - `--chapter` 时同步追加 data/curriculum.json 该章 levels 条目（结构克隆自该章最后一条，
##     自动适配 LabStage/Lab3DStage 的 lab/lab_ref 字段）与 data/knowledge_map.json 该章 points
##     （E1 联动：新关卡必须挂知识点，否则 check_knowledge 退出 1）。
##
## 用法：
##   godot --headless --path . --script res://tools/scaffold_level.gd -- \
##       --file=inequalities_levels --key=ineq_demo [--chapter=inequalities] [--name="1-7 新关卡"] \
##       [--rounds=5] [--apply]
##   默认 dry-run（只打印骨架与将要写入的位置）；`--apply` 实际写入。
##
## 写入方式为「文本级追加」（tools/json_text.gd），不重排既有内容，git diff 最小。
## 写入后请按 §9.1 跑：fix_labels --apply → check_questions → check_knowledge → 四件套。

const JsonText = preload("res://tools/json_text.gd")

var _apply := false
var _file := ""
var _key := ""
var _chapter := ""
var _name := ""
var _rounds := 5

func _initialize() -> void:
	if not _parse_args():
		quit(1)
		return
	var path := _levels_path()
	if not FileAccess.file_exists(path):
		push_error("数据文件不存在：" + path)
		quit(1)
		return
	var raw := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("数据文件解析失败：" + path)
		quit(1)
		return
	if data.has(_key):
		push_error("key 已存在：" + _key + "（换一个 key，或先手工合并）")
		quit(1)
		return
	var group_no := (data as Dictionary).size() + 1
	var group := _build_group(group_no)
	print("SCAFFOLD: file=%s key=%s group_no=%d chapter=%s apply=%s" % [path, _key, group_no, _chapter if _chapter != "" else "(不写 curriculum)", _apply])

	if not _apply:
		print("--- 骨架预览（JSON.stringify 两空格缩进）---")
		print(JSON.stringify(group, "  "))
		print("--- dry-run 结束；加 `-- --apply` 实际写入 ---")
		quit(0)
		return

	# 1) 关卡数据文件：追加组
	var top := JsonText.top_close(raw)
	if top < 0:
		push_error("找不到 " + path + " 的顶层 }")
		quit(1)
		return
	var new_raw := JsonText.insert_into_object(raw, top, '"%s": %s' % [_key, JsonText.embed(group, "  ")])
	var chk = JSON.parse_string(new_raw)
	if typeof(chk) != TYPE_DICTIONARY or not chk.has(_key) or (chk as Dictionary).size() != (data as Dictionary).size() + 1:
		push_error("关卡文件追加未通过结构校验，未写盘")
		quit(1)
		return
	_write(path, new_raw)
	print("  + 已追加关卡组：%s : %s（%d 轮）" % [path.get_file(), _key, (group["levels"] as Array).size()])

	# 2) curriculum + knowledge_map（可选）
	var ok_curr := true
	if _chapter != "":
		ok_curr = _patch_chapter(path)
	if ok_curr:
		print("SCAFFOLD-OK")
		_print_reminders()
		quit(0)
	else:
		quit(1)

# ---------------------------------------------------------------- 参数

func _parse_args() -> bool:
	for a in OS.get_cmdline_user_args():
		if a == "--apply":
			_apply = true
			continue
		var kv := a.split("=", true, 1)
		if kv.size() != 2:
			continue
		var k := kv[0].trim_prefix("--")
		var v := kv[1]
		match k:
			"file":
				_file = v
			"key":
				_key = v
			"chapter":
				_chapter = v
			"name":
				_name = v
			"rounds":
				_rounds = clampi(int(v), 2, 8)
	if _file == "" or _key == "":
		push_error("用法：-- --file=<*_levels.json（可省略 _levels.json 后缀）> --key=<新组 key> [--chapter=<章 id>] [--name=<显示名>] [--rounds=5] [--apply]")
		return false
	return true

func _levels_path() -> String:
	var f := _file.trim_prefix("data/").trim_suffix(".json")
	if not f.ends_with("_levels"):
		f += "_levels"
	return "res://data/%s.json" % f

func _lab_name() -> String:
	return _file.trim_prefix("data/").trim_suffix(".json").trim_suffix("_levels")

# ---------------------------------------------------------------- 骨架

func _build_group(group_no: int) -> Dictionary:
	var todo_q := func(ri: int, what: String) -> String:
		return "【TODO %s-%d】%s（题面写任务句，不要把结论写进题面）" % [_key, ri, what]
	var todo_opts: Array = ["【TODO】选项 A", "【TODO】选项 B", "【TODO】选项 C", "【TODO】选项 D"]
	var lbl := func(ri: int, stage: String) -> String:
		return "%d-%d %s · 【待填】" % [group_no, ri, stage]
	var rounds: Array = []
	# 1 探究（explore 两段式：先动手，再回答追问）
	rounds.append({
		"name": lbl.call(1, "探究"), "type": "explore",
		"q": todo_q.call(1, "实验任务句"),
		"scene": {
			"range": 7,
			"sliders": [{ "name": "k", "min": -3, "max": 3, "value": 1, "step": 0.5, "label": "参数 k" }],
			"lines": [{ "A": 1, "B": -1, "C": "-k", "color": "#5AD8A6", "label": "y=x−k" }],
		},
		"goal": "【TODO】实验目标（调到什么状态）",
		"steps": ["【TODO】步骤 1", "【TODO】步骤 2"],
		"tip": "【TODO】操作提示（只讲方法，不泄露答案）",
		"confirm": "完成观察",
		"ask": "【TODO】追问：条件必须来自刚才的滑块/读数（B4 闭环）",
		"success": "很好！把刚才的观察总结成结论。",
		"opts": todo_opts.duplicate(), "ans": 0,
		"hint": "【TODO】只给方法/方向的提示（B12：不得泄露答案）",
		"explain": "【TODO】解析（数学式子写 $$…$$，如 $$x^2$$）",
	})
	# 2 建构 / 3 迁移（选择）
	for pair in [[2, "建构"], [3, "迁移"]]:
		var ri: int = pair[0]
		rounds.append({
			"name": lbl.call(ri, pair[1]), "type": "choice",
			"q": todo_q.call(ri, "概念辨析题干"),
			"opts": todo_opts.duplicate(), "ans": 0,
			"hint": "【TODO】方法提示",
			"explain": "【TODO】解析（干扰项须对应真实错误路径，见 B5）",
		})
	# 4 巩固（数值填空，B1 非四选一）
	rounds.append({
		"name": lbl.call(4, "巩固"), "type": "input",
		"q": todo_q.call(4, "数值填空题干（答案为纯数值）"),
		"ans": 0, "tol": 0.01,
		"hint": "【TODO】方法提示",
		"explain": "【TODO】解析",
	})
	# 5 综合（选择）
	rounds.append({
		"name": lbl.call(5, "综合"), "type": "choice",
		"q": todo_q.call(5, "综合题干（跨小问/跨情境）"),
		"opts": todo_opts.duplicate(), "ans": 0,
		"hint": "【TODO】方法提示",
		"explain": "【TODO】解析",
	})
	while rounds.size() > _rounds:
		rounds.pop_back()
	return {
		"title": "%s · 【待填】标题" % _key,
		"method": "实验探究 → 建构知识 → 迁移应用",
		"color": "#5AD8A6",
		"summary": "【TODO】一句话综述（显示在知识卡片上）",
		"levels": rounds,
	}

# ---------------------------------------------------------------- curriculum / knowledge_map

func _patch_chapter(levels_file_path: String) -> bool:
	var cpath := "res://data/curriculum.json"
	var kpath := "res://data/knowledge_map.json"
	var craw := FileAccess.get_file_as_string(cpath)
	var cdata = JSON.parse_string(craw)
	if typeof(cdata) != TYPE_DICTIONARY:
		push_error("curriculum.json 解析失败")
		return false
	var cspan := _find_chapter(craw, _chapter)
	if cspan.is_empty():
		push_error("curriculum.json 找不到章节 id=" + _chapter)
		return false
	# 该章现有条目（解析侧）
	var cdict: Dictionary = {}
	for ch in (cdata as Dictionary)["chapters"]:
		if str(ch.get("id", "")) == _chapter:
			cdict = ch
			break
	var existing: Array = cdict.get("levels", [])
	var display_name := _name
	if display_name == "":
		# 知识章用 1-N 连续编号；方法章无编号习惯
		display_name = "1-%d 【待填】关卡名" % (existing.size() + 1) if str(cdict.get("kind", "")) == "knowledge" else "【待填】关卡名"
	# 克隆该章最后一条的结构字段（自动适配 LabStage/Lab3DStage 的 lab/lab_ref）
	var entry := { "id": _key, "name": display_name }
	if not existing.is_empty():
		var tmpl: Dictionary = existing.back()
		for k in tmpl.keys():
			if k in ["id", "name", "lab_ref", "space", "sequence", "conic", "technique"]:
				continue
			entry[k] = tmpl[k]
		entry["technique"] = "【TODO】技法"
		if tmpl.has("lab"):
			entry["lab"] = _lab_name()
			entry["lab_ref"] = _key
		if tmpl.has("space"):
			entry["space"] = _key
	else:
		entry["technique"] = "【TODO】技法"
		entry["archetype"] = "LAB"
		entry["lab"] = _lab_name()
		entry["lab_ref"] = _key
		entry["scene"] = "res://scenes/LabStage.tscn"
	# levels 数组末尾追加
	var lf := JsonText.find_key(craw, "levels", int(cspan["start"]), int(cspan["end"]))
	if lf.is_empty() or raw_check_empty(craw, int(lf["v"])):
		push_error("章节 " + _chapter + " 的 levels 定位失败")
		return false
	var cnew := JsonText.append_into_array(craw, int(lf["v"]), entry)
	var cchk = JSON.parse_string(cnew)
	if typeof(cchk) != TYPE_DICTIONARY:
		push_error("curriculum.json 追加未通过解析校验，未写盘")
		return false
	_write(cpath, cnew)
	print("  + 已追加 curriculum：章 %s ← %s（%s）" % [_chapter, _key, display_name])

	# knowledge_map：points 追加 { name, levels: [key] }
	var kraw := FileAccess.get_file_as_string(kpath)
	var kdata = JSON.parse_string(kraw)
	if typeof(kdata) != TYPE_DICTIONARY:
		push_error("knowledge_map.json 解析失败（curriculum 已写入，请检查）")
		return false
	var kspan := _find_chapter_kmap(kraw, _chapter)
	if kspan.is_empty():
		push_error("knowledge_map.json 找不到章节 id=" + _chapter + "（curriculum 已写入，请补挂知识点）")
		return false
	var pf := JsonText.find_key(kraw, "points", int(kspan["start"]), int(kspan["end"]))
	if pf.is_empty():
		push_error("章节 " + _chapter + " 的 points 定位失败")
		return false
	var point := { "name": display_name, "levels": [_key] }
	var knew := JsonText.append_into_array(kraw, int(pf["v"]), point)
	var kchk = JSON.parse_string(knew)
	if typeof(kchk) != TYPE_DICTIONARY:
		push_error("knowledge_map.json 追加未通过解析校验")
		return false
	_write(kpath, knew)
	print("  + 已追加 knowledge_map：章 %s ← 知识点「%s」" % [_chapter, display_name])
	return true

func raw_check_empty(raw: String, arr_v: int) -> bool:
	return arr_v >= raw.length() or raw[arr_v] != "["

## 在 curriculum.json 的 chapters 数组里按 id 找章节 span。
func _find_chapter(raw: String, cid: String) -> Dictionary:
	var f := JsonText.find_key(raw, "chapters")
	if f.is_empty() or raw[int(f["v"])] != "[":
		return {}
	return _nth_chapter(raw, int(f["v"]), cid)

## 在 knowledge_map.json 的 chapters 数组里按 id 找章节 span。
func _find_chapter_kmap(raw: String, cid: String) -> Dictionary:
	return _find_chapter(raw, cid)

func _nth_chapter(raw: String, arr_v: int, cid: String) -> Dictionary:
	var i := arr_v + 1
	while i < raw.length():
		while i < raw.length() and raw[i] in " \t\r\n":
			i += 1
		if i >= raw.length() or raw[i] == "]":
			return {}
		var e := JsonText.value_end(raw, i)
		if e < 0:
			return {}
		if JsonText.key_string(raw, "id", i, e) == cid:
			return {"start": i, "end": e}
		i = e
		while i < raw.length() and raw[i] in " \t\r\n":
			i += 1
		if i < raw.length() and raw[i] == ",":
			i += 1
	return {}

# ---------------------------------------------------------------- 写盘 / 提示

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("无法写入 " + path)
		quit(1)
		return
	f.store_string(text)
	f.close()

func _print_reminders() -> void:
	print("后续步骤（E2 固定流程）：")
	print("  1. 把骨架里的【TODO】逐项填成真内容（式子一律 $$…$$，不写 Unicode 片段）；")
	print("  2. godot --headless --path . --script res://tools/fix_labels.gd -- --apply   # 规范轮次标签")
	print("  3. 跑 §9.1 全量校验：check_questions / check_knowledge / check_all / Tests / smoke / UiSmoke")
	print("  4. 更新 TODO §9.2 基线数字，提交信息带条目编号。")
