class_name EllipsePlane
extends Control
## 圆锥曲线 · 椭圆 · 可交互坐标平面(纯代码绘制，无图片依赖)。
## 被动图元：网格 / 坐标轴 / 椭圆(可切换焦点轴) / 焦点 / 点 / 线段 / 直线 / 向量 / 角弧 / 文本。
## 交互式学习：拖动金色手柄或底部滑块，实时把"读数"调到目标值即通关。
## 模型：def_sum(第一定义) / def_state(2a·2c 三态) / ecc(离心率) /
##       focal_tri(焦点三角形) / point_diff(点差法中点弦) / secant(直线与椭圆相交 · 硬解定理)。
## 用法：set_scene(静态图形) → begin_task(交互任务) → is_task_ok() 判定。

signal state_changed(value: String)

const COL_GRID := Palette.GRID
const COL_AXIS := Palette.AXIS
const COL_TEXT := Palette.TEXT
const COL_DIM := Palette.DIM
const COL_CYAN := Palette.ACCENT
const COL_GOLD := Palette.GOLD
const COL_VIOLET := Color(0.659, 0.44, 0.792, 1.0)
const COL_GREEN := Palette.SUCCESS
const COL_RED := Palette.DANGER
const COL_PINK := Color(1.0, 0.494, 0.659, 1.0)

const HANDLE_R := 13.0
const SEG := 128

var _scene: Dictionary = {}
var _task: Dictionary = {}
var _t := 0.0
var _reveal := 0.0

var mode := ""              # "" / "task"
var _drag_pos := Vector2.ZERO
var _dragging := false
var _param := 0.0
var _slider_drag := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	_reveal = minf(_reveal + delta * 1.6, 1.0)
	queue_redraw()

func set_scene(s: Dictionary) -> void:
	_scene = s if s != null else {}
	mode = ""
	_task = {}
	_reveal = 0.0
	queue_redraw()

func begin_task(t: Dictionary) -> void:
	_task = t if t != null else {}
	mode = "task"
	var ctrl := _control()
	if ctrl == "slider":
		var rng := _param_range()
		_param = clampf(float(_task.get("start", rng.x)), rng.x, rng.y)
	else:
		_drag_pos = _clamp_pos(_vec(_task.get("start", [0, 0]), Vector2.ZERO))
		_drag_pos = _magnets(_drag_pos)
	_state_changed()
	queue_redraw()

func is_task_ok() -> bool:
	if mode != "task":
		return false
	return _check_ok()

func readout() -> String:
	if mode != "task":
		return ""
	return _readout()

func model() -> String:
	return str(_task.get("model", ""))

func _control() -> String:
	return str(_task.get("control", "point"))

# ---------------------------------------------------------------- 坐标换算
func _range() -> float:
	var r := 6.0
	if _scene.has("range"):
		r = float(_scene["range"])
	if _scene.has("x") and _scene["x"] is Array and (_scene["x"] as Array).size() == 2:
		r = maxf(r, maxf(absf(float(_scene["x"][0])), absf(float(_scene["x"][1]))))
	if _scene.has("y") and _scene["y"] is Array and (_scene["y"] as Array).size() == 2:
		r = maxf(r, maxf(absf(float(_scene["y"][0])), absf(float(_scene["y"][1]))))
	if _task.has("range_xy"):
		r = maxf(r, float(_task["range_xy"]))
	return maxf(r, 2.0)

func _origin() -> Vector2:
	return size * 0.5

func _scale() -> float:
	return minf(size.x, size.y) / (2.0 * _range() + 0.5)

func _to_screen(p: Vector2) -> Vector2:
	return _origin() + Vector2(p.x, -p.y) * _scale()

func _to_math(sp: Vector2) -> Vector2:
	return Vector2((sp.x - _origin().x) / _scale(), (_origin().y - sp.y) / _scale())

func _clamp_pos(p: Vector2) -> Vector2:
	var r := _range()
	return Vector2(clampf(p.x, -r, r), clampf(p.y, -r, r))

func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.0005:
		return str(int(roundf(v)))
	return "%.2f" % v

func _f2(v: Vector2) -> String:
	return "(%s, %s)" % [_fmt(v.x), _fmt(v.y)]

