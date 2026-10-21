class_name PetRules
## A4 第三刀：从 GameData 切出的**萌宠养成纯规则**——无状态、无 IO、无 autoload 依赖。
## 单一来源：好感度分层、饥饿判定、状态标签、跨会话衰减、投喂效果。
## 调用方约定：只在 GameData 门面后使用；存档、部件解锁仍在 GameData 之后。
## 单测：tests/Tests.gd::_test_pet_rules()（构造数据）；门面行为由既有萌宠 UI 流程回归保护。

# ---------------------------------------------------------------- 阈值
const HUNGRY_AT := 0.35          ## 饱食度低于此值判定「饿」
const AFFECTION_FAMILIAR := 3    ## 投喂次数 → 熟悉
const AFFECTION_CLINGY := 8      ## 投喂次数 → 黏人
const MOOD_HAPPY := 0.75         ## 心情标签分界：开心
const MOOD_OK := 0.45            ## 心情标签分界：一般(以下为低落)
const SATIETY_FULL := 0.7        ## 饱食标签分界：吃饱
const SATIETY_HALF := 0.4        ## 饱食标签分界：半饱(以下为好饿)

# ---------------------------------------------------------------- 衰减 / 投喂
const PET_DECAY_PER_DAY := 0.32   ## 每天饱食度自然下降
const PET_MOOD_BASE := 0.55       ## 心情自然回落基准(长离线向其靠拢)
const MOOD_LERP_DAYS := 1.0       ## 心情回落按离线天数插值的封顶天数
const DECAY_SATIETY_FLOOR := 0.15 ## 衰减饱食度地板(不归零，留投喂余地)
const MOOD_FLOOR := 0.2           ## 心情地板
const FEED_SATIETY := 1.0         ## 投喂直接吃饱
const FEED_MOOD_GAIN := 0.12      ## 投喂心情增量(封顶 1.0)

## 好感度等级：投喂次数决定(0 初识 / 1 熟悉 / 2 黏人)。
static func affection_tier(pet_fed: int) -> int:
	if pet_fed >= AFFECTION_CLINGY:
		return 2
	if pet_fed >= AFFECTION_FAMILIAR:
		return 1
	return 0

## 是否饿了。
static func is_hungry(satiety: float) -> bool:
	return satiety < HUNGRY_AT

## 心情标签：开心 / 一般 / 低落。
static func mood_label(mood: float) -> String:
	if mood >= MOOD_HAPPY:
		return "开心"
	if mood >= MOOD_OK:
		return "一般"
	return "低落"

## 饱食标签：吃饱 / 半饱 / 好饿。
static func satiety_label(satiety: float) -> String:
	if satiety >= SATIETY_FULL:
		return "吃饱"
	if satiety >= SATIETY_HALF:
		return "半饱"
	return "好饿"

## 跨会话衰减(纯)：按离线天数降饱食度、心情向基准回落；away_days<=0 原样返回。
static func decay(satiety: float, mood: float, away_days: float) -> Dictionary:
	if away_days <= 0.0:
		return { "satiety": satiety, "mood": mood }
	return {
		"satiety": clampf(satiety - PET_DECAY_PER_DAY * away_days, DECAY_SATIETY_FLOOR, 1.0),
		"mood": clampf(lerpf(mood, PET_MOOD_BASE, clampf(away_days, 0.0, MOOD_LERP_DAYS)), MOOD_FLOOR, 1.0),
	}

## 投喂后的新心情(纯)：饱食度置满由调用方做；心情 +FEED_MOOD_GAIN 封顶 1.0。
static func feed_mood(mood: float) -> float:
	return minf(1.0, mood + FEED_MOOD_GAIN)
