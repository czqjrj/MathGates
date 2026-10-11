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
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.topbar_box())
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 64)
	bar.offset_bottom = 64
	add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	bar.add_child(hb)
	hb.add_child(UI.ghost_button("← 返回终端", func() -> void:
		Scene.goto("res://scenes/MainHub.tscn")
	))
	hb.add_child(_hairline(Vector2(1, 18)))
	hb.add_child(UI.make_label("档案库", 22))
	hb.add_child(UI.mono_label("USER PROFILE", 13, Color(UI.COL_TEXT_DIM, 0.7)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
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
	overview.custom_minimum_size = Vector2(920, 0)
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
	stats.add_theme_constant_override("separation", 30)
	ovb.add_child(stats)
	stats.add_child(_stat("已通关卡", "%d" % done_levels))
	stats.add_child(_stat("累计作答", "%d" % GameData.total_questions))
	stats.add_child(_stat("累计答对", "%d" % GameData.total_correct))
	stats.add_child(_stat("正确率", "%d%%" % acc))
	stats.add_child(_stat("总星数", "%d" % GameData.total_stars()))
	stats.add_child(_stat("投喂萌宠", "%d" % GameData.pet_fed))
	var tier_name: String = ["初识", "熟悉", "黏人"][_pet_tier()]
	stats.add_child(_stat("好感度", tier_name))

	# ---- 进阶 · 等级与称号 ----
	vb.add_child(_advance_card())

	# ---- 知识掌握 · 萌宠进化 ----
	vb.add_child(_mastery_card())

	# ---- 记忆档案 · 馆灵碑文 ----
	vb.add_child(_lore_card())

	# ---- 成就 · 勋章墙 ----
	vb.add_child(_section("成就 · 勋章墙  %d / %d" % [GameData.medal_count(), GameData.MEDALS.size()], Color("#a878ff")))
	var gcenter := CenterContainer.new()
	vb.add_child(gcenter)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 16)
	gcenter.add_child(grid)
	for m in GameData.MEDALS:
		grid.add_child(_medal_cell(m))

	# ---- 出错位置 ----
	vb.add_child(_section("出错位置 · 错题本", Color("#fb7185")))
	var wl := GameData.wrong_list()
	if wl.is_empty():
		vb.add_child(_empty("暂无错题记录，保持这个状态！"))
	else:
		for rec in wl:
			vb.add_child(_wrong_row(rec))

	# ---- 重点 ----
	vb.add_child(_section("重点 · 错误集中的知识点", Color("#ffd479")))
	var kp := GameData.key_points()
	if kp.is_empty():
		vb.add_child(_empty("暂无明显薄弱点。"))
	else:
		for rec in kp:
			vb.add_child(_key_row(rec))

	vb.add_child(_gap(20))
	UI.stagger_in(vb, 0.035, 0.24, 10)

func _section(title: String, col: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var bar := ColorRect.new()
	bar.color = col
	bar.custom_minimum_size = Vector2(4, 22)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)
	row.add_child(UI.make_label(title, 20, UI.COL_TEXT))
	return row

func _stat(label: String, value: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(UI.mono_label(value, 24, UI.COL_ACCENT))
	box.add_child(UI.make_label(label, 14, UI.COL_TEXT_DIM))
	return box

## 进阶卡片：推演等级 + 称号进度(两条进度条)
func _advance_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#a878ff", 0.3), 14, 22, Color("#a878ff", 0.18))
	card.custom_minimum_size = Vector2(920, 0)
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
	card.custom_minimum_size = Vector2(920, 0)
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
	elif m < GameData.MASTERY_STALE:
		tag = "已解锁 · 生疏"
	head.add_child(UI.mono_label(tag, 13, col if unlocked else UI.COL_TEXT_DIM))
	var bar := ProgressLine.new()
	bar.col = col
	bar.glow = unlocked
	bar.custom_minimum_size = Vector2(414, 6)
	bar.set_ratio(m, false)
	row.add_child(bar)
	return row

## 馆灵记忆档案：寻回的碑文与尚未寻回的裂隙
func _lore_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#5ee6ff", 0.3), 14, 22, Color("#5ee6ff", 0.16))
	card.custom_minimum_size = Vector2(920, 0)
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

## 单枚勋章格：徽章 + 名称(未解锁灰色)
func _medal_cell(m: Dictionary) -> Control:
	var unlocked := GameData.is_medal_unlocked(str(m["id"]))
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(92, 0)
	cell.add_theme_constant_override("separation", 5)
	cell.tooltip_text = "%s\n%s" % [str(m["desc"]), "已解锁" if unlocked else "未解锁"]
	var badge := MedalBadge.new()
	badge.custom_minimum_size = Vector2(58, 58)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.col = Color(str(m["color"]))
	badge.symbol = str(m["symbol"])
	badge.unlocked = unlocked
	cell.add_child(badge)
	var nm := UI.make_label(str(m["name"]), 12, UI.COL_TEXT if unlocked else Color(UI.COL_TEXT_DIM, 0.6), HORIZONTAL_ALIGNMENT_CENTER)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cell.add_child(nm)
	return cell

func _wrong_row(rec: Dictionary) -> Control:
	var info: Dictionary = GameData.level_info(str(rec["level_id"]))
	var p := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.065), Color(1, 1, 1, 0.13), 12, 16)
	p.custom_minimum_size = Vector2(920, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	p.add_child(vb)
	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 8)
	vb.add_child(line1)
	line1.add_child(UI.mono_label("第 %d 题" % (int(rec["qi"]) + 1), 14, Color("#fb7185")))
	line1.add_child(UI.make_label(str(rec["name"]), 16, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line1.add_child(sp)
	line1.add_child(UI.mono_label("错 %d 次" % int(rec["count"]), 14, Color("#ffd479")))
	var nav := GameData.quest_target({ "level_id": str(rec["level_id"]), "qi": int(rec.get("qi", 0)) })
	if not nav.is_empty():
		line1.add_child(UI.ghost_button("去复习", func() -> void:
			GameData.start_level(int(nav["ci"]), int(nav["li"]))
			Scene.goto(str(nav["scene"]))
		, 13))
	var line2 := UI.make_label("%s · %s     上次选 %s，正确 %s" % [str(info.get("chapter", "")), str(info.get("name", "")), _letter(int(rec.get("last_chose", -1))), _letter(int(rec.get("correct", -1)))], 13, UI.COL_TEXT_DIM)
	vb.add_child(line2)
	return p

func _key_row(rec: Dictionary) -> Control:
	var info: Dictionary = GameData.level_info(str(rec["level_id"]))
	var row := UI.card(false, UI.COL_ACCENT, Color(0.15, 0.12, 0.03, 0.5), Color("#ffd479", 0.35), 12, 14)
	row.custom_minimum_size = Vector2(920, 0)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	hb.add_child(UI.mono_label("▲", 15, Color("#ffd479")))
	hb.add_child(UI.make_label("%s · %s" % [str(info.get("chapter", "")), str(info.get("name", ""))], 16, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	hb.add_child(UI.mono_label("累计错 %d 次" % int(rec["count"]), 14, Color("#fb7185")))
	return row

func _empty(text: String) -> Control:
	var p := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.13), 12, 18)
	p.custom_minimum_size = Vector2(920, 0)
	p.add_child(UI.make_label(text, 15, UI.COL_TEXT_DIM))
	return p

func _letter(i: int) -> String:
	return "ABCD".substr(i, 1) if i >= 0 and i <= 3 else "—"

func _pet_tier() -> int:
	if GameData.pet_fed >= 8:
		return 2
	if GameData.pet_fed >= 3:
		return 1
	return 0

func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _hairline(min_size: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.color = UI.COL_LINE
	r.custom_minimum_size = min_size
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
