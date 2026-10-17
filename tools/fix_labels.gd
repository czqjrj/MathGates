extends SceneTree
## 轮次标签编号批量修正（TODO B9）。
##
## 规范：每个关卡的每轮 `name` 形如 `<关卡序号>-<轮次> <阶段名>`，其中
##   关卡序号 = 该关卡 key 在所在 `data/*_levels.json` 中的先后次序（与 check_questions.gd 口径一致）；
##   轮次     = 该轮在 `levels[]` 中的次序；
##   阶段名   = 原 `name` 去掉已有的编号前缀后的剩余文本（无剩余则留空）。
##
## 用法：
##   godot --headless --path . --script res://tools/fix_labels.gd                # 只预览（dry-run）
##   godot --headless --path . --script res://tools/fix_labels.gd -- --apply    # 实际写入
##
## 说明：**文本级替换**，只改轮次标签行，保留原文件排版；滑块 `name`（在 `"sliders"` 内、
## 且名字与期望不符）与 boss.name（名字与期望不符）都不会被误改。
## 匹配时按 JSON 顺序要求旧名逐一相等（位置护栏）；若「匹配到的标签数 != 轮次数」则跳过该文件并报错。

const DATA_DIR := "res://data"

var _name_re: RegEx
var _num_re: RegEx

func _initialize() -> void:
	var apply := OS.get_cmdline_user_args().has("--apply")
	_name_re = RegEx.new()
	# 组1=前导缩进 组2=可选的 "{ "（conic 等内联关卡对象） 组3=原名字
	_name_re.compile("^([ \\t]*)(\\{ )?\"name\": \"([^\"]*)\"")
	_num_re = RegEx.new()
	_num_re.compile("^\\s*[0-9]+\\s*[-.．]\\s*[0-9]*\\s*")

	var files := _level_files()
	var ok_files := 0
	var total_fixed := 0
	for f in files:
		var n := _process_file(f, apply)
		if n < 0:
			continue
		ok_files += 1
		total_fixed += n
	print("FIX-LABELS: %s / %d/%d files / %d labels" % ["APPLIED" if apply else "DRY-RUN", ok_files, files.size(), total_fixed])
	if not apply:
		print("（预览模式；加 `-- --apply` 实际写入）")
	quit(0 if ok_files == files.size() else 1)

func _level_files() -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(DATA_DIR)
	if d == null:
		push_error("无法打开 " + DATA_DIR)
		return out
	for f in d.get_files():
		if f.ends_with("_levels.json"):
			out.append(DATA_DIR + "/" + f)
	out.sort()
	return out

func _process_file(path: String, apply: bool) -> int:
	var raw := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("解析失败：" + path)
		return -1

	# 期望：{ old, new } 按 JSON 顺序
	var expected: Array[Dictionary] = []
	var group_no := 0
	for key in (data as Dictionary).keys():
		group_no += 1
		var g = data[key]
		if typeof(g) != TYPE_DICTIONARY:
			continue
		var lv = (g as Dictionary).get("levels", null)
		if typeof(lv) != TYPE_ARRAY:
			continue
		var round_no := 0
		for s in (lv as Array):
			round_no += 1
			if typeof(s) != TYPE_DICTIONARY:
				continue
			var st: Dictionary = s
			if not st.has("name"):
				continue
			var old_name := str(st.get("name", ""))
			if old_name.strip_edges() == "":
				continue  # 空名轮次不编号（与 check_questions.gd 口径一致）
			var suffix := _num_re.sub(old_name, "", true).strip_edges()
			var new_name := "%d-%d" % [group_no, round_no]
			if suffix != "":
				new_name += " " + suffix
			expected.append({"old": old_name, "new": new_name})

	# 文本级替换（位置护栏：第 idx 个匹配行必须正好是第 idx 个轮次标签）
	var lines := raw.split("\n")
	var idx := 0
	var fixed := 0
	for i in lines.size():
		if idx >= expected.size():
			break
		var m := _name_re.search(lines[i])
		if m == null:
			continue
		if m.get_string(3) != str(expected[idx]["old"]):
			continue  # 名字不符：滑块/boss.name/其它，跳过
		idx += 1
		var new_name2 := str(expected[idx - 1]["new"])
		if m.get_string(3) == new_name2:
			continue
		var rest := lines[i].substr(m.get_end())
		lines[i] = "%s%s\"name\": \"%s\"%s" % [m.get_string(1), m.get_string(2), new_name2, rest]
		fixed += 1

	if idx != expected.size():
		push_error("标签数不匹配，跳过：%s（匹配 %d / 期望 %d）" % [path, idx, expected.size()])
		return -1
	if fixed == 0:
		return 0
	if apply:
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			push_error("无法写入：" + path)
			return -1
		f.store_string("\n".join(lines))
		f.close()
	print("  %s：修正 %d 处" % [path, fixed])
	return fixed
