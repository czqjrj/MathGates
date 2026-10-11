class_name LinePlane
extends Control
## 直线方程 · 可交互坐标平面(纯代码绘制，无图片依赖)
## 图元：网格 / 坐标轴 / 直线(两点式、斜截式、一般式、随参数变化)/ 点 / 线段 / 圆 / 夹角弧 / 直角标记 / 文本
## 动画：图形载入时逐条"生长"显现；点弹入并脉冲；直线上的动点循环游走。
## 交互：滑块调参(斜率 k、截距 b)与沿直线拖动动点 P。
## 通过 set_scene(dict) 载入当前题目的图形，begin_interact(...) 进入交互模式。

signal param_changed(value: float)
signal point_moved(pos: Vector2)

const COL_GRID := Palette.GRID
const COL_GRID_MAJOR := Palette.GRID_MAJOR
const COL_AXIS := Palette.AXIS
const COL_TEXT := Palette.TEXT
const COL_DIM := Palette.DIM
const COL_ACCENT := Palette.ACCENT
const COL_GOLD := Palette.GOLD
const COL_SUCCESS := Palette.SUCCESS

var domain := Vector2(-6.0, 6.0)
var range_y := Vector2(-4.5, 4.5)
var pad := 26.0

var mode := ""                  # "" / "slider" / "drag"
var param := 0.0
var param_target := 0.0
var param_range := Vector2(-3.0, 3.0)
var param_tol := 0.06
var param_label := "k"
var param_explore := false       # 纯探究滑块(不显示"已对准目标")

var drag_pos := Vector2.ZERO
var drag_answer := Vector2.ZERO
var drag_tol := 0.3
var drag_constraint: Dictionary = {}
## 拖动探索增强：连到若干目标点、实时指标读数、或显示动点的对称点。
var drag_targets: Array = []
var drag_metric := ""            # "" / "sum" / "diff_abs"
var drag_metric_label := ""
var drag_reflect := ""           # "" / "origin" / "xaxis" / "yaxis" / "line"
var drag_reflect_line: Dictionary = {}
var drag_reflect_label := "P′"
var drag_path := false           # 光路/折线 A→P→B 动画
var drag_tri_fill := false       # 填充 △PAB
var drag_mirror: Dictionary = {} # 镜像作图：反射某目标点，连另一点，标最优点
var drag_point_label := "P"      # 动点标签
var derive_cfg: Dictionary = {}  # 图形化"垂直平分"列式(可选)

var _scene: Dictionary = {}
var _t := 0.0
var _anim_t := 0.0
var _slider_drag := false
var _point_drag := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	_anim_t += delta
	queue_redraw()

# ---------------------------------------------------------------- 配置
func set_scene(s: Dictionary) -> void:
	_scene = s if s != null else {}
	mode = ""
	derive_cfg = {}
	_anim_t = 0.0
	if _scene.has("x"):
		var xr: Array = _scene["x"]
		domain = Vector2(float(xr[0]), float(xr[1]))
	if _scene.has("y"):
		var yr: Array = _scene["y"]
		range_y = Vector2(float(yr[0]), float(yr[1]))
	queue_redraw()

func begin_slider(cfg: Dictionary) -> void:
	mode = "slider"
	param_label = str(cfg.get("param", "k"))
	var rng: Array = cfg.get("range", [-3, 3])
	param_range = Vector2(float(rng[0]), float(rng[1]))
	param_target = float(cfg.get("target", 0.0))
	param_tol = float(cfg.get("tol", 0.06))
	param_explore = bool(cfg.get("explore", false))
	param = float(cfg.get("start", param_range.x))
	queue_redraw()

func begin_drag(cfg: Dictionary) -> void:
	mode = "drag"
	var st: Array = cfg.get("start", [0, 0])
	drag_pos = Vector2(float(st[0]), float(st[1]))
	var an: Array = cfg.get("answer", [0, 0])
	drag_answer = Vector2(float(an[0]), float(an[1]))
	drag_tol = float(cfg.get("tol", 0.3))
	drag_constraint = cfg.get("constraint", {})
	drag_targets = cfg.get("targets", [])
	drag_metric = str(cfg.get("metric", ""))
	drag_metric_label = str(cfg.get("metric_label", ""))
	drag_reflect = str(cfg.get("reflect", ""))
	drag_reflect_line = cfg.get("reflect_line", {})
	drag_reflect_label = str(cfg.get("reflect_label", "P′"))
	drag_path = bool(cfg.get("path", false))
	drag_tri_fill = bool(cfg.get("tri_fill", false))
	drag_mirror = cfg.get("mirror", {})
	drag_point_label = str(cfg.get("point_label", "P"))
	drag_pos = _apply_constraint(drag_pos)
	queue_redraw()

