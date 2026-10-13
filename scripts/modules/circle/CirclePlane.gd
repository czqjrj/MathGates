class_name CirclePlane
extends Control
## 圆 · 静态示范坐标平面(纯代码绘制，无图片依赖)。
## 被动图元：网格 / 坐标轴 / 圆(可选填充) / 直线 Ax+By+C=0 / 线段 / 点 /
## 向量箭头 / 文本标签。用于知识体系「圆」章节各关的图形辅助。
## 用法：set_scene(scene_dict)。不做交互动画，仅在场景变化/尺寸变化时重绘。

const COL_GRID := Palette.GRID
const COL_AXIS := Palette.AXIS
const COL_TEXT := Palette.TEXT
const COL_DIM := Palette.DIM
const COL_CYAN := Palette.ACCENT
const COL_GOLD := Palette.GOLD
const COL_GREEN := Palette.SUCCESS
const COL_RED := Palette.DANGER

var _scene: Dictionary = {}
var _reveal := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)

func set_scene(s: Dictionary) -> void:
	_scene = s if s != null else {}
	queue_redraw()

# ---------------------------------------------------------------- 坐标换算
func _range() -> float:
	var r := 5.0
	if _scene.has("range"):
		r = float(_scene["range"])
	return maxf(r, 1.0)

func _origin() -> Vector2:
	return size * 0.5

func _scale() -> float:
	return minf(size.x, size.y) / (2.0 * _range() + 0.5)

func _to_screen(p: Vector2) -> Vector2:
	return _origin() + Vector2(p.x, -p.y) * _scale()

func _vec(a: Variant, dflt: Vector2) -> Vector2:
	if a is Array and a.size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return dflt

func _c(v: Variant, dflt: Color) -> Color:
	if v is String and v.begins_with("#") and (v.length() == 7 or v.length() == 9):
		return Color(v)
	return dflt

func _arr(k: String) -> Array:
	var v: Variant = _scene.get(k, [])
	return v if v is Array else []

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	if _scene.is_empty():
		return
	if bool(_scene.get("axes", true)):
		_draw_grid()
	_draw_circles()
	_draw_lines()
	_draw_segments()
	_draw_vectors()
	_draw_points()
	_draw_labels()

func _draw_grid() -> void:
	var r := _range()
	var s := _scale()
	var o := _origin()
	var k := 1
	while float(k) <= r + 0.001:
		var off := float(k) * s
		draw_line(Vector2(o.x + off, 0), Vector2(o.x + off, size.y), COL_GRID)
		draw_line(Vector2(o.x - off, 0), Vector2(o.x - off, size.y), COL_GRID)
		draw_line(Vector2(0, o.y + off), Vector2(size.x, o.y + off), COL_GRID)
		draw_line(Vector2(0, o.y - off), Vector2(size.x, o.y - off), COL_GRID)
		k += 1
	draw_line(Vector2(o.x, 0), Vector2(o.x, size.y), COL_AXIS, 1.5)
	draw_line(Vector2(0, o.y), Vector2(size.x, o.y), COL_AXIS, 1.5)
	var fl := UI.mono_font()
	var axs := UI.fs(13)
	draw_string(fl, Vector2(o.x + r * s - axs - 3, o.y - axs * 0.7), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, axs, COL_DIM)
	draw_string(fl, Vector2(o.x + 6, axs), "y", HORIZONTAL_ALIGNMENT_LEFT, -1, axs, COL_DIM)
	draw_string(fl, Vector2(o.x + 6, o.y + axs), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, axs, COL_DIM)

func _draw_circles() -> void:
	for ci in _arr("circles"):
		var center := _vec(ci.get("c", [0, 0]), Vector2.ZERO)
		var rr := float(ci.get("r", 1.0)) * _scale()
		var col := _c(ci.get("color", "#9270CA"), Color(COL_CYAN))
		if bool(ci.get("fill", false)):
			draw_circle(_to_screen(center), rr, Color(col, 0.10))
		draw_arc(_to_screen(center), rr, 0.0, TAU, 96, col, 2.0)
		var lab := str(ci.get("label", ""))
		if lab != "":
			var lp := _to_screen(center) + Vector2(rr * 0.7071, -rr * 0.7071)
			_draw_label(lp, lab, Color(col, 0.95), 14)

