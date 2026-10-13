extends Node3D
## 立体几何 · 方法闯关(整合自 SolidGeometryDemo，统一极简未来科技风)
## 从世界地图进入：按 GameData.current_level["method"] 载入对应方法的三维模型与关卡。

const METHODS_PATH := "res://data/solid_methods.json"
## 相对原演示的取景缩放(为右侧留出 UI 空间并把整体收进 720p 画面)
const CAM_ZOOM := 1.42
## 公式图片统一显示比例：所有公式同 DPI 渲染，按同一比例缩放才能保证字号一致
const FORMULA_SCALE := 0.46

const SKY_SHADER := """
shader_type sky;

uniform vec3 c_top : source_color = vec3(0.02, 0.032, 0.062);
uniform vec3 c_bottom : source_color = vec3(0.05, 0.09, 0.16);
uniform vec3 accent : source_color = vec3(0.369, 0.902, 1.0);
uniform float time = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 col = mix(c_bottom, c_top, pow(h, 0.8));

	// 漂移极光辉光
	vec2 p1 = vec2(-0.45 + 0.25 * sin(time * 0.05), -0.2 + 0.2 * cos(time * 0.04));
	float a1 = exp(-length(d.xz - p1) * 2.2);
	col += accent * 0.13 * a1;

	vec2 p2 = vec2(0.5 + 0.2 * cos(time * 0.045 + 1.7), 0.35 + 0.18 * sin(time * 0.035 + 0.9));
	float a2 = exp(-length(d.xz - p2) * 2.8);
	col += accent * 0.09 * a2;

	// 地平线光带
	col += accent * 0.10 * exp(-abs(d.y) * 6.5);

	// 星点
	vec2 sp = floor(d.xz * 220.0 + vec2(0.0, d.y * 90.0));
	float st = step(0.9987, hash(sp + floor(time * 0.4)));
	col += vec3(st) * 0.5 * smoothstep(0.0, 0.25, abs(d.y));

	COLOR = vec3(col);
}
"""

var _methods: Dictionary = {}
var _method_id := "complement"
var _cfg: Dictionary = {}
var _stages: Array = []
var _zoom := CAM_ZOOM
var _topic: Node3D

var _camera: Camera3D
var _sky_mat: ShaderMaterial
var _t := 0.0
var _frames := 0

var cam_target := Vector3.ZERO
var cam_goal := Vector3.ZERO
var cam_yaw := 0.0
var cam_yaw_goal := 0.0
var cam_pitch := 0.3
var cam_pitch_goal := 0.3
var cam_dist := 15.0
var cam_dist_goal := 15.0
var dragging := false

var _idx := 0
var _reveal := 0.0
var _target_reveal := 0.0
var _wrongs := 0
var _hint_used := false
var _solved := false
var _done := false
var _clean: Array[int] = []
var _picked: Array[int] = []
var _pick_indices: Array[int] = []
var _hi_mat: StandardMaterial3D

var _ui_root: Control
var _top_fill: ColorRect
var _prog_lbl: Label
var _hud_lbl: Label
var _panel: PanelContainer
var _bottombar: PanelContainer
var _panel_title: Label
var _q_lbl: RichTextLabel
var _formula_tex: TextureRect
var _feed: Label
var _ans_box: VBoxContainer
var _opt_btns: Array[Button] = []
var _opt_panels: Array[PanelContainer] = []
var _opt_badges: Array[PanelContainer] = []
var _opt_contents: Array[Control] = []
var _opt_marks: Array[Label] = []
var _btn_hint: Button
var _btn_next: Button
var _btn_restart: Button
var _input_edit: LineEdit
var _victory: PanelContainer
var _v_star_row: HBoxContainer
var _v_rate: Label
var _v_score: Label
var _v_coins: Label
var _coin_lbl: Label
var _dim: ColorRect
var _nav_prev: Button
var _nav_next: Button
var _pet: Pet

func _ready() -> void:
	_load_config()
	_build_env()
	_load_topic()
	_build_camera()
	_build_ui()
	_reset(true)
	update_camera(1000.0)
	_pet = Pet.spawn(self, "立体几何：先看图形，再作答！")
	_pet.tap_provider = _pet_point

func _load_config() -> void:
	if FileAccess.file_exists(METHODS_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(METHODS_PATH))
		if typeof(data) == TYPE_DICTIONARY:
			_methods = data.get("methods", {})
	var lv: Dictionary = GameData.current_level
	if lv.has("method"):
		_method_id = str(lv["method"])
	if not _methods.has(_method_id):
		_method_id = "complement" if _methods.has("complement") else str(_methods.keys()[0] if _methods.size() > 0 else "")
	if _methods.has(_method_id):
		_cfg = _methods[_method_id]
		_stages = _cfg.get("levels", [])
		_zoom = float(_cfg.get("zoom", CAM_ZOOM))

