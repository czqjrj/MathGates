class_name Lab3DView
extends SubViewportContainer
## 立体几何「真实网格 3D」视口：内嵌 SubViewport + Camera3D + 光照 + SolidBuilder。
##
## 交互：左键拖动旋转、滚轮缩放、双击重置视角；空闲自动缓转。
## 视角预设：iso（默认斜二测视角）/ front（正视图）/ top（俯视图）/ side（侧视图）。
## 动画：载入生长、脉冲高亮、参数插值（截面/展开）、镜头巡游、自转演示。
##
## 用法： view.set_scene(scene_dict, vars)；view.play_anim(steps)；
##        view.set_var("a", 2.0) → 实时重建几何。

signal user_interacted

const SKY_SHADER := """
shader_type sky;

uniform vec3 c_top : source_color = vec3(0.03, 0.05, 0.09);
uniform vec3 c_bottom : source_color = vec3(0.06, 0.1, 0.17);
uniform vec3 accent : source_color = vec3(0.369, 0.902, 1.0);
uniform float time = 0.0;

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 col = mix(c_bottom, c_top, pow(h, 0.8));
	col += accent * 0.10 * exp(-abs(d.y) * 6.5);
	vec2 p1 = vec2(-0.4 + 0.25 * sin(time * 0.05), 0.1 * cos(time * 0.04));
	col += accent * 0.08 * exp(-length(d.xz - p1) * 2.4);
	COLOR = vec3(col);
}
"""

var _sv: SubViewport
var _world: Node3D
var _builder: SolidBuilder
var _camera: Camera3D
var _sky_mat: ShaderMaterial
var _t := 0.0

var scene: Dictionary = {}
var vars: Dictionary = {}

# 相机状态
var yaw := 0.72
var pitch := 0.34
var dist := 13.0
var target := Vector3.ZERO
var yaw_goal := 0.72
var pitch_goal := 0.34
var dist_goal := 13.0
var target_goal := Vector3.ZERO

var dragging := false
var _idle := 0.0
var auto_rotate := true
var _auto_pause := 0.0

var _reveal := 0.0
var _reveal_target := 1.0
var _reveal_speed := 1.5

# 动画
var _anim: Array = []
var _anim_i := 0
var _anim_t := 0.0
var _anim_playing := false
var _anim_vars_from: Dictionary = {}
var _anim_rot_from := 0.0

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sv = SubViewport.new()
	_sv.own_world_3d = true
	_sv.transparent_bg = false
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.handle_input_locally = false
	_sv.msaa_3d = Viewport.MSAA_2X
	add_child(_sv)

	_world = Node3D.new()
	_world.name = "World"
	_sv.add_child(_world)

	_build_environment()

	_builder = SolidBuilder.new()
	_builder.name = "Builder"
	_world.add_child(_builder)

	_camera = Camera3D.new()
	_camera.fov = 30.0
	_camera.near = 0.02
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.current = true

	set_process(true)
	resized.connect(_on_resized)
	_on_resized()

func _build_environment() -> void:
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
	env.ambient_light_color = Color(0.58, 0.72, 0.95)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.background_energy_multiplier = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	_world.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-54, -46, 0)
	key.light_energy = 1.25
	key.light_color = Color(0.92, 0.96, 1.0)
	_world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 140, 0)
	fill.light_energy = 0.45
	fill.light_color = Color(0.7, 0.8, 1.0)
	_world.add_child(fill)

func _on_resized() -> void:
	if _sv != null:
		_sv.size = Vector2i(maxi(int(size.x), 2), maxi(int(size.y), 2))

# ================================================================ 场景/变量

func set_scene(s: Dictionary, v: Dictionary = {}) -> void:
	scene = s if s != null else {}
	vars = (v if v != null else {}).duplicate()
	_reveal = 0.0
	_reveal_target = 1.0
	_anim_playing = false
	_anim.clear()
	_builder.build(scene, vars)
	_apply_default_view()
	_update_camera(1000.0)

