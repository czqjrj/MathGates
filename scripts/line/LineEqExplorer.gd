class_name LineEqExplorer
extends Control
## 直线方程演示器：六种模式，覆盖第 2 章全部形态并演示"何时不能用"
##  point_slope / slope_intercept / vertical          点斜式、斜截式、竖直(点斜式失效)
##  two_points                                          两点式(含 x₁=x₂ 或 y₁=y₂ 失效)
##  intercept                                           截距式(含过原点/平行轴失效)
##  general                                             一般式 → 斜截式 互化
## 纯代码绘制；直线"生长"、读数淡入、手柄脉冲。

signal changed(k: float, b: float)

const COL_GRID := Color(1, 1, 1, 0.05)
const COL_GRID_MAJOR := Color(1, 1, 1, 0.10)
const COL_AXIS := Color(0.55, 0.62, 0.78, 1.0)
const COL_TEXT := Color(0.92, 0.96, 1.0, 1.0)
const COL_DIM := Color(0.62, 0.68, 0.8, 1.0)
const COL_LINE := Color(0.369, 0.902, 1.0, 1.0)
const COL_P := Color(1.0, 0.44, 0.52, 1.0)
const COL_K := Color(1.0, 0.83, 0.47, 1.0)
const COL_B := Color(0.66, 0.55, 1.0, 1.0)
const COL_DANGER := Color(0.98, 0.44, 0.52, 1.0)
const COL_SUCCESS := Color(0.204, 0.827, 0.6, 1.0)
const K_CLAMP := 6.0

var domain := Vector2(-2.0, 6.0)
var range_y := Vector2(-2.0, 6.0)
var pad := 30.0

var _mode := "point_slope"
var _p := Vector2(2.0, 3.0)
var _x0 := 2.0
var _k := 1.0
var _b := 0.0
var _k0 := 1.0
var _b0 := 0.0
var _a2 := Vector2(1.0, 2.0)
var _b2 := Vector2(3.0, 6.0)
var _xi := 3.0
var _yi := 2.0
var _A := 2.0
var _B := -3.0
var _C := 6.0
var _prompt := ""
var _vertical := false
var _auto_v := false
var _auto_t := 0.0
var _drag_kind := ""
var _t := 0.0
var _reveal := 0.0
var _tex_ps: Texture2D
var _tex_si: Texture2D
var _tex_tp: Texture2D
var _tex_ic: Texture2D
var _tex_gn: Texture2D
var _tex_g2s: Texture2D
var _formula_tex: Texture2D
var _formula2_tex: Texture2D
var _reset_btn: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	_tex_ps = _tex("line_point_slope")
	_tex_si = _tex("line_slope_intercept")
	_tex_tp = _tex("line_two_points_form")
	_tex_ic = _tex("line_xa_yb_form")
	_tex_gn = _tex("line_general")
	_tex_g2s = _tex("line_general_to_slope")
	_reset_btn = UI.ghost_button("重置", func() -> void: _reset(), 14)
	_reset_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_reset_btn.offset_left = -100.0
	_reset_btn.offset_right = -16.0
	_reset_btn.offset_top = 14.0
	_reset_btn.offset_bottom = 48.0
	add_child(_reset_btn)
	set_process(true)

