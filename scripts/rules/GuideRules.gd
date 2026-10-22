class_name GuideRules
extends RefCounted
## F6：首次引导与机制说明（纯规则，无 IO、不碰 autoload）。
##
## 本文件只负责「有哪些引导、每条引导讲什么、什么时候该显示」；
## 真正的绘制在 `scripts/ui/GuideOverlay.gd`，是否已看过由 `Settings.seen_guides` 记录。
##
## 约定：
## - 引导是**表意内容**：不随「界面动效」总开关关闭（与 D4 的语义一致，见
##   `Settings.animations` / `UI.fx_on()`——引导只弱化入场动画，文字本身照常显示）；
## - 每条引导有稳定 `id`（字符串），看过即写进 `seen_guides`；新增引导用新 id 即可；
## - 步骤/图例都是纯数据，可单测（不依赖任何场景）。
##
## 单测：tests/Tests.gd::_test_guide_rules()

## 第一关的机制引导（3~4 步气泡，按顺序给）。
## 每步：title（标题）+ body（说人话的解释）+ anchor（在关卡界面里指向哪块区域，UI 层用）。
const FIRST_LEVEL_STEPS := [
	{
		"id": "drag",
		"title": "① 先动手调一调",
		"body": "拖动滑块 / 直接拖图上的点，把图调到题目要求的样子。改了参数图上会立刻重画。",
		"anchor": "view",
	},
	{
		"id": "submit",
		"title": "② 提交你的答案",
		"body": "选择选项，或在输入框里填答案后按「提交」。答错不要紧，可以再试。",
		"anchor": "panel",
	},
	{
		"id": "explain",
		"title": "③ 看解析，弄懂为止",
		"body": "答完会给出解析。答错时点「提示」会扣一点评分，但能把思路补上。",
		"anchor": "action",
	},
	{
		"id": "stars",
		"title": "④ 三星怎么拿",
		"body": "一次答对的题越多、越少用提示，结算星级越高：全对且无提示＝三星，错一点＝两星，通关＝一星。",
		"anchor": "victory",
	},
]

## 地图页图例（Boss 门 / 宝箱 / 随机事件 / 支线）——条目数据，UI 层照此渲染。
const MAP_LEGEND := [
	{
		"id": "boss_gate",
		"title": "Boss 门",
		"body": "标着「★ 已有/需要」的关卡是 Boss 门，攒够本单元的星数才会解锁。",
		"color": "#ffd479",
	},
	{
		"id": "chest",
		"title": "宝箱",
		"body": "节点右下角的宝箱：本单元星数达到门槛后可开启，领金币与提示卡。",
		"color": "#ffd479",
	},
	{
		"id": "event",
		"title": "随机事件",
		"body": "节点左上角的菱形：通关后触发一次，给一份小奖励，只触发一次。",
		"color": "#5ee6ff",
	},
	{
		"id": "optional",
		"title": "支线探索",
		"body": "标着「支线」的节点是选做路线，不影响主线通关，但能多拿星与奖励。",
		"color": "#c4b5fd",
	},
]

## 引导 id 一览（写入 seen_guides 的键）。
const ID_FIRST_LEVEL := "first_level"
const ID_MAP_LEGEND := "map_legend"

## 全部引导 id（「重置引导」清空这些键）。
static func all_ids() -> Array:
	return [ID_FIRST_LEVEL, ID_MAP_LEGEND]

## 是否还没看过某条引导。seen：Settings.seen_guides（id -> true）。
static func should_show(id: String, seen: Dictionary) -> bool:
	if id == "":
		return false
	return not bool(seen.get(id, false))

## 第一关引导步骤（返回副本，调用方可安全改）。
static func first_level_steps() -> Array:
	return FIRST_LEVEL_STEPS.duplicate(true)

## 地图图例条目（返回副本）。
static func map_legend() -> Array:
	return MAP_LEGEND.duplicate(true)

## 图例条目正文（给「? 帮助」复看时拼成一段文字）。
static func legend_text() -> String:
	var lines: Array = []
	for e in MAP_LEGEND:
		lines.append("【%s】%s" % [str(e["title"]), str(e["body"])])
	return "\n".join(lines)

## 第一关引导正文（给「? 帮助」复看时拼成一段文字）。
static func first_level_text() -> String:
	var lines: Array = []
	for s in FIRST_LEVEL_STEPS:
		lines.append("%s  %s" % [str(s["title"]), str(s["body"])])
	return "\n\n".join(lines)

## 「重置引导」：返回一份清空所有引导记录的新字典。
## 只清引导键，不动其它设置（由调用方在 Settings 上落地）。
static func reset(seen: Dictionary) -> Dictionary:
	var out := seen.duplicate(true)
	for id in all_ids():
		out.erase(id)
	return out

## 标记某条引导为「看过了」，返回新字典（不就地改入参）。
static func mark_seen(seen: Dictionary, id: String) -> Dictionary:
	var out := seen.duplicate(true)
	if id != "":
		out[id] = true
	return out
