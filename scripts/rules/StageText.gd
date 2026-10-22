class_name StageText
extends RefCounted
## A4：从 StageRules 拆出的**结算文案纯规则**——评级字母与「下一星差在哪」的提示。
## 判定逻辑仍在 StageRules（星级怎么算）；这里只管**怎么写给用户看**。
##
## 约定：无状态、无 IO、无 autoload 依赖；文案不随设置变化。
## 单测：tests/Tests.gd::_test_stage_rules()（与 StageRules 同组）。

## 评级(纯)：三星且全对无陷阱 = S；三星 = A；两星 = B；其余 = C。
static func grade(stars: int, clean: int, total: int, trap_missed: bool) -> String:
	if stars >= 3 and clean == total and not trap_missed:
		return "S"
	if stars >= 3:
		return "A"
	if stars == 2:
		return "B"
	return "C"

## P2 · 三星条件显式化：结算给出「下一星差在哪」的引导文案(无需引导时返回空串)。
## 纯函数——由 StageBase 传入当前局面，文案在此单点维护。
static func next_star_hint(stars: int, clean: int, total: int, trap_missed: bool,
		boss_failed: bool, time_capped: bool, time_limit: float) -> String:
	if boss_failed:
		return "推演能量归零 · 补齐一次完整推演即可重新挑战"
	var msg := ""
	if stars <= 0:
		var need2 := int(ceil(0.6 * float(total)))
		msg = "零失误 %d / %d 轮即可拿到 2 星（当前 %d）" % [need2, total, clean]
	elif stars == 2:
		var need3 := int(ceil(0.8 * float(total)))
		var lack := maxi(0, need3 - clean)
		if lack > 0:
			msg = "再 %d 轮零失误即可升到 3 星（需 %d / %d）" % [lack, need3, total]
	elif trap_missed:
		msg = "不踩陷阱即可拿到 S 评级"
	elif clean < total:
		msg = "全程 %d 轮零失误可拿 S 评级" % total
	if time_capped:
		var t := "超时降星：用时压到 %.0f 秒内可升回" % time_limit
		msg = t if msg == "" else msg + "  ·  " + t
	return msg
