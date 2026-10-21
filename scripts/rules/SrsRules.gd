class_name SrsRules
## G1：错题间隔重复（SRS）纯规则——无状态、无 IO、无 autoload 依赖。
## 单一来源：间隔阶梯(1/3/7/16/35 天)、到期判定、排程推进(答对进阶 / 答错重置)、毕业判定、当日奖励去重。
##
## 约定：
## - 天数用「日序号」表示（本地日历日 / 86400 的整数日），不用时间戳——避免跨时区与夏令时漂移；
## - 「旧档无时间戳」一律视为**立即到期**（due_day = 0），天然兼容历史存档；
## - 采用 Leitner 分箱而非 SM-2 的 ease 乘子：排程可复现、便于单测与回放。
##
## 单测：tests/Tests.gd::_test_srs_rules()

## 间隔阶梯（天）：新错 → 1 天；之后每连续答对一次进一档 → 3 / 7 / 16 / 35 天。
const INTERVALS: Array[int] = [1, 3, 7, 16, 35]
## 阶梯末级下标（越界夹取）。
const MAX_STEP := 4
## 连续答对达到此次数即「毕业」——从复习计划移除，不再排程。
const GRADUATE_OK := 4
## 复习答对的奖励金币（同一题当日只发一次，见 rewarded_today）。
const REVIEW_COINS := 2
## 毕业奖励金币（每题仅一次：毕业即从计划移除）。
const GRADUATE_COINS := 5

## 阶梯间隔：step 越大间隔越长；越界夹到末级。
static func interval_days(step: int) -> int:
	return INTERVALS[clampi(step, 0, MAX_STEP)]

## 新错题的计划：阶梯归零、明天到期（首次错误也进复习计划）。
static func new_plan(level_id: String, qi: int, qname: String, module: String,
		now_ts: int, today_day: int) -> Dictionary:
	return {
		"level_id": level_id, "qi": qi, "name": qname, "module": module,
		"step": 0, "ok_streak": 0, "interval_days": INTERVALS[0],
		"due_day": today_day + INTERVALS[0], "last_wrong_day": today_day,
		"first_wrong_at": now_ts, "last_review_at": now_ts,
		"wrong_count": 1, "last_reward_day": "",
	}

## 推进排程：答对 → 阶梯 +1、到期日推后；答错 → 阶梯归零、明天再来。
## 返回**新的**计划 dict（不改入参）；graduated=true 表示本次答对后该题毕业。
static func advance(plan: Dictionary, correct: bool, now_ts: int, today_day: int) -> Dictionary:
	var p := plan.duplicate()
	p["last_review_at"] = now_ts
	if correct:
		p["ok_streak"] = int(p.get("ok_streak", 0)) + 1
		var step := clampi(int(p.get("step", 0)) + 1, 0, MAX_STEP)
		p["step"] = step
		p["interval_days"] = interval_days(step)
		p["last_wrong_day"] = 0    # 已答对 → 不再算「今天刚错过」
	else:
		p["ok_streak"] = 0
		p["step"] = 0
		p["interval_days"] = INTERVALS[0]
		p["wrong_count"] = int(p.get("wrong_count", 0)) + 1
		p["last_wrong_day"] = today_day
	p["due_day"] = today_day + int(p["interval_days"])
	p["graduated"] = correct and int(p.get("ok_streak", 0)) >= GRADUATE_OK
	return p

## 计划里记录的到期日；旧档无此字段 → 0（视为立即到期）。
static func due_day_of(plan: Dictionary) -> int:
	return int(plan.get("due_day", 0))

## 有效到期日：尚未到期、但「今天刚错过」的题视作今天到期
## （保留「错题优先」的即时复练，同时不破坏间隔语义）。
static func eff_due_day(plan: Dictionary, today_day: int) -> int:
	var d := due_day_of(plan)
	if d > today_day and int(plan.get("last_wrong_day", 0)) == today_day:
		return today_day
	return d

## 是否到期：到期日已过，或今天刚错过。
static func is_due(plan: Dictionary, today_day: int) -> bool:
	return eff_due_day(plan, today_day) <= today_day

## 两个计划的先后（a 排前 = true）：有效到期日升序 → 错次多优先 → 题号稳定。
static func plan_less(a: Dictionary, b: Dictionary, today_day: int) -> bool:
	var da := eff_due_day(a, today_day)
	var db := eff_due_day(b, today_day)
	if da != db:
		return da < db
	var wa := int(a.get("wrong_count", 0))
	var wb := int(b.get("wrong_count", 0))
	if wa != wb:
		return wa > wb
	return int(a.get("qi", 0)) < int(b.get("qi", 0))

## 清单中到期条数。
static func count_due(plans: Array, today_day: int) -> int:
	var n := 0
	for p in plans:
		if is_due(p, today_day):
			n += 1
	return n

## 该题今日是否已发过复习奖励（同题当日不重复计奖，防刷）。
static func rewarded_today(plan: Dictionary, today: String) -> bool:
	return today != "" and str(plan.get("last_reward_day", "")) == today

## 距离到期还有几天（<=0 表示已到期 / 今天到期）。
static func days_left(plan: Dictionary, today_day: int) -> int:
	return eff_due_day(plan, today_day) - today_day

## 到期状态文案（错题本展示用）。旧档（无 due_day）显示「待复习」。
static func due_text(plan: Dictionary, today_day: int) -> String:
	if due_day_of(plan) <= 0:
		return "待复习"
	var d := days_left(plan, today_day)
	if d < 0:
		return "已逾期 %d 天" % (-d)
	if d == 0:
		return "今天到期"
	return "%d 天后复习" % d
