class_name LabPlane
extends Control
## 知识体系「实验探究」通用绘图平面（纯代码绘制，无图片依赖）。
## 图元：坐标网格(可选 π 刻度) / 函数曲线 / 单位圆 / 直线 / 线段 / 圆 / 点 / 向量 / 文本。
## 交互：多滑块实时调参（曲线/单位圆随参数变化）+ 可拖动动点。
## 用法：set_scene(dict) 载入图形；begin_sliders(...) / begin_drag(...) 进入交互。
## 各知识章节（函数/三角/指对/导数…）的 LabStage 复用本平面，实现"实验探究"。

signal slider_changed(name: String, value: float)
signal point_moved(pos: Vector2)

const COL_GRID := Palette.GRID
const COL_GRID_MAJOR := Palette.GRID_MAJOR
const COL_AXIS := Palette.AXIS
const COL_TEXT := Palette.TEXT
const COL_DIM := Palette.DIM
const COL_ACCENT := Palette.ACCENT
const COL_GOLD := Palette.GOLD
const COL_SUCCESS := Palette.SUCCESS
const COL_INDIGO := Palette.INDIGO

const TRACK_X0 := 150.0
const TRACK_X1_MARGIN := 34.0

var domain := Vector2(-6.5, 6.5)
var range_y := Vector2(-3.5, 3.5)
var pad := 26.0

var mode := ""                       # "" / "sliders" / "drag"
var _scene: Dictionary = {}
var _sliders: Array = []             # [{name,min,max,value,step,label}]
var _answers: Dictionary = {}
var _tol: Dictionary = {}
var _slider_drag := -1
var _point_drag := false

var drag_pos := Vector2.ZERO
var drag_answer := Vector2.ZERO
var drag_tol := 0.3
var drag_constraint: Dictionary = {}
var drag_point_label := "P"

var _t := 0.0
var _anim_t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	_anim_t += delta
	if mode == "sliders" or not _scene.is_empty():
		queue_redraw()

# ---------------------------------------------------------------- 配置
func set_scene(s: Dictionary) -> void:
	_scene = s if s != null else {}
	mode = ""
	_anim_t = 0.0
	if _scene.has("x"):
		var xr: Array = _scene["x"]
		domain = Vector2(float(xr[0]), float(xr[1]))
	if _scene.has("y"):
		var yr: Array = _scene["y"]
		range_y = Vector2(float(yr[0]), float(yr[1]))
	queue_redraw()

func begin_sliders(list: Array, answers: Dictionary = {}, tol: Dictionary = {}) -> void:
	mode = "sliders"
	_answers = answers
	_tol = tol
	_sliders.clear()
	for item in list:
		if not (item is Dictionary):
			continue
		var d: Dictionary = item
		var lo := float(d.get("min", -3.0))
		var hi := float(d.get("max", 3.0))
		var val := float(d.get("value", lo))
		_sliders.append({
			"name": str(d.get("name", "k")),
			"min": lo, "max": hi,
			"value": clampf(val, lo, hi),
			"step": float(d.get("step", 0.0)),
			"label": str(d.get("label", d.get("name", "k"))),
		})
	queue_redraw()

func begin_drag(cfg: Dictionary) -> void:
	mode = "drag"
	var st: Array = cfg.get("start", [0, 0])
	drag_pos = Vector2(float(st[0]), float(st[1]))
	var an: Array = cfg.get("answer", [0, 0])
	drag_answer = Vector2(float(an[0]), float(an[1]))
	drag_tol = float(cfg.get("tol", 0.3))
	drag_constraint = cfg.get("constraint", {})
	drag_point_label = str(cfg.get("point_label", "P"))
	drag_pos = _apply_constraint(drag_pos)
	queue_redraw()

func slider_value(name: String) -> float:
	for s in _sliders:
		if str(s["name"]) == name:
			return float(s["value"])
	return 0.0

func slider_summary() -> String:
	var parts: PackedStringArray = []
	for s in _sliders:
		parts.append("%s = %s" % [str(s["label"]), _fmt(float(s["value"]))])
	return "，".join(parts)

func is_point_correct() -> bool:
	return drag_pos.distance_to(drag_answer) <= drag_tol