func _pet_point() -> String:
	var title := str(_cfg.get("title", "立体几何"))
	var summary := str(_cfg.get("summary", ""))
	var hint := ""
	if not _stages.is_empty():
		hint = str(_stages[clampi(_idx, 0, _stages.size() - 1)].get("hint", ""))
	if hint != "":
		return "【%s】%s\n提示：%s" % [title, summary, hint]
	return "【%s】%s" % [title, summary]

func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SKY_SHADER
	_sky_mat.shader = sh
	sky.sky_material = _sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.72, 0.95)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var dir := DirectionalLight3D.new()
	dir.rotation_degrees = Vector3(-52, -58, 0)
	dir.light_energy = 1.5
	dir.light_color = Color(0.9, 0.95, 1.0)
	dir.shadow_enabled = true
	dir.position = Vector3(2, 9, 2)
	add_child(dir)

func _load_topic() -> void:
	var path := str(_cfg.get("topic", ""))
	var scr := load(path) as GDScript
	if scr == null:
		return
	_topic = scr.new() as Node3D
	_topic.ui_font = UI.font()
	add_child(_topic)
	_topic.build()

	_hi_mat = StandardMaterial3D.new()
	_hi_mat.albedo_color = Color("#5ee6ff")
	_hi_mat.emission_enabled = true
	_hi_mat.emission = Color("#2ad2ff")
	_hi_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# 拾取：找出以原点顶点为端点的棱
	var verts = _topic.get("P")
	var origin_letter := ""
	if verts is Dictionary:
		var best := 1e9
		for k in verts.keys():
			var l: float = (verts[k] as Vector3).length()
			if l < best:
				best = l
				origin_letter = str(k)
	var edges = _topic.get("EDGES")
	if edges is Array:
		for j in edges.size():
			var e = edges[j]
			if str(e[0]) == origin_letter or str(e[1]) == origin_letter:
				_pick_indices.append(j)

func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 22.0
	_camera.near = 0.02
	_camera.far = 2000.0
	add_child(_camera)
	if _topic == null or _topic.STEPS.is_empty():
		return
	var st: Dictionary = _topic.STEPS[0]
	if st.has("yaw"):
		cam_yaw = st["yaw"]
		cam_pitch = st["pitch"]
		cam_dist = st["dist"] * _zoom * _region_fit()
		cam_target = _mv(st["focus"])
	cam_yaw_goal = cam_yaw
	cam_pitch_goal = cam_pitch
	cam_dist_goal = cam_dist
	cam_goal = cam_target

func _mv(v: Vector3) -> Vector3:
	return Vector3(v.x, v.z, v.y)

## 三维主体与左侧任务面板的比例适配系数：面板越宽(右侧图形区越窄)，
## 越要拉远镜头让主体整体落入右侧区域，避免图像左溢出到文字面板上。
func _region_fit() -> float:
	var sw := maxf(get_viewport().get_visible_rect().size.x, 1.0)
	var region_left := float(UI.stage_layout()["view_left"])
	var region_w := maxf(sw - region_left, 1.0)
	return clampf(sw / region_w, 1.0, 1.4)

# ---------------------------------------------------------------- 流程
func _reset(animated: bool) -> void:
	_idx = 0
	_wrongs = 0
	_hint_used = false
	_solved = false
	_done = false
	_picked.clear()
	_clean.clear()
	for i in _stages.size():
		_clean.append(0)
	_reveal = 0.0 if animated else _reveal_of(0)
	_target_reveal = _reveal_of(0)
	_clear_highlights()
	_cam_to_stage(0)
	if _victory != null:
		_victory.visible = false
	if _dim != null:
		_dim.visible = false
	_rebuild()
	_update_hud()

func _reveal_of(i: int) -> float:
	if _stages.is_empty():
		return 0.0
	var s: Dictionary = _stages[clampi(i, 0, _stages.size() - 1)]
	return float(s.get("reveal", 0.0))

func _cam_to_stage(i: int) -> void:
	if _topic == null or _topic.STEPS.is_empty():
		return
	var step_i := i
	var z := _zoom
	if not _stages.is_empty():
		var lvl: Dictionary = _stages[clampi(i, 0, _stages.size() - 1)]
		step_i = int(lvl.get("cam_step", i))
		z = float(lvl.get("cam_zoom", _zoom))
	var st: Dictionary = _topic.STEPS[clampi(step_i, 0, _topic.STEPS.size() - 1)]
	if st.has("yaw"):
		cam_yaw_goal = st["yaw"]
		cam_pitch_goal = st["pitch"]
		cam_dist_goal = st["dist"] * z * _region_fit()
		cam_goal = _mv(st["focus"])
		cam_target = cam_goal

