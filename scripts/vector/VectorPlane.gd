class_name VectorPlane
extends Control
## 平面向量 · 可交互坐标平面(纯代码绘制，无图片依赖)。
## 被动图元：网格 / 坐标轴 / 向量箭头 / 点 / 线段 / 圆 / 夹角弧 / 直角标 / 文本。
## 交互式学习：拖动矢量箭头或动点，右侧实时读出目标量(夹角·点积·投影·模长·
## 系数和·极化值等)，把数值"调"到目标即通关。用动手取代死记，用手感学会知识点。
## 用法：set_scene(静态图形) → begin_task(交互任务) → is_task_ok() 判定。

signal state_changed(value: String)

const COL_GRID := Color(1.0, 1.0, 1.0, 0.05)
const COL_AXIS := Color(0.55, 0.62, 0.78, 1.0)
const COL_TEXT := Color(0.92, 0.96, 1.0, 1.0)
const COL_DIM := Color(0.62, 0.68, 0.80, 1.0)
const COL_CYAN := Color(0.369, 0.902, 1.0, 1.0)
const COL_GOLD := Color(1.0, 0.83, 0.47, 1.0)
const COL_VIOLET := Color(0.659, 0.44, 0.792, 1.0)
const COL_GREEN := Color(0.204, 0.827, 0.6, 1.0)
const COL_RED := Color(0.984, 0.443, 0.522, 1.0)

const MODELS := [
	"vec_add", "vec_add_par", "vec_sub", "unit_len", "perp", "parallel",
	"dot_product", "proj", "point_delta", "midpoint", "diag_equal",
	"dot_constant", "iso_line", "polar",
]

const HANDLE_R := 13.0

var _scene: Dictionary = {}
var _task: Dictionary = {}
var _t := 0.0
var _reveal := 0.0

var mode := ""              # "" / "task"
var _drag_pos := Vector2.ZERO
var _dragging := false

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
	var st: Array = _task.get("start", [0, 0])
	_drag_pos = Vector2(float(st[0]), float(st[1]))
	_drag_pos = _clamp_pos(_drag_pos)
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

# ---------------------------------------------------------------- 坐标换算
func _range() -> float:
	var r := 5.0
	if _scene.has("range"):
		r = float(_scene["range"])
	if _scene.has("x") and _scene["x"] is Array and (_scene["x"].size() == 2):
		r = maxf(r, maxf(absf(float(_scene["x"][0])), absf(float(_scene["x"][1]))))
	if _scene.has("y") and _scene["y"] is Array and (_scene["y"].size() == 2):
		r = maxf(r, maxf(absf(float(_scene["y"][0])), absf(float(_scene["y"][1]))))
	return maxf(r, 1.0)

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
	return "%.1f" % v

func _f2(v: Vector2) -> String:
	return "(%s, %s)" % [_fmt(v.x), _fmt(v.y)]

func _vec(a: Variant, dflt: Vector2) -> Vector2:
	if a is Array and a.size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return dflt

func _c(v, dflt: Color) -> Color:
	if v is String and v.begins_with("#") and (v.length() == 7 or v.length() == 9):
		return Color(v)
	return dflt

func _arr(k: String) -> Array:
	var v: Variant = _scene.get(k, [])
	return v if v is Array else []

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

