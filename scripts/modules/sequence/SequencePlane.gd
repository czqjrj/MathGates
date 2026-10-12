extends Control
class_name SequencePlane
## 数列「递推 → 通项」实验探究画布。
## 由 data/recurrence_levels.json 里每题 scene 字典驱动，支持：
##   图形(点列/折线/柱状/蛛网) + 公式图像(PNG) + 拖动参数(探针) + 缓动动画。
## kind: add / mul / construct / reciprocal / log / sn

signal param_changed(value: float)

enum CursorStyle { DOT, JUMP }

const COL_GRID := Palette.GRID
const COL_GRID_MAJOR := Palette.GRID_MAJOR
const COL_AXIS := Palette.AXIS
const COL_TEXT := Palette.TEXT
const COL_DIM := Palette.DIM
const COL_ACCENT := Palette.ACCENT
const COL_GOLD := Palette.GOLD
const COL_SUCCESS := Palette.SUCCESS
const COL_PINK := Color(1.0, 0.60, 0.765, 1.0)

var kind := "add"
var mode := ""                     # "" / "slider"
var param := 0.0
var param_target := 0.0
var param_range := Vector2(-1.0, 3.0)
var param_tol := 0.12
var param_step := 0.0
var param_label := "d"

var domain := Vector2(0.0, 9.0)
var range_y := Vector2(-2.0, 12.0)
var pad := 44.0

var _s: Dictionary = {}
var _anim := 0.0
var _slider_drag := false

var _n := 8
var _a1 := 1.0
var _p := 0.5
var _B: Array = []
var _R: Array = []
var _coef := 0.0
var _fkind := "const"               # add 的差函数：const(d) / linear(f(k)=c·k) / list(b[])
var _pk := "coef"                    # 滑块参数含义：coef(系数) / n(项数)
var _has_x := false
var _has_y := false

var _a: Array = []                 # 主序列(或变换后的序列)
var _b: Array = []                 # 辅助(相邻差 / a_n)
var _ratios: Array = []            # mul 专用：每步比值 f(j) = Vector2(分子, 分母)
var _imgs: Array = []              # {name, fx, fy, w, tint} 公式叠层

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

# ---------------------------------------------------------------- 配置
func set_scene(s: Dictionary) -> void:
	_s = s
	kind = str(s.get("seq", "add"))
	_n = int(s.get("n", 8))
	_a1 = float(s.get("a1", 1.0))
	_p = float(s.get("p", 0.5))
	_B = s.get("b", [])
	_R = s.get("r", [])
	_coef = float(s.get("coef", 0.0))
	_pk = str(s.get("param_kind", "coef"))
	_fkind = "const"
	if _B is Array and _B.size() > 0:
		_fkind = "list"
	elif s.has("coef"):
		_fkind = "linear"
	_has_x = s.has("x")
	_has_y = s.has("y")
	mode = ""
	param = _default_param()
	param_range = Vector2(param - 3.0, param + 3.0)
	if s.has("slider"):
		_apply_slider(s["slider"])
	_recompute()
	if _has_x:
		var xr: Array = s["x"]
		domain = Vector2(float(xr[0]), float(xr[1]))
	if _has_y:
		var yr: Array = s["y"]
		range_y = Vector2(float(yr[0]), float(yr[1]))
	if not _has_x or not _has_y:
		_auto_range()
	_sync_images()
	queue_redraw()

func _apply_slider(cfg: Dictionary) -> void:
	mode = "slider"
	param_label = str(cfg.get("label", "k"))
	var rng: Array = cfg.get("range", [-1.0, 3.0])
	param_range = Vector2(float(rng[0]), float(rng[1]))
	param = float(cfg.get("value", param_range.x))
	param_target = float(cfg.get("answer", param))
	param_tol = float(cfg.get("tol", 0.12))
	param_step = float(cfg.get("step", 0.0))

func _default_param() -> float:
	match kind:
		"add":
			if _pk == "n":
				return float(_s.get("n", 5))
			if _fkind == "linear":
				return _coef
			return float(_s.get("d", 1.0))
		"sn":
			return float(_s.get("d", 1.0))
		"mul", "log", "construct":
			if kind == "mul" and _pk == "n":
				return float(_s.get("n", 4))
			return float(_s.get("q", 2.0))
		"reciprocal":
			return float(_s.get("c", 0.5))
	return 1.0

func is_param_correct() -> bool:
	if mode != "slider":
		return true
	return absf(param - param_target) <= param_tol

