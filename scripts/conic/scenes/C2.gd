extends Node2D

# SceneC2  第二定义（统一定义）
# 动点到焦点 F 的距离与到定直线（准线）l 的距离之比为常数 e：
#   e < 1  椭圆      e = 1  抛物线      e > 1  双曲线
# 应用：焦半径与准线距离互化（|PF| = e · d(P,l)）

const CYCLE := 15.0
const TRACE_FROM := 3.2
const TRACE_TO := 11.2
const YMAX := 232.0

# mode: 1 椭圆， 2 抛物线， 3 双曲线
var mode := 1
var e := 0.7
var A := 200.0          # 椭圆半长轴 / 双曲线实半轴
var B := 0.0
var c := 140.0          # 半焦距
var p := 180.0          # 抛物线参数
var time := 0.0
var paused := false
var ctr := Vector2(480.0, 360.0)
var show_deriv := false
var deriv_t := 0.0

const DERIV_ID := "c2"
const DERIV_FPS := 20.0
const DERIV_RECT := Rect2(128.0, 181.0, 1024.0, 358.0)
const DERIV_STEP := 2.3
const DERIV_STEPS := 6

var t_unidef: Texture2D
var t_ratio: Texture2D
var t_dpf: Texture2D
var t_dpl: Texture2D
var t_ff: Texture2D
var t_ll: Texture2D
var t_eqe: Texture2D
var t_eqh: Texture2D
var t_eqp: Texture2D


func _ready() -> void:
	DrawUtil.ensure()
	t_unidef = DrawUtil.tex("unidef")
	t_ratio = DrawUtil.tex("ratio")
	t_dpf = DrawUtil.tex("dpf")
	t_dpl = DrawUtil.tex("dpl")
	t_ff = DrawUtil.tex("ff")
	t_ll = DrawUtil.tex("ll")
	t_eqe = DrawUtil.tex("eqe")
	t_eqh = DrawUtil.tex("eqh")
	t_eqp = DrawUtil.tex("eqp")
	_set_mode(1)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_set_mode(int(arg.get_slice("=", 1)))
		elif arg.begins_with("--e="):
			e = float(arg.get_slice("=", 1))
			_recalc()
		elif arg.begins_with("--p="):
			p = float(arg.get_slice("=", 1))
			_recalc()
		elif arg.begins_with("--paused="):
			paused = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--t="):
			time = clampf(float(arg.get_slice("=", 1)), 0.0, CYCLE)
		elif arg.begins_with("--deriv="):
			show_deriv = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--derivt="):
			deriv_t = float(arg.get_slice("=", 1))
			show_deriv = true


func _process(delta: float) -> void:
	if not paused:
		time = fmod(time + delta, CYCLE)
		if show_deriv:
			deriv_t += delta
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			_set_mode(1)
		KEY_2:
			_set_mode(2)
		KEY_3:
			_set_mode(3)
		KEY_UP:
			_adjust(0.03)
		KEY_DOWN:
			_adjust(-0.03)
		KEY_SPACE:
			paused = not paused
		KEY_LEFT:
			if show_deriv:
				deriv_t = clampf(deriv_t - DERIV_STEP, 0.0, _deriv_dur())
		KEY_RIGHT:
			if show_deriv:
				deriv_t = clampf(deriv_t + DERIV_STEP, 0.0, _deriv_dur())
		KEY_D:
			show_deriv = not show_deriv
			deriv_t = 0.0
		KEY_ESCAPE:
			pass


func _set_mode(m: int) -> void:
	mode = clampi(m, 1, 3)
	match mode:
		1:
			e = 0.7
		2:
			p = 180.0
		3:
			e = 1.35
	time = 0.0
	_recalc()


func _adjust(d: float) -> void:
	match mode:
		1:
			e = clampf(e + d, 0.5, 0.85)
		3:
			e = clampf(e + d, 1.15, 1.8)
		2:
			p = clampf(p + d * 40.0, 120.0, 240.0)
			return
	_recalc()


func _recalc() -> void:
	match mode:
		1:
			c = A * e
			B = sqrt(maxf(0.0, A * A - c * c))
		2:
			e = 1.0
		3:
			A = c / e
			B = sqrt(maxf(0.0, c * c - A * A))


func _directrix_x() -> float:
	match mode:
		1:
			return A / e
		2:
			return -p * 0.5
		_:
			return A / e