func _draw_static() -> void:
	for sg in _arr("segments"):
		var p1 := _vec(sg.get("p1", [0, 0]), Vector2.ZERO)
		var p2 := _vec(sg.get("p2", [0, 0]), Vector2.ZERO)
		var c := _c(sg.get("color", "#a878ff"), Color(COL_VIOLET))
		if bool(sg.get("dash", false)):
			draw_dashed_line(_to_screen(p1), _to_screen(p2), c, 1.6, 6.0)
		else:
			draw_line(_to_screen(p1), _to_screen(p2), c, 1.8)
		if sg.has("label"):
			_draw_label((_to_screen(p1) + _to_screen(p2)) * 0.5 + Vector2(-20, -10), str(sg["label"]), Color(c, 0.9), 13)
	for ci in _arr("circles"):
		var center := _vec(ci.get("c", [0, 0]), Vector2.ZERO)
		var r := float(ci.get("r", 1.0)) * _scale()
		var c := _c(ci.get("color", "#9270CA"), Color(COL_VIOLET))
		draw_arc(_to_screen(center), r, 0.0, TAU, 72, c, 1.8)
	for ar in _arr("arcs"):
		var at := _to_screen(_vec(ar.get("at", [0, 0]), Vector2.ZERO))
		var pa := _to_screen(_vec(ar.get("a", [1, 0]), Vector2.ONE))
		var pb := _to_screen(_vec(ar.get("b", [0, 1]), Vector2.ONE))
		var c := _c(ar.get("color", "#ffd479"), Color(COL_GOLD))
		var rr := float(ar.get("r", 30.0))
		var aa := (pa - at).angle()
		var ab := (pb - at).angle()
		draw_arc(at, rr, aa, ab, 48, c, 1.8)
	for ra in _arr("right_angles"):
		var at := _to_screen(_vec(ra.get("at", [0, 0]), Vector2.ZERO))
		var da := (_to_screen(_vec(ra.get("a", [1, 0]), Vector2.ONE)) - at).normalized()
		var db := (_to_screen(_vec(ra.get("b", [0, 1]), Vector2.ONE)) - at).normalized()
		var c := _c(ra.get("color", "#fb7185"), Color(COL_RED))
		var s := float(ra.get("size", 12.0))
		draw_polyline(PackedVector2Array([at + da * s, at + da * s + db * s, at + db * s]), c, 1.6)
	for pt in _arr("points"):
		var pos := _to_screen(_vec(pt.get("p", [0, 0]), Vector2.ZERO))
		var c := _c(pt.get("color", "#ffd479"), Color(COL_GOLD))
		draw_circle(pos, 4.0, Color(c, 0.95))
		if pt.has("label"):
			_draw_label(pos + Vector2(8, -8), str(pt["label"]), Color(c, 0.95), 14)
	for vc in _arr("vectors"):
		var a := _to_screen(_vec(vc.get("from", [0, 0]), Vector2.ZERO))
		var b := _to_screen(_vec(vc.get("to", [0, 0]), Vector2.ZERO))
		_draw_arrow(a, b, _c(vc.get("color", "#5ee6ff"), Color(COL_CYAN)), 2.2)
		if vc.has("label"):
			_draw_label(b + Vector2(8, -8), str(vc["label"]), _c(vc.get("color", "#5ee6ff"), Color(COL_CYAN)), 14)

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
	var pulse := 6.0 + 2.0 * sin(_t * 2.6)
	draw_circle(sp, pulse, Color(COL_GREEN, 0.28))
	draw_arc(sp, 9.0, 0.0, TAU, 24, COL_GREEN, 1.6)
	draw_dashed_line(sp - Vector2(16, 0), sp + Vector2(16, 0), Color(COL_GREEN, 0.5), 1.0, 6.0)
	draw_dashed_line(sp - Vector2(0, 16), sp + Vector2(0, 16), Color(COL_GREEN, 0.5), 1.0, 6.0)
	if label != "":
		_draw_label(sp + Vector2(14, 20), label, COL_GREEN, 14)

func _task_label() -> String:
	return str(_task.get("label", "拖动金点，对准目标"))

