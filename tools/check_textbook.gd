extends SceneTree
## E5 · 教材对齐核对（headless，可进 CI）。
##
## 用法： godot --headless --path . --script res://tools/check_textbook.gd
##
## 作用：
##   1. 校验 data/textbooks.json 的 6 个版本定义是否**自洽且覆盖全部章节**——
##      版本 id/分册 id 唯一、默认版本存在；method_order + knowledge_order 无重复、
##      无未知章、无漏章；chapter_book / chapter_no 齐全（方法章可无章号）；
##      unit_titles 的 `分册|章号` 必须真实存在；
##   2. 把 E1 的覆盖矩阵按**教材版本**展开：同一知识点在不同版本的
##      分册 / 章号 / 状态，生成 docs/教材对齐核对.md（文档与数据不分叉）；
##   3. 显式区分三种状态：已覆盖 / 未覆盖（待补）/ 不适用（选学·旧课标）。
##
## 退出码：0 = 通过（允许存量缺口）；1 = 结构错误。

const TB := "res://data/textbooks.json"
const KMAP := "res://data/knowledge_map.json"
const CUR := "res://data/curriculum.json"
const DOC := "res://docs/教材对齐核对.md"

const ST_OK := "✅ 已覆盖"
const ST_MISS := "❌ 未覆盖（待补）"
const ST_NA := "○ 不适用（选学·旧课标）"

var problems: Array[String] = []
var warnings: Array[String] = []