# ---------------------------------------------------------------- 数值
func _recompute() -> void:
	_a = []
	_b = []
	match kind:
		"add":
			var nn := _n
			var coef := _coef
			if _pk == "n":
				nn = clampi(int(round(param)), 2, 8)
			else:
				coef = param
			var m := maxi(nn - 1, 1)
			var diffs: Array = []
			if _fkind == "list":
				diffs = _B.duplicate()
			elif _fkind == "linear":
				for k in m:
					diffs.append(coef * float(k + 1))
			else:
				for k in m:
					diffs.append(coef)
			_a = [_a1]
			for d in diffs:
				_a.append(float(_a[_a.size() - 1]) + float(d))
			_b = diffs.duplicate()
		"mul":
			_ratios = []
			var nn := _n
			if _pk == "n":
				nn = clampi(int(round(param)), 2, 8)
			var rk := str(_s.get("ratio_kind", ""))
			if _R is Array and _R.size() > 0:
				for j in range(1, nn):
					var v := float(_R[(j - 1) % _R.size()])
					_ratios.append(Vector2(v, 1.0))
			elif rk == "telescoping":
				for j in range(1, nn):
					_ratios.append(Vector2(float(j + 1), float(j)))
			elif rk == "pow2":
				for j in range(1, nn):
					_ratios.append(Vector2(pow(2.0, float(j)), 1.0))
			elif _fkind == "list" and _B.size() > 0:
				for j in range(1, nn):
					var v := float(_B[(j - 1) % _B.size()])
					_ratios.append(Vector2(v, 1.0))
			else:
				var q := maxf(param if _pk != "n" else float(_s.get("q", 2.0)), 0.05)
				for j in range(1, nn):
					_ratios.append(Vector2(q, 1.0))
			_a = [_a1]
			_b = []
			for r in _ratios:
				var v := float(r.x) / maxf(float(r.y), 0.0001)
				_a.append(float(_a[_a.size() - 1]) * v)
				_b.append(v)
		"construct":
			var x := _a1
			for i in _n:
				_a.append(x)
				x = _p * x + param
		"reciprocal":
			var inv := 1.0 / maxf(_a1, 0.001)
			for i in _n:
				_a.append(inv)
				inv += param
		"log":
			var q := maxf(param, 0.05)
			var l1 := log(maxf(_a1, 0.0001)) / log(10.0)
			var lq := log(q) / log(10.0)
			for i in _n:
				_a.append(l1 + float(i) * lq)
		"sn":
			for i in _n:
				var nn := float(i + 1)
				_a.append(nn * _a1 + param * nn * (nn - 1.0) * 0.5)
			for i in _n:
				_b.append(float(_a[i]) - (float(_a[i - 1]) if i > 0 else 0.0))

func _auto_range() -> void:
	var lo := INF
	var hi := -INF
	for v in _a:
		lo = minf(lo, float(v))
		hi = maxf(hi, float(v))
	for v in _b:
		lo = minf(lo, float(v))
		hi = maxf(hi, float(v))
	if not is_finite(lo) or not is_finite(hi):
		lo = 0.0
		hi = 1.0
	if kind == "construct":
		var xstar := param / (1.0 - _p) if absf(1.0 - _p) > 0.0001 else 0.0
		lo = minf(lo, xstar)
		hi = maxf(hi, xstar)
		var c := (lo + hi) * 0.5
		var half := maxf((hi - lo) * 0.5, 1.5)
		domain = Vector2(c - half, c + half)
		range_y = domain
		return
	domain = Vector2(0.0, float(maxi(_a.size(), 1)) + 0.6)
	range_y = Vector2(floor(lo - 1.0), ceil(hi + 1.0))

func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.0005:
		return str(int(roundf(v)))
	return "%.2f" % v

# ---------------------------------------------------------------- 坐标系
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
	return Vector2(o.x + p.x * s, o.y - p.y * s)

# ---------------------------------------------------------------- 交互
func _gui_input(event: InputEvent) -> void:
	if mode != "slider":
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_slider_drag = event.pressed
			if event.pressed:
				_set_param_from_x(event.position.x)
	elif event is InputEventScreenTouch:
		_slider_drag = event.pressed
		if event.pressed:
			_set_param_from_x(event.position.x)
	elif event is InputEventScreenDrag:
		_set_param_from_x(event.position.x)
	elif event is InputEventMouseMotion and _slider_drag:
		_set_param_from_x(event.position.x)

func _set_param_from_x(px: float) -> void:
	var r := _track_rect()
	var t := clampf((px - r.position.x) / maxf(r.size.x, 1.0), 0.0, 1.0)
	var v := lerpf(param_range.x, param_range.y, t)
	if param_step > 0.0:
		v = roundf(v / param_step) * param_step
	v = clampf(v, param_range.x, param_range.y)
	if absf(v - param) < 0.0001:
		return
	param = v
	_recompute()
	_anim = 0.0
	if not _has_x or not _has_y:
		_auto_range()
	param_changed.emit(param)
	queue_redraw()

