class_name SlopeExplorer
extends Control
## 斜率演示器：两点 A(固定)、B(可拖动) + 实时 "rise/run" 直角边 + k=Δy/Δx 读数。
## 用于讲清"斜率 = 纵坐标增量 / 横坐标增量"，以及竖直直线 Δx=0 时 k 不存在。
## 纯代码绘制；载入时直角边逐段"生长"。

signal changed(dx: float, dy: float)

const COL_GRID := Color(1, 1, 1, 0.05)
const COL_GRID_MAJOR := Color(1, 1, 1, 0.10)
const COL_AXIS := Color(0.55, 0.62, 0.78, 1.0)
const COL_TEXT := Color(0.92, 0.96, 1.0, 1.0)
const COL_DIM := Color(0.62, 0.68, 0.80, 1.0)
const COL_LINE := Color(0.369, 0.902, 1.0, 1.0)
const COL_DX := Color(1.0, 0.83, 0.47, 1.0)
const COL_DY := Color(0.66, 0.55, 1.0, 1.0)
const COL_A := Color(1.0, 0.44, 0.52, 1.0)
const COL_B := Color(1.0, 0.57, 0.15, 1.0)
const COL_DANGER := Color(0.98, 0.44, 0.52, 1.0)
const COL_SUCCESS := Color(0.204, 0.827, 0.6, 1.0)

var domain := Vector2(-2.0, 6.0)
var range_y := Vector2(-2.0, 8.0)
var pad := 30.0

var _a := Vector2(1.0, 2.0)
var _b := Vector2(3.0, 6.0)
var _b0 := Vector2(3.0, 6.0)
var _prompt := ""
var _drag := false
var _t := 0.0
var _reveal := 0.0
var _reset_btn: Button
var _tex_slope: Texture2D
var _tex_alpha90: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	_tex_slope = _tex("line_slope_def")
	_tex_alpha90 = _tex("line_alpha90")
	_reset_btn = UI.ghost_button("重置 B", func() -> void: _reset(), 14)
	_reset_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_reset_btn.offset_left = -120.0
	_reset_btn.offset_right = -16.0
	_reset_btn.offset_top = 14.0
	_reset_btn.offset_bottom = 48.0
	add_child(_reset_btn)
	set_process(true)

func setup(cfg: Dictionary) -> void:
	if cfg.has("a"):
		var av: Array = cfg["a"]
		_a = Vector2(float(av[0]), float(av[1]))
	if cfg.has("b"):
		var bv: Array = cfg["b"]
		_b = Vector2(float(bv[0]), float(bv[1]))
	_b0 = _b
	_prompt = str(cfg.get("prompt", ""))
	if cfg.has("x"):
		var xr: Array = cfg["x"]
		domain = Vector2(float(xr[0]), float(xr[1]))
	else:
		domain = Vector2(minf(_a.x, _b.x) - 2.0, maxf(_a.x, _b.x) + 2.0)
	if cfg.has("y"):
		var yr: Array = cfg["y"]
		range_y = Vector2(float(yr[0]), float(yr[1]))
	else:
		range_y = Vector2(minf(_a.y, _b.y) - 2.0, maxf(_a.y, _b.y) + 2.0)
	_reveal = 0.0
	queue_redraw()

func _reset() -> void:
	_b = _b0
	_reveal = 0.0
	changed.emit(_b.x - _a.x, _b.y - _a.y)

func _process(delta: float) -> void:
	_t += delta
	_reveal = minf(_reveal + delta * 1.3, 1.0)
	queue_redraw()

func dx() -> float:
	return _b.x - _a.x

func dy() -> float:
	return _b.y - _a.y

func is_vertical() -> bool:
	return absf(dx()) < 0.05

# ---------------------------------------------------------------- 坐标
func _scale() -> float:
	var w := maxf(size.x - pad * 2.0, 1.0)
	var h := maxf(size.y - pad * 2.0 - 44.0, 1.0)
	return minf(w / maxf(domain.y - domain.x, 0.001), h / maxf(range_y.y - range_y.x, 0.001))

func _origin() -> Vector2:
	var s := _scale()
	var cx := (domain.x + domain.y) * 0.5
	var cy := (range_y.x + range_y.y) * 0.5
	return Vector2(size.x * 0.5 - cx * s, (size.y - 44.0) * 0.5 + cy * s + 12.0)

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

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	_draw_grid()
	var sa := _to_screen(_a)
	var sb := _to_screen(_b)
	var c := Vector2(_b.x, _a.y)
	var sc := _to_screen(c)

	# 直线 AB(延伸)
	draw_line(sa, sb, Color(COL_LINE, 0.9), 2.4)

	# 直角边动画：先横后纵
	var hx := clampf(_reveal / 0.55, 0.0, 1.0)
	var hy := clampf((_reveal - 0.5) / 0.5, 0.0, 1.0)
	var scx := sa.lerp(sc, hx)
	var scy := sc.lerp(sb, hy)
	draw_line(sa, scx, COL_DX, 3.0)
	draw_line(Vector2(scx.x, sc.y), scy, COL_DY, 3.0)
	if hx > 0.99 and hy > 0.99:
		_corner(sc, COL_DIM)

	# Δx / Δy 标签
	if _reveal > 0.5 and not is_vertical():
		var mx := sa.lerp(sc, 0.5)
		_draw_label(mx + Vector2(-30.0, 20.0), "Δx = %s" % _fmt(dx()), COL_DX, 15)
	if _reveal > 0.9:
		var my := sc.lerp(sb, 0.5)
		_draw_label(my + Vector2(10.0, -8.0), "Δy = %s" % _fmt(dy()), COL_DY, 15)

	# 点 A / B
	_draw_pt(sa, COL_A, "A(%s, %s)" % [_fmt(_a.x), _fmt(_a.y)], false)
	_draw_pt(sb, COL_B, "B(%s, %s)" % [_fmt(_b.x), _fmt(_b.y)], true)

	_draw_readout()
	_draw_prompt()

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

