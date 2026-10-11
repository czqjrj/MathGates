class_name Vfx
extends RefCounted
## 通用动效工厂(纯代码绘制，无外部素材)，供各关卡作答/结算复用。
##
## 用法(父应为铺满屏幕的 Control，如 StageBase 的 _ui 或场景根节点)：
##   Vfx.burst(_ui, Vfx.center_of(_opt_panels[k]), UI.COL_SUCCESS)
##   Vfx.float_text(_ui, pos, "连击 x3", Color("#ffd479"))
##   Vfx.celebrate(_ui, pos, UI.COL_ACCENT)
##
## 所有特效均受「界面动效」开关(UI.animations)控制：关闭时静默不生成，调用可安全忽略返回值。
## 坐标为父控件本地坐标；父铺满全屏时即屏幕坐标，控件屏幕中心用 center_of() 取。

const STAR_COLS := [Color("#5ee6ff"), Color("#ffd479"), Color("#34d399"), Color("#a878ff"), Color("#fb7185")]

# ---------------------------------------------------------------- 工具
static func enabled() -> bool:
	return UI.animations

## 某控件中心的屏幕坐标(供特效定位)。控件无效时返回调用方给定的兜底值。
static func center_of(ctl: Control, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if ctl == null or not is_instance_valid(ctl):
		return fallback
	return ctl.get_global_rect().get_center()

## 建一个铺满父级的特效层(鼠标穿透)。父应为铺满屏幕的 Control。
static func _layer(parent: Node) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	if parent is Control:
		UI.full_rect(c)
	return c

static func _kill(c: Control, key: String) -> void:
	if c.has_meta(key):
		var old: Variant = c.get_meta(key)
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()

# ---------------------------------------------------------------- 冲击爆发(答对)
## 答对反馈：扩散冲击环 + 放射光点。
static func burst(parent: Node, pos: Vector2, col: Color = UI.COL_SUCCESS, scale: float = 1.0) -> void:
	if not enabled() or parent == null or not is_instance_valid(parent):
		return
	var b := Burst.new()
	b.center = pos
	b.col = col
	b.scl = scale
	parent.add_child(b)
	if parent is Control:
		UI.full_rect(b)

## 星光爆发：彩色五角星向四周飞散并旋转(通关/连击庆祝)。
static func star_burst(parent: Node, pos: Vector2, count: int = 18, power: float = 1.0) -> void:
	if not enabled() or parent == null or not is_instance_valid(parent):
		return
	var s := StarBurst.new()
	s.center = pos
	s.count = count
	s.power = power
	parent.add_child(s)
	if parent is Control:
		UI.full_rect(s)

## 组合庆祝：冲击环 + 星光爆发(通关/里程碑)。
static func celebrate(parent: Node, pos: Vector2, col: Color = UI.COL_ACCENT) -> void:
	burst(parent, pos, col, 1.25)
	star_burst(parent, pos, 20, 1.15)

# ---------------------------------------------------------------- 单环扩散
static func ring(parent: Node, pos: Vector2, col: Color = UI.COL_ACCENT, max_r: float = 140.0, dur: float = 0.6) -> void:
	if not enabled() or parent == null or not is_instance_valid(parent):
		return
	var r := Ring.new()
	r.center = pos
	r.col = col
	r.max_r = max_r
	r.dur = dur
	parent.add_child(r)
	if parent is Control:
		UI.full_rect(r)

# ---------------------------------------------------------------- 漂浮文字
## 上浮 + 弹入 + 淡出的提示文字(如「正确」「连击 x3」)。
static func float_text(parent: Node, pos: Vector2, text: String, col: Color = UI.COL_TEXT, size_px: int = 30) -> void:
	if not enabled() or parent == null or not is_instance_valid(parent):
		return
	var f := FloatText.new()
	f.start = pos
	f.text = text
	f.col = col
	f.size_px = size_px
	parent.add_child(f)
	if parent is Control:
		UI.full_rect(f)

# ---------------------------------------------------------------- 屏幕闪光
static func screen_flash(parent: Node, col: Color = Color.WHITE, peak: float = 0.3, dur: float = 0.4) -> void:
	if not enabled() or parent == null or not is_instance_valid(parent):
		return
	var r := ColorRect.new()
	r.color = Color(col.r, col.g, col.b, peak)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	if parent is Control:
		UI.full_rect(r)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: r.queue_free())