func _vec(a: Variant, dflt: Vector2) -> Vector2:
	if a is Array and (a as Array).size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return dflt

func _c(v: Variant, dflt: Color) -> Color:
	if v is String and v.begins_with("#") and ((v as String).length() == 7 or (v as String).length() == 9):
		return Color(v)
	return dflt

func _arr(k: String) -> Array:
	var v: Variant = _scene.get(k, [])
	return v if v is Array else []

# ---------------------------------------------------------------- 参数滑块
func _param_range() -> Vector2:
	var rng: Array = _task.get("range", [0.0, 1.0])
	if rng.size() < 2:
		return Vector2(0.0, 1.0)
	return Vector2(float(rng[0]), float(rng[1]))

func _slider_geom() -> Array:
	return [46.0, size.x - 46.0, size.y - 34.0]

func _param_to_x(v: float) -> float:
	var g := _slider_geom()
	var rng := _param_range()
	var tt := clampf((v - rng.x) / maxf(rng.y - rng.x, 0.001), 0.0, 1.0)
	return lerpf(g[0], g[1], tt)

func _x_to_param(x: float) -> float:
	var g := _slider_geom()
	var rng := _param_range()
	var tt := clampf((x - g[0]) / maxf(g[1] - g[0], 0.001), 0.0, 1.0)
	return lerpf(rng.x, rng.y, tt)

# ---------------------------------------------------------------- 椭圆工具
func _ellipse_pt(t: float, a: float, b: float, axis: String) -> Vector2:
	if axis == "y":
		return Vector2(b * cos(t), a * sin(t))
	return Vector2(a * cos(t), b * sin(t))

func _ellipse_b(a: float, c: float) -> float:
	return sqrt(maxf(a * a - c * c, 0.0004))

func _foci(c: float, axis: String) -> Array:
	if axis == "y":
		return [Vector2(0, -c), Vector2(0, c)]
	return [Vector2(-c, 0), Vector2(c, 0)]

func _nearest_on_ellipse(p: Vector2, a: float, b: float, axis: String) -> Vector2:
	var tt: float
	if axis == "y":
		tt = atan2(p.y / maxf(a, 1e-6), p.x / maxf(b, 1e-6))
	else:
		tt = atan2(p.y / maxf(b, 1e-6), p.x / maxf(a, 1e-6))
	return _ellipse_pt(tt, a, b, axis)

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	if _scene.is_empty() and mode != "task":
		return
	_draw_grid()
	_draw_static()
	if mode == "task":
		_draw_task()

func _draw_grid() -> void:
	if not _scene.get("axes", true):
		return
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

func _draw_ellipse(a: float, b: float, axis: String, col: Color, width: float, dash: bool) -> void:
	var prev := _to_screen(_ellipse_pt(0.0, a, b, axis))
	for i in range(1, SEG + 1):
		var cur := _to_screen(_ellipse_pt(TAU * float(i) / float(SEG), a, b, axis))
		if dash:
			draw_dashed_line(prev, cur, col, width, 7.0)
		else:
			draw_line(prev, cur, col, width)
		prev = cur

