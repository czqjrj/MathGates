class_name PlayerRules
## A4 第一刀：从 GameData 切出的**纯规则层**——无状态、无 IO、无 autoload 依赖，
## 全部是「给定输入 → 算出结果」的静态函数；存档、通知、音效仍留在 GameData 门面之后。
## 调用方约定：只通过 GameData.xxx() 门面或本类静态函数使用，不要在本类里读写全局状态。
## 每个函数都能被 tests/Tests.gd::_test_player_rules() 用构造数据直接单测。

# ---------------------------------------------------------------- 称号阶梯(按满星比例达成)
const RANKS := [
	{ "title": "窥数者",     "ratio": 0.00 },
	{ "title": "演算者",     "ratio": 0.06 },
	{ "title": "衍算师",     "ratio": 0.15 },
	{ "title": "定理执笔人", "ratio": 0.30 },
	{ "title": "公理谛听者", "ratio": 0.50 },
	{ "title": "衍数尊者",   "ratio": 0.70 },
	{ "title": "衍数阁主",   "ratio": 0.88 },
]

static func rank_index(total_stars: int, max_stars: int) -> int:
	var mx := maxi(1, max_stars)
	var idx := 0
	for i in RANKS.size():
		if total_stars >= int(ceil(float(RANKS[i]["ratio"]) * float(mx))):
			idx = i
	return idx

static func rank_title(total_stars: int, max_stars: int) -> String:
	return str(RANKS[rank_index(total_stars, max_stars)]["title"])

## 称号进度：{title, next_title, cur, span, need, ratio}(已满级 next_title 为空)
static func rank_progress(total_stars: int, max_stars: int) -> Dictionary:
	var s := total_stars
	var mx := maxi(1, max_stars)
	var idx := rank_index(s, mx)
	var prev := int(ceil(float(RANKS[idx]["ratio"]) * float(mx)))
	var has_next := idx < RANKS.size() - 1
	var target := mx if not has_next else int(ceil(float(RANKS[idx + 1]["ratio"]) * float(mx)))
	var span := maxi(1, target - prev)
	var into := clampi(s - prev, 0, span)
	return {
		"title": str(RANKS[idx]["title"]),
		"next_title": str(RANKS[idx + 1]["title"]) if has_next else "",
		"cur": into, "span": span,
		"need": maxi(0, target - s),
		"ratio": float(into) / float(span),
	}

# ---------------------------------------------------------------- 玩家等级(每 STARS_PER_LEVEL 星升 1 级)
const STARS_PER_LEVEL := 8

static func player_level(total_stars: int) -> int:
	return 1 + int(total_stars / float(STARS_PER_LEVEL))

## 等级进度：{level, cur, span, ratio}
static func level_progress(total_stars: int) -> Dictionary:
	var into := total_stars % STARS_PER_LEVEL
	return {
		"level": player_level(total_stars), "cur": into,
		"span": STARS_PER_LEVEL, "ratio": float(into) / float(STARS_PER_LEVEL),
	}

# ---------------------------------------------------------------- 星级统计(遍历课程表结构)
## 单章已获星(按 level_id 累加)
static func chapter_stars(chapter: Dictionary, stars: Dictionary) -> int:
	var total := 0
	for lv in chapter.get("levels", []):
		total += int(stars.get(str(lv["id"]), 0))
	return total

## 单章满星上限(每关 3 星)
static func chapter_max_stars(chapter: Dictionary) -> int:
	return chapter.get("levels", []).size() * 3

## 通关数(≥1 星)
static func cleared_level_count(chapters: Array, stars: Dictionary) -> int:
	var n := 0
	for ch in chapters:
		for lv in ch.get("levels", []):
			if int(stars.get(str(lv["id"]), 0)) >= 1:
				n += 1
	return n

