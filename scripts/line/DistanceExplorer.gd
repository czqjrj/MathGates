class_name DistanceExplorer
extends Control
## 距离演示器(三种模式):
##  - two_points : 拖动 A、B，画直角三角形，实时给出 |AB| = √((Δx)²+(Δy)²)
##  - point_line : 拖动点 P，作出垂足与垂线段，实时给出点到直线距离(垂线段最短)
##  - parallel   : 两条平行线，拖动线上的点，垂线段长度恒定
## 纯代码绘制；线段"生长"、垂足脉冲。

const COL_GRID := Color(1, 1, 1, 0.05)
const COL_GRID_MAJOR := Color(1, 1, 1, 0.10)
const COL_AXIS := Color(0.55, 0.62, 0.78, 1.0)
const COL_TEXT := Color(0.92, 0.96, 1.0, 1.0)
const COL_DIM := Color(0.62, 0.68, 0.8, 1.0)
const COL_LINE := Color(0.369, 0.902, 1.0, 1.0)
const COL_A := Color(1.0, 0.44, 0.52, 1.0)
const COL_B := Color(1.0, 0.83, 0.47, 1.0)
const COL_DX := Color(1.0, 0.83, 0.47, 1.0)
const COL_DY := Color(0.66, 0.55, 1.0, 1.0)
const COL_DIST := Color(0.204, 0.827, 0.6, 1.0)

var domain := Vector2(-4.0, 6.0)
var range_y := Vector2(-3.0, 6.0)
var pad := 30.0

var _mode := "two_points"
var _a := Vector2(1.0, 1.0)
var _b := Vector2(4.0, 5.0)
var _a0 := Vector2(1.0, 1.0)
var _b0 := Vector2(4.0, 5.0)
var _A := 3.0
var _B := 4.0
var _C := -5.0
var _C2 := 15.0
var _p := Vector2(1.0, 2.0)
var _p0 := Vector2(1.0, 2.0)
var _prompt := ""
var _drag_kind := ""
var _t := 0.0
var _reveal := 0.0
var _reset_btn: Button
var _tex_formula: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	_tex_formula = _tex("line_dist_point")
	_reset_btn = UI.ghost_button("重置", func() -> void: _reset(), 14)
	_reset_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_reset_btn.offset_left = -100.0
	_reset_btn.offset_right = -16.0
	_reset_btn.offset_top = 14.0
	_reset_btn.offset_bottom = 48.0
	add_child(_reset_btn)
	set_process(true)

func setup(cfg: Dictionary) -> void:
	_mode = str(cfg.get("mode", "two_points"))
	_prompt = str(cfg.get("prompt", ""))
	if cfg.has("a"):
		var a: Array = cfg["a"]
		_a = Vector2(float(a[0]), float(a[1]))
	if cfg.has("b") and cfg["b"] is Array:
		var b: Array = cfg["b"]
		_b = Vector2(float(b[0]), float(b[1]))
	_a0 = _a
	_b0 = _b
	_A = float(cfg.get("A", 3.0))
	_B = float(cfg.get("B", 4.0))
	_C = float(cfg.get("C", -5.0))
	_C2 = float(cfg.get("C2", 15.0))
	if cfg.has("p"):
		var p: Array = cfg["p"]
		_p = Vector2(float(p[0]), float(p[1]))
	_p0 = _p
	if cfg.has("x"):
		var xr: Array = cfg["x"]
		domain = Vector2(float(xr[0]), float(xr[1]))
	if cfg.has("y"):
		var yr: Array = cfg["y"]
		range_y = Vector2(float(yr[0]), float(yr[1]))
	var fp := str(cfg.get("formula", ""))
	if fp != "":
		_tex_formula = _tex(fp)
	_reveal = 0.0
	queue_redraw()

func _reset() -> void:
	_a = _a0
	_b = _b0
	_p = _p0
	_reveal = 0.0

func _tex(n: String) -> Texture2D:
	if n == "":
		return null
	return load(n) if ResourceLoader.exists(n) else null

func _process(delta: float) -> void:
	_t += delta
	_reveal = minf(_reveal + delta * 1.4, 1.0)
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