func is_sliders_correct() -> bool:
	var checked := false
	for s in _sliders:
		var nm := str(s["name"])
		if _answers.has(nm):
			checked = true
			if absf(float(s["value"]) - float(_answers[nm])) > float(_tol.get(nm, 0.06)):
				return false
	return checked

# ---------------------------------------------------------------- 坐标换算
func _scale() -> float:
	var w := maxf(size.x - pad * 2.0, 1.0)
	var h := maxf(size.y - pad * 2.0, 1.0)
	var sx := w / maxf(domain.y - domain.x, 0.001)
	var sy := h / maxf(range_y.y - range_y.x, 0.001)
	return minf(sx, sy)

func _origin() -> Vector2:
	var s := _scale()
	var cx := (domain.x + domain.y) * 0.5
	var cy := (range_y.x + range_y.y) * 0.5
	return Vector2(size.x * 0.5 - cx * s, size.y * 0.5 + cy * s)

func _to_screen(p: Vector2) -> Vector2:
	var s := _scale()
	var o := _origin()
	return o + Vector2(p.x * s, -p.y * s)

func _to_math(sp: Vector2) -> Vector2:
	var s := _scale()
	var o := _origin()
	return Vector2((sp.x - o.x) / s, (o.y - sp.y) / s)

func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.0005:
		return str(int(roundf(v)))
	return "%.2f" % v

func _c(v: Variant, dflt: Color) -> Color:
	if v == null:
		return dflt
	if v is Color:
		return v
	return Color(str(v))

func _arr(k: String) -> Array:
	var v: Variant = _scene.get(k, [])
	return v if v is Array else []

func _vec(a: Variant) -> Vector2:
	if a is Array and (a as Array).size() >= 2:
		return Vector2(_num((a as Array)[0], 0.0), _num((a as Array)[1], 0.0))
	return Vector2.ZERO

## 参数取值：数字直接取；字符串取同名滑块当前值(支持前导 "−" 与 "滑块*数"/"滑块/数" 形式)；缺省用默认。
func _num(v: Variant, dflt: float) -> float:
	if v == null:
		return dflt
	if v is String:
		var s := str(v).strip_edges()
		if s.is_valid_float():
			return s.to_float()
		var sign := 1.0
		if s.begins_with("-"):
			sign = -1.0
			s = s.substr(1)
		elif s.begins_with("+"):
			s = s.substr(1)
		for op in ["*", "/"]:
			var idx := s.find(op)
			if idx > 0:
				var left := _num(s.substr(0, idx), dflt)
				var right := s.substr(idx + 1).to_float()
				if op == "*":
					return sign * left * right
				return sign * left / (right if absf(right) > 1e-9 else 1.0)
		for sl in _sliders:
			if str(sl["name"]) == s:
				return sign * float(sl["value"])
		return dflt
	return float(v)

func _fmt_num(v: float) -> String:
	if absf(v - roundf(v)) < 0.0005:
		return str(int(roundf(v)))
	return "%.2f" % v

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	_draw_grid()
	_draw_scene()
	if not _scene.is_empty() and _scene.has("unit_circle"):
		_draw_unit_circle()
	if mode == "sliders":
		_draw_sliders()
	elif mode == "drag":
		_draw_drag()

func _draw_grid() -> void:
	var o := _origin()
	if bool(_scene.get("pi_ticks", false)):
		_draw_pi_grid(o)
		return
	var x0 := int(ceil(domain.x))
	var x1 := int(floor(domain.y))
	for gx in range(x0, x1 + 1):
		var sp := _to_screen(Vector2(float(gx), 0.0))
		draw_line(Vector2(sp.x, 0.0), Vector2(sp.x, size.y), COL_GRID_MAJOR if gx == 0 else COL_GRID, 1.0)
	var y0 := int(ceil(range_y.x))
	var y1 := int(floor(range_y.y))
	for gy in range(y0, y1 + 1):
		var sp := _to_screen(Vector2(0.0, float(gy)))
		draw_line(Vector2(0.0, sp.y), Vector2(size.x, sp.y), COL_GRID_MAJOR if gy == 0 else COL_GRID, 1.0)
	_draw_axes(o)
	var mf := UI.mono_font()
	var tick := UI.fs(11)
	for gx in range(x0, x1 + 1):
		if gx == 0:
			continue
		var sp := _to_screen(Vector2(float(gx), 0.0))
		draw_string(mf, Vector2(sp.x - tick * 0.45, o.y + tick + 4.0), str(gx), HORIZONTAL_ALIGNMENT_LEFT, -1, tick, COL_DIM)
	for gy in range(y0, y1 + 1):
		if gy == 0:
			continue
		var sp := _to_screen(Vector2(0.0, float(gy)))
		draw_string(mf, Vector2(o.x + 6.0, sp.y + tick * 0.4), str(gy), HORIZONTAL_ALIGNMENT_LEFT, -1, tick, COL_DIM)