func _track_rect() -> Rect2:
	var y := size.y - 34.0
	return Rect2(Vector2(pad, y - 4.0), Vector2(maxf(size.x - pad * 2.0, 10.0), 8.0))

# ---------------------------------------------------------------- 动画
func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _reveal() -> float:
	var count := maxf(float(_a.size()), 1.0)
	var period := 0.55 * count + 0.9
	return clampf(_anim / period, 0.0, 1.0)

# ---------------------------------------------------------------- LaTeX 公式图
const FORM_DIR := "res://art/sequence/formulas/"
const LINE_FORM_DIR := "res://art/line/formulas/"
const FORM_SCALE := 0.60

var _tex_cache: Dictionary = {}

func _tex(name: String) -> Texture2D:
	if _tex_cache.has(name):
		return _tex_cache[name]
	var t: Texture2D = null
	if not name.is_empty():
		for d in [FORM_DIR, LINE_FORM_DIR]:
			var p: String = str(d) + name + ".png"
			if ResourceLoader.exists(p):
				t = load(p) as Texture2D
				if t != null:
					break
	_tex_cache[name] = t
	return t

func _tex_size(name: String, sc: float) -> Vector2:
	var t := _tex(name)
	return t.get_size() * sc if t != null else Vector2.ZERO

func _draw_tex(name: String, center: Vector2, sc: float, tint: Color) -> Vector2:
	var t := _tex(name)
	if t == null:
		return Vector2.ZERO
	var s := t.get_size() * sc
	draw_texture_rect(t, Rect2(center - s * 0.5, s), false, tint)
	return s

## 数字 → LaTeX 图片名（0..20 内用预渲染，其余返回空串走文字）
func _num_name(v: float) -> String:
	var iv := int(roundf(v))
	if absf(v - float(iv)) < 0.001 and iv >= 0 and iv <= 20:
		return "n%d" % iv
	return ""

# ---------------------------------------------------------------- 图像叠层
func _sync_images() -> void:
	_imgs.clear()
	for cfg in _s.get("imgs", []):
		var name := str(cfg.get("f", ""))
		if name.is_empty():
			continue
		_imgs.append({
			"name": name,
			"fx": float(cfg.get("x", 0.5)),
			"fy": float(cfg.get("y", 0.5)),
			"w": float(cfg.get("w", 0.5)),
			"tint": Color(str(cfg.get("col", "#eaf2ff"))),
		})

func _draw_overlay_imgs(alpha: float = 1.0) -> void:
	for it in _imgs:
		var t := _tex(str(it["name"]))
		if t == null or t.get_width() <= 0.0:
			continue
		var w := float(it["w"]) * size.x
		var s := Vector2(w, w * t.get_height() / t.get_width())
		var c := Vector2(float(it["fx"]) * size.x, float(it["fy"]) * size.y)
		draw_texture_rect(t, Rect2(c - s * 0.5, s), false, Color(it["tint"], alpha))

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	_draw_grid()
	_draw_axes()
	match kind:
		"add":
			_draw_add()
		"mul":
			_draw_mul()
		"reciprocal", "log":
			_draw_line_series()
		"construct":
			_draw_cobweb()
		"sn":
			_draw_stack()
	_draw_overlay_imgs(_ease(clampf(_anim / 0.6, 0.0, 1.0)))
	_draw_caption()

func _draw_grid() -> void:
	var gx := int(ceil(domain.x))
	while gx <= int(floor(domain.y)):
		var sx := _to_screen(Vector2(float(gx), 0.0)).x
		if sx >= pad - 0.5 and sx <= size.x - pad + 0.5:
			draw_line(Vector2(sx, pad * 0.5), Vector2(sx, size.y - pad * 0.5), COL_GRID_MAJOR if gx == 0 else COL_GRID, 1.0)
		gx += 1
	var gy := int(ceil(range_y.x))
	while gy <= int(floor(range_y.y)):
		var sy := _to_screen(Vector2(0.0, float(gy))).y
		if sy >= pad * 0.5 and sy <= size.y - pad * 0.5:
			draw_line(Vector2(pad * 0.5, sy), Vector2(size.x - pad * 0.5, sy), COL_GRID_MAJOR if gy == 0 else COL_GRID, 1.0)
		gy += 1