func _rebuild() -> void:
	if _stages.is_empty():
		return
	var s: Dictionary = _stages[_idx]
	_solved = false
	_wrongs = 0
	_hint_used = false
	_picked.clear()
	_clear_highlights()
	_panel_title.text = str(s.get("name", ""))
	_q_lbl.text = str(s.get("q", ""))
	UI.tts_say(_q_lbl.text)
	var fpath := str(s.get("formula", ""))
	if fpath != "" and ResourceLoader.exists(fpath):
		var tex := load(fpath) as Texture2D
		_formula_tex.texture = tex
		if tex != null:
			_formula_tex.custom_minimum_size = tex.get_size() * FORMULA_SCALE
		_formula_tex.visible = true
	else:
		_formula_tex.texture = null
		_formula_tex.visible = false
	_feed.text = ""
	_btn_hint.disabled = false
	_btn_next.disabled = true
	_btn_next.text = "下一关 →" if _idx < _stages.size() - 1 else "生成报告"
	for c in _ans_box.get_children():
		c.queue_free()
	_opt_btns.clear()
	_opt_panels.clear()
	_opt_badges.clear()
	_opt_contents.clear()
	_opt_marks.clear()
	_input_edit = null

	match str(s.get("type", "choice")):
		"choice":
			_build_choices(s)
		"input":
			_build_input(s)
		"pick":
			_feed.text = "在右侧三维图中点击高亮的棱。"
		_:
			pass
	_update_hud()

func _build_choices(s: Dictionary) -> void:
	var opts: Array = s.get("opts", [])
	for k in opts.size():
		_ans_box.add_child(_choice_row(k, str(opts[k])))

## 选项行：字母徽章 + 文本或公式图片 + 对错标记；整行覆盖按钮。
func _choice_row(k: int, opt: String) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(0, 58)

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel",
		UI.glass_box(Color(1, 1, 1, 0.04), 12, Color(1, 1, 1, 0.13), 1, 12))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(p)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	p.add_child(hb)

	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel",
		UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(UI.COL_ACCENT, 0.5), 1, 0))
	badge.custom_minimum_size = Vector2(34, 32)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bl := UI.mono_label("ABCD".substr(k, 1), 16, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	hb.add_child(badge)

	var content: Control
	if opt.begins_with("res://") and ResourceLoader.exists(opt):
		var tex := load(opt) as Texture2D
		var tex_r := TextureRect.new()
		tex_r.texture = tex
		tex_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_r.stretch_mode = TextureRect.STRETCH_SCALE
		if tex != null:
			tex_r.custom_minimum_size = tex.get_size() * FORMULA_SCALE
		tex_r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content = tex_r
	else:
		var l := UI.make_label(opt, 18, UI.COL_TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content = l
	hb.add_child(content)

	var mark := UI.make_label("", 20, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	mark.custom_minimum_size = Vector2(26, 0)
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(mark)

	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.set_meta("sfx_click", "none")
	btn.add_theme_stylebox_override("normal", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	btn.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.07), 12, Color(UI.COL_ACCENT, 0.55), 1, 0))
	btn.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.28), 12, Color(UI.COL_ACCENT, 0.8), 1, 0))
	btn.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, Color(UI.COL_ACCENT, 0.3), 1, 0))
	btn.add_theme_stylebox_override("disabled", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	btn.pressed.connect(_on_choice.bind(k))
	box.add_child(btn)

	_opt_btns.append(btn)
	_opt_panels.append(p)
	_opt_badges.append(badge)
	_opt_contents.append(content)
	_opt_marks.append(mark)
	return box

func _reveal_choices(picked: int, correct: int) -> void:
	for i in _opt_btns.size():
		_opt_btns[i].disabled = true
		if i == correct:
			_opt_panels[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(UI.COL_SUCCESS, 0.15), 12, UI.COL_SUCCESS, 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(UI.COL_SUCCESS, 0.35), 8, UI.COL_SUCCESS, 1, 0))
			_opt_marks[i].text = "✓"
			_opt_marks[i].add_theme_color_override("font_color", UI.COL_SUCCESS)
		elif i == picked:
			_opt_panels[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(UI.COL_DANGER, 0.15), 12, UI.COL_DANGER, 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(UI.COL_DANGER, 0.35), 8, UI.COL_DANGER, 1, 0))
			_opt_marks[i].text = "✗"
			_opt_marks[i].add_theme_color_override("font_color", UI.COL_DANGER)
		else:
			_opt_panels[i].add_theme_stylebox_override("panel",
				UI.glass_box(Color(0, 0, 0, 0.18), 12, Color(1, 1, 1, 0.06), 1, 12))
			_opt_marks[i].modulate.a = 0.0
		if _opt_contents[i] is Label:
			(_opt_contents[i] as Label).add_theme_color_override("font_color",
				UI.COL_TEXT if i == correct else Color(1, 1, 1, 0.32))

