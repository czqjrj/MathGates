class_name PlayerRules
## A4 第一刀：从 GameData 切出的**纯规则层**——无状态、无 IO、无 autoload 依赖，
## 全部是「给定输入 → 算出结果」的静态函数；存档、通知、音效仍留在 GameData 门面之后。
## 调用方约定：只通过 GameData.xxx() 门面或本类静态函数使用，不要在本类里读写全局状态。
## 每个函数都能被 tests/Tests.gd::_test_player_rules() 用构造数据直接单测。

# ---------------------------------------------------------------- 称号阶梯(按满星比例达成)
## A15：本表已迁到 `data/meta.json` 的 `ranks`，此处保留**空的静态注入位**，
## 由 GameData._load_meta() 在启动时填入（rules 层不自己做 IO）。
## 每项 {title, ratio}；ratio 为「占满星总数的比例」阈值。
static var RANKS: Array = []

static func rank_index(total_stars: int, max_stars: int) -> int:
	if RANKS.is_empty():
		return 0
	var mx := maxi(1, max_stars)
	var idx := 0
	for i in RANKS.size():
		if total_stars >= int(ceil(float(RANKS[i]["ratio"]) * float(mx))):
			idx = i
	return idx

static func rank_title(total_stars: int, max_stars: int) -> String:
	if RANKS.is_empty():
		return ""
	return str(RANKS[rank_index(total_stars, max_stars)]["title"])

## 称号进度：{title, next_title, cur, span, need, ratio}(已满级 next_title 为空)
static func rank_progress(total_stars: int, max_stars: int) -> Dictionary:
	if RANKS.is_empty():
		return { "title": "", "next_title": "", "cur": 0, "span": 1, "need": 0, "ratio": 0.0 }
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
## 勋章定义。A15：本表已迁到 `data/meta.json`，此处保留为**空的静态注入位**，
## 由 GameData._load_meta() 在启动时填入（rules 层不自己做 IO）。
## 每条含**展示字段**（name/desc/symbol/color）与**达成规则**（kind/metric/value 等），
## 两者同源，避免「改了文案却没改阈值」的双份真相。
static var MEDALS: Array = []

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

## 单枚勋章的达成判定。A15 起**数据驱动**：规则来自 `data/meta.json` 的
## `kind` / `metric` / `value`（accuracy 类用 `min_questions` + `ratio`），
## 与 desc 文案同源，避免「改了文案却没改阈值」的双份真相。
## ctx 由调用方(GameData._medal_ctx())一次性汇总：
## { cleared, full_star, total_stars, total_questions, accuracy,
##   coins_earned, pet_fed, boss_total, boss_cleared, chapter_master }
## 未知 id / meta 未加载时返回 false（不抛错，避免内容损坏拖垮存档流程）。
static func medal_met(id: String, ctx: Dictionary) -> bool:
	var m := medal_def(id)
	if m.is_empty():
		return false
	match str(m.get("kind", "")):
		"count":
			return int(ctx.get(str(m.get("metric", "")), 0)) >= int(m.get("value", 0))
		"flag":
			return bool(ctx.get(str(m.get("metric", "")), false))
		"accuracy":
			var enough := int(ctx.get("total_questions", 0)) >= int(m.get("min_questions", 0))
			return enough and float(ctx.get("accuracy", 0.0)) >= float(m.get("ratio", 1.0))
		"boss_all":
			var total := int(ctx.get("boss_total", 0))
			return total > 0 and int(ctx.get("boss_cleared", 0)) >= total
	return false

## A15：meta 是否已装载（UI/测试可用来判断是否走了降级路径）。
static func meta_loaded() -> bool:
	return not RANKS.is_empty() and not MEDALS.is_empty()

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