func _draw_pi_grid(o: Vector2) -> void:
	var mf := UI.mono_font()
	var tick := UI.fs(12)
	var names := { 1: "π/2", 2: "π", 3: "3π/2", 4: "2π" }
	var k := -8
	while k <= 8:
		var xv := float(k) * PI / 2.0
		if xv >= domain.x - 0.01 and xv <= domain.y + 0.01:
			var sp := _to_screen(Vector2(xv, 0.0))
			draw_line(Vector2(sp.x, 0.0), Vector2(sp.x, size.y), COL_GRID_MAJOR if k == 0 else COL_GRID, 1.0)
			if k != 0:
				var key := absi(k)
				var lab := ("−" if k < 0 else "") + str(names.get(key, "%dπ/2" % key))
				draw_string(mf, Vector2(sp.x - tick * 0.7, o.y + tick + 5.0), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, tick, COL_DIM)
		k += 1
	var y0 := int(ceil(range_y.x))
	var y1 := int(floor(range_y.y))
	for gy in range(y0, y1 + 1):
		var sp := _to_screen(Vector2(0.0, float(gy)))
		draw_line(Vector2(0.0, sp.y), Vector2(size.x, sp.y), COL_GRID_MAJOR if gy == 0 else COL_GRID, 1.0)
		if gy != 0:
			draw_string(mf, Vector2(o.x + 6.0, sp.y + tick * 0.4), str(gy), HORIZONTAL_ALIGNMENT_LEFT, -1, tick, COL_DIM)
	_draw_axes(o)

func _draw_axes(o: Vector2) -> void:
	draw_line(Vector2(0.0, o.y), Vector2(size.x, o.y), COL_AXIS, 1.6)
	draw_line(Vector2(o.x, 0.0), Vector2(o.x, size.y), COL_AXIS, 1.6)
	draw_line(Vector2(size.x, o.y), Vector2(size.x - 11.0, o.y - 5.0), COL_AXIS, 1.6)
	draw_line(Vector2(size.x, o.y), Vector2(size.x - 11.0, o.y + 5.0), COL_AXIS, 1.6)
	draw_line(Vector2(o.x, 0.0), Vector2(o.x - 5.0, 11.0), COL_AXIS, 1.6)
	draw_line(Vector2(o.x, 0.0), Vector2(o.x + 5.0, 11.0), COL_AXIS, 1.6)
	var mf := UI.mono_font()
	var tick := UI.fs(11)
	draw_string(mf, Vector2(o.x - tick - 4.0, o.y + tick + 5.0), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, tick + 1, COL_DIM)

func _draw_scene() -> void:
	if _scene.is_empty():
		return
	var i := 0
	for cu in _as_array(_scene.get("curves", [])):
		_draw_curve(cu, _rev(i)); i += 1
	for l in _as_array(_scene.get("lines", [])):
		_draw_line_def(l, _rev(i)); i += 1
	for sg in _as_array(_scene.get("segments", [])):
		_draw_segment_def(sg, _rev(i)); i += 1
	for ci in _as_array(_scene.get("circles", [])):
		_draw_circle_def(ci, _rev(i)); i += 1
	for b in _as_array(_scene.get("bars", [])):
		_draw_bar_def(b, _rev(i)); i += 1
	for rg in _as_array(_scene.get("regions", [])):
		_draw_region_def(rg, _rev(i)); i += 1
	_draw_vectors()
	_draw_scatter(_rev(i)); i += 1
	for p in _as_array(_scene.get("points", [])):
		_draw_point_def(p, _rev(i)); i += 1
	_draw_label_def(_as_array(_scene.get("labels", [])))

func _as_array(v: Variant) -> Array:
	return v if v is Array else []

## 第 i 个图元的显现进度(0→1，依次错峰)
func _rev(i: int) -> float:
	var c := clampf((_anim_t - float(i) * 0.10) / 0.45, 0.0, 1.0)
	return 1.0 - pow(1.0 - c, 3.0)

