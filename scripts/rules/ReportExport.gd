class_name ReportExport
## G3：学习报告的**输出层**（纯规则）——文本周报 / 家长建议 / CSV / JSON 序列化。
## 只做序列化：不读 autoload、不碰磁盘、不联网（落盘与分享由 UI 层负责）。
##
## 约定：
## - 导出内容只含日期与计数，**不含题目原文 / 关卡名 / 作答内容**（隐私最小化）；
## - 文本报告末尾固定标注「本地生成，不联网、不上传」。
##
## 单测：tests/Tests.gd::_test_report_rules()

## 家长视角建议文案。
static func parent_advice(view: Dictionary) -> String:
	if int(view.get("answered", 0)) <= 0:
		return "本期暂无学习记录。"
	var titles: Array = view.get("weak_titles", [])
	if titles.is_empty():
		return "本期状态稳定，可适当提高练习强度。"
	var names := ""
	for t in titles:
		names += ("、" if names != "" else "") + str(t)
	return "建议关注：%s（共 %d 个薄弱领域）。" % [names, titles.size()]

## 可分享的文本周报 / 月报（不含题目原文）。
static func report_text(summary: Dictionary, weak: Array) -> String:
	var days := int(summary.get("days", 7))
	var title := "周报" if days <= 7 else "月报"
	var lines := "【衍数阁 · 学习%s】%s ~ %s\n" % [
		title, str(summary.get("from", "")), str(summary.get("to", ""))]
	lines += "作答 %d 题 · 正确率 %d%% · 活跃 %d 天 · 新增 ★%d · 复习 %d 题\n" % [
		int(summary.get("answered", 0)),
		int(round(float(summary.get("accuracy", 0.0)) * 100.0)),
		int(summary.get("active_days", 0)),
		int(summary.get("stars", 0)),
		int(summary.get("reviews", 0)),
	]
	var weak_names := ""
	for w in weak:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = w
		weak_names += ("、" if weak_names != "" else "") + "%s(%d%%)" % [
			str(item.get("title", "")), int(item.get("mastery", 0))]
	lines += "薄弱领域：%s\n" % (weak_names if weak_names != "" else "暂无")
	lines += "—— 本报告在本地生成，不联网、不上传。"
	return lines

## 导出 CSV（逐日明细，表头固定）。
static func report_csv(summary: Dictionary) -> String:
	var out := "date,answered,correct,stars,clears,reviews\n"
	for row in summary.get("daily", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var r: Dictionary = row
		out += "%s,%d,%d,%d,%d,%d\n" % [
			str(r.get("date", "")), int(r.get("answered", 0)), int(r.get("correct", 0)),
			int(r.get("stars", 0)), int(r.get("clears", 0)), int(r.get("reviews", 0))]
	return out

## 导出 JSON（结构化，可外部查看）。
static func report_json(summary: Dictionary) -> String:
	return JSON.stringify(summary, "  ")
