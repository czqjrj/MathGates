class_name SrsStore
## G1：错题间隔重复（SRS）存档层——纯操作 srs_plan / wrong_log 两个字典，不碰 autoload、UI 与磁盘。
## 与 SrsRules 的分工：SrsRules 管「一条排程怎么算」，SrsStore 管「整本排程怎么存、怎么查、怎么排序」。
##
## 约定：
## - 所有函数只吃字典与标量，不读全局状态，便于单测与回放；
## - 旧档（只有错题记录、没有排程）一律合成 due_day=0 的「立即到期」计划，天然兼容历史存档；
## - answer() 就地改传入的 plans 字典（存档层语义），返回值只带奖励与毕业信号。
##
## 单测：tests/Tests.gd::_test_srs_store()

## 计划键："level_id#qi"
static func key(level_id: String, qi: int) -> String:
	return "%s#%d" % [level_id, qi]

## 旧档计划合成：只有错题记录、没有排程 → 无时间戳 → 立即到期。
static func legacy_plan(w: Dictionary) -> Dictionary:
	var p := SrsRules.new_plan(str(w.get("level_id", "")), int(w.get("qi", 0)),
		str(w.get("name", "")), str(w.get("module", "")), 0, 0)
	p["due_day"] = 0
	p["last_wrong_day"] = 0
	p["wrong_count"] = int(w.get("count", 0))
	return p

## 某题的计划：优先取排程；无排程但有错题记录 → 旧档（立即到期）；都没有 → {}。
static func plan_for(plans: Dictionary, wrong_log: Dictionary, level_id: String, qi: int) -> Dictionary:
	var k := key(level_id, qi)
	if plans.has(k) and typeof(plans[k]) == TYPE_DICTIONARY:
		return plans[k]
	var w = wrong_log.get(k, {})
	if typeof(w) != TYPE_DICTIONARY or (w as Dictionary).is_empty():
		return {}
	return legacy_plan(w)

## 今日到期清单（SRS 到期 + 今天新错 + 旧档无时间戳者），按到期顺序排。
static func due_list(plans: Dictionary, wrong_log: Dictionary, today_day: int) -> Array:
	var out: Array = []
	for k in plans.keys():
		if typeof(plans[k]) != TYPE_DICTIONARY:
			continue
		var p: Dictionary = plans[k]
		if SrsRules.is_due(p, today_day):
			out.append(p)
	for k in wrong_log.keys():
		if plans.has(k) or typeof(wrong_log[k]) != TYPE_DICTIONARY:
			continue
		out.append(legacy_plan(wrong_log[k]))
	out.sort_custom(func(a, b): return SrsRules.plan_less(a, b, today_day))
	return out

## 并入一次作答（就地改 plans）：答对进阶、答错重置、连续答对 SrsRules.GRADUATE_OK 次即毕业。
## 返回 {"coins": 本次奖励金币, "graduated": 是否毕业}。
static func answer(plans: Dictionary, level_id: String, qi: int,
		qname: String, module: String, correct: bool, now_ts: int, today_day: int,
		today: String) -> Dictionary:
	var k := key(level_id, qi)
	var plan: Dictionary = plans.get(k, {})
	if plan.is_empty():
		# 从未错过且本次答对 → 不进复习计划
		if not correct:
			plans[k] = SrsRules.new_plan(level_id, qi, qname, module, now_ts, today_day)
		return {"coins": 0, "graduated": false}
	plan = SrsRules.advance(plan, correct, now_ts, today_day)
	if bool(plan.get("graduated", false)):
		plans.erase(k)
		return {"coins": SrsRules.GRADUATE_COINS, "graduated": true}
	var gain := 0
	if correct and not SrsRules.rewarded_today(plan, today):
		plan["last_reward_day"] = today
		gain = SrsRules.REVIEW_COINS
	plans[k] = plan
	return {"coins": gain, "graduated": false}

