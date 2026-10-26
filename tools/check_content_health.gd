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
const META_PATH := "res://data/meta.json"   # A15：元游戏内容（头像/称号/勋章/任务/领域/形态/碑文）

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

	# —— A15：元游戏内容（data/meta.json）——
	for p in _meta_problems():
		problems.append(p)

	print("CONTENT-HEALTH: %d chapters / %d levels / %d problems (orphans=%d)" % [
		chapters.size(), levels, problems.size(), orphans])
	for p in problems:
		print("  [%s] %s · %s" % [str(p.get("code", "")), str(p.get("message", "")), str(p.get("where", ""))])
	if not problems.is_empty():
		print("CONTENT-HEALTH-FAIL: 内容数据有 %d 处问题" % problems.size())
		quit(1)
		return
	quit(0)

## A15：`data/meta.json`（元游戏内容）的完整性检查。
## 判据：文件可解析、六个分组齐全、组内 id 唯一、展示字段齐、勋章规则字段合法、
## 称号比例单调且从 0 起、领域与碑文 id 一一对应。
## 这些内容以前硬编码在 GameData/PlayerRules 里，改错只有到运行时才炸；现在发版前就能拦住。
func _meta_problems() -> Array:
	var out: Array = []
	var data = _read_json(META_PATH)
	if typeof(data) != TYPE_DICTIONARY:
		out.append(ContentHealth.problem("E_META", META_PATH, "找不到或无法解析元游戏内容文件"))
		return out
	var groups := ["avatars", "ranks", "medals", "daily_missions", "domains", "pet_forms", "lore"]
	for g in groups:
		if typeof(data.get(g, null)) != TYPE_ARRAY:
			out.append(ContentHealth.problem("E_META_MISSING", META_PATH + " → " + g, "缺少分组或不是数组"))
	# 需要 id 且 id 必须唯一的组（ranks/pet_forms 没有 id）
	var id_groups := ["avatars", "medals", "daily_missions", "domains", "lore"]
	var ids := {}
	for g in id_groups:
		var seen := {}
		var arr: Array = data.get(g, []) if typeof(data.get(g, null)) == TYPE_ARRAY else []
		for it in arr:
			if typeof(it) != TYPE_DICTIONARY:
				out.append(ContentHealth.problem("E_META_SHAPE", META_PATH + " → " + g, "列表项不是对象"))
				continue
			var id := str(it.get("id", ""))
			if id == "":
				out.append(ContentHealth.problem("E_META_NO_ID", META_PATH + " → " + g, "缺少 id"))
				continue
			if seen.has(id):
				out.append(ContentHealth.problem("E_META_DUP_ID", META_PATH + " → " + g, "id 重复：" + id))
			seen[id] = true
		ids[g] = seen
	# 勋章：展示字段 + 规则字段
	var medal_kinds := ["count", "flag", "accuracy", "boss_all"]
	for it in (data.get("medals", []) if typeof(data.get("medals", null)) == TYPE_ARRAY else []):
		if typeof(it) != TYPE_DICTIONARY:
			continue
		var mid := str(it.get("id", ""))
		for f in ["name", "desc", "symbol"]:
			if str(it.get(f, "")) == "":
				out.append(ContentHealth.problem("E_META_MEDAL", META_PATH + " → " + mid, "缺少字段 " + f))
		var kind := str(it.get("kind", ""))
		if not kind in medal_kinds:
			out.append(ContentHealth.problem("E_META_MEDAL", META_PATH + " → " + mid, "未知 kind：" + kind))
		elif kind == "count" and (str(it.get("metric", "")) == "" or not it.has("value")):
			out.append(ContentHealth.problem("E_META_MEDAL", META_PATH + " → " + mid, "count 类必须有 metric 与 value"))
	# 每日任务：metric 必须是引擎认识的四种之一
	for it in (data.get("daily_missions", []) if typeof(data.get("daily_missions", null)) == TYPE_ARRAY else []):
		if typeof(it) != TYPE_DICTIONARY:
			continue
		var mt := str(it.get("metric", ""))
		if not mt in ["answers", "clears", "coins", "streak"]:
			out.append(ContentHealth.problem("E_META_MISSION", META_PATH + " → " + str(it.get("id", "")), "未知 metric：" + mt))
		if int(it.get("goal", 0)) <= 0:
			out.append(ContentHealth.problem("E_META_MISSION", META_PATH + " → " + str(it.get("id", "")), "goal 必须 > 0"))
	# 称号：比例必须单调不减，且第一档为 0（否则低星玩家没有称号）
	var ranks: Array = data.get("ranks", []) if typeof(data.get("ranks", null)) == TYPE_ARRAY else []
	var last := -1.0
	for i in ranks.size():
		var rk = ranks[i]
		if typeof(rk) != TYPE_DICTIONARY:
			out.append(ContentHealth.problem("E_META_RANK", META_PATH + " → ranks[%d]" % i, "不是对象"))
			continue
		if str(rk.get("title", "")) == "":
			out.append(ContentHealth.problem("E_META_RANK", META_PATH + " → ranks[%d]" % i, "缺少 title"))
		var r := float(rk.get("ratio", -1.0))
		if r < last:
			out.append(ContentHealth.problem("E_META_RANK", META_PATH + " → ranks[%d]" % i, "ratio 必须单调不减"))
		last = r
	if not ranks.is_empty() and typeof(ranks[0]) == TYPE_DICTIONARY \
			and float(ranks[0].get("ratio", -1.0)) != 0.0:
		out.append(ContentHealth.problem("E_META_RANK", META_PATH + " → ranks[0]", "首档 ratio 必须为 0"))
	# 领域 ↔ 碑文：每个领域都要有一段碑文（否则「掌握该领域」后寻不回任何档案）
	var lore_ids: Dictionary = ids.get("lore", {})
	for d in (data.get("domains", []) if typeof(data.get("domains", null)) == TYPE_ARRAY else []):
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var did := str(d.get("id", ""))
		if not lore_ids.has(did):
			out.append(ContentHealth.problem("E_META_LORE", META_PATH + " → " + did, "领域缺少对应碑文"))
	return out

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
