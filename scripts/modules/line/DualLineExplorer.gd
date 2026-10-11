class_name DualLineExplorer
extends Control
## 双线位置关系演示器：l1 固定、l2 可拖动。实时计算并显示两直线关系
## (平行 / 垂直 / 相交 / 重合)与一般式判别式 A1A2+B1B2、A1B2−A2B1。
## 模式：relation(自由探索) / task(任务：让 l2 与 l1 平行或垂直)。
## 纯代码绘制；直线"生长"、交点脉冲、达标高亮。

signal goal_reached

const COL_GRID := Palette.GRID
const COL_GRID_MAJOR := Palette.GRID_MAJOR
const COL_AXIS := Palette.AXIS
const COL_TEXT := Palette.TEXT
const COL_DIM := Palette.DIM
const COL_L1 := Palette.ACCENT
const COL_L2 := Palette.ORANGE
const COL_P := Color(1.0, 0.44, 0.52, 1.0)
const COL_OK := Palette.SUCCESS
const COL_BAD := Palette.DANGER
const COL_K := Palette.GOLD
const COL_B := Color(0.66, 0.55, 1.0, 1.0)
const K_CLAMP := 6.0

var domain := Vector2(-5.0, 5.0)
var range_y := Vector2(-4.0, 4.0)
var pad := 30.0

var _l1 := [-0.5, 1.0, -1.0]
var _k2 := 2.0
var _b2 := -1.0
var _k2_0 := 2.0
var _b2_0 := -1.0
var _mode := "relation"
var _goal := "perp"
var _prompt := ""
var _drag_kind := ""
var _t := 0.0
var _reveal := 0.0
var _ok_glow := 0.0
var _goal_fired := false
var _reset_btn: Button
var _tex_f1: Texture2D
var _tex_f2: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	_reset_btn = UI.ghost_button("重置", func() -> void: _reset(), 14)
	_reset_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_reset_btn.offset_left = -100.0
	_reset_btn.offset_right = -16.0
	_reset_btn.offset_top = 14.0
	_reset_btn.offset_bottom = 48.0
	add_child(_reset_btn)
	set_process(true)

func setup(cfg: Dictionary) -> void:
	if cfg.has("l1"):
		var d: Dictionary = cfg["l1"]
		if d.has("A"):
			_l1 = [float(d["A"]), float(d.get("B", 1.0)), float(d.get("C", 0.0))]
		elif d.has("k"):
			var k := float(d["k"])
			var b := float(d.get("b", 0.0))
			_l1 = [-k, 1.0, -b]
	_k2 = float(cfg.get("k2", 2.0))
	_b2 = float(cfg.get("b2", -1.0))
	_k2_0 = _k2
	_b2_0 = _b2
	_mode = str(cfg.get("mode", "relation"))
	_goal = str(cfg.get("goal", "perp"))
	_prompt = str(cfg.get("prompt", ""))
	if cfg.has("x"):
		var xr: Array = cfg["x"]
		domain = Vector2(float(xr[0]), float(xr[1]))
	if cfg.has("y"):
		var yr: Array = cfg["y"]
		range_y = Vector2(float(yr[0]), float(yr[1]))
	_tex_f1 = _tex(str(cfg.get("formula1", "")))
	_tex_f2 = _tex(str(cfg.get("formula2", "")))
	_reveal = 0.0
	_ok_glow = 0.0
	_goal_fired = false
	queue_redraw()

func _reset() -> void:
	_k2 = _k2_0
	_b2 = _b2_0
	_reveal = 0.0
	_ok_glow = 0.0
	_goal_fired = false

func _tex(n: String) -> Texture2D:
	if n == "":
		return null
	return load(n) if ResourceLoader.exists(n) else null

func _process(delta: float) -> void:
	_t += delta
	_reveal = minf(_reveal + delta * 1.4, 1.0)
	if _mode == "task" and is_goal_ok():
		_ok_glow = minf(_ok_glow + delta * 3.0, 1.0)
		if not _goal_fired:
			_goal_fired = true
			goal_reached.emit()
	else:
		_goal_fired = false
		_ok_glow = maxf(_ok_glow - delta * 3.0, 0.0)
	queue_redraw()

# ---------------------------------------------------------------- 关系
func _A2() -> float:
	return -_k2
func _B2() -> float:
	return 1.0
func _C2() -> float:
	return -_b2
func _m() -> float:
	return _l1[0] * _B2() - _A2() * _l1[1]
func _n() -> float:
	return _l1[0] * _A2() + _l1[1] * _B2()

func _relation() -> String:
	if absf(_m()) < 1e-4:
		var d: float = float(_l1[0]) * _C2() - _A2() * float(_l1[2])
		return "重合" if absf(d) < 1e-4 else "平行"
	if absf(_n()) < 1e-4:
		return "垂直"
	return "相交"

