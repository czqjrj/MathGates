extends Control
## 设置页 · 统一配置字号 / 音效 / 萌宠 / 全屏 / 界面动效。
## 所有项即时写入 Settings(自动持久化)；字号变更会重建本页以刷新整体布局。

const RETURN_DEFAULT := "res://scenes/MainHub.tscn"

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build_topbar()
	_build_body()

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
	hb.add_child(UI.ghost_button("← 返回", _go_back))
	hb.add_child(UI.hairline(Vector2(1, 18)))
	hb.add_child(UI.make_label("设置", 22))
	hb.add_child(UI.mono_label("SETTINGS", 13, Color(UI.COL_TEXT_DIM, 0.7)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	hb.add_child(UI.ghost_button("恢复默认", _on_reset, 14))

func _build_body() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 72
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	UI.enable_touch_scroll(scroll)
	UI.style_scrollbar(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var panel := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.32), 16, 26, Color(UI.COL_ACCENT, 0.18))
	panel.custom_minimum_size = Vector2(820, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	panel.add_child(vb)

	vb.add_child(UI.mono_label("可配置项", 13, Color(UI.COL_ACCENT, 0.8)))
	vb.add_child(_divider())
	vb.add_child(_textbook_row())
	vb.add_child(_divider())
	vb.add_child(_font_row())
	vb.add_child(_divider())
	vb.add_child(_volume_row())
	vb.add_child(_divider())
	vb.add_child(_voice_row())
	vb.add_child(_divider())
	vb.add_child(_toggle_row("萌宠助手", "主界面右下角的互动小助手", Settings.show_pet, Settings.set_show_pet))
	vb.add_child(_toggle_row("全屏显示", "以全屏方式运行(移动端忽略此项)", Settings.fullscreen, Settings.set_fullscreen))
	vb.add_child(_toggle_row("界面动效", "卡片入场、按钮回弹等过渡动画", Settings.animations, Settings.set_animations))
	vb.add_child(_divider())
	vb.add_child(UI.make_label("提示：调整字号后会自动重建当前页面以应用新的整体布局。", 13, UI.COL_TEXT_DIM))

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 20)
	vb.add_child(pad)

	UI.stagger_in(vb, 0.03, 0.24, 12)

func _textbook_row() -> Control:
	var items: Array = []
	for v in GameData.textbook_list():
		items.append([str(v.get("id", "")), str(v.get("title", ""))])
	if items.is_empty():
		items = [["sujiao", "苏教版"]]
	var box := _opt_row("教材版本", items, Settings.textbook, func(v: String) -> void:
		Settings.set_textbook(v)
		Sound.play("select")
		Toast.show_toast("已切换教材版本 · %s" % GameData.textbook_title(v))
		get_tree().reload_current_scene()
	)
	var sub := "调整知识体系与方法推演的章节顺序、分册与章号，并重置自定义排序。"
	var d := GameData.textbook_def(Settings.textbook)
	if not d.is_empty() and str(d.get("subtitle", "")) != "":
		sub = str(d["subtitle"]) + " · " + sub
	box.add_child(UI.make_label(sub, 13, UI.COL_TEXT_DIM))
	return box

func _font_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	head.add_child(UI.make_label("字号大小", 18, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var val := UI.mono_label("%.1f×" % Settings.font_scale, 16, UI.COL_ACCENT)
	head.add_child(val)

	var slider := HSlider.new()
	slider.min_value = Settings.FONT_MIN
	slider.max_value = Settings.FONT_MAX
	slider.step = Settings.FONT_STEP
	slider.value = Settings.font_scale
	slider.custom_minimum_size = Vector2(0, 26)
	box.add_child(slider)

	var preview := UI.make_label("示例：把每个知识点点亮 · ABC 1024", 20, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(preview)

	slider.value_changed.connect(func(v: float) -> void:
		Settings.set_font_scale(v)
		val.text = "%.1f×" % v
		preview.add_theme_font_size_override("font_size", UI.fs(20))
	)
	# 松开滑块后再重建本页，让整个界面应用新字号(拖动中重建会打断操作)
	slider.drag_ended.connect(func(changed: bool) -> void:
		if changed:
			get_tree().reload_current_scene()
	)
	return box

func _volume_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	head.add_child(UI.make_label("音效音量", 18, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var val := UI.mono_label("%d%%" % int(round(Settings.sfx_volume * 100.0)), 16, UI.COL_ACCENT)
	head.add_child(val)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Settings.sfx_volume
	slider.custom_minimum_size = Vector2(0, 26)
	box.add_child(slider)

	slider.value_changed.connect(func(v: float) -> void:
		Settings.set_sfx_volume(v)
		val.text = "%d%%" % int(round(v * 100.0))
	)
	slider.drag_ended.connect(func(changed: bool) -> void:
		if changed:
			Sound.play("select")
	)
	return box

func _voice_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var online := Settings.tts_engine == "online"
	var sub := "用在线神经语音朗读题干、解析与提示（需联网）" if online else "用系统语音朗读题干、解析与提示"
	if not online and not UI.tts_available():
		sub = "当前设备没有可用的系统语音，可在上方切换为在线语音"
	box.add_child(_toggle_row("语音朗读", sub, Settings.voice, Settings.set_voice))

	# 语音引擎
	box.add_child(_opt_row("语音引擎", [
		["online", "在线语音（百度 / 有道 · 音质更好）"],
		["system", "系统语音（离线 · 音质一般）"],
	], Settings.tts_engine, func(v: String) -> void:
		Settings.set_tts_engine(v)
		get_tree().reload_current_scene()
	))

	# 音源 / 音色(随引擎变化)
	if online:
		box.add_child(_opt_row("在线音源", [
			["baidu", "百度语音"],
			["youdao", "有道语音"],
		], Settings.tts_provider, func(v: String) -> void:
			Settings.set_tts_provider(v)
			if Settings.voice:
				UI.tts_say("这是在线音源的朗读示例。", true)
		))
	else:
		box.add_child(_voice_pick_row())

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	head.add_child(UI.make_label("朗读语速", 16, UI.COL_TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var val := UI.mono_label("%.1f×" % Settings.voice_rate, 16, UI.COL_ACCENT)
	head.add_child(val)

	var slider := HSlider.new()
	slider.min_value = 0.5
	slider.max_value = 1.8
	slider.step = 0.1
	slider.value = Settings.voice_rate
	slider.custom_minimum_size = Vector2(0, 26)
	slider.editable = UI.tts_available()
	box.add_child(slider)
	slider.value_changed.connect(func(v: float) -> void:
		Settings.set_voice_rate(v)
		val.text = "%.1f×" % v
	)
	slider.drag_ended.connect(func(changed: bool) -> void:
		if changed and Settings.voice:
			UI.tts_say("这是当前语速的朗读示例。", true)
	)
	return box

func _voice_pick_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(UI.make_label("朗读音色", 16, UI.COL_TEXT))

	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(0, 46)
	opt.focus_mode = Control.FOCUS_NONE
	opt.add_theme_font_size_override("font_size", UI.fs(16))
	opt.add_theme_stylebox_override("normal", UI.stylebox(Color(1, 1, 1, 0.03), 12, UI.COL_LINE, 1, 16))
	opt.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.07), 12, Color(UI.COL_ACCENT, 0.5), 1, 16))
	opt.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.25), 12, UI.COL_ACCENT, 1, 16))
	opt.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, Color(UI.COL_ACCENT, 0.3), 1, 16))
	opt.add_theme_color_override("font_color", UI.COL_TEXT)
	opt.add_theme_color_override("font_hover_color", UI.COL_TEXT)

	# 首项为“自动选择”，其余按系统可用声线列出。
	opt.add_item("自动选择（推荐用萌宠音色）")
	opt.set_item_metadata(0, "")
	var voices := UI.tts_list_voices()
	var sel := 0
	for i in voices.size():
		var v: Dictionary = voices[i]
		var nm := str(v.get("name", ""))
		var lg := str(v.get("language", ""))
		opt.add_item(("%s（%s）" % [nm, lg]) if lg != "" else nm)
		var vid := str(v.get("id", ""))
		opt.set_item_metadata(i + 1, vid)
		if vid == Settings.voice_id:
			sel = i + 1
	opt.select(sel)
	opt.disabled = not UI.tts_available()
	opt.item_selected.connect(func(i: int) -> void:
		var vid := str(opt.get_item_metadata(i))
		Settings.set_voice_id(vid)
		if Settings.voice and UI.tts_available():
			var nm := str(opt.get_item_text(i)).split("（")[0]
			UI.tts_say("你好，我是%s，以后由我来朗读。" % nm, true)
	)
	box.add_child(opt)
	return box

