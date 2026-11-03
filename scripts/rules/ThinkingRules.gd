## E4 · 专题章 references 校验规则（纯函数、无 IO）。
##
## 用法：ThinkingRules.validate_thinking(thinking_data, knowledge_map_data)
##       → (valid: bool, errors: Array[String])
##
## 作用：
##   1. 校验每个专题的 references.chapters 必须是 curriculum 真实章节
##   2. references.points 必须存在且已挂关卡
##   3. 生成可消费的 summary_text（用于知识点页「相关思想方法」入口）

const THINKING_PATH := "res://data/thinking_levels.json"
const KM_PATH := "res://data/knowledge_map.json"
const CUR_PATH := "res://data/curriculum.json"


static func validate_references(thinking_id: String, refs: Dictionary, valid_chapters: Array[String], valid_points: Dictionary) -> Array[String]:
	"""
	校验单个专题的 references 字段。
	valid_points: { level_id: point_name }
	返回错误信息数组。
	"""
	var errors: Array[String] = []
	
	if not refs.has("chapters") or not refs["chapters"] is Array:
		errors.append("[%s] references.chapters 缺失或不是数组" % thinking_id)
		return errors
	
	for ch in refs.get("chapters", []):
		var chid := str(ch)
		if chid == "":
			errors.append("[%s] references.chapters 含空条目" % thinking_id)
			continue
		if not valid_chapters.has(chid):
			errors.append("[%s] references.chapters 引用了不存在的章节：%s" % [thinking_id, chid])
	
	if not refs.has("points") or not refs["points"] is Array:
		errors.append("[%s] references.points 缺失或不是数组" % thinking_id)
		return errors
	
	for p in refs.get("points", []):
		var pt := str(p)
		if pt == "":
			errors.append("[%s] references.points 含空条目" % thinking_id)
			continue
		if not valid_points.has(pt):
			errors.append("[%s] references.points 引用了未覆盖的点：%s" % [thinking_id, pt])
	
	if not refs.has("description") or str(refs.get("description", "")).strip_edges() == "":
		errors.append("[%s] references.description 缺失或为空" % thinking_id)
	
	return errors


static func validate_thinking(thinking_data: Dictionary, km_data: Dictionary, cur_data: Dictionary) -> Dictionary:
	"""
	校验整个 thinking_levels.json。
	返回 { valid: bool, errors: Array[String], stats: Dictionary }
	stats: { total: int, valid_chapters: int, invalid_chapters: int, total_points: int, valid_points: int, invalid_points: int }
	"""
	var errors: Array[String] = []
	
	# 构建有效集合
	var valid_chapters: Array[String] = []
	for c in cur_data.get("chapters", []):
		valid_chapters.append(str(c.get("id", "")))
	
	var valid_points: Dictionary = {}
	var chapter_of_point: Dictionary = {}
	for c in km_data.get("chapters", []):
		var cid := str(c.get("id", ""))
		for p in c.get("points", []):
			for lv in p.get("levels", []):
				valid_points[str(lv)] = str(p.get("name", ""))
				chapter_of_point[str(lv)] = cid
	
	var total := 0
	var valid_topics := 0
	var invalid_chapters := 0
	var total_points := 0
	var valid_points_cnt := 0
	var invalid_points_cnt := 0
	
	for key in thinking_data.keys():
		var v: Dictionary = thinking_data[key]
		var refs: Dictionary = v.get("references", {})
		
		total += 1
		var topic_errors := validate_references(key, refs, valid_chapters, valid_points)
		if not topic_errors.is_empty():
			errors.append_array(topic_errors)
		else:
			valid_topics += 1
		
		# 统计引用情况
		for ch in refs.get("chapters", []):
			if str(ch) in valid_chapters:
				pass # valid
			else:
				invalid_chapters += 1
		
		for p in refs.get("points", []):
			total_points += 1
			if str(p) in valid_points:
				valid_points_cnt += 1
			else:
				invalid_points_cnt += 1
	
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"stats": {
			"total": total,
			"valid_topics": valid_topics,
			"invalid_chapters": invalid_chapters,
			"total_points": total_points,
			"valid_points": valid_points_cnt,
			"invalid_points": invalid_points_cnt,
		}
	}


static func build_summary(thinking_id: String, refs: Dictionary, km_data: Dictionary, chapter_titles: Dictionary) -> String:
	"""
	生成分享摘要文本，用于知识点页「相关思想方法」入口显示。
	示例：「数形结合」关联函数（概念/定义域/值域）、圆锥曲线（几何性质）、圆（标准方程/一般方程）、直线（方程）。
	"""
	var lines: Array[String] = []
	
	# 标题
	var method := str(refs.get("method", thinking_id))
	lines.append("「%s」思想专题" % method if method != thinking_id else "数学思想综合")
	
	# 按章节分组
	var by_chapter: Dictionary = {}
	for p in refs.get("points", []):
		var pt := str(p)
		# TODO: 实际应查 km_data 找到该点对应的章节
		# 这里简化处理
		by_chapter[pt] = true
	
	if refs.has("chapters"):
		var ch_list: Array[String] = []
		for ch in refs.get("chapters", []):
			var chid := str(ch)
			if chid in chapter_titles:
				ch_list.append(chapter_titles[chid])
			else:
				ch_list.append(chid)
		if not ch_list.is_empty():
			lines.append("关联章节：" + "、".join(ch_list))
	
	if refs.has("description"):
		lines.append(str(refs.get("description", "")))
	
	return "\n".join(lines)
