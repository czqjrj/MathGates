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

## 分界点交互(分段函数实验室)：拖动竖线 x=name，复用滑块通道让 _num(name) 生效。
var _break: Dictionary = {}
## 值域色带：{lo,hi} 用 INF 哨兵表示向 ±∞ 延伸。
const _INF := 1e18
const _BIG := 1e17

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
	var has_range := _scene.has("x") or _scene.has("y")
	if _scene.has("x"):
		var xr: Array = _scene["x"]
		domain = Vector2(float(xr[0]), float(xr[1]))
	if _scene.has("y"):
		var yr: Array = _scene["y"]
		range_y = Vector2(float(yr[0]), float(yr[1]))
	# 兼容几何章节常用的对称视野 "range": R（等价 x/y = [−R, R]）
	if not has_range and _scene.has("range"):
		var rr := maxf(float(_scene["range"]), 1.0)
		domain = Vector2(-rr, rr)
		range_y = Vector2(-rr, rr)
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

func begin_break(cfg: Dictionary) -> void:
	_break = cfg
	mode = "break"
	var lo := float(cfg.get("min", domain.x))
	var hi := float(cfg.get("max", domain.y))
	var val := clampf(float(cfg.get("value", (lo + hi) * 0.5)), lo, hi)
	_sliders.clear()
	_sliders.append({
		"name": str(cfg.get("name", "a")), "min": lo, "max": hi,
		"value": val, "step": float(cfg.get("step", 0.0)),
		"label": str(cfg.get("label", cfg.get("name", "a"))),
	})
	queue_redraw()

func is_break_correct() -> bool:
	if _sliders.is_empty():
		return true
	var v := float(_sliders[0]["value"])
	if _break.has("lo") or _break.has("hi"):
		return v >= float(_break.get("lo", -1e9)) - 1e-6 and v <= float(_break.get("hi", 1e9)) + 1e-6
	return absf(v - float(_break.get("answer", v))) <= float(_break.get("tol", 0.1))

func _set_break(x: float) -> void:
	if _sliders.is_empty():
		return
	var s: Dictionary = _sliders[0]
	var v := clampf(x, float(s["min"]), float(s["max"]))
	var step := float(s["step"])
	if step > 0.0:
		v = roundf(v / step) * step
	s["value"] = v
	slider_changed.emit(str(s["name"]), v)
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

# ---- 值域分析（分段函数实验：各分支值域 + 是否拼接为 R）
## 采样某条曲线在其定义域上的 [min,max]。
func _curve_range(cu: Dictionary) -> Array:
	var kind := str(cu.get("fn", "sin"))
	var a := _num(cu.get("a", 1.0), 1.0)
	var b := _num(cu.get("b", 1.0), 1.0)
	var c := _num(cu.get("c", 0.0), 0.0)
	var d := _num(cu.get("d", 0.0), 0.0)
	var mir := bool(cu.get("mirror", false))
	var x0 := _num(cu.get("from", domain.x), domain.x)
	var x1 := _num(cu.get("to", domain.y), domain.y)
	var lo := INF
	var hi := -INF
	var steps := 480
	for i in steps + 1:
		var x := lerpf(x0, x1, float(i) / float(steps))
		var y := _f_y(kind, x, a, b, c, d)
		if mir:
			y = -y
		if not is_finite(y):
			continue
		lo = minf(lo, y)
		hi = maxf(hi, y)
	if lo > hi:
		lo = 0.0
		hi = 0.0
	return [lo, hi]

## 各曲线值域区间 [{lo,hi,color,label}]；cover="down"/"up"/"both" 表示向 ±∞ 延伸。
func _range_intervals() -> Array:
	var out: Array = []
	for cu in _as_array(_scene.get("curves", [])):
		var r := _curve_range(cu)
		var cover := str(cu.get("cover", ""))
		var lo := float(r[0])
		var hi := float(r[1])
		if cover == "down":
			lo = -_INF
		elif cover == "up":
			hi = _INF
		elif cover == "both":
			lo = -_INF
			hi = _INF
		out.append({
			"lo": lo, "hi": hi,
			"color": _c(cu.get("color"), COL_ACCENT),
			"label": str(cu.get("range_label", cu.get("label", ""))),
		})
	return out