func _focus_x() -> float:
	match mode:
		1:
			return c
		2:
			return p * 0.5
		_:
			return c


func _draw() -> void:
	DrawUtil.ensure()
	var fo := 1.0 - smoothstep(13.8, 15.0, time)
	var intro := smoothstep(0.3, 1.5, time) * fo
	var def_a := smoothstep(1.0, 2.1, time) * fo
	var str_a := smoothstep(1.9, 3.0, time) * fo
	var rev := smoothstep(11.3, 12.6, time) * fo
	var pgt := clampf((time - TRACE_FROM) / (TRACE_TO - TRACE_FROM), 0.0, 1.0)

	var dx := _directrix_x()
	var fx := _focus_x()

	# 目标曲线
	if intro > 0.01:
		match mode:
			1:
				draw_polyline(_ell_pts(TAU, 128, ctr), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.18 * intro), 2.0, true)
			2:
				draw_polyline(_parab_pts(-YMAX, YMAX, 110, ctr), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.18 * intro), 2.0, true)
			3:
				draw_polyline(_hyper_pts(110, 1.0, ctr), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.15 * intro), 2.0, true)
				draw_polyline(_hyper_pts(110, -1.0, ctr), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.15 * intro), 2.0, true)

	# 坐标轴
	if str_a > 0.01:
		var ac := DrawUtil.with_a(DrawUtil.COL_AXIS, 0.7 * str_a)
		draw_line(ctr + Vector2(-250.0, 0.0), ctr + Vector2(360.0, 0.0), ac, 1.5, true)
		if mode != 2:
			draw_line(ctr + Vector2(0.0, -YMAX - 20.0), ctr + Vector2(0.0, YMAX + 20.0), ac, 1.5, true)
		draw_circle(ctr, 3.5, DrawUtil.with_a(DrawUtil.COL_TXT, str_a))
		DrawUtil.tag(self, ctr + Vector2(15.0, 13.0), "O", 15, DrawUtil.COL_DIM, str_a)

	# 准线 l
	if str_a > 0.01:
		draw_line(ctr + Vector2(dx, -YMAX - 30.0), ctr + Vector2(dx, YMAX + 30.0),
				DrawUtil.with_a(DrawUtil.COL_F2, 0.9 * str_a), 2.5, true)
		draw_line(ctr + Vector2(dx, -YMAX - 30.0), ctr + Vector2(dx, YMAX + 30.0),
				DrawUtil.with_a(DrawUtil.COL_TRACE, 0.35 * str_a), 1.0, true)
		DrawUtil.tag_tex(self, ctr + Vector2(dx, -YMAX - 44.0), t_ll, str_a)

	# 焦点 F
	if str_a > 0.01:
		var fp := ctr + Vector2(fx, 0.0)
		draw_circle(fp, 7.0, DrawUtil.with_a(DrawUtil.COL_F1, str_a))
		draw_arc(fp, 7.0, 0.0, TAU, 24, DrawUtil.with_a(DrawUtil.COL_TXT, 0.85 * str_a), 2.0, true)
		DrawUtil.tag_tex(self, fp + Vector2(0.0, -20.0), t_ff, str_a)

	# 动点 P 与两条距离
	var pp := _point(pgt)
	var foot := Vector2(dx, pp.y)
	if str_a > 0.01:
		draw_line(ctr + Vector2(fx, 0.0), ctr + pp, DrawUtil.with_a(DrawUtil.COL_S2, str_a), 2.5, true)
		draw_line(ctr + pp, ctr + foot, DrawUtil.with_a(DrawUtil.COL_S1, str_a), 2.5, true)
		draw_circle(ctr + foot, 5.0, DrawUtil.with_a(DrawUtil.COL_S1, str_a))
		draw_line(ctr + foot, ctr + foot + Vector2(0.0, 14.0), DrawUtil.with_a(DrawUtil.COL_S1, str_a), 2.0, true)
		var r1 := pp.distance_to(Vector2(fx, 0.0))
		var r2 := absf(pp.x - dx)
		var m1 := (Vector2(fx, 0.0) + pp) * 0.5 + (pp - Vector2(fx, 0.0)).orthogonal().normalized() * 18.0
		var m2 := (pp + foot) * 0.5 + Vector2(0.0, -22.0)
		DrawUtil.tag_val(self, ctr + m1, t_dpf, "%.1f" % r1, 16, str_a)
		DrawUtil.tag_val(self, ctr + m2, t_dpl, "%.1f" % r2, 16, str_a)

	# 轨迹描绘
	if pgt > 0.002:
		var ta := smoothstep(TRACE_FROM, TRACE_FROM + 0.7, time) * fo
		var n := maxi(4, int(round(240.0 * pgt)))
		match mode:
			1:
				draw_polyline(_ell_pts(TAU * pgt, n, ctr), DrawUtil.with_a(DrawUtil.COL_TRACE, ta), 3.0, true)
			2:
				var t2 := -YMAX + 2.0 * YMAX * pgt
				draw_polyline(_parab_pts(-YMAX, t2, n, ctr), DrawUtil.with_a(DrawUtil.COL_TRACE, ta), 3.0, true)
			3:
				var tm := asinh(YMAX / maxf(B, 8.0))
				var t3 := -tm + 2.0 * tm * pgt
				draw_polyline(_hyper_arc(-tm, t3, n, ctr), DrawUtil.with_a(DrawUtil.COL_TRACE, ta), 3.0, true)

	# 动点 P
	if str_a > 0.01:
		draw_circle(ctr + pp, 7.0, DrawUtil.with_a(DrawUtil.COL_TXT, str_a))
		draw_arc(ctr + pp, 11.0, 0.0, TAU, 28, DrawUtil.with_a(DrawUtil.COL_TRACE, 0.8 * str_a), 2.0, true)
		var off := Vector2(0.0, -32.0) if mode != 2 else Vector2(28.0, -20.0)
		DrawUtil.tag(self, ctr + pp + off + Vector2(0.0, 6.0), "P", 17, DrawUtil.COL_TXT, str_a)

	# 底部读数：比值恒为 e
	if str_a > 0.01:
		var pulse := smoothstep(10.8, 11.4, time) * (1.0 - smoothstep(11.4, 13.0, time)) * fo
		var tint := DrawUtil.COL_DIM.lerp(DrawUtil.COL_S2, pulse)
		DrawUtil.readout(self, ctr.x + 40.0, 636.0, t_ratio, "%.3f" % e, "= e（常数）", str_a, tint)

	# 标题由游戏 UI 提供，保留定义说明
	DrawUtil.text_center(self, 80.0, "动点到焦点 F 的距离与到准线 l 的距离之比为常数 e：e<1 椭圆，e=1 抛物线，e>1 双曲线",
			17, DrawUtil.with_a(DrawUtil.COL_DIM, def_a))
	DrawUtil.tex_centered(self, t_unidef, Vector2(get_viewport_rect().size.x * 0.5, 122.0), def_a)

	if rev > 0.01:
		_params(rev)

	if show_deriv:
		_draw_deriv()