func _build_input(_s: Dictionary) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_ans_box.add_child(col)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	col.add_child(hb)
	_input_edit = LineEdit.new()
	_input_edit.placeholder_text = "输入数值或公式，如 3.54、√50/2、5√2/2"
	_input_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_edit.add_theme_font_size_override("font_size", UI.fs(19))
	_input_edit.custom_minimum_size = Vector2(0, 52)
	_input_edit.add_theme_color_override("font_color", UI.COL_TEXT)
	_input_edit.add_theme_color_override("font_placeholder_color", Color(UI.COL_TEXT_DIM, 0.7))
	_input_edit.add_theme_color_override("caret_color", UI.COL_ACCENT)
	_input_edit.add_theme_color_override("selection_color", Color(UI.COL_ACCENT, 0.3))
	_input_edit.add_theme_stylebox_override("normal", UI.glass_box(Color(0, 0, 0, 0.3), 10, Color(1, 1, 1, 0.16), 1, 10))
	_input_edit.add_theme_stylebox_override("focus", UI.glass_box(Color(0, 0, 0, 0.3), 10, Color(UI.COL_ACCENT, 0.6), 1, 10))
	_input_edit.text_submitted.connect(func(_t2: String) -> void: _submit_input())
	hb.add_child(_input_edit)
	var b := Button.new()
	b.text = "提交"
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(96, 52)
	b.pressed.connect(_submit_input)
	hb.add_child(b)

	# 数学符号快捷输入
	var keys := HBoxContainer.new()
	keys.add_theme_constant_override("separation", 6)
	col.add_child(keys)
	for sym in ["√", "²", "³", "π", "×", "÷", "(", ")", "/", "."]:
		var kb := Button.new()
		kb.text = sym
		kb.focus_mode = Control.FOCUS_NONE
		kb.custom_minimum_size = Vector2(40, 40)
		kb.add_theme_font_size_override("font_size", UI.fs(19))
		kb.add_theme_color_override("font_color", UI.COL_TEXT)
		kb.add_theme_stylebox_override("normal", UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(1, 1, 1, 0.16), 1, 4))
		kb.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.1), 8, Color(UI.COL_ACCENT, 0.5), 1, 4))
		kb.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.3), 8, Color(UI.COL_ACCENT, 0.8), 1, 4))
		kb.pressed.connect(_insert_symbol.bind(sym))
		keys.add_child(kb)

func _insert_symbol(sym: String) -> void:
	if _input_edit == null:
		return
	_input_edit.grab_focus()
	_input_edit.insert_text_at_caret(sym)

func _on_choice(k: int) -> void:
	if _solved or _done or _stages.is_empty():
		return
	var correct := int(_stages[_idx].get("ans", -1))
	_reveal_choices(k, correct)
	if k == correct:
		_level_ok()
	else:
		_wrong("不对，再想想——注意观察右侧图形。")

func _submit_input() -> void:
	if _solved or _done or _input_edit == null or _stages.is_empty():
		return
	var s: Dictionary = _stages[_idx]
	var val = _parse_math(_input_edit.text.strip_edges())
	if val == null:
		_wrong("没看懂这个式子，试试输入数值或 sqrt(2)。")
		return
	var tol := float(s.get("tol", 0.05))
	if absf(float(val) - float(s.get("ans", 0.0))) <= tol:
		_level_ok()
	else:
		_wrong("还差一点，再算算？")

func _parse_math(text: String) -> Variant:
	var s := _norm_math(text)
	if s == "":
		return null
	if s.is_valid_float():
		return s.to_float()
	if s.is_valid_int():
		return float(s.to_int())
	var e := Expression.new()
	if e.parse(s) != OK:
		return null
	var v: Variant = e.execute()
	if e.has_execute_failed():
		return null
	if v != null and (v is float or v is int):
		return float(v)
	return null

## 把常见数学写法(√、²、×、÷、π、隐式乘法)转成表达式可解析的形式。
func _norm_math(text: String) -> String:
	var s := text.strip_edges()
	s = s.replace(" ", "").replace("　", "")
	s = s.replace("×", "*").replace("·", "*").replace("÷", "/")
	s = s.replace("−", "-").replace("–", "-").replace("—", "-")
	s = s.replace("π", "3.141592653589793")
	s = s.replace("²", "^2").replace("³", "^3").replace("¹", "^1").replace("⁰", "^0")
	var re := RegEx.new()
	re.compile("([0-9]+(?:\\.[0-9]+)?)\\^([0-9]+)")
	s = re.sub(s, "pow($1,$2)", true)
	re.compile("√\\s*\\(([^()]*)\\)")
	s = re.sub(s, "sqrt($1)", true)
	re.compile("√\\s*([0-9]+(?:\\.[0-9]+)?)")
	s = re.sub(s, "sqrt($1)", true)
	s = s.replace("√", "sqrt")
	re.compile("([0-9])\\s*([a-zA-Z(])")
	s = re.sub(s, "$1*$2", true)
	re.compile("\\)\\s*([0-9a-zA-Z(])")
	s = re.sub(s, ")*$1", true)
	return s

