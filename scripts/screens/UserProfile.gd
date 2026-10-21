extends Control
## 档案库 · 用户系统：展示当前进度、出错位置(错题本)、重点(按错误次数排序的知识点)。

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build_topbar()
	_build_body()
	var pet := Pet.spawn(self, "看看你的出错位置和重点吧～")
	pet.tap_provider = _pet_comment
	GameData.progress_changed.connect(_build_body)

func _pet_comment() -> String:
	var kp := GameData.key_points()
	if kp.is_empty():
		return "暂时没有薄弱点，继续保持！"
	var top: Dictionary = kp[0]
	var info := GameData.level_info(str(top["level_id"]))
	return "重点：「%s · %s」累计错 %d 次，建议先重练它！" % [str(info.get("chapter", "")), str(info.get("name", "")), int(top["count"])]

func _build_topbar() -> void:
	var hb := UI.screen_topbar(self, "档案库", "USER PROFILE", "res://scenes/MainHub.tscn")
	hb.add_child(UI.mono_label("★ %d / %d" % [GameData.total_stars(), GameData.total_max_stars()], 17, UI.COL_ACCENT))

func _build_body() -> void:
	for c in get_children():
		if c is ScrollContainer:
			c.queue_free()
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

	# ---- 概览 ----
	var overview := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.3), 14, 22, Color(UI.COL_ACCENT, 0.2))
	overview.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	vb.add_child(overview)
	var ovb := VBoxContainer.new()
	ovb.add_theme_constant_override("separation", 12)
	overview.add_child(ovb)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	ovb.add_child(head)
	head.add_child(UI.make_label(GameData.rank_title(), 26, UI.COL_TEXT))
	head.add_child(UI.mono_label("Lv.%d" % GameData.player_level(), 16, UI.COL_TEXT_DIM))
	head.add_child(UI.mono_label("◆ %d" % GameData.coins, 16, Color("#ffd479")))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	var done_levels := 0
	for ch in GameData.chapters:
		for lv in ch.get("levels", []):
			if int(GameData.stars.get(lv["id"], 0)) >= 1:
				done_levels += 1
	var acc := int(round(GameData.accuracy() * 100.0))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	ovb.add_child(stats)
	stats.add_child(UI.stat_box("已通关卡", "%d" % done_levels))
	stats.add_child(UI.stat_box("累计作答", "%d" % GameData.total_questions))
	stats.add_child(UI.stat_box("累计答对", "%d" % GameData.total_correct))
	stats.add_child(UI.stat_box("正确率", "%d%%" % acc))
	stats.add_child(UI.stat_box("总星数", "%d" % GameData.total_stars()))
	stats.add_child(UI.stat_box("投喂萌宠", "%d" % GameData.pet_fed))
	var tier_name: String = ["初识", "熟悉", "黏人"][clampi(GameData.pet_affection_tier(), 0, 2)]
	stats.add_child(UI.stat_box("好感度", tier_name))

	# ---- 进阶 · 等级与称号 ----
	vb.add_child(_advance_card())

	# ---- 学习报告 / 家长视图(G3) ----
	vb.add_child(_report_card())

	# ---- 学情诊断 · 萌宠分析 ----
	vb.add_child(_diagnosis_card())

	# ---- 知识掌握 · 萌宠进化 ----
	vb.add_child(_mastery_card())

	# ---- 记忆档案 · 馆灵碑文 ----
	vb.add_child(_lore_card())

	# ---- 成就 · 勋章(明细收敛到「成就馆」页) ----
	vb.add_child(_achievements_summary_card())

	# ---- 错题与重点(明细统一收敛到「错题笔记」页) ----
	vb.add_child(_wrong_summary_card())

	vb.add_child(UI.gap(20))
	UI.stagger_in(vb, 0.035, 0.24, 10)