## 合并后的覆盖情况：{covered: bool, gap_lo, gap_hi}
func _coverage() -> Dictionary:
	var ivs := _range_intervals()
	ivs.sort_custom(func(x, y): return float(x["lo"]) < float(y["lo"]))
	var merged: Array = []
	for iv in ivs:
		if merged.is_empty() or float(iv["lo"]) > float((merged[-1] as Dictionary)["hi"]) + 1e-6:
			merged.append({"lo": float(iv["lo"]), "hi": float(iv["hi"])})
		else:
			(merged[-1] as Dictionary)["hi"] = maxf(float((merged[-1] as Dictionary)["hi"]), float(iv["hi"]))
	var covered := merged.size() == 1 and float(merged[0]["lo"]) <= -_BIG and float(merged[0]["hi"]) >= _BIG
	var g_lo := 0.0
	var g_hi := 0.0
	if not covered and merged.size() >= 2:
		g_lo = float(merged[0]["hi"])
		g_hi = float(merged[1]["lo"])
	return {"covered": covered, "gap_lo": g_lo, "gap_hi": g_hi}

## 供关卡面板显示的值域状态文本。
func coverage_status() -> String:
	if not bool(_scene.get("range_bands", false)):
		return ""
	var cv := _coverage()
	if bool(cv["covered"]):
		return "两段值域拼接 = R ✓"
	return "两段值域之间有缝隙：未覆盖 (%s, %s)" % [_fmt(float(cv["gap_lo"])), _fmt(float(cv["gap_hi"]))]

func _draw_range_bands() -> void:
	var ivs := _range_intervals()
	if ivs.is_empty():
		return
	var x := size.x - 15.0
	var w := 10.0
	var y_top := pad
	var y_bot := size.y - pad
	for iv in ivs:
		var lo := maxf(float(iv["lo"]), range_y.x)
		var hi := minf(float(iv["hi"]), range_y.y)
		var sy_hi := _to_screen(Vector2(0.0, hi)).y
		var sy_lo := _to_screen(Vector2(0.0, lo)).y
		var top := clampf(sy_hi, y_top, y_bot)
		var bot := clampf(sy_lo, y_top, y_bot)
		var col: Color = iv["color"]
		draw_rect(Rect2(x, top, w, maxf(bot - top, 2.0)), Color(col, 0.30))
		draw_rect(Rect2(x, top, w, maxf(bot - top, 2.0)), Color(col, 0.9), false, 1.4)
		var lbl := str(iv["label"])
		if lbl != "":
			_draw_label(Vector2(x - 6.0 - UI.font().get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(12)).x, clampf((top + bot) * 0.5, y_top + 8.0, y_bot - 4.0)), lbl, col, 12)
	if _scene.has("range_caption"):
		# 自定义值域说明（非分段拼接场景时使用）。
		var cap := str(_scene.get("range_caption", ""))
		if cap != "":
			_draw_label(Vector2(12.0, 20.0), cap, COL_GOLD, 15)
		return
	var cv := _coverage()
	var txt := "值域 = R ✓" if bool(cv["covered"]) else "值域 ≠ R（有缝隙）"
	var col2 := COL_SUCCESS if bool(cv["covered"]) else COL_GOLD
	_draw_label(Vector2(12.0, 20.0), txt, col2, 15)

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

## 参数取值：支持数字、滑块名、算术表达式(+ − * / ^ 括号)与函数 sqrt/abs/sin/cos/tan、
## 常量 pi/e(三角函数按角度制)；缺省用 dflt。使几何图形可随滑块实时重绘。
var _ex_s := ""
var _ex_i := 0
var _ex_ok := true
var _ex_dflt := 0.0