func _corner(at: Vector2, col: Color) -> void:
	if is_vertical():
		return
	var hdir := Vector2(-signf(dx()), 0.0)
	var vdir := Vector2(0.0, -signf(dy()))
	var s := 12.0
	draw_polyline(PackedVector2Array([at + hdir * s, at + hdir * s + vdir * s, at + vdir * s]), Color(col, 0.7), 1.4, true)

func _draw_pt(sp: Vector2, col: Color, label: String, pulse: bool) -> void:
	var r := 5.0
	if pulse:
		r = 5.0 + 0.6 * sin(_t * 3.0)
		draw_circle(sp, 12.0 + 1.5 * sin(_t * 3.0), Color(col, 0.16))
	draw_circle(sp, 6.5, Color(0.02, 0.03, 0.06, 0.92))
	draw_circle(sp, r, col)
	draw_arc(sp, 6.5, 0.0, TAU, 24, Color(1, 1, 1, 0.85), 1.4, true)
	_draw_label(sp + Vector2(10.0, -10.0), label, col, 15)

func _draw_readout() -> void:
	if _reveal < 0.9:
		return
	var cx := size.x * 0.5
	var y0 := _origin().y - _scale() * range_y.y + 10.0
	var accent := COL_DANGER if is_vertical() else COL_SUCCESS
	draw_rect(Rect2(Vector2(cx - 250.0, y0), Vector2(500.0, 92.0)), Color(0.05, 0.07, 0.12, 0.82), true)
	draw_rect(Rect2(Vector2(cx - 250.0, y0), Vector2(3.0, 92.0)), Color(accent, 0.9), true)
	if is_vertical():
		_draw_tex_centered(_tex_alpha90, Vector2(cx, y0 + 30.0), 38.0, Color.WHITE)
		_ctext("→   倾斜角 90°，斜率 k 不存在", cx, y0 + 76.0, 17, COL_DANGER)
	else:
		_draw_tex_centered(_tex_slope, Vector2(cx, y0 + 32.0), 52.0, Color.WHITE)
		var k := dy() / dx()
		_ctext("= %s / %s = %s        倾斜角 α ≈ %s°" % [_fmt(dy()), _fmt(dx()), _fmt(k), _fmt(_alpha_deg())], cx, y0 + 79.0, 16, COL_SUCCESS)

func _draw_tex_centered(t: Texture2D, center: Vector2, target_h: float, col: Color) -> void:
	if t == null:
		return
	var w := target_h * float(t.get_width()) / float(maxi(t.get_height(), 1))
	draw_texture_rect(t, Rect2(center - Vector2(w, target_h) * 0.5, Vector2(w, target_h)), false, col)

func _ctext(text: String, cx: float, y: float, s: int, col: Color) -> void:
	var px := UI.fs(s)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string(f, Vector2(cx - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

func _tex(n: String) -> Texture2D:
	var p := "res://art/line/formulas/%s.png" % n
	return load(p) if ResourceLoader.exists(p) else null

func _alpha_deg() -> float:
	var d := dx()
	var dyv := dy()
	if absf(d) < 0.05:
		return 90.0
	var a := rad_to_deg(atan2(dyv, d))
	if a < 0.0:
		a += 180.0
	if a >= 180.0:
		a -= 180.0
	return a

func _draw_prompt() -> void:
	if _prompt == "":
		return
	_draw_label(Vector2(20.0, 34.0), _prompt, COL_DIM, 14)

func _draw_label(pos: Vector2, text: String, col: Color, s: int) -> void:
	if text.is_empty() or col.a <= 0.01:
		return
	var px := UI.fs(s)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_rect(Rect2(pos + Vector2(-5.0, -px - 2.0), Vector2(w + 10.0, px + 7.0)), Color(0.04, 0.06, 0.11, 0.62), true)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

# ---------------------------------------------------------------- 交互
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.position.distance_to(_to_screen(_b)) < 44.0:
				_drag = true
				accept_event()
		else:
			if _drag:
				accept_event()
			_drag = false
	elif event is InputEventMouseMotion and _drag:
		var m := _to_math(event.position)
		_b = Vector2(roundf(m.x * 2.0) * 0.5, roundf(m.y * 2.0) * 0.5)
		_b.x = clampf(_b.x, domain.x, domain.y)
		_b.y = clampf(_b.y, range_y.x, range_y.y)
		changed.emit(dx(), dy())
		accept_event()