func _draw_axes() -> void:
	var ax := clampf(_to_screen(Vector2(0.0, 0.0)).x, pad * 0.5, size.x - pad * 0.5)
	draw_line(Vector2(ax, pad * 0.4), Vector2(ax, size.y - pad * 0.4), COL_AXIS, 1.6)
	var ay := clampf(_to_screen(Vector2(0.0, 0.0)).y, pad * 0.5, size.y - pad * 0.5)
	draw_line(Vector2(pad * 0.4, ay), Vector2(size.x - pad * 0.4, ay), COL_AXIS, 1.6)

func _draw_caption() -> void:
	var cap := str(_s.get("caption", ""))
	if not cap.is_empty():
		draw_string(UI.font(), Vector2(pad, 30.0), cap, HORIZONTAL_ALIGNMENT_LEFT, size.x - pad * 2.0, UI.fs(18), Color(COL_TEXT, 0.9))
	if mode == "slider":
		var col := COL_SUCCESS if is_param_correct() else COL_GOLD
		draw_string(UI.mono_font(), Vector2(size.x - 220.0, 30.0), "%s = %s" % [param_label, _fmt(param)], HORIZONTAL_ALIGNMENT_RIGHT, 200.0, UI.fs(20), col)
		_draw_slider()

func _draw_slider() -> void:
	var r := _track_rect()
	draw_rect(r, Color(1, 1, 1, 0.10), true)
	var t := clampf((param - param_range.x) / maxf(param_range.y - param_range.x, 0.0001), 0.0, 1.0)
	var hx := r.position.x + t * r.size.x
	draw_rect(Rect2(Vector2(r.position.x, r.position.y), Vector2(hx - r.position.x, r.size.y)), Color(COL_ACCENT, 0.6), true)
	draw_circle(Vector2(hx, r.position.y + r.size.y * 0.5), 11.0, COL_ACCENT)
	draw_circle(Vector2(hx, r.position.y + r.size.y * 0.5), 11.0, Color(COL_ACCENT, 0.25) * 0.0 + Color(1, 1, 1, 0.0))
	draw_string(UI.mono_font(), Vector2(r.position.x, r.position.y - 8.0), _fmt(param_range.x), HORIZONTAL_ALIGNMENT_LEFT, 60.0, UI.fs(11), COL_DIM)
	draw_string(UI.mono_font(), Vector2(r.end.x - 60.0, r.position.y - 8.0), _fmt(param_range.y), HORIZONTAL_ALIGNMENT_RIGHT, 60.0, UI.fs(11), COL_DIM)

func _dot(p: Vector2, col: Color, r: float) -> void:
	var sp := _to_screen(p)
	draw_circle(sp, r + 3.0, Color(col, 0.18))
	draw_circle(sp, r, col)

## ---------------------------------------------------------------- 横式推导链
## 单元格：{t:"frac", n, d} / {t:"sum", a, op, b} / {t:"atom", n} / {t:"num", v}
func _cell_w(c: Dictionary, sc: float) -> float:
	match str(c.get("t", "")):
		"frac":
			return maxf(_tex_size(str(c["n"]), sc).x, _tex_size(str(c["d"]), sc).x)
		"sum":
			return _tex_size(str(c["a"]), sc).x + _tex_size(str(c["op"]), sc).x + _tex_size(str(c["b"]), sc).x
		"atom":
			return _tex_size(str(c["n"]), sc).x
		"num":
			var nm := _num_name(float(c["v"]))
			if nm != "":
				return _tex_size(nm, sc).x
			return UI.mono_font().get_string_size(_fmt(float(c["v"])), HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(sc * 44.0)).x
	return 0.0