func _draw_lines() -> void:
	var r := _range()
	for ln in _arr("lines"):
		var A := float(ln.get("a", 1.0))
		var B := float(ln.get("b", 0.0))
		var C := float(ln.get("c", 0.0))
		var col := _c(ln.get("color", "#5ee6ff"), Color(COL_CYAN))
		var pt: Vector2
		if absf(A) >= absf(B):
			pt = Vector2(-C / A, 0.0) if absf(A) > 1e-6 else Vector2.ZERO
		else:
			pt = Vector2(0.0, -C / B) if absf(B) > 1e-6 else Vector2.ZERO
		var dir := Vector2(-B, A).normalized()
		var e0 := _to_screen(pt - dir * (r * 2.0))
		var e1 := _to_screen(pt + dir * (r * 2.0))
		if bool(ln.get("dash", false)):
			draw_dashed_line(e0, e1, col, 1.8, 8.0)
		else:
			draw_line(e0, e1, col, 1.8)
		if ln.has("label"):
			_draw_label(e0.lerp(e1, 0.82), str(ln["label"]), Color(col, 0.95), 13)

func _draw_segments() -> void:
	for sg in _arr("segments"):
		var p1 := _vec(sg.get("p1", [0, 0]), Vector2.ZERO)
		var p2 := _vec(sg.get("p2", [0, 0]), Vector2.ZERO)
		var col := _c(sg.get("color", "#ffd479"), Color(COL_GOLD))
		if bool(sg.get("dash", false)):
			draw_dashed_line(_to_screen(p1), _to_screen(p2), col, 1.6, 6.0)
		else:
			draw_line(_to_screen(p1), _to_screen(p2), col, 1.8)
		if sg.has("label"):
			_draw_label((_to_screen(p1) + _to_screen(p2)) * 0.5 + Vector2(6, -10), str(sg["label"]), Color(col, 0.95), 13)

func _draw_vectors() -> void:
	for vv in _arr("vectors"):
		var p1 := _vec(vv.get("p1", vv.get("from", [0, 0])), Vector2.ZERO)
		var p2 := _vec(vv.get("p2", vv.get("to", [1, 1])), Vector2.ONE)
		var col := _c(vv.get("color", "#5ee6ff"), Color(COL_CYAN))
		var a := _to_screen(p1)
		var b := _to_screen(p2)
		draw_line(a, b, col, 2.0)
		if a.distance_to(b) > 10.0:
			var dir := (b - a).normalized()
			var perp := Vector2(-dir.y, dir.x)
			var head := 9.0
			draw_colored_polygon(PackedVector2Array([
				b, b - dir * head + perp * (head * 0.42), b - dir * head - perp * (head * 0.42)
			]), col)
		if vv.has("label"):
			_draw_label(b + Vector2(8, -8), str(vv["label"]), col, 13)

func _draw_points() -> void:
	for pt in _arr("points"):
		var pos := _to_screen(_vec(pt.get("p", [0, 0]), Vector2.ZERO))
		var col := _c(pt.get("color", "#ffd479"), Color(COL_GOLD))
		draw_circle(pos, 5.0, Color(0.02, 0.04, 0.08, 0.9))
		draw_circle(pos, 4.0, col)
		if pt.has("label"):
			_draw_label(pos + Vector2(10, -10), str(pt["label"]), Color(col, 0.95), 13)

func _draw_labels() -> void:
	for lb in _arr("labels"):
		var pos := _to_screen(_vec(lb.get("p", [0, 0]), Vector2.ZERO))
		var col := _c(lb.get("color", "#e8eef8"), Color(COL_TEXT))
		_draw_label(pos, str(lb.get("text", "")), col, int(lb.get("size", 14)))

func _draw_label(pos: Vector2, text: String, col: Color, s: int) -> void:
	if text.is_empty() or col.a <= 0.01:
		return
	var px := UI.fs(s)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_rect(Rect2(pos + Vector2(-5, -px - 3), Vector2(w + 10, px + 7)), Color(0.04, 0.06, 0.11, 0.72 * col.a), true)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
