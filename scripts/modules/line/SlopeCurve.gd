class_name SlopeCurve
extends Control
## 倾斜角—斜率关系图：横轴 α(0°～180°)、纵轴 k，绘制 k=tanα 的两支曲线。
## 直观呈现：锐角支 k 从 0 升到 +∞;α=90° 处断开(k 不存在)；钝角支 k 从 −∞ 升到 0⁻。
## 载入自动分段导览，可拖动标记点沿曲线移动。

signal angle_changed(deg: float)

const COL_GRID := Palette.GRID
const COL_AXIS := Palette.AXIS
const COL_TEXT := Palette.TEXT
const COL_DIM := Palette.DIM
const COL_POS := Palette.ACCENT
const COL_NEG := Palette.ORANGE
const COL_DANGER := Palette.DANGER
const COL_SUCCESS := Palette.SUCCESS
const COL_MARK := Palette.GOLD

const KMAX := 4.0
const A_MAX := 180.0

var _alpha := 30.0
var _demo_t := -0.35
var _demo := true
var _user := false
var _drag := false
var _phases: Array = []
var _emphasis := "monotonic"
var _reveal := 0.0
var _t := 0.0
var _caption := ""
var _caption_a := 0.0
var _replay_btn: Button
var _tex_tan: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	_replay_btn = UI.ghost_button("↻ 重播导览", func() -> void: replay(), 14)
	_replay_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_replay_btn.offset_left = -134.0
	_replay_btn.offset_right = -16.0
	_replay_btn.offset_top = 14.0
	_replay_btn.offset_bottom = 48.0
	add_child(_replay_btn)
	var tp := "res://art/line/formulas/line_slope_tan.png"
	_tex_tan = load(tp) if ResourceLoader.exists(tp) else null
	set_process(true)

func setup(cfg: Dictionary) -> void:
	_emphasis = str(cfg.get("emphasis", "monotonic"))
	_phases = _build_phases(_emphasis)
	replay()

func replay() -> void:
	_demo_t = -0.35
	_demo = true
	_user = false
	_drag = false
	_alpha = 30.0
	_reveal = 0.0
	_caption = ""
	_caption_a = 0.0
	queue_redraw()

func _build_phases(emphasis: String) -> Array:
	match emphasis:
		"slope":
			return [
				{ "dur": 1.5, "a0": 45.0, "a1": 89.4, "text": "α 增大、靠近 90°：k = tanα 沿曲线冲向 +∞。" },
				{ "dur": 1.3, "a0": 89.4, "a1": 90.5, "text": "α = 90° 处曲线断开，k 不存在；越过 90° 后 k 从 +∞ 跳到 −∞。" },
				{ "dur": 1.5, "a0": 90.5, "a1": 135.0, "text": "钝角支：α = 135° 时 k = −1，再增大 k 从 −∞ 升向 0。" },
				{ "dur": 2.0, "a0": 135.0, "a1": 135.0, "text": "所以已知 α 范围求 k 范围，必须在 90° 处分段讨论。" },
			]
		_:
			return [
				{ "dur": 1.7, "a0": 2.0, "a1": 89.0, "text": "锐角支 α∈(0°，90°):k = tanα > 0，从 0 递增到 +∞。" },
				{ "dur": 1.7, "a0": 91.0, "a1": 179.0, "text": "钝角支 α∈(90°，180°):k = tanα < 0，从 −∞ 递增到 0⁻。" },
				{ "dur": 2.1, "a0": 179.0, "a1": 179.0, "text": "两段各自递增；但钝角 k<0 恒小于锐角 k>0，所以不能笼统说「α 越大 k 越大」。" },
			]

func _process(delta: float) -> void:
	_t += delta
	_reveal = minf(_reveal + delta * 1.4, 1.0)
	if _caption != "":
		_caption_a = minf(_caption_a + delta * 4.0, 1.0)
	if _demo and not _user:
		_demo_t += delta
		_update_demo()
	queue_redraw()

func _update_demo() -> void:
	if _phases.is_empty() or _demo_t < 0.0:
		return
	var start := 0.0
	for ph in _phases:
		var dur: float = maxf(float(ph.get("dur", 1.0)), 0.001)
		if _demo_t <= start + dur:
			var p := clampf((_demo_t - start) / dur, 0.0, 1.0)
			var e := p * p * (3.0 - 2.0 * p)
			_alpha = lerpf(float(ph.get("a0", 0.0)), float(ph.get("a1", 0.0)), e)
			_set_caption(str(ph.get("text", "")))
			return
		start += dur
	var last: Dictionary = _phases[_phases.size() - 1]
	_alpha = float(last.get("a1", _alpha))
	_set_caption(str(last.get("text", "")))
	_demo = false
	_user = true

func _set_caption(t: String) -> void:
	if t != _caption:
		_caption = t
		_caption_a = 0.0

func _takeover() -> void:
	if _demo:
		_demo = false
		_user = true
		_set_caption("手动探索：沿横轴拖动，看 k = tanα 在曲线上的位置。")