func _deriv_dur() -> float:
	return maxf(0.001, float(Deriv.count(DERIV_ID)) / DERIV_FPS)


func _deriv_step(prog: float) -> int:
	return clampi(int(prog * float(DERIV_STEPS)) + 1, 1, DERIV_STEPS)


func _draw_deriv() -> void:
	var app := clampf(deriv_t / 0.35, 0.0, 1.0)
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.03, 0.04, 0.07, 0.82 * app), true)
	DrawUtil.text_center(self, 150.0, "公式推导 · 第二定义推标准方程（Manim）", 22, DrawUtil.with_a(DrawUtil.COL_S2, app))
	var dur := _deriv_dur()
	var prog := clampf(deriv_t / dur, 0.0, 1.0)
	if Deriv.count(DERIV_ID) == 0:
		DrawUtil.text_center(self, 360.0, "推导素材未生成：请运行  tools\\render_manim.ps1 -Id c2",
				20, DrawUtil.with_a(DrawUtil.COL_F1, app))
	else:
		Deriv.draw(self, DERIV_ID, DERIV_RECT, prog, app)
	var bx := 128.0
	var bw := 1024.0
	var by := 662.0
	draw_rect(Rect2(bx, by, bw, 6.0), Color(0.15, 0.18, 0.26, 0.8 * app), true)
	draw_rect(Rect2(bx, by, bw * prog, 6.0), DrawUtil.with_a(DrawUtil.COL_TRACE, app), true)
	DrawUtil.text(self, Vector2(bx, by - 22.0), "推导进度 %d%%" % int(round(prog * 100.0)), 15,
			DrawUtil.with_a(DrawUtil.COL_S2, app))
	DrawUtil.text_right(self, Vector2(bx + bw, by - 22.0), "第 %d / %d 步" % [_deriv_step(prog), DERIV_STEPS], 15,
			DrawUtil.with_a(DrawUtil.COL_S2, app))
	DrawUtil.text_center(self, 700.0, "← / → 逐步查看　·　空格 暂停 / 继续　·　D 关闭",
			15, DrawUtil.with_a(DrawUtil.COL_DIM, app))