func rebuild() -> void:
	_builder.build(scene, vars)

func set_var(name: String, value: float) -> void:
	vars[name] = value
	rebuild()

func set_vars(v: Dictionary) -> void:
	vars = v.duplicate()
	rebuild()

func _apply_default_view() -> void:
	var v: Dictionary = scene.get("view", {}) if scene.has("view") else {}
	yaw = deg_to_rad(NumExpr.num(v.get("yaw", 40.0), vars, 40.0)) if v.has("yaw") else 0.72
	pitch = deg_to_rad(NumExpr.num(v.get("pitch", 20.0), vars, 20.0)) if v.has("pitch") else 0.34
	dist = _auto_dist() * NumExpr.num(v.get("zoom", 1.0), vars, 1.0)
	if v.has("dist"):
		dist = NumExpr.num(v["dist"], vars, dist)
	var focus: Variant = v.get("focus", null)
	if focus is Array:
		target = _mv(NumExpr.vec3(focus, vars))
	else:
		target = _auto_target()
	yaw_goal = yaw
	pitch_goal = pitch
	dist_goal = dist
	target_goal = target

func _auto_target() -> Vector3:
	var b := _builder.bounds()
	if b.size == Vector3.ZERO:
		return Vector3(0, 1.0, 0)
	return b.get_center()

func _auto_dist() -> float:
	var b := _builder.bounds()
	var r := maxf(b.size.length() * 0.55, 2.0)
	return clampf(r / tan(deg_to_rad(15.0)), 5.0, 90.0)

func reset_view(animated := true) -> void:
	_apply_default_view()
	_idle = 0.0
	_auto_pause = 0.0
	if not animated:
		_update_camera(1000.0)

func preset_view(name: String, animated := true) -> void:
	var t := target_goal
	match name:
		"front":
			yaw_goal = 0.0
			pitch_goal = 0.0
		"top":
			yaw_goal = 0.0
			pitch_goal = 1.52
		"side":
			yaw_goal = PI * 0.5
			pitch_goal = 0.0
		"back":
			yaw_goal = PI
			pitch_goal = 0.0
		_:
			yaw_goal = 0.72
			pitch_goal = 0.34
	target_goal = t
	_auto_pause = 2.5
	if not animated:
		_update_camera(1000.0)

func _mv(v: Vector3) -> Vector3:
	return Vector3(v.x, v.z, v.y)

# ================================================================ 帧循环

func _process(delta: float) -> void:
	_t += delta
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("time", _t)
	if _anim_playing:
		_tick_anim(delta)
	_reveal = lerpf(_reveal, _reveal_target, 1.0 - exp(-3.0 * delta))
	if absf(_reveal - _reveal_target) < 0.002:
		_reveal = _reveal_target
	_builder.set_reveal(_reveal)
	# 空闲自动缓转
	if auto_rotate and not dragging and not _anim_playing:
		if _auto_pause > 0.0:
			_auto_pause -= delta
		else:
			yaw_goal += delta * 0.22
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	var a := 1.0 - exp(-6.0 * delta)
	yaw = lerp_angle(yaw, yaw_goal, a)
	pitch = lerpf(pitch, pitch_goal, a)
	dist = lerpf(dist, dist_goal, 1.0 - exp(-4.5 * delta))
	target = target.lerp(target_goal, 1.0 - exp(-4.5 * delta))
	var off := Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * dist
	var cp := target + off
	var up := Vector3.UP
	if absf(cp.y - target.y) < 0.25:
		up = Vector3(0, 0.72, 0.69).normalized()
	_camera.global_position = cp
	_camera.look_at(target, up)

# ================================================================ 动画播放

