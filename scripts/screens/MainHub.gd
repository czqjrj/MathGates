extends Control
## 主城 · 极简未来风：顶栏档案读数 + 标题 + 玻璃功能卡片

var _name_lbl: Label
var _lv_lbl: Label
var _star_lbl: Label
var _prog_lbl: Label
var _prog_line: ProgressLine
var _daily_btn: Button

func _ready() -> void:
	theme = UI.make_theme()
	if not GameData.is_logged_in():
		Scene.goto.call_deferred("res://scenes/Login.tscn")
		return
	add_child(TechBg.new())
	_build_topbar()
	_build_center()
	_add_pet()
	_refresh_status()
	GameData.progress_changed.connect(_refresh_status)
	_maybe_daily()

## 每日登录奖励：当天未领取时弹窗，连续登录加成。
func _maybe_daily() -> void:
	if not GameData.daily_available():
		return
	var next_streak := (GameData.login_streak + 1) if GameData.last_login_date == GameData._yesterday() else 1
	var mult := 1.0 + 0.2 * float(next_streak - 1)
	var coins := int(50.0 * mult)
	var ex := int(20.0 * mult)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	UI.confirm(self, "每日登录奖励", "连续登录第 %d 天\n金币 +%d   ·   经验 +%d" % [next_streak, coins, ex], func() -> void:
		var r := GameData.claim_daily()
		if bool(r.get("ok", false)):
			Sound.play("unlock")
			Toast.show_toast("每日奖励 · 金币 +%d   经验 +%d" % [int(r["coins"]), int(r["exp"])])
	, "领取")

func _add_pet() -> void:
	var pet := Pet.spawn(self)
	pet.position = Vector2(get_viewport_rect().size.x - 210.0, get_viewport_rect().size.y - 220.0)
	pet.tap_provider = _pet_comment
	var cnt := GameData.unlocked_region_count()
	var unlocked_new := cnt > GameData.regions_seen and GameData.regions_seen > 0
	if cnt != GameData.regions_seen:
		GameData.set_regions_seen(cnt)
	if pet.try_autogreet():
		return
	if not GameData.pet_greeted_session:
		GameData.pet_greeted_session = true
		pet.clingy()
	elif unlocked_new:
		pet.celebrate(1.5)
		pet.say("解锁了新区域，太棒了！", 3.4)
	else:
		pet.say(Pet.daily_greeting(GameData.current_user))

func _pet_comment() -> String:
	var kp := GameData.key_points()
	if kp.is_empty():
		return "暂时没有薄弱点，继续保持，厉害！"
	var top: Dictionary = kp[0]
	var info := GameData.level_info(str(top["level_id"]))
	return "你最近在「%s · %s」错得比较多，重点复习一下哦～" % [str(info.get("chapter", "")), str(info.get("name", ""))]

# ---------------------------------------------------------------- 顶栏
func _build_topbar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.topbar_box())
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 64)
	bar.offset_bottom = 64
	add_child(bar)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	bar.add_child(hb)

	hb.add_child(UI.make_label("推演档案", 15, UI.COL_TEXT_DIM))

	_name_lbl = UI.make_label("", 17)
	hb.add_child(_name_lbl)

	_lv_lbl = UI.mono_label("", 17, UI.COL_TEXT_DIM)
	hb.add_child(_lv_lbl)

	_star_lbl = UI.mono_label("", 17, UI.COL_ACCENT)
	hb.add_child(_star_lbl)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)

	# 当前用户 + 头像 + 退出
	var info: Dictionary = GameData.avatar_info(GameData.avatar)
	var av := TextureRect.new()
	av.texture = UI.icon(str(info["icon"]), 34, Color(str(info["color"])))
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av.custom_minimum_size = Vector2(34, 34)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(av)
	hb.add_child(UI.make_label(GameData.current_user, 17))
	_daily_btn = UI.ghost_button(_daily_text(), func() -> void:
		Sound.play("select")
		Scene.goto("res://scenes/DailyMissions.tscn")
	, 14)
	hb.add_child(_daily_btn)
	hb.add_child(UI.ghost_button("退出登录", func() -> void:
		GameData.logout()
		Sound.play("select")
		Scene.goto("res://scenes/Login.tscn")
	, 14))

	hb.add_child(UI.ghost_button("重置推演", func() -> void:
		UI.confirm(self, "重置推演", "将清空全部推演进度(星数、错题、萌宠成长等)，且无法撤销。确定吗？", func() -> void:
			GameData.reset_progress()
			Toast.show_toast("推演档案已重置")
		)
	, 14))

	hb.add_child(UI.ghost_button("设置", func() -> void:
		Sound.play("select")
		Scene.goto("res://scenes/Settings.tscn")
	, 14))

	hb.add_child(UI.ghost_button("退出", func() -> void:
		UI.confirm(self, "退出游戏", "确定要退出吗？", func() -> void: get_tree().quit())
	, 14))