func is_param_correct() -> bool:
	return absf(param - param_target) <= param_tol

func is_point_correct() -> bool:
	return drag_pos.distance_to(drag_answer) <= drag_tol

# ---------------------------------------------------------------- 动画工具
func _ease(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - c, 3.0)

## 第 i 个图元的显现进度(0→1，依次错峰)
func _rev(i: int) -> float:
	return _ease((_anim_t - float(i) * 0.12) / 0.5)

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

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	_draw_grid()
	_draw_scene()
	if mode == "slider":
		_draw_slider()
	elif mode == "drag":
		_draw_drag()
	if not derive_cfg.is_empty() and mode == "drag":
		_draw_derive()

func _draw_grid() -> void:
	var o := _origin()
	var x0 := int(ceil(domain.x))
	var x1 := int(floor(domain.y))
	for gx in range(x0, x1 + 1):
		var sp := _to_screen(Vector2(float(gx), 0.0))
		var col := COL_GRID_MAJOR if gx == 0 else COL_GRID
		draw_line(Vector2(sp.x, 0.0), Vector2(sp.x, size.y), col, 1.0)
	var y0 := int(ceil(range_y.x))
	var y1 := int(floor(range_y.y))
	for gy in range(y0, y1 + 1):
		var sp := _to_screen(Vector2(0.0, float(gy)))
		var col := COL_GRID_MAJOR if gy == 0 else COL_GRID
		draw_line(Vector2(0.0, sp.y), Vector2(size.x, sp.y), col, 1.0)

	# 坐标轴
	draw_line(Vector2(0.0, o.y), Vector2(size.x, o.y), COL_AXIS, 1.6)
	draw_line(Vector2(o.x, 0.0), Vector2(o.x, size.y), COL_AXIS, 1.6)
	draw_line(Vector2(size.x, o.y), Vector2(size.x - 11.0, o.y - 5.0), COL_AXIS, 1.6)
	draw_line(Vector2(size.x, o.y), Vector2(size.x - 11.0, o.y + 5.0), COL_AXIS, 1.6)
	draw_line(Vector2(o.x, 0.0), Vector2(o.x - 5.0, 11.0), COL_AXIS, 1.6)
	draw_line(Vector2(o.x, 0.0), Vector2(o.x + 5.0, 11.0), COL_AXIS, 1.6)

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
	draw_string(mf, Vector2(o.x - tick - 4.0, o.y + tick + 5.0), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, tick + 1, COL_DIM)

func _draw_scene() -> void:
	if _scene.is_empty():
		return
	var i := 0
	for l in _as_array(_scene.get("lines", [])):
		_draw_line_def(l, _rev(i)); i += 1
	for sg in _as_array(_scene.get("segments", [])):
		_draw_segment_def(sg, _rev(i)); i += 1
	for ci in _as_array(_scene.get("circles", [])):
		_draw_circle_def(ci, _rev(i)); i += 1
	for ar in _as_array(_scene.get("arcs", [])):
		_draw_arc_def(ar, _rev(i)); i += 1
	for ra in _as_array(_scene.get("right_angles", [])):
		_draw_right_angle(ra, _rev(i)); i += 1
	for p in _as_array(_scene.get("points", [])):
		_draw_point_def(p, _rev(i)); i += 1
	for tx in _as_array(_scene.get("texts", [])):
		_draw_text_def(tx, _rev(i)); i += 1
	if mode == "slider" and bool(_scene.get("tilt_arc", false)):
		_draw_tilt_arc()

func _as_array(v: Variant) -> Array:
	return v if v is Array else []