func _num(v: Variant, dflt: float) -> float:
	if v == null:
		return dflt
	if v is float or v is int or v is bool:
		return float(v)
	if v is String:
		var s := str(v).strip_edges()
		if s.is_empty():
			return dflt
		if s.is_valid_float():
			return s.to_float()
		_ex_s = s.replace(" ", "")
		_ex_i = 0
		_ex_ok = true
		_ex_dflt = dflt
		var r := _ex_expr()
		if not _ex_ok or _ex_i < _ex_s.length():
			return dflt
		return r
	return dflt

func _ex_peek() -> String:
	return _ex_s[_ex_i] if _ex_i < _ex_s.length() else ""

func _ex_next() -> String:
	var c := _ex_peek()
	_ex_i += 1
	return c

func _ex_expr() -> float:
	var v := _ex_term()
	while _ex_ok:
		var c := _ex_peek()
		if c == "+":
			_ex_next()
			v += _ex_term()
		elif c == "-":
			_ex_next()
			v -= _ex_term()
		else:
			break
	return v

func _ex_term() -> float:
	var v := _ex_unary()
	while _ex_ok:
		var c := _ex_peek()
		if c == "*":
			_ex_next()
			v *= _ex_unary()
		elif c == "/":
			_ex_next()
			var d := _ex_unary()
			v = v / d if absf(d) > 1e-12 else 0.0
		else:
			break
	return v

func _ex_unary() -> float:
	var c := _ex_peek()
	if c == "-":
		_ex_next()
		return -_ex_unary()
	if c == "+":
		_ex_next()
		return _ex_unary()
	return _ex_power()

func _ex_power() -> float:
	var base := _ex_primary()
	if _ex_peek() == "^":
		_ex_next()
		return pow(base, _ex_unary())
	return base

func _ex_primary() -> float:
	var c := _ex_peek()
	if c == "(":
		_ex_next()
		var v := _ex_expr()
		if _ex_peek() == ")":
			_ex_next()
		else:
			_ex_ok = false
		return v
	if c.is_valid_float() or c == ".":
		var st := _ex_i
		while _ex_i < _ex_s.length() and (_ex_s[_ex_i].is_valid_float() or _ex_s[_ex_i] == "."):
			_ex_i += 1
		return _ex_s.substr(st, _ex_i - st).to_float()
	if _ex_is_ident_start(c):
		var st2 := _ex_i
		while _ex_i < _ex_s.length() and _ex_is_ident_char(_ex_s[_ex_i]):
			_ex_i += 1
		var name := _ex_s.substr(st2, _ex_i - st2)
		if _ex_peek() == "(":
			_ex_next()
			var arg := _ex_expr()
			if _ex_peek() == ")":
				_ex_next()
			else:
				_ex_ok = false
			return _ex_func(name, arg)
		return _ex_var(name)
	_ex_ok = false
	return 0.0

func _ex_is_ident_start(c: String) -> bool:
	return not c.is_empty() and c.is_valid_identifier()

func _ex_is_ident_char(c: String) -> bool:
	return c.is_valid_identifier() or c.is_valid_int()

func _ex_func(name: String, arg: float) -> float:
	match name:
		"sqrt": return sqrt(maxf(arg, 0.0))
		"abs": return absf(arg)
		"sin": return sin(deg_to_rad(arg))
		"cos": return cos(deg_to_rad(arg))
		"tan": return tan(deg_to_rad(arg))
	return 0.0

func _ex_var(name: String) -> float:
	for sl in _sliders:
		if str(sl["name"]) == name:
			return float(sl["value"])
	if name == "pi": return PI
	if name == "e": return 2.718281828459045
	return _ex_dflt

