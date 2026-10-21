class_name ReportRules
## G3：学习报告 / 家长视图的纯规则层——聚合、排序、序列化。
## 不读 autoload、不碰磁盘、不联网；数据全部由调用方传入。
##
## 约定：
## - 活动日志 activity：按天一条 {date, answered, correct, stars, clears, reviews}，
##   最多保留 KEEP_DAYS 天（更早的裁掉，避免存档无限膨胀）；
## - 日期一律用「日历日字符串 YYYY-MM-DD」；内部换算成日序号做**纯日历加减**
##   （按 UTC 解释、无时区概念，故不随时区/夏令时漂移）；
## - 家长视图只给聚合量与**领域级**薄弱点，不含题目原文 / 关卡名 / 作答内容（隐私最小化）；
## - 报告默认本地生成、不上传（与 F1 的隐私策略一致）。
##
## 单测：tests/Tests.gd::_test_report_rules()

## 活动日志保留天数（超出裁掉最早的一天）。
const KEEP_DAYS := 120
## 逐日指标。
const METRICS := ["answered", "correct", "stars", "clears", "reviews"]

## 取计数（缺失 / null / 非数字 → 0）——脏档不炸。
static func _num(v: Variant, def: int = 0) -> int:
	if v == null:
		return def
	var t := typeof(v)
	if t == TYPE_INT or t == TYPE_FLOAT or t == TYPE_BOOL:
		return int(v)
	return def

## 日序号 → 日期串（以正午为锚点，避免边界漂移）。
static func date_of(index: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(index * 86400 + 43200)
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]

## 日期串 → 日序号（纯日历日；非法串返回 0）。
static func index_of(date: String) -> int:
	var p := date.split("-")
	if p.size() != 3:
		return 0
	return int(Time.get_unix_time_from_datetime_dict({
		"year": int(p[0]), "month": int(p[1]), "day": int(p[2]),
		"hour": 12, "minute": 0, "second": 0}) / 86400)

## 最近 n 天的日期串（升序，最后一个就是今天）。
static func recent_dates(today: String, n: int) -> Array:
	var out := []
	var days := maxi(1, n)
	var t := index_of(today)
	for i in days:
		out.append(date_of(t - (days - 1 - i)))
	return out

## 取某个天的活动记录；没有则返回 {}。
static func day_record(activity: Array, date: String) -> Dictionary:
	for rec in activity:
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		var r: Dictionary = rec
		if str(r.get("date", "")) == date:
			return r
	return {}

## 累加某天某项指标，返回**新的**活动日志（不改动入参；裁剪到最近 KEEP_DAYS 天）。
static func bump(activity: Array, date: String, metric: String, delta: int = 1) -> Array:
	var out := []
	for rec in activity:
		if typeof(rec) == TYPE_DICTIONARY:
			var r: Dictionary = rec
			out.append(r.duplicate())
	var hit := -1
	for i in out.size():
		var r2: Dictionary = out[i]
		if str(r2.get("date", "")) == date:
			hit = i
			break
	if hit < 0:
		var rec2 := { "date": date }
		for m in METRICS:
			rec2[m] = 0
		out.append(rec2)
		hit = out.size() - 1
	var r3: Dictionary = out[hit]
	r3[metric] = maxi(0, _num(r3.get(metric, 0)) + delta)
	out.sort_custom(func(a, b) -> bool:
		return str((a as Dictionary).get("date", "")) < str((b as Dictionary).get("date", "")))
	while out.size() > KEEP_DAYS:
		out.pop_front()
	return out

## 汇总最近 n 天：{from, to, days, answered, correct, accuracy, stars, clears, reviews,
## active_days, daily:[{date, answered, ...}]}。
static func summarize(activity: Array, today: String, days: int) -> Dictionary:
	var dates := recent_dates(today, days)
	var daily := []
	var answered := 0
	var correct := 0
	var stars := 0
	var clears := 0
	var reviews := 0
	var active := 0
	for d in dates:
		var rec := day_record(activity, str(d))
		var row := { "date": str(d) }
		for m in METRICS:
			row[m] = _num(rec.get(m, 0))
		daily.append(row)
		answered += int(row["answered"])
		correct += int(row["correct"])
		stars += int(row["stars"])
		clears += int(row["clears"])
		reviews += int(row["reviews"])
		if int(row["answered"]) > 0 or int(row["reviews"]) > 0:
			active += 1
	return {
		"from": str(dates[0]),
		"to": str(dates[dates.size() - 1]),
		"days": dates.size(),
		"answered": answered,
		"correct": correct,
		"accuracy": (float(correct) / float(answered)) if answered > 0 else 0.0,
		"stars": stars,
		"clears": clears,
		"reviews": reviews,
		"active_days": active,
		"daily": daily,
	}

## 薄弱点（领域级）：入参是 GameData.diagnose() 的 weak 数组；
## 输出只含领域 id / 名 / 掌握度 / 错次——**不含关卡名与题目原文**。
static func weak_points(weak: Array, limit: int = 3) -> Array:
	var out := []
	for w in weak:
		if out.size() >= limit:
			break
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = w
		var dom = item.get("domain", {})
		if typeof(dom) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = dom
		out.append({
			"id": str(d.get("id", "")),
			"title": str(d.get("title", "")),
			"mastery": int(round(float(item.get("mastery", 0.0)) * 100.0)),
			"wrong": int(item.get("wrong_count", 0)),
		})
	return out

## 家长视图：只含聚合量与领域薄弱点名（隐私最小化，默认本地生成不联网）。
static func parent_view(summary: Dictionary, weak: Array) -> Dictionary:
	var titles := []
	for w in weak:
		if typeof(w) == TYPE_DICTIONARY:
			var item: Dictionary = w
			titles.append(str(item.get("title", "")))
	return {
		"from": str(summary.get("from", "")),
		"to": str(summary.get("to", "")),
		"answered": int(summary.get("answered", 0)),
		"accuracy": int(round(float(summary.get("accuracy", 0.0)) * 100.0)),
		"active_days": int(summary.get("active_days", 0)),
		"stars": int(summary.get("stars", 0)),
		"weak_titles": titles,
		"note": "本视图仅含汇总数据，不含题目原文与作答内容；报告在本地生成，不联网。",
	}