func _resolve_line(def: Dictionary) -> Array:
	if def.has("model"):
		var m := str(def["model"])
		var k := 0.0
		var b := 0.0
		if m == "slope":
			k = param
			b = float(def.get("b", 0.0))
			return [-k, 1.0, -b]
		elif m == "intercept":
			k = float(def.get("k", 0.0))
			b = param
			return [-k, 1.0, -b]
		elif m == "point_slope_pt":
			# 过定点 (px,py)、斜率随 param 变化的直线系
			var px := float(def.get("px", 0.0))
			var py := float(def.get("py", 0.0))
			return [-param, 1.0, param * px - py]
		elif m == "parallel":
			# A、B 固定、常数项随 param 变化的平行直线系
			return [float(def.get("A", 1.0)), float(def.get("B", 1.0)), param]
		elif m == "expr":
			# 一般式 A、B、C 关于 param 的线性表达式：A = a1·param + a0 …
			var A := float(def.get("a1", 0.0)) * param + float(def.get("a0", 1.0))
			var B := float(def.get("b1", 0.0)) * param + float(def.get("b0", 1.0))
			var C := float(def.get("c1", 0.0)) * param + float(def.get("c0", 0.0))
			return [A, B, C]
		return [0.0, 1.0, 0.0]
	if def.has("k"):
		return [-float(def["k"]), 1.0, -float(def.get("b", 0.0))]
	if def.has("A"):
		return [float(def["A"]), float(def.get("B", 1.0)), float(def.get("C", 0.0))]
	if def.has("p1") and def.has("p2"):
		var a1: Array = def["p1"]
		var a2: Array = def["p2"]
		var p1 := Vector2(float(a1[0]), float(a1[1]))
		var p2 := Vector2(float(a2[0]), float(a2[1]))
		var a := p2.y - p1.y
		var bb := p1.x - p2.x
		var c := -(a * p1.x + bb * p1.y)
		return [a, bb, c]
	return [0.0, 1.0, 0.0]

func _draw_line_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var abc := _resolve_line(def)
	var A: float = abc[0]
	var B: float = abc[1]
	var C: float = abc[2]
	var col := _c(def.get("color"), COL_ACCENT)
	var w := float(def.get("width", 2.2))
	var p0: Vector2
	var p1: Vector2
	if absf(B) > 1e-6:
		var ya := (-A * domain.x - C) / B
		var yb := (-A * domain.y - C) / B
		p0 = _to_screen(Vector2(domain.x, ya))
		p1 = _to_screen(Vector2(domain.y, yb))
	else:
		var xv := -C / A if absf(A) > 1e-6 else 0.0
		p0 = _to_screen(Vector2(xv, range_y.x))
		p1 = _to_screen(Vector2(xv, range_y.y))
	# "生长"动画：从中心向两端展开
	var mid := p0.lerp(p1, 0.5)
	var a := mid.lerp(p0, rev)
	var b := mid.lerp(p1, rev)
	if bool(def.get("dash", false)):
		draw_dashed_line(a, b, col, w, 9.0)
	else:
		draw_line(a, b, col, w)
	if def.has("label"):
		var lp: Vector2
		if def.has("label_at"):
			var la: Array = def["label_at"]
			lp = _to_screen(Vector2(float(la[0]), float(la[1])))
		else:
			lp = p0.lerp(p1, 0.82)
		_draw_label(lp + Vector2(8.0, -8.0), str(def["label"]), Color(col, rev), 17)
	# 直线上的循环游走动点
	if bool(def.get("trace", false)) and rev > 0.99:
		var tt := fposmod(_t * 0.22, 1.0)
		var tp := a.lerp(b, 0.08 + 0.84 * tt)
		draw_circle(tp, 9.0, Color(col, 0.18))
		draw_circle(tp, 4.0, Color(1, 1, 1, 0.95))

func _draw_segment_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var a1: Array = def["p1"]
	var a2: Array = def["p2"]
	var p0 := _to_screen(Vector2(float(a1[0]), float(a1[1])))
	var p1 := _to_screen(Vector2(float(a2[0]), float(a2[1])))
	var col := _c(def.get("color"), COL_GOLD)
	var w := float(def.get("width", 2.0))
	var e := p0.lerp(p1, rev)
	if bool(def.get("dash", false)):
		draw_dashed_line(p0, e, col, w, 8.0)
	else:
		draw_line(p0, e, col, w)
	if def.has("label") and rev > 0.6:
		_draw_label(p0.lerp(p1, 0.5) + Vector2(6.0, -6.0), str(def["label"]), Color(col, (rev - 0.6) / 0.4), 15)

