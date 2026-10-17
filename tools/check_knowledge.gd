extends SceneTree
## E1 · 知识点覆盖矩阵校验器（headless，可进 CI）。
##
## 用法： godot --headless --path . --script res://tools/check_knowledge.gd
##
## 作用：
##   1. 校验 data/knowledge_map.json 与 data/curriculum.json **同步**——
##      每个关卡都必须挂到某知识点（否则报「未挂知识点的关卡」），
##      矩阵引用的关卡 id 必须真实存在；
##   2. 输出**未覆盖知识点清单**（硬缺口），并对照基线 tools/knowledge_gaps_baseline.txt：
##      **新增**硬缺口 → 退出码 1（不阻塞存量）；低于基线 → 提示下调基线；
##   3. 由数据生成 docs/知识点覆盖矩阵.md（文档与数据不分叉）。
##
## 退出码：0 = 通过（可含存量缺口）；1 = 有新增缺口/结构错误。

const CUR := "res://data/curriculum.json"
const KMAP := "res://data/knowledge_map.json"
const BASELINE := "res://tools/knowledge_gaps_baseline.txt"
const DOC := "res://docs/知识点覆盖矩阵.md"

func _initialize() -> void:
	var cur: Dictionary = JSON.parse_string(FileAccess.open(CUR, FileAccess.READ).get_as_text())
	var km: Dictionary = JSON.parse_string(FileAccess.open(KMAP, FileAccess.READ).get_as_text())
	if cur == null or km == null:
		push_error("check_knowledge: 无法解析数据文件")
		quit(1)
		return

	var problems: Array[String] = []
	var warnings: Array[String] = []

	# 章节级：课程表顺序与矩阵顺序一致
	var cur_ch: Array = cur["chapters"]
	var map_ch: Array = km["chapters"]
	var cur_ids: Array[String] = []
	for c in cur_ch:
		cur_ids.append(str(c.get("id", "")))
	var map_ids: Array[String] = []
	for c in map_ch:
		map_ids.append(str(c.get("id", "")))
	if cur_ids != map_ids:
		problems.append("章节集合/顺序与 curriculum.json 不一致（课程表 %d 章 / 矩阵 %d 章）" % [cur_ids.size(), map_ids.size()])

	# 全库关卡 id（检测跨章节重名）
	var seen_ids := {}
	for c in cur_ch:
		for lv in c.get("levels", []):
			var lid := str(lv.get("id", ""))
			if seen_ids.has(lid):
				warnings.append("关卡 id 跨章节重名：%s（%s 与 %s）" % [lid, seen_ids[lid], c.get("id", "")])
			else:
				seen_ids[lid] = str(c.get("id", ""))

	var hard_gaps: Array = []
	var opt_gaps: Array = []
	var points_total := 0
	var mapped_total := 0

	var doc: PackedStringArray = []
	doc.append("# 知识点覆盖矩阵（E1）\n")
	doc.append("> 本文件由 `data/knowledge_map.json` + `data/curriculum.json` **自动生成**，请勿手改；")
	doc.append("> 改数据后运行 `godot --headless --path . --script res://tools/check_knowledge.gd` 重新生成。\n")
	doc.append("教材口径：**苏教2019 + 人教A2019** 为主（章节级对齐），其余版本差异另注。\n")
	doc.append("> 其余四版（北师大 / 人教B / 湘教 / 沪教）的差异以 `data/textbooks.json` 的章号与顺序为准，尚**未拆到小节级**（残留）。\n")

	for ci in cur_ch.size():
		var c: Dictionary = cur_ch[ci]
		var cid := str(c.get("id", ""))
		var title := str(c.get("title", ""))
		var m: Dictionary = {}
		if ci < map_ch.size() and str(map_ch[ci].get("id", "")) == cid:
			m = map_ch[ci]
		# 关卡集合
		var want := {}
		var want_order: Array[String] = []
		for lv in c.get("levels", []):
			want[str(lv.get("id", ""))] = true
			want_order.append(str(lv.get("id", "")))
		var got := {}
		var pts: Array = m.get("points", [])
		for p in pts:
			points_total += 1
			if str(p.get("name", "")).strip_edges() == "":
				problems.append("[%s] 知识点缺 name" % cid)
			var lvs: Array = p.get("levels", [])
			if lvs.is_empty():
				problems.append("[%s] 知识点「%s」未挂任何关卡（应为缺口 gaps）" % [cid, p.get("name", "")])
			for l in lvs:
				var lid := str(l)
				if got.has(lid):
					problems.append("[%s] 关卡 %s 被重复映射" % [cid, lid])
				got[lid] = true
				if not want.has(lid):
					problems.append("[%s] 矩阵引用了不存在的关卡 %s" % [cid, lid])
		for lid in want_order:
			if not got.has(lid):
				problems.append("[%s] 未挂知识点的关卡 %s" % [cid, lid])
		mapped_total += got.size()
		if str(m.get("sujiao", "TODO")).strip_edges() in ["", "TODO"]:
			problems.append("[%s] 缺苏教对齐" % cid)
		if str(m.get("renjiao_a", "TODO")).strip_edges() in ["", "TODO"]:
			problems.append("[%s] 缺人教A对齐" % cid)

		# 生成文档：章节
		doc.append("## %d. %s（`%s`）\n" % [ci, title, cid])
		doc.append("- 苏教：%s" % str(m.get("sujiao", "—")))
		doc.append("- 人教A：%s\n" % str(m.get("renjiao_a", "—")))
		doc.append("| 知识点 | 覆盖关卡 id | 状态 |")
		doc.append("|---|---|---|")
		for p in pts:
			var lvs: Array = p.get("levels", [])
			var lvstr := "、".join(lvs) if not lvs.is_empty() else "—"
			doc.append("| %s | %s | ✅ 已覆盖 |" % [str(p.get("name", "")), lvstr])
		for g in m.get("gaps", []):
			var opt := bool(g.get("optional", false))
			var stat := "○ 选学·旧课标" if opt else "❌ 未覆盖"
			doc.append("| %s | — | %s |" % [str(g.get("name", "")), stat])
			var entry := {"chapter": cid, "title": title, "name": str(g.get("name", "")), "note": str(g.get("note", ""))}
			if opt:
				opt_gaps.append(entry)
			else:
				hard_gaps.append(entry)
		doc.append("")

	# 汇总
	doc.insert(5, "- 章节 **%d** · 知识点 **%d** · 覆盖关卡 **%d** · 硬缺口 **%d** · 选学/旧课标 **%d**\n" % [cur_ch.size(), points_total, mapped_total, hard_gaps.size(), opt_gaps.size()])

	# 基线对照
	var base := _read_baseline()
	var new_problems := hard_gaps.size() > base
	print("KNOWLEDGE: %d chapters / %d points / %d levels mapped / hard-gaps=%d (baseline %d) / optional=%d" % [cur_ch.size(), points_total, mapped_total, hard_gaps.size(), base, opt_gaps.size()])
	if not hard_gaps.is_empty():
		print("  未覆盖知识点（硬缺口）：")
		for g in hard_gaps:
			print("    - [%s] %s  （%s）" % [g["chapter"], g["name"], g["note"]])
	if not opt_gaps.is_empty():
		print("  选学/旧课标（不计入缺口）：")
		for g in opt_gaps:
			print("    - [%s] %s  （%s）" % [g["chapter"], g["name"], g["note"]])
	for w in warnings:
		print("  KN-WARN: " + w)
	if new_problems:
		print("KNOWLEDGE-FAIL: 硬缺口 %d 条 > 基线 %d（新增缺口未登记）" % [hard_gaps.size(), base])
	for p in problems:
		print("  KN-ERROR: " + p)
	if problems.size() > 0:
		print("KNOWLEDGE-FAIL: %d 处矩阵/课程表不一致" % problems.size())

	# 写文档
	FileAccess.open(DOC, FileAccess.WRITE).store_string("\n".join(doc) + "\n")
	print("  文档已生成：%s" % DOC)
	if hard_gaps.size() < base:
		print("  提示：硬缺口已降到 %d，请把 %s 更新为 %d" % [hard_gaps.size(), BASELINE, hard_gaps.size()])

	quit(1 if (problems.size() > 0 or new_problems) else 0)

func _read_baseline() -> int:
	if not FileAccess.file_exists(BASELINE):
		return 0
	for line in FileAccess.open(BASELINE, FileAccess.READ).get_as_text().split("\n"):
		var t := line.strip_edges()
		if t != "" and not t.begins_with("#"):
			return int(t)
	return 0
