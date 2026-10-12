extends Control
## 每日任务 · 今日推演目标 + 领取奖励，并附本地连击榜。

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build_topbar()
	_build_body()
	var pet := Pet.spawn(self, "完成今日任务，领取额外星辉～")
	pet.tap_provider = _pet_comment
	GameData.progress_changed.connect(_on_progress)

func _pet_comment() -> String:
	var n := GameData.daily_claimable_count()
	if n > 0:
		return "有 %d 个任务可以领取奖励啦，别忘了领～" % n
	var claimed := GameData.daily_claimed_count()
	if claimed >= GameData.DAILY_MISSIONS.size():
		return "今日任务全部完成，好厉害！"
	return "今日最高连击 x%d，继续加油～" % GameData.daily_peak_streak

func _on_progress() -> void:
	_build_topbar_refresh()
	_build_body()

# ---------------------------------------------------------------- 顶栏
var _claim_lbl: Label

func _build_topbar() -> void:
	var hb := UI.screen_topbar(self, "每日任务", "DAILY MISSIONS", "res://scenes/MainHub.tscn")
	_claim_lbl = UI.mono_label(_claim_text(), 17, Color("#ffd479"))
	hb.add_child(_claim_lbl)

func _claim_text() -> String:
	var n := GameData.daily_claimable_count()
	return ("可领取 %d 项" % n) if n > 0 else "今日进度"

func _build_topbar_refresh() -> void:
	if _claim_lbl != null and is_instance_valid(_claim_lbl):
		_claim_lbl.text = _claim_text()
		_claim_lbl.add_theme_color_override("font_color", Color("#4dd6a8") if GameData.daily_claimable_count() > 0 else Color("#ffd479"))

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

	vb.add_child(UI.section("今日任务", Color("#ffd479")))
	var mcenter := CenterContainer.new()
	vb.add_child(mcenter)
	var mcol := VBoxContainer.new()
	mcol.add_theme_constant_override("separation", 12)
	mcenter.add_child(mcol)
	for m in GameData.daily_missions():
		mcol.add_child(_mission_card(m))

	vb.add_child(UI.section("连击榜", Color("#5ee6ff")))
	var lcenter := CenterContainer.new()
	vb.add_child(lcenter)
	var lcard := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#5ee6ff", 0.3), 14, 20, Color("#5ee6ff", 0.16))
	lcard.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 10)
	lcard.add_child(lcol)
	_build_board(lcol)
	lcenter.add_child(lcard)

	vb.add_child(UI.gap(20))
	UI.stagger_in(vb, 0.03, 0.24, 12)

func _overview_card() -> Control:
	var card := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color("#ffd479", 0.35), 14, 22, Color("#ffd479", 0.2))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(UI.make_label("每日任务", 26, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label("日拱一卒 · 功不唐捐", 14, UI.COL_TEXT_DIM))
	var claimed := GameData.daily_claimed_count()
	var total := GameData.DAILY_MISSIONS.size()
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	box.add_child(stats)
	stats.add_child(UI.stat_box("已完成", "%d / %d" % [claimed, total]))
	stats.add_child(UI.stat_box("今日最高连击", "x%d" % GameData.daily_peak_streak))
	stats.add_child(UI.stat_box("历史最高连击", "x%d" % GameData.best_streak))
	stats.add_child(UI.stat_box("连续登录", "%d 天" % GameData.login_streak))
	var bar := ProgressLine.new()
	bar.col = Color("#ffd479")
	bar.glow = claimed > 0
	bar.set_ratio(float(claimed) / float(maxi(1, total)), false)
	box.add_child(bar)
	return card

# ---------------------------------------------------------------- 任务
func _mission_card(m: Dictionary) -> Control:
	var id := str(m["id"])
	var done := bool(m["done"])
	var claimed := bool(m["claimed"])
	var card := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.13), 12, 16)
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	card.add_child(hb)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 5)
	hb.add_child(col)
	var title := UI.make_label(str(m["name"]), 18, UI.COL_TEXT)
	col.add_child(title)
	col.add_child(UI.make_label(str(m["desc"]), 13, UI.COL_TEXT_DIM))

	var goal := maxi(1, int(m["goal"]))
	var cur := mini(int(m["cur"]), goal)
	var bar := ProgressLine.new()
	bar.custom_minimum_size = Vector2(0, 6)
	bar.col = Color("#4dd6a8") if done else Color("#ffd479")
	bar.set_ratio(float(cur) / float(goal), false)
	col.add_child(bar)

	var right := VBoxContainer.new()
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_theme_constant_override("separation", 6)
	hb.add_child(right)
	right.add_child(UI.mono_label("%d / %d" % [cur, goal], 14, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	right.add_child(UI.mono_label("◆%d · %d经验" % [int(m["coins"]), int(m["exp"])], 12, Color("#ffd479"), HORIZONTAL_ALIGNMENT_CENTER))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 0)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if claimed:
		btn.text = "已领取"
		btn.disabled = true
	elif done:
		btn.text = "领取奖励"
		UI.primary_button(btn)
		btn.pressed.connect(func() -> void: _claim(id))
	else:
		btn.text = "进行中"
		btn.disabled = true
	hb.add_child(btn)
	return card

func _claim(id: String) -> void:
	if GameData.claim_daily_mission(id):
		Sound.play("unlock")
		Toast.show_toast("已领取任务奖励！")
	else:
		Sound.play("wrong")
		Toast.show_toast("任务尚未完成")

# ---------------------------------------------------------------- 连击榜
func _build_board(col: VBoxContainer) -> void:
	var users := GameData.list_users()
	if users.is_empty():
		col.add_child(UI.make_label("暂无记录", 14, UI.COL_TEXT_DIM))
		return
	users.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["best_streak"]) > int(b["best_streak"]))
	var rank := 0
	for u in users:
		rank += 1
		col.add_child(_board_row(rank, u))

func _board_row(rank: int, u: Dictionary) -> Control:
	var me := str(u["name"]) == GameData.current_user
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var rcol := Color("#ffd479") if rank == 1 else (Color("#cfd6e6") if rank == 2 else (Color("#e8a06a") if rank == 3 else Color(UI.COL_TEXT_DIM, 0.8)))
	var rl := UI.mono_label("#%d" % rank, 16, rcol)
	rl.custom_minimum_size = Vector2(44, 0)
	row.add_child(rl)
	var def := _avatar_def(str(u["avatar"]))
	var iv := TextureRect.new()
	iv.texture = UI.icon(str(def.get("icon", "player")), 30, Color(str(def.get("color", "#ffffff"))))
	iv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	iv.custom_minimum_size = Vector2(30, 30)
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(iv)
	var nm := UI.make_label(str(u["name"]) + ("  (我)" if me else ""), 16, UI.COL_ACCENT if me else UI.COL_TEXT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nm)
	row.add_child(UI.mono_label("x%d" % int(u["best_streak"]), 16, Color("#5ee6ff")))
	return row

func _avatar_def(id: String) -> Dictionary:
	for a in GameData.AVATARS:
		if str(a["id"]) == id:
			return a
	return {}