## 在 (cx, axis_y) 处画一个单元格；返回锚点字典（num/den/a/b）。
func _draw_cell(c: Dictionary, cx: float, axis_y: float, sc: float, alpha: float, tn: Color, td: Color) -> Dictionary:
	var g: Dictionary = {}
	var tt := str(c.get("t", ""))
	if tt == "frac":
		var ns := _tex_size(str(c["n"]), sc)
		var ds := _tex_size(str(c["d"]), sc)
		var hw := maxf(ns.x, ds.x) * 0.5 + 4.0
		var ny := axis_y - 2.5 - ns.y * 0.5
		var dy := axis_y + 2.5 + ds.y * 0.5
		_draw_tex(str(c["n"]), Vector2(cx, ny), sc, Color(tn, alpha))
		draw_line(Vector2(cx - hw, axis_y), Vector2(cx + hw, axis_y), Color(COL_TEXT, alpha * 0.9), 1.8, true)
		_draw_tex(str(c["d"]), Vector2(cx, dy), sc, Color(td, alpha))
		g = {"num": Vector2(cx, ny), "den": Vector2(cx, dy)}
	elif tt == "sum":
		var wa := _tex_size(str(c["a"]), sc).x
		var wo := _tex_size(str(c["op"]), sc).x
		var wb := _tex_size(str(c["b"]), sc).x
		var bx := cx - (wa + wo + wb) * 0.5
		_draw_tex(str(c["a"]), Vector2(bx + wa * 0.5, axis_y), sc, Color(tn, alpha))
		_draw_tex(str(c["op"]), Vector2(bx + wa + wo * 0.5, axis_y), sc, Color(COL_TEXT, alpha))
		_draw_tex(str(c["b"]), Vector2(bx + wa + wo + wb * 0.5, axis_y), sc, Color(td, alpha))
		g = {"a": Vector2(bx + wa * 0.5, axis_y), "b": Vector2(bx + wa + wo + wb * 0.5, axis_y)}
	elif tt == "atom":
		_draw_tex(str(c["n"]), Vector2(cx, axis_y), sc, Color(tn, alpha))
		g = {"a": Vector2(cx, axis_y)}
	elif tt == "num":
		var nm := _num_name(float(c["v"]))
		if nm != "":
			_draw_tex(nm, Vector2(cx, axis_y), sc, Color(tn, alpha))
		else:
			draw_string(UI.mono_font(), Vector2(cx - sc * 22.0, axis_y + sc * 22.0), _fmt(float(c["v"])), HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(sc * 44.0), Color(tn, alpha))
		g = {"a": Vector2(cx, axis_y)}
	return g

func _chain_measure(cells: Array, rhs: Array, sc: float, sep: float, eq_gap: float) -> float:
	var lw := 0.0
	for c in cells:
		lw += _cell_w(c, sc)
	lw += sep * float(maxi(cells.size() - 1, 0))
	var rw := 0.0
	for c in rhs:
		rw += _cell_w(c, sc)
	rw += sep * float(maxi(rhs.size() - 1, 0))
	return lw + rw + eq_gap * 2.0 + _tex_size("op_eq", sc).x

## 按目标像素宽缩放绘制（横式公式更自然）
func _draw_tex_w(name: String, center: Vector2, w: float, tint: Color) -> void:
	var t := _tex(name)
	if t == null or t.get_width() <= 0.0:
		return
	var s := Vector2(w, w * t.get_height() / t.get_width())
	draw_texture_rect(t, Rect2(center - s * 0.5, s), false, tint)

func _ease(v: float) -> float:
	v = clampf(v, 0.0, 1.0)
	return v * v * (3.0 - 2.0 * v)

## 相消进度：第 k 对相消项（0..1）
func _cancel_amt(t: float, k: int, t0: float) -> float:
	return clampf((t - (t0 + 0.26 * float(k - 1))) / 0.5, 0.0, 1.0)

## 乘号分隔点；t_appear..c0 期间高亮放大
func _draw_sep(x: float, axis_y: float, sc: float, sep: float, t: float, t_appear: float, c0: float) -> void:
	var emph := clampf((t - t_appear) / 0.3, 0.0, 1.0) * (1.0 - clampf((t - c0) / 0.3, 0.0, 1.0))
	_draw_tex("op_cdot", Vector2(x + sep * 0.5, axis_y), sc * (1.0 + 0.7 * emph), Color(COL_GOLD if emph > 0.35 else COL_TEXT, 0.9))

## 相消连线 + 火花
func _draw_cancel_pair(a: Vector2, b: Vector2, p: float) -> void:
	if p <= 0.0:
		return
	var c := clampf(p / 0.45, 0.0, 1.0)
	draw_line(a, b, Color(COL_PINK, 0.95 * c), 1.8, true)
	draw_line(Vector2(a.x - 4.0, a.y), Vector2(a.x + 4.0, a.y), Color(COL_PINK, c), 2.6, true)
	draw_line(Vector2(b.x - 4.0, b.y), Vector2(b.x + 4.0, b.y), Color(COL_PINK, c), 2.6, true)
	var mid := (a + b) * 0.5
	var sp := clampf((p - 0.15) / 0.7, 0.0, 1.0)
	if sp > 0.0:
		draw_arc(mid, 6.0 + 26.0 * sp, 0.0, TAU, 26, Color(1.0, 0.78, 0.9, (1.0 - sp) * 0.85), 2.0, true)
		for s in 8:
			var ang := TAU * float(s) / 8.0
			draw_line(mid, mid + Vector2(cos(ang), sin(ang)) * (5.0 + 18.0 * sp), Color(1.0, 0.82, 0.92, (1.0 - sp) * 0.8), 1.6, true)

