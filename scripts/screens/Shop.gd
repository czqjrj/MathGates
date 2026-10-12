extends Control
## 星辉市集 · 用金币解锁头像与道具，形成消费闭环。

const AV_LABELS := {
	"player": "推演者", "boss": "守关者", "book": "典藏者",
	"map": "寻路者", "tree": "智者", "train": "旅人",
}
const AVATAR_COST := 120

const ITEMS := [
	{ "id": "exp",    "name": "经验符",        "desc": "立即获得 80 经验",      "cost": 150, "icon": "icon_star_full", "color": "#ffd479" },
	{ "id": "hint",   "name": "提示卡",        "desc": "用提示时不记失误",      "cost": 60,  "icon": "icon_book",      "color": "#5ee6ff" },
	{ "id": "hint3",  "name": "提示卡 ×3",     "desc": "一次购入三张，更划算",  "cost": 150, "icon": "icon_book",      "color": "#5ee6ff" },
	{ "id": "boost",  "name": "双倍金币卡",    "desc": "下一关结算金币翻倍",    "cost": 80,  "icon": "icon_star_full", "color": "#4dd6a8" },
	{ "id": "boost3", "name": "双倍金币卡 ×3", "desc": "一次购入三张，更划算",  "cost": 200, "icon": "icon_star_full", "color": "#4dd6a8" },
	{ "id": "pet",    "name": "宠物点心",      "desc": "立即回满饱食并提升好感", "cost": 50,  "icon": "icon_star_full", "color": "#ff7ab8" },
]

var _coin_lbl: Label

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build_topbar()
	_build_body()
	var pet := Pet.spawn(self, "金币要花在刀刃上哦～")
	pet.tap_provider = func() -> String: return "攒金币，解锁更多头像和道具吧！"
	GameData.progress_changed.connect(_on_progress)

func _on_progress() -> void:
	if _coin_lbl != null and is_instance_valid(_coin_lbl):
		_coin_lbl.text = "金币 %d" % GameData.coins
	_build_body()

# ---------------------------------------------------------------- 顶栏
func _build_topbar() -> void:
	var hb := UI.screen_topbar(self, "星辉市集", "STAR MARKET", "res://scenes/MainHub.tscn")
	_coin_lbl = UI.mono_label("金币 %d" % GameData.coins, 17, Color("#ffd479"))
	hb.add_child(_coin_lbl)

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

	vb.add_child(UI.section("头像解锁", Color("#a878ff")))
	vb.add_child(_avatar_grid())

	vb.add_child(UI.section("道具补给", Color("#5ee6ff")))
	var items := HFlowContainer.new()
	items.add_theme_constant_override("h_separation", 14)
	items.add_theme_constant_override("v_separation", 14)
	for it in ITEMS:
		items.add_child(_item_card(it))
	vb.add_child(items)

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
	head.add_child(UI.make_label("星辉市集", 26, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label("推演所得 · 兑换成长", 14, UI.COL_TEXT_DIM))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	box.add_child(stats)
	stats.add_child(UI.stat_box("金币余额", "%d" % GameData.coins))
	stats.add_child(UI.stat_box("累计获得", "%d" % GameData.coins_earned))
	stats.add_child(UI.stat_box("已集头像", "%d / %d" % [_owned_count(), GameData.AVATARS.size()]))
	stats.add_child(UI.stat_box("道具库存", "%d" % (GameData.hint_tokens + GameData.coin_boost)))
	return card

func _owned_count() -> int:
	var n := 0
	for a in GameData.AVATARS:
		if GameData.has_avatar(str(a["id"])):
			n += 1
	return n

# ---------------------------------------------------------------- 头像
func _avatar_grid() -> Control:
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for a in GameData.AVATARS:
		grid.add_child(_avatar_card(a))
	return grid

func _avatar_card(a: Dictionary) -> Control:
	var id := str(a["id"])
	var owned := GameData.has_avatar(id)
	var card := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.13), 12, 14)
	card.custom_minimum_size = Vector2(160, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var iv := TextureRect.new()
	iv.texture = UI.icon(str(a["icon"]), 64, Color(str(a["color"])) if owned else Color(1, 1, 1, 0.22))
	iv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	iv.custom_minimum_size = Vector2(64, 64)
	iv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(iv)
	box.add_child(UI.make_label(str(AV_LABELS.get(id, id)), 17, UI.COL_TEXT if owned else UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	if owned:
		box.add_child(UI.mono_label("已拥有", 13, UI.COL_SUCCESS, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		box.add_child(UI.ghost_button("解锁 %d" % AVATAR_COST, func() -> void: _buy_avatar(id), 13))
	return card

func _buy_avatar(id: String) -> void:
	if GameData.unlock_avatar(id, AVATAR_COST):
		Sound.play("unlock")
		Toast.show_toast("已解锁头像 · %s" % str(AV_LABELS.get(id, id)))
	else:
		Sound.play("wrong")
		Toast.show_toast("金币不足，去闯关赚金币吧！")

# ---------------------------------------------------------------- 道具
func _item_card(it: Dictionary) -> Control:
	var card := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.13), 12, 14)
	card.custom_minimum_size = Vector2(226, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	var iv := TextureRect.new()
	iv.texture = UI.icon(str(it["icon"]), 40, Color(str(it["color"])))
	iv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	iv.custom_minimum_size = Vector2(40, 40)
	iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(iv)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(col)
	col.add_child(UI.make_label(str(it["name"]), 18, UI.COL_TEXT))
	var stock := _item_stock(str(it["id"]))
	col.add_child(UI.mono_label(("库存 %d" % stock) if stock >= 0 else "即买即用", 12, UI.COL_TEXT_DIM))
	box.add_child(UI.make_label(str(it["desc"]), 13, UI.COL_TEXT_DIM))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(sp)
	box.add_child(UI.ghost_button("购买 %d" % int(it["cost"]), func() -> void: _buy_item(it), 13))
	return card

func _item_stock(id: String) -> int:
	match id:
		"hint":  return GameData.hint_tokens
		"boost": return GameData.coin_boost
	return -1

func _buy_item(it: Dictionary) -> void:
	var cost := int(it["cost"])
	if not GameData.spend_coins(cost):
		Sound.play("wrong")
		Toast.show_toast("金币不足，去闯关赚金币吧！")
		return
	match str(it["id"]):
		"exp":    GameData.add_exp(80)
		"hint":   GameData.add_hint_tokens(1)
		"hint3":  GameData.add_hint_tokens(3)
		"boost":  GameData.add_coin_boosts(1)
		"boost3": GameData.add_coin_boosts(3)
		"pet":    GameData.add_pet_fed()
	Sound.play("unlock")
	Toast.show_toast("已购入 · %s" % str(it["name"]))
