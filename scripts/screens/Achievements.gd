extends Control
## 成就馆 · 汇集全部勋章的图鉴与达成进度。

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build_topbar()
	_build_body()
	var pet := Pet.spawn(self, "点亮勋章，记录你的每一步～")
	pet.tap_provider = _pet_comment
	GameData.progress_changed.connect(_on_progress)

func _pet_comment() -> String:
	var n := GameData.medal_count()
	var total := PlayerRules.MEDALS.size()
	if n >= total:
		return "全部勋章都集齐了，太厉害了！"
	var nxt := ""
	for m in PlayerRules.MEDALS:
		if not GameData.is_medal_unlocked(str(m["id"])):
			nxt = str(m["name"])
			break
	return "已点亮 %d / %d，下一枚「%s」等你摘取～" % [n, total, nxt]

func _on_progress() -> void:
	_build_topbar_refresh()
	_build_body()

# ---------------------------------------------------------------- 顶栏
var _count_lbl: Label

func _build_topbar() -> void:
	var hb := UI.screen_topbar(self, "成就馆", "ACHIEVEMENTS", "res://scenes/MainHub.tscn")
	_count_lbl = UI.mono_label("勋章 %d / %d" % [GameData.medal_count(), PlayerRules.MEDALS.size()], 17, Color("#a878ff"))
	hb.add_child(_count_lbl)

func _build_topbar_refresh() -> void:
	if _count_lbl != null and is_instance_valid(_count_lbl):
		_count_lbl.text = "勋章 %d / %d" % [GameData.medal_count(), PlayerRules.MEDALS.size()]

# ---------------------------------------------------------------- 主体
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

	vb.add_child(_overview_card())

	vb.add_child(UI.section("勋章图鉴", Color("#a878ff")))
	var gcenter := CenterContainer.new()
	vb.add_child(gcenter)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	gcenter.add_child(grid)
	for m in PlayerRules.MEDALS:
		grid.add_child(_medal_card(m))

	vb.add_child(UI.gap(20))
	UI.stagger_in(vb, 0.03, 0.24, 12)

func _overview_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#a878ff", 0.35), 14, 22, Color("#a878ff", 0.2))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("成就馆", 26, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label("解析失序 · 留痕成章", 14, UI.COL_TEXT_DIM))
	var total := PlayerRules.MEDALS.size()
	var got := GameData.medal_count()
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	box.add_child(stats)
	stats.add_child(UI.stat_box("已解锁", "%d" % got))
	stats.add_child(UI.stat_box("待解锁", "%d" % (total - got)))
	stats.add_child(UI.stat_box("已集头像", "%d / %d" % [_owned_avatar_count(), GameData.AVATARS.size()]))
	stats.add_child(UI.stat_box("萌宠形态", GameData.pet_form_name()))
	var bar := ProgressLine.new()
	bar.col = Color("#a878ff")
	bar.glow = got > 0
	bar.set_ratio(float(got) / float(maxi(1, total)), false)
	box.add_child(bar)
	return card

func _owned_avatar_count() -> int:
	var n := 0
	for a in GameData.AVATARS:
		if GameData.has_avatar(str(a["id"])):
			n += 1
	return n

# ---------------------------------------------------------------- 勋章
func _medal_card(m: Dictionary) -> Control:
	var id := str(m["id"])
	var unlocked := GameData.is_medal_unlocked(id)
	var card := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.13), 12, 14)
	card.custom_minimum_size = Vector2(440, 0)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	card.add_child(hb)
	var badge := MedalBadge.new()
	badge.custom_minimum_size = Vector2(58, 58)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.col = Color(str(m["color"]))
	badge.symbol = str(m["symbol"])
	badge.unlocked = unlocked
	hb.add_child(badge)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 3)
	hb.add_child(col)
	col.add_child(UI.make_label(str(m["name"]), 18, UI.COL_TEXT if unlocked else UI.COL_TEXT_DIM))
	col.add_child(UI.make_label(str(m["desc"]), 13, UI.COL_TEXT_DIM))

	var st := ""
	var st_col := Color(UI.COL_TEXT_DIM, 0.8)
	if unlocked:
		st = "已解锁"
		st_col = UI.COL_SUCCESS
	else:
		var p := _medal_progress(id)
		if not p.is_empty():
			var goal := maxi(1, int(p["goal"]))
			var cur := mini(int(p["cur"]), goal)
			st = "%d / %d" % [cur, goal]
			st_col = Color(str(m["color"]))
			var bar := ProgressLine.new()
			bar.custom_minimum_size = Vector2(0, 5)
			bar.col = Color(str(m["color"]))
			bar.set_ratio(float(cur) / float(goal), false)
			col.add_child(bar)
		else:
			st = "未解锁"
	hb.add_child(UI.mono_label(st, 14, st_col))
	return card

## 可量化的勋章返回 {cur, goal}；不可量化(章节通解等)返回空。
func _medal_progress(id: String) -> Dictionary:
	match id:
		"clear_10":   return { "cur": GameData.cleared_level_count(), "goal": 10 }
		"clear_30":   return { "cur": GameData.cleared_level_count(), "goal": 30 }
		"clear_60":   return { "cur": GameData.cleared_level_count(), "goal": 60 }
		"perfect_1":  return { "cur": GameData.full_star_level_count(), "goal": 1 }
		"perfect_10": return { "cur": GameData.full_star_level_count(), "goal": 10 }
		"perfect_30": return { "cur": GameData.full_star_level_count(), "goal": 30 }
		"stars_50":   return { "cur": GameData.total_stars(), "goal": 50 }
		"stars_150":  return { "cur": GameData.total_stars(), "goal": 150 }
		"stars_300":  return { "cur": GameData.total_stars(), "goal": 300 }
		"answer_100": return { "cur": GameData.total_questions, "goal": 100 }
		"answer_500": return { "cur": GameData.total_questions, "goal": 500 }
		"coins_1000": return { "cur": GameData.coins_earned, "goal": 1000 }
		"pet_3":      return { "cur": GameData.pet_fed, "goal": 3 }
		"pet_10":     return { "cur": GameData.pet_fed, "goal": 10 }
		"boss_first": return { "cur": GameData.boss_cleared_count(), "goal": 1 }
		"boss_all":   return { "cur": GameData.boss_cleared_count(), "goal": GameData.boss_level_ids().size() }
	return {}
