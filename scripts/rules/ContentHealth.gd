class_name ContentHealth
## A18：内容数据完整性检查（纯规则）——把「坏数据」翻译成**问题码 + 位置 + 人话**。
##
## 痛点：内容数据一旦出问题（课程表损坏 / 关卡 id 撞车 / 引用指向不存在的组），
## 运行时只会 push_error 然后**静默空白**——学生看到的是没有解释的空页面。
## 本模块供「用户可见兜底」与「CI 闸门」共用同一套判定，避免两处口径漂移。
##
## 约定：
## - 入参全部由调用方传入（章节数组 / 已知场景集合 / 内容组键表），本文件不读文件、不读 autoload；
## - 输出 {ok, problems:[{code, where, message}], count}；ok == problems.is_empty()；
## - 问题码固定，便于测试与文案映射：
##   E_EMPTY     课程表为空（一个章节都没有）
##   E_DUP_ID    关卡 id 重复
##   E_NO_LEVEL  章节里一关都没有
##   E_NO_TITLE  关卡没有名字
##   E_NO_SCENE  关卡没有场景
##   E_BAD_REF   关卡引用的题目数据定位不到
##   E_LOAD      课程表本身读不出来（文件缺失 / JSON 损坏）
##
## 单测：tests/Tests.gd::_test_content_health()

## 问题码 → 人话（UI 与 CI 共用一套文案）。
const MESSAGES := {
	"E_EMPTY": "课程表是空的，没有任何章节",
	"E_DUP_ID": "关卡 id 重复",
	"E_NO_LEVEL": "章节里一关都没有",
	"E_NO_TITLE": "关卡没有名字",
	"E_NO_SCENE": "关卡没有场景",
	"E_BAD_REF": "关卡引用的题目数据找不到",
	"E_LOAD": "课程表读取失败",
}

## 关卡内容引用的字段顺序（关卡字段 → 组键字段）。
const REF_FIELDS := ["lab", "sequence", "conic", "method"]

# ---------------------------------------------------------------- 检查

## 检查课程表结构与内容引用。
## chapters：curriculum.json 的章节数组
## scenes  ：已知场景集合 {scene_path: true}（空 = 不查场景是否存在）
## groups  ：内容组键表 {来源键: [组键, ...]}（空 = 不查引用能否定位）
static func check(chapters: Array, scenes: Dictionary = {}, groups: Dictionary = {}) -> Dictionary:
	var problems: Array = []
	if chapters.is_empty():
		problems.append(problem("E_EMPTY", "curriculum.json", MESSAGES["E_EMPTY"]))
		return result(problems)
	var seen := {}
	for ci in chapters.size():
		var ch = chapters[ci]
		if typeof(ch) != TYPE_DICTIONARY:
			problems.append(problem("E_NO_LEVEL", "chapter[%d]" % ci, "章节数据不是对象"))
			continue
		var c: Dictionary = ch
		var cid := str(c.get("id", ""))
		var where := cid if cid != "" else "chapter[%d]" % ci
		var levels = c.get("levels", [])
		if typeof(levels) != TYPE_ARRAY or (levels as Array).is_empty():
			problems.append(problem("E_NO_LEVEL", where, "章节「%s」里一关都没有" % (str(c.get("title", cid)))))
			continue
		for lv in levels:
			if typeof(lv) != TYPE_DICTIONARY:
				problems.append(problem("E_NO_LEVEL", where, "关卡数据不是对象"))
				continue
			var l: Dictionary = lv
			var lid := str(l.get("id", ""))
			var at := "%s/%s" % [where, lid] if lid != "" else where
			if lid == "":
				problems.append(problem("E_NO_TITLE", at, "关卡没有 id"))
			elif seen.has(lid):
				problems.append(problem("E_DUP_ID", at, "关卡 id「%s」重复" % lid))
			else:
				seen[lid] = true
			if str(l.get("name", "")) == "":
				problems.append(problem("E_NO_TITLE", at, "关卡「%s」没有名字" % lid))
			var scene := str(l.get("scene", ""))
			if scene == "":
				problems.append(problem("E_NO_SCENE", at, "关卡「%s」没有场景" % lid))
			elif not scenes.is_empty() and not scenes.has(scene):
				problems.append(problem("E_NO_SCENE", at, "场景文件不存在：%s" % scene))
			var ref := ref_of(l)
			if ref.is_empty():
				problems.append(problem("E_BAD_REF", at, "关卡「%s」没有指向任何题目数据" % lid))
			elif not groups.is_empty():
				var src := str(ref[0])
				var key := str(ref[1])
				if not groups.has(src):
					problems.append(problem("E_BAD_REF", at, "找不到数据源「%s」" % src))
				elif not (groups[src] as Array).has(key):
					problems.append(problem("E_BAD_REF", at, "数据源「%s」里没有「%s」" % [src, key]))
	return result(problems)

## 关卡的内容引用：返回 [来源键, 组键]；没有引用返回空数组。
## 来源键：lab → "lab:<模块名>"，其余（sequence/conic/method）同名。
static func ref_of(level: Dictionary) -> Array:
	for f in REF_FIELDS:
		var v := str(level.get(f, ""))
		if v == "":
			continue
		var key := v
		if f == "lab":
			key = str(level.get("lab_ref", ""))
			if key == "":
				key = str(level.get("space", ""))
			if key == "":
				key = str(level.get("id", ""))
		return [ref_source(f, v), key]
	return []

## 来源键（lab 特殊：带上模块名，其余同名）。
static func ref_source(field: String, value: String) -> String:
	return ("lab:" + value) if field == "lab" else field

## 造一条问题（供调用方与测试使用）。
static func problem(code: String, where: String, message: String) -> Dictionary:
	return { "code": code, "where": where, "message": message }

static func result(problems: Array) -> Dictionary:
	return { "ok": problems.is_empty(), "problems": problems, "count": problems.size() }

# ---------------------------------------------------------------- 文案

## 一行中文说明（UI 兜底与 CI 输出共用）。
static func describe(problems: Array) -> String:
	if problems.is_empty():
		return "内容数据完整"
	var first = problems[0]
	if typeof(first) != TYPE_DICTIONARY:
		return "内容数据异常"
	var f: Dictionary = first
	var s := "%s（%s）" % [str(f.get("message", "")), str(f.get("where", ""))]
	if problems.size() > 1:
		s += " 等 %d 处" % problems.size()
	return s

## 问题码清单（去重、排序稳定）。
static func codes(problems: Array) -> Array:
	var out: Array = []
	for p in problems:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var c := str((p as Dictionary).get("code", ""))
		if c != "" and not out.has(c):
			out.append(c)
	return out