func _fmt_num(v: float) -> String:
	if absf(v - roundf(v)) < 0.0005:
		return str(int(roundf(v)))
	return "%.2f" % v

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	_draw_grid()
	_draw_scene()
	_draw_readouts()
	if not _scene.is_empty() and _scene.has("unit_circle"):
		_draw_unit_circle()
	if bool(_scene.get("range_bands", false)):
		_draw_range_bands()
	if mode == "sliders":
		_draw_sliders()
	elif mode == "drag":
		_draw_drag()
	elif mode == "break":
		_draw_break()

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
	for el in _as_array(_scene.get("ellipses", [])):
		_draw_ellipse_def(el, _rev(i)); i += 1
	for fo in _as_array(_scene.get("foci", [])):
		_draw_foci_def(fo, _rev(i)); i += 1
	for b in _as_array(_scene.get("bars", [])):
		_draw_bar_def(b, _rev(i)); i += 1
	for rg in _as_array(_scene.get("regions", [])):
		_draw_region_def(rg, _rev(i)); i += 1
	for ar in _as_array(_scene.get("arcs", [])):
		_draw_arc_def(ar, _rev(i)); i += 1
	for ra in _as_array(_scene.get("right_angles", [])):
		_draw_right_angle_def(ra, _rev(i)); i += 1
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
		"log":
			if x <= 1e-6:
				return NAN
			return a * log(x) / log(maxf(b, 1.01)) + d
		"ln":
			if x <= 1e-6:
				return NAN
			return a * log(x) + d
		"pow": return a * pow(x, b) + c
		"sqrt":
			if x < 0.0:
				return NAN
			return a * sqrt(x) + b
		"recip": return a / maxf(absf(x), 1e-3) * signf(x) + b if absf(x) > 1e-4 else c
		"quad": return a * x * x + b * x + c
		"linear": return a * x + b
		"linrecip": return a * x - b / maxf(absf(x), 1e-3)
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

# ---- 椭圆：{a,b,axis,color,label}（axis="y" 时长轴在 y 轴，a 为 y 向半轴）
func _draw_ellipse_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var a := maxf(absf(_num(def.get("a", 1.0), 1.0)), 1e-3)
	var b := maxf(absf(_num(def.get("b", 1.0), 1.0)), 1e-3)
	var axis := str(def.get("axis", "x"))
	var rx := a if axis != "y" else b
	var ry := b if axis != "y" else a
	var col := _c(def.get("color"), COL_INDIGO)
	if bool(def.get("fill", false)):
		var poly := PackedVector2Array()
		for k in 96:
			var tf := TAU * float(k) / 96.0
			poly.append(_to_screen(Vector2(rx * cos(tf), ry * sin(tf))))
		draw_colored_polygon(poly, Color(col, 0.10 * rev))
	var n := 144
	var lim := maxi(2, int(round(float(n) * clampf(rev, 0.0, 1.0))))
	var pts := PackedVector2Array()
	for k in lim + 1:
		var tt := TAU * float(k) / float(n)
		pts.append(_to_screen(Vector2(rx * cos(tt), ry * sin(tt))))
	if pts.size() >= 2:
		draw_polyline(pts, col, 2.0, true)
	if def.has("label") and rev > 0.6:
		_draw_label(_to_screen(Vector2(0.0, ry)) + Vector2(6.0, -6.0),
			str(def["label"]), Color(col, (rev - 0.6) / 0.4), 14)

# ---- 焦点：{c,axis,color} 在长轴两端 ±c 处画焦点
func _draw_foci_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var c := absf(_num(def.get("c", 0.0), 0.0))
	var axis := str(def.get("axis", "x"))
	var col := _c(def.get("color"), COL_GOLD)
	var xs := [Vector2(-c, 0.0), Vector2(c, 0.0)]
	if axis == "y":
		xs = [Vector2(0.0, -c), Vector2(0.0, c)]
	var names := ["F₁", "F₂"]
	for k in 2:
		var sp := _to_screen(xs[k])
		draw_circle(sp, 6.0 * rev, Color(0.02, 0.03, 0.06, 0.92 * rev))
		draw_circle(sp, 4.2 * rev, Color(col, rev))
		if rev > 0.5:
			_draw_label(sp + Vector2(10.0, -10.0), names[k], Color(col, (rev - 0.5) / 0.5), 15)