# ---------------------------------------------------------------- 模型几何
## 返回当前任务的可测值 + 辅助绘制所需的量；由 _draw_task 与 _check_ok 共用。
func _geom() -> Dictionary:
	var m := str(_task.get("model", ""))
	var g: Dictionary = {}
	g["model"] = m
	match m:
		"vec_add", "vec_add_par":
			var a := _vec(_task.get("a", [2, 1]), Vector2(2, 1))
			var layout := str(_task.get("layout", "head_to_tail"))
			var b_base := Vector2.ZERO if layout == "tail_to_tail" else a
			var b := _drag_pos - b_base
			g["a"] = a
			g["b"] = b
			g["b_base"] = b_base
			g["sum"] = a + b
			g["layout"] = layout
		"vec_sub":
			var a := _drag_pos
			var b := _vec(_task.get("b", [1, 2]), Vector2(1, 2))
			g["a"] = a
			g["b"] = b
			g["diff"] = a - b
		"unit_len":
			var v := _drag_pos
			g["v"] = v
			g["len"] = v.length()
		"perp", "parallel":
			var a := _vec(_task.get("a", [2, 0]), Vector2(2, 0))
			var b := _drag_pos
			g["a"] = a
			g["b"] = b
			g["dot"] = a.dot(b)
			g["cross"] = a.cross(b)
			g["lena"] = a.length()
			g["lenb"] = b.length()
			g["ths"] = clampf(a.dot(b) / (maxf(a.length(), 1e-6) * maxf(b.length(), 1e-6)), -1.0, 1.0)
			g["theta"] = rad_to_deg(acos(g["ths"]))
			g["sin_abs"] = absf(a.cross(b)) / (maxf(a.length(), 1e-6) * maxf(b.length(), 1e-6))
		"dot_product":
			var a := _vec(_task.get("a", [2, 0]), Vector2(2, 0))
			var b := _drag_pos
			g["a"] = a
			g["b"] = b
			g["dot"] = a.dot(b)
		"proj":
			var a := _vec(_task.get("a", [2, 0]), Vector2(2, 0))
			var b := _drag_pos
			g["a"] = a
			g["b"] = b
			g["proj"] = a.dot(b) / maxf(a.length(), 1e-6)
		"point_delta":
			var pa := _vec(_task.get("a", [1, 2]), Vector2(1, 2))
			var pb := _drag_pos
			g["pa"] = pa
			g["pb"] = pb
			g["ab"] = pb - pa
		"midpoint":
			var pa := _vec(_task.get("a", [1, 1]), Vector2(1, 1))
			var pb := _vec(_task.get("b", [5, 4]), Vector2(5, 4))
			g["pa"] = pa
			g["pb"] = pb
			g["m"] = _drag_pos
			g["ma"] = pa.distance_to(_drag_pos)
			g["mb"] = pb.distance_to(_drag_pos)
		"diag_equal":
			var a := _vec(_task.get("a", [2, 0]), Vector2(2, 0))
			var b := _drag_pos
			g["a"] = a
			g["b"] = b
			g["d1"] = (a + b).length()
			g["d2"] = (a - b).length()
		"dot_constant":
			var m0 := _vec(_task.get("m", [0, 1]), Vector2(0, 1))
			var p := _drag_pos
			g["m"] = m0
			g["p"] = p
			g["val"] = m0.dot(p)
		"iso_line":
			var a := _vec(_task.get("a", [3, 1]), Vector2(3, 1))
			var b := _vec(_task.get("b", [1, 3]), Vector2(1, 3))
			var c := _drag_pos
			g["a"] = a
			g["b"] = b
			g["c"] = c
			var det := a.x * b.y - a.y * b.x
			if absf(det) > 1e-6:
				g["x"] = (c.x * b.y - c.y * b.x) / det
				g["y"] = (a.x * c.y - a.y * c.x) / det
			else:
				g["x"] = 0.0
				g["y"] = 0.0
			g["s"] = float(g.get("x", 0.0)) + float(g.get("y", 0.0))
		"polar":
			var d := absf(float(_task.get("d", 2.0)))
			var pa := Vector2(-d, 0)
			var pb := Vector2(d, 0)
			var p := _drag_pos
			g["d"] = d
			g["pa"] = pa
			g["pb"] = pb
			g["p"] = p
			g["pm2"] = p.length_squared()
			g["val"] = g["pm2"] - d * d
	return g

func _magnets(orig: Vector2) -> Vector2:
	var p := orig
	var m := str(_task.get("model", ""))
	var r := _range()
	match m:
		"midpoint":
			var pa := _vec(_task.get("a", [1, 1]), Vector2(1, 1))
			var pb := _vec(_task.get("b", [5, 4]), Vector2(5, 4))
			var mid := (pa + pb) * 0.5
			if p.distance_to(mid) <= 0.22:
				p = mid
		"dot_constant":
			var m0 := _vec(_task.get("m", [0, 1]), Vector2(0, 1))
			var k := float(_task.get("target", 1.0))
			var lensq := maxf(m0.length_squared(), 1e-6)
			var proj := (p.dot(m0) - k) / lensq
			var foot := p - m0 * proj
			if p.distance_to(foot) <= 0.22:
				p = foot
		"iso_line":
			var a := _vec(_task.get("a", [3, 1]), Vector2(3, 1))
			var b := _vec(_task.get("b", [1, 3]), Vector2(1, 3))
			var dd := b - a
			var t := (p - a).dot(dd) / maxf(dd.length_squared(), 1e-6)
			var foot := a + dd * t
			if p.distance_to(foot) <= 0.25:
				p = foot
		"unit_len":
			var L := absf(float(_task.get("target", 1.0)))
			var len := p.length()
			if absf(len - L) <= 0.22:
				p = p.normalized() * L
			elif absf(len - roundf(L)) <= 0.22:
				p = p.normalized() * roundf(L)
	return _clamp_pos(p)

