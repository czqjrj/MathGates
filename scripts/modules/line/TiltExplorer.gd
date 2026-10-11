class_name TiltExplorer
extends Control
## 倾斜角探索器：把"倾斜角"讲清楚的专用交互动画。
## 圆形表盘上——金色始边(x 轴正方向)、青色终边(可拖动旋转)、逆时针扇形角、
## 实时 α 与斜率读数；进入时自动播放分段导览，可重播；拖动越界会 wrap 并提示 180°≡0°。

signal angle_changed(deg: float)

const COL_START := Color("#ffd479")
const COL_TERM := Color("#5ee6ff")
const COL_DIM := Color("#8fa3c8")
const COL_TEXT := Color("#eaf2ff")
const COL_DANGER := Color("#fb7185")
const COL_SUCCESS := Color("#34d399")

var _alpha := 0.0
var _demo_t := -0.35
var _demo := true
var _user := false
var _drag := false
var _phases: Array = []
var _emphasis := "range"
var _reveal := 0.0
var _t := 0.0
var _caption_txt := ""
var _caption_alpha := 0.0
var _wrap_flash := 0.0
var _replay_btn: Button
var _task := false
var _target := 0.0
var _tol := 2.0
var _tex_tan: Texture2D
var _tex_alpha90: Texture2D

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
	_tex_tan = _load_tex("line_slope_tan")
	_tex_alpha90 = _load_tex("line_alpha90")
	set_process(true)

func setup(cfg: Dictionary) -> void:
	_emphasis = str(cfg.get("emphasis", "range"))
	_phases = _build_phases(_emphasis)
	_task = false
	replay()

## 任务模式：把直线向上方向转到 target(度)，供玩家动手操作
func setup_task(cfg: Dictionary, target: float, tol: float, task_text: String) -> void:
	_emphasis = str(cfg.get("emphasis", "range"))
	_phases = _build_phases(_emphasis)
	_task = true
	_target = target
	_tol = tol
	_demo = false
	_user = true
	_drag = false
	_alpha = 20.0
	_reveal = 0.0
	_caption_txt = task_text if task_text != "" else "拖动直线，把倾斜角调到目标角度。"
	_caption_alpha = 0.0
	_wrap_flash = 0.0
	queue_redraw()

func is_task_correct() -> bool:
	return _task and absf(_alpha - _target) <= _tol

func replay() -> void:
	_demo_t = -0.35
	_demo = true
	_user = false
	_drag = false
	_alpha = 0.0
	_reveal = 0.0
	_caption_txt = ""
	_caption_alpha = 0.0
	_wrap_flash = 0.0
	queue_redraw()

func _build_phases(emphasis: String) -> Array:
	match emphasis:
		"monotonic":
			return [
				{ "dur": 1.5, "a0": 0.0, "a1": 89.0, "text": "锐角范围 0°<α<90°：k = tanα > 0，且 α 越大 k 越大。" },
				{ "dur": 1.5, "a0": 91.0, "a1": 179.0, "text": "钝角范围 90°<α<180°：k = tanα < 0，且 α 越大 k 越大(负值趋近 0)。" },
				{ "dur": 2.0, "a0": 179.0, "a1": 179.0, "text": "两段各自递增；但钝角 k<0 恒小于锐角 k>0，所以整体并非「α 越大 k 越大」。" },
			]
		"slope":
			return [
				{ "dur": 1.4, "a0": 45.0, "a1": 89.5, "text": "α 从 45° 增大、靠近 90°：k = tanα → +∞。" },
				{ "dur": 1.3, "a0": 89.5, "a1": 90.5, "text": "越过 90°：k 从 +∞ 突变为 −∞(α = 90° 时 k 不存在)。" },
				{ "dur": 1.4, "a0": 90.5, "a1": 135.0, "text": "继续增大：α = 135° 时 k = −1，再往后 k 从 −∞ 增大趋近 0。" },
				{ "dur": 1.9, "a0": 135.0, "a1": 135.0, "text": "所以已知 α 范围求 k 范围，必须在 90° 处分段讨论。" },
			]
		_:
			return [
				{ "dur": 1.9, "a0": 118.0, "a1": 118.0, "text": "直线无限延伸、有两个方向。规定：倾斜角取「直线向上的方向」与 x 轴正方向的夹角。" },
				{ "dur": 1.5, "a0": 118.0, "a1": 58.0, "text": "从 x 轴正方向(始边)逆时针量到直线向上方向(终边)，这个角就是倾斜角 α。" },
				{ "dur": 1.3, "a0": 58.0, "a1": 90.0, "text": "α = 90°：直线竖直，向上方向垂直向上，斜率 k 不存在。" },
				{ "dur": 1.5, "a0": 90.0, "a1": 176.0, "text": "继续逆时针旋转，倾斜角继续增大……" },
				{ "dur": 1.5, "a0": 176.0, "a1": 179.4, "text": "α 无限接近 180°：直线向上方向又回到与 x 轴重合的位置。" },
				{ "dur": 1.8, "a0": 179.4, "a1": 179.4, "text": "180° 与 0° 表示同一条直线，所以取不到 180°；直线水平时规定 α = 0°。" },
				{ "dur": 2.2, "a0": 179.4, "a1": 179.4, "text": "结论：倾斜角 α 的取值范围是 [0°， 180°)。" },
			]

