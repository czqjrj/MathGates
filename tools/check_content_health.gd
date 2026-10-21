extends SceneTree
## A18：内容数据完整性检查（CLI / CI 闸门）。
##
## 用法：godot --headless --path . --script res://tools/check_content_health.gd
## 输出：CONTENT-HEALTH: <chapters> chapters / <levels> levels / <n> problems
## 有问题时逐条打印并以非零码退出（CONTENT-HEALTH-FAIL）。
##
## 与运行时的关系：运行时只做**轻量**体检（课程表结构，见 GameData.content_health），
## 保证启动开销小；本工具做**深度**体检（场景文件是否存在、内容引用能否定位到组键），
## 放在 CI 与发版前当闸门——坏数据不许出包。
##
## 顺带查「孤儿组」：数据文件里存在、但课程表没有任何关卡引用的组（只提示，不算失败）。

const CURRICULUM := "res://data/curriculum.json"

## 内容来源 → [数据文件, 组键所在子键（空 = 顶层就是组键）]
const SOURCES := {
	"sequence": ["res://data/recurrence_levels.json", ""],
	"conic": ["res://data/conic_levels.json", ""],
	"method": ["res://data/solid_methods.json", "methods"],
}

func _initialize() -> void:
	var raw = _read_json(CURRICULUM)
	if typeof(raw) != TYPE_DICTIONARY or not raw.has("chapters"):
		print("CONTENT-HEALTH-FAIL: 课程表读不出来：", CURRICULUM)
		quit(1)
		return
	var chapters: Array = raw["chapters"]

	# —— 场景集合：关卡指向的场景文件必须存在 ——
	var scenes := {}
	var levels := 0
	for ch in chapters:
		for lv in ch.get("levels", []):
			levels += 1
			var s := str(lv.get("scene", ""))
			if s != "" and not scenes.has(s):
				scenes[s] = ResourceLoader.exists(s)

	# —— 按需打开内容数据文件，收集组键与被引用的组键 ——
	var groups := {}          # 来源键 → 组键数组（给 ContentHealth.check 用）
	var file_keys := {}       # 数据文件标识 → 组键数组
	var file_refs := {}       # 数据文件标识 → 被引用组键集合
	var missing: Array = []
	for ch in chapters:
		for lv in ch.get("levels", []):
			var ref := ContentHealth.ref_of(lv)
			if ref.is_empty():
				continue
			var src := str(ref[0])
			var key := str(ref[1])
			var spec := _spec_of(src)
			if spec.is_empty():
				continue
			var path := str(spec[0])
			var sub := str(spec[1])
			var fid := path + "|" + sub
			if not groups.has(src):
				if not FileAccess.file_exists(path):
					missing.append(path)
					groups[src] = []
					file_keys[fid] = []
				else:
					var keys := _keys_of(path, sub)
					groups[src] = keys
					file_keys[fid] = keys
			if not file_refs.has(fid):
				file_refs[fid] = {}
			file_refs[fid][key] = true

	# —— 组装检查 ——
	var problems: Array = []
	for p in missing:
		problems.append(ContentHealth.problem("E_BAD_REF", str(p), "内容数据文件缺失"))
	var res := ContentHealth.check(chapters, scenes, groups)
	for p in res["problems"]:
		problems.append(p)

	# —— 孤儿组：数据文件里有、但课程表没引用（按**文件**算，同一文件可被多个来源引用）——
	var orphans := 0
	for fid in file_keys.keys():
		var refs: Dictionary = file_refs.get(fid, {})
		for k in file_keys[fid]:
			if not refs.has(str(k)):
				orphans += 1
				print("  [orphan] %s 里的「%s」没有关卡引用" % [str(fid).split("|")[0], k])

	print("CONTENT-HEALTH: %d chapters / %d levels / %d problems (orphans=%d)" % [
		chapters.size(), levels, problems.size(), orphans])
	for p in problems:
		print("  [%s] %s · %s" % [str(p.get("code", "")), str(p.get("message", "")), str(p.get("where", ""))])
	if not problems.is_empty():
		print("CONTENT-HEALTH-FAIL: 内容数据有 %d 处问题" % problems.size())
		quit(1)
		return
	quit(0)

## 来源键 → [数据文件, 子键]；lab:<模块> 走 data/<模块>_levels.json。
func _spec_of(src: String) -> Array:
	if src.begins_with("lab:"):
		return ["res://data/%s_levels.json" % src.substr(4), ""]
	if SOURCES.has(src):
		return SOURCES[src]
	return []

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

## 取数据文件里的组键（sub 非空时取子对象的键）。
func _keys_of(path: String, sub: String) -> Array:
	var d = _read_json(path)
	if typeof(d) != TYPE_DICTIONARY:
		return []
	if sub != "":
		var inner = d.get(sub, null)
		if typeof(inner) != TYPE_DICTIONARY:
			return []
		d = inner
	return d.keys()