## 满星关卡数(=3 星)
static func full_star_level_count(chapters: Array, stars: Dictionary) -> int:
	var n := 0
	for ch in chapters:
		for lv in ch.get("levels", []):
			if int(stars.get(str(lv["id"]), 0)) >= 3:
				n += 1
	return n

## 隐藏 Boss 关卡 id 列表(以 _boss 结尾)
static func boss_level_ids(chapters: Array) -> Array:
	var arr: Array = []
	for ch in chapters:
		for lv in ch.get("levels", []):
			if str(lv.get("id", "")).ends_with("_boss"):
				arr.append(str(lv["id"]))
	return arr

static func boss_cleared_count(chapters: Array, stars: Dictionary) -> int:
	var n := 0
	for id in boss_level_ids(chapters):
		if int(stars.get(id, 0)) >= 1:
			n += 1
	return n

## 是否存在「已满星且非空」的章节
static func chapter_master_any(chapters: Array, stars: Dictionary) -> bool:
	for ch in chapters:
		if chapter_max_stars(ch) > 0 and chapter_stars(ch, stars) >= chapter_max_stars(ch):
			return true
	return false

# ---------------------------------------------------------------- 勋章 / 成就
## 勋章/成就定义。symbol 为徽章中央字符；达成条件见 medal_met()。
const MEDALS := [
	{ "id": "first_clear",   "name": "初露锋芒", "desc": "首次通关任意关卡",             "symbol": "初", "color": "#5ee6ff" },
	{ "id": "clear_10",      "name": "小有心得", "desc": "通关 10 个关卡",               "symbol": "十", "color": "#5ee6ff" },
	{ "id": "clear_30",      "name": "登堂入室", "desc": "通关 30 个关卡",               "symbol": "堂", "color": "#a878ff" },
	{ "id": "clear_60",      "name": "融会贯通", "desc": "通关 60 个关卡",               "symbol": "贯", "color": "#a878ff" },
	{ "id": "perfect_1",     "name": "一丝不苟", "desc": "首次满星通关",                 "symbol": "满", "color": "#ffd479" },
	{ "id": "perfect_10",    "name": "完美主义", "desc": "满星关卡达到 10 个",           "symbol": "完", "color": "#ffd479" },
	{ "id": "perfect_30",    "name": "精益求精", "desc": "满星关卡达到 30 个",           "symbol": "精", "color": "#f6bd16" },
	{ "id": "chapter_master","name": "章节通解", "desc": "任意章节集满全部星星",         "symbol": "章", "color": "#45C7E5" },
	{ "id": "stars_50",      "name": "星辉初绽", "desc": "累计获得 50 颗星",             "symbol": "星", "color": "#5ee6ff" },
	{ "id": "stars_150",     "name": "星河璀璨", "desc": "累计获得 150 颗星",            "symbol": "河", "color": "#a878ff" },
	{ "id": "stars_300",     "name": "满天星斗", "desc": "累计获得 300 颗星",            "symbol": "斗", "color": "#ffd479" },
	{ "id": "answer_100",    "name": "勤学不辍", "desc": "累计作答 100 题",              "symbol": "勤", "color": "#34d399" },
	{ "id": "answer_500",    "name": "博览群题", "desc": "累计作答 500 题",              "symbol": "博", "color": "#34d399" },
	{ "id": "accuracy_80",   "name": "精准推演", "desc": "作答满 50 题且正确率 ≥ 80%",    "symbol": "准", "color": "#34d399" },
	{ "id": "coins_1000",    "name": "富甲一方", "desc": "金币累计达到 1000",            "symbol": "金", "color": "#ffd479" },
	{ "id": "boss_first",    "name": "破阵者",   "desc": "通关任意隐藏 Boss",            "symbol": "破", "color": "#fb7185" },
	{ "id": "boss_all",      "name": "无冕之王", "desc": "通关全部隐藏 Boss",            "symbol": "王", "color": "#fb7185" },
	{ "id": "pet_3",         "name": "亲密伙伴", "desc": "投喂萌宠 3 次",                "symbol": "友", "color": "#4dd6a8" },
	{ "id": "pet_10",        "name": "形影不离", "desc": "投喂萌宠 10 次",               "symbol": "伴", "color": "#4dd6a8" },
]