func setup(cfg: Dictionary) -> void:
	_mode = str(cfg.get("mode", "point_slope"))
	_prompt = str(cfg.get("prompt", ""))
	if cfg.has("p"):
		var a: Array = cfg["p"]
		_p = Vector2(float(a[0]), float(a[1]))
	if cfg.has("x0"):
		_x0 = float(cfg["x0"])
	if _mode == "vertical" and not cfg.has("p"):
		_p = Vector2(_x0, float(cfg.get("y0", 1.2)))
	if cfg.has("a"):
		var av: Array = cfg["a"]
		_a2 = Vector2(float(av[0]), float(av[1]))
	if cfg.has("b") and cfg["b"] is Array:
		var bv: Array = cfg["b"]
		_b2 = Vector2(float(bv[0]), float(bv[1]))
	_k = float(cfg.get("k0", 1.0))
	_b = float(cfg.get("b0", 0.0))
	_k0 = _k
	_b0 = _b
	_xi = float(cfg.get("xi", 3.0))
	_yi = float(cfg.get("yi", 2.0))
	_A = float(cfg.get("A", 2.0))
	_B = float(cfg.get("B", -3.0))
	_C = float(cfg.get("C", 6.0))
	if _mode == "general" and absf(_B) > 1e-6:
		_k = -_A / _B
		_b = -_C / _B
		_k0 = _k
		_b0 = _b
	var fp := str(cfg.get("formula", ""))
	_formula_tex = load(fp) if (fp != "" and ResourceLoader.exists(fp)) else null
	var fp2 := str(cfg.get("formula2", ""))
	_formula2_tex = load(fp2) if (fp2 != "" and ResourceLoader.exists(fp2)) else null
	if cfg.has("x"):
		var xr: Array = cfg["x"]
		domain = Vector2(float(xr[0]), float(xr[1]))
	if cfg.has("y"):
		var yr: Array = cfg["y"]
		range_y = Vector2(float(yr[0]), float(yr[1]))
	_vertical = false
	_auto_v = _mode == "vertical" and bool(cfg.get("auto_vertical", true))
	_auto_t = 0.0
	if _auto_v:
		_k = 0.5
	_reveal = 0.0
	queue_redraw()

func _reset() -> void:
	_k = _k0
	_b = _b0
	_vertical = false
	_auto_v = _mode == "vertical"
	_auto_t = 0.0
	if _auto_v:
		_k = 0.5
	_reveal = 0.0
	changed.emit(_k, _b)

func _process(delta: float) -> void:
	_t += delta
	_reveal = minf(_reveal + delta * 1.4, 1.0)
	if _auto_v:
		_auto_t += delta
		var p := clampf(_auto_t / 1.7, 0.0, 1.0)
		_k = lerpf(0.5, K_CLAMP, p * p)
		if _auto_t > 2.4:
			_vertical = true
			_auto_v = false
	queue_redraw()

# ---------------------------------------------------------------- 坐标
func _scale() -> float:
	var w := maxf(size.x - pad * 2.0, 1.0)
	var h := maxf(size.y - pad * 2.0 - 40.0, 1.0)
	return minf(w / maxf(domain.y - domain.x, 0.001), h / maxf(range_y.y - range_y.x, 0.001))

func _origin() -> Vector2:
	var s := _scale()
	var cx := (domain.x + domain.y) * 0.5
	var cy := (range_y.x + range_y.y) * 0.5
	return Vector2(size.x * 0.5 - cx * s, (size.y - 40.0) * 0.5 + cy * s + 10.0)

func _to_screen(p: Vector2) -> Vector2:
	var s := _scale()
	var o := _origin()
	return o + Vector2(p.x * s, -p.y * s)

func _to_math(sp: Vector2) -> Vector2:
	var s := _scale()
	var o := _origin()
	return Vector2((sp.x - o.x) / s, (o.y - sp.y) / s)

func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.005:
		return str(int(roundf(v)))
	return "%.2f" % v

func _rat(v: float) -> String:
	for den in range(1, 13):
		var num := roundf(v * den)
		if absf(v - num / den) < 1e-4:
			if den == 1:
				return str(int(num))
			return "%d/%d" % [int(num), den]
	return "%.2f" % v

func _signed(v: float, first: bool) -> String:
	if first:
		return ("−%s" % _fmt(absf(v))) if v < 0.0 else _fmt(v)
	return (" − " if v < 0.0 else " + ") + _fmt(absf(v))

func _tex(n: String) -> Texture2D:
	var p := "res://art/line/formulas/%s.png" % n
	return load(p) if ResourceLoader.exists(p) else null