func _draw_circle_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var cc: Array = def["c"]
	var center := _to_screen(Vector2(float(cc[0]), float(cc[1])))
	var r := float(def.get("r", 1.0)) * _scale()
	var col := _c(def.get("color"), COL_ACCENT)
	draw_arc(center, r, 0.0, TAU * rev, 72, col, 1.8, true)
	if def.has("label") and rev > 0.6:
		_draw_label(center + Vector2(0.0, -r - 6.0), str(def["label"]), Color(col, (rev - 0.6) / 0.4), 15)

func _draw_arc_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var vv: Array = def["at"]
	var av: Array = def["a"]
	var bv: Array = def["b"]
	var sv := _to_screen(Vector2(float(vv[0]), float(vv[1])))
	var sp_a := _to_screen(Vector2(float(av[0]), float(av[1])))
	var sp_b := _to_screen(Vector2(float(bv[0]), float(bv[1])))
	var ang_a := (sp_a - sv).angle()
	var ang_b := (sp_b - sv).angle()
	var col := _c(def.get("color"), COL_GOLD)
	var radius := float(def.get("r", 30.0))
	draw_arc(sv, radius, ang_a, lerpf(ang_a, ang_b, rev), 26, col, 2.0, true)
	if def.has("label") and rev > 0.6:
		var mid := (ang_a + ang_b) * 0.5
		_draw_label(sv + Vector2(cos(mid), sin(mid)) * (radius + 14.0), str(def["label"]), Color(col, (rev - 0.6) / 0.4), 15)