func _process(delta: float) -> void:
	_t += delta
	_reveal = minf(_reveal + delta * 1.8, 1.0)
	_wrap_flash = maxf(_wrap_flash - delta * 1.2, 0.0)
	if _caption_txt != "":
		_caption_alpha = minf(_caption_alpha + delta * 4.0, 1.0)
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

func _set_caption(text: String) -> void:
	if text != _caption_txt:
		_caption_txt = text
		_caption_alpha = 0.0

func _takeover() -> void:
	if _demo:
		_demo = false
		_user = true
		_set_caption("手动探索：拖动终边旋转，观察 α 与 k = tanα 的变化。")

func _set_alpha_from(pos: Vector2) -> void:
	var c := size * 0.5
	var d := pos - c
	if d.length() < 8.0:
		return
	var deg := rad_to_deg(atan2(-d.y, d.x))
	var norm := fposmod(deg, 180.0)
	if absf(norm - _alpha) > 90.0:
		_wrap_flash = 0.9
		_set_caption("越过边界：180° 与 0° 是同一条直线，倾斜角始终落在 [0°， 180°) 内。")
	_alpha = norm
	angle_changed.emit(_alpha)

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	if size.x < 60.0 or size.y < 60.0:
		return
	var c := Vector2(size.x * 0.5, (size.y - 70.0) * 0.5 + 12.0)
	var R := minf(size.x * 0.5 - 46.0, (size.y - 100.0) * 0.5)
	if R < 34.0:
		return
	_draw_backdrop(c, R)
	_draw_guides(c, R)
	_draw_sector(c, R)
	_draw_start_ray(c, R)
	_draw_terminal(c, R)
	_draw_readouts(c, R)
	if _task:
		_draw_target(c, R)
	if _wrap_flash > 0.0:
		draw_arc(c, 30.0 + (1.0 - _wrap_flash) * (R - 30.0), 0.0, TAU, 64, Color(COL_START, _wrap_flash * 0.6), 3.0, true)
	_draw_caption()

func _draw_backdrop(c: Vector2, R: float) -> void:
	draw_circle(c, R + 16.0, Color(0.03, 0.05, 0.09, 0.55))
	draw_arc(c, R + 16.0, 0.0, TAU, 96, Color(UI.COL_ACCENT, 0.18), 1.5, true)
	draw_arc(c, R, 0.0, TAU, 96, Color(1, 1, 1, 0.06), 1.0, true)