# ---------------------------------------------------------------- 几何
func _base_pt() -> Vector2:
	if _mode == "slope_intercept" or _mode == "general":
		return Vector2(0.0, _b)
	return _p

func _slope_handle() -> Vector2:
	var base := _base_pt()
	if _vertical:
		return base + Vector2(0.0, 1.5)
	return base + Vector2(1.0, _k).normalized() * 1.5

func _handles() -> Array:
	match _mode:
		"point_slope", "vertical":
			return [{"m": _slope_handle(), "kind": "k", "col": COL_K, "tag": "k"}]
		"slope_intercept", "general":
			return [{"m": _slope_handle(), "kind": "k", "col": COL_K, "tag": "k"}, {"m": Vector2(0.0, _b), "kind": "b", "col": COL_B, "tag": "b"}]
		"two_points":
			return [{"m": _a2, "kind": "pa", "col": COL_P, "tag": "A"}, {"m": _b2, "kind": "pb", "col": COL_K, "tag": "B"}]
		"intercept":
			return [{"m": Vector2(_xi, 0.0), "kind": "xi", "col": COL_P, "tag": "a"}, {"m": Vector2(0.0, _yi), "kind": "yi", "col": COL_B, "tag": "b"}]
	return []

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	_draw_grid()
	match _mode:
		"two_points":
			_draw_abc(_line_through(_a2, _b2))
			_draw_dot(_to_screen(_a2), COL_P, "A(%s, %s)" % [_fmt(_a2.x), _fmt(_a2.y)])
			_draw_dot(_to_screen(_b2), COL_K, "B(%s, %s)" % [_fmt(_b2.x), _fmt(_b2.y)])
		"intercept":
			_draw_abc([_yi, _xi, -_xi * _yi])
			_draw_dot(_to_screen(Vector2(_xi, 0.0)), COL_P, "a = %s" % _fmt(_xi))
			_draw_dot(_to_screen(Vector2(0.0, _yi)), COL_B, "b = %s" % _fmt(_yi))
		"general":
			_draw_sloped()
			_draw_dot(_to_screen(Vector2(0.0, _b)), COL_B, "b = %s" % _fmt(_b))
		"slope_intercept":
			_draw_sloped()
			_draw_dot(_to_screen(Vector2(0.0, _b)), COL_B, "b = %s" % _fmt(_b))
		_:
			if _vertical:
				_draw_vertical()
			else:
				_draw_sloped()
			_draw_dot(_to_screen(_p), COL_P, "P(%s, %s)" % [_fmt(_p.x), _fmt(_p.y)])

	if _reveal > 0.9 and not _auto_v:
		for h in _handles():
			_handle(_to_screen(h["m"]), h["col"], h["tag"])

	_draw_readout()
	_draw_prompt()

func _draw_sloped() -> void:
	var base := _base_pt()
	var off := base.y - _k * base.x
	var pa := _to_screen(Vector2(domain.x, _k * domain.x + off))
	var pb := _to_screen(Vector2(domain.y, _k * domain.y + off))
	_line_reveal(pa, pb)

func _draw_vertical() -> void:
	var top := _to_screen(Vector2(_p.x, range_y.y))
	var bot := _to_screen(Vector2(_p.x, range_y.x))
	_line_reveal(top, bot)

func _draw_abc(abc: Array) -> void:
	var A: float = abc[0]
	var B: float = abc[1]
	var C: float = abc[2]
	if absf(A) < 1e-6 and absf(B) < 1e-6:
		return
	if absf(B) > 1e-6:
		_line_reveal(_to_screen(Vector2(domain.x, (-A * domain.x - C) / B)), _to_screen(Vector2(domain.y, (-A * domain.y - C) / B)))
	else:
		var xv := -C / A
		_line_reveal(_to_screen(Vector2(xv, range_y.x)), _to_screen(Vector2(xv, range_y.y)))

