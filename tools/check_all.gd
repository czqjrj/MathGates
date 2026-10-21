extends SceneTree

## 上帝对象行数红线(A4 验收,与 README「代码结构红线」同步):
## 超限即红灯——要么拆纯规则到 scripts/rules/,要么经 TODO 决策显式上调上限。
const RULES_DIR := "res://scripts/rules/"
const RULES_LIMIT := 200
## 三个历史大文件的上限(路径 -> 上限)。
const BIG_LIMITS := {
	"res://scripts/autoload/GameData.gd": 1600,
	"res://scripts/modules/line/TheoremTree.gd": 1550,
	"res://scripts/screens/StageBase.gd": 1200,
}

func _initialize() -> void:
	var files: Array[String] = []
	_collect("res://", files)
	var fails := 0
	for f in files:
		var res: Variant = load(f)
		if res == null:
			fails += 1
			print("FAILED: ", f)
	# —— A4 行数红线 ——
	for f in files:
		if f.begins_with(RULES_DIR):
			fails += _check_limit(f, RULES_LIMIT)
	for path in BIG_LIMITS:
		fails += _check_limit(str(path), int(BIG_LIMITS[path]))
	# —— D4 动效令牌：禁止裸写时长 ——
	fails += _check_bare_durations()
	print("CHECKED %d scripts, %d failures" % [files.size(), fails])
	quit()

## D4：`tween_property(...)` 的第 4 个参数与 `_scale_to(...)` 的第 3 个参数
## 必须是 `UI.DUR_*` 令牌（或变量），裸写秒数即红灯。
## 用括号深度扫描取「顶层第 N 个实参」，避免被 `Color(0.5, …)` 这类嵌套调用误伤。
const DURATION_CALLS := {
	"tween_property(": 3,   # 0-based 第 4 个实参
	"_scale_to(": 2,        # 0-based 第 3 个实参
}

func _check_bare_durations() -> int:
	var bad := 0
	for path in ["res://scripts"]:
		var files: Array[String] = []
		_collect(path, files)
		for f in files:
			var lines := FileAccess.get_file_as_string(f).split("\n")
			for i in lines.size():
				for call in DURATION_CALLS:
					var argi := int(DURATION_CALLS[call])
					var args := _args_at(lines[i], call)
					if args.size() <= argi:
						continue
					var a := args[argi].strip_edges()
					if a.is_empty():
						continue
					var c := a[0]
					if c == "0" or (c >= "1" and c <= "9"):
						print("BARE-DURATION: %s:%d %s → 用 UI.DUR_* 令牌" % [f, i + 1, a])
						bad += 1
	return bad

## 取某行内指定调用的顶层实参（简单括号/引号扫描，够用且不误伤嵌套）。
func _args_at(line: String, call: String) -> Array[String]:
	var out: Array[String] = []
	var start := line.find(call)
	if start < 0:
		return out
	var i := start + call.length()
	var depth := 1
	var quote := ""
	var cur := ""
	while i < line.length():
		var ch := line[i]
		if quote != "":
			cur += ch
			if ch == quote:
				quote = ""
		elif ch == "\"" or ch == "'":
			quote = ch
			cur += ch
		elif ch == "(":
			depth += 1
			cur += ch
		elif ch == ")":
			depth -= 1
			if depth == 0:
				out.append(cur)
				return out
			cur += ch
		elif ch == "," and depth == 1:
			out.append(cur)
			cur = ""
		else:
			cur += ch
		i += 1
	return out

## 超限记一条失败并打印现状;文件缺失(-1)不算失败(可能尚未创建)。
func _check_limit(path: String, limit: int) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var n := FileAccess.get_file_as_string(path).split("\n").size()
	if n > limit:
		print("OVERLIMIT: %s %d 行 > 上限 %d (A4 红线:先拆纯规则,或经 TODO 决策上调)" % [path, n, limit])
		return 1
	return 0

func _collect(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n.begins_with("."):
			n = d.get_next()
			continue
		var full := dir_path.path_join(n)
		if d.current_is_dir():
			_collect(full, out)
		elif n.ends_with(".gd"):
			out.append(full)
		n = d.get_next()
	d.list_dir_end()