static func medal_def(id: String) -> Dictionary:
	for m in MEDALS:
		if str(m["id"]) == id:
			return m
	return {}

## 按 MEDALS 定义顺序返回已解锁勋章(unlocked 为 medal_id -> 解锁时间戳)
static func medals_in_order(unlocked: Dictionary) -> Array:
	var arr: Array = []
	for m in MEDALS:
		if unlocked.has(str(m["id"])):
			arr.append(m)
	return arr

## 单枚勋章的达成判定。ctx 由调用方(GameData._medal_ctx())一次性汇总：
## { cleared, full_star, total_stars, total_questions, accuracy,
##   coins_earned, pet_fed, boss_total, boss_cleared, chapter_master }
static func medal_met(id: String, ctx: Dictionary) -> bool:
	match id:
		"first_clear":    return int(ctx.get("cleared", 0)) >= 1
		"clear_10":       return int(ctx.get("cleared", 0)) >= 10
		"clear_30":       return int(ctx.get("cleared", 0)) >= 30
		"clear_60":       return int(ctx.get("cleared", 0)) >= 60
		"perfect_1":      return int(ctx.get("full_star", 0)) >= 1
		"perfect_10":     return int(ctx.get("full_star", 0)) >= 10
		"perfect_30":     return int(ctx.get("full_star", 0)) >= 30
		"chapter_master": return bool(ctx.get("chapter_master", false))
		"stars_50":       return int(ctx.get("total_stars", 0)) >= 50
		"stars_150":      return int(ctx.get("total_stars", 0)) >= 150
		"stars_300":      return int(ctx.get("total_stars", 0)) >= 300
		"answer_100":     return int(ctx.get("total_questions", 0)) >= 100
		"answer_500":     return int(ctx.get("total_questions", 0)) >= 500
		"accuracy_80":    return int(ctx.get("total_questions", 0)) >= 50 and float(ctx.get("accuracy", 0.0)) >= 0.8
		"coins_1000":     return int(ctx.get("coins_earned", 0)) >= 1000
		"boss_first":     return int(ctx.get("boss_cleared", 0)) >= 1
		"boss_all":
			var total := int(ctx.get("boss_total", 0))
			return total > 0 and int(ctx.get("boss_cleared", 0)) >= total
		"pet_3":          return int(ctx.get("pet_fed", 0)) >= 3
		"pet_10":         return int(ctx.get("pet_fed", 0)) >= 10
	return false

# ---------------------------------------------------------------- 关卡结算防刷公式(C1/C2)
const REPEAT_REWARD_RATE := 0.3        ## 重复通关(未刷新星级)的奖励折扣
const REPEAT_PAID_PER_DAY := 3         ## 同一关每日最多计几次「重复奖励」，之后为 0
const STAR_CAP_ATTEMPTS_PER_DAY := 3   ## 同一关当日第几次尝试起降级星级上限
const STAR_CAP_REPEAT := 2             ## 上述情况下的星级上限

## 本次尝试的星级上限：当日第 STAR_CAP_ATTEMPTS_PER_DAY 次起封顶 STAR_CAP_REPEAT。
static func star_cap(attempts_today: int) -> int:
	return STAR_CAP_REPEAT if attempts_today >= STAR_CAP_ATTEMPTS_PER_DAY else 3

## 重复通关(未刷新星级)的金币：每日前 REPEAT_PAID_PER_DAY 次按 REPEAT_REWARD_RATE 折扣，之后 0。
static func repeat_grant(base_reward: int, paid_today: int) -> int:
	if paid_today >= REPEAT_PAID_PER_DAY:
		return 0
	return int(floor(float(maxi(0, base_reward)) * REPEAT_REWARD_RATE))
