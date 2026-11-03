extends SceneTree
## E4 · 专题章 references 校验器 (headless)。
##
## 用法： godot --headless --path . --script res://tools/check_thinking_refs.gd
##
## 作用:
##   1. 校验 data/thinking_levels.json 每个专题的 references.chapters/points 是否有效
##   2. 统计引用覆盖率 (valid_points / total_points)
##   3. 生成 docs/专题章 references 报告.md
##
## 退出码:0 = 通过;1 = 有错误。

const THINKING_PATH := "res://data/thinking_levels.json"
const KM_PATH := "res://data/knowledge_map.json"
const CUR_PATH := "res://data/curriculum.json"
const DOC := "res://docs/专题章 references 报告.md"


func _initialize() -> void:
	if not FileAccess.file_exists(THINKING_PATH):
		push_error("E4-FAIL: thinking_levels.json 不存在")
		quit(1)
		return
	if not FileAccess.file_exists(KM_PATH):
		push_error("E4-FAIL: knowledge_map.json 不存在")
		quit(1)
		return
	if not FileAccess.file_exists(CUR_PATH):
		push_error("E4-FAIL: curriculum.json 不存在")
		quit(1)
		return
	
	var thinking_txt := FileAccess.open(THINKING_PATH, FileAccess.READ).get_as_text()
	var km_txt := FileAccess.open(KM_PATH, FileAccess.READ).get_as_text()
	var cur_txt := FileAccess.open(CUR_PATH, FileAccess.READ).get_as_text()
	
	var thinking_data: Dictionary = JSON.parse_string(thinking_txt)
	var km_data: Dictionary = JSON.parse_string(km_txt)
	var cur_data: Dictionary = JSON.parse_string(cur_txt)
	
	if thinking_data.is_empty() or km_data.is_empty() or cur_data.is_empty():
		push_error("E4-FAIL: 无法解析数据文件")
		quit(1)
		return
	
	# 构建有效集合
	var valid_chapters: Array[String] = []
	var chapter_titles: Dictionary = {}
	var chapters_arr: Array = cur_data.get("chapters", [])
	for i in chapters_arr.size():
		var c: Dictionary = chapters_arr[i]
		var cid := str(c.get("id", ""))
		valid_chapters.append(cid)
		chapter_titles[cid] = str(c.get("title", ""))
	
	var valid_points: Dictionary = {}
	var point_to_chapter: Dictionary = {}
	var km_chapters_arr: Array = km_data.get("chapters", [])
	for i in km_chapters_arr.size():
		var c: Dictionary = km_chapters_arr[i]
		var cid := str(c.get("id", ""))
		var points_arr: Array = c.get("points", [])
		for j in points_arr.size():
			var p: Dictionary = points_arr[j]
			var pname := str(p.get("name", ""))
			var levels_arr: Array = p.get("levels", [])
			for k in levels_arr.size():
				var lv = levels_arr[k]
				valid_points[str(lv)] = pname
				point_to_chapter[str(lv)] = cid
	
	# 校验
	var errors: Array[String] = []
	var stats: Dictionary = {
		"total_topics": 0,
		"valid_topics": 0,
		"invalid_chapters": 0,
		"invalid_chapters_detail": [],
		"total_points": 0,
		"valid_points": 0,
		"invalid_points": 0,
		"invalid_points_detail": [],
	}
	
	var keys_arr: Array = thinking_data.keys()
	for idx in keys_arr.size():
		var key: String = keys_arr[idx]
		var v: Dictionary = thinking_data[key]
		var refs: Dictionary = v.get("references", {})
		stats["total_topics"] += 1
		
		var topic_errors: Array[String] = []
		
		# 校验 chapters
		var method: String = str(v.get("method", key))
		var chaps: Array = refs.get("chapters", [])
		for ci in chaps.size():
			var ch = chaps[ci]
			var chid := str(ch)
			if chid == "":
				topic_errors.append("[%s/%s] references.chapters 含空条目" % [key, method])
			elif not valid_chapters.has(chid):
				stats["invalid_chapters"] += 1
				stats["invalid_chapters_detail"].append("%s:%s" % [key, chid])
				topic_errors.append("[%s/%s] references.chapters 引用了不存在的章节：%s" % [key, method, chid])
		
		# 校验 points
		var pts: Array = refs.get("points", [])
		for pi in pts.size():
			var p = pts[pi]
			var pt := str(p)
			if pt == "":
				topic_errors.append("[%s/%s] references.points 含空条目" % [key, method])
			elif not valid_points.has(pt):
				stats["total_points"] += 1
				stats["invalid_points"] += 1
				stats["invalid_points_detail"].append("%s:%s" % [key, pt])
				topic_errors.append("[%s/%s] references.points 引用了未覆盖的点：%s" % [key, method, pt])
			else:
				stats["total_points"] += 1
				stats["valid_points"] += 1
		
		# 校验 description
		var desc_val = refs.get("description")
		if desc_val == null or str(desc_val).strip_edges() == "":
			topic_errors.append("[%s/%s] references.description 缺失或为空" % [key, method])
		
		if topic_errors.is_empty():
			stats["valid_topics"] += 1
		else:
			errors.append_array(topic_errors)
	
	# 生成文档
	var doc: PackedStringArray = []
	doc.append("# 专题章 references 校验报告 (E4)\n")
	doc.append("> 本文件由 `data/thinking_levels.json` + `data/knowledge_map.json` + `data/curriculum.json` **自动生成**。\n")
	doc.append("## 0. 概览\n")
	doc.append("- 专题总数:**%d**" % stats["total_topics"])
	doc.append("- 校验通过:**%d**" % stats["valid_topics"])
	doc.append("- 引用章节错误:**%d**" % stats["invalid_chapters"])
	var total_pts: int = max(1, stats["total_points"])
	var valid_pct: float = float(stats["valid_points"]) / float(total_pts) * 100.0
	doc.append("- 引用知识点错误:**%d**(共 %d 个知识点引用，通过率 %.1f%%)\n" % [
		stats["invalid_points"],
		stats["total_points"],
		valid_pct,
	])
	
	var bad_chaps: Array = stats["invalid_chapters_detail"]
	if not bad_chaps.is_empty():
		doc.append("### 错误的章节引用\n")
		for detail in bad_chaps:
			doc.append("- %s" % detail)
		doc.append("")
	
	var bad_pts: Array = stats["invalid_points_detail"]
	if not bad_pts.is_empty():
		doc.append("### 错误的知识点引用\n")
		for detail in bad_pts:
			doc.append("- %s" % detail)
		doc.append("")
	
	# 详细校验结果
	doc.append("## 1. 各专题校验结果\n")
	for idx in keys_arr.size():
		var key: String = keys_arr[idx]
		var v: Dictionary = thinking_data[key]
		var refs: Dictionary = v.get("references", {})
		var method: String = str(v.get("method", key))
		var title: String = str(v.get("title", ""))
		
		doc.append("### %s (`%s`)\n" % [title, key])
		doc.append("- 方法：%s" % method)
		var ch_list: Array = []
		var chaps: Array = refs.get("chapters", [])
		for ci in chaps.size():
			ch_list.append(str(chaps[ci]))
		var ch_str: String = "、".join(ch_list) if not ch_list.is_empty() else "—"
		doc.append("- 关联章节：%s" % ch_str)
		var pts_arr: Array = refs.get("points", [])
		doc.append("- 关联知识点：%d 个" % pts_arr.size())
		var desc_str: String = str(refs.get("description", "")).strip_edges()
		var desc_status: String = desc_str if desc_str != "" else "❌ 缺失"
		doc.append("- 描述：%s" % desc_str)
		
		# 检查有效性
		var has_error: bool = false
		var err_list: Array[String] = []
		for ci in chaps.size():
			var chid: String = str(chaps[ci])
			if chid != "" and not valid_chapters.has(chid):
				has_error = true
				err_list.append("章节 %s 不存在" % chid)
		for pi in pts_arr.size():
			var pt: String = str(pts_arr[pi])
			if pt != "" and not valid_points.has(pt):
				has_error = true
				err_list.append("点 %s 未覆盖" % pt)
		
		if has_error:
			doc.append("- **状态**: ❌ 有错误")
			for e in err_list:
				doc.append("  - %s" % e)
		else:
			doc.append("- **状态**: ✅ 校验通过")
		doc.append("")
	
	# 写文档
	FileAccess.open(DOC, FileAccess.WRITE).store_string("\n".join(doc) + "\n")
	
	# 控制台输出
	var total_pt_cnt: int = max(1, stats["total_points"])
	var pct: float = float(stats["valid_points"]) / float(total_pt_cnt) * 100.0
	print("E4: %d topics / %d valid / %d invalid_chapters / %d/%d points (%.1f%% valid)" % [
		stats["total_topics"],
		stats["valid_topics"],
		stats["invalid_chapters"],
		stats["valid_points"],
		total_pt_cnt,
		pct,
	])
	if not errors.is_empty():
		print("  E4-ERRORS:")
		for e in errors:
			print("    - " + e)
		print("E4-FAIL: %d 处 references 错误" % errors.size())
	else:
		print("  ✓ 全部校验通过")
	
	var have_bad_chaps: bool = not stats["invalid_chapters_detail"].is_empty()
	var have_bad_pts: bool = not stats["invalid_points_detail"].is_empty()
	if have_bad_chaps or have_bad_pts:
		print("  报告已生成：%s" % DOC)
		print("  提示：需要先补全知识点的关卡挂接，再修正 references 中的引用 ID")
		quit(1)
	else:
		quit(0)