# ---- 函数曲线
func _f_y(kind: String, x: float, a: float, b: float, c: float, d: float) -> float:
	match kind:
		"sin": return a * sin(b * x + c) + d
		"cos": return a * cos(b * x + c) + d
		"tan": return a * tan(b * x + c) + d
		"exp": return a * pow(maxf(b, 0.01), x) + d
		"log": return a * log(maxf(x, 1e-6)) / log(maxf(b, 1.01)) + d
		"ln": return a * log(maxf(x, 1e-6)) + d
		"pow": return a * pow(x, b) + c
		"sqrt": return a * sqrt(maxf(x, 0.0)) + b
		"recip": return a / maxf(absf(x), 1e-3) * signf(x) + b if absf(x) > 1e-4 else c
		"quad": return a * x * x + b * x + c
		"linear": return a * x + b
		"abs": return a * absf(x - b) + c
		"const": return a
		"hyp": return b * sqrt(x * x / (a * a) - 1.0) + d
		"hypv": return b * sqrt(1.0 + x * x / (a * a)) + d
		"parr": return sqrt(2.0 * maxf(a, 0.0) * x) + d
		"parl": return sqrt(2.0 * maxf(a, 0.0) * -x) + d
		"paru": return x * x / (2.0 * maxf(a, 0.01)) + d
	return a * sin(b * x + c) + d