func _line_reveal(p0: Vector2, p1: Vector2) -> void:
	var m := p0.lerp(p1, 0.5)
	draw_line(m, m.lerp(p0, _reveal), COL_LINE, 3.0)
	draw_line(m, m.lerp(p1, _reveal), COL_LINE, 3.0)

func _line_through(p: Vector2, q: Vector2) -> Array:
	var A := q.y - p.y
	var B := p.x - q.x
	return [A, B, -(A * p.x + B * p.y)]

func _draw_grid() -> void:
	var o := _origin()
	for gx in range(int(ceil(domain.x)), int(floor(domain.y)) + 1):
		var sp := _to_screen(Vector2(float(gx), 0.0))
		draw_line(Vector2(sp.x, 0.0), Vector2(sp.x, size.y), COL_GRID_MAJOR if gx == 0 else COL_GRID, 1.0)
	for gy in range(int(ceil(range_y.x)), int(floor(range_y.y)) + 1):
		var sp := _to_screen(Vector2(0.0, float(gy)))
		draw_line(Vector2(0.0, sp.y), Vector2(size.x, sp.y), COL_GRID_MAJOR if gy == 0 else COL_GRID, 1.0)
	draw_line(Vector2(0.0, o.y), Vector2(size.x, o.y), COL_AXIS, 1.5)
	draw_line(Vector2(o.x, 0.0), Vector2(o.x, size.y), COL_AXIS, 1.5)
	var mf := UI.mono_font()
	var tick := UI.fs(11)
	for gx in range(int(ceil(domain.x)), int(floor(domain.y)) + 1):
		if gx == 0:
			continue
		var sp := _to_screen(Vector2(float(gx), 0.0))
		draw_string(mf, Vector2(sp.x - tick * 0.45, o.y + tick + 4.0), str(gx), HORIZONTAL_ALIGNMENT_LEFT, -1, tick, COL_DIM)
	for gy in range(int(ceil(range_y.x)), int(floor(range_y.y)) + 1):
		if gy == 0:
			continue
		var sp := _to_screen(Vector2(0.0, float(gy)))
		draw_string(mf, Vector2(o.x + 6.0, sp.y + tick * 0.4), str(gy), HORIZONTAL_ALIGNMENT_LEFT, -1, tick, COL_DIM)

func _draw_dot(sp: Vector2, col: Color, label: String) -> void:
	draw_circle(sp, 6.5, Color(0.02, 0.03, 0.06, 0.92))
	draw_circle(sp, 4.6, col)
	draw_arc(sp, 5.6, 0.0, TAU, 24, Color(1, 1, 1, 0.85), 1.3, true)
	_draw_label(sp + Vector2(10.0, -10.0), label, col, 15)

func _handle(sp: Vector2, col: Color, tag: String) -> void:
	var pulse := 10.0 + 2.0 * sin(_t * 3.0)
	draw_circle(sp, pulse, Color(col, 0.16))
	draw_circle(sp, 6.5, Color(0.02, 0.03, 0.06, 0.9))
	draw_circle(sp, 5.0, col)
	_draw_label(sp + Vector2(12.0, -12.0), tag, col, 15)