## 学习报告入口（G3）：周报/月报、逐日趋势、家长只读摘要与本地导出。
func _report_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#5b8cff", 0.3), 14, 22, Color("#5b8cff", 0.18))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("学习报告 · 家长视图", 20, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.ghost_button("打开学习报告", func() -> void:
		Sound.play("select")
		Scene.goto("res://scenes/LearningReport.tscn")
	, 14))
	var s := GameData.report_summary(7)
	box.add_child(UI.make_label("本周作答 %d 题 · 正确率 %d%% · 活跃 %d 天 · 新增 ★%d" % [
		int(s.get("answered", 0)),
		int(round(float(s.get("accuracy", 0.0)) * 100.0)),
		int(s.get("active_days", 0)),
		int(s.get("stars", 0)),
	], 14, UI.COL_TEXT_DIM))
	box.add_child(UI.make_label("报告在本地生成、不联网；家长视图只含汇总量，不含题目原文。", 12, UI.COL_TEXT_DIM))
	return card

## 进阶卡片：推演等级 + 称号进度(两条进度条)
func _advance_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#a878ff", 0.3), 14, 22, Color("#a878ff", 0.18))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 46)
	box.add_child(row)

	var lvl := GameData.level_progress()
	var lvbox := VBoxContainer.new()
	lvbox.custom_minimum_size = Vector2(400, 0)
	lvbox.add_theme_constant_override("separation", 6)
	row.add_child(lvbox)
	var lvhead := HBoxContainer.new()
	lvhead.add_theme_constant_override("separation", 10)
	lvbox.add_child(lvhead)
	lvhead.add_child(UI.make_label("推演等级", 16, UI.COL_TEXT_DIM))
	lvhead.add_child(UI.mono_label("Lv.%d" % int(lvl["level"]), 18, UI.COL_ACCENT))
	var lbar := ProgressLine.new()
	lbar.col = UI.COL_ACCENT
	lbar.glow = true
	lbar.set_ratio(float(lvl["ratio"]), false)
	lvbox.add_child(lbar)
	lvbox.add_child(UI.mono_label("%d / %d 星 升至 Lv.%d" % [int(lvl["cur"]), int(lvl["span"]), int(lvl["level"]) + 1], 12, UI.COL_TEXT_DIM))

	var rp := GameData.rank_progress()
	var rkbox := VBoxContainer.new()
	rkbox.custom_minimum_size = Vector2(400, 0)
	rkbox.add_theme_constant_override("separation", 6)
	row.add_child(rkbox)
	rkbox.add_child(UI.make_label(GameData.rank_title(), 20, UI.COL_TEXT))
	var rbar := ProgressLine.new()
	rbar.col = Color("#a878ff")
	rbar.glow = true
	rbar.set_ratio(float(rp["ratio"]), false)
	rkbox.add_child(rbar)
	var rt := ("已达顶阶 · %s" % GameData.rank_title()) if str(rp["next_title"]) == "" else ("距「%s」还需 %d★" % [str(rp["next_title"]), int(rp["need"])])
	rkbox.add_child(UI.mono_label(rt, 12, UI.COL_TEXT_DIM))
	return card

## 知识掌握卡片：各领域掌握度进度条 + 当前萌宠形态
func _mastery_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.3), 14, 22, Color(UI.COL_ACCENT, 0.18))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	head.add_child(UI.make_label("知识掌握 · 萌宠进化", 20, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label("形态 · %s  (%d/%d)" % [GameData.pet_form_name(), GameData.pet_part_count(), GameData.DOMAINS.size()], 14, UI.COL_ACCENT))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 22)
	box.add_child(stats)
	var tier := clampi(GameData.pet_affection_tier(), 0, 2)
	var aff: String = ["初识", "熟悉", "黏人"][tier]
	stats.add_child(UI.mono_label("好感 %s · %s" % ["♥".repeat(tier + 1) + "♡".repeat(2 - tier), aff], 14, Color("#ff7ab8")))
	stats.add_child(UI.mono_label("饱食 %s" % GameData.pet_satiety_label(), 14, Color("#ffd479")))
	stats.add_child(UI.mono_label("心情 %s" % GameData.pet_mood_label(), 14, UI.COL_ACCENT))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	for d in GameData.domain_entries():
		grid.add_child(_domain_row(d))
	return card