func _level_ok() -> void:
	if _solved:
		return
	_solved = true
	if _wrongs == 0:
		_clean[_idx] = 1
	Sound.play("correct")
	_target_reveal = _reveal_of(_idx + 1)
	_cam_to_stage(_idx + 1)
	_show_feed("推演正确！继续观看右侧的图形演化。", UI.COL_SUCCESS)
	_btn_next.disabled = false
	update_camera(0.0)

func _wrong(msg: String) -> void:
	if _solved or _done:
		return
	_wrongs += 1
	Sound.play("wrong")
	_show_feed(msg, UI.COL_DANGER)

func _use_hint() -> void:
	if _solved or _done or _hint_used or _stages.is_empty():
		return
	_hint_used = true
	_wrongs += 1
	_btn_hint.disabled = true
	_show_feed("[提示] " + str(_stages[_idx].get("hint", "")), Color("#ffd479"))

func _on_pick(i: int) -> void:
	if _solved or _done:
		return
	if not (i in _pick_indices):
		_wrong("这条棱不在顶点 P 处——墙角的三条棱都有一端在 P。")
		return
	if _picked.has(i):
		return
	_picked.append(i)
	var n: Node3D = _topic.edge_segs[i]
	var mi: MeshInstance3D = n.get_child(0) as MeshInstance3D
	mi.material_override = _hi_mat
	_show_feed("已选中 %d / %d 条棱。" % [_picked.size(), _pick_indices.size()], UI.COL_SUCCESS)
	if _picked.size() == _pick_indices.size():
		_level_ok()

func _clear_highlights() -> void:
	if _topic == null:
		return
	var segs = _topic.get("edge_segs")
	if not (segs is Array):
		return
	for n in segs:
		var mi: MeshInstance3D = n.get_child(0) as MeshInstance3D
		mi.material_override = null

func _next() -> void:
	if not _solved or _done:
		return
	if _idx < _stages.size() - 1:
		_idx += 1
		_cam_to_stage(_idx)
		_rebuild()
	else:
		_finish()

