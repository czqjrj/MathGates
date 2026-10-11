extends Node2D

# SceneC3  第三定义
# 椭圆/双曲线上一点 P 与两顶点 A(-a,0)、B(a,0) 连线的斜率之积为定值：
#   椭圆  k(PA)·k(PB) = -b²/a²        双曲线  k(PA)·k(PB) = +b²/a²
# 与点差法互为表里，是斜率积、中点弦、定点定值问题的源头。

const CYCLE := 15.0
const TRACE_FROM := 3.4
const TRACE_TO := 11.4
const YMAX := 232.0
const AA := 200.0          # 半长轴 / 实半轴 a（固定）
const ELL_EPS := 0.16      # 避开顶点的角偏移
const HYP_T0 := 0.12

# mode: 1 椭圆， 2 双曲线
var mode := 1
var B := 150.0             # 半短轴 / 虚半轴 b（可调）
var time := 0.0
var paused := false
var ctr := Vector2(500.0, 360.0)
var a_pt := Vector2(-AA, 0.0)
var b_pt := Vector2(AA, 0.0)
var show_deriv := false
var deriv_t := 0.0

const DERIV_ID := "c3"
const DERIV_FPS := 20.0
const DERIV_RECT := Rect2(128.0, 181.0, 1024.0, 358.0)
const DERIV_STEP := 2.3
const DERIV_STEPS := 6

var t_def3e: Texture2D
var t_def3h: Texture2D
var t_k1l: Texture2D
var t_k2l: Texture2D
var t_kprod: Texture2D
var t_eqe: Texture2D
var t_eqh: Texture2D


func _ready() -> void:
	DrawUtil.ensure()
	t_def3e = DrawUtil.tex("def3e")
	t_def3h = DrawUtil.tex("def3h")
	t_k1l = DrawUtil.tex("k1l")
	t_k2l = DrawUtil.tex("k2l")
	t_kprod = DrawUtil.tex("kprod")
	t_eqe = DrawUtil.tex("eqe")
	t_eqh = DrawUtil.tex("eqh")
	_set_mode(1)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_set_mode(int(arg.get_slice("=", 1)))
		elif arg.begins_with("--b="):
			B = float(arg.get_slice("=", 1))
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
		KEY_UP:
			_adjust(8.0)
		KEY_DOWN:
			_adjust(-8.0)
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
	mode = clampi(m, 1, 2)
	B = 150.0 if mode == 1 else 160.0
	time = 0.0
	_recalc()


func _adjust(d: float) -> void:
	B = clampf(B + d, 60.0, 230.0)
	_recalc()


func _recalc() -> void:
	pass


func _k_const() -> float:
	var k := B * B / (AA * AA)
	return -k if mode == 1 else k


