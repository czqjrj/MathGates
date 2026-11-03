## B6 · 错因标签规则（纯函数、无 IO）。
##
## 用法：ContentRules.validate_err_reason(reason) -> bool
##       ContentRules.infer_err_reason(q_data, wrong_answer) -> String
##
## 作用：
##   1. 校验 err_reason 是否在白名单内
##   2. 根据题目数据和错答案自动推断错因
##   3. 提供错因聚合统计辅助函数

# === 错因标签白名单 ===
const ERR_REASON_WHITELIST: Array[String] = [
	"",              # 空串 = 尚未标注
	"concept",       # 概念混淆
	"calc",          # 计算失误
	"formula",       # 公式遗忘
	"read",          # 审题疏忽
	"method",        # 方法不当
	"logic",         # 逻辑漏洞
	"time",          # 时间不足
	"guess",         # 蒙对后暴露
	"careless",      # 粗心（未细分）
]

const CORE_ERR_REASONS: Array[String] = ["", "concept", "calc", "formula", "read", "method", "logic", "time"]

const ERR_REASON_LABELS: Dictionary = {
	"": "待标注", "concept": "概念混淆", "calc": "计算失误", "formula": "公式遗忘",
	"read": "审题疏忽", "method": "方法不当", "logic": "逻辑漏洞", "time": "时间不足",
	"guess": "蒙对后暴露", "careless": "粗心",
}


## 校验 err_reason 是否合法
static func validate_err_reason(reason: Variant) -> bool:
	if reason == null: return true
	var r := str(reason).strip_edges()
	return r.is_empty() or r.begins_with("ext:") or ERR_REASON_WHITELIST.has(r)


## 批量校验错因列表
static func validate_err_reasons(reasons: Array) -> Array[String]:
	var invalid: Array[String] = []
	for r in reasons:
		if not validate_err_reason(r):
			invalid.append(str(r))
	return invalid


## 按错因分组错题记录
static func group_by_reason(wrong_records: Array) -> Dictionary:
	var groups: Dictionary = {}
	for rec in wrong_records:
		if typeof(rec) != TYPE_DICTIONARY: continue
		var reason: String = str(rec.get("err_reason", ""))
		if not groups.has(reason): groups[reason] = []
		groups[reason].append(rec)
	return groups


## 计算错因分布统计
static func reason_stats(wrong_records: Array) -> Dictionary:
	var groups := group_by_reason(wrong_records)
	var total := 0
	var by_reason := {}
	var top_reason := ""
	var top_count := 0
	for reason in groups.keys():
		var count: int = groups[reason].size()
		total += count
		by_reason[reason] = count
		if count > top_count:
			top_count = count
			top_reason = reason
	return {"total": total, "by_reason": by_reason, "top_reason": top_reason, "top_reason_count": top_count}


## 获取错因中文标签
static func get_reason_label(reason: String) -> String:
	if ERR_REASON_LABELS.has(reason): return str(ERR_REASON_LABELS[reason])
	if reason.begins_with("ext:"): return "自定义：%s" % reason.substr(4)
	return reason


## 获取所有核心错因及其中文名
static func get_core_reasons() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in CORE_ERR_REASONS:
		out.append({"id": r, "label": get_reason_label(r)})
	return out