## steps: [{a:"view", to:"front", dur, hold}, {a:"pulse", ids|id, dur},
##         {a:"vars", to:{a:2}, dur, hold}, {a:"rotate", turns, dur, hold},
##         {a:"highlight", ids}, {a:"reveal", dur}]
func play_anim(steps: Array) -> void:
	if steps.is_empty():
		return
	_anim = steps.duplicate(true)
	_anim_i = 0
	_anim_t = 0.0
	_anim_playing = true
	_auto_pause = 999.0

func _tick_anim(delta: float) -> void:
	if _anim_i >= _anim.size():
		_anim_playing = false
		_auto_pause = 1.5
		return
	var step: Dictionary = _anim[_anim_i]
	var kind := str(step.get("a", ""))
	var dur := maxf(NumExpr.num(step.get("dur", 1.2), vars, 1.2), 0.05)
	var hold := NumExpr.num(step.get("hold", 0.0), vars, 0.0)
	# 起始准备
	if _anim_t <= 0.0:
		_anim_prepare(step, kind)
	_anim_t += delta
	var total := dur + hold
	var done := _anim_t >= total
	# 收尾帧必须落在目标值上，否则最后一段补间会被整帧跳过（参数停在 ~80% 处）
	var k := 1.0 if done else clampf(_anim_t / dur, 0.0, 1.0)
	_anim_apply(step, kind, k)
	if done:
		_anim_i += 1
		_anim_t = 0.0

func _anim_prepare(step: Dictionary, kind: String) -> void:
	match kind:
		"vars":
			_anim_vars_from = {}
			var to: Dictionary = step.get("to", {})
			for key in to.keys():
				_anim_vars_from[key] = float(vars.get(key, 0.0))
		"rotate":
			_anim_rot_from = yaw_goal

func _anim_apply(step: Dictionary, kind: String, k: float) -> void:
	match kind:
		"view":
			preset_view(str(step.get("to", "iso")), true)
		"rotate":
			var turns := NumExpr.num(step.get("turns", 1.0), vars, 1.0)
			yaw = _anim_rot_from + turns * TAU * k
			yaw_goal = yaw
		"pulse":
			if _anim_t <= 0.0:
				var ids: Array = step.get("ids", [str(step.get("id", ""))] if step.has("id") else [])
				_builder.pulse(ids, NumExpr.num(step.get("dur", 2.0), vars, 2.0) + NumExpr.num(step.get("hold", 0.0), vars, 0.0))
		"highlight":
			if _anim_t <= 0.0:
				_builder.set_highlight(step.get("ids", []))
		"vars":
			var to: Dictionary = step.get("to", {})
			var changed := false
			for key in to.keys():
				var from := float(_anim_vars_from.get(key, 0.0))
				var tgt := NumExpr.num(to[key], vars, from)
				var nv := lerpf(from, tgt, k)
				if absf(nv - float(vars.get(key, 0.0))) > 0.004:
					vars[key] = nv
					changed = true
			if changed:
				rebuild()
		"reveal":
			_reveal = k
			_reveal_target = k
		_:
			pass

# ================================================================ 输入

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and mb.double_click:
				reset_view(true)
				_auto_pause = 2.0
				accept_event()
				return
			dragging = mb.pressed
			if mb.pressed:
				_auto_pause = 2.5
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			dist_goal = clampf(dist_goal * 0.88, 2.5, 120.0)
			_auto_pause = 3.0
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dist_goal = clampf(dist_goal * 1.14, 2.5, 120.0)
			_auto_pause = 3.0
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			reset_view(true)
			_auto_pause = 2.0
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		var mm := event as InputEventMouseMotion
		yaw_goal = fmod(yaw_goal - mm.relative.x * 0.007, TAU)
		pitch_goal = clampf(pitch_goal + mm.relative.y * 0.006, -0.12, 1.55)
		user_interacted.emit()
		accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		dragging = st.pressed
		_auto_pause = 2.5
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		yaw_goal = fmod(yaw_goal - sd.relative.x * 0.008, TAU)
		pitch_goal = clampf(pitch_goal + sd.relative.y * 0.007, -0.12, 1.55)
		user_interacted.emit()
