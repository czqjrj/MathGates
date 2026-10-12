extends Control
## 错题笔记 · 逐题回看历史错题，按关卡分组、可按领域筛选，一键跳转重练。

var _filter: String = ""   # 当前领域/模块筛选("" = 全部)

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build_topbar()
	_build_body()
	var pet := Pet.spawn(self, "错题是宝藏，一起把它们清掉吧～")
	pet.tap_provider = _pet_comment
	GameData.progress_changed.connect(_build_body)

func _pet_comment() -> String:
	var wl := GameData.wrong_list()
	if wl.is_empty():
		return "错题本空空的，太厉害了！"
	var top: Dictionary = wl[0]
	var info := GameData.level_info(str(top["level_id"]))
	return "错得最多的是「%s · %s」第 %d 题，重练一遍吧～" % [str(info.get("chapter", "")), str(info.get("name", "")), int(top["qi"]) + 1]

# ---------------------------------------------------------------- 顶栏
func _build_topbar() -> void:
	var hb := UI.screen_topbar(self, "错题笔记", "WRONG NOTEBOOK", "res://scenes/MainHub.tscn")
	hb.add_child(UI.mono_label("错题 %d" % GameData.wrong_list().size(), 17, Color("#fb7185")))

# ---------------------------------------------------------------- 主体
func _build_body() -> void:
	for c in get_children():
		if c is ScrollContainer:
			c.queue_free()
	var mods := _modules_present()
	if _filter != "" and not mods.has(_filter):
		_filter = ""

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

	if mods.size() > 1:
		vb.add_child(_filter_row(mods))

	vb.add_child(UI.section("错题清单", Color("#fb7185")))
	var recs := _visible_wrong()
	if recs.is_empty():
		vb.add_child(_empty("暂无错题记录，保持这个状态！" if _filter == "" else "该领域暂无错题。"))
	else:
		for g in _group_by_level(recs):
			vb.add_child(_level_group(g))

	vb.add_child(UI.gap(20))
	UI.stagger_in(vb, 0.03, 0.24, 12)

func _overview_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#fb7185", 0.35), 14, 22, Color("#fb7185", 0.2))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("错题笔记", 26, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label("逐题回看 · 一键重练", 14, UI.COL_TEXT_DIM))
	var wl := GameData.wrong_list()
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
	stats.add_child(UI.stat_box("涉及领域", "%d" % _modules_present().size()))
	return card

func _filter_row(mods: Array) -> Control:
	var card := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.12), 12, 12)
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	card.add_child(hb)
	hb.add_child(UI.make_label("筛选", 14, UI.COL_TEXT_DIM))
	var wrap := HFlowContainer.new()
	wrap.add_theme_constant_override("h_separation", 8)
	wrap.add_theme_constant_override("v_separation", 6)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(wrap)
	wrap.add_child(_filter_btn("全部", ""))
	for m in mods:
		wrap.add_child(_filter_btn(_module_label(str(m)), str(m)))
	return card

func _filter_btn(text: String, m: String) -> Button:
	var sel := _filter == m
	var b := UI.ghost_button(("● " if sel else "") + text, func() -> void:
		if _filter == m:
			return
		_filter = m
		Sound.play("select")
		_build_body()
	, 13)
	if sel:
		b.add_theme_color_override("font_color", UI.COL_ACCENT)
	return b

func _level_group(g: Dictionary) -> Control:
	var lid := str(g["level_id"])
	var recs: Array = g["recs"]
	var info := GameData.level_info(lid)
	var card := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.13), 12, 16)
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	var bar := ColorRect.new()
	bar.color = Color("#fb7185")
	bar.custom_minimum_size = Vector2(4, 20)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(bar)
	head.add_child(UI.make_label("%s · %s" % [str(info.get("chapter", "")), str(info.get("name", ""))], 18, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.mono_label("%d 题 · 错 %d 次" % [recs.size(), int(g["total"])], 13, Color("#ffd479")))
	var nav := GameData.quest_target({ "level_id": lid, "qi": int(recs[0].get("qi", 0)) })
	if not nav.is_empty():
		head.add_child(UI.ghost_button("整关重练", func() -> void:
			GameData.start_level(int(nav["ci"]), int(nav["li"]))
			Scene.goto(str(nav["scene"]))
		, 13))

	var line := ColorRect.new()
	line.color = UI.COL_LINE
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line)

	for rec in recs:
		box.add_child(_wrong_line(rec))
	return card

func _wrong_line(rec: Dictionary) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.add_child(UI.mono_label("第 %d 题" % (int(rec["qi"]) + 1), 14, Color("#fb7185")))
	hb.add_child(UI.make_label(str(rec["name"]), 15, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	hb.add_child(UI.mono_label("上次 %s / 正确 %s" % [UI.letter(int(rec.get("last_chose", -1))), UI.letter(int(rec.get("correct", -1)))], 13, UI.COL_TEXT_DIM))
	hb.add_child(UI.mono_label("错 %d 次" % int(rec["count"]), 13, Color("#ffd479")))
	var nav := GameData.quest_target({ "level_id": str(rec["level_id"]), "qi": int(rec.get("qi", 0)) })
	if not nav.is_empty():
		hb.add_child(UI.ghost_button("去复习", func() -> void:
			GameData.start_level_focus(int(nav["ci"]), int(nav["li"]), int(rec.get("qi", 0)))
			Scene.goto(str(nav["scene"]))
		, 13))
	return hb

# ---------------------------------------------------------------- 数据
func _visible_wrong() -> Array:
	var out: Array = []
	for rec in GameData.wrong_list():
		if _filter == "" or str(rec.get("module", "")) == _filter:
			out.append(rec)
	return out

func _modules_present() -> Array:
	var seen := {}
	var out: Array = []
	for rec in GameData.wrong_list():
		var m := str(rec.get("module", ""))
		if not seen.has(m):
			seen[m] = true
			out.append(m)
	return out

func _module_label(m: String) -> String:
	if m == "":
		return "综合"
	for d in GameData.DOMAINS:
		if m == str(d["id"]) or m in d["chapters"]:
			return str(d["title"])
	return m

func _group_by_level(recs: Array) -> Array:
	var groups := {}
	for rec in recs:
		var lid := str(rec["level_id"])
		if not groups.has(lid):
			groups[lid] = []
		(groups[lid] as Array).append(rec)
	var out: Array = []
	for lid in groups.keys():
		var arr: Array = groups[lid]
		out.append({ "level_id": lid, "recs": arr, "total": _group_total(arr) })
	out.sort_custom(func(a, b): return int(a["total"]) > int(b["total"]))
	return out

func _group_total(recs: Array) -> int:
	var t := 0
	for r in recs:
		t += int(r.get("count", 0))
	return t

# ---------------------------------------------------------------- 小组件
func _empty(text: String) -> Control:
	var p := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.13), 12, 18)
	p.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	p.add_child(UI.make_label(text, 15, UI.COL_TEXT_DIM))
	return p