func _opt_row(title: String, items: Array, current: String, on_change: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(UI.make_label(title, 16, UI.COL_TEXT))

	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(0, 46)
	opt.focus_mode = Control.FOCUS_NONE
	opt.add_theme_font_size_override("font_size", UI.fs(16))
	opt.add_theme_stylebox_override("normal", UI.stylebox(Color(1, 1, 1, 0.03), 12, UI.COL_LINE, 1, 16))
	opt.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.07), 12, Color(UI.COL_ACCENT, 0.5), 1, 16))
	opt.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.25), 12, UI.COL_ACCENT, 1, 16))
	opt.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, Color(UI.COL_ACCENT, 0.3), 1, 16))
	opt.add_theme_color_override("font_color", UI.COL_TEXT)
	opt.add_theme_color_override("font_hover_color", UI.COL_TEXT)
	var sel := 0
	for i in items.size():
		var it: Array = items[i]
		opt.add_item(str(it[1]))
		opt.set_item_metadata(i, str(it[0]))
		if str(it[0]) == current:
			sel = i
	opt.select(sel)
	opt.item_selected.connect(func(i: int) -> void:
		on_change.call(str(opt.get_item_metadata(i)))
	)
	box.add_child(opt)
	return box

func _toggle_row(title: String, sub: String, value: bool, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(col)
	col.add_child(UI.make_label(title, 18, UI.COL_TEXT))
	col.add_child(UI.make_label(sub, 13, UI.COL_TEXT_DIM))

	var btn := Button.new()
	btn.toggle_mode = true
	btn.button_pressed = value
	btn.text = "开启" if value else "关闭"
	btn.custom_minimum_size = Vector2(132, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_stylebox_override("normal", UI.stylebox(Color(1, 1, 1, 0.03), 12, UI.COL_LINE, 1, 16))
	btn.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.07), 12, Color(UI.COL_ACCENT, 0.5), 1, 16))
	btn.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, Color(UI.COL_ACCENT, 0.3), 1, 16))
	btn.add_theme_stylebox_override("pressed", UI.glass_box(Color(UI.COL_ACCENT, 0.22), 12, UI.COL_ACCENT, 1, 16, Color(UI.COL_ACCENT, 0.3), 12))
	btn.add_theme_color_override("font_color", UI.COL_TEXT_DIM)
	btn.add_theme_color_override("font_hover_color", UI.COL_TEXT)
	btn.add_theme_color_override("font_pressed_color", UI.COL_ACCENT)
	btn.add_theme_color_override("font_hover_pressed_color", UI.COL_ACCENT)
	UI.press_fx(btn, 0.96)
	btn.toggled.connect(func(on: bool) -> void:
		btn.text = "开启" if on else "关闭"
		on_change.call(on)
	)
	row.add_child(btn)
	return row

func _go_back() -> void:
	Sound.play("select")
	var back := Scene.previous
	if back.is_empty() or back == scene_file_path:
		back = RETURN_DEFAULT
	Scene.goto(back)

func _on_reset() -> void:
	UI.confirm(self, "恢复默认设置", "教材版本、字号、音效、语音、萌宠、全屏、动效将重置为默认值。", func() -> void:
		Settings.reset_defaults()
		Sound.play("select")
		get_tree().reload_current_scene()
	)

func _divider() -> Control:
	var r := ColorRect.new()
	r.color = UI.COL_LINE
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