func _check_ok() -> bool:
	var g := _geom()
	var tgt := _vec(_task.get("target", [0, 0]), Vector2.ZERO)
	var tg: Variant = _task.get("target", 0.0)
	var sval := float(tg) if (tg is int or tg is float) else 0.0
	var tol := float(_task.get("tol", 0.3))
	match str(g.get("model", "")):
		"vec_add", "vec_add_par":
			return g["sum"].distance_to(tgt) <= tol
		"vec_sub":
			return g["diff"].distance_to(tgt) <= tol
		"point_delta":
			return g["ab"].distance_to(tgt) <= tol
		"midpoint":
			return g["m"].distance_to(tgt) <= tol
		"unit_len":
			return absf(g["len"] - sval) <= float(_task.get("tol", 0.15))
		"perp":
			return absf(g["theta"] - sval) <= tol
		"parallel":
			return g["sin_abs"] <= float(_task.get("tol", 0.025))
		"dot_product":
			return absf(g["dot"] - sval) <= float(_task.get("tol", 0.2))
		"proj":
			return absf(g["proj"] - sval) <= float(_task.get("tol", 0.18))
		"diag_equal":
			return absf(g["d1"] - g["d2"]) <= float(_task.get("tol", 0.15))
		"dot_constant":
			return absf(g["val"] - sval) <= float(_task.get("tol", 0.2))
		"iso_line":
			return absf(g["s"] - sval) <= float(_task.get("tol", 0.08))
		"polar":
			return absf(g["val"] - sval) <= float(_task.get("tol", 0.4))
	return false

func _readout() -> String:
	var g := _geom()
	match str(g.get("model", "")):
		"vec_add", "vec_add_par":
			return "a + b = %s" % _f2(g["sum"])
		"vec_sub":
			return "a − b = %s" % _f2(g["diff"])
		"unit_len":
			return "|b| = %s" % _fmt(g["len"])
		"perp":
			return "θ = %s°， a·b = %s" % [_fmt(g["theta"]), _fmt(g["dot"])]
		"parallel":
			return "sinθ = %s" % _fmt(g["sin_abs"])
		"dot_product":
			return "a·b = %s" % _fmt(g["dot"])
		"proj":
			return "投影 = %s(%s)" % [_fmt(g["proj"]), "正·方向一致" if g["proj"] >= 0 else "负·方向相反"]
		"point_delta":
			return "AB = %s" % _f2(g["ab"])
		"midpoint":
			return "|MA| = %s, |MB| = %s" % [_fmt(g["ma"]), _fmt(g["mb"])]
		"diag_equal":
			return "|a+b| = %s, |a−b| = %s" % [_fmt(g["d1"]), _fmt(g["d2"])]
		"dot_constant":
			return "OP·m = %s" % _fmt(g["val"])
		"iso_line":
			return "x = %s, y = %s, x+y = %s" % [_fmt(g["x"]), _fmt(g["y"]), _fmt(g["s"])]
		"polar":
			return "PA·PB = %s" % _fmt(g["val"])
	return ""