func _draw_readout() -> void:
	if _reveal < 0.9:
		return
	var cx := size.x * 0.5
	match _mode:
		"slope_intercept":
			_show(cx, 48.0, 42.0, _formula_tex, _tex_si)
			_hud("当前 k = %s,b = %s" % [_fmt(_k), _fmt(_b)], cx, 92.0)
		"point_slope":
			_show(cx, 48.0, 42.0, _formula_tex, _tex_ps)
			_hud("当前 k = %s" % _fmt(_k), cx, 92.0)
		"two_points":
			if _tp_bad():
				var r := _draw_tex_centered(_tex_tp, Vector2(cx, 48.0), 42.0, Color(1, 1, 1, 0.35))
				_fail_cross_rect(r)
				_ctext("x₁ = x₂ 或 y₁ = y₂ → 两点式不能用", cx, 92.0, 16, COL_DANGER)
			else:
				_show(cx, 48.0, 42.0, _formula_tex, _tex_tp)
				_hud("当前 A(%s,%s)、B(%s,%s)" % [_fmt(_a2.x), _fmt(_a2.y), _fmt(_b2.x), _fmt(_b2.y)], cx, 92.0)
		"intercept":
			if _ic_bad():
				var r2 := _draw_tex_centered(_tex_ic, Vector2(cx, 48.0), 42.0, Color(1, 1, 1, 0.35))
				_fail_cross_rect(r2)
				_ctext("截距为 0(过原点)或不存在 → 截距式不能用", cx, 92.0, 16, COL_DANGER)
			else:
				_show(cx, 48.0, 42.0, _formula_tex, _tex_ic)
				_hud("当前 a = %s,b = %s" % [_fmt(_xi), _fmt(_yi)], cx, 92.0)
		"general":
			_show(cx, 40.0, 32.0, _formula_tex, _tex_gn)
			_show(cx, 84.0, 34.0, _formula2_tex, _tex_si)
			_hud("当前 k = %s,b = %s" % [_rat(_k), _rat(_b)], cx, 120.0)
		_:
			if _vertical:
				var r3 := _draw_tex_centered(_tex_ps, Vector2(cx, 48.0), 42.0, Color(1, 1, 1, 0.35))
				_fail_cross_rect(r3)
				_ctext("k 不存在 → 不能用点斜式，只能写成 x = %s" % _fmt(_p.x), cx, 92.0, 16, COL_DANGER)
			else:
				_show(cx, 48.0, 42.0, _formula_tex, _tex_ps)
				_hud("当前 k = %s" % _fmt(_k), cx, 92.0)

func _show(cx: float, cy: float, h: float, conc: Texture2D, tmpl: Texture2D) -> void:
	var t: Texture2D = conc if conc != null else tmpl
	_draw_tex_centered(t, Vector2(cx, cy), h, Color.WHITE)

func _hud(text: String, cx: float, y: float) -> void:
	_ctext(text, cx, y, 14, COL_DIM)

func _tp_bad() -> bool:
	return absf(_b2.x - _a2.x) < 0.1 or absf(_b2.y - _a2.y) < 0.1

func _ic_bad() -> bool:
	return absf(_xi) < 0.1 or absf(_yi) < 0.1

func _int_general() -> String:
	var den := 1
	for dd in range(1, 13):
		if _is_int(_k * dd) and _is_int(_b * dd):
			den = dd
			break
	var A := roundf(_k * den)
	var B := -float(den)
	var C := roundf(_b * den)
	var g := _gcd(int(roundf(absf(A))), int(roundf(absf(B))))
	g = _gcd(g, int(roundf(absf(C))))
	if g > 0:
		A /= g
		B /= g
		C /= g
	if A < -1e-6 or (absf(A) < 1e-6 and B < -1e-6):
		A = -A
		B = -B
		C = -C
	return _coef_eq(A, B, C)

func _is_int(x: float) -> bool:
	return absf(x - roundf(x)) < 1e-4

