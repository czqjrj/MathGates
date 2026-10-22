class_name TreeRules
## A4 第六刀：从 TheoremTree 切出的**知识树布局纯规则**——无状态、无 IO、无 autoload 依赖。
## 单一来源：关卡分组（显式 group / "N-M" 编号 / 隐藏 Boss 殿后）与 Catmull-Rom 曲线平滑。
## 调用方约定：数据由调用方取出后传入；节点创建/绘制/滚动仍在 TheoremTree 之后。
## 单测：tests/Tests.gd::_test_tree_rules()（构造数据）。

## 关卡分组(纯)：返回 [{title, boss, items:[{li, code, title, technique, optional, after}]}]。
## 任一关自带 group 字段 → 按该字段分组；否则按 "N-M" 的 N 分单元。
## 编号：名为 "1-2 xxx" → code "1-2"；否则按顺序号 "01"（避免整段标题塞进节点圆环）。
## 隐藏 Boss 始终排在所有单元之后。
static func disasm_groups(levels: Array, group_names: Array, module_title: String) -> Array:
	var explicit := false
	for lv in levels:
		if str((lv as Dictionary).get("group", "")) != "":
			explicit = true
			break
	var gmap: Dictionary = {}
	var order: Array = []
	var gtitle: Dictionary = {}
	for li in levels.size():
		var lv: Dictionary = levels[li]
		var nm := str(lv.get("name", ""))
		var is_boss := nm.contains("Boss") or nm.contains("隐藏")
		var key := ""
		var code := ""
		if is_boss:
			key = "b"
			code = "BOSS"
		else:
			# 关卡名形如 "1-2 平行判定" 时用 "1-2" 作节点编号并按单元分组;
			# 否则(如"集合的交并补")用顺序号,避免整段标题塞进节点圆环。
			var parts := nm.split(" ", false)
			var first := parts[0] if parts.size() > 0 else ""
			var np := first.split("-", false)
			var has_num := np.size() == 2 and np[0].is_valid_int() and np[1].is_valid_int()
			if has_num:
				code = first
			else:
				code = "%02d" % (li + 1)
			# 合并章节各关卡自带 group(原章节标题) → 按该字段分单元；
			# 普通章节沿用 "N-M" 的 N 分组。
			var grp := str(lv.get("group", ""))
			if explicit and grp != "":
				key = "g:" + grp
				gtitle[key] = grp
			else:
				key = "n:" + (str(int(np[0]) - 1) if has_num else "0")
		if not gmap.has(key):
			gmap[key] = { "items": [] }
			if not is_boss:
				order.append(key)
		var item_title := str(nm)
		if is_boss:
			item_title = nm.replace("隐藏Boss · ", "").strip_edges()
		gmap[key]["items"].append({
			"li": li, "code": code,
			"title": item_title,
			"technique": str(lv.get("technique", "")),
			"optional": bool(lv.get("optional", false)),
			"after": str(lv.get("after", "")),
		})
	# 隐藏挑战(Boss)始终排在所有单元之后
	if gmap.has("b"):
		order.append("b")

	var out: Array = []
	for key in order:
		var boss: bool = key == "b"
		var title := "隐藏挑战"
		if not boss and gtitle.has(key):
			title = str(gtitle[key])
		elif not boss:
			var gidx := int(str(key).substr(2))
			if gidx < group_names.size():
				title = str(group_names[gidx])
			elif order.size() == 1:
				title = module_title
			else:
				title = "单元 %d" % (gidx + 1)
		out.append({ "title": title, "boss": boss, "items": gmap[key]["items"] })
	return out

## 当前单元(章节)的累计星数(纯)：Boss 门/宝箱门槛的唯一来源。
static func region_stars(levels: Array, stars: Dictionary) -> int:
	var total := 0
	for lv in levels:
		total += int(stars.get(str((lv as Dictionary).get("id", "")), 0))
	return total

## 关卡表内按 id 查索引(纯)；找不到返回 -1。
static func level_li_by_id(levels: Array, level_id: String) -> int:
	for i in levels.size():
		if str((levels[i] as Dictionary).get("id", "")) == level_id:
			return i
	return -1

## 节点解锁判定(纯)：自由模式/首关恒开；已通关可重玩(避免新增门槛把已通关节点锁回去)；
## Boss 门(gate.need_stars>0)以「本单元累计星数」为唯一条件；否则要求上一关 >=1 星。
static func level_unlocked(li: int, levels: Array, stars: Dictionary, free_roam: bool) -> bool:
	if free_roam:
		return true
	if li <= 0:
		return true
	if li >= levels.size():
		return false
	var lv: Dictionary = levels[li]
	if int(stars.get(str(lv.get("id", "")), 0)) >= 1:
		return true
	var gate: Variant = lv.get("gate")
	if gate is Dictionary and int(gate.get("need_stars", 0)) > 0:
		return region_stars(levels, stars) >= int(gate["need_stars"])
	if li - 1 >= levels.size():
		return false
	return int(stars.get(str((levels[li - 1] as Dictionary).get("id", "")), 0)) >= 1

## Catmull-Rom 平滑(纯)：相邻点之间插 per_seg 个采样点，首尾点保留。
static func catmull_rom(pts: PackedVector2Array, per_seg: int) -> PackedVector2Array:
	if pts.size() < 2:
		return pts
	var ext := PackedVector2Array()
	ext.append(pts[0])
	ext.append_array(pts)
	ext.append(pts[pts.size() - 1])
	var out := PackedVector2Array()
	for i in range(1, ext.size() - 2):
		var p0 := ext[i - 1]
		var p1 := ext[i]
		var p2 := ext[i + 1]
		var p3 := ext[i + 2]
		for s in range(per_seg):
			var t := float(s) / float(per_seg)
			var t2 := t * t
			var t3 := t2 * t
			var p := 0.5 * (
				(2.0 * p1)
				+ (-p0 + p2) * t
				+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			out.append(p)
	out.append(pts[pts.size() - 1])
	return out

## 奖励文案(纯)：把 {coins, hint_tokens, coin_boost} 拼成「金币 +50 · 提示卡 +1」；
## 全为 0 或空时返回「—」。宝箱与随机事件共用同一来源。
static func reward_text(reward: Dictionary) -> String:
	var parts: Array = []
	if int(reward.get("coins", 0)) > 0:
		parts.append("金币 +%d" % int(reward.get("coins", 0)))
	if int(reward.get("hint_tokens", 0)) > 0:
		parts.append("提示卡 +%d" % int(reward.get("hint_tokens", 0)))
	if int(reward.get("coin_boost", 0)) > 0:
		parts.append("金币加成 +%d" % int(reward.get("coin_boost", 0)))
	return " · ".join(parts) if not parts.is_empty() else "—"