func _draw_right_angle(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var vv: Array = def["at"]
	var av: Array = def["a"]
	var bv: Array = def["b"]
	var sv := _to_screen(Vector2(float(vv[0]), float(vv[1])))
	var da := (_to_screen(Vector2(float(av[0]), float(av[1]))) - sv).normalized()
	var db := (_to_screen(Vector2(float(bv[0]), float(bv[1]))) - sv).normalized()
	var col := _c(def.get("color"), COL_GOLD)
	var s := float(def.get("size", 14.0)) * rev
	var pts := PackedVector2Array([sv + da * s, sv + da * s + db * s, sv + db * s])
	draw_polyline(pts, col, 1.6, true)

func _draw_point_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var pv: Array = def["p"]
	var mp := Vector2(float(pv[0]), float(pv[1]))
	var sp := _to_screen(mp)
	var col := _c(def.get("color"), COL_ACCENT)
	var pulse := 1.0 + 0.12 * sin(_t * 3.0 + mp.x)
	var r := 4.4 * rev * pulse
	if rev > 0.99:
		draw_circle(sp, 5.6 + 2.0 * sin(_t * 2.4), Color(col, 0.18))
	draw_circle(sp, 6.0 * rev, Color(0.02, 0.03, 0.06, 0.92 * rev))
	draw_circle(sp, r, Color(col, rev))
	if rev > 0.4:
		draw_arc(sp, 5.6 * rev, 0.0, TAU, 24, Color(1, 1, 1, 0.85 * rev), 1.3, true)
	if def.has("label") and rev > 0.5:
		_draw_label(sp + Vector2(9.0, -9.0), str(def["label"]), Color(col, (rev - 0.5) / 0.5), 16)
	if bool(def.get("show_coord", false)) and rev > 0.6:
		_draw_label(sp + Vector2(9.0, 16.0), "(%s, %s)" % [_fmt(mp.x), _fmt(mp.y)], Color(COL_DIM, (rev - 0.6) / 0.4), 13)

func _draw_text_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var pv: Array = def["p"]
	var sp := _to_screen(Vector2(float(pv[0]), float(pv[1])))
	_draw_label(sp, str(def.get("s", "")), Color(_c(def.get("color"), COL_DIM), rev), int(def.get("size", 15)))

func _draw_tilt_arc() -> void:
	var o := _to_screen(Vector2.ZERO)
	var full := -atan(param)
	var ang := full * _rev(0)
	var radius := 46.0
	draw_arc(o, radius, 0.0, ang, 32, COL_GOLD, 2.0, true)
	var deg := rad_to_deg(atan(param))
	_draw_label(o + Vector2(cos(ang * 0.5), sin(ang * 0.5)) * (radius + 16.0),
		"α≈%s°" % _fmt(absf(deg)), COL_GOLD, 14)

func _draw_label(pos: Vector2, text: String, col: Color, s: int) -> void:
	if text.is_empty() or col.a <= 0.01:
		return
	var px := UI.fs(s)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_rect(Rect2(pos + Vector2(-5.0, -px - 3.0), Vector2(w + 10.0, px + 8.0)), Color(0.04, 0.06, 0.11, 0.66 * col.a), true)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

func _draw_slider() -> void:
	var y := size.y - 32.0
	var x0 := 46.0
	var x1 := size.x - 46.0
	draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.15), 6.0)
	var tp := _param_to_x(param, x0, x1)
	draw_line(Vector2(x0, y), Vector2(tp, y), Color(COL_ACCENT, 0.75), 6.0)
	var knob_r := 9.5 + (1.0 if _slider_drag else 0.0) + 0.6 * sin(_t * 4.0)
	draw_circle(Vector2(tp, y), knob_r + 3.5, Color(0.02, 0.04, 0.08, 0.92))
	draw_circle(Vector2(tp, y), knob_r, COL_ACCENT)
	var near := (not param_explore) and absf(param - param_target) <= param_tol
	var col := COL_SUCCESS if near else COL_TEXT
	var fs := UI.fs(18)
	draw_string(UI.mono_font(), Vector2(x0, y - fs - 6.0),
		"%s = %s" % [param_label, _fmt(param)], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	if near:
		draw_string(UI.font(), Vector2(x0 + fs * 5.3, y - fs - 6.0), "✓ 已对准目标", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(15), COL_SUCCESS)
	_draw_label(Vector2(x1 - UI.fs(96.0), y - fs - 6.0), "拖动调节 →", COL_DIM, 13)

func _draw_drag() -> void:
	var sp := _to_screen(drag_pos)
	var tpts: Array[Vector2] = []
	for t in drag_targets:
		tpts.append(_vec(t))

	# 三角形填充
	if drag_tri_fill and tpts.size() >= 2:
		draw_colored_polygon(PackedVector2Array([_to_screen(tpts[0]), sp, _to_screen(tpts[1])]), Color(COL_ACCENT, 0.10))

	# 镜像/对称作图(将军饮马 · 光反射)
	if not drag_mirror.is_empty() and tpts.size() >= 2:
		_draw_mirror(tpts)

	# 连到目标点(A、B…)的辅助线
	for i in tpts.size():
		var tp := _to_screen(tpts[i])
		draw_dashed_line(sp, tp, Color(COL_DIM, 0.6), 1.5, 6.0)
		draw_circle(tp, 4.0, Color(0.02, 0.03, 0.06, 0.9))
		draw_circle(tp, 3.0, COL_GOLD)

	# 光路动画：A → P → B 上循环游走的亮点 + 箭头
	if drag_path and tpts.size() >= 2:
		_draw_light_path(_to_screen(tpts[0]), sp, _to_screen(tpts[1]))

	# 动点的对称点(关于原点 / 坐标轴 / 直线)
	var ref := drag_pos
	var has_refl := false
	match drag_reflect:
		"origin": ref = Vector2(-drag_pos.x, -drag_pos.y); has_refl = true
		"xaxis":  ref = Vector2(drag_pos.x, -drag_pos.y); has_refl = true
		"yaxis":  ref = Vector2(-drag_pos.x, drag_pos.y); has_refl = true
		"line":
			if not drag_reflect_line.is_empty():
				ref = _reflect_pt(drag_pos, drag_reflect_line)
				has_refl = true
	if has_refl:
		var rp := _to_screen(ref)
		var mid := _to_screen((drag_pos + ref) * 0.5)
		draw_dashed_line(sp, rp, Color(COL_GOLD, 0.85), 1.6, 7.0)
		# 直角标记(关于直线对称)：PP′ ⊥ l
		if drag_reflect == "line" and not drag_reflect_line.is_empty():
			var la := float(drag_reflect_line.get("A", 0.0))
			var lb := float(drag_reflect_line.get("B", 1.0))
			_draw_rightangle(mid, Vector2(lb, -la), ref - drag_pos, 12.0, COL_SUCCESS)
		# 中点(垂足)标记
		draw_circle(mid, 4.6, Color(0.02, 0.03, 0.06, 0.9))
		draw_circle(mid, 3.2, COL_SUCCESS)
		if drag_reflect == "line":
			_draw_label(mid + Vector2(8.0, 15.0), "中点(在 l 上)", Color(COL_SUCCESS, 0.95), 13)
		draw_circle(rp, 5.0, Color(0.02, 0.03, 0.06, 0.9))
		draw_circle(rp, 4.0, COL_GOLD)
		draw_arc(rp, 6.4, 0.0, TAU, 20, Color(1, 1, 1, 0.85), 1.2, true)
		_draw_label(rp + Vector2(9.0, -9.0), "%s(%s, %s)" % [drag_reflect_label, _fmt(ref.x), _fmt(ref.y)], COL_GOLD, 14)

	# 动点 P
	var pulse := 1.0 + 0.10 * sin(_t * 3.0)
	draw_circle(sp, 15.0 * pulse, Color(COL_GOLD, 0.16))
	draw_line(Vector2(sp.x - 15.0, sp.y), Vector2(sp.x + 15.0, sp.y), Color(COL_GOLD, 0.5), 1.0)
	draw_line(Vector2(sp.x, sp.y - 15.0), Vector2(sp.x, sp.y + 15.0), Color(COL_GOLD, 0.5), 1.0)
	draw_circle(sp, 12.0, Color(0.02, 0.04, 0.08, 0.92))
	draw_circle(sp, 8.5 * pulse, COL_GOLD)
	_draw_label(sp + Vector2(15.0, -13.0), "%s(%s, %s)" % [drag_point_label, _fmt(drag_pos.x), _fmt(drag_pos.y)], COL_TEXT, 15)

	# 实时指标读数(|PA|+|PB| / ||PA|−|PB|| / 周长 / Δy·Δx)
	if drag_metric != "":
		var lab := drag_metric_label
		var val := 0.0
		var text := ""
		if drag_metric == "ratio" and tpts.size() >= 1:
			var dx := drag_pos.x - tpts[0].x
			var dy := drag_pos.y - tpts[0].y
			if lab.is_empty():
				lab = "Δy/Δx"
			if absf(dx) < 1e-6:
				text = "%s = —" % lab
			else:
				text = "%s = %s" % [lab, _fmt(dy / dx)]
		elif tpts.size() >= 2:
			var d1 := drag_pos.distance_to(tpts[0])
			var d2 := drag_pos.distance_to(tpts[1])
			match drag_metric:
				"sum": val = d1 + d2
				"perimeter":
					val = d1 + d2 + tpts[0].distance_to(tpts[1])
					if lab.is_empty():
						lab = "周长"
				_: val = absf(d1 - d2)
			if lab.is_empty():
				lab = drag_metric
			text = "%s = %s" % [lab, _fmt(val)]
		if text != "":
			_draw_label(sp + Vector2(15.0, 24.0), text, COL_GOLD, 15)

func _reflect_pt(p: Vector2, spec: Dictionary) -> Vector2:
	var t := str(spec.get("type", ""))
	if t.is_empty() and (spec.has("A") or spec.has("B")):
		t = "line"
	if t.is_empty() or t == "xaxis":
		return Vector2(p.x, -p.y)
	if t == "origin":
		return Vector2(-p.x, -p.y)
	if t == "yaxis":
		return Vector2(-p.x, p.y)
	if t == "line":
		var A := float(spec.get("A", 0.0))
		var B := float(spec.get("B", 1.0))
		var C := float(spec.get("C", 0.0))
		var d := (A * p.x + B * p.y + C) / maxf(A * A + B * B, 1e-6)
		return Vector2(p.x - 2.0 * A * d, p.y - 2.0 * B * d)
	return p

func _spec_abc(spec: Dictionary) -> Array:
	match str(spec.get("type", "xaxis")):
		"xaxis": return [0.0, 1.0, 0.0]
		"yaxis": return [1.0, 0.0, 0.0]
		"line": return [float(spec.get("A", 0.0)), float(spec.get("B", 1.0)), float(spec.get("C", 0.0))]
	return [0.0, 1.0, 0.0]

func _intersect_with_spec(p1: Vector2, p2: Vector2, spec: Dictionary) -> Variant:
	var abc := _spec_abc(spec)
	var A: float = abc[0]
	var B: float = abc[1]
	var C: float = abc[2]
	var dx := p2.x - p1.x
	var dy := p2.y - p1.y
	var den := A * dx + B * dy
	if absf(den) < 1e-6:
		return null
	var t := -(A * p1.x + B * p1.y + C) / den
	if t < -10.0 or t > 10.0:
		return null
	return Vector2(p1.x + t * dx, p1.y + t * dy)

func _draw_mirror(tpts: Array) -> void:
	var idx := int(drag_mirror.get("index", 1))
	if idx < 0 or idx >= tpts.size():
		return
	var spec: Dictionary = drag_mirror.get("over", {"type": "xaxis"})
	var q: Vector2 = _reflect_pt(tpts[idx], spec)
	var other: Vector2 = tpts[0] if idx != 0 else tpts[1]
	var qs := _to_screen(q)
	var os := _to_screen(other)
	draw_dashed_line(qs, os, Color(COL_SUCCESS, 0.8), 1.8, 9.0)
	draw_circle(qs, 5.0, Color(0.02, 0.03, 0.06, 0.9))
	draw_circle(qs, 4.0, COL_SUCCESS)
	draw_arc(qs, 6.6, 0.0, TAU, 20, Color(1, 1, 1, 0.85), 1.2, true)
	_draw_label(qs + Vector2(9.0, -9.0), str(drag_mirror.get("label", "镜像点")), COL_SUCCESS, 14)
	var ip = _intersect_with_spec(q, other, spec)
	if ip != null:
		var ips := _to_screen(ip)
		var pu := 1.0 + 0.15 * sin(_t * 4.0)
		draw_arc(ips, 13.0 * pu, 0.0, TAU, 26, Color(COL_SUCCESS, 0.9), 2.2, true)
		_draw_label(ips + Vector2(11.0, 12.0), "最优点", COL_SUCCESS, 13)

func _draw_light_path(a: Vector2, p: Vector2, b: Vector2) -> void:
	var l1 := a.distance_to(p)
	var l2 := p.distance_to(b)
	var total := l1 + l2
	if total < 1.0:
		return
	var u := fposmod(_t * 0.35, 1.0)
	var d := u * total
	var pos := a
	if d <= l1:
		pos = a.lerp(p, d / maxf(l1, 0.001))
	else:
		pos = p.lerp(b, (d - l1) / maxf(l2, 0.001))
	draw_circle(pos, 13.0, Color(1.0, 0.95, 0.7, 0.16))
	draw_circle(pos, 7.0, Color(1.0, 0.97, 0.82, 0.95))
	draw_circle(pos, 3.0, Color.WHITE)
	_draw_arrowhead(p, a)
	_draw_arrowhead(b, p)

func _draw_rightangle(center: Vector2, d1: Vector2, d2: Vector2, s: float, col: Color) -> void:
	var u1 := Vector2(d1.x, -d1.y)
	var u2 := Vector2(d2.x, -d2.y)
	if u1.length() < 1e-6 or u2.length() < 1e-6:
		return
	u1 = u1.normalized()
	u2 = u2.normalized()
	var pts := PackedVector2Array([center + u1 * s, center + u1 * s + u2 * s, center + u2 * s])
	draw_polyline(pts, Color(col, 0.95), 1.6, true)

func _draw_arrowhead(tip: Vector2, tail: Vector2) -> void:
	var dir := tip - tail
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	var n := Vector2(-dir.y, dir.x)
	var s := 9.0
	var base := tip - dir * s
	draw_colored_polygon(PackedVector2Array([tip, base + n * s * 0.55, base - n * s * 0.55]), Color(COL_GOLD, 0.9))

func _tex(name: String) -> Texture2D:
	if name.is_empty():
		return null
	var p := "res://art/line/formulas/%s.png" % name
	return (load(p) as Texture2D) if ResourceLoader.exists(p) else null

## 在画面上绘制"垂直平分"列式面板，随动点 P 实时更新
func _draw_derive() -> void:
	var line: Dictionary = derive_cfg.get("line", {})
	var A := float(line.get("A", 1.0))
	var B := float(line.get("B", 1.0))
	var C := float(line.get("C", 0.0))
	var x := drag_pos.x
	var y := drag_pos.y
	var D := A * x + B * y + C
	var den := maxf(A * A + B * B, 1e-6)
	var xp := x - 2.0 * A * D / den
	var yp := y - 2.0 * B * D / den
	var mono := UI.mono_font()
	var fs := float(UI.fs(13))
	var lh := fs * 1.5
	var pad := 12.0
	var lines := [
		"垂直平分列式（随 P 实时更新）",
		"① 垂直  PP'⊥l： (x'−%s)/%s = (y'−%s)/%s" % [_fmt(x), _fmt(A), _fmt(y), _fmt(B)],
		"② 平分  中点在 l 上：",
		"   %s(%s+x')+%s(%s+y')+%s = 0" % [_fmt(A), _fmt(x), _fmt(B), _fmt(y), _fmt(2.0 * C)],
		"解得  P'(%s, %s)" % [_fmt(xp), _fmt(yp)],
	]
	var maxw := 0.0
	for s in lines:
		maxw = maxf(maxw, mono.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs)).x)
	var boxw := maxw + pad * 2.0
	var boxh := pad * 2.0 + float(lines.size()) * lh
	var ox := 14.0
	var oy := 14.0
	draw_rect(Rect2(ox, oy, boxw, boxh), Color(0.03, 0.05, 0.10, 0.86), true)
	draw_rect(Rect2(ox, oy, boxw, boxh), Color(COL_ACCENT, 0.35), false, 1.0)
	var tx := ox + pad
	var ty := oy + pad + fs * 0.85
	draw_string(mono, Vector2(tx, ty), lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), COL_ACCENT)
	ty += lh
	for i in range(1, lines.size()):
		var col := COL_TEXT if i < 4 else COL_SUCCESS
		draw_string(mono, Vector2(tx, ty), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), col)
		ty += lh