# ---------------------------------------------------------------- 任务绘制
func _draw_task() -> void:
	if mode != "task":
		return
	var g := _geom()
	var m := str(g.get("model", ""))
	var tgt := _vec(_task.get("target", [0, 0]), Vector2.ZERO)
	match m:
		"vec_add", "vec_add_par":
			var a: Vector2 = g["a"]
			var bs: Vector2 = g["b_base"]
			var b: Vector2 = g["b"]
			var sm: Vector2 = g["sum"]
			var sc := _to_screen(sm)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(a), COL_CYAN, 2.2)
			_draw_label(_to_screen(a) + Vector2(8, -8), "a", COL_CYAN, 14)
			_draw_arrow(_to_screen(bs), _to_screen(_drag_pos), COL_GOLD, 2.2)
			_draw_label(_to_screen(_drag_pos) + Vector2(8, -8), "b", COL_GOLD, 14)
			if bool(_task.get("hint_diag", true)):
				var pc := _to_screen(Vector2.ZERO)
				draw_dashed_line(pc, _to_screen(Vector2(a.x, 0)), COL_DIM, 1.0, 5.0)
				draw_dashed_line(pc, _to_screen(Vector2(0, a.y)), COL_DIM, 1.0, 5.0)
				_draw_label(_to_screen(a + b * 0.5) + Vector2(0, -10), "平行推 a → b", COL_DIM, 12)
			_draw_arrow(_to_screen(Vector2.ZERO), sc, COL_VIOLET, 2.6)
			_draw_label(sc + Vector2(10, -6), "a + b", Color(COL_VIOLET), 15)
			_draw_target(tgt, _task.get("target_label", "目标： %s" % _f2(tgt)))
		"vec_sub":
			var a: Vector2 = g["a"]
			var b: Vector2 = g["b"]
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(a), COL_GOLD, 2.2)
			_draw_label(_to_screen(a) + Vector2(8, -8), "a", COL_GOLD, 14)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(b), COL_CYAN, 2.2)
			_draw_label(_to_screen(b) + Vector2(8, -8), "b", COL_CYAN, 14)
			draw_dashed_line(_to_screen(b), _to_screen(a), COL_DIM, 1.0, 5.0)
			_draw_arrow(_to_screen(b), _to_screen(a), COL_VIOLET, 2.6)
			_draw_label((_to_screen(b) + _to_screen(a)) * 0.5, "a − b", Color(COL_VIOLET), 15)
			var td := tgt
			_draw_target(td, _task.get("target_label", "让 a − b 指向此"))
		"unit_len":
			var v: Vector2 = g["v"]
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(v), COL_GOLD, 2.2)
			_draw_label(_to_screen(v) + Vector2(8, -8), "b", COL_GOLD, 14)
			var L := absf(float(_task.get("target", 1.0)))
			draw_arc(_to_screen(Vector2.ZERO), L * _scale(), 0.0, TAU, 72, Color(COL_GREEN, 0.65), 1.6)
			_draw_label(_to_screen(Vector2(L - 0.35, 0.45)), "|b|=%s" % _fmt(L), COL_GREEN, 13)
		"perp", "parallel":
			var a: Vector2 = g["a"]
			var b: Vector2 = g["b"]
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(a), COL_CYAN, 2.2)
			_draw_label(_to_screen(a) + Vector2(8, -8), "a", COL_CYAN, 14)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(b), COL_GOLD, 2.2)
			_draw_label(_to_screen(b) + Vector2(8, -8), "b", COL_GOLD, 14)
			if m == "perp":
				var sp0 := _to_screen(Vector2.ZERO)
				var da := (_to_screen(a) - sp0).normalized()
				var db := (_to_screen(b) - sp0).normalized()
				var ang_a := da.angle()
				var ang_b := db.angle()
				var span := wrapf(ang_b - ang_a, -PI, PI)
				var rad := minf(34.0, (sp0.distance_to(_to_screen(b))) * 0.5)
				draw_arc(sp0, rad, ang_a, ang_a + span, 40, COL_GOLD, 1.8)
				_draw_label(sp0 + Vector2(cos(ang_a + span * 0.5), sin(ang_a + span * 0.5)) * (rad + 14),
					"%s°" % _fmt(g["theta"]), COL_GOLD, 14)
			else:
				_draw_label((_to_screen(a) + _to_screen(b)) * 0.5 + Vector2(0, 16), "sinθ = %s" % _fmt(g["sin_abs"]), COL_GOLD, 13)
			_draw_target(tgt, _task.get("target_label", "目标 %s°" % _fmt(tgt.x)))
		"dot_product":
			var a: Vector2 = g["a"]
			var b: Vector2 = g["b"]
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(a), COL_CYAN, 2.2)
			_draw_label(_to_screen(a) + Vector2(8, -8), "a", COL_CYAN, 14)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(b), COL_GOLD, 2.2)
			_draw_label(_to_screen(b) + Vector2(8, -8), "b", COL_GOLD, 14)
			_draw_target(tgt, _task.get("target_label", "a·b = %s" % _fmt(tgt.x)))
		"proj":
			var a: Vector2 = g["a"]
			var b: Vector2 = g["b"]
			var pr: float = g["proj"]
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(a), COL_CYAN, 2.2)
			_draw_label(_to_screen(a) + Vector2(8, -8), "a", COL_CYAN, 14)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(b), COL_GOLD, 2.2)
			_draw_label(_to_screen(b) + Vector2(8, -8), "b", COL_GOLD, 14)
			var foot := Vector2(pr, 0)
			_draw_dashed_line_to(_to_screen(b), _to_screen(foot), COL_DIM)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(foot), COL_GREEN if pr >= 0 else COL_RED, 2.4)
			_draw_label(_to_screen(foot) + Vector2(6, -8), "投影 %s" % _fmt(pr),
				COL_GREEN if pr >= 0 else COL_RED, 14)
			_draw_target(tgt, "目标 投影 = %s" % _fmt(tgt.x))
		"point_delta":
			var pa: Vector2 = g["pa"]
			var pb: Vector2 = g["pb"]
			_draw_label(_to_screen(pa) + Vector2(-16, -8), "A", COL_CYAN, 14)
			_draw_circle_dot(_to_screen(pa), COL_CYAN)
			_draw_arrow(_to_screen(pa), _to_screen(pb), COL_GOLD, 2.2)
			_draw_label(_to_screen(pb) + Vector2(10, 0), "B(拖动)", COL_GOLD, 13)
			_draw_target(pa + tgt, "目标 AB = %s" % _f2(tgt))
		"midpoint":
			var pa: Vector2 = g["pa"]
			var pb: Vector2 = g["pb"]
			_draw_circle_dot(_to_screen(pa), COL_CYAN)
			_draw_circle_dot(_to_screen(pb), COL_CYAN)
			_draw_label(_to_screen(pa) + Vector2(-14, -6), "A", COL_CYAN, 14)
			_draw_label(_to_screen(pb) + Vector2(6, -16), "B", COL_CYAN, 14)
			draw_line(_to_screen(pa), _to_screen(pb), Color(COL_CYAN, 0.55), 1.6)
			_draw_arrow(_to_screen(_drag_pos), _to_screen(pa), COL_DIM, 1.6)
			_draw_arrow(_to_screen(_drag_pos), _to_screen(pb), COL_DIM, 1.6)
			_draw_label((_to_screen(pa) + _to_screen(_drag_pos)) * 0.5 + Vector2(0, -12), "|MA|", COL_DIM, 12)
			_draw_label((_to_screen(pb) + _to_screen(_drag_pos)) * 0.5 + Vector2(0, 14), "|MB|", COL_DIM, 12)
			_draw_target((pa + pb) * 0.5, "中点目标")
		"diag_equal":
			var a: Vector2 = g["a"]
			var b: Vector2 = g["b"]
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(a), COL_CYAN, 2.2)
			_draw_label(_to_screen(a) + Vector2(8, -8), "a", COL_CYAN, 14)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(b), COL_GOLD, 2.2)
			_draw_label(_to_screen(b) + Vector2(8, -8), "b", COL_GOLD, 14)
			_draw_arrow(_to_screen(a), _to_screen(a + b), COL_DIM, 1.6)
			_draw_arrow(_to_screen(b), _to_screen(a + b), COL_DIM, 1.6)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(a + b), COL_VIOLET, 2.4)
			_draw_label(_to_screen(a + b) + Vector2(8, -8), "a+b", Color(COL_VIOLET), 14)
			_draw_arrow(_to_screen(b), _to_screen(a), COL_GREEN, 2.0)
			_draw_label((_to_screen(b) + _to_screen(a)) * 0.5 + Vector2(0, 12), "a−b", COL_GREEN, 13)
			_draw_target(Vector2.ZERO, "")
		"dot_constant":
			var m0: Vector2 = g["m"]
			var k := float(_task.get("target", 1.0))
			var footdir := m0.normalized()
			var focus := footdir * (k / maxf(m0.length(), 1e-6))
			var r := _range()
			var e0 := _to_screen(focus - m0 * r)
			var e1 := _to_screen(focus + m0 * r)
			draw_dashed_line(e0, e1, Color(COL_GREEN, 0.75), 1.8, 8.0)
			_draw_label((e0 + e1) * 0.5 + Vector2(0, 16), "OP·m = %s" % _fmt(k), COL_GREEN, 13)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(m0 * 2.0), COL_CYAN, 2.0)
			_draw_label(_to_screen(m0 * 2.0) + Vector2(8, -8), "m", COL_CYAN, 14)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(_drag_pos), COL_GOLD, 2.2)
			_draw_label(_to_screen(_drag_pos) + Vector2(8, -8), "P", COL_GOLD, 14)
		"iso_line":
			var a: Vector2 = g["a"]
			var b: Vector2 = g["b"]
			var dd: Vector2 = b - a
			var e0 := _to_screen(a - dd * 0.9)
			var e1 := _to_screen(b + dd * 0.9)
			draw_dashed_line(e0, e1, Color(COL_GREEN, 0.8), 1.8, 8.0)
			_draw_label((e0 + e1) * 0.5 + Vector2(20, -12), "等和线 x+y = 1", COL_GREEN, 13)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(a), COL_CYAN, 2.2)
			_draw_label(_to_screen(a) + Vector2(8, -8), "a", COL_CYAN, 14)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(b), COL_CYAN, 2.2)
			_draw_label(_to_screen(b) + Vector2(8, -8), "b", COL_CYAN, 14)
			if absf(g["s"] - 1.0) < 0.12:
				draw_circle(_to_screen(Vector2.ZERO), 8.0, Color(COL_GREEN, 0.4))
			_draw_target(_drag_pos, _task.get("target_label", "让 C 落在等和线 x+y=1"))
		"polar":
			var d: float = g["d"]
			var pa: Vector2 = g["pa"]
			var pb: Vector2 = g["pb"]
			_draw_circle_dot(_to_screen(pa), COL_CYAN)
			_draw_circle_dot(_to_screen(pb), COL_CYAN)
			_draw_label(_to_screen(pa) + Vector2(-14, -6), "A", COL_CYAN, 14)
			_draw_label(_to_screen(pb) + Vector2(6, -16), "B", COL_CYAN, 14)
			draw_line(_to_screen(pa), _to_screen(pb), Color(COL_CYAN, 0.5), 1.4)
			_draw_circle_dot(_to_screen(Vector2.ZERO), COL_DIM)
			_draw_label(_to_screen(Vector2.ZERO) + Vector2(6, 12), "M", COL_DIM, 12)
			draw_arc(_to_screen(Vector2.ZERO), _drag_pos.length() * _scale(), 0.0, TAU, 64, Color(COL_DIM, 0.5), 1.2)
			_draw_arrow(_to_screen(_drag_pos), _to_screen(pa), COL_DIM, 1.6)
			_draw_arrow(_to_screen(_drag_pos), _to_screen(pb), COL_DIM, 1.6)
			_draw_arrow(_to_screen(Vector2.ZERO), _to_screen(_drag_pos), COL_GOLD, 2.4)
			_draw_label(_to_screen(_drag_pos) + Vector2(12, 4), "P(拖动)", COL_GOLD, 14)
			var r0 := sqrt(maxf(tgt.x + d * d, 0.0))
			if r0 > 0.01:
				draw_arc(_to_screen(Vector2.ZERO), r0 * _scale(), 0.0, TAU, 64, Color(COL_GREEN, 0.75), 1.8)
				_draw_label(_to_screen(Vector2(r0, 0)) + Vector2(0, 14), "|P| = %s" % _fmt(r0), COL_GREEN, 13)
			_draw_target(Vector2(0, r0), _task.get("target_label", "目标 PA·PB"))
	_draw_handle(_drag_pos, COL_GOLD, _task.get("handle_label", "拖我"))
	# 顶部读数条
	var read := readout()
	if read != "":
		_draw_label(Vector2(12, 12), read, Color.ORANGE if not _check_ok() else COL_GREEN, 15)

func _draw_circle_dot(sp: Vector2, col: Color) -> void:
	draw_circle(sp, 5.0, Color(col, 0.95))
	draw_arc(sp, 7.0, 0.0, TAU, 24, Color(1, 1, 1, 0.85), 1.2)

func _draw_dashed_line_to(a: Vector2, b: Vector2, col: Color) -> void:
	draw_dashed_line(a, b, col, 1.0, 6.0)

func _state_changed() -> void:
	state_changed.emit(readout())

# ---------------------------------------------------------------- 交互
func _gui_input(event: InputEvent) -> void:
	if mode != "task":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var sp := _to_screen(_drag_pos)
			if event.position.distance_to(sp) <= HANDLE_R + 24.0:
				_dragging = true
				accept_event()
		else:
			if _dragging:
				_dragging = false
				_state_changed()
				accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_drag_pos = _magnets(_clamp_pos(_to_math(event.position)))
		_state_changed()
		accept_event()
	queue_redraw()