extends Control
## 学习报告 / 家长视图（G3）：周报·月报、逐日趋势、薄弱领域、家长只读摘要与本地导出。
##
## 隐私约定（与 F1 一致）：
## - 家长视图只给**汇总量与领域级**薄弱点，**不含题目原文 / 关卡名 / 作答内容**；
## - 报告在本地生成，导出走本地文件，**不联网、不上传**。

var _days: int = 7
var _summary: Dictionary = {}
var _wk_btn: Button
var _mo_btn: Button

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build_topbar()
	_rebuild()
	GameData.progress_changed.connect(_rebuild)

# ---------------------------------------------------------------- 顶栏
func _build_topbar() -> void:
	var hb := UI.screen_topbar(self, "学习报告", "LEARNING REPORT", "res://scenes/MainHub.tscn")
	_wk_btn = UI.ghost_button("本周", func() -> void: _set_days(7), 14)
	hb.add_child(_wk_btn)
	_mo_btn = UI.ghost_button("本月", func() -> void: _set_days(30), 14)
	hb.add_child(_mo_btn)
	hb.add_child(UI.mono_label("本地生成 · 不联网", 13, UI.COL_TEXT_DIM))

func _set_days(d: int) -> void:
	_days = d
	Sound.play("select")
	_rebuild()

# ---------------------------------------------------------------- 主体
func _rebuild() -> void:
	for c in get_children():
		if c is ScrollContainer:
			c.queue_free()
	_summary = GameData.report_summary(_days)
	if _wk_btn != null and is_instance_valid(_wk_btn):
		_wk_btn.text = "本周 ✓" if _days == 7 else "本周"
	if _mo_btn != null and is_instance_valid(_mo_btn):
		_mo_btn.text = "本月 ✓" if _days == 30 else "本月"

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 74
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	UI.enable_touch_scroll(scroll)
	UI.style_scrollbar(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	center.add_child(vb)

	vb.add_child(_summary_card())
	vb.add_child(_trend_card())
	vb.add_child(_weak_card())
	vb.add_child(_report_text_card())
	vb.add_child(_parent_card())
	vb.add_child(_export_card())

	vb.add_child(UI.gap(20))
	UI.stagger_in(vb, 0.035, 0.24, 10)

## 概览卡：本期核心指标
func _summary_card() -> Control:
	var s := _summary
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.3), 14, 22, Color(UI.COL_ACCENT, 0.2))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("学习概览", 20, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.mono_label("%s ~ %s" % [str(s.get("from", "")), str(s.get("to", ""))], 13, UI.COL_TEXT_DIM))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	box.add_child(stats)
	stats.add_child(UI.stat_box("作答", "%d 题" % int(s.get("answered", 0))))
	stats.add_child(UI.stat_box("正确率", "%d%%" % int(round(float(s.get("accuracy", 0.0)) * 100.0))))
	stats.add_child(UI.stat_box("活跃", "%d 天" % int(s.get("active_days", 0))))
	stats.add_child(UI.stat_box("新增星", "★%d" % int(s.get("stars", 0))))
	stats.add_child(UI.stat_box("通关", "%d 关" % int(s.get("clears", 0))))
	stats.add_child(UI.stat_box("复习", "%d 题" % int(s.get("reviews", 0))))
	return card

## 趋势卡：逐日作答量柱状（空档也画出来——沉默的日子同样是有用信息）
func _trend_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#5b8cff", 0.3), 14, 22, Color("#5b8cff", 0.18))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("逐日趋势 · 作答量", 20, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var daily: Array = _summary.get("daily", [])
	var peak := 0
	for row in daily:
		peak = maxi(peak, int((row as Dictionary).get("answered", 0)))
	head.add_child(UI.mono_label("峰值 %d 题/天" % peak, 13, UI.COL_ACCENT))
	var chart := HBoxContainer.new()
	chart.add_theme_constant_override("separation", 4)
	chart.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(chart)
	var step := 1 if daily.size() <= 8 else 5
	for i in daily.size():
		chart.add_child(_trend_bar(daily[i], peak, i, step, daily.size()))
	return card

