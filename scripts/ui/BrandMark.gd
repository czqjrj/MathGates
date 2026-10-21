class_name BrandMark
extends Control
## 动态品牌徽标：多层旋转弧环 + 反向自转内环 + 脉动核心 + 环绕光点。
## 纯代码绘制，无素材。作为 UI 节点直接 add_child 即可；关闭「界面动效」时静态呈现。
## 另附 BrandMark.Underline：会往复扫光的科技感下划线，可替代普通 ColorRect 分隔线。

var accent: Color = Color("#5ee6ff")
var active: bool = true
var _t: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(150, 150)
	resized.connect(queue_redraw)
	set_process(UI.fx_on() and active)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var t := _t
	if not (UI.fx_on() and active):
		t = 0.0
	var c := size * 0.5
	var R := minf(size.x, size.y) * 0.5 - 3.0
	if R <= 4.0:
		return
	var a := accent

	# 外环：三段旋转弧
	var rot := t * 0.9
	for i in 3:
		var start := rot + TAU * float(i) / 3.0
		draw_arc(c, R, start, start + TAU / 3.0 * 0.72, 48, Color(a, 0.85), 2.4, true)

	# 外环刻度(每 3 格一根长刻线)
	for i in 24:
		var ang := -PI / 2.0 + TAU * float(i) / 24.0
		var on := i % 3 == 0
		var dir := Vector2(cos(ang), sin(ang))
		var rr := R - 4.0
		var seg := 4.5 if on else 2.4
		draw_line(c + dir * rr, c + dir * (rr - seg), Color(a, 0.5 if on else 0.22), 1.4)

	# 内环：反向旋转的短弧
	var R2 := R * 0.74
	var rot2 := -t * 1.45
	for i in 8:
		var start2 := rot2 + TAU * float(i) / 8.0
		draw_arc(c, R2, start2, start2 + TAU / 8.0 * 0.55, 24, Color(a, 0.45), 1.6, true)

	# 六边形(缓慢自转)
	var R3 := R * 0.5
	var pts := PackedVector2Array()
	var hrot := t * 0.5 - PI / 2.0
	for i in 6:
		var ang := hrot + TAU * float(i) / 6.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * R3)
	pts.append(pts[0])
	draw_polyline(pts, Color(a, 0.7), 1.8, true)
	for i in 6:
		draw_circle(pts[i], 2.4, Color(a, 0.9))

	# 脉动核心
	var pulse := 0.5 + 0.5 * sin(t * 3.0)
	var core := R * (0.11 + 0.05 * pulse)
	draw_circle(c, core * 3.4, Color(a, 0.10))
	draw_circle(c, core * 2.1, Color(a, 0.22))
	draw_circle(c, core, Color(1, 1, 1, 0.95))
	draw_circle(c, core * 0.55, Color.WHITE)

	# 环绕光点(三条轨道)
	var orb := R * 0.92
	for i in 3:
		var ang := t * 1.15 + TAU * float(i) / 3.0
		var p := c + Vector2(cos(ang), sin(ang)) * orb
		draw_circle(p, 5.0, Color(a, 0.25))
		draw_circle(p, 2.4, a)
		draw_circle(p, 1.1, Color.WHITE)

# ---------------------------------------------------------------- 会扫光的下划线
class Underline extends Control:
	var accent: Color = Color("#5ee6ff")
	var _t: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if custom_minimum_size == Vector2.ZERO:
			custom_minimum_size = Vector2(132, 3)
		resized.connect(queue_redraw)
		set_process(UI.fx_on())

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var mid := h * 0.5
		draw_rect(Rect2(0.0, mid - h * 0.5, w, h), Color(accent, 0.28), true)
		draw_rect(Rect2(0.0, mid - 0.5, w, 1.0), Color(accent, 0.9), true)
		if not UI.fx_on():
			return
		# 扫光：明亮段往复移动
		var p := fposmod(_t * 0.4, 1.0)
		var ping := 1.0 - absf(p * 2.0 - 1.0)
		var x := ping * w
		var band := maxf(30.0, w * 0.38)
		var steps := int(maxf(12.0, band))
		for i in steps:
			var fx := x - band * 0.5 + float(i) / float(steps) * band
			if fx < 0.0 or fx >= w:
				continue
			var k := 1.0 - absf(float(i) / float(steps) * 2.0 - 1.0)
			draw_rect(Rect2(fx, mid - h * 0.5 - 0.5, 1.0, h + 1.0), Color(1, 1, 1, k * 0.85), true)