# ---------------------------------------------------------------- 抖动 / 摇摆
## 旋转摇摆(答错时的"摇头"反馈)，适合容器子项(container 只管位置不管旋转)。
static func wobble(c: Control, amp_deg: float = 7.0, dur: float = 0.5) -> void:
	if not enabled() or c == null or not is_instance_valid(c):
		return
	_kill(c, "_fx_wobble")
	c.pivot_offset = c.size * 0.5
	var base := c.rotation
	var tw := c.create_tween()
	c.set_meta("_fx_wobble", tw)
	tw.tween_method(func(v: float) -> void:
		if is_instance_valid(c):
			c.rotation = base + deg_to_rad(v)
	, amp_deg, 0.0, dur).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## 位移抖动(答错/危险的画面冲击)，适合不在容器中的自由控件(面板/弹层)。
static func shake(c: Control, amp: float = 12.0, dur: float = 0.42) -> void:
	if not enabled() or c == null or not is_instance_valid(c):
		return
	_kill(c, "_fx_shake")
	var base := c.position
	var tw := c.create_tween()
	c.set_meta("_fx_shake", tw)
	var steps := 6
	for i in steps + 1:
		var k := 1.0 - float(i) / float(steps + 1)
		var off := Vector2(randf_range(-amp, amp), randf_range(-amp * 0.55, amp * 0.55)) * k
		tw.tween_property(c, "position", base + off, dur / float(steps + 1)).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "position", base, dur / float(steps + 1)).set_trans(Tween.TRANS_SINE)

# ---------------------------------------------------------------- 金币飞行
## 金币从 from 沿弧线飞向 to(结算时飞向顶栏金币读数)。
static func coin_fly(parent: Node, from: Vector2, to: Vector2, count: int = 10) -> void:
	if not enabled() or parent == null or not is_instance_valid(parent):
		return
	var c := CoinFly.new()
	c.from = from
	c.to = to
	c.count = count
	parent.add_child(c)
	if parent is Control:
		UI.full_rect(c)

# ================================================================ 内部特效节点
class Burst extends Control:
	var center := Vector2.ZERO
	var col := Color.WHITE
	var scl := 1.0
	var _t := 0.0
	var _parts: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rays := 16
		for i in rays:
			var a := TAU * float(i) / float(rays) + randf_range(-0.14, 0.14)
			var sp := randf_range(190.0, 380.0) * scl
			var life := randf_range(0.45, 0.75)
			_parts.append({
				"pos": center,
				"vel": Vector2(cos(a), sin(a)) * sp,
				"life": life,
				"max": life,
				"size": randf_range(1.8, 3.8) * scl,
			})
		set_process(true)

	func _process(delta: float) -> void:
		_t += delta
		var alive: Array = []
		for p in _parts:
			var v: Vector2 = p["vel"]
			v *= (1.0 - minf(3.2 * delta, 0.9))
			v.y += 130.0 * delta
			p["vel"] = v
			p["pos"] = (p["pos"] as Vector2) + v * delta
			p["life"] = float(p["life"]) - delta
			if float(p["life"]) > 0.0:
				alive.append(p)
		_parts = alive
		queue_redraw()
		if _t > 1.05:
			queue_free()

	func _draw() -> void:
		var rp := clampf(_t / 0.5, 0.0, 1.0)
		if rp < 1.0:
			var r := 92.0 * scl * (1.0 - pow(1.0 - rp, 3.0))
			var a := 0.8 * (1.0 - rp)
			draw_arc(center, r, 0.0, TAU, 64, Color(col.r, col.g, col.b, a), 4.0 * (1.0 - rp) + 1.0, true)
			draw_arc(center, r * 0.66, 0.0, TAU, 48, Color(1, 1, 1, a * 0.45), 1.5, true)
		for p in _parts:
			var a2 := clampf(float(p["life"]) / maxf(float(p["max"]), 0.001), 0.0, 1.0)
			var sz := float(p["size"]) * (0.55 + 0.45 * a2)
			draw_circle(p["pos"], sz * 1.9, Color(col.r, col.g, col.b, a2 * 0.35))
			draw_circle(p["pos"], sz, Color(1, 1, 1, a2))