func is_goal_ok() -> bool:
	if _goal == "perp":
		return absf(_n()) < 0.06
	if _goal == "para":
		return absf(_m()) < 0.06 and _relation() == "平行"
	return true

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

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	_draw_grid()
	_draw_line(_l1, COL_L1)
	_draw_line([_A2(), _B2(), _C2()], COL_L2)
	# 交点
	var m := _m()
	if absf(m) > 1e-4:
		var px: float = (float(_l1[1]) * _C2() - _B2() * float(_l1[2])) / m
		var py: float = (float(_l1[2]) * _A2() - _C2() * float(_l1[0])) / m
		if px >= domain.x and px <= domain.y and py >= range_y.x and py <= range_y.y and _reveal > 0.6:
			var sp := _to_screen(Vector2(px, py))
			draw_circle(sp, 8.0 + 2.0 * sin(_t * 3.0), Color(COL_P, 0.18))
			draw_circle(sp, 4.3, COL_P)
			_draw_label(sp + Vector2(9.0, -9.0), "P(%s, %s)" % [_fmt(px), _fmt(py)], COL_P, 14)
			if absf(_n()) < 1e-4:
				_draw_right_angle(sp, _l1, [_A2(), _B2(), _C2()])
	# 手柄
	if _reveal > 0.9:
		var base := Vector2(0.0, _b2)
		_handle(_to_screen(base + Vector2(1.0, _k2).normalized() * 1.4), COL_K, "k")
		_handle(_to_screen(base), COL_B, "b")
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

func _draw_line(abc: Array, col: Color) -> void:
	var A: float = abc[0]
	var B: float = abc[1]
	var C: float = abc[2]
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
	draw_line(mid, mid.lerp(p0, _reveal), col, 3.0)
	draw_line(mid, mid.lerp(p1, _reveal), col, 3.0)

func _draw_right_angle(at: Vector2, abc1: Array, abc2: Array) -> void:
	# 沿两条线的方向各取单位向量，画直角小方块
	var d1 := Vector2(abc1[1], -abc1[0]).normalized()
	var d2 := Vector2(abc2[1], -abc2[0]).normalized()
	if d1.dot(d2) < 0.0:
		d2 = -d2
	var s := 13.0
	var pts := PackedVector2Array([at + d1 * s, at + d1 * s + d2 * s, at + d2 * s])
	draw_polyline(pts, Color(COL_OK, 0.9), 1.6, true)

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
	var rel := _relation()
	var rel_col := COL_DIM
	if rel == "垂直":
		rel_col = COL_OK
	elif rel == "平行":
		rel_col = COL_L1
	elif rel == "重合":
		rel_col = COL_BAD
	# 公式图(给定)
	var y := 40.0
	if _tex_f1 != null and _tex_f2 != null:
		_draw_tex_centered(_tex_f1, Vector2(cx - 92.0, y + 14.0), 26.0, Color(1, 1, 1, 0.85))
		_draw_tex_centered(_tex_f2, Vector2(cx + 92.0, y + 14.0), 26.0, Color(1, 1, 1, 0.85))
	elif _tex_f1 != null:
		_draw_tex_centered(_tex_f1, Vector2(cx, y + 14.0), 26.0, Color(1, 1, 1, 0.85))
	elif _tex_f2 != null:
		_draw_tex_centered(_tex_f2, Vector2(cx, y + 14.0), 26.0, Color(1, 1, 1, 0.85))
	# 关系
	var f := UI.font()
	var reltxt := "l1 ⊥ l2" if rel == "垂直" else ("l1 ∥ l2" if rel == "平行" else ("l1 与 l2 重合" if rel == "重合" else "l1 与 l2 相交"))
	var rs := UI.fs(24)
	var w := f.get_string_size(reltxt, HORIZONTAL_ALIGNMENT_LEFT, -1, rs).x
	var rh := rs * 1.7
	draw_rect(Rect2(Vector2(cx - w * 0.5 - 16.0, y + 34.0), Vector2(w + 32.0, rh)), Color(0.05, 0.07, 0.12, 0.85), true)
	draw_rect(Rect2(Vector2(cx - w * 0.5 - 16.0, y + 34.0), Vector2(3.0, rh)), Color(rel_col, 0.9), true)
	draw_string(f, Vector2(cx - w * 0.5, y + 34.0 + rs * 1.15), reltxt, HORIZONTAL_ALIGNMENT_LEFT, -1, rs, rel_col)
	# 判别式
	_ctext("A1A2 + B1B2 = %s      A1B2 − A2B1 = %s" % [_fmt(_n()), _fmt(_m())], cx, y + 96.0, 15, COL_DIM)
	if _mode == "task":
		var goal := "垂直" if _goal == "perp" else "平行"
		var okc := COL_OK if is_goal_ok() else COL_DIM
		var t := ("✓ 已使 l1 与 l2 %s" % goal) if is_goal_ok() else ("任务：让 l2 与 l1 %s" % goal)
		_ctext(t, cx, y + 122.0, 16, okc)

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
			var hk := _to_screen(Vector2(0.0, _b2) + Vector2(1.0, _k2).normalized() * 1.4)
			var hb := _to_screen(Vector2(0.0, _b2))
			var dk: float = mpos.distance_to(hk)
			var db: float = mpos.distance_to(hb)
			if dk < 44.0 and dk <= db:
				_drag_kind = "k"
			elif db < 44.0:
				_drag_kind = "b"
			if _drag_kind != "":
				accept_event()
		else:
			if _drag_kind != "":
				accept_event()
			_drag_kind = ""
	elif event is InputEventMouseMotion and _drag_kind != "":
		var m := _to_math(event.position)
		if _drag_kind == "k":
			var dxv := m.x
			if absf(dxv) < 0.2:
				dxv = 0.2 * signf(dxv if dxv != 0.0 else 1.0)
			_k2 = clampf((m.y - _b2) / dxv, -K_CLAMP, K_CLAMP)
		elif _drag_kind == "b":
			_b2 = clampf(roundf(m.y * 2.0) * 0.5, range_y.x + 0.5, range_y.y - 0.5)
		accept_event()