func _draw() -> void:
	DrawUtil.ensure()
	var fo := 1.0 - smoothstep(13.8, 15.0, time)
	var intro := smoothstep(0.3, 1.5, time) * fo
	var def_a := smoothstep(1.0, 2.1, time) * fo
	var str_a := smoothstep(1.9, 3.0, time) * fo
	var rev := smoothstep(11.5, 12.8, time) * fo
	var pgt := clampf((time - TRACE_FROM) / (TRACE_TO - TRACE_FROM), 0.0, 1.0)

	# 目标曲线
	if intro > 0.01:
		if mode == 1:
			draw_polyline(_ell_pts(TAU, 128, ctr), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.18 * intro), 2.0, true)
		else:
			draw_polyline(_hyper_pts(110, 1.0, ctr), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.15 * intro), 2.0, true)
			draw_polyline(_hyper_pts(110, -1.0, ctr), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.15 * intro), 2.0, true)

	# 坐标轴
	if str_a > 0.01:
		var ac := DrawUtil.with_a(DrawUtil.COL_AXIS, 0.7 * str_a)
		draw_line(ctr + Vector2(-AA - 40.0, 0.0), ctr + Vector2(AA + 60.0, 0.0), ac, 1.5, true)
		if mode == 1:
			draw_line(ctr + Vector2(0.0, -B - 20.0), ctr + Vector2(0.0, B + 20.0), ac, 1.5, true)
		else:
			draw_line(ctr + Vector2(0.0, -YMAX - 20.0), ctr + Vector2(0.0, YMAX + 20.0), ac, 1.5, true)
		draw_circle(ctr, 3.5, DrawUtil.with_a(DrawUtil.COL_TXT, str_a))
		DrawUtil.tag(self, ctr + Vector2(16.0, 14.0), "O", 15, DrawUtil.COL_DIM, str_a)

	# 顶点 A、B
	if str_a > 0.01:
		_vertex(a_pt, "A", DrawUtil.COL_S1, str_a)
		_vertex(b_pt, "B", DrawUtil.COL_F2, str_a)

	# 动点 P 与两条连线
	var pp := _path_p(pgt)
	var k1 := pp.y / (pp.x - a_pt.x)
	var k2 := pp.y / (pp.x - b_pt.x)
	if str_a > 0.01:
		draw_line(ctr + a_pt, ctr + pp, DrawUtil.with_a(DrawUtil.COL_S1, str_a), 2.5, true)
		draw_line(ctr + b_pt, ctr + pp, DrawUtil.with_a(DrawUtil.COL_F2, str_a), 2.5, true)
		var m1 := (a_pt + pp) * 0.5 + (pp - a_pt).orthogonal().normalized() * 18.0
		var m2 := (b_pt + pp) * 0.5 + (pp - b_pt).orthogonal().normalized() * 18.0
		DrawUtil.tag_val(self, ctr + m1, t_k1l, "%.2f" % k1, 16, str_a)
		DrawUtil.tag_val(self, ctr + m2, t_k2l, "%.2f" % k2, 16, str_a)

	# 轨迹描绘
	if pgt > 0.002:
		var ta := smoothstep(TRACE_FROM, TRACE_FROM + 0.7, time) * fo
		var n := maxi(4, int(round(240.0 * pgt)))
		draw_polyline(_path_samples(pgt, n), DrawUtil.with_a(DrawUtil.COL_TRACE, ta), 3.0, true)

	# 动点 P
	if str_a > 0.01:
		draw_circle(ctr + pp, 7.0, DrawUtil.with_a(DrawUtil.COL_TXT, str_a))
		draw_arc(ctr + pp, 11.0, 0.0, TAU, 28, DrawUtil.with_a(DrawUtil.COL_TRACE, 0.8 * str_a), 2.0, true)
		var dir := (pp - Vector2.ZERO)
		var off := dir.normalized() * 32.0 if dir.length() > 0.5 else Vector2(0.0, -32.0)
		DrawUtil.tag(self, ctr + pp + off + Vector2(0.0, 6.0), "P", 17, DrawUtil.COL_TXT, str_a)

	# 底部读数：斜率积为定值
	if str_a > 0.01:
		var pulse := smoothstep(11.0, 11.6, time) * (1.0 - smoothstep(11.6, 13.2, time)) * fo
		var tint := DrawUtil.COL_DIM.lerp(DrawUtil.COL_S2, pulse)
		var tail := "= -b²/a²  （定值）" if mode == 1 else "= b²/a²  （定值）"
		DrawUtil.readout(self, ctr.x + 40.0, 636.0, t_kprod, "%.3f" % (k1 * k2), tail, str_a, tint)

	# 标题由游戏 UI 提供，保留定义说明
	DrawUtil.text_center(self, 80.0, "曲线上一点 P 与两顶点 A、B 连线的斜率之积为定值（与 P 无关）",
			17, DrawUtil.with_a(DrawUtil.COL_DIM, def_a))
	DrawUtil.tex_centered(self, t_def3e if mode == 1 else t_def3h,
			Vector2(get_viewport_rect().size.x * 0.5, 122.0), def_a)

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
	DrawUtil.text_center(self, 150.0, "公式推导 · 第三定义（斜率积为定值）（Manim）", 22, DrawUtil.with_a(DrawUtil.COL_S2, app))
	var dur := _deriv_dur()
	var prog := clampf(deriv_t / dur, 0.0, 1.0)
	if Deriv.count(DERIV_ID) == 0:
		DrawUtil.text_center(self, 360.0, "推导素材未生成：请运行  tools\\render_manim.ps1 -Id c3",
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


func _vertex(local: Vector2, nm: String, col: Color, a: float) -> void:
	var pos := ctr + local
	draw_circle(pos, 6.0, DrawUtil.with_a(col, a))
	draw_arc(pos, 6.0, 0.0, TAU, 20, DrawUtil.with_a(DrawUtil.COL_TXT, 0.8 * a), 2.0, true)
	DrawUtil.tag(self, pos + Vector2(0.0, 24.0), nm, 16, col, a)


func _params(a: float) -> void:
	var x := 1006.0
	var y := 224.0
	var c := sqrt(AA * AA + B * B) if mode == 2 else sqrt(maxf(0.0, AA * AA - B * B))
	var title := "椭圆" if mode == 1 else "双曲线"
	var lines := [
		"a = %.1f" % AA,
		"b = %.1f" % B,
		"c = %.1f" % c,
		"e = c/a = %.3f" % (c / AA),
		"k(PA)·k(PB) = %.3f" % _k_const(),
	]
	var cond := "-b²/a²  （定值）" if mode == 1 else "+b²/a²  （定值）"
	var h := 62.0 + lines.size() * 26.0 + 26.0
	draw_rect(Rect2(x - 18.0, y - 34.0, 224.0, h), Color(0.09, 0.11, 0.17, 0.6 * a), true)
	DrawUtil.text(self, Vector2(x, y), "参数 · " + title, 17, DrawUtil.with_a(DrawUtil.COL_TXT, a))
	for i in lines.size():
		DrawUtil.text(self, Vector2(x + 8.0, y + 36.0 + i * 26.0), lines[i], 16,
				DrawUtil.with_a(DrawUtil.COL_DIM, a))
	DrawUtil.text(self, Vector2(x + 8.0, y + 42.0 + lines.size() * 26.0), cond, 16,
			DrawUtil.with_a(DrawUtil.COL_S2, a))


# ---------------------------------------------------------------------------
#  P 的路径（两段圆弧，避开两顶点处斜率无定义）
# ---------------------------------------------------------------------------
func _path_p(u: float) -> Vector2:
	if mode == 1:
		var span := PI - 2.0 * ELL_EPS
		var th := 0.0
		if u < 0.5:
			th = ELL_EPS + span * (u / 0.5)
		else:
			th = PI + ELL_EPS + span * ((u - 0.5) / 0.5)
		return Vector2(AA * cos(th), B * sin(th))
	var tm := asinh(YMAX / maxf(B, 8.0))
	if u < 0.5:
		var t := tm - (tm - HYP_T0) * (u / 0.5)
		return Vector2(AA * cosh(t), B * sinh(t))
	var t2 := -HYP_T0 - (tm - HYP_T0) * ((u - 0.5) / 0.5)
	return Vector2(AA * cosh(t2), B * sinh(t2))


func _path_samples(u_to: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in range(n + 1):
		pts[i] = ctr + _path_p(u_to * float(i) / float(n))
	return pts


func _ell_pts(theta1: float, n: int, off: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in range(n + 1):
		var th := theta1 * float(i) / float(n)
		pts[i] = off + Vector2(AA * cos(th), B * sin(th))
	return pts


func _hyper_pts(n: int, side: float, off: Vector2) -> PackedVector2Array:
	var tm := asinh(YMAX / maxf(B, 8.0))
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in range(n + 1):
		var t := -tm + 2.0 * tm * float(i) / float(n)
		pts[i] = off + Vector2(side * AA * cosh(t), B * sinh(t))
	return pts
