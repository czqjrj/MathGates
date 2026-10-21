class_name EconomyRules
## A4 第二刀：从 GameData / MainHub 切出的**经济结算纯规则**——无状态、无 IO、无 autoload 依赖。
## 单一来源：星级经验、每日登录（连击推进+奖励）、通关结算判定（C1/C2）、消费判定、每日任务进度。
## 调用方约定：只在 GameData 门面后使用；存档、通知、音效仍在 GameData 之后。
## 单测：tests/Tests.gd::_test_economy_rules()（构造数据）；
## 门面行为回归：既有 _test_economy / _test_anti_farm / _test_daily。

# ---------------------------------------------------------------- 星级 → 经验（C1）
const EXP_PER_STAR := 10   ## 星级每提升 1 星发放的经验

## 星级提升带来的经验增量：只按「新增星数」计发，未提升为 0（重复通关不刷经验）。
static func exp_for_star_gain(prev_stars: int, new_stars: int) -> int:
	return EXP_PER_STAR * (maxi(prev_stars, new_stars) - prev_stars)

# ---------------------------------------------------------------- 每日登录
const LOGIN_COINS_BASE := 50
const LOGIN_EXP_BASE := 20
const LOGIN_STREAK_MULT := 0.2   ## 连续登录每日额外加成系数（第 n 天 = 基数 ×(1+0.2×(n-1))）

## 连接天数推进：上次登录 = 昨天 → +1；断签或首次 → 从 1 重来。
static func next_login_streak(prev_streak: int, last_login_date: String, yesterday: String) -> int:
	return prev_streak + 1 if last_login_date == yesterday else 1

## 第 streak 天的登录奖励：{coins, exp}（int 截断，与历史行为一致）。
static func login_reward(streak: int) -> Dictionary:
	var mult := 1.0 + LOGIN_STREAK_MULT * float(maxi(1, streak) - 1)
	return {
		"coins": int(float(LOGIN_COINS_BASE) * mult),
		"exp": int(float(LOGIN_EXP_BASE) * mult),
	}

# ---------------------------------------------------------------- 关卡结算判定（C1/C2）
## 通关结算的纯判定：入参为 level_records 字段快照，返回需回写的字段。
## 首次达成某星级 → 全额奖励；重复通关 → 折扣(×0.3)且每日最多 PlayerRules.REPEAT_PAID_PER_DAY 次，
## 跨天(paid_date != today)重置当日计数。折扣公式在 PlayerRules.repeat_grant。
static func settle_grant(base_reward: int, level_stars: int, prev_best: int,
		today: String, paid_date: String, paid_today: int) -> Dictionary:
	var full := level_stars > prev_best
	if full:
		return { "granted": maxi(0, base_reward), "full": true, "paid_date": paid_date, "paid_today": paid_today }
	var pd := paid_date
	var pt := paid_today
	if pd != today:
		pd = today
		pt = 0
	var granted := PlayerRules.repeat_grant(base_reward, pt)
	if granted > 0:
		pt += 1
	return { "granted": granted, "full": false, "paid_date": pd, "paid_today": pt }

# ---------------------------------------------------------------- 消费判定
## 余额是否足够支付：cost<=0 视为无需支付(恒 true)；余额不足 false（调用方不扣款）。
static func can_spend(coins: int, cost: int) -> bool:
	if cost <= 0:
		return true
	return coins >= cost

# ---------------------------------------------------------------- 每日任务进度
## metric=streak → 当日峰值 mini(peak, goal)；否则当日增量 clamp(当前-基准, 0, goal)。
## base/cur 由 GameData 按 metric 从 daily_base/_daily_metrics 取出后传入。
static func mission_progress(metric: String, goal: int, peak_streak: int, base: int, cur: int) -> int:
	if metric == "streak":
		return mini(peak_streak, goal)
	return clampi(cur - base, 0, goal)