func _draw_static() -> void:
	if _scene.has("ellipse") and _scene["ellipse"] is Dictionary:
		var e: Dictionary = _scene["ellipse"]
		var a := float(e.get("a", 5.0))
		var b := float(e.get("b", 3.0))
		var axis := str(e.get("axis", "x"))
		var ec := _c(e.get("color", "#ff7ea8"), COL_PINK)
		_draw_ellipse(a, b, axis, ec, float(e.get("width", 2.2)), bool(e.get("dash", false)))
		if e.has("label"):
			_draw_label(_to_screen(_ellipse_pt(PI * 0.5, a, b, axis)) + Vector2(8, -6), str(e["label"]), ec, 14)
	if _scene.has("foci") and _scene["foci"] is Dictionary:
		var f: Dictionary = _scene["foci"]
		var c := float(f.get("c", 3.0))
		var axis := str(f.get("axis", "x"))
		var fc := _c(f.get("color", "#ffd479"), COL_GOLD)
		var pts := _foci(c, axis)
		_draw_circle_dot(_to_screen(pts[0]), fc)
		_draw_circle_dot(_to_screen(pts[1]), fc)
		var labs: Array = f.get("labels", ["F₁", "F₂"])
		if labs.size() >= 2:
			_draw_label(_to_screen(pts[0]) + Vector2(-18, -8), str(labs[0]), fc, 13)
			_draw_label(_to_screen(pts[1]) + Vector2(8, -8), str(labs[1]), fc, 13)
	for l in _arr("lines"):
		var A := float(l.get("A", 1.0))
		var B := float(l.get("B", 1.0))
		var C := float(l.get("C", 0.0))
		var lc := _c(l.get("color", "#a878ff"), COL_VIOLET)
		var e0: Vector2
		var e1: Vector2
		if absf(B) > 1e-6:
			e0 = _to_screen(Vector2(-_range(), (-A * (-_range()) - C) / B))
			e1 = _to_screen(Vector2(_range(), (-A * _range() - C) / B))
		else:
			e0 = _to_screen(Vector2(-C / maxf(A, 1e-6), -_range()))
			e1 = _to_screen(Vector2(-C / maxf(A, 1e-6), _range()))
		if bool(l.get("dash", false)):
			draw_dashed_line(e0, e1, lc, 1.6, 7.0)
		else:
			draw_line(e0, e1, lc, 1.8)
		if l.has("label"):
			_draw_label((e0 + e1) * 0.5 + Vector2(10, -10), str(l["label"]), Color(lc, 0.9), 13)
	for sg in _arr("segments"):
		var p1 := _vec(sg.get("p1", [0, 0]), Vector2.ZERO)
		var p2 := _vec(sg.get("p2", [0, 0]), Vector2.ZERO)
		var sc := _c(sg.get("color", "#a878ff"), COL_VIOLET)
		if bool(sg.get("dash", false)):
			draw_dashed_line(_to_screen(p1), _to_screen(p2), sc, 1.6, 6.0)
		else:
			draw_line(_to_screen(p1), _to_screen(p2), sc, 1.8)
		if sg.has("label"):
			_draw_label((_to_screen(p1) + _to_screen(p2)) * 0.5 + Vector2(-20, -10), str(sg["label"]), Color(sc, 0.9), 13)
	for pt in _arr("points"):
		var pos := _to_screen(_vec(pt.get("p", [0, 0]), Vector2.ZERO))
		var pc := _c(pt.get("color", "#ffd479"), COL_GOLD)
		_draw_circle_dot(pos, pc)
		if pt.has("label"):
			_draw_label(pos + Vector2(8, -8), str(pt["label"]), Color(pc, 0.95), 14)
	for vc in _arr("vectors"):
		var va := _to_screen(_vec(vc.get("from", [0, 0]), Vector2.ZERO))
		var vb := _to_screen(_vec(vc.get("to", [0, 0]), Vector2.ZERO))
		var vcol := _c(vc.get("color", "#5ee6ff"), COL_CYAN)
		_draw_arrow(va, vb, vcol, 2.2)
		if vc.has("label"):
			_draw_label(vb + Vector2(8, -8), str(vc["label"]), vcol, 14)
	for ar in _arr("arcs"):
		var at := _to_screen(_vec(ar.get("at", [0, 0]), Vector2.ZERO))
		var pa := _to_screen(_vec(ar.get("a", [1, 0]), Vector2.ONE))
		var pb := _to_screen(_vec(ar.get("b", [0, 1]), Vector2.ONE))
		var acol := _c(ar.get("color", "#ffd479"), COL_GOLD)
		var rr := float(ar.get("r", 30.0))
		draw_arc(at, rr, (pa - at).angle(), (pb - at).angle(), 48, acol, 1.8)
		if ar.has("label"):
			_draw_label(at + Vector2(0, -rr - 12), str(ar["label"]), acol, 13)
	for tx in _arr("texts"):
		var tp := _to_screen(_vec(tx.get("p", [0, 0]), Vector2.ZERO))
		_draw_label(tp, str(tx.get("s", "")), _c(tx.get("color", "#9aa4bd"), COL_DIM), int(tx.get("size", 14)))