func _finish() -> void:
	_done = true
	var total := _stages.size()
	var clean := 0
	for c in _clean:
		clean += c
	var ratio := float(clean) / float(maxi(1, total))
	var st := 0
	if ratio >= 0.999:
		st = 3
	elif ratio >= 0.6:
		st = 2
	elif ratio >= 0.4:
		st = 1
	if GameData.current_level_id() != "":
		GameData.grant_stars(GameData.current_level_id(), st)
	var reward := 30 + clean * 15 + st * 20
	if st >= 3:
		reward += 60
	GameData.add_coins(reward)
	_update_hud()

	var pct := int(round(ratio * 100.0))
	if st >= 3:
		_v_rate.text = "正确率  %d%%   ·   完美通关！" % pct
		_v_rate.add_theme_color_override("font_color", Color("#ffd479"))
	else:
		_v_rate.text = "正确率  %d%%" % pct
		_v_rate.add_theme_color_override("font_color", UI.COL_ACCENT)
	_v_score.text = "无失误 %d / %d 关" % [clean, total]
	_v_coins.text = "金币  +0"

	# 星级逐颗弹出
	for c in _v_star_row.get_children():
		_v_star_row.remove_child(c)
		c.free()
	var tex_full := UI.icon("icon_star_full", 54, UI.COL_ACCENT)
	var tex_empty := UI.icon("icon_star_empty", 54, Color("#3c4a66"))
	for i in 3:
		var filled := i < st
		var tex_r := TextureRect.new()
		tex_r.texture = tex_full if (filled and tex_full != null) else tex_empty
		if tex_r.texture != null:
			tex_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_r.custom_minimum_size = Vector2(54, 54)
		else:
			tex_r.custom_minimum_size = Vector2(34, 54)
		tex_r.pivot_offset = Vector2(27, 27)
		tex_r.scale = Vector2(0.01, 0.01)
		tex_r.modulate.a = 0.0
		_v_star_row.add_child(tex_r)
		var delay := 0.35 + i * 0.2
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(tex_r, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(tex_r, "modulate:a", 1.0, 0.25)
		if filled:
			get_tree().create_timer(delay).timeout.connect(func() -> void: Sound.play("star"))

	Sound.play("complete")
	get_tree().create_timer(0.5).timeout.connect(func() -> void: Sound.play("select"))
	get_tree().create_timer(0.85).timeout.connect(func() -> void: Sound.play("unlock"))

	_refresh_nav()
	_dim.visible = true
	_victory.visible = true
	_spawn_confetti()
	await get_tree().process_frame
	if is_instance_valid(_victory):
		UI.popup_in(_victory)
	# 金币累加
	var tc := create_tween()
	tc.tween_interval(0.75)
	tc.tween_method(func(v: float) -> void: _v_coins.text = "金币  +%d" % int(v), 0.0, float(reward), 0.9) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.tween_callback(func() -> void:
		if is_instance_valid(_v_coins):
			_v_coins.text = "金币  +%d      (共 %d)" % [reward, GameData.coins])

func _refresh_nav() -> void:
	if _nav_prev != null:
		_nav_prev.disabled = not GameData.has_prev_level()
	if _nav_next != null:
		_nav_next.disabled = not GameData.has_next_level()

func _spawn_confetti() -> void:
	Confetti.spawn(_ui_root)

func _show_feed(msg: String, col: Color) -> void:
	if _feed == null:
		return
	_feed.text = msg
	_feed.add_theme_color_override("font_color", col)
	UI.tts_say(msg)

func _update_hud() -> void:
	if _prog_lbl == null:
		return
	var total := maxi(1, _stages.size())
	_prog_lbl.text = "SEQ %02d / %02d" % [_idx + 1, _stages.size()]
	var clean := 0
	for c in _clean:
		clean += c
	_hud_lbl.text = "无失误 %d / %d" % [clean, _stages.size()]
	if _coin_lbl != null:
		_coin_lbl.text = "◆ %d" % GameData.coins
	var tw := create_tween()
	tw.tween_property(_top_fill, "anchor_right", float(_idx) / float(total), 0.4) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------- 3D 相机/输入
func _process(delta: float) -> void:
	_frames += 1
	_t += delta
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("time", _t)
	if _topic != null:
		_reveal = lerpf(_reveal, _target_reveal, 1.0 - exp(-4.0 * delta))
		if absf(_reveal - _target_reveal) < 0.002:
			_reveal = _target_reveal
		_topic.apply(_reveal)
		_sync_labels()
	update_camera(delta)

## Label3D 的描边不随 modulate 透明度变化，这里统一同步，避免未公开答案的标签提前显形。
func _sync_labels() -> void:
	var ls = _topic.get("labels")
	if not (ls is Array):
		return
	for l in ls:
		if l is Label3D:
			var lab := l as Label3D
			var a := lab.modulate.a
			lab.outline_modulate.a = a
			lab.visible = a > 0.015

func update_camera(delta: float) -> void:
	if _camera == null:
		return
	var a := 1.0 - exp(-5.0 * delta)
	cam_yaw = lerp_angle(cam_yaw, cam_yaw_goal, a)
	cam_pitch = lerpf(cam_pitch, cam_pitch_goal, a)
	cam_dist = lerpf(cam_dist, cam_dist_goal, 1.0 - exp(-3.5 * delta))
	cam_target = cam_target.lerp(cam_goal, 1.0 - exp(-3.5 * delta))
	var off := Vector3(cos(cam_pitch) * sin(cam_yaw), sin(cam_pitch), cos(cam_pitch) * cos(cam_yaw)) * cam_dist
	var cp := cam_target + off
	var up := Vector3.UP
	if absf(cp.y - cam_target.y) < 0.18:
		up = Vector3(0, 0.6, 0.8).normalized()
	_camera.global_position = cp
	_camera.look_at(cam_target, up)
	_camera.fov = 22.0
	_camera.near = 0.02
	_camera.far = 2000.0
	# 把三维主体的中心对准右侧图形区中心(按当前分辨率动态计算)，
	# 使其稳定落在左侧任务面板之外，不再随窗口宽度变化而左溢出。
	var vp := get_viewport().get_visible_rect()
	var sw := maxf(vp.size.x, 1.0)
	var asp := sw / maxf(vp.size.y, 1.0)
	var region_left := float(UI.stage_layout()["view_left"])
	var region_center := (region_left + sw) * 0.5
	var coeff := clampf((region_center / sw - 0.5) * 2.0, 0.0, 0.92)
	_camera.h_offset = -coeff * cam_dist * tan(deg_to_rad(_camera.fov * 0.5)) * asp

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var picked := false
				if _stages.size() > 0 and str(_stages[_idx].get("type", "")) == "pick" and not _solved and not _done and not _is_over_ui():
					var i := _pick_edge(event.position)
					if i >= 0:
						_on_pick(i)
						picked = true
				dragging = not picked
			else:
				dragging = false
		elif event.pressed and not _is_over_ui():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				cam_dist_goal = clampf(cam_dist_goal * 0.88, 3.5, 80.0)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				cam_dist_goal = clampf(cam_dist_goal * 1.14, 3.5, 80.0)
	elif event is InputEventMouseMotion and dragging:
		cam_yaw_goal = fmod(cam_yaw_goal + event.relative.x * 0.007, TAU)
		cam_pitch_goal = clampf(cam_pitch_goal + event.relative.y * 0.006, -0.08, 1.3)

func _dist_pt_ray(p: Vector3, ro: Vector3, rd: Vector3) -> float:
	var t := (p - ro).dot(rd)
	return p.distance_to(ro + rd * t)

func _pick_edge(mpos: Vector2) -> int:
	if _topic == null:
		return -1
	var segs = _topic.get("edge_segs")
	if not (segs is Array):
		return -1
	var ro := _camera.project_ray_origin(mpos)
	var rd := _camera.project_ray_normal(mpos)
	var best := -1
	var best_d := 0.6
	for i in segs.size():
		var n: Node3D = segs[i]
		if n == null or not n.visible:
			continue
		var pa: Vector3 = n.get_meta("p1")
		var pb: Vector3 = n.get_meta("p2")
		var d := 1e9
		for s in 21:
			d = minf(d, _dist_pt_ray(pa.lerp(pb, float(s) / 20.0), ro, rd))
		if d < best_d:
			best_d = d
			best = i
	return best

func _is_over_ui() -> bool:
	if _ui_root == null:
		return false
	var m := get_viewport().get_mouse_position()
	for c in [_panel, _bottombar]:
		if c != null and (c as Control).visible and (c as Control).get_global_rect().has_point(m):
			return true
	if _victory != null and _victory.visible and _victory.get_global_rect().has_point(m):
		return true
	return false

# ---------------------------------------------------------------- UI
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = UiConst.LAYER_STAGE_UI
	add_child(layer)

	_ui_root = Control.new()
	_ui_root.theme = UI.make_theme()
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(_ui_root)
	layer.add_child(_ui_root)

	# 顶部进度线
	var tl := Control.new()
	tl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tl.offset_bottom = 3
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(tl)
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.07)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(track)
	tl.add_child(track)
	_top_fill = ColorRect.new()
	_top_fill.color = UI.COL_ACCENT
	_top_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top_fill.anchor_right = 0.0
	_top_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(_top_fill)

	# 顶栏
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.topbar_box())
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 62)
	bar.offset_bottom = 62
	_ui_root.add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	bar.add_child(hb)
	hb.add_child(UI.ghost_button("← " + Scene.origin_label("方法推演"), func() -> void: Scene.goto_origin("res://scenes/WorldMap.tscn")))
	var vline := ColorRect.new()
	vline.color = UI.COL_LINE
	vline.custom_minimum_size = Vector2(1, 18)
	vline.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vline)
	hb.add_child(UI.make_label(str(_cfg.get("title", "立体几何")), 21))
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel",
		UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(UI.COL_ACCENT, 0.3), 1, 10))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cl := UI.mono_label(str(_cfg.get("method", "")), 13, Color(UI.COL_ACCENT, 0.85))
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(cl)
	hb.add_child(chip)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_coin_lbl = UI.mono_label("◆ 0", 16, Color("#ffd479"))
	_coin_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_coin_lbl)
	_hud_lbl = UI.mono_label("", 15, UI.COL_TEXT_DIM)
	_hud_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_hud_lbl)
	_prog_lbl = UI.mono_label("SEQ 00 / 00", 17, UI.COL_ACCENT)
	_prog_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_prog_lbl)

	# 左侧任务面板
	_panel = UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.3), 14, 18)
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 1.0
	var lay := UI.stage_layout()
	_panel.offset_left = float(lay["left"])
	_panel.offset_right = float(lay["left"]) + float(lay["width"])
	_panel.offset_top = 62
	_panel.offset_bottom = -90
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 12)
	_panel.add_child(pv)
	pv.add_child(UI.mono_label("QUERY", 13, UI.COL_ACCENT))
	_panel_title = UI.make_label("", 23, Color("#ffd479"))
	_panel_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_title.custom_minimum_size = Vector2(0, 34)
	pv.add_child(_panel_title)
	var hl := ColorRect.new()
	hl.color = UI.COL_LINE
	hl.custom_minimum_size = Vector2(0, 1)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(hl)
	_q_lbl = RichTextLabel.new()
	_q_lbl.bbcode_enabled = true
	_q_lbl.fit_content = true
	_q_lbl.scroll_active = true
	_q_lbl.selection_enabled = false
	_q_lbl.focus_mode = Control.FOCUS_NONE
	_q_lbl.custom_minimum_size = Vector2(0, 118)
	_q_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_q_lbl.add_theme_font_override("normal_font", UI.font())
	_q_lbl.add_theme_font_override("bold_font", UI.font())
	_q_lbl.add_theme_font_override("mono_font", UI.mono_font())
	_q_lbl.add_theme_font_size_override("normal_font_size", UI.fs(18))
	_q_lbl.add_theme_font_size_override("bold_font_size", UI.fs(18))
	_q_lbl.add_theme_font_size_override("mono_font_size", UI.fs(18))
	_q_lbl.add_theme_color_override("default_color", UI.COL_TEXT)
	_q_lbl.add_theme_constant_override("line_separation", 5)
	pv.add_child(_q_lbl)

	_formula_tex = TextureRect.new()
	_formula_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_formula_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_formula_tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_formula_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formula_tex.visible = false
	pv.add_child(_formula_tex)
	_ans_box = VBoxContainer.new()
	_ans_box.add_theme_constant_override("separation", 10)
	pv.add_child(_ans_box)
	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(sp2)
	_feed = UI.make_label("", 16, UI.COL_TEXT_DIM)
	_feed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feed.custom_minimum_size = Vector2(0, 58)
	pv.add_child(_feed)

	# 底部控制条
	_bottombar = PanelContainer.new()
	_bottombar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bottombar.offset_left = -370
	_bottombar.offset_right = 370
	_bottombar.offset_top = -88
	_bottombar.offset_bottom = -26
	_bottombar.add_theme_stylebox_override("panel", UI.glass_box(Color(0.03, 0.05, 0.09, 0.88), 12, Color(UI.COL_ACCENT, 0.25), 1, 12))
	_bottombar.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_bottombar)
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 14)
	_bottombar.add_child(bh)
	_btn_hint = UI.ghost_button("提示 (−评分)", _use_hint, 16)
	bh.add_child(_btn_hint)
	_btn_restart = UI.ghost_button("重新挑战", func() -> void: _reset(false), 16)
	bh.add_child(_btn_restart)
	bh.add_child(UI.voice_button(func() -> void: UI.tts_say(_q_lbl.text), 16))
	_btn_next = Button.new()
	_btn_next.text = "下一关 →"
	_btn_next.custom_minimum_size = Vector2(220, 52)
	UI.primary_button(_btn_next)
	_btn_next.disabled = true
	_btn_next.pressed.connect(_next)
	bh.add_child(_btn_next)

	var tip := UI.mono_label("拖动旋转 · 滚轮缩放 · 直接点选图形", 13, Color(UI.COL_TEXT_DIM, 0.8))
	tip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tip.offset_left = -420
	tip.offset_right = -26
	tip.offset_top = -114
	tip.offset_bottom = -92
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(tip)

	# 结算
	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.02, 0.05, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_dim)
	_victory = UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.4), 16, 26)
	_victory.set_anchors_preset(Control.PRESET_CENTER)
	_victory.custom_minimum_size = Vector2(560, 0)
	_victory.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_victory.grow_vertical = Control.GROW_DIRECTION_BOTH
	_victory.offset_left = -280
	_victory.offset_right = 280
	_victory.offset_top = -190
	_victory.offset_bottom = 190
	_victory.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_victory)
	var vv := VBoxContainer.new()
	vv.alignment = BoxContainer.ALIGNMENT_CENTER
	vv.add_theme_constant_override("separation", 14)
	_victory.add_child(vv)
	vv.add_child(UI.mono_label("MISSION CLEAR", 13, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	vv.add_child(UI.make_label("方法推演完成", 30, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var vl := ColorRect.new()
	vl.color = UI.COL_LINE
	vl.custom_minimum_size = Vector2(0, 1)
	vl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vv.add_child(vl)
	_v_star_row = HBoxContainer.new()
	_v_star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_v_star_row.add_theme_constant_override("separation", 14)
	vv.add_child(_v_star_row)
	_v_rate = UI.make_label("", 20, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_rate)
	_v_score = UI.make_label("", 16, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_score)
	_v_coins = UI.make_label("", 22, Color("#ffd479"), HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_coins)
	vv.add_child(UI.make_label(str(_cfg.get("summary", "")), 15, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vv.add_child(row)
	_nav_prev = UI.ghost_button("上一关", func() -> void: GameData.goto_prev_level(), 15)
	row.add_child(_nav_prev)
	row.add_child(UI.ghost_button("返回" + Scene.origin_label("方法推演"), func() -> void: Scene.goto_origin("res://scenes/WorldMap.tscn"), 16))
	var again := Button.new()
	again.text = "重新推演"
	again.custom_minimum_size = Vector2(180, 56)
	UI.primary_button(again)
	again.pressed.connect(func() -> void: _reset(true))
	row.add_child(again)
	_nav_next = UI.ghost_button("下一关", func() -> void: GameData.goto_next_level(), 15)
	row.add_child(_nav_next)
	_victory.visible = false
	_dim.visible = false