func _dist_pt_line(p: Vector2) -> float:
	return absf(_A * p.x + _B * p.y + _C) / sqrt(_A * _A + _B * _B)

func _foot(p: Vector2) -> Vector2:
	var d := (_A * p.x + _B * p.y + _C) / (_A * _A + _B * _B)
	return Vector2(p.x - _A * d, p.y - _B * d)

func _foot2(p: Vector2) -> Vector2:
	var d := (_A * p.x + _B * p.y + _C2) / (_A * _A + _B * _B)
	return Vector2(p.x - _A * d, p.y - _B * d)

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	_draw_grid()
	match _mode:
		"point_line":
			_draw_abc([_A, _B, _C])
			_draw_point_line()
		"parallel":
			_draw_abc([_A, _B, _C])
			_draw_abc([_A, _B, _C2])
			_draw_parallel()
		_:
			_draw_two_points()
	_draw_readout()
	_draw_prompt()
	if _reveal > 0.9:
		for h in _handles():
			_handle(_to_screen(h["m"]), h["col"], h["tag"])

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

func _draw_abc(abc: Array) -> void:
	var A: float = abc[0]
	var B: float = abc[1]
	var C: float = abc[2]
	if absf(B) > 1e-6:
		_line_reveal(_to_screen(Vector2(domain.x, (-A * domain.x - C) / B)), _to_screen(Vector2(domain.y, (-A * domain.y - C) / B)))
	else:
		var xv := -C / A if absf(A) > 1e-6 else 0.0
		_line_reveal(_to_screen(Vector2(xv, range_y.x)), _to_screen(Vector2(xv, range_y.y)))

func _line_reveal(p0: Vector2, p1: Vector2) -> void:
	var m := p0.lerp(p1, 0.5)
	draw_line(m, m.lerp(p0, _reveal), COL_LINE, 2.6)
	draw_line(m, m.lerp(p1, _reveal), COL_LINE, 2.6)

func _draw_two_points() -> void:
	var sa := _to_screen(_a)
	var sb := _to_screen(_b)
	var c := Vector2(_b.x, _a.y)
	var sc := _to_screen(c)
	var hx := clampf(_reveal / 0.55, 0.0, 1.0)
	var hy := clampf((_reveal - 0.5) / 0.5, 0.0, 1.0)
	var scx := sa.lerp(sc, hx)
	var scy := sc.lerp(sb, hy)
	draw_line(sa, scx, COL_DX, 2.6)
	draw_line(Vector2(sc.x, sc.y), scy, COL_DY, 2.6)
	draw_line(sa, sb, COL_DIST, 3.0)
	if _reveal > 0.5:
		_draw_label(sa.lerp(sc, 0.5) + Vector2(-24.0, 20.0), "Δx = %s" % _fmt(_b.x - _a.x), COL_DX, 14)
	if _reveal > 0.9:
		_draw_label(sc.lerp(sb, 0.5) + Vector2(10.0, -8.0), "Δy = %s" % _fmt(_b.y - _a.y), COL_DY, 14)
	_draw_dot(sa, COL_A, "A(%s, %s)" % [_fmt(_a.x), _fmt(_a.y)])
	_draw_dot(sb, COL_B, "B(%s, %s)" % [_fmt(_b.x), _fmt(_b.y)])

func _draw_point_line() -> void:
	var sp := _to_screen(_p)
	var f := _foot(_p)
	var sf := _to_screen(f)
	var seg := sp.lerp(sf, _reveal)
	draw_dashed_line(sf, seg, COL_DIST, 3.0, 8.0)
	_draw_dot(sp, COL_A, "P(%s, %s)" % [_fmt(_p.x), _fmt(_p.y)])
	draw_circle(sf, 4.5, COL_DIST)
	draw_arc(sf, 5.6, 0.0, TAU, 20, Color(1, 1, 1, 0.8), 1.2, true)
	if _reveal > 0.9:
		_draw_label(seg, "d = %s" % _fmt(_dist_pt_line(_p)), COL_DIST, 15)
		var dir_line := Vector2(_B, -_A).normalized()
		var dir_pf := (_p - f).normalized()
		var s := 12.0
		draw_polyline(PackedVector2Array([sf + dir_line * s, sf + dir_line * s + dir_pf * s, sf + dir_pf * s]), Color(COL_DIST, 0.8), 1.4, true)
		draw_dashed_line(sf, sf + dir_line * s, Color(COL_DIST, 0.4), 1.0, 4.0)