# ---------------------------------------------------------------- 坐标
func _plot() -> Rect2:
	return Rect2(58.0, 62.0, maxf(size.x - 82.0, 10.0), maxf(size.y - 62.0 - 92.0, 10.0))

func _mx(alpha: float) -> float:
	var r := _plot()
	return r.position.x + clampf(alpha / A_MAX, 0.0, 1.0) * r.size.x

func _my(k: float) -> float:
	var r := _plot()
	var cy := r.position.y + r.size.y * 0.5
	return cy - clampf(k / KMAX, -1.0, 1.0) * (r.size.y * 0.5)

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	var r := _plot()
	# 背板
	draw_rect(Rect2(r.position - Vector2(0, 0), r.size), Color(0.03, 0.05, 0.09, 0.4), true)
	# 网格
	for i in range(0, 181, 30):
		var x := _mx(float(i))
		draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + r.size.y), COL_GRID, 1.0)
	for kk in range(-4, 5):
		var y := _my(float(kk))
		draw_line(Vector2(r.position.x, y), Vector2(r.position.x + r.size.x, y), COL_GRID, 1.0)
	# 坐标轴
	var cy := r.position.y + r.size.y * 0.5
	draw_line(Vector2(r.position.x, cy), Vector2(r.position.x + r.size.x, cy), COL_AXIS, 1.5)
	draw_line(Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.position.y + r.size.y), COL_AXIS, 1.5)
	# 90° 渐近线
	var x90 := _mx(90.0)
	draw_dashed_line(Vector2(x90, r.position.y), Vector2(x90, r.position.y + r.size.y), Color(COL_DANGER, 0.6), 1.6, 8.0)
	# 刻度
	var mf := UI.mono_font()
	var tick := UI.fs(11)
	for i in range(0, 181, 30):
		var x := _mx(float(i))
		draw_string(mf, Vector2(x - tick, cy + tick + 6.0), "%d°" % i, HORIZONTAL_ALIGNMENT_LEFT, -1, tick, COL_DIM)
	for kk in range(-4, 5, 2):
		var y := _my(float(kk))
		draw_string(mf, Vector2(r.position.x - tick * 2.2, y + tick * 0.35), str(kk), HORIZONTAL_ALIGNMENT_LEFT, -1, tick, COL_DIM)
	# 轴名
	_draw_label(Vector2(r.position.x + r.size.x - 54.0, cy + 34.0), "倾斜角 α", COL_DIM, 13)
	_draw_label(Vector2(r.position.x - 46.0, r.position.y + 14.0), "k", COL_DIM, 14)
	# 90° 标注
	_draw_label(Vector2(x90 + 6.0, r.position.y + 16.0), "α=90°：k 不存在", Color(COL_DANGER, 0.95), 13)

	# 曲线(两支)
	_draw_branch(0.4, 90.0, COL_POS)
	_draw_branch(90.0, 179.6, COL_NEG)
	# 无穷箭头
	_arrow_up(Vector2(x90 - 6.0, r.position.y + 4.0), COL_POS)
	_arrow_down(Vector2(x90 + 6.0, r.position.y + r.size.y - 4.0), COL_NEG)
	_draw_label(Vector2(_mx(52.0), _my(3.4)), "k>0 递增", Color(COL_POS, 0.85), 13)
	_draw_label(Vector2(_mx(112.0), _my(-3.4)), "k<0 递增", Color(COL_NEG, 0.85), 13)

	_draw_marker()
	_draw_caption()