## 累加法专用（横式）：(a₂−a₁)+(a₃−a₂)+⋯+(aₙ−aₙ₋₁) = f(1)+f(2)+⋯+f(n−1)
## 演示「各式相加后中间项两两相消」，只剩 aₙ−a₁，再收成 aₙ = a₁ + Σ f(k)。
func _draw_add() -> void:
	var rows := _a.size() - 1
	if rows < 1:
		return
	var big := UI.font()
	var lhs: Array = []
	for j in range(1, rows + 1):
		lhs.append({"t": "sum", "a": "a%d" % (j + 1), "op": "op_minus", "b": "a%d" % j})
	var rhs: Array = []
	for j in range(1, rows + 1):
		rhs.append({"t": "num", "v": float(_b[j - 1]) if j - 1 < _b.size() else 0.0})
	var per := 0.14
	var t_appear := per * float(lhs.size() + rhs.size()) + 0.2
	var c0 := t_appear + 0.5
	var res_start := c0 + 0.26 * float(rows - 1) + 0.85
	var cyc := res_start + 3.0
	var t := fmod(_anim, cyc)
	var sc := FORM_SCALE
	var sep := 14.0
	var eq_gap := 22.0
	var total := _chain_measure(lhs, rhs, sc, sep, eq_gap)
	var avail := size.x - pad * 2.0
	if total > avail and total > 0.0:
		sc *= avail / total
		total = _chain_measure(lhs, rhs, sc, sep, eq_gap)
	var axis_y := size.y * 0.42
	var x := maxf(pad, (size.x - total) * 0.5)
	var lgeom: Array = []
	for i in lhs.size():
		var cw := _cell_w(lhs[i], sc)
		var e := _ease(clampf((t - per * float(i)) / 0.45, 0.0, 1.0))
		var ca := _cancel_amt(t, i, c0) if i >= 1 else 0.0
		var cb := _cancel_amt(t, i + 1, c0) if i <= rows - 2 else 0.0
		lgeom.append(_draw_cell(lhs[i], x + cw * 0.5, axis_y, sc, 0.12 + 0.88 * e, Color(COL_TEXT, 1.0 - 0.9 * ca), Color(COL_TEXT, 1.0 - 0.9 * cb)))
		x += cw
		if i < lhs.size() - 1:
			_draw_sep(x, axis_y, sc, sep, t, t_appear, c0)
			x += sep
	var eqw := _tex_size("op_eq", sc).x
	x += eq_gap
	_draw_tex("op_eq", Vector2(x + eqw * 0.5, axis_y), sc, Color(COL_TEXT, 0.85))
	x += eqw + eq_gap
	for i in rhs.size():
		var cw := _cell_w(rhs[i], sc)
		var e := _ease(clampf((t - per * float(lhs.size() + i)) / 0.45, 0.0, 1.0))
		_draw_cell(rhs[i], x + cw * 0.5, axis_y, sc, 0.12 + 0.88 * e, COL_GOLD, COL_GOLD)
		x += cw
		if i < rhs.size() - 1:
			_draw_sep(x, axis_y, sc, sep, t, t_appear, c0)
			x += sep
	for k in range(1, rows):
		_draw_cancel_pair(lgeom[k - 1]["a"], lgeom[k]["b"], _cancel_amt(t, k, c0))
	if t > c0:
		var pulse := 0.5 + 0.5 * sin(_anim * 5.0)
		var gl := clampf((t - c0) / 0.4, 0.0, 1.0)
		draw_circle(Vector2(lgeom[0]["b"]), 15.0 + 4.0 * pulse, Color(COL_GOLD, (0.16 + 0.18 * pulse) * gl))
		draw_circle(Vector2(lgeom[rows - 1]["a"]), 15.0 + 4.0 * pulse, Color(COL_GOLD, (0.16 + 0.18 * pulse) * gl))
	var ban := clampf((t - t_appear) / 0.4, 0.0, 1.0) * (1.0 - clampf((t - res_start) / 0.4, 0.0, 1.0))
	if ban > 0.0:
		draw_string(big, Vector2(pad, 66.0), "把以上各式相加 →", HORIZONTAL_ALIGNMENT_LEFT, -1.0, UI.fs(19), Color(COL_ACCENT, ban))
	if t > res_start:
		var re := _ease(clampf((t - res_start) / 0.55, 0.0, 1.0))
		var yr := size.y * 0.80
		var wb := minf(size.x * 0.58, 470.0)
		_draw_tex_w("add_r1", Vector2(size.x * 0.5, yr - 26.0), wb * re + 0.01, Color(COL_SUCCESS, re))
		_draw_tex_w("add_r2", Vector2(size.x * 0.5, yr + 30.0), wb * 0.96 * re + 0.01, Color(COL_GOLD, re))