func _draw_arrow(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	draw_line(a, b, col, w)
	if a.distance_to(b) > 10.0:
		var dir := (b - a).normalized()
		var perp := Vector2(-dir.y, dir.x)
		var head := maxf(9.0, float(w) * 4.2)
		draw_colored_polygon(PackedVector2Array([
			b, b - dir * head + perp * (head * 0.42), b - dir * head - perp * (head * 0.42)
		]), col)

func _draw_label(pos: Vector2, text: String, col: Color, s: int) -> void:
	if text.is_empty() or col.a <= 0.01:
		return
	var px := UI.fs(s)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_rect(Rect2(pos + Vector2(-5, -px - 3), Vector2(w + 10, px + 7)), Color(0.04, 0.06, 0.11, 0.72 * col.a), true)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

func _draw_handle(p: Vector2, col: Color, label: String) -> void:
	var sp := _to_screen(p)
	var pulse := 1.0 + (0.10 if _dragging else 0.0) + 0.06 * sin(_t * 3.0)
	draw_circle(sp, HANDLE_R * pulse, Color(col, 0.16))
	draw_circle(sp, HANDLE_R * pulse * 0.5, Color(0.02, 0.04, 0.08, 0.9))
	draw_circle(sp, 7.5 * pulse + (2.0 if _dragging else 0.0), col)
	draw_arc(sp, 5.2, 0.0, TAU, 24, Color(1, 1, 1, 0.85), 1.2)
	if label != "":
		_draw_label(sp + Vector2(14, -14), label, col, 15)

func _draw_target(p: Vector2, label: String) -> void:
	var sp := _to_screen(p)
	var pulse := 7.0 + 2.0 * sin(_t * 2.6)
	draw_circle(sp, pulse, Color(COL_GREEN, 0.28))
	draw_arc(sp, 10.0, 0.0, TAU, 24, COL_GREEN, 1.6)
	draw_dashed_line(sp - Vector2(17, 0), sp + Vector2(17, 0), Color(COL_GREEN, 0.5), 1.0, 6.0)
	draw_dashed_line(sp - Vector2(0, 17), sp + Vector2(0, 17), Color(COL_GREEN, 0.5), 1.0, 6.0)
	if label != "":
		_draw_label(sp + Vector2(14, 20), label, COL_GREEN, 14)

func _draw_circle_dot(sp: Vector2, col: Color) -> void:
	draw_circle(sp, 5.0, Color(col, 0.95))
	draw_arc(sp, 7.0, 0.0, TAU, 24, Color(1, 1, 1, 0.85), 1.2)

# ---------------------------------------------------------------- 模型几何
func _geom() -> Dictionary:
	var m := str(_task.get("model", ""))
	var g: Dictionary = { "model": m }
	match m:
		"def_sum":
			var a := float(_task.get("a", 5.0))
			var c := float(_task.get("c", 3.0))
			var axis := str(_task.get("axis", "x"))
			var b := _ellipse_b(a, c)
			var fs := _foci(c, axis)
			g["a"] = a
			g["b"] = b
			g["c"] = c
			g["axis"] = axis
			g["f1"] = fs[0]
			g["f2"] = fs[1]
			g["p"] = _drag_pos
			g["d1"] = _drag_pos.distance_to(fs[0])
			g["d2"] = _drag_pos.distance_to(fs[1])
			g["sum"] = g["d1"] + g["d2"]
		"def_state":
			var c := float(_task.get("c", 3.0))
			var two_a := _param
			var two_c := 2.0 * c
			var state := "椭圆"
			if absf(two_a - two_c) <= 0.02:
				state = "线段"
			elif two_a < two_c:
				state = "无轨迹"
			g["c"] = c
			g["two_a"] = two_a
			g["two_c"] = two_c
			g["state"] = state
			if state == "椭圆":
				g["a"] = two_a * 0.5
				g["b"] = _ellipse_b(two_a * 0.5, c)
		"ecc":
			var a := float(_task.get("a", 5.0))
			var e := clampf(_param, 0.02, 0.98)
			var c := e * a
			var b := _ellipse_b(a, c)
			g["a"] = a
			g["e"] = e
			g["c"] = c
			g["b"] = b
		"focal_tri":
			var a := float(_task.get("a", 5.0))
			var b := float(_task.get("b", 3.0))
			var axis := str(_task.get("axis", "x"))
			var c := sqrt(maxf(a * a - b * b, 0.0004))
			var fs := _foci(c, axis)
			var p := _nearest_on_ellipse(_drag_pos, a, b, axis)
			var v1: Vector2 = fs[0] - p
			var v2: Vector2 = fs[1] - p
			var ths := clampf(v1.dot(v2) / (maxf(v1.length(), 1e-6) * maxf(v2.length(), 1e-6)), -1.0, 1.0)
			var theta := rad_to_deg(acos(ths))
			var area := c * absf(p.y) if axis == "x" else c * absf(p.x)
			g["a"] = a
			g["b"] = b
			g["c"] = c
			g["axis"] = axis
			g["f1"] = fs[0]
			g["f2"] = fs[1]
			g["p"] = p
			g["d1"] = p.distance_to(fs[0])
			g["d2"] = p.distance_to(fs[1])
			g["theta"] = theta
			g["area"] = area
		"point_diff":
			var a := float(_task.get("a", 5.0))
			var b := float(_task.get("b", 3.0))
			var axis := str(_task.get("axis", "x"))
			var pa := _vec(_task.get("A", [5, 0]), Vector2(5, 0))
			var pb := _nearest_on_ellipse(_drag_pos, a, b, axis)
			var mid := (pa + pb) * 0.5
			var kab := INF
			if absf(pb.x - pa.x) > 1e-6:
				kab = (pb.y - pa.y) / (pb.x - pa.x)
			var kom := INF
			if absf(mid.x) > 1e-6:
				kom = mid.y / mid.x
			g["a"] = a
			g["b"] = b
			g["axis"] = axis
			g["pa"] = pa
			g["pb"] = pb
			g["mid"] = mid
			g["kab"] = kab
			g["kom"] = kom
			g["prod"] = kab * kom
			g["const"] = -b * b / (a * a)
		"secant":
			var a := float(_task.get("a", 5.0))
			var b := float(_task.get("b", 3.0))
			var k := float(_task.get("k", 0.5))
			var mm := _drag_pos.y
			var A := b * b + a * a * k * k
			var B := 2.0 * a * a * k * mm
			var C := a * a * (mm * mm - b * b)
			var disc := B * B - 4.0 * A * C
			var x1 := 0.0
			var x2 := 0.0
			var ok := disc >= 0.0
			if ok:
				var sq := sqrt(disc)
				x1 = (-B - sq) / (2.0 * A)
				x2 = (-B + sq) / (2.0 * A)
			g["a"] = a
			g["b"] = b
			g["k"] = k
			g["m"] = mm
			g["A"] = A
			g["B"] = B
			g["C"] = C
			g["disc"] = disc
			g["x1"] = x1
			g["x2"] = x2
			g["xsum"] = (-B / A) if absf(A) > 1e-6 else 0.0
			g["xprod"] = (C / A) if absf(A) > 1e-6 else 0.0
			g["inter"] = ok
			g["p1"] = Vector2(x1, k * x1 + mm)
			g["p2"] = Vector2(x2, k * x2 + mm)
			g["chord"] = (sqrt(1.0 + k * k) * sqrt(maxf(disc, 0.0)) / A) if ok else 0.0
	return g

func _magnets(orig: Vector2) -> Vector2:
	var p := orig
	var m := str(_task.get("model", ""))
	match m:
		"def_sum":
			var a := float(_task.get("a", 5.0))
			var c := float(_task.get("c", 3.0))
			var b := _ellipse_b(a, c)
			var axis := str(_task.get("axis", "x"))
			var ne := _nearest_on_ellipse(p, a, b, axis)
			if p.distance_to(ne) <= 0.28:
				p = ne
		"focal_tri":
			var a := float(_task.get("a", 5.0))
			var b := float(_task.get("b", 3.0))
			p = _nearest_on_ellipse(p, a, b, str(_task.get("axis", "x")))
		"point_diff":
			var a := float(_task.get("a", 5.0))
			var b := float(_task.get("b", 3.0))
			p = _nearest_on_ellipse(p, a, b, str(_task.get("axis", "x")))
		"secant":
			p = Vector2(0.0, clampf(p.y, -_range(), _range()))
	return _clamp_pos(p)

func _check_ok() -> bool:
	var g := _geom()
	var tol := float(_task.get("tol", 0.3))
	match str(g.get("model", "")):
		"def_sum":
			return absf(float(g["sum"]) - float(_task.get("target", 10.0))) <= tol
		"def_state":
			return str(g["state"]) == str(_task.get("target", "椭圆"))
		"ecc":
			return absf(float(g["e"]) - float(_task.get("target", 0.6))) <= tol
		"focal_tri":
			return absf(float(g["area"]) - float(_task.get("target", 3.0))) <= tol
		"point_diff":
			var tm := _vec(_task.get("target", [0, 0]), Vector2.ZERO)
			return (g["mid"] as Vector2).distance_to(tm) <= tol
		"secant":
			if not bool(g["inter"]):
				return false
			return absf(float(g["chord"]) - float(_task.get("target", 6.0))) <= tol
	return false

func _readout() -> String:
	var g := _geom()
	match str(g.get("model", "")):
		"def_sum":
			return "|PF₁|+|PF₂| = %s  (2a = %s)" % [_fmt(g["sum"]), _fmt(2.0 * float(g["a"]))]
		"def_state":
			return "2a = %s, 2c = %s  →  轨迹：%s" % [_fmt(g["two_a"]), _fmt(g["two_c"]), str(g["state"])]
		"ecc":
			return "e = c/a = %s, c = %s, b = %s" % [_fmt(g["e"]), _fmt(g["c"]), _fmt(g["b"])]
		"focal_tri":
			return "∠F₁PF₂ = %s°， S = c·|y| = %s" % [_fmt(g["theta"]), _fmt(g["area"])]
		"point_diff":
			return "k_AB = %s, k_OM = %s, 乘积 = %s  (定值 -b²/a² = %s)" % [
				_fmt(g["kab"]), _fmt(g["kom"]), _fmt(g["prod"]), _fmt(g["const"])]
		"secant":
			if not bool(g["inter"]):
				return "Δ = %s < 0  直线与椭圆无交点" % _fmt(g["disc"])
			return "Δ = %s, x₁+x₂ = %s, x₁x₂ = %s, |AB| = %s" % [
				_fmt(g["disc"]), _fmt(g["xsum"]), _fmt(g["xprod"]), _fmt(g["chord"])]
	return ""

# ---------------------------------------------------------------- 任务绘制
func _draw_task() -> void:
	if mode != "task":
		return
	var g := _geom()
	var m := str(g.get("model", ""))
	match m:
		"def_sum":
			var a: float = g["a"]
			var b: float = g["b"]
			var axis: String = g["axis"]
			var f1: Vector2 = g["f1"]
			var f2: Vector2 = g["f2"]
			_draw_ellipse(a, b, axis, Color(COL_PINK, 0.5), 1.6, true)
			_draw_circle_dot(_to_screen(f1), COL_RED)
			_draw_circle_dot(_to_screen(f2), COL_RED)
			_draw_label(_to_screen(f1) + Vector2(-18, -8), "F₁", COL_RED, 14)
			_draw_label(_to_screen(f2) + Vector2(8, -8), "F₂", COL_RED, 14)
			draw_line(_to_screen(f1), _to_screen(_drag_pos), Color(COL_CYAN, 0.85), 1.8)
			draw_line(_to_screen(f2), _to_screen(_drag_pos), Color(COL_GOLD, 0.85), 1.8)
			_draw_label((_to_screen(f1) + _to_screen(_drag_pos)) * 0.5 + Vector2(0, -10), "d₁", COL_CYAN, 13)
			_draw_label((_to_screen(f2) + _to_screen(_drag_pos)) * 0.5 + Vector2(0, 14), "d₂", COL_GOLD, 13)
			_draw_handle(_drag_pos, COL_GOLD, "P")
		"def_state":
			var c: float = g["c"]
			var fs := _foci(c, "x")
			_draw_circle_dot(_to_screen(fs[0]), COL_RED)
			_draw_circle_dot(_to_screen(fs[1]), COL_RED)
			_draw_label(_to_screen(fs[0]) + Vector2(-18, -8), "F₁", COL_RED, 14)
			_draw_label(_to_screen(fs[1]) + Vector2(8, -8), "F₂", COL_RED, 14)
			var st := str(g["state"])
			if st == "椭圆":
				_draw_ellipse(g["a"], g["b"], "x", COL_PINK, 2.2, false)
				_draw_label(_to_screen(Vector2(0, g["b"])) + Vector2(8, -6), "2a > 2c · 椭圆", COL_PINK, 14)
			elif st == "线段":
				draw_line(_to_screen(fs[0]), _to_screen(fs[1]), COL_PINK, 3.0)
				_draw_label(_to_screen(Vector2(0, 0.4)) + Vector2(8, -10), "2a = 2c · 线段", COL_PINK, 14)
			else:
				_draw_label(_to_screen(Vector2(0, 0.6)) + Vector2(8, -10), "2a < 2c · 无轨迹", COL_RED, 15)
			_draw_slider("2a")
		"ecc":
			_draw_ellipse(g["a"], g["b"], "x", COL_PINK, 2.2, false)
			var c2: float = g["c"]
			var fs2 := _foci(c2, "x")
			_draw_circle_dot(_to_screen(fs2[0]), COL_RED)
			_draw_circle_dot(_to_screen(fs2[1]), COL_RED)
			_draw_label(_to_screen(Vector2(g["a"], 0)) + Vector2(4, -6), "a", COL_DIM, 13)
			_draw_label(_to_screen(Vector2(0, g["b"])) + Vector2(6, -6), "b", COL_DIM, 13)
			_draw_slider("e")
		"focal_tri":
			var a3: float = g["a"]
			var b3: float = g["b"]
			var axis3: String = g["axis"]
			var f1b: Vector2 = g["f1"]
			var f2b: Vector2 = g["f2"]
			var p: Vector2 = g["p"]
			_draw_ellipse(a3, b3, axis3, Color(COL_PINK, 0.6), 1.8, false)
			_draw_circle_dot(_to_screen(f1b), COL_RED)
			_draw_circle_dot(_to_screen(f2b), COL_RED)
			_draw_label(_to_screen(f1b) + Vector2(-18, -8), "F₁", COL_RED, 14)
			_draw_label(_to_screen(f2b) + Vector2(8, -8), "F₂", COL_RED, 14)
			draw_colored_polygon(PackedVector2Array([_to_screen(f1b), _to_screen(f2b), _to_screen(p)]), Color(COL_GOLD, 0.14))
			draw_line(_to_screen(f1b), _to_screen(p), Color(COL_CYAN, 0.9), 2.0)
			draw_line(_to_screen(f2b), _to_screen(p), Color(COL_GOLD, 0.9), 2.0)
			draw_line(_to_screen(f1b), _to_screen(f2b), Color(COL_DIM, 0.7), 1.4)
			var sp := _to_screen(p)
			var da := (_to_screen(f1b) - sp).normalized()
			var db := (_to_screen(f2b) - sp).normalized()
			var aa := da.angle()
			var span := wrapf(db.angle() - aa, -PI, PI)
			var rad := minf(38.0, sp.distance_to(_to_screen(f1b)) * 0.45)
			draw_arc(sp, rad, aa, aa + span, 40, COL_GOLD, 2.0)
			_draw_label(sp + Vector2(cos(aa + span * 0.5), sin(aa + span * 0.5)) * (rad + 12), "%s°" % _fmt(g["theta"]), COL_GOLD, 13)
			_draw_handle(p, COL_GOLD, "P")
		"point_diff":
			var a4: float = g["a"]
			var b4: float = g["b"]
			var axis4: String = g["axis"]
			var pa: Vector2 = g["pa"]
			var pb: Vector2 = g["pb"]
			var mid: Vector2 = g["mid"]
			_draw_ellipse(a4, b4, axis4, Color(COL_PINK, 0.55), 1.8, false)
			_draw_circle_dot(_to_screen(Vector2.ZERO), COL_DIM)
			_draw_label(_to_screen(Vector2.ZERO) + Vector2(-14, 14), "O", COL_DIM, 12)
			draw_line(_to_screen(pa), _to_screen(pb), Color(COL_CYAN, 0.85), 2.0)
			draw_line(_to_screen(Vector2.ZERO), _to_screen(mid), Color(COL_VIOLET, 0.9), 1.8)
			_draw_circle_dot(_to_screen(pa), COL_CYAN)
			_draw_circle_dot(_to_screen(pb), COL_GOLD)
			_draw_circle_dot(_to_screen(mid), COL_VIOLET)
			_draw_label(_to_screen(pa) + Vector2(-16, -8), "A", COL_CYAN, 14)
			_draw_label(_to_screen(pb) + Vector2(10, -8), "B(拖动)", COL_GOLD, 13)
			_draw_label(_to_screen(mid) + Vector2(6, 16), "M 中点", COL_VIOLET, 13)
			_draw_target(_vec(_task.get("target", [0, 0]), Vector2.ZERO), _task.get("target_label", "把中点 M 拖到此处"))
			_draw_handle(pb, COL_GOLD, "B")
		"secant":
			var a5: float = g["a"]
			var b5: float = g["b"]
			var k: float = g["k"]
			var mm: float = g["m"]
			_draw_ellipse(a5, b5, "x", Color(COL_PINK, 0.7), 2.0, false)
			var rr := _range()
			var le0 := _to_screen(Vector2(-rr, k * (-rr) + mm))
			var le1 := _to_screen(Vector2(rr, k * rr + mm))
			var lcol := COL_GREEN if bool(g["inter"]) else COL_RED
			draw_line(le0, le1, lcol, 2.2)
			if bool(g["inter"]):
				var ip1: Vector2 = g["p1"]
				var ip2: Vector2 = g["p2"]
				_draw_circle_dot(_to_screen(ip1), COL_GOLD)
				_draw_circle_dot(_to_screen(ip2), COL_GOLD)
				_draw_label(_to_screen(ip1) + Vector2(8, -8), "A", COL_GOLD, 13)
				_draw_label(_to_screen(ip2) + Vector2(8, -8), "B", COL_GOLD, 13)
			_draw_label(_to_screen(Vector2(-rr * 0.9, k * (-rr * 0.9) + mm)) + Vector2(6, -10), "y = %sx + %s" % [_fmt(k), _fmt(mm)], lcol, 13)
			_draw_handle(_drag_pos, COL_GOLD, "拖动改变 m")
	var read := readout()
	if read != "":
		_draw_label(Vector2(12, 12), read, COL_GREEN if _check_ok() else Color.ORANGE, 15)

func _draw_slider(label: String) -> void:
	var g := _slider_geom()
	var y := float(g[2])
	var x0 := float(g[0])
	var x1 := float(g[1])
	draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.15), 6.0)
	var tp := _param_to_x(_param)
	draw_line(Vector2(x0, y), Vector2(tp, y), Color(COL_PINK, 0.8), 6.0)
	var knob := 9.5 + (2.0 if _slider_drag else 0.0) + 0.6 * sin(_t * 4.0)
	draw_circle(Vector2(tp, y), knob + 3.5, Color(0.02, 0.04, 0.08, 0.92))
	draw_circle(Vector2(tp, y), knob, COL_PINK)
	var ss := UI.fs(17)
	draw_string(UI.mono_font(), Vector2(x0, y - ss - 5.0), "%s = %s" % [label, _fmt(_param)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, ss, COL_GREEN if _check_ok() else COL_TEXT)
	_draw_label(Vector2(x1 - UI.fs(96.0), y - ss - 5.0), "拖动调节 →", COL_DIM, 13)

func _state_changed() -> void:
	state_changed.emit(readout())

# ---------------------------------------------------------------- 交互
func _gui_input(event: InputEvent) -> void:
	if mode != "task":
		return
	var ctrl := _control()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if ctrl == "slider":
				var y := float(_slider_geom()[2])
				if absf(event.position.y - y) < 30.0:
					_slider_drag = true
					_param = _x_to_param(event.position.x)
					_state_changed()
					accept_event()
			else:
				var sp := _to_screen(_drag_pos)
				if event.position.distance_to(sp) <= HANDLE_R + 26.0:
					_dragging = true
					accept_event()
		else:
			if _slider_drag or _dragging:
				_state_changed()
				accept_event()
			_slider_drag = false
			_dragging = false
	elif event is InputEventMouseMotion:
		if _slider_drag and ctrl == "slider":
			_param = _x_to_param(event.position.x)
			_state_changed()
			accept_event()
		elif _dragging and ctrl != "slider":
			_drag_pos = _magnets(_clamp_pos(_to_math(event.position)))
			_state_changed()
			accept_event()
	queue_redraw()