func _trend_bar(row: Variant, peak: int, idx: int, step: int, total: int) -> Control:
	var r: Dictionary = row
	var v := int(r.get("answered", 0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bar := ColorRect.new()
	bar.color = UI.COL_ACCENT if v > 0 else Color(1, 1, 1, 0.08)
	bar.custom_minimum_size = Vector2(0, 6 + int(54.0 * float(v) / float(maxi(1, peak))))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(bar)
	var lbl := UI.mono_label("", 10, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	if idx % step == 0 or idx == total - 1:
		lbl.text = str(r.get("date", "")).substr(5)
	col.add_child(lbl)
	return col

## 薄弱领域卡：领域级（不含关卡名与题目原文）
func _weak_card() -> Control:
	var weak := GameData.report_weak(3)
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#fb7185", 0.3), 14, 22, Color("#fb7185", 0.18))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("薄弱领域", 20, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.mono_label("按掌握度与错次排序", 13, UI.COL_TEXT_DIM))
	if weak.is_empty():
		box.add_child(UI.make_label("目前没有明显薄弱领域，保持这个状态！", 15, UI.COL_SUCCESS))
		return card
	for w in weak:
		var item: Dictionary = w
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		box.add_child(row)
		var hr := HBoxContainer.new()
		hr.add_theme_constant_override("separation", 10)
		row.add_child(hr)
		hr.add_child(UI.make_label(str(item.get("title", "")), 15, UI.COL_TEXT))
		var sp2 := Control.new()
		sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hr.add_child(sp2)
		hr.add_child(UI.mono_label("掌握 %d%% · 错 %d" % [int(item.get("mastery", 0)), int(item.get("wrong", 0))], 13, Color("#fb7185")))
		var bar := ProgressLine.new()
		bar.col = Color("#fb7185")
		bar.glow = false
		bar.custom_minimum_size = Vector2(0, 6)
		bar.set_ratio(float(item.get("mastery", 0)) / 100.0, false)
		row.add_child(bar)
	return card

## 报告文本卡：可分享的周报/月报（纯文本，不含题目原文）
func _report_text_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#4dd6a8", 0.3), 14, 22, Color("#4dd6a8", 0.18))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("可分享的报告文本", 20, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.ghost_button("复制到剪贴板", func() -> void:
		Sound.play("select")
		_copy_text(GameData.report_text(_days))
	, 14))
	var txt := UI.make_label(GameData.report_text(_days), 14, UI.COL_TEXT)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(txt)
	return card

## 家长视图卡：只读摘要（不含题目原文；本地生成不联网）
func _parent_card() -> Control:
	var pv := GameData.parent_view(_days)
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#a878ff", 0.3), 14, 22, Color("#a878ff", 0.18))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("家长视图 · 只读摘要", 20, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.mono_label("%s ~ %s" % [str(pv.get("from", "")), str(pv.get("to", ""))], 13, UI.COL_TEXT_DIM))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	box.add_child(stats)
	stats.add_child(UI.stat_box("学习量", "%d 题" % int(pv.get("answered", 0))))
	stats.add_child(UI.stat_box("正确率", "%d%%" % int(pv.get("accuracy", 0))))
	stats.add_child(UI.stat_box("活跃天数", "%d 天" % int(pv.get("active_days", 0))))
	stats.add_child(UI.stat_box("新增星", "★%d" % int(pv.get("stars", 0))))
	box.add_child(UI.make_label(GameData.parent_advice(_days), 15, UI.COL_TEXT))
	var weak_titles: Array = pv.get("weak_titles", [])
	if not weak_titles.is_empty():
		var names := ""
		for t in weak_titles:
			names += ("、" if names != "" else "") + str(t)
		box.add_child(UI.make_label("需关注领域：%s" % names, 14, Color("#fb7185")))
	box.add_child(UI.make_label("隐私说明：%s" % str(pv.get("note", "")), 12, UI.COL_TEXT_DIM))
	return card

## 导出卡：结构化数据（JSON / CSV）落到本地文件，可外部查看
func _export_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#ffd479", 0.3), 14, 22, Color("#ffd479", 0.18))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("导出数据", 20, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.mono_label("本地文件 · 不上传", 13, UI.COL_TEXT_DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	row.add_child(UI.ghost_button("导出 CSV", func() -> void:
		Sound.play("select")
		_export("csv", GameData.report_csv(_days))
	, 14))
	row.add_child(UI.ghost_button("导出 JSON", func() -> void:
		Sound.play("select")
		_export("json", GameData.report_json(_days))
	, 14))
	row.add_child(UI.ghost_button("导出文本", func() -> void:
		Sound.play("select")
		_export("txt", GameData.report_text(_days))
	, 14))
	box.add_child(UI.make_label("导出的 CSV / JSON 只含日期与计数，不含题目原文；文件写在应用私有目录。", 12, UI.COL_TEXT_DIM))
	return card

# ---------------------------------------------------------------- 工具
func _export(ext: String, text: String) -> void:
	var path := "user://learning_report_%d.%s" % [_days, ext]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		Toast.show_toast("导出失败：无法写入文件")
		return
	f.store_string(text)
	f.close()
	Toast.show_toast("已导出 · %s" % ProjectSettings.globalize_path(path))

func _copy_text(text: String) -> void:
	DisplayServer.clipboard_set(text)
	Toast.show_toast("报告文本已复制到剪贴板")
