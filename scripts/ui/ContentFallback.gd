class_name ContentFallback
## A18：内容数据异常时的**用户可见兜底**——不再静默空白页。
##
## 回答三件事：发生了什么（人话）+ 出在哪（位置）+ 怎么办（重试 / 复制错误信息）。
## 隐私：错误详情只写进用户自己的剪贴板，**不联网、不上传**（与 F1 策略一致），
## 发不发由用户自己决定；详情里只有内容结构信息，不含任何作答数据。

# ---------------------------------------------------------------- 卡片
## 兜底卡：完整说明 + 明细 + 动作。
static func card(problems: Array, on_retry: Callable, on_copy: Callable) -> Control:
	var card := UI.card(true, UI.COL_DANGER, UI.COL_GLASS, Color(UI.COL_DANGER, 0.35), 14, 22, Color(UI.COL_DANGER, 0.16))
	card.custom_minimum_size = Vector2(UiConst.CARD_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)

	box.add_child(UI.make_label("内容数据加载失败", 21, UI.COL_TEXT))
	var tip := UI.make_label("知识点体系暂时无法显示。下面是具体原因——重试即可恢复；仍不行就把详情发给开发者。", 14, UI.COL_TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	box.add_child(list)
	var shown := 0
	for p in problems:
		if shown >= 5:
			break
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = p
		list.add_child(UI.mono_label("[%s] %s · %s" % [
			str(d.get("code", "")), str(d.get("message", "")), str(d.get("where", ""))], 12, UI.COL_DANGER))
		shown += 1
	if shown == 0:
		list.add_child(UI.make_label("（没有更具体的信息）", 13, UI.COL_TEXT_DIM))
	if problems.size() > shown:
		list.add_child(UI.mono_label("……另有 %d 处同类问题" % (problems.size() - shown), 12, UI.COL_TEXT_DIM))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	row.add_child(UI.ghost_button("重试加载", on_retry, 14))
	row.add_child(UI.ghost_button("复制错误信息", on_copy, 14))
	box.add_child(UI.make_label("错误详情只写到你自己的剪贴板，不联网、不上传。", 12, UI.COL_TEXT_DIM))
	return card

## 紧凑横幅（主城顶部用）：一句说明 + 重试，不喧宾夺主。
static func banner() -> Control:
	var card := UI.card(true, UI.COL_DANGER, UI.COL_GLASS, Color(UI.COL_DANGER, 0.3), 12, 16, Color(UI.COL_DANGER, 0.12))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	card.add_child(hb)
	var lbl := UI.make_label("⚠ 内容数据异常：%s" % _short(), 13, UI.COL_TEXT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl)
	hb.add_child(UI.ghost_button("重试", func() -> void:
		Sound.play("select")
		if GameData.reload_content():
			Toast.show_toast("内容数据已恢复")
			Scene.goto("res://scenes/MainHub.tscn")
		else:
			Toast.show_toast("仍然无法加载：" + _short())
	, 13))
	return card

# ---------------------------------------------------------------- 铺页
## 在 root 里铺一张兜底卡（自带滚动容器）——替代原本的空白页。
static func fill(root: Control, top: int = 84) -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = top
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	UI.enable_touch_scroll(scroll)
	UI.style_scrollbar(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(box)
	box.add_child(card(GameData.content_problems,
		func() -> void: _retry(root),
		func() -> void: _copy()))

# ---------------------------------------------------------------- 工具
## 复制到剪贴板的详情（只有内容结构信息，不含任何作答数据）。
static func detail_text(problems: Array) -> String:
	var lines := ["MathGates 内容数据异常"]
	lines.append("时间：%s" % Time.get_datetime_string_from_system(false, true))
	lines.append("问题数：%d" % problems.size())
	lines.append("（仅本机生成，不联网、不上传）")
	for p in problems:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = p
		lines.append("[%s] %s（%s）" % [
			str(d.get("code", "")), str(d.get("message", "")), str(d.get("where", ""))])
	return "\n".join(lines)

## 一行短说明（横幅用，最多 24 字）。
static func _short() -> String:
	var s := ContentHealth.describe(GameData.content_problems)
	if s.length() > 24:
		s = s.substr(0, 24) + "…"
	return s

static func _retry(root: Control) -> void:
	Sound.play("select")
	if GameData.reload_content():
		Toast.show_toast("内容数据已恢复")
		Scene.goto("res://scenes/MainHub.tscn")
		return
	Toast.show_toast("仍然无法加载：" + _short())

static func _copy() -> void:
	Sound.play("select")
	DisplayServer.clipboard_set(detail_text(GameData.content_problems))
	Toast.show_toast("错误详情已复制到剪贴板")
