class_name Space3DView
extends Control
## 空间向量 3D 演示视图：可拖动旋转、滚轮缩放的正交投影视图。
## 支持坐标轴、点、向量(箭头)、线段、平面(平行四边形)与文字标签；载入时"生长"动画。

const COL_AXIS_X := Color(0.98, 0.44, 0.52, 1.0)
const COL_AXIS_Y := Color(0.204, 0.827, 0.6, 1.0)
const COL_AXIS_Z := Color(0.357, 0.56, 0.976, 1.0)
const COL_TEXT := Color(0.92, 0.96, 1.0, 1.0)
const COL_DIM := Color(0.62, 0.68, 0.8, 1.0)
const COL_LINE := Color(0.369, 0.902, 1.0, 1.0)

var _scene: Dictionary = {}
var yaw := -0.7
var pitch := 0.42
var zoom := 58.0
var _auto := true
var _drag := false
var _t := 0.0
var _reveal := 0.0
var _user_touched := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	set_process(true)

func set_scene(s: Dictionary) -> void:
	_scene = s if s != null else {}
	_reveal = 0.0
	_auto = true
	_user_touched = false
	if _scene.has("view"):
		zoom = float(_scene["view"]) * 58.0
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	_reveal = minf(_reveal + delta * 1.6, 1.0)
	if _auto and not _user_touched:
		yaw += delta * 0.25
	queue_redraw()

# ---------------------------------------------------------------- 3D → 2D
func _rot(p: Vector3) -> Vector3:
	var cy := cos(yaw)
	var sy := sin(yaw)
	var x1 := p.x * cy + p.z * sy
	var z1 := -p.x * sy + p.z * cy
	var cp := cos(pitch)
	var sp := sin(pitch)
	var y2 := p.y * cp - z1 * sp
	var z2 := p.y * sp + z1 * cp
	return Vector3(x1, y2, z2)

func _proj(p: Vector3) -> Vector2:
	var r := _rot(p)
	return Vector2(r.x, -r.y) * zoom + size * 0.5

func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	_draw_axes()
	# 平面(先画)
	for pl in _arr(_scene.get("planes", [])):
		_draw_plane(pl)
	# 线段
	for sg in _arr(_scene.get("segments", [])):
		_draw_segment(sg)
	# 向量
	for vc in _arr(_scene.get("vectors", [])):
		_draw_vector(vc)
	# 点
	for pt in _arr(_scene.get("points", [])):
		_draw_point(pt)
	# 提示
	var f := UI.font()
	var msg := "拖动旋转 · 滚轮缩放"
	var ts := UI.fs(13)
	var tw := f.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
	draw_string(f, Vector2(size.x - tw - 16.0, size.y - 14.0), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Color(COL_DIM, 0.85))

func _arr(v: Variant) -> Array:
	return v if v is Array else []

func _draw_axes() -> void:
	var L := float(_scene.get("range", 3)) * _reveal
	var o := _proj(Vector3.ZERO)
	_axis(o, _proj(Vector3(L, 0, 0)), COL_AXIS_X, "x")
	_axis(o, _proj(Vector3(0, L, 0)), COL_AXIS_Y, "y")
	_axis(o, _proj(Vector3(0, 0, L)), COL_AXIS_Z, "z")
	draw_circle(o, 3.5, Color(1, 1, 1, 0.9))

func _axis(o: Vector2, e: Vector2, col: Color, nm: String) -> void:
	draw_line(o, e, col, 2.2)
	var d := (e - o).normalized()
	draw_line(e, e - d * 9.0 + Vector2(-d.y, d.x) * 5.0, col, 2.2)
	draw_line(e, e - d * 9.0 - Vector2(-d.y, d.x) * 5.0, col, 2.2)
	_draw_label(e + d * 10.0, nm, col, 15)

func _draw_point(pt: Dictionary) -> void:
	var sp := _proj(_v(pt["p"]))
	var col := Color(str(pt.get("color", "#ffd479")))
	var r := 5.0 * _reveal
	draw_circle(sp, r + 3.0, Color(col, 0.18))
	draw_circle(sp, 5.0, Color(0.02, 0.03, 0.06, 0.92))
	draw_circle(sp, 3.6 * _reveal, col)
	if pt.has("label") and _reveal > 0.6:
		_draw_label(sp + Vector2(9.0, -9.0), str(pt["label"]), col, 15)

func _draw_segment(sg: Dictionary) -> void:
	var a := _proj(_v(sg["p1"]))
	var b := _proj(_v(sg["p1"]).lerp(_v(sg["p2"]), _reveal))
	var col := Color(str(sg.get("color", "#45C7E5")))
	if bool(sg.get("dash", false)):
		draw_dashed_line(a, b, col, 2.2, 7.0)
	else:
		draw_line(a, b, col, 2.2)
	if sg.has("label") and _reveal > 0.7:
		_draw_label(a.lerp(b, 0.5) + Vector2(6.0, -6.0), str(sg["label"]), col, 14)

func _draw_vector(vc: Dictionary) -> void:
	var a := _proj(_v(vc.get("from", [0, 0, 0])))
	var b := _proj(_v(vc.get("from", [0, 0, 0])).lerp(_v(vc["to"]), _reveal))
	var col := Color(str(vc.get("color", "#ffd479")))
	draw_line(a, b, col, 3.0)
	var d := (b - a).normalized()
	if d.length() > 0.1:
		draw_line(b, b - d * 11.0 + Vector2(-d.y, d.x) * 6.0, col, 3.0)
		draw_line(b, b - d * 11.0 - Vector2(-d.y, d.x) * 6.0, col, 3.0)
	if vc.has("label") and _reveal > 0.6:
		_draw_label(a.lerp(b, 0.55) + Vector2(8.0, -8.0), str(vc["label"]), col, 15)

func _draw_plane(pl: Dictionary) -> void:
	var o := _v(pl["origin"])
	var u := _v(pl["u"]) * _reveal
	var v := _v(pl["v"]) * _reveal
	var c := Color(str(pl.get("color", "#45C7E5")))
	var p0 := _proj(o)
	var p1 := _proj(o + u)
	var p2 := _proj(o + u + v)
	var p3 := _proj(o + v)
	draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color(c, 0.14))
	draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), Color(c, 0.6), 1.6, true)
	if pl.has("label") and _reveal > 0.6:
		_draw_label(_proj(o + (u + v) * 0.5) + Vector2(6.0, -6.0), str(pl["label"]), c, 14)

func _draw_label(pos: Vector2, text: String, col: Color, size_px: int) -> void:
	if text.is_empty():
		return
	var px := UI.fs(size_px)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_rect(Rect2(pos + Vector2(-5.0, -px - 2.0), Vector2(w + 10.0, px + 7.0)), Color(0.04, 0.06, 0.11, 0.6), true)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

# ---------------------------------------------------------------- 交互
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag = true
				_user_touched = true
				accept_event()
			else:
				_drag = false
				accept_event()
		elif event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom = clampf(zoom * 1.1, 24.0, 200.0)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom = clampf(zoom * 0.9, 24.0, 200.0)
			accept_event()
	elif event is InputEventMouseMotion and _drag:
		yaw += event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.006, -1.3, 1.3)
		_user_touched = true
		accept_event()