func _draw_curve(cu: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var kind := str(cu.get("fn", "sin"))
	var a := _num(cu.get("a", 1.0), 1.0)
	var b := _num(cu.get("b", 1.0), 1.0)
	var c := _num(cu.get("c", 0.0), 0.0)
	var d := _num(cu.get("d", 0.0), 0.0)
	var mir := bool(cu.get("mirror", false))
	var col := _c(cu.get("color"), COL_ACCENT)
	var w := float(cu.get("width", 2.4))
	var x0 := _num(cu.get("from", domain.x), domain.x)
	var x1 := _num(cu.get("to", domain.y), domain.y)
	var steps := 640
	var ext := (range_y.y - range_y.x) * 0.9
	var vis_x := lerpf(x0, x1, rev)
	var prev_valid := false
	var prev := Vector2.ZERO
	for i in steps + 1:
		var x := lerpf(x0, x1, float(i) / float(steps))
		if x > vis_x:
			break
		var y := _f_y(kind, x, a, b, c, d)
		if mir:
			y = -y
		if not is_finite(y) or y < range_y.x - ext or y > range_y.y + ext:
			prev_valid = false
			continue
		var sp := _to_screen(Vector2(x, y))
		if prev_valid:
			if bool(cu.get("dash", false)):
				draw_dashed_line(prev, sp, col, w, 8.0)
			else:
				draw_line(prev, sp, col, w)
		prev = sp
		prev_valid = true
	if cu.has("label"):
		var lx := x1 * 0.72
		var ly := _f_y(kind, lx, a, b, c, d)
		if mir:
			ly = -ly
		_draw_label(_to_screen(Vector2(lx, ly)) + Vector2(6.0, -10.0), str(cu["label"]), col, 15)

# ---- 静态图元
func _draw_circle_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var center := _to_screen(_vec(def.get("c", [0, 0])))
	var r := _num(def.get("r", 1.0), 1.0) * _scale()
	var col := _c(def.get("color"), COL_INDIGO)
	if bool(def.get("fill", false)):
		draw_circle(center, r, Color(col, 0.10))
	draw_arc(center, r, 0.0, TAU * rev, 96, col, 2.0, true)
	if def.has("label") and rev > 0.6:
		_draw_label(center + Vector2(0.0, -r - 6.0), str(def["label"]), Color(col, (rev - 0.6) / 0.4), 15)

func _resolve_line(def: Dictionary) -> Array:
	if def.has("k"):
		return [-_num(def["k"], 0.0), 1.0, -_num(def.get("b", 0.0), 0.0)]
	if def.has("A"):
		return [_num(def["A"], 1.0), _num(def.get("B", 1.0), 1.0), _num(def.get("C", 0.0), 0.0)]
	if def.has("p1") and def.has("p2"):
		var p1 := _vec(def["p1"])
		var p2 := _vec(def["p2"])
		var a := p2.y - p1.y
		var bb := p1.x - p2.x
		return [a, bb, -(a * p1.x + bb * p1.y)]
	return [0.0, 1.0, 0.0]

func _draw_line_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var abc := _resolve_line(def)
	var A: float = abc[0]
	var B: float = abc[1]
	var C: float = abc[2]
	var col := _c(def.get("color"), COL_ACCENT)
	var w := float(def.get("width", 2.0))
	var p0: Vector2
	var p1: Vector2
	if absf(B) > 1e-6:
		p0 = _to_screen(Vector2(domain.x, (-A * domain.x - C) / B))
		p1 = _to_screen(Vector2(domain.y, (-A * domain.y - C) / B))
	else:
		var xv := -C / A if absf(A) > 1e-6 else 0.0
		p0 = _to_screen(Vector2(xv, range_y.x))
		p1 = _to_screen(Vector2(xv, range_y.y))
	var mid := p0.lerp(p1, 0.5)
	var a := mid.lerp(p0, rev)
	var b := mid.lerp(p1, rev)
	if bool(def.get("dash", false)):
		draw_dashed_line(a, b, col, w, 9.0)
	else:
		draw_line(a, b, col, w)
	if def.has("label") and rev > 0.6:
		_draw_label(p0.lerp(p1, 0.8) + Vector2(8.0, -8.0), str(def["label"]), Color(col, (rev - 0.6) / 0.4), 15)

func _draw_segment_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var p0 := _to_screen(_vec(def.get("p1", [0, 0])))
	var p1 := _to_screen(_vec(def.get("p2", [0, 0])))
	var col := _c(def.get("color"), COL_GOLD)
	var e := p0.lerp(p1, rev)
	if bool(def.get("dash", false)):
		draw_dashed_line(p0, e, col, float(def.get("width", 1.8)), 8.0)
	else:
		draw_line(p0, e, col, float(def.get("width", 1.8)))
	if def.has("label") and rev > 0.6:
		_draw_label(p0.lerp(p1, 0.5) + Vector2(6.0, -6.0), str(def["label"]), Color(col, (rev - 0.6) / 0.4), 14)

func _draw_vectors() -> void:
	for vv in _as_array(_scene.get("vectors", [])):
		var a := _to_screen(_vec(vv.get("p1", vv.get("from", [0, 0]))))
		var b := _to_screen(_vec(vv.get("p2", vv.get("to", [1, 1]))))
		var col := _c(vv.get("color"), COL_ACCENT)
		draw_line(a, b, col, 2.0)
		if a.distance_to(b) > 10.0:
			var dir := (b - a).normalized()
			var perp := Vector2(-dir.y, dir.x)
			draw_colored_polygon(PackedVector2Array([b, b - dir * 9.0 + perp * 3.8, b - dir * 9.0 - perp * 3.8]), col)
		if vv.has("label"):
			_draw_label(b + Vector2(8.0, -8.0), str(vv["label"]), col, 14)

func _draw_point_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var mp := _vec(def.get("p", [0, 0]))
	var sp := _to_screen(mp)
	var col := _c(def.get("color"), COL_GOLD)
	draw_circle(sp, 6.0 * rev, Color(0.02, 0.03, 0.06, 0.92 * rev))
	draw_circle(sp, 4.2 * rev, Color(col, rev))
	if def.has("label") and rev > 0.5:
		_draw_label(sp + Vector2(10.0, -10.0), str(def["label"]), Color(col, (rev - 0.5) / 0.5), 15)

# ---- 条形(柱状/频率直方图)
func _draw_bar_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var x := _num(def.get("x", 0.0), 0.0)
	var h := _num(def.get("h", 0.0), 0.0)
	var base_y := _num(def.get("base", 0.0), 0.0)
	var w := float(def.get("w", 0.6))
	var col := _c(def.get("color"), COL_ACCENT)
	var base := _to_screen(Vector2(x, base_y))
	var top := _to_screen(Vector2(x, lerpf(base_y, h, rev)))
	var half := w * 0.5 * _scale()
	var rect := Rect2(Vector2(base.x - half, minf(base.y, top.y)), Vector2(half * 2.0, absf(base.y - top.y)))
	draw_rect(rect, Color(col, 0.5 * rev))
	draw_rect(rect, Color(col, rev), false, 1.6)
	if def.has("label") and rev > 0.5:
		_draw_label(Vector2((base.x + top.x) * 0.5, top.y - 6.0), str(def["label"]), Color(col, (rev - 0.5) / 0.5), 13)

# ---- 散点(数列/样本点)，可选虚线连线
func _draw_scatter(rev: float) -> void:
	var pts := _as_array(_scene.get("scatter", []))
	if pts.is_empty() or rev <= 0.001:
		return
	var col := _c(_scene.get("scatter_color"), COL_GOLD)
	var guide := bool(_scene.get("scatter_guide", false))
	var prev := Vector2.ZERO
	var prev_ok := false
	for i in pts.size():
		var sp := _to_screen(_vec(pts[i]))
		if guide and prev_ok:
			draw_dashed_line(prev, sp, Color(col, 0.45 * rev), 1.6, 7.0)
		draw_circle(sp, 5.4 * rev, Color(0.02, 0.03, 0.06, 0.92 * rev))
		draw_circle(sp, 3.8 * rev, Color(col, rev))
		prev = sp
		prev_ok = true

# ---- 半透明多边形区域(可行域/阴影)
func _draw_region_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var pts := _as_array(def.get("points", []))
	if pts.size() < 3:
		return
	var col := _c(def.get("color"), COL_ACCENT)
	var poly := PackedVector2Array()
	for p in pts:
		poly.append(_to_screen(_vec(p)))
	draw_colored_polygon(poly, Color(col, float(def.get("alpha", 0.18)) * rev))
	if bool(def.get("outline", true)):
		var loop := poly.duplicate()
		poly.append(poly[0])
		for j in poly.size() - 1:
			draw_line(poly[j], poly[j + 1], Color(col, 0.8 * rev), 1.6)

func _draw_label_def(list: Array) -> void:
	for lb in list:
		var sp := _to_screen(_vec(lb.get("p", [0, 0])))
		_draw_label(sp, str(lb.get("text", "")), _c(lb.get("color"), COL_TEXT), int(lb.get("size", 15)))

func _draw_label(pos: Vector2, text: String, col: Color, s: int) -> void:
	if text.is_empty() or col.a <= 0.01:
		return
	var px := UI.fs(s)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_rect(Rect2(pos + Vector2(-5.0, -px - 3.0), Vector2(w + 10.0, px + 8.0)), Color(0.04, 0.06, 0.11, 0.66 * col.a), true)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

# ---- 单位圆
func _draw_unit_circle() -> void:
	var uc: Dictionary = _scene.get("unit_circle", {})
	var r := float(uc.get("r", 1.0))
	var deg := _num(uc.get("angle", 0.0), 0.0)
	var rad := deg_to_rad(deg)
	var o := _to_screen(Vector2.ZERO)
	var rp := r * _scale()
	draw_arc(o, rp, 0.0, TAU, 96, Color(COL_INDIGO, 0.85), 1.8, true)
	var p := Vector2(r * cos(rad), r * sin(rad))
	var sp := _to_screen(p)
	# 角弧
	if absf(deg) > 0.5:
		draw_arc(o, rp * 0.30, 0.0, -rad, 48, COL_GOLD, 2.0, true)
		_draw_label(o + Vector2(cos(rad * 0.5), -sin(rad * 0.5)) * (rp * 0.30 + 16.0), "%s°" % _fmt(deg), COL_GOLD, 14)
	# 半径
	draw_line(o, sp, COL_ACCENT, 2.2)
	# 投影
	if bool(uc.get("show_cos", true)):
		draw_dashed_line(sp, _to_screen(Vector2(p.x, 0.0)), Color(COL_SUCCESS, 0.9), 1.6, 6.0)
		_draw_label(_to_screen(Vector2(p.x, 0.0)) + Vector2(4.0, 18.0), "cosθ≈%s" % _fmt(p.x), COL_SUCCESS, 13)
	if bool(uc.get("show_sin", true)):
		draw_dashed_line(sp, _to_screen(Vector2(0.0, p.y)), Color(COL_ACCENT, 0.9), 1.6, 6.0)
		_draw_label(_to_screen(Vector2(0.0, p.y)) + Vector2(-84.0, -6.0), "sinθ≈%s" % _fmt(p.y), COL_ACCENT, 13)
	# P 点
	draw_circle(sp, 6.0, Color(0.02, 0.04, 0.08, 0.92))
	draw_circle(sp, 4.4, COL_GOLD)
	_draw_label(sp + Vector2(10.0, -12.0), str(uc.get("label", "P")), COL_GOLD, 15)

# ---- 滑块
func _slider_y(i: int) -> float:
	return size.y - 42.0 - float(i) * 40.0

func _track_x1() -> float:
	return size.x - TRACK_X1_MARGIN

func _param_to_x(v: float, lo: float, hi: float, x0: float, x1: float) -> float:
	var t := clampf((v - lo) / maxf(hi - lo, 0.001), 0.0, 1.0)
	return lerpf(x0, x1, t)

func _x_to_param(x: float, lo: float, hi: float, x0: float, x1: float) -> float:
	var t := clampf((x - x0) / maxf(x1 - x0, 1.0), 0.0, 1.0)
	return lerpf(lo, hi, t)

func _draw_sliders() -> void:
	var x0 := TRACK_X0
	var x1 := _track_x1()
	for i in _sliders.size():
		var s: Dictionary = _sliders[i]
		var y := _slider_y(i)
		var col := Color(str(_scene.get("slider_color", "#5ee6ff")))
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.15), 6.0)
		var tp := _param_to_x(float(s["value"]), float(s["min"]), float(s["max"]), x0, x1)
		draw_line(Vector2(x0, y), Vector2(tp, y), Color(col, 0.8), 6.0)
		draw_circle(Vector2(tp, y), 8.5, Color(0.02, 0.04, 0.08, 0.92))
		draw_circle(Vector2(tp, y), 6.0, col)
		_draw_label(Vector2(16.0, y + 6.0), "%s = %s" % [str(s["label"]), _fmt(float(s["value"]))], COL_TEXT, 15)