func _initialize() -> void:
	var tb := _read_json(TB)
	var km := _read_json(KMAP)
	var cur := _read_json(CUR)
	if tb.is_empty() or km.is_empty() or cur.is_empty():
		print("TEXTBOOK-FAIL: 无法解析数据文件")
		quit(1)
		return

	var cur_chs: Array = cur.get("chapters", [])
	var km_chs: Array = km.get("chapters", [])

	# —— 课程表 / 覆盖矩阵：章节集合必须一致（与 check_knowledge 同口径）——
	var cur_ids: Array[String] = []
	var kind_of := {}
	var title_of := {}
	for c in cur_chs:
		var cid := str(c.get("id", ""))
		cur_ids.append(cid)
		kind_of[cid] = str(c.get("kind", "knowledge"))
		title_of[cid] = str(c.get("title", ""))
	var km_ids: Array[String] = []
	for c in km_chs:
		km_ids.append(str(c.get("id", "")))
	if cur_ids != km_ids:
		problems.append("章节集合/顺序与 knowledge_map.json 不一致（课程表 %d / 矩阵 %d）" % [cur_ids.size(), km_ids.size()])

	# —— 覆盖状态：chapter -> {points:[], gaps_miss:[], gaps_na:[]} ——
	var coverage := {}
	var total_points := 0
	var total_covered := 0
	var total_miss := 0
	var total_na := 0
	for c in km_chs:
		var cid := str(c.get("id", ""))
		var cov := {"points": [], "gaps_miss": [], "gaps_na": []}
		for p in c.get("points", []):
			var pname := str(p.get("name", "")).strip_edges()
			var lvs: Array = p.get("levels", [])
			total_points += 1
			if lvs.is_empty():
				cov["gaps_miss"].append(pname)
				total_miss += 1
			else:
				cov["points"].append({"name": pname, "levels": lvs})
				total_covered += 1
		for g in c.get("gaps", []):
			var gname := str(g.get("name", "")).strip_edges()
			if bool(g.get("optional", false)):
				cov["gaps_na"].append(gname)
				total_na += 1
			else:
				cov["gaps_miss"].append(gname)
				total_miss += 1
		coverage[cid] = cov

	# —— 教材版本定义校验 ——
	var versions: Array = tb.get("versions", [])
	var default_id := str(tb.get("default", ""))
	if versions.is_empty():
		problems.append("textbooks.json 没有 versions")
	var seen_vid := {}
	var seen_default := false
	for v in versions:
		var vid := str(v.get("id", ""))
		if vid == "":
			problems.append("教材版本缺 id")
			continue
		if seen_vid.has(vid):
			problems.append("教材版本 id 重复：%s" % vid)
		seen_vid[vid] = true
		if vid == default_id:
			seen_default = true
		if str(v.get("title", "")).strip_edges() == "":
			problems.append("[%s] 缺 title" % vid)
		var books: Array = v.get("books", [])
		if books.is_empty():
			problems.append("[%s] 缺 books（分册）" % vid)
		var book_ids := {}
		for b in books:
			var bid := str(b.get("id", ""))
			if bid == "":
				problems.append("[%s] 分册缺 id" % vid)
				continue
			if book_ids.has(bid):
				problems.append("[%s] 分册 id 重复：%s" % [vid, bid])
			book_ids[bid] = str(b.get("title", bid))
		var method_order: Array = v.get("method_order", [])
		var knowledge_order: Array = v.get("knowledge_order", [])
		var order: Array = []
		order.append_array(method_order)
		order.append_array(knowledge_order)
		if order.is_empty():
			problems.append("[%s] method_order / knowledge_order 均为空" % vid)
		var excluded: Dictionary = v.get("excluded_chapters", {})
		for cid in excluded:
			if not kind_of.has(str(cid)):
				problems.append("[%s] excluded_chapters 引用未知章节：%s" % [vid, cid])
			elif str(excluded[cid]).strip_edges() == "":
				problems.append("[%s] excluded_chapters[%s] 缺原因" % [vid, cid])
		var seen_order := {}
		for cid in order:
			var sid := str(cid)
			if seen_order.has(sid):
				problems.append("[%s] 章节在排序中出现多次：%s" % [vid, sid])
			seen_order[sid] = true
			if not kind_of.has(sid):
				problems.append("[%s] 排序引用了未知章节：%s" % [vid, sid])
			if excluded.has(sid):
				problems.append("[%s] 章节同时被排除又在排序中：%s" % [vid, sid])
		for cid in cur_ids:
			if not excluded.has(cid) and not seen_order.has(cid):
				problems.append("[%s] 章节未进入 method_order / knowledge_order：%s" % [vid, cid])
		var cb: Dictionary = v.get("chapter_book", {})
		var cn: Dictionary = v.get("chapter_no", {})
		for cid in cur_ids:
			if excluded.has(cid):
				continue
			if not cb.has(cid):
				problems.append("[%s] chapter_book 缺章节：%s" % [vid, cid])
			else:
				var bid := str(cb[cid])
				if not book_ids.has(bid):
					problems.append("[%s] chapter_book[%s] 指向不存在的分册：%s" % [vid, cid, bid])
			if not cn.has(cid):
				# 方法章不属于教材章节，允许没有章号（文档显示为「方法拓展」）。
				if kind_of.get(cid, "") != "method":
					problems.append("[%s] chapter_no 缺章节：%s" % [vid, cid])
			elif str(cn[cid]).strip_edges() == "" and kind_of.get(cid, "") != "method":
				problems.append("[%s] chapter_no[%s] 为空" % [vid, cid])
		var ut: Dictionary = v.get("unit_titles", {})
		for key in ut:
			var parts := str(key).split("|")
			if parts.size() != 2:
				problems.append("[%s] unit_titles 键不是「分册|章号」：%s" % [vid, key])
				continue
			if not book_ids.has(parts[0]):
				problems.append("[%s] unit_titles 引用不存在的分册：%s" % [vid, parts[0]])
	if default_id != "" and not seen_default:
		problems.append("default 指向不存在的版本：%s" % default_id)

	# —— 生成文档 ——
	var doc: PackedStringArray = []
	doc.append("# 教材对齐核对矩阵（E5）\n")
	doc.append("> 本文件由 `data/textbooks.json` + `data/knowledge_map.json` + `data/curriculum.json` **自动生成**，请勿手改；")
	doc.append("> 改数据后运行 `godot --headless --path . --script res://tools/check_textbook.gd` 重新生成。\n")
	doc.append("## 0. 口径\n")
	doc.append("- **章节**：`data/curriculum.json` 的 %d 章（含 4 个方法章）。" % cur_ids.size())
	doc.append("- **小节行**：`data/knowledge_map.json` 的知识点（E1 口径，已拆到教材小节级）。")
	doc.append("- **版本差异**：只体现在分册与章号（`textbooks.json`），同一知识点在各版本共用；")
	doc.append("  某版本确实不学某章时，在该版本写 `excluded_chapters: {\"章 id\": \"原因\"}`，本表该章标「不适用」。")
	doc.append("- **状态**：%s / %s / %s。" % [ST_OK, ST_MISS, ST_NA])
	doc.append("- 缺口与选学口径与 `docs/知识点覆盖矩阵.md` 同源，两边数字必须一致。\n")
	doc.append("## 1. 六版总览\n")
	doc.append("| 版本 | 分册 | 章 | 小节（知识点） | ✅ 已覆盖 | ❌ 未覆盖 | ○ 不适用 |")
	doc.append("|---|---|---|---|---|---|---|")
	for v in versions:
		var vid := str(v.get("id", ""))
		var books: Array = v.get("books", [])
		var excluded: Dictionary = v.get("excluded_chapters", {})
		var v_points := 0
		var v_covered := 0
		var v_miss := 0
		var v_na := 0
		for cid in cur_ids:
			var cov: Dictionary = coverage.get(cid, {})
			var pts: Array = cov.get("points", [])
			var miss: Array = cov.get("gaps_miss", [])
			var na: Array = cov.get("gaps_na", [])
			if excluded.has(cid):
				v_na += pts.size() + miss.size() + na.size()
			else:
				v_points += pts.size()
				v_covered += pts.size()
				v_miss += miss.size()
				v_na += na.size()
		doc.append("| %s（`%s`） | %d | %d | %d | %d | %d | %d |" % [
			str(v.get("title", vid)), vid, books.size(), cur_ids.size(),
			v_points, v_covered, v_miss, v_na,
		])
	doc.append("")

	# —— 版本差异速查 ——
	doc.append("## 2. 版本差异速查（同一章的分册与章号）\n")
	doc.append("> 空单元格 = 该版本未在 `chapter_book` / `chapter_no` 登记（结构校验会报错）。\n")
	var head := "| 章节 |"
	var sep := "|---|"
	for v in versions:
		head += " %s |" % str(v.get("title", v.get("id", "")))
		sep += "---|"
	doc.append(head)
	doc.append(sep)
	for cid in cur_ids:
		var row := "| %s（`%s`） |" % [str(title_of[cid]), cid]
		for v in versions:
			var cb: Dictionary = v.get("chapter_book", {})
			var cn: Dictionary = v.get("chapter_no", {})
			var excluded: Dictionary = v.get("excluded_chapters", {})
			var cell := ""
			if excluded.has(cid):
				cell = "○ 不适用（%s）" % str(excluded[cid])
			elif cb.has(cid) or cn.has(cid):
				var bid := str(cb.get(cid, ""))
				var btitle := bid
				for b in v.get("books", []):
					if str(b.get("id", "")) == bid:
						btitle = str(b.get("title", bid))
						break
				var no := str(cn.get(cid, "")).strip_edges()
				if no == "" and kind_of.get(cid, "") == "method":
					no = "方法拓展"
				cell = "%s %s" % [btitle, no]
			row += " %s |" % cell
		doc.append(row)
	doc.append("")

	# —— 分版本核对（每个版本一张小节表）——
	doc.append("## 3. 分版本核对\n")
	var vi := 0
	for v in versions:
		vi += 1
		var vid := str(v.get("id", ""))
		var vtitle := str(v.get("title", vid))
		doc.append("### 3.%d %s（`%s`）\n" % [vi, vtitle, vid])
		var book_title := {}
		var book_line: Array[String] = []
		for b in v.get("books", []):
			var bid := str(b.get("id", ""))
			var btitle := str(b.get("title", bid))
			book_title[bid] = btitle
			book_line.append(btitle)
		doc.append("分册：%s\n" % ("、".join(book_line) if not book_line.is_empty() else "—"))
		doc.append("| 分册 | 章号 | 章节 | 小节（知识点） | 关卡 | 状态 |")
		doc.append("|---|---|---|---|---|---|")
		var order: Array = []
		order.append_array(v.get("method_order", []))
		order.append_array(v.get("knowledge_order", []))
		var cb: Dictionary = v.get("chapter_book", {})
		var cn: Dictionary = v.get("chapter_no", {})
		for cid in order:
			var sid := str(cid)
			if not coverage.has(sid):
				doc.append("| — | — | %s（`%s`） | — | — | ❌ 数据缺失 |" % [sid, sid])
				continue
			var bid := str(cb.get(sid, ""))
			var btitle := str(book_title.get(bid, bid if bid != "" else "—"))
			var no := str(cn.get(sid, "")).strip_edges()
			if no == "":
				no = "方法拓展" if kind_of.get(sid, "") == "method" else "—"
			var cov: Dictionary = coverage[sid]
			var first := true
			for p in cov["points"]:
				doc.append("| %s | %s | %s（`%s`） | %s | %s | %s |" % [
					btitle if first else "", no if first else "",
					str(title_of.get(sid, sid)), sid,
					str(p["name"]), "、".join(p["levels"]), ST_OK,
				])
				first = false
			for gname in cov["gaps_miss"]:
				doc.append("| %s | %s | %s（`%s`） | %s | — | %s |" % [
					btitle if first else "", no if first else "",
					str(title_of.get(sid, sid)), sid, str(gname), ST_MISS,
				])
				first = false
			for gname in cov["gaps_na"]:
				doc.append("| %s | %s | %s（`%s`） | %s | — | %s |" % [
					btitle if first else "", no if first else "",
					str(title_of.get(sid, sid)), sid, str(gname), ST_NA,
				])
				first = false
		var excluded: Dictionary = v.get("excluded_chapters", {})
		for cid in cur_ids:
			if not excluded.has(cid):
				continue
			var sid := str(cid)
			doc.append("| — | — | %s（`%s`） | 整章不适用（%s） | — | %s |" % [
				str(title_of.get(sid, sid)), sid, str(excluded[cid]), ST_NA,
			])
		doc.append("")

	# —— 缺口清单（按状态聚合，便于一眼看缺什么）——
	doc.append("## 4. 缺口与不适用清单\n")
	if total_miss == 0:
		doc.append("- ❌ 未覆盖（待补）：**无**。")
	else:
		doc.append("- ❌ 未覆盖（待补）：")
		for cid in cur_ids:
			var cov: Dictionary = coverage.get(cid, {})
			for gname in cov.get("gaps_miss", []):
				doc.append("  - [%s] %s" % [cid, gname])
	doc.append("")
	if total_na == 0:
		doc.append("- ○ 不适用（选学·旧课标）：**无**。\n")
	else:
		doc.append("- ○ 不适用（选学·旧课标）：")
		for cid in cur_ids:
			var cov: Dictionary = coverage.get(cid, {})
			for gname in cov.get("gaps_na", []):
				doc.append("  - [%s] %s" % [cid, gname])
		doc.append("")
	var has_exclusions := false
	for v in versions:
		var ex: Dictionary = v.get("excluded_chapters", {})
		if not ex.is_empty():
			has_exclusions = true
			break
	if has_exclusions:
		doc.append("- ○ 版本级整章不适用：")
		for v in versions:
			var vid := str(v.get("id", ""))
			var excluded: Dictionary = v.get("excluded_chapters", {})
			for cid in excluded:
				doc.append("  - [%s] %s：%s" % [vid, cid, str(excluded[cid])])
		doc.append("")

	# 写文档
	FileAccess.open(DOC, FileAccess.WRITE).store_string("\n".join(doc) + "\n")

	# —— 控制台输出 ——
	print("TEXTBOOK: %d versions / %d chapters / %d sections / covered=%d / missing=%d / optional=%d" % [
		versions.size(), cur_ids.size(), total_points, total_covered, total_miss, total_na,
	])
	if not warnings.is_empty():
		for w in warnings:
			print("  TB-WARN: " + w)
	for p in problems:
		print("  TB-ERROR: " + p)
	if not problems.is_empty():
		print("TEXTBOOK-FAIL: %d 处教材版本定义不一致" % problems.size())
	print("  文档已生成：%s" % DOC)
	quit(1 if not problems.is_empty() else 0)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var txt := FileAccess.get_file_as_string(path)
	var v: Variant = JSON.parse_string(txt)
	return v if v is Dictionary else {}