func _draw_branch(a_from: float, a_to: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var a := a_from
	while a <= a_to:
		var k := tan(deg_to_rad(a))
		if absf(k) <= KMAX:
			pts.append(Vector2(_mx(a), _my(k)))
		elif pts.size() >= 2:
			draw_polyline(pts, col, 2.6, true)
			pts = PackedVector2Array()
		a += 0.5
	if pts.size() >= 2:
		draw_polyline(pts, col, 2.6, true)

func _arrow_up(at: Vector2, col: Color) -> void:
	draw_line(at, at + Vector2(0, 10), col, 2.0)
	draw_line(at + Vector2(-6, 12), at, col, 2.0)
	draw_line(at + Vector2(6, 12), at, col, 2.0)

func _arrow_down(at: Vector2, col: Color) -> void:
	draw_line(at, at + Vector2(0, -10), col, 2.0)
	draw_line(at + Vector2(-6, -12), at, col, 2.0)
	draw_line(at + Vector2(6, -12), at, col, 2.0)

func _draw_marker() -> void:
	var r := _plot()
	var a := clampf(_alpha, 0.4, 179.6)
	var k := tan(deg_to_rad(a))
	var near90 := absf(a - 90.0) < 0.6
	var kk := clampf(k, -KMAX, KMAX)
	var pos := Vector2(_mx(a), _my(kk))
	# 竖直投影到 α 轴
	draw_line(Vector2(pos.x, r.position.y + r.size.y * 0.5), pos, Color(COL_MARK, 0.4), 1.2)
	draw_circle(pos, 10.0 + 1.5 * sin(_t * 3.0), Color(COL_MARK, 0.15))
	draw_circle(pos, 5.5, Color(0.02, 0.03, 0.06, 0.9))
	draw_circle(pos, 4.2, COL_MARK)
	# 读数
	var f := UI.font()
	var ms := UI.fs(18)
	var bh := ms * 1.8
	var cy0 := r.position.y - bh - 8.0
	if near90:
		var txt := "α = 90°   →   k 不存在"
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, ms).x
		var bx := (size.x - w) * 0.5
		draw_rect(Rect2(Vector2(bx - 14.0, cy0), Vector2(w + 28.0, bh)), Color(0.05, 0.07, 0.12, 0.82), true)
		draw_rect(Rect2(Vector2(bx - 14.0, cy0), Vector2(3.0, bh)), Color(COL_DANGER, 0.9), true)
		draw_string(f, Vector2(bx, cy0 + ms * 1.25), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, ms, COL_DANGER)
	else:
		var p1 := "α = %s°    " % _fmt(a)
		var p2 := " = %s" % _fmt(tan(deg_to_rad(a)))
		var h := ms * 1.35
		var iw := 0.0
		if _tex_tan != null:
			iw = h * float(_tex_tan.get_width()) / float(maxi(_tex_tan.get_height(), 1))
		var w1 := f.get_string_size(p1, HORIZONTAL_ALIGNMENT_LEFT, -1, ms).x
		var w2 := f.get_string_size(p2, HORIZONTAL_ALIGNMENT_LEFT, -1, ms).x
		var total := w1 + iw + w2
		var x0 := (size.x - total) * 0.5
		draw_rect(Rect2(Vector2(x0 - 14.0, cy0), Vector2(total + 28.0, bh)), Color(0.05, 0.07, 0.12, 0.82), true)
		draw_rect(Rect2(Vector2(x0 - 14.0, cy0), Vector2(3.0, bh)), Color(COL_SUCCESS, 0.9), true)
		draw_string(f, Vector2(x0, cy0 + ms * 1.25), p1, HORIZONTAL_ALIGNMENT_LEFT, -1, ms, COL_TEXT)
		if _tex_tan != null:
			draw_texture_rect(_tex_tan, Rect2(Vector2(x0 + w1, cy0 + (bh - h) * 0.5), Vector2(iw, h)), false, Color.WHITE)
		draw_string(f, Vector2(x0 + w1 + iw, cy0 + ms * 1.25), p2, HORIZONTAL_ALIGNMENT_LEFT, -1, ms, COL_SUCCESS)

func _draw_caption() -> void:
	if _caption == "" or _caption_a <= 0.01:
		return
	var f := UI.font()
	var maxw := size.x - 72.0
	var cs := UI.fs(15)
	var lh := cs * 1.4
	var lines := _wrap(f, cs, maxw, _caption)
	var bh := 14.0 + lines.size() * lh
	var by := size.y - bh - 12.0
	draw_rect(Rect2(24.0, by, size.x - 48.0, bh), Color(0.05, 0.07, 0.12, 0.84 * _caption_a), true)
	draw_rect(Rect2(Vector2(24.0, by), Vector2(3.0, bh)), Color(COL_MARK, _caption_a), true)
	var y := by + 6.0
	for ln in lines:
		draw_string(f, Vector2(40.0, y + cs), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, cs, Color(COL_TEXT, _caption_a))
		y += lh

func _wrap(f: Font, size_px: int, maxw: float, text: String) -> Array:
	var out: Array = []
	var line := ""
	for i in text.length():
		var ch := text.substr(i, 1)
		var test := line + ch
		if line != "" and f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x > maxw:
			out.append(line)
			line = ch
		else:
			line = test
	if line != "":
		out.append(line)
	return out

func _draw_label(pos: Vector2, text: String, col: Color, size_px: int) -> void:
	if text.is_empty() or col.a <= 0.01:
		return
	var px := UI.fs(size_px)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_rect(Rect2(pos + Vector2(-5.0, -px - 2.0), Vector2(w + 10.0, px + 7.0)), Color(0.04, 0.06, 0.11, 0.62), true)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.005:
		return str(int(roundf(v)))
	return "%.2f" % v

# ---------------------------------------------------------------- 交互
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag = true
			_takeover()
			_set_from_x(event.position.x)
			accept_event()
		else:
			if _drag:
				accept_event()
			_drag = false
	elif event is InputEventMouseMotion and _drag:
		_set_from_x(event.position.x)
		accept_event()

func _set_from_x(x: float) -> void:
	var r := _plot()
	var a := clampf((x - r.position.x) / maxf(r.size.x, 1.0), 0.01, 0.99) * A_MAX
	_alpha = a
	angle_changed.emit(a)