func _draw_drag() -> void:
	var sp := _to_screen(drag_pos)
	var pulse := 1.0 + 0.12 * sin(_t * 3.0)
	draw_circle(sp, 14.0 * pulse, Color(COL_GOLD, 0.16))
	draw_circle(sp, 11.0, Color(0.02, 0.04, 0.08, 0.92))
	draw_circle(sp, 8.0 * pulse, COL_GOLD)
	_draw_label(sp + Vector2(14.0, -12.0), "%s(%s, %s)" % [drag_point_label, _fmt(drag_pos.x), _fmt(drag_pos.y)], COL_TEXT, 15)

# ---------------------------------------------------------------- 交互
func _apply_constraint(p: Vector2) -> Vector2:
	var q := Vector2(clampf(p.x, domain.x, domain.y), clampf(p.y, range_y.x, range_y.y))
	var t := str(drag_constraint.get("type", ""))
	if t == "xaxis":
		return Vector2(q.x, 0.0)
	if t == "yaxis":
		return Vector2(0.0, q.y)
	return q

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if mode == "sliders":
				var x0 := TRACK_X0
				var x1 := _track_x1()
				for i in _sliders.size():
					if absf(event.position.y - _slider_y(i)) < 18.0 and event.position.x > x0 - 20.0:
						_slider_drag = i
						_set_slider_from_x(i, event.position.x, x0, x1)
						accept_event()
						break
			elif mode == "drag":
				if event.position.distance_to(_to_screen(drag_pos)) < 40.0:
					_point_drag = true
					accept_event()
		else:
			if _slider_drag >= 0 or _point_drag:
				accept_event()
			_slider_drag = -1
			_point_drag = false
	elif event is InputEventMouseMotion:
		if _slider_drag >= 0 and mode == "sliders":
			_set_slider_from_x(_slider_drag, event.position.x, TRACK_X0, _track_x1())
			accept_event()
		elif _point_drag and mode == "drag":
			drag_pos = _apply_constraint(_to_math(event.position))
			point_moved.emit(drag_pos)
			accept_event()

func _set_slider_from_x(i: int, x: float, x0: float, x1: float) -> void:
	if i < 0 or i >= _sliders.size():
		return
	var s: Dictionary = _sliders[i]
	var v := _x_to_param(x, float(s["min"]), float(s["max"]), x0, x1)
	var step := float(s["step"])
	if step > 0.0:
		v = roundf(v / step) * step
	v = clampf(v, float(s["min"]), float(s["max"]))
	s["value"] = v
	slider_changed.emit(str(s["name"]), v)
	queue_redraw()
