class_name CurriculumRules
## 教材版本下的章节重排与合并规则(A4 第九刀,从 GameData._apply_curriculum_order /
## _apply_chapter_grouping 迁出)。
## 纯函数:教材定义作为参数显式传入,不读全局状态;便于单测与复用。
## 背景:同一套 curriculum.json 在不同教材版本下,章节的排序与「同分册+同章号」
## 的知识章节合并结果不同(如人教A选必一 第2章 = 直线方程 + 圆的方程)。

## 按教材版本重排章节:方法推演在前、知识体系在后,各自遵循版本顺序;
## 未在版本配置中列出的章节按原始顺序补齐(新增章节不会丢失)。
## tb_def 为空(未知版本)时原样复制返回。
static func apply_order(raw: Array, tb_def: Dictionary) -> Array:
	if tb_def.is_empty():
		return raw.duplicate()
	var by_id: Dictionary = {}
	for ch in raw:
		by_id[str(ch.get("id", ""))] = ch
	var out: Array = []
	var used: Dictionary = {}
	for key in ["method_order", "knowledge_order"]:
		var ids = tb_def.get(key, [])
		if typeof(ids) != TYPE_ARRAY:
			continue
		for id in ids:
			var sid := str(id)
			if by_id.has(sid) and not used.has(sid):
				out.append(by_id[sid])
				used[sid] = true
	for ch in raw:
		var sid := str(ch.get("id", ""))
		if not used.has(sid):
			out.append(ch)
			used[sid] = true
	return out

## 按「分册 + 章号」合并知识章节:同键的知识章节合并为一张章节卡片,
## 关卡数据全部保留,每关的 "group" 记为其原章节标题;方法推演章节不参与合并。
## 返回 { "chapters": Array, "members": Dictionary(合并章 id -> 成员原始章 id 数组) }。
## tb_def 为空时原样返回(不合并)。
static func group_chapters(chapters: Array, tb_def: Dictionary) -> Dictionary:
	var members: Dictionary = {}
	if tb_def.is_empty():
		return { "chapters": chapters.duplicate(), "members": members }
	var counts: Dictionary = {}
	for ch in chapters:
		var info := group_key_of(ch, tb_def)
		if not info.is_empty():
			var k := str(info["key"])
			counts[k] = int(counts.get(k, 0)) + 1
	var out: Array = []
	var pos: Dictionary = {}
	for ch in chapters:
		var info := group_key_of(ch, tb_def)
		if info.is_empty() or int(counts.get(str(info["key"]), 0)) <= 1:
			out.append(ch)
			continue
		var key := str(info["key"])
		if pos.has(key):
			var g: Dictionary = out[int(pos[key])]
			var lvs: Array = g["levels"]
			for lv in ch.get("levels", []):
				var lv2: Dictionary = (lv as Dictionary).duplicate(true)
				lv2["group"] = str(ch.get("title", ""))
				lvs.append(lv2)
			g["levels"] = lvs
			(members[str(g["id"])] as Array).append(str(ch.get("id", "")))
		else:
			var g2: Dictionary = ch.duplicate(true)
			var lvarr: Array = g2.get("levels", [])
			for i in lvarr.size():
				(lvarr[i] as Dictionary)["group"] = str(ch.get("title", ""))
			g2["levels"] = lvarr
			g2["title"] = unit_title(str(info["bk"]), str(info["no"]), str(ch.get("title", "")), tb_def)
			pos[key] = out.size()
			out.append(g2)
			members[str(g2["id"])] = [str(ch.get("id", ""))]
	return { "chapters": out, "members": members }

## 章节的合并键(分册 + 章号);非知识章节或缺少分册/章号时返回 {}。
static func group_key_of(ch: Dictionary, tb_def: Dictionary) -> Dictionary:
	if str(ch.get("kind", "knowledge")) == "method":
		return {}
	var cid := str(ch.get("id", ""))
	var no := chapter_no(cid, tb_def)
	var bk := book_of_chapter(cid, tb_def)
	if no == "" or bk == "":
		return {}
	return { "key": bk + "|" + no, "bk": bk, "no": no }

## 合并章节的显示标题:优先取教材版本的 unit_titles 覆盖,否则沿用首个成员标题。
static func unit_title(bk: String, no: String, fallback: String, tb_def: Dictionary) -> String:
	var m = tb_def.get("unit_titles", {})
	if typeof(m) == TYPE_DICTIONARY and m.has(bk + "|" + no):
		return str(m[bk + "|" + no])
	return fallback

## 章节所属分册 id;未定义返回 ""
static func book_of_chapter(chapter_id: String, tb_def: Dictionary) -> String:
	var m = tb_def.get("chapter_book", {})
	return str(m.get(chapter_id, "")) if typeof(m) == TYPE_DICTIONARY else ""

## 章节的教材章号文案(如 "第5章");未定义返回 ""
static func chapter_no(chapter_id: String, tb_def: Dictionary) -> String:
	var m = tb_def.get("chapter_no", {})
	return str(m.get(chapter_id, "")) if typeof(m) == TYPE_DICTIONARY else ""

## 章节(可能是合并章节)是否归属于某知识领域;members 为 group_chapters 返回的映射。
static func chapter_in_domain(chapter_id: String, d: Dictionary, members: Dictionary) -> bool:
	var ms: Array = members.get(chapter_id, [chapter_id])
	for m in ms:
		if str(m) in d["chapters"]:
			return true
	return false