class StarBurst extends Control:
	var center := Vector2.ZERO
	var count := 18
	var power := 1.0
	var _t := 0.0
	var _stars: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in count:
			var a := randf_range(0.0, TAU)
			var sp := randf_range(140.0, 340.0) * power
			var life := randf_range(0.6, 1.0)
			_stars.append({
				"pos": center,
				"vel": Vector2(cos(a), sin(a)) * sp,
				"rot": randf_range(0.0, TAU),
				"spin": randf_range(-8.0, 8.0),
				"life": life,
				"max": life,
				"size": randf_range(6.0, 12.0) * power,
				"col": STAR_COLS[randi() % STAR_COLS.size()],
			})
		set_process(true)

	func _process(delta: float) -> void:
		_t += delta
		var alive: Array = []
		for s in _stars:
			var v: Vector2 = s["vel"]
			v *= (1.0 - minf(2.2 * delta, 0.9))
			v.y += 120.0 * delta
			s["vel"] = v
			s["pos"] = (s["pos"] as Vector2) + v * delta
			s["rot"] = float(s["rot"]) + float(s["spin"]) * delta
			s["life"] = float(s["life"]) - delta
			if float(s["life"]) > 0.0:
				alive.append(s)
		_stars = alive
		queue_redraw()
		if _t > 1.4:
			queue_free()

	func _draw() -> void:
		for s in _stars:
			var a := clampf(float(s["life"]) / maxf(float(s["max"]), 0.001), 0.0, 1.0)
			var c: Color = s["col"]
			c.a = a
			_star(s["pos"], float(s["size"]) * (0.5 + 0.5 * a), float(s["rot"]), c)

	func _star(pos: Vector2, r: float, rot: float, c: Color) -> void:
		var pts := PackedVector2Array()
		for i in 8:
			var ang := rot + TAU * float(i) / 8.0
			var rad := r if i % 2 == 0 else r * 0.42
			pts.append(pos + Vector2(cos(ang), sin(ang)) * rad)
		draw_colored_polygon(pts, c)

class Ring extends Control:
	var center := Vector2.ZERO
	var col := Color.WHITE
	var max_r := 140.0
	var dur := 0.6
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t >= dur:
			queue_free()

	func _draw() -> void:
		var p := clampf(_t / maxf(dur, 0.001), 0.0, 1.0)
		var r := max_r * (1.0 - pow(1.0 - p, 3.0))
		var a := 1.0 - p
		draw_arc(center, r, 0.0, TAU, 72, Color(col.r, col.g, col.b, a * 0.85), 3.0 * a + 1.0, true)

class FloatText extends Control:
	var start := Vector2.ZERO
	var text := ""
	var col := Color.WHITE
	var size_px := 30
	var dur := 1.25
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t >= dur:
			queue_free()

	func _draw() -> void:
		var p := clampf(_t / maxf(dur, 0.001), 0.0, 1.0)
		var rise := 54.0 * (1.0 - pow(1.0 - p, 2.0))
		var alpha := 1.0 - smoothstep(0.5, 1.0, p)
		var pop := 1.0
		if p < 0.18:
			pop = 0.6 + 0.4 * (p / 0.18)
			pop = maxf(pop, 0.6)
		else:
			pop = 1.0 + 0.18 * (1.0 - smoothstep(0.18, 0.42, p))
		var f := UI.font()
		var px := maxi(1, int(round(float(UI.fs(size_px)) * pop)))
		var pos := start + Vector2(0.0, -rise)
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var at := pos + Vector2(-w * 0.5, 0.0)
		var c := col
		c.a = alpha
		draw_string_outline(f, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(2, int(px * 0.24)), Color(0, 0, 0, 0.55 * alpha))
		draw_string(f, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)

class CoinFly extends Control:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var count := 10
	var _t := 0.0
	var _coins: Array = []
	var _dur := 0.62

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in count:
			_coins.append({
				"delay": float(i) * 0.045,
				"ctrl": from + Vector2(randf_range(-70.0, 70.0), randf_range(-30.0, 30.0)) - Vector2(0.0, 130.0),
				"jitter": randf_range(-24.0, 24.0),
			})
		set_process(true)

	func _total() -> float:
		return float(maxi(0, count - 1)) * 0.045 + _dur

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t > _total() + 0.35:
			queue_free()

	func _draw() -> void:
		for i in _coins.size():
			var c: Dictionary = _coins[i]
			var lp := (_t - float(c["delay"])) / _dur
			if lp < 0.0:
				continue
			var p := clampf(lp, 0.0, 1.0)
			var e := 1.0 - pow(1.0 - p, 2.4)
			var pos := _bezier(from, c["ctrl"], to, e)
			pos.x += float(c["jitter"]) * sin(p * PI)
			var fade := 1.0 if p < 0.85 else (1.0 - (p - 0.85) / 0.15)
			var r := 11.0 - 3.0 * p
			draw_circle(pos, r, Color("#ffd479", fade))
			draw_circle(pos, r * 0.62, Color(1.0, 0.96, 0.78, fade))
			# 中心菱形(金币图案)
			var d := r * 0.42
			draw_colored_polygon(PackedVector2Array([
				pos + Vector2(0, -d), pos + Vector2(d, 0),
				pos + Vector2(0, d), pos + Vector2(-d, 0)]), Color("#c98a1a", fade))

	func _bezier(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
		var u := 1.0 - t
		return u * u * a + 2.0 * u * t * c + t * t * b