func _draw_guides(c: Vector2, R: float) -> void:
	draw_line(Vector2(c.x - R - 12.0, c.y), Vector2(c.x + R + 12.0, c.y), Color(0.5, 0.56, 0.7, 0.5), 1.4)
	draw_string(UI.mono_font(), Vector2(c.x + R + 4.0, c.y + UI.fs(12) + 4.0), "0° / 180°", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(12), COL_DIM)
	draw_dashed_line(Vector2(c.x, c.y - R - 12.0), Vector2(c.x, c.y - 8.0), Color(COL_START, 0.5), 1.4, 7.0)
	draw_dashed_line(Vector2(c.x, c.y + 8.0), Vector2(c.x, c.y + R + 12.0), Color(COL_START, 0.26), 1.4, 7.0)
	_draw_label(Vector2(c.x + 8.0, c.y - R - 4.0), "90°  k 不存在", Color(COL_START, 0.9), 13)

func _draw_sector(c: Vector2, R: float) -> void:
	var rad := deg_to_rad(_alpha)
	var rr := R * 0.999
	var steps := maxi(2, int(_alpha))
	var arcpts := PackedVector2Array()
	for i in steps + 1:
		var th := rad * float(i) / float(steps)
		arcpts.append(c + Vector2(cos(th), -sin(th)) * rr)
	if _alpha > 0.6:
		var poly := PackedVector2Array([c])
		poly.append_array(arcpts)
		draw_colored_polygon(poly, Color(COL_TERM, 0.13 * _reveal))
	if arcpts.size() >= 2:
		draw_polyline(arcpts, Color(COL_START, 0.85 * _reveal), 2.4, true)
		var th2 := rad
		var tip := c + Vector2(cos(th2), -sin(th2)) * rr
		var dir := Vector2(-sin(th2), -cos(th2)).normalized()
		_arrowhead(tip, dir, Color(COL_START, 0.95 * _reveal), 11.0)

func _draw_start_ray(c: Vector2, R: float) -> void:
	var end := c + Vector2(R, 0.0) * _reveal
	draw_line(c, end, Color(COL_START, 0.95), 4.0)
	_arrowhead(end, Vector2(1, 0), Color(COL_START, 0.95), 12.0)
	_draw_label(Vector2(c.x + R * 0.52, c.y + 22.0), "始边(x 轴正方向)", Color(COL_START, 0.9), 14)

func _draw_terminal(c: Vector2, R: float) -> void:
	var rad := deg_to_rad(_alpha)
	var dir := Vector2(cos(rad), -sin(rad))
	var end := c + dir * (R * _reveal)
	draw_line(c - dir * R * 0.99, c + dir * R * 0.99, Color(COL_TERM, 0.16 * _reveal), 2.0)
	draw_line(c, end, Color(COL_TERM, 0.98), 4.0)
	_arrowhead(end, dir, Color(COL_TERM, 0.98), 12.0)
	if _reveal > 0.98:
		var pulse := 1.0 + 0.25 * sin(_t * 3.0)
		draw_circle(end, 9.5 * pulse, Color(COL_TERM, 0.18))
	draw_circle(end, 4.6, Color(1, 1, 1, 0.95))
	if _alpha > 8.0 and _alpha < 172.0:
		var down := c - dir * (R * _reveal)
		draw_circle(down, 3.4, Color(COL_DIM, 0.55 * _reveal))
		_draw_label(down + Vector2(8.0, 14.0), "向下方向", Color(COL_DIM, 0.7 * _reveal), 12)
	var lp := end + dir * 18.0 + Vector2(-34.0, 0.0)
	_draw_label(lp, "直线向上方向", Color(COL_TERM, 0.95), 14)

