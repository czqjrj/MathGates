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
	print("CHECKED %d scripts, %d failures" % [files.size(), fails])
	quit()

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