func _draw_parallel() -> void:
	var p := _project_l1(_p)
	var f := _foot2(p)
	var sp := _to_screen(p)
	var sf := _to_screen(f)
	var seg := sp.lerp(sf, _reveal)
	draw_dashed_line(sf, seg, COL_DIST, 3.0, 8.0)
	_draw_dot(sp, COL_A, "P")
	draw_circle(sf, 4.5, COL_DIST)
	if _reveal > 0.9:
		_draw_label(seg, "d = %s" % _fmt(absf(_C - _C2) / sqrt(_A * _A + _B * _B)), COL_DIST, 15)

func _project_l1(p: Vector2) -> Vector2:
	var d := (_A * p.x + _B * p.y + _C) / (_A * _A + _B * _B)
	return Vector2(p.x - _A * d, p.y - _B * d)

func _handles() -> Array:
	match _mode:
		"two_points":
			return [{"m": _a, "col": COL_A, "tag": "A"}, {"m": _b, "col": COL_B, "tag": "B"}]
		"point_line":
			return [{"m": _p, "col": COL_A, "tag": "P"}]
		"parallel":
			return [{"m": _p, "col": COL_A, "tag": "P"}]
	return []

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
	var y := 42.0
	var hud := ""
	match _mode:
		"two_points":
			_show(cx, y + 22.0, 40.0, "line_dist_two")
			hud = "Δx = %s,Δy = %s   →   |AB| = %s" % [_fmt(_b.x - _a.x), _fmt(_b.y - _a.y), _fmt(_a.distance_to(_b))]
		"parallel":
			_show(cx, y + 22.0, 40.0, "line_dist_par")
			hud = "两条平行线距离 d = %s(沿线上移动也恒定)" % _fmt(absf(_C - _C2) / sqrt(_A * _A + _B * _B))
		_:
			_show(cx, y + 22.0, 40.0, "line_dist_point")
			hud = "d = |A x₀ + B y₀ + C| / √(A²+B²) = %s" % _fmt(_dist_pt_line(_p))
	_hud(hud, cx, y + 62.0)

func _show(cx: float, cy: float, h: float, nm: String) -> void:
	var t := _tex(nm)
	if t != null:
		_draw_tex_centered(t, Vector2(cx, cy), h, Color.WHITE)

func _draw_prompt() -> void:
	if _prompt == "":
		return
	_draw_label(Vector2(20.0, size.y - 18.0), _prompt, COL_DIM, 14)

func _draw_tex_centered(t: Texture2D, center: Vector2, target_h: float, col: Color) -> void:
	if t == null:
		return
	var w := target_h * float(t.get_width()) / float(maxi(t.get_height(), 1))
	draw_texture_rect(t, Rect2(center - Vector2(w, target_h) * 0.5, Vector2(w, target_h)), false, col)

func _ctext(text: String, cx: float, y: float, size_px: int, col: Color) -> void:
	var px := UI.fs(size_px)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string(f, Vector2(cx - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

func _hud(text: String, cx: float, y: float) -> void:
	_ctext(text, cx, y, 14, COL_DIM)

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
					kind = str(h["tag"])
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
			"A":
				_a = _snap(m)
			"B":
				_b = _snap(m)
			"P":
				if _mode == "parallel":
					_p = _project_l1(m)
				else:
					_p = _snap(m)
		accept_event()

func _snap(m: Vector2) -> Vector2:
	return Vector2(
		clampf(roundf(m.x * 2.0) * 0.5, domain.x + 0.5, domain.y - 0.5),
		clampf(roundf(m.y * 2.0) * 0.5, range_y.x + 0.5, range_y.y - 0.5))