# ---- 实时读数：场景 readouts = [{label, expr, color?}]，expr 可用滑块名与函数
func _draw_readouts() -> void:
	var list := _as_array(_scene.get("readouts", []))
	if list.is_empty():
		return
	var y := 10.0
	for rd in list:
		if not (rd is Dictionary):
			continue
		var d: Dictionary = rd
		var col := _c(d.get("color"), COL_GOLD)
		var txt := "%s = %s" % [str(d.get("label", "值")), _fmt(_num(d.get("expr", 0.0), 0.0))]
		_draw_label(Vector2(12.0, y + 16.0), txt, col, 15)
		y += 27.0

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

# ---- 角弧：以 at 为顶点、介于方向 a 与 b 之间、半径 r 的圆弧
func _draw_arc_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var at := _vec(def.get("at", [0, 0]))
	var va := _vec(def.get("a", [1, 0]))
	var vb := _vec(def.get("b", [0, 1]))
	var rr := maxf(_num(def.get("r", 1.0), 1.0), 0.05) * _scale()
	var col := _c(def.get("color"), COL_ACCENT)
	var o := _to_screen(at)
	var ang_a := atan2(-va.y, va.x)
	var ang_b := atan2(-vb.y, vb.x)
	var d := ang_b - ang_a
	while d > PI:
		d -= TAU
	while d < -PI:
		d += TAU
	draw_arc(o, rr, ang_a, ang_a + d * rev, 40, Color(col, rev), 2.0, true)
	if def.has("label") and rev > 0.6:
		var mid := ang_a + d * 0.5
		_draw_label(o + Vector2(cos(mid), sin(mid)) * (rr + 16.0),
			str(def["label"]), Color(col, (rev - 0.6) / 0.4), 15)

# ---- 直角标记：以 at 为顶点、夹在方向 a 与 b 之间的小方角
func _draw_right_angle_def(def: Dictionary, rev: float) -> void:
	if rev <= 0.001:
		return
	var at := _vec(def.get("at", [0, 0]))
	var va := _vec(def.get("a", [1, 0]))
	var vb := _vec(def.get("b", [0, 1]))
	if va.length() < 1e-4 or vb.length() < 1e-4:
		return
	va = va.normalized()
	vb = vb.normalized()
	var col := _c(def.get("color"), COL_ACCENT)
	var sz := float(def.get("size", 0.32))
	var p0 := _to_screen(at + va * sz)
	var p1 := _to_screen(at + (va + vb) * sz)
	var p2 := _to_screen(at + vb * sz)
	draw_polyline(PackedVector2Array([p0, p1, p2]), Color(col, rev), 2.0, true)

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

## 分界点把手(绘制在 x 轴上，可直接拖动)。
func _draw_break() -> void:
	if _sliders.is_empty():
		return
	var v := float(_sliders[0]["value"])
	var base := _to_screen(Vector2(v, 0.0))
	draw_line(Vector2(base.x, 0.0), Vector2(base.x, size.y), Color(COL_GOLD, 0.10), 8.0)
	var pulse := 1.0 + 0.12 * sin(_t * 3.0)
	draw_circle(base, 13.0 * pulse, Color(COL_GOLD, 0.18))
	draw_circle(base, 9.0, Color(0.02, 0.04, 0.08, 0.92))
	draw_circle(base, 6.0, COL_GOLD)
	_draw_label(base + Vector2(12.0, -14.0), "%s = %s" % [str(_sliders[0]["label"]), _fmt(v)], COL_TEXT, 15)

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
			elif mode == "break":
				_point_drag = true
				_set_break(_to_math(event.position).x)
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
		elif _point_drag and mode == "break":
			_set_break(_to_math(event.position).x)
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