func _domain_row(d: Dictionary) -> Control:
	var id := str(d["id"])
	var m := GameData.domain_mastery(id)
	var unlocked := GameData.pet_part_unlocked(id)
	var col := Color(str(d["color"]))
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(414, 0)
	row.add_theme_constant_override("separation", 4)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	row.add_child(head)
	var dot := ColorRect.new()
	dot.color = col if unlocked else Color(1, 1, 1, 0.12)
	dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(dot)
	head.add_child(UI.make_label(str(d["title"]), 15, UI.COL_TEXT if unlocked else UI.COL_TEXT_DIM))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var tag := "已解锁"
	if not unlocked:
		tag = "%d%%" % int(round(m * 100.0))
	elif m < MasteryRules.MASTERY_STALE:
		tag = "已解锁 · 生疏"
	head.add_child(UI.mono_label(tag, 13, col if unlocked else UI.COL_TEXT_DIM))
	var bar := ProgressLine.new()
	bar.col = col
	bar.glow = unlocked
	bar.custom_minimum_size = Vector2(414, 6)
	bar.set_ratio(m, false)
	row.add_child(bar)
	return row

## 学情诊断：薄弱领域排序 + 建议关卡一键直达 + 优势面
func _diagnosis_card() -> Control:
	var diag := GameData.diagnose()
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#34d399", 0.3), 14, 22, Color("#34d399", 0.16))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	head.add_child(UI.make_label("学情诊断 · 萌宠分析", 20, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label(GameData.pet_form_name(), 14, UI.COL_ACCENT))
	box.add_child(UI.make_label(GameData.diagnosis_line(), 14, UI.COL_TEXT_DIM))

	var rec := GameData.recommended_level()
	if not rec.is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		row.add_child(UI.mono_label("建议先练", 13, UI.COL_ACCENT))
		var chap := str((rec.get("domain", {}) as Dictionary).get("title", ""))
		row.add_child(UI.make_label("%s · %s" % [chap, str(rec.get("level_name", ""))], 16, UI.COL_TEXT))
		row.add_child(UI.ghost_button("去复习", func() -> void:
			GameData.start_level(int(rec["ci"]), int(rec["li"]))
			Scene.goto(str(rec["scene"]))
		, 14))
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)

	var weak: Array = diag["weak"]
	if not diag["ready"]:
		box.add_child(UI.make_label("尚未开始推演 —— 先挑一关试试，我会据此给出诊断。", 14, UI.COL_TEXT_DIM))
	elif weak.is_empty():
		box.add_child(UI.make_label("目前没有明显薄弱领域，保持这个状态！", 14, UI.COL_SUCCESS))
	else:
		for w in weak.slice(0, 3):
			box.add_child(_diag_row(w))
	var strong: Array = diag["strong"]
	if not strong.is_empty():
		var names := ""
		for s in strong.slice(0, 4):
			names += ("、" if names != "" else "") + str(s["domain"]["title"])
		box.add_child(UI.make_label("优势领域：%s" % names, 13, UI.COL_SUCCESS))
	return card