## 累乘法专用（横式）：(a₂/a₁)·(a₃/a₂)·⋯·(aₙ/aₙ₋₁) = f(1)·f(2)·⋯·f(n−1)
## 演示「左右分别相乘后中间约掉」，只剩 aₙ/a₁，再收成 aₙ = a₁·∏ f(k)。
func _draw_mul() -> void:
	var rows := _ratios.size()
	if rows < 1:
		return
	var big := UI.font()
	var lhs: Array = []
	for j in range(1, rows + 1):
		lhs.append({"t": "frac", "n": "a%d" % (j + 1), "d": "a%d" % j})
	var rk := str(_s.get("ratio_kind", ""))
	var rhs: Array = []
	for j in range(1, rows + 1):
		var r: Vector2 = _ratios[j - 1]
		if rk == "telescoping":
			rhs.append({"t": "frac", "n": "n%d" % (j + 1), "d": "n%d" % j})
		elif rk == "pow2":
			rhs.append({"t": "atom", "n": "pw%d" % j})
		else:
			rhs.append({"t": "num", "v": r.x / maxf(r.y, 0.0001)})
	var per := 0.14
	var t_appear := per * float(lhs.size() + rhs.size()) + 0.2
	var c0 := t_appear + 0.5
	var res_start := c0 + 0.26 * float(rows - 1) + 0.85
	var cyc := res_start + 3.0
	var t := fmod(_anim, cyc)
	var sc := FORM_SCALE
	var sep := 14.0
	var eq_gap := 22.0
	var total := _chain_measure(lhs, rhs, sc, sep, eq_gap)
	var avail := size.x - pad * 2.0
	if total > avail and total > 0.0:
		sc *= avail / total
		total = _chain_measure(lhs, rhs, sc, sep, eq_gap)
	var axis_y := size.y * 0.42
	var x := maxf(pad, (size.x - total) * 0.5)
	var lgeom: Array = []
	for i in lhs.size():
		var cw := _cell_w(lhs[i], sc)
		var e := _ease(clampf((t - per * float(i)) / 0.45, 0.0, 1.0))
		var cn := _cancel_amt(t, i + 1, c0) if i <= rows - 2 else 0.0
		var cd := _cancel_amt(t, i, c0) if i >= 1 else 0.0
		lgeom.append(_draw_cell(lhs[i], x + cw * 0.5, axis_y, sc, 0.12 + 0.88 * e, Color(COL_TEXT, 1.0 - 0.9 * cn), Color(COL_TEXT, 1.0 - 0.9 * cd)))
		x += cw
		if i < lhs.size() - 1:
			_draw_sep(x, axis_y, sc, sep, t, t_appear, c0)
			x += sep
	var eqw := _tex_size("op_eq", sc).x
	x += eq_gap
	_draw_tex("op_eq", Vector2(x + eqw * 0.5, axis_y), sc, Color(COL_TEXT, 0.85))
	x += eqw + eq_gap
	var rgeom: Array = []
	for i in rhs.size():
		var cw := _cell_w(rhs[i], sc)
		var e := _ease(clampf((t - per * float(lhs.size() + i)) / 0.45, 0.0, 1.0))
		rgeom.append(_draw_cell(rhs[i], x + cw * 0.5, axis_y, sc, 0.12 + 0.88 * e, COL_GOLD, COL_GOLD))
		x += cw
		if i < rhs.size() - 1:
			_draw_sep(x, axis_y, sc, sep, t, t_appear, c0)
			x += sep
	for k in range(1, rows):
		_draw_cancel_pair(lgeom[k - 1]["num"], lgeom[k]["den"], _cancel_amt(t, k, c0))
	if rk == "telescoping":
		for k in range(1, rows):
			_draw_cancel_pair(rgeom[k - 1]["num"], rgeom[k]["den"], _cancel_amt(t, k, c0))
	if t > c0:
		var pulse := 0.5 + 0.5 * sin(_anim * 5.0)
		var gl := clampf((t - c0) / 0.4, 0.0, 1.0)
		draw_circle(Vector2(lgeom[0]["den"]), 15.0 + 4.0 * pulse, Color(COL_GOLD, (0.16 + 0.18 * pulse) * gl))
		draw_circle(Vector2(lgeom[rows - 1]["num"]), 15.0 + 4.0 * pulse, Color(COL_GOLD, (0.16 + 0.18 * pulse) * gl))
	var ban := clampf((t - t_appear) / 0.4, 0.0, 1.0) * (1.0 - clampf((t - c0) / 0.3, 0.0, 1.0))
	if ban > 0.0:
		draw_string(big, Vector2(pad, 66.0), "左边相乘、右边相乘 →", HORIZONTAL_ALIGNMENT_LEFT, -1.0, UI.fs(19), Color(COL_ACCENT, ban))
	if t > res_start:
		var re := _ease(clampf((t - res_start) / 0.55, 0.0, 1.0))
		var yr := size.y * 0.80
		var wb := minf(size.x * 0.52, 420.0)
		_draw_tex_w("mul_r1", Vector2(size.x * 0.5, yr - 26.0), wb * re + 0.01, Color(COL_SUCCESS, re))
		_draw_tex_w("mul_r2", Vector2(size.x * 0.5, yr + 30.0), wb * 1.1 * re + 0.01, Color(COL_GOLD, re))