func _draw_readouts(c: Vector2, R: float) -> void:
	var mid := deg_to_rad(_alpha * 0.5)
	var ap := c + Vector2(cos(mid), -sin(mid)) * (R * 0.46)
	_draw_label(ap - Vector2(52.0, 0.0), "α = %s°" % _fmt(_alpha), COL_TEXT, 22)
	var near90 := absf(_alpha - 90.0) < 0.6
	var tex := _tex_alpha90 if near90 else _tex_tan
	var h := 30.0 if near90 else 26.0
	var tw := 0.0
	if tex != null:
		tw = h * float(tex.get_width()) / float(maxi(tex.get_height(), 1))
	var val := "  →  k 不存在" if near90 else ("  = %s" % _fmt(tan(deg_to_rad(_alpha))))
	var kcol := COL_DANGER if near90 else COL_SUCCESS
	var kf := UI.font()
	var ks := UI.fs(17)
	var vw := kf.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, ks).x
	var x0 := c.x - (tw + vw) * 0.5
	var yb := c.y + R * 0.72
	if tex != null:
		draw_texture_rect(tex, Rect2(Vector2(x0, yb - h * 0.5), Vector2(tw, h)), false, Color.WHITE)
	draw_string(kf, Vector2(x0 + tw, yb + ks * 0.35), val, HORIZONTAL_ALIGNMENT_LEFT, -1, ks, kcol)

func _load_tex(n: String) -> Texture2D:
	var p := "res://art/line/formulas/%s.png" % n
	return load(p) if ResourceLoader.exists(p) else null

func _draw_target(c: Vector2, R: float) -> void:
	var rad := deg_to_rad(_target)
	var dir := Vector2(cos(rad), -sin(rad))
	var hit := absf(_alpha - _target) <= _tol
	var col := COL_SUCCESS if hit else Color("#c8a2ff")
	draw_dashed_line(c, c + dir * (R * 0.99), col, 2.4, 9.0)
	_arrowhead(c + dir * (R * 0.99), dir, col, 12.0)
	_draw_label(c + dir * (R * 0.86) + Vector2(8.0, -8.0), "目标 α = %s°" % _fmt(_target), col, 14)
	if hit:
		_draw_label(Vector2(c.x - 74.0, c.y - R * 0.78), "✓ 已对准目标", COL_SUCCESS, 16)

func _draw_caption() -> void:
	if _caption_txt == "" or _caption_alpha <= 0.01:
		return
	var f := UI.font()
	var cs := UI.fs(15)
	var lh := cs * 1.4
	var lines := _wrap(f, cs, size.x - 72.0, _caption_txt)
	var bh := 14.0 + lines.size() * lh
	var by := size.y - bh - 12.0
	draw_rect(Rect2(24.0, by, size.x - 48.0, bh), Color(0.05, 0.07, 0.12, 0.84 * _caption_alpha), true)
	draw_rect(Rect2(Vector2(24.0, by), Vector2(3.0, bh)), Color(COL_START, _caption_alpha), true)
	var y := by + 6.0
	for ln in lines:
		draw_string(f, Vector2(40.0, y + cs), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, cs, Color(COL_TEXT, _caption_alpha))
		y += lh

func _arrowhead(tip: Vector2, dir: Vector2, col: Color, s: float) -> void:
	var d := -dir.normalized()
	var p := Vector2(-d.y, d.x)
	draw_line(tip, tip + d * s + p * s * 0.5, col, 2.4)
	draw_line(tip, tip + d * s - p * s * 0.5, col, 2.4)

func _draw_label(pos: Vector2, text: String, col: Color, s: int) -> void:
	if text.is_empty() or col.a <= 0.01:
		return
	var px := UI.fs(s)
	var f := UI.font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_rect(Rect2(pos + Vector2(-6.0, -px - 2.0), Vector2(w + 12.0, px + 8.0)), Color(0.04, 0.06, 0.11, 0.6 * col.a), true)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

func _wrap(f: Font, s: int, maxw: float, text: String) -> Array:
	var out: Array = []
	var line := ""
	for i in text.length():
		var ch := text.substr(i, 1)
		if ch == "\n":
			out.append(line)
			line = ""
			continue
		var test := line + ch
		if line != "" and f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > maxw:
			out.append(line)
			line = ch
		else:
			line = test
	if line != "":
		out.append(line)
	return out

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
			_set_alpha_from(event.position)
			accept_event()
		else:
			_drag = false
			accept_event()
	elif event is InputEventMouseMotion and _drag:
		_set_alpha_from(event.position)
		accept_event()