func _diag_row(w: Dictionary) -> Control:
	var d: Dictionary = w["domain"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var dot := ColorRect.new()
	dot.color = Color(str(d.get("color", "#5ee6ff")))
	dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dot)
	row.add_child(UI.make_label(str(d["title"]), 15, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	row.add_child(UI.mono_label("掌握 %d%% · 错 %d" % [int(round(float(w["mastery"]) * 100.0)), int(w["wrong_count"])], 13, Color("#fb7185")))
	return row

## 馆灵记忆档案：寻回的碑文与尚未寻回的裂隙
func _lore_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#5ee6ff", 0.3), 14, 22, Color("#5ee6ff", 0.16))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	head.add_child(UI.make_label("馆灵记忆 · 失序碑文", 20, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label("记忆恢复 %d%%" % int(round(GameData.memory_ratio() * 100.0)), 14, UI.COL_ACCENT))
	box.add_child(UI.make_label("解析失序，碑文四散。每掌握一个领域，馆灵便替你拾回一段记忆。", 13, UI.COL_TEXT_DIM))
	for l in GameData.lore_entries():
		box.add_child(_lore_row(l))
	return card

func _lore_row(l: Dictionary) -> Control:
	var id := str(l["id"])
	var got := GameData.lore_unlocked(id)
	var dom := GameData.domain_def(id)
	var col := Color(str(dom.get("color", "#5ee6ff")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var mark := ColorRect.new()
	mark.color = col if got else Color(1, 1, 1, 0.10)
	mark.custom_minimum_size = Vector2(4, 34)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mark)
	var col_box := VBoxContainer.new()
	col_box.add_theme_constant_override("separation", 1)
	col_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col_box)
	col_box.add_child(UI.make_label(str(l["title"]), 15, UI.COL_TEXT if got else UI.COL_TEXT_DIM))
	var text := str(l["text"])
	if not got:
		text = "『 尚未寻回 · 掌握「%s」领域后显现 』" % str(dom.get("title", ""))
	col_box.add_child(UI.make_label(text, 13, UI.COL_TEXT if got else Color(UI.COL_TEXT_DIM, 0.7)))
	return row

## 成就摘要：只给进度与入口，勋章图鉴统一收敛到「成就馆」页。
func _achievements_summary_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#a878ff", 0.35), 14, 22, Color("#a878ff", 0.2))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("成就 · 勋章", 22, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label("%d / %d" % [GameData.medal_count(), PlayerRules.MEDALS.size()], 15, Color("#a878ff")))
	head.add_child(UI.ghost_button("打开成就馆", func() -> void:
		Sound.play("select")
		Scene.goto("res://scenes/Achievements.tscn")
	, 14))
	var total := maxi(1, PlayerRules.MEDALS.size())
	var bar := ProgressLine.new()
	bar.col = Color("#a878ff")
	bar.glow = GameData.medal_count() > 0
	bar.set_ratio(float(GameData.medal_count()) / float(total), false)
	box.add_child(bar)
	var un := GameData.unlocked_medals()
	if un.is_empty():
		box.add_child(UI.make_label("尚未点亮勋章，去闯关摘取第一枚吧！", 14, UI.COL_TEXT_DIM))
	else:
		var names := ""
		for m in un.slice(maxi(0, un.size() - 3)):
			names += ("、" if names != "" else "") + str(m["name"])
		box.add_child(UI.make_label("最近解锁：%s" % names, 14, Color("#ffd479")))
	return card

## 错题与重点摘要：只给概览与入口，逐题/按关卡的明细统一收敛到「错题笔记」页。
func _wrong_summary_card() -> Control:
	var wl := GameData.wrong_list()
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#fb7185", 0.35), 14, 22, Color("#fb7185", 0.2))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("错题与重点", 22, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.ghost_button("打开错题笔记", func() -> void:
		Sound.play("select")
		Scene.goto("res://scenes/WrongNotebook.tscn")
	, 14))
	if wl.is_empty():
		box.add_child(UI.make_label("暂无错题记录，保持这个状态！", 15, UI.COL_SUCCESS))
		return card
	var total := 0
	var levels := {}
	for rec in wl:
		total += int(rec.get("count", 0))
		levels[str(rec["level_id"])] = true
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	box.add_child(stats)
	stats.add_child(UI.stat_box("错题题数", "%d" % wl.size()))
	stats.add_child(UI.stat_box("累计错次", "%d" % total))
	stats.add_child(UI.stat_box("涉及关卡", "%d" % levels.size()))
	var kp := GameData.key_points()
	if not kp.is_empty():
		var top: Dictionary = kp[0]
		var info := GameData.level_info(str(top["level_id"]))
		box.add_child(UI.make_label("重点：「%s · %s」累计错 %d 次" % [str(info.get("chapter", "")), str(info.get("name", "")), int(top["count"])], 14, Color("#ffd479")))
	return card