func _vec(a: Variant) -> Vector2:
	if a is Array and (a as Array).size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO

# ---------------------------------------------------------------- 交互
func _param_to_x(v: float, x0: float, x1: float) -> float:
	var t := clampf((v - param_range.x) / maxf(param_range.y - param_range.x, 0.001), 0.0, 1.0)
	return lerpf(x0, x1, t)

func _x_to_param(x: float, x0: float, x1: float) -> float:
	var t := clampf((x - x0) / maxf(x1 - x0, 0.001), 0.0, 1.0)
	return lerpf(param_range.x, param_range.y, t)

func _apply_constraint(p: Vector2) -> Vector2:
	var q := Vector2(clampf(p.x, domain.x, domain.y), clampf(p.y, range_y.x, range_y.y))
	if drag_constraint.is_empty():
		return q
	var t := str(drag_constraint.get("type", "free"))
	if t == "xaxis":
		return Vector2(q.x, 0.0)
	if t == "yaxis":
		return Vector2(0.0, q.y)
	if t == "line":
		var A := float(drag_constraint.get("A", 0.0))
		var B := float(drag_constraint.get("B", 1.0))
		var C := float(drag_constraint.get("C", 0.0))
		var d := (A * q.x + B * q.y + C) / maxf(A * A + B * B, 0.0001)
		return Vector2(q.x - A * d, q.y - B * d)
	return q

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if mode == "slider":
				var y := size.y - 32.0
				if absf(event.position.y - y) < 30.0:
					_slider_drag = true
					param = _x_to_param(event.position.x, 46.0, size.x - 46.0)
					param_changed.emit(param)
					accept_event()
			elif mode == "drag":
				var sp := _to_screen(drag_pos)
				if event.position.distance_to(sp) < 36.0:
					_point_drag = true
					accept_event()
		else:
			if _slider_drag or _point_drag:
				accept_event()
			_slider_drag = false
			_point_drag = false
	elif event is InputEventMouseMotion:
		if _slider_drag and mode == "slider":
			param = _x_to_param(event.position.x, 46.0, size.x - 46.0)
			param_changed.emit(param)
			accept_event()
		elif _point_drag and mode == "drag":
			drag_pos = _apply_constraint(_to_math(event.position))
			point_moved.emit(drag_pos)
			accept_event()