## 存档迁移：字段补全与钳制（缺字段按「立即到期」处理，旧档天然兼容）。
static func normalize(plans: Dictionary) -> Dictionary:
	var out := {}
	for k in plans.keys():
		var rec = plans[k]
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		var p: Dictionary = rec
		p["level_id"] = str(p.get("level_id", str(k).split("#")[0]))
		p["qi"] = int(p.get("qi", 0))
		p["name"] = str(p.get("name", ""))
		p["module"] = str(p.get("module", ""))
		p["step"] = clampi(int(p.get("step", 0)), 0, SrsRules.MAX_STEP)
		p["ok_streak"] = maxi(0, int(p.get("ok_streak", 0)))
		p["interval_days"] = maxi(1, int(p.get("interval_days", SrsRules.INTERVALS[0])))
		p["due_day"] = int(p.get("due_day", 0))
		p["last_wrong_day"] = int(p.get("last_wrong_day", 0))
		p["first_wrong_at"] = int(p.get("first_wrong_at", 0))
		p["last_review_at"] = int(p.get("last_review_at", 0))
		p["wrong_count"] = maxi(0, int(p.get("wrong_count", 0)))
		p["last_reward_day"] = str(p.get("last_reward_day", ""))
		out[k] = p
	return out

## 复习排程：把**到期**的错题(SRS 排程 / 旧档视为立即到期)重排到关卡最前面，其余保持原序。
## 返回 { stages: 重排后的题列表, order: Array[int](显示下标→原始下标), review: bool }。
## 注意：order[i] 为该显示位置对应的原始题号，记录作答时须用它作为 qi，才能与错题账本对齐。
static func review_order(level_id: String, stages: Array, focus: int, plans: Dictionary,
		wrong_log: Dictionary, today_day: int) -> Dictionary:
	var n := stages.size()
	var order: Array[int] = []
	for i in n:
		order.append(i)
	# 到期的错题（按到期日 → 错次 → 题号排序）；未到期的保持原序。
	var due: Array[int] = []
	for i in n:
		var p := plan_for(plans, wrong_log, level_id, i)
		if not p.is_empty() and SrsRules.is_due(p, today_day):
			due.append(i)
	due.sort_custom(func(a: int, b: int) -> bool:
		return SrsRules.plan_less(plan_for(plans, wrong_log, level_id, a),
			plan_for(plans, wrong_log, level_id, b), today_day))
	if due.size() > 0 and n >= 2:
		var rest: Array[int] = []
		for i in n:
			if not due.has(i):
				rest.append(i)
		order = due + rest
	# 错题深链：把指定题号提到最前，实现「去复习第 N 题」
	var has_focus := focus >= 0 and focus < n
	if has_focus:
		order.erase(focus)
		order.push_front(focus)
	var re: Array = []
	for i in order:
		re.append(stages[i])
	return {"stages": re, "order": order, "review": due.size() > 0 and n >= 2}

## 萌宠复习任务：今日到期的排最前，其余错题按错次补位，最多 limit 条。
## meta(lid) 需返回 { valid: bool, chapter: String, level_name: String, domain: Variant }。
static func pet_quests(limit: int, plans: Dictionary, wrong_log: Dictionary, wrongs: Array,
		meta: Callable, today_day: int) -> Array:
	var out: Array = []
	var seen := {}
	# ① 今日到期（SRS 排程）优先
	for rec in due_list(plans, wrong_log, today_day):
		if out.size() >= limit:
			break
		var lid := str(rec.get("level_id", ""))
		var qi := int(rec.get("qi", 0))
		var m: Dictionary = meta.call(lid)
		if not bool(m.get("valid", false)):
			continue
		out.append(quest_of(lid, qi, str(rec.get("name", "")), str(rec.get("module", "")),
			int(rec.get("wrong_count", 0)), m))
		seen[key(lid, qi)] = true
	# ② 其余错题（未到期）按累计错次补位
	for rec in wrongs:
		if out.size() >= limit:
			break
		var lid2 := str(rec.get("level_id", ""))
		var qi2 := int(rec.get("qi", 0))
		if seen.has(key(lid2, qi2)):
			continue
		var m2: Dictionary = meta.call(lid2)
		if not bool(m2.get("valid", false)):
			continue
		out.append(quest_of(lid2, qi2, str(rec.get("name", "")), str(rec.get("module", "")),
			int(rec.get("count", 0)), m2))
	return out

## 复习任务的统一结构（供萌宠任务与首页入口使用）。
static func quest_of(level_id: String, qi: int, qname: String, module: String, count: int,
		meta: Dictionary) -> Dictionary:
	return {
		"level_id": level_id, "qi": qi,
		"name": qname,
		"module": module,
		"count": count,
		"chapter": str(meta.get("chapter", "")),
		"level_name": str(meta.get("level_name", "")),
		"domain": meta.get("domain", {}),
	}
