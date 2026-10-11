extends Control
## 用户登录 / 注册：本地多用户 + 头像选择。

var _mode := "list"        # list / create
var _sel_avatar := "player"
var _name_edit: LineEdit
var _body: Control
var _err := ""

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build()
	_add_pet()
	GameData.progress_changed.connect(func() -> void: _build())

func _add_pet() -> void:
	var pet := Pet.spawn(self)
	pet.position = Vector2(60.0, get_viewport_rect().size.y - 220.0)
	if not GameData.pet_greeted_session:
		GameData.pet_greeted_session = true
		pet.clingy()
	else:
		pet.say("欢迎回来！选一个档案开始吧～", 3.5)

func _avatar_tex(av_id: String, px: int) -> Texture2D:
	var info: Dictionary = GameData.avatar_info(av_id)
	return UI.icon(str(info["icon"]), px, Color(str(info["color"])))

func _build() -> void:
	for c in get_children():
		if (c is TechBg) or (c is Pet) or (c is CanvasLayer):
			continue
		c.queue_free()
	var center := CenterContainer.new()
	UI.full_rect(center)
	add_child(center)
	var panel := UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.35), 16, 28, Color(UI.COL_ACCENT, 0.22))
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var mark := BrandMark.new()
	mark.custom_minimum_size = Vector2(104, 104)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(mark)

	var title := UI.make_label("衍 数 阁", 40, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", UI.title_font())
	UI.outlined(title, 4, Color(0, 0, 0, 0.4))
	vb.add_child(title)
	vb.add_child(UI.make_label("选择档案进入 · 或新建推演者", 15, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var line := BrandMark.Underline.new()
	line.custom_minimum_size = Vector2(120, 3)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(line)
	vb.add_child(_gap(6))

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	vb.add_child(_body)

	if _mode == "list":
		_build_list()
	else:
		_build_create()

	var quit := UI.ghost_button("退出", func() -> void:
		UI.confirm(self, "退出游戏", "确定要退出吗？", func() -> void: get_tree().quit())
	, 14)
	quit.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	quit.offset_left = -132
	quit.offset_right = -20
	quit.offset_top = 16
	quit.offset_bottom = 56
	add_child(quit)

	var setb := UI.ghost_button("设置", func() -> void:
		Sound.play("select")
		Scene.goto("res://scenes/Settings.tscn")
	, 14)
	setb.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	setb.offset_left = -252
	setb.offset_right = -148
	setb.offset_top = 16
	setb.offset_bottom = 56
	add_child(setb)

	UI.fade_in(panel, 0.4)
	UI.stagger_in(_body, 0.05, 0.28)

func _build_list() -> void:
	var list := GameData.list_users()
	if list.is_empty():
		_body.add_child(UI.make_label("还没有用户，请新建一位推演者。", 16, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		for u in list:
			_body.add_child(_user_card(u))
	_body.add_child(_gap(6))
	var row := CenterContainer.new()
	_body.add_child(row)
	var nb := Button.new()
	nb.text = "＋ 新建用户"
	nb.custom_minimum_size = Vector2(220, 52)
	UI.primary_button(nb)
	nb.pressed.connect(func() -> void:
		_mode = "create"
		_err = ""
		_build()
	)
	row.add_child(nb)
	if _err != "":
		_body.add_child(UI.make_label(_err, 14, UI.COL_DANGER, HORIZONTAL_ALIGNMENT_CENTER))

func _user_card(u: Dictionary) -> Control:
	var p := UI.card(false, UI.COL_ACCENT, Color(1, 1, 1, 0.05), Color(UI.COL_ACCENT, 0.3), 12, 14)
	p.custom_minimum_size = Vector2(700, 0)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	p.add_child(hb)
	var av := TextureRect.new()
	av.texture = _avatar_tex(str(u["avatar"]), 56)
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av.custom_minimum_size = Vector2(56, 56)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(av)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(col)
	col.add_child(UI.make_label(str(u["name"]), 20, UI.COL_TEXT))
	col.add_child(UI.mono_label("★ %d" % int(u["stars"]), 14, UI.COL_ACCENT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	var del := UI.ghost_button("删除", func() -> void: _on_delete(str(u["name"])), 14)
	hb.add_child(del)
	var enter := Button.new()
	enter.text = "登录 →"
	enter.custom_minimum_size = Vector2(140, 48)
	UI.primary_button(enter)
	enter.pressed.connect(func() -> void: _on_login(str(u["name"])))
	hb.add_child(enter)
	return p

func _build_create() -> void:
	_body.add_child(UI.make_label("用户名", 15, UI.COL_TEXT_DIM))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "输入用户名(如：小明)"
	_name_edit.max_length = 12
	_name_edit.custom_minimum_size = Vector2(0, 50)
	_name_edit.add_theme_font_size_override("font_size", UI.fs(19))
	_name_edit.add_theme_color_override("font_color", UI.COL_TEXT)
	_name_edit.add_theme_color_override("font_placeholder_color", Color(UI.COL_TEXT_DIM, 0.7))
	_name_edit.add_theme_color_override("caret_color", UI.COL_ACCENT)
	_name_edit.add_theme_stylebox_override("normal", UI.glass_box(Color(0, 0, 0, 0.3), 10, Color(1, 1, 1, 0.16), 1, 10))
	_name_edit.add_theme_stylebox_override("focus", UI.glass_box(Color(0, 0, 0, 0.3), 10, Color(UI.COL_ACCENT, 0.6), 1, 10))
	_name_edit.text_submitted.connect(func(_t: String) -> void: _on_create())
	_body.add_child(_name_edit)

	_body.add_child(UI.make_label("选择头像", 15, UI.COL_TEXT_DIM))
	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 10)
	_body.add_child(grid)
	for a in GameData.AVATARS:
		var id := str(a["id"])
		var box := Control.new()
		box.custom_minimum_size = Vector2(72, 72)
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.05), 12, Color(str(a["color"]), 0.9 if id == _sel_avatar else 0.25), 2 if id == _sel_avatar else 1, 6))
		UI.full_rect(p)
		box.add_child(p)
		var tex_r := TextureRect.new()
		tex_r.texture = _avatar_tex(id, 48)
		tex_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_r.custom_minimum_size = Vector2(48, 48)
		tex_r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(tex_r)
		var btn := Button.new()
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.add_theme_stylebox_override("normal", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
		btn.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.08), 12, Color(UI.COL_ACCENT, 0.5), 1, 0))
		btn.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.25), 12, Color(UI.COL_ACCENT, 0.8), 1, 0))
		btn.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
		btn.pressed.connect(func() -> void:
			_sel_avatar = id
			_build()
		)
		box.add_child(btn)
		grid.add_child(box)

	if _err != "":
		_body.add_child(UI.make_label(_err, 14, UI.COL_DANGER, HORIZONTAL_ALIGNMENT_CENTER))

	_body.add_child(_gap(4))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	_body.add_child(row)
	row.add_child(UI.ghost_button("← 返回", func() -> void:
		_mode = "list"
		_err = ""
		_build()
	, 16))
	var cb := Button.new()
	cb.text = "创建并登录"
	cb.custom_minimum_size = Vector2(200, 52)
	UI.primary_button(cb)
	cb.pressed.connect(_on_create)
	row.add_child(cb)

func _on_login(nm: String) -> void:
	if GameData.login(nm):
		Sound.play("begin")
		Scene.goto("res://scenes/MainHub.tscn")
	else:
		_err = "登录失败：用户不存在"
		_build()

func _on_create() -> void:
	var nm := _name_edit.text if _name_edit != null else ""
	if not GameData.create_user(nm, _sel_avatar):
		_err = "用户名不能为空或已存在"
		_build()
		return
	Sound.play("begin")
	Scene.goto("res://scenes/MainHub.tscn")

func _on_delete(nm: String) -> void:
	GameData.delete_user(nm)
	Sound.play("select")
	_build()

func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