func _point(pgt: float) -> Vector2:
	match mode:
		1:
			var th := TAU * pgt
			return Vector2(A * cos(th), B * sin(th))
		2:
			var t := -YMAX + 2.0 * YMAX * pgt
			return Vector2(t * t / (2.0 * p), t)
		_:
			var tm := asinh(YMAX / maxf(B, 8.0))
			var t := -tm + 2.0 * tm * pgt
			return Vector2(A * cosh(t), B * sinh(t))


func _params(a: float) -> void:
	var x := 1006.0
	var y := 224.0
	var title := ""
	var lines: Array = []
	var cond := ""
	match mode:
		1:
			title = "椭圆"
			lines = [
				"e = c/a = %.3f" % e,
				"a = %.1f" % A,
				"b = %.1f" % B,
				"c = %.1f" % c,
				"焦点 F(%.1f, 0)" % c,
				"准线 l : x = %.1f" % (A / e),
			]
			cond = "0 < e < 1  椭圆"
		2:
			title = "抛物线"
			lines = [
				"e = 1",
				"p = %.1f" % p,
				"焦点 F(%.1f, 0)" % (p * 0.5),
				"准线 l : x = %.1f" % (-p * 0.5),
			]
			cond = "e = 1  抛物线"
		_:
			title = "双曲线"
			lines = [
				"e = c/a = %.3f" % e,
				"a = %.1f" % A,
				"b = %.1f" % B,
				"c = %.1f" % c,
				"焦点 F(%.1f, 0)" % c,
				"准线 l : x = %.1f" % (A / e),
			]
			cond = "e > 1  双曲线"
	var h := 62.0 + lines.size() * 26.0 + 26.0
	draw_rect(Rect2(x - 18.0, y - 34.0, 224.0, h), Color(0.09, 0.11, 0.17, 0.6 * a), true)
	DrawUtil.text(self, Vector2(x, y), "参数 · " + title, 17, DrawUtil.with_a(DrawUtil.COL_TXT, a))
	for i in lines.size():
		DrawUtil.text(self, Vector2(x + 8.0, y + 36.0 + i * 26.0), lines[i], 16,
				DrawUtil.with_a(DrawUtil.COL_DIM, a))
	DrawUtil.text(self, Vector2(x + 8.0, y + 42.0 + lines.size() * 26.0), cond, 16,
			DrawUtil.with_a(DrawUtil.COL_S2, a))


# ---------------------------------------------------------------------------
#  采样
# ---------------------------------------------------------------------------
func _ell_pts(theta1: float, n: int, off: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in range(n + 1):
		var th := theta1 * float(i) / float(n)
		pts[i] = off + Vector2(A * cos(th), B * sin(th))
	return pts


func _hyper_pts(n: int, side: float, off: Vector2) -> PackedVector2Array:
	var tm := asinh(YMAX / maxf(B, 8.0))
	return _hyper_arc_side(-tm, tm, n, side, off)


func _hyper_arc(t0: float, t1: float, n: int, off: Vector2) -> PackedVector2Array:
	return _hyper_arc_side(t0, t1, n, 1.0, off)


func _hyper_arc_side(t0: float, t1: float, n: int, side: float, off: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in range(n + 1):
		var t := t0 + (t1 - t0) * float(i) / float(n)
		pts[i] = off + Vector2(side * A * cosh(t), B * sinh(t))
	return pts


func _parab_pts(t0: float, t1: float, n: int, off: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in range(n + 1):
		var t := t0 + (t1 - t0) * float(i) / float(n)
		pts[i] = off + Vector2(t * t / (2.0 * p), t)
	return pts