func _gcd(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var t := b
		b = a % b
		a = t
	return maxi(a, 1)

func _coef_eq(pA: float, pB: float, pC: float) -> String:
	var s := ""
	var first := true
	if absf(pA) > 1e-6:
		s += _coef_term(pA, "x", first)
		first = false
	if absf(pB) > 1e-6:
		s += _coef_term(pB, "y", first)
		first = false
	if absf(pC) > 1e-6:
		s += _coef_term(pC, "", first)
		first = false
	if s == "":
		s = "0"
	return s + " = 0"

func _coef_term(c: float, v: String, first: bool) -> String:
	var core := ("" if absf(absf(c) - 1.0) < 1e-6 and v != "" else _fmt(absf(c))) + v
	if first:
		return ("−" if c < 0.0 else "") + core
	return (" − " if c < 0.0 else " + ") + core

func _fail_cross(cx: float, cy: float, w: float) -> void:
	var r := Rect2(cx - w * 0.5, cy - 22.0, w, 44.0)
	_fail_cross_rect(r)

func _fail_cross_rect(r: Rect2) -> void:
	draw_line(r.position + Vector2(6, 6), r.end - Vector2(6, 6), Color(COL_DANGER, 0.85), 3.0)
	draw_line(Vector2(r.end.x - 6.0, r.position.y + 6.0), Vector2(r.position.x + 6.0, r.end.y - 6.0), Color(COL_DANGER, 0.85), 3.0)

func _draw_prompt() -> void:
	if _prompt == "":
		return
	_draw_label(Vector2(20.0, size.y - 18.0), _prompt, COL_DIM, 14)

func _draw_tex_centered(t: Texture2D, center: Vector2, target_h: float, col: Color) -> Rect2:
	if t == null:
		return Rect2()
	var w := target_h * float(t.get_width()) / float(maxi(t.get_height(), 1))
	var rect := Rect2(center - Vector2(w, target_h) * 0.5, Vector2(w, target_h))
	draw_texture_rect(t, rect, false, col)
	return rect

func _ctext(text: String, cx: float, y: float, size_px: int, col: Color) -> void:
	var px := UI.fs(size_px)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string(f, Vector2(cx - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

func _draw_label(pos: Vector2, text: String, col: Color, size_px: int) -> void:
	if text.is_empty():
		return
	var px := UI.fs(size_px)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_rect(Rect2(pos + Vector2(-5.0, -px - 2.0), Vector2(w + 10.0, px + 7.0)), Color(0.04, 0.06, 0.11, 0.62), true)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

# ---------------------------------------------------------------- 交互
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mpos: Vector2 = event.position
			var best := 44.0
			var kind := ""
			for h in _handles():
				var d: float = mpos.distance_to(_to_screen(h["m"]))
				if d < best:
					best = d
					kind = str(h["kind"])
			_drag_kind = kind
			if kind != "":
				accept_event()
		else:
			if _drag_kind != "":
				accept_event()
			_drag_kind = ""
	elif event is InputEventMouseMotion and _drag_kind != "":
		var m := _to_math(event.position)
		match _drag_kind:
			"k":
				if _mode == "slope_intercept" or _mode == "general":
					var dxv := m.x
					if absf(dxv) < 0.2:
						dxv = 0.2 * signf(dxv if dxv != 0.0 else 1.0)
					_k = clampf((m.y - _b) / dxv, -K_CLAMP, K_CLAMP)
				else:
					var dx2 := m.x - _p.x
					if absf(dx2) < 0.16:
						_vertical = true
						_auto_v = false
					else:
						_vertical = false
						_k = clampf((m.y - _p.y) / dx2, -K_CLAMP, K_CLAMP)
			"b":
				_b = clampf(roundf(m.y * 2.0) * 0.5, range_y.x + 0.5, range_y.y - 0.5)
			"pa":
				_a2 = _snap(m)
			"pb":
				_b2 = _snap(m)
			"xi":
				_xi = clampf(roundf(m.x * 2.0) * 0.5, domain.x + 0.5, domain.y - 0.5)
			"yi":
				_yi = clampf(roundf(m.y * 2.0) * 0.5, range_y.x + 0.5, range_y.y - 0.5)
		changed.emit(_k, _b)
		accept_event()

func _snap(m: Vector2) -> Vector2:
	return Vector2(
		clampf(roundf(m.x * 2.0) * 0.5, domain.x + 0.5, domain.y - 0.5),
		clampf(roundf(m.y * 2.0) * 0.5, range_y.x + 0.5, range_y.y - 0.5))
