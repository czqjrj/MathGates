class_name GuideOverlay
extends RefCounted
## F6：首次引导与机制说明的界面层（数据在 `scripts/rules/GuideRules.gd`）。
##
## 三个入口：
## - `first_level(root, on_done)`：第一关的 3~4 步气泡（拖动 → 提交 → 看解析 → 拿星）；
## - `legend(root, on_done)`：地图页图例（Boss 门 / 宝箱 / 随机事件 / 支线）；
## - `help(root, title, text)`：随时回看的「? 帮助」面板（纯展示，不改状态）。
##
## 引导是**表意内容**：即使关掉「界面动效」，文字照常显示，只弱化入场动画
## （`UI.fx_on()` 为假时直接显示，不播放大位移/回弹）。

## 第一关气泡引导：逐条显示，最后一步给「开始闯关」。
## root 一般为关卡场景根节点；on_done 在用户走完或跳过时调用（用于记录已看过）。
static func first_level(root: Node, on_done: Callable = Callable()) -> void:
	_steps(root, GuideRules.first_level_steps(), on_done)

## 地图页图例：一张卡列出四条机制说明，底部「开始探索」。
static func legend(root: Node, on_done: Callable = Callable()) -> void:
	var body := GuideRules.legend_text()
	_panel(root, "地图上的四种标记", body, "开始探索", on_done)

## 随时回看的帮助：标题 + 正文，只有一个「知道了」。
static func help(root: Node, title: String, text: String) -> void:
	_panel(root, title, text, "知道了", Callable())

# ---------------------------------------------------------------- 内部
## 多步气泡：遮罩 + 居中卡片，一步一屏，「下一步 / 跳过」。
static func _steps(root: Node, steps: Array, on_done: Callable) -> void:
	if steps.is_empty():
		if on_done.is_valid():
			on_done.call()
		return
	var dim := _dim(root)
	# 用数组做可变状态，避免 lambda 自引用(GDScript 不允许内部函数引用尚未声明的自身)
	var st := { "idx": 0, "holder": null }
	_show_step(root, dim, steps, st, on_done)

## 显示第 st.idx 步；调用方负责先清掉上一步的卡片。
static func _show_step(root: Node, dim: Control, steps: Array, st: Dictionary, on_done: Callable) -> void:
	if is_instance_valid(st["holder"]):
		(st["holder"] as Node).queue_free()
	if int(st["idx"]) >= steps.size():
		_finish(dim, on_done)
		return
	var s: Dictionary = steps[int(st["idx"])]
	st["idx"] = int(st["idx"]) + 1
	var card := _step_card(int(st["idx"]), steps.size(), s,
		func() -> void: _show_step(root, dim, steps, st, on_done),
		func() -> void: _finish(dim, on_done))
	st["holder"] = card
	dim.add_child(card)

## 单步卡片：序号 + 标题 + 正文 + 「下一步」(最后一步为「开始闯关」) + 「跳过」。
static func _step_card(step_no: int, total: int, s: Dictionary,
		on_next: Callable, on_skip: Callable) -> Control:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP

	var pan := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.42), 16, 26, Color(UI.COL_ACCENT, 0.18))
	pan.custom_minimum_size = Vector2(600.0 * UI.S, 0)
	center.add_child(pan)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	pan.add_child(vb)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	vb.add_child(head)
	head.add_child(UI.mono_label("引导 %d / %d" % [step_no, total], 13, Color(UI.COL_ACCENT, 0.85)))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.ghost_button("跳过", func() -> void: on_skip.call(), 14))

	vb.add_child(UI.make_label(str(s.get("title", "")), 26, UI.COL_TEXT))
	var body := UI.make_label(str(s.get("body", "")), 17, UI.COL_TEXT_DIM)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(520.0 * UI.S, 0)
	vb.add_child(body)

	var last := step_no >= total
	var ok := Button.new()
	ok.text = "开始闯关" if last else "下一步 →"
	ok.custom_minimum_size = Vector2(180, 52)
	UI.primary_button(ok)
	ok.pressed.connect(func() -> void: on_next.call())
	vb.add_child(ok)

	_maybe_popup(center)
	return center

## 单屏面板（图例 / 帮助）：标题 + 多行正文 + 一个确认按钮。
static func _panel(root: Node, title: String, body_text: String, ok_text: String, on_done: Callable) -> void:
	var dim := _dim(root)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.add_child(center)

	var pan := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.42), 16, 26, Color(UI.COL_ACCENT, 0.18))
	pan.custom_minimum_size = Vector2(640.0 * UI.S, 0)
	center.add_child(pan)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	pan.add_child(vb)
	vb.add_child(UI.make_label(title, 26, UI.COL_TEXT))
	var body := UI.make_label(body_text, 16, UI.COL_TEXT_DIM)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(580.0 * UI.S, 0)
	vb.add_child(body)
	var ok := Button.new()
	ok.text = ok_text
	ok.custom_minimum_size = Vector2(180, 52)
	UI.primary_button(ok)
	ok.pressed.connect(func() -> void: _finish(dim, on_done))
	vb.add_child(ok)

	_maybe_popup(center)

## 半透明遮罩层（拦截点击，防止穿透到下层界面）。
static func _dim(root: Node) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	return dim

## 引导关闭：移除遮罩并回调。回调用于记录「已看过」（写 Settings）。
static func _finish(dim: Control, on_done: Callable) -> void:
	if is_instance_valid(dim):
		dim.queue_free()
	if on_done.is_valid():
		on_done.call()

## 入场动画：只在动效开启时播放，引导文字本身不受「界面动效」开关影响。
static func _maybe_popup(c: Control) -> void:
	if UI.fx_on():
		UI.popup_in(c)