func _refresh_status() -> void:
	if _name_lbl == null:
		return
	_name_lbl.text = GameData.rank_title()
	_lv_lbl.text = "Lv.%d" % GameData.player_level()
	_star_lbl.text = "★ %d / %d" % [GameData.total_stars(), GameData.total_max_stars()]
	if _daily_btn != null and is_instance_valid(_daily_btn):
		_daily_btn.text = _daily_text()
	var rp := GameData.rank_progress()
	if str(rp["next_title"]) == "":
		_prog_line.set_ratio(1.0)
		_prog_lbl.text = "称号进度 · 已臻顶阶"
	else:
		_prog_line.set_ratio(float(rp["ratio"]))
		_prog_lbl.text = "称号进度 · 距「%s」还需 %d★" % [str(rp["next_title"]), int(rp["need"])]

## 顶栏「每日任务」按钮文案：有可领取时附数量。
func _daily_text() -> String:
	var n := GameData.daily_claimable_count()
	return ("每日任务 (%d)" % n) if n > 0 else "每日任务"

# ---------------------------------------------------------------- 中央
func _build_center() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 64
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	center.add_child(vb)

	var mark := BrandMark.new()
	mark.custom_minimum_size = Vector2(118, 118)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(mark)

	var title := UI.make_label("衍 数 阁", 56, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", UI.title_font())
	UI.outlined(title, 4, Color(0, 0, 0, 0.4))
	vb.add_child(title)

	var line := BrandMark.Underline.new()
	line.custom_minimum_size = Vector2(150, 3)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(line)

	# 标题呼吸(纯气氛动效，可在设置中关闭)
	if UI.animations:
		title.pivot_offset = title.size * 0.5
		title.resized.connect(func() -> void: title.pivot_offset = title.size * 0.5)
		var btw := title.create_tween().set_loops()
		btw.tween_property(title, "scale", Vector2(1.035, 1.035), 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		btw.tween_property(title, "scale", Vector2.ONE, 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	vb.add_child(UI.make_label("解析失序的公理 · 推演世界的唯一解", 17, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	# 称号进度
	var pbox := VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 6)
	pbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(pbox)
	_prog_lbl = UI.mono_label("", 14, Color(UI.COL_TEXT_DIM, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	pbox.add_child(_prog_lbl)
	_prog_line = ProgressLine.new()
	_prog_line.custom_minimum_size = Vector2(280, 5)
	_prog_line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pbox.add_child(_prog_line)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 22)
	vb.add_child(gap)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vb.add_child(row)
	row.add_child(_card("知识体系", "思维导图统整知识，逐点点亮", Color("#a878ff"), "icon_tree", _on_theorem_tree, true))
	row.add_child(_card("方法推演", "按教材分册，逐章攻克方法与题型", Color("#5b8cff"), "icon_map", _on_adventure, false, true))
	row.add_child(_card("档案库", "用户档案与学情诊断", Color("#ffa64d"), "icon_book", _on_archive, false, true))
	row.add_child(_card("错题笔记", "逐题回看错题，一键重练", Color("#4dd6a8"), "icon_train", _on_wrong_notebook, false, true))
	row.add_child(_card("星辉市集", "金币兑换头像与道具", Color("#ffd479"), "icon_star_full", _on_shop, false, true))

	UI.fade_in(vb, 0.42)
	UI.card_deal_in(row, 0.09, 0.55)

# ---------------------------------------------------------------- 功能卡片
func _card(title: String, desc: String, color: Color, icon_name: String, on_press: Callable, primary: bool, available: bool = false) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(226, 244)

	var border := Color(color, 0.4)
	if primary:
		border = Color(UI.COL_ACCENT, 0.75)
	elif available:
		border = Color(color, 0.6)
	var p := PanelContainer.new()
	var glow := Color(UI.COL_ACCENT, 0.18) if primary else Color(color, 0.15)
	p.add_theme_stylebox_override("panel", UI.glass_box(Color(0.05, 0.07, 0.12, 0.72), 14, border, 1, 16, glow, 14))
	UI.full_rect(p)
	holder.add_child(p)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)

	var tint := UI.COL_ACCENT if primary else color.lightened(0.35)
	var iv := TextureRect.new()
	iv.texture = UI.icon(icon_name, 76, tint)
	iv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	iv.custom_minimum_size = Vector2(76, 76)
	iv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(iv)

	var hl := ColorRect.new()
	hl.color = UI.COL_LINE
	hl.custom_minimum_size = Vector2(0, 1)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(hl)

	var t_lbl := UI.make_label(title, 21, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	vb.add_child(t_lbl)
	var d_lbl := UI.make_label(desc, 14, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(d_lbl)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var enterable := primary or available
	vb.add_child(UI.mono_label(
		"ENTER →" if enterable else "COMING SOON", 13,
		UI.COL_ACCENT if primary else (color.lightened(0.3) if available else Color(UI.COL_TEXT_DIM, 0.75)),
		HORIZONTAL_ALIGNMENT_CENTER))

	var mark_col := Color(UI.COL_ACCENT, 0.85) if primary else Color(color, 0.8)
	UI.corner_marks(holder, 7, 13, 2, mark_col)

	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_theme_stylebox_override("normal", UI.stylebox(Color(0, 0, 0, 0), 14, Color(0, 0, 0, 0), 0, 0))
	btn.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.06), 14, Color(UI.COL_ACCENT, 0.5), 1, 0))
	btn.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.25), 14, Color(UI.COL_ACCENT, 0.8), 1, 0))
	btn.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 14, Color(UI.COL_ACCENT, 0.3), 1, 0))
	btn.add_theme_stylebox_override("disabled", UI.stylebox(Color(0, 0, 0, 0), 14, Color(0, 0, 0, 0), 0, 0))
	btn.pressed.connect(on_press)
	holder.add_child(btn)
	# lift=1.0：悬停只做倾斜，不做放大——避免“发牌”飞入途中经过指针后
	# 卡在 hover 放大态，导致五张卡片大小不一致（详见 UI.card_tilt）。
	UI.card_tilt(holder, btn, 6.0, 1.0)
	UI.press_scale(holder, btn, 0.985)
	return holder

# ---------------------------------------------------------------- 工具
func _on_adventure() -> void:
	Sound.play("begin")
	Scene.goto("res://scenes/WorldMap.tscn")

func _on_theorem_tree() -> void:
	Sound.play("begin")
	Scene.goto("res://scenes/TheoremTree.tscn")

func _on_archive() -> void:
	Sound.play("begin")
	Scene.goto("res://scenes/UserProfile.tscn")

func _on_wrong_notebook() -> void:
	Sound.play("begin")
	Scene.goto("res://scenes/WrongNotebook.tscn")

func _on_shop() -> void:
	Sound.play("begin")
	Scene.goto("res://scenes/Shop.tscn")