func _draw_line_series() -> void:
	var count := _a.size()
	if count < 2:
		return
	var reveal := _reveal()
	var shown := maxi(2, int(ceil(reveal * float(count))))
	var last := mini(shown, count) - 1
	draw_line(_to_screen(Vector2(1.0, float(_a[0]))), _to_screen(Vector2(float(last + 1), float(_a[last]))), Color(COL_SUCCESS, 0.7), 2.2, true)
	for i in mini(shown, count):
		var cur := i == last
		_dot(Vector2(float(i + 1), float(_a[i])), COL_GOLD if cur else COL_SUCCESS, 5.0 if cur else 4.0)
	var gi := clampi(int(reveal * float(count - 1)), 0, count - 1)
	draw_circle(_to_screen(Vector2(float(gi + 1), float(_a[gi]))), 9.0 + 2.0 * sin(_anim * 4.0), Color(COL_SUCCESS, 0.22))

func _draw_cobweb() -> void:
	if _a.size() < 2:
		return
	var d0 := domain.x
	var d1 := domain.y
	draw_dashed_line(_to_screen(Vector2(d0, d0)), _to_screen(Vector2(d1, d1)), Color(COL_DIM, 0.5), 1.2, 6.0)
	draw_line(_to_screen(Vector2(d0, _p * d0 + param)), _to_screen(Vector2(d1, _p * d1 + param)), Color(COL_ACCENT, 0.9), 2.2, true)
	var xstar := param / (1.0 - _p) if absf(1.0 - _p) > 0.0001 else 0.0
	if xstar > d0 and xstar < d1:
		draw_circle(_to_screen(Vector2(xstar, xstar)), 7.0, Color(COL_PINK, 0.5))
	var reveal := _reveal()
	var steps := _a.size()
	var drawn := maxi(1, int(ceil(reveal * float(steps))))
	var x := _a1
	for i in drawn:
		var y := _p * x + param
		draw_line(_to_screen(Vector2(x, x)), _to_screen(Vector2(x, y)), Color(COL_ACCENT, 0.9), 2.0, true)
		draw_line(_to_screen(Vector2(x, y)), _to_screen(Vector2(y, y)), Color(COL_PINK, 0.9), 2.0, true)
		x = y
	draw_circle(_to_screen(Vector2(x, x)), 8.0 + 2.0 * sin(_anim * 4.0), Color(COL_PINK, 0.3))

func _draw_stack() -> void:
	var count := _a.size()
	if count == 0:
		return
	var reveal := _reveal()
	var shown := maxi(1, int(ceil(reveal * float(count))))
	for i in mini(shown, count):
		var base := float(_a[i - 1]) if i > 0 else 0.0
		var top := float(_a[i])
		var x0 := _to_screen(Vector2(float(i + 1) - 0.32, 0.0)).x
		var x1 := _to_screen(Vector2(float(i + 1) + 0.32, 0.0)).x
		var y_top := _to_screen(Vector2(0.0, top)).y
		var y_base := _to_screen(Vector2(0.0, base)).y
		var rect := Rect2(Vector2(x0, minf(y_top, y_base)), Vector2(x1 - x0, maxf(absf(y_top - y_base), 1.0)))
		draw_rect(rect, Color.from_hsv(0.52 - 0.05 * float(i), 0.55, 1.0, 0.9))
		draw_rect(rect, Color(1, 1, 1, 0.12), false, 1.0)
		_dot(Vector2(float(i + 1), top), COL_GOLD, 4.0)
		if i == mini(shown, count) - 1:
			draw_string(UI.mono_font(), Vector2(x1 + 8.0, (y_top + y_base) * 0.5 + 4.0), "a%d = S%d − S%d" % [i + 1, i + 1, i], HORIZONTAL_ALIGNMENT_LEFT, 140.0, UI.fs(12), COL_GOLD)
	var line := PackedVector2Array()
	for i in mini(shown, count):
		line.append(_to_screen(Vector2(float(i + 1), float(_a[i]))))
	if line.size() >= 2:
		draw_polyline(line, Color(COL_DIM, 0.6), 1.6, true)
