extends Node2D

# SceneC1  第一定义（强化版）
#   1 绳作法机械构图    两枚图钉 + 长为 2a 的细绳，笔尖绷紧描绘椭圆
#   2 圆交法构造        |PF1|=r, |PF2|=2a-r, 两圆交点 P 的轨迹
#   3 焦半径应用        焦点三角形周长 = 2a+2c；定义法求 |PA|+|PF1| 最小值
#   4 三态讨论          2a 与 2c 的大小关系：椭圆 / 线段 / 空集
#   5 双曲线第一定义     ||PF1|-|PF2|| = 2a
#   6 抛物线第一定义     |PF| = d(P,l)
#   D 键：定义 → 标准方程 的 Manim 推导

const CYCLE := 18.0
const TRACE_FROM := 4.0
const TRACE_TO := 14.0
const DERIV_ID := "c1"
const DERIV_FPS := 20.0
const DERIV_RECT := Rect2(128.0, 181.0, 1024.0, 358.0)
const DERIV_STEP := 2.3

var mode := 1
var a := 220.0            # 椭圆半长轴
var b := 169.7            # 椭圆半短轴
var ah := 90.0            # 双曲线实半轴
var bh := 107.2           # 双曲线虚半轴
var p := 160.0            # 抛物线参数
var foc := 140.0          # 焦点到中心距离 c
var time := 0.0
var paused := false
var show_deriv := false
var deriv_t := 0.0
var ctr := Vector2(620.0, 372.0)
var f1 := Vector2.ZERO
var f2 := Vector2.ZERO

var t_def1: Texture2D
var t_def2: Texture2D
var t_def3: Texture2D
var t_rsum: Texture2D
var t_rdiff: Texture2D
var t_d1: Texture2D
var t_d2: Texture2D
var t_dpf: Texture2D
var t_dpl: Texture2D
var t_f1: Texture2D
var t_f2: Texture2D
var t_ff: Texture2D
var t_ll: Texture2D
var t_c1per: Texture2D
var t_c1min: Texture2D
var t_c1circ: Texture2D


func _ready() -> void:
	DrawUtil.ensure()
	t_def1 = DrawUtil.tex("def1")
	t_def2 = DrawUtil.tex("def2")
	t_def3 = DrawUtil.tex("def3")
	t_rsum = DrawUtil.tex("rsum")
	t_rdiff = DrawUtil.tex("rdiff")
	t_d1 = DrawUtil.tex("d1")
	t_d2 = DrawUtil.tex("d2")
	t_dpf = DrawUtil.tex("dpf")
	t_dpl = DrawUtil.tex("dpl")
	t_f1 = DrawUtil.tex("f1")
	t_f2 = DrawUtil.tex("f2")
	t_ff = DrawUtil.tex("ff")
	t_ll = DrawUtil.tex("ll")
	t_c1per = DrawUtil.tex("c1per")
	t_c1min = DrawUtil.tex("c1min")
	t_c1circ = DrawUtil.tex("c1circ")
	_set_mode(1)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_set_mode(int(arg.get_slice("=", 1)))
		elif arg.begins_with("--a="):
			a = float(arg.get_slice("=", 1))
			_recalc()
		elif arg.begins_with("--p="):
			p = float(arg.get_slice("=", 1))
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
		KEY_4:
			_set_mode(4)
		KEY_5:
			_set_mode(5)
		KEY_6:
			_set_mode(6)
		KEY_UP:
			_adjust(10.0)
		KEY_DOWN:
			_adjust(-10.0)
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
	mode = clampi(m, 1, 6)
	match mode:
		1, 2, 3:
			a = 220.0
			foc = 140.0
		5:
			ah = 90.0
			foc = 140.0
		6:
			p = 160.0
	time = 0.0
	_recalc()


func _adjust(d: float) -> void:
	match mode:
		1, 2, 3:
			a = clampf(a + d, foc + 25.0, 300.0)
		4:
			foc = clampf(foc + d, 70.0, 200.0)
		5:
			ah = clampf(ah + d, 40.0, foc - 20.0)
		6:
			p = clampf(p + d, 80.0, 240.0)
	_recalc()


func _recalc() -> void:
	b = sqrt(maxf(0.0, a * a - foc * foc))
	bh = sqrt(maxf(0.0, foc * foc - ah * ah))
	f1 = Vector2(-foc, 0.0)
	f2 = Vector2(foc, 0.0)


func _pgt() -> float:
	return clampf((time - TRACE_FROM) / (TRACE_TO - TRACE_FROM), 0.0, 1.0)


func _draw() -> void:
	DrawUtil.ensure()
	_recalc()
	var fo := 1.0 - smoothstep(CYCLE - 1.4, CYCLE, time)
	var intro := smoothstep(0.3, 1.6, time) * fo
	var def_a := smoothstep(1.0, 2.2, time) * fo
	var str_a := smoothstep(2.0, 3.2, time) * fo
	var rev := smoothstep(TRACE_TO - 0.9, TRACE_TO + 0.6, time) * fo
	var pgt := _pgt()

	match mode:
		1:
			_rope(intro, def_a, str_a, rev, fo, pgt)
		2:
			_circle(intro, def_a, str_a, rev, fo, pgt)
		3:
			_radius_app(intro, def_a, str_a, rev, fo, pgt)
		4:
			_three_states(intro, def_a, str_a, rev, fo, pgt)
		5:
			_hyperbola(intro, def_a, str_a, rev, fo, pgt)
		_:
			_parabola(intro, def_a, str_a, rev, fo, pgt)

	# 标题由游戏 UI 提供
	_narration(def_a)
	if mode == 3:
		var tB := smoothstep(0.42, 0.52, pgt)
		DrawUtil.tex_centered(self, t_c1per, Vector2(ctr.x, 118.0), def_a * (1.0 - tB))
		DrawUtil.tex_centered(self, t_c1min, Vector2(ctr.x, 118.0), def_a * tB)
	else:
		var ht := _header_tex()
		if ht != null:
			DrawUtil.tex_centered(self, ht, Vector2(ctr.x, 118.0), def_a)
	_hint(fo)
	if show_deriv:
		_draw_deriv()


# ---------------------------------------------------------------------------
#  1  绳作法机械构图
# ---------------------------------------------------------------------------
func _rope(intro: float, def_a: float, str_a: float, rev: float, fo: float, pgt: float) -> void:
	if intro > 0.01:
		draw_polyline(_ell(a, b, 0.0, TAU, 160), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.16 * intro), 2.0, true)
	_axes(def_a)
	_focus_marker(f1, t_f1, DrawUtil.COL_F1, def_a)
	_focus_marker(f2, t_f2, DrawUtil.COL_F2, def_a)

	if str_a > 0.01:
		var th := TAU * pgt
		var pl := Vector2(a * cos(th), b * sin(th))
		var r1 := pl.distance_to(f1)
		var r2 := pl.distance_to(f2)
		draw_line(ctr + f1, ctr + pl, DrawUtil.with_a(DrawUtil.COL_S1, str_a), 4.0, true)
		draw_line(ctr + pl, ctr + f2, DrawUtil.with_a(DrawUtil.COL_S2, str_a), 4.0, true)
		_trace_ell(th, fo)
		DrawUtil.tag_val(self, ctr + (f1 + pl) * 0.5 + (pl - f1).orthogonal().normalized() * 20.0,
				t_d1, "%.0f" % r1, 15, str_a)
		DrawUtil.tag_val(self, ctr + (f2 + pl) * 0.5 + (pl - f2).orthogonal().normalized() * -20.0,
				t_d2, "%.0f" % r2, 15, str_a)
		_pencil(ctr + pl, pl.normalized(), str_a)
		DrawUtil.text_center(self, 610.0, "|PF₁| + |PF₂| = %.0f + %.0f = %.0f  （绳长 2a，始终不变）" % [r1, r2, r1 + r2],
				19, DrawUtil.with_a(DrawUtil.COL_TXT, str_a))
		_sum_bar(Vector2(ctr.x, 648.0), 380.0, r1 / (2.0 * a), "|PF₁|", "|PF₂|", str_a)

	if rev > 0.01:
		_panel(rev)


# ---------------------------------------------------------------------------
#  2  圆交法构造
# ---------------------------------------------------------------------------
func _circle(intro: float, def_a: float, str_a: float, rev: float, fo: float, pgt: float) -> void:
	if intro > 0.01:
		draw_polyline(_ell(a, b, 0.0, TAU, 160), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.16 * intro), 2.0, true)
	_axes(def_a)
	_focus_marker(f1, t_f1, DrawUtil.COL_F1, def_a)
	_focus_marker(f2, t_f2, DrawUtil.COL_F2, def_a)

	if str_a > 0.01:
		var r1 := (a - foc) + 2.0 * foc * pgt
		var r2 := 2.0 * a - r1
		draw_arc(ctr + f1, r1, 0.0, TAU, 160, DrawUtil.with_a(DrawUtil.COL_F1, 0.5 * str_a), 2.0, true)
		draw_arc(ctr + f2, r2, 0.0, TAU, 160, DrawUtil.with_a(DrawUtil.COL_F2, 0.5 * str_a), 2.0, true)

		var x := a * (r1 - a) / foc
		var y2 := r1 * r1 - (x + foc) * (x + foc)
		if y2 >= 0.0:
			var yy := sqrt(y2)
			var pl := Vector2(x, yy)
			draw_line(ctr + f1, ctr + pl, DrawUtil.with_a(DrawUtil.COL_S1, str_a), 3.0, true)
			draw_line(ctr + f2, ctr + pl, DrawUtil.with_a(DrawUtil.COL_S2, str_a), 3.0, true)
			_dot(Vector2(x, -yy), "", DrawUtil.COL_FAINT, 0.6 * str_a)
			_dot(pl, "P", DrawUtil.COL_TXT, str_a)
			DrawUtil.tag_val(self, ctr + (f1 + pl) * 0.5 + Vector2(0.0, -22.0), t_d1, "%.0f" % r1, 15, str_a)
			DrawUtil.tag_val(self, ctr + (f2 + pl) * 0.5 + Vector2(0.0, -22.0), t_d2, "%.0f" % r2, 15, str_a)
			_trace_circle(x, fo)

		DrawUtil.tex_centered(self, t_c1circ, Vector2(ctr.x, 600.0), str_a)
		DrawUtil.text_center(self, 634.0, "以 F₁ 为心半径 r₁、F₂ 为心半径 r₂ 作两圆，交点即 P；r₁ 变化扫出椭圆",
				16, DrawUtil.with_a(DrawUtil.COL_DIM, str_a))
		_sum_bar(Vector2(ctr.x, 664.0), 380.0, r1 / (2.0 * a), "r₁", "r₂", str_a)

	if rev > 0.01:
		_panel(rev)


# ---------------------------------------------------------------------------
#  3  焦半径应用（周长 / 最值）
# ---------------------------------------------------------------------------
func _radius_app(intro: float, def_a: float, str_a: float, rev: float, fo: float, pgt: float) -> void:
	if intro > 0.01:
		draw_polyline(_ell(a, b, 0.0, TAU, 160), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.16 * intro), 2.0, true)
	_axes(def_a)
	_focus_marker(f1, t_f1, DrawUtil.COL_F1, def_a)
	_focus_marker(f2, t_f2, DrawUtil.COL_F2, def_a)

	var th := TAU * pgt
	var pl := Vector2(a * cos(th), b * sin(th))
	var r1 := pl.distance_to(f1)
	var tA := (1.0 - smoothstep(0.40, 0.50, pgt)) * str_a
	var tB := smoothstep(0.44, 0.54, pgt) * str_a

	# --- 焦点三角形：周长恒为 2a + 2c ---
	if tA > 0.01:
		draw_dashed_line(ctr + f1, ctr + f2, DrawUtil.with_a(DrawUtil.COL_DIM, 0.8 * tA), 2.0, 8.0, true, true)
		draw_line(ctr + f1, ctr + pl, DrawUtil.with_a(DrawUtil.COL_S1, tA), 3.0, true)
		draw_line(ctr + pl, ctr + f2, DrawUtil.with_a(DrawUtil.COL_S2, tA), 3.0, true)
		_dot2(pl, tA)
		DrawUtil.text_center(self, 596.0, "焦点三角形周长 = |PF₁| + |PF₂| + |F₁F₂| = %.0f  （2a + 2c = %.0f，恒定）"
				% [r1 + (2.0 * a - r1) + 2.0 * foc, 2.0 * a + 2.0 * foc], 18, DrawUtil.with_a(DrawUtil.COL_TXT, tA))

	# --- 定义法求 |PA| + |PF1| 最小值 ---
	if tB > 0.01:
		var pa := Vector2(60.0, -60.0)
		draw_line(ctr + f1, ctr + pl, DrawUtil.with_a(DrawUtil.COL_S1, tB), 3.0, true)
		draw_line(ctr + pa, ctr + pl, DrawUtil.with_a(DrawUtil.COL_S2, tB), 2.0, true)
		_dot(pa, "A", DrawUtil.COL_S2, tB)
		_dot2(pl, tB)
		var val := pa.distance_to(pl) + pl.distance_to(f1)
		DrawUtil.text_center(self, 596.0, "|PA| + |PF₁| = %.1f      （其中 |PF₁| = 2a − |PF₂|）" % val, 18,
				DrawUtil.with_a(DrawUtil.COL_TXT, tB))
		var pmin := _min_point(pa)
		var ring := 1.0 + 0.5 * sin(time * 6.0)
		draw_arc(ctr + pmin, 13.0, 0.0, TAU, 32, DrawUtil.with_a(DrawUtil.COL_TRACE, tB), 2.5 + ring, true)
		draw_line(ctr + pa, ctr + f2, DrawUtil.with_a(DrawUtil.COL_TRACE, 0.7 * tB), 2.0, true)
		var dmin := 2.0 * a - pa.distance_to(f2)
		DrawUtil.text_center(self, 636.0, "取最小值时 A、P、F₂ 共线：min = 2a − |AF₂| = %.1f − %.1f = %.1f"
				% [2.0 * a, pa.distance_to(f2), dmin], 17, DrawUtil.with_a(DrawUtil.COL_TRACE, tB))

	if rev > 0.01:
		_panel(rev)


func _min_point(pa: Vector2) -> Vector2:
	var d := (pa - f2).normalized()
	var x0 := pa.x
	var y0 := pa.y
	var a1 := d.x * d.x / (a * a) + d.y * d.y / (b * b)
	var b1 := 2.0 * (x0 * d.x / (a * a) + y0 * d.y / (b * b))
	var c1 := x0 * x0 / (a * a) + y0 * y0 / (b * b) - 1.0
	var s := (-b1 + sqrt(maxf(0.0, b1 * b1 - 4.0 * a1 * c1))) / (2.0 * a1)
	return pa + d * s


# ---------------------------------------------------------------------------
#  4  三态讨论
# ---------------------------------------------------------------------------
func _three_states(intro: float, def_a: float, str_a: float, rev: float, fo: float, pgt: float) -> void:
	var tri := absf(fmod(pgt * 2.0, 2.0) - 1.0)
	var a4 := 80.0 + (280.0 - 80.0) * tri
	var b4 := sqrt(maxf(0.0, a4 * a4 - foc * foc))
	var has_ell := a4 > foc + 0.6
	var is_seg := absf(a4 - foc) <= 0.6

	_axes(def_a)
	_focus_marker(f1, t_f1, DrawUtil.COL_F1, def_a)
	_focus_marker(f2, t_f2, DrawUtil.COL_F2, def_a)

	if has_ell and str_a > 0.01:
		draw_polyline(_ell(a4, b4, 0.0, TAU, 150), DrawUtil.with_a(DrawUtil.COL_TRACE, 0.9 * str_a), 3.0, true)
	elif is_seg and str_a > 0.01:
		draw_dashed_line(ctr + f1, ctr + f2, DrawUtil.with_a(DrawUtil.COL_S1, str_a), 4.0, 9.0, true, true)
	elif str_a > 0.01:
		draw_line(ctr + Vector2(-40.0, -40.0), ctr + Vector2(40.0, 40.0), DrawUtil.with_a(DrawUtil.COL_F1, 0.8 * str_a), 3.0, true)
		draw_line(ctr + Vector2(-40.0, 40.0), ctr + Vector2(40.0, -40.0), DrawUtil.with_a(DrawUtil.COL_F1, 0.8 * str_a), 3.0, true)

	_bars(a4 * 2.0, foc * 2.0, str_a)

	if str_a > 0.01:
		var msg := ""
		var col := DrawUtil.COL_S2
		if has_ell:
			msg = "2a > 2c：点的轨迹是椭圆"
		elif is_seg:
			msg = "2a = 2c：退化为线段 F₁F₂"
			col = DrawUtil.COL_S1
		else:
			msg = "2a < 2c：不存在这样的点（空集）"
			col = DrawUtil.COL_F1
		DrawUtil.text_center(self, 636.0, msg, 21, DrawUtil.with_a(col, str_a))

	if rev > 0.01:
		_panel(rev)


# ---------------------------------------------------------------------------
#  5  双曲线第一定义
# ---------------------------------------------------------------------------
func _hyperbola(intro: float, def_a: float, str_a: float, rev: float, fo: float, pgt: float) -> void:
	var tmax := asinh(275.0 / maxf(bh, 8.0))
	if intro > 0.01:
		var fa := DrawUtil.with_a(DrawUtil.COL_FAINT, 0.18 * intro)
		_asymptotes(fa)
		draw_polyline(_hyper(ah, bh, -tmax, tmax, 96, 1.0), fa, 2.0, true)
		draw_polyline(_hyper(ah, bh, -tmax, tmax, 96, -1.0), fa, 2.0, true)
	_axes(def_a)
	_focus_marker(f1, t_f1, DrawUtil.COL_F1, def_a)
	_focus_marker(f2, t_f2, DrawUtil.COL_F2, def_a)

	if str_a > 0.01:
		var t := -tmax + 2.0 * tmax * pgt
		var pl := Vector2(ah * cosh(t), bh * sinh(t))
		var r1 := pl.distance_to(f1)
		var r2 := pl.distance_to(f2)
		draw_line(ctr + f1, ctr + pl, DrawUtil.with_a(DrawUtil.COL_S1, str_a), 2.5, true)
		draw_line(ctr + f2, ctr + pl, DrawUtil.with_a(DrawUtil.COL_S2, str_a), 2.5, true)
		var ta := smoothstep(TRACE_FROM, TRACE_FROM + 0.7, time) * fo
		var n := maxi(4, int(round(180.0 * absf(t + tmax) / (2.0 * tmax))))
		draw_polyline(_hyper(ah, bh, -tmax, t, n, 1.0), DrawUtil.with_a(DrawUtil.COL_TRACE, ta), 3.0, true)
		DrawUtil.tag_val(self, ctr + (f1 + pl) * 0.5 + Vector2(0.0, -20.0), t_d1, "%.0f" % r1, 15, str_a)
		DrawUtil.tag_val(self, ctr + (f2 + pl) * 0.5 + Vector2(0.0, 20.0), t_d2, "%.0f" % r2, 15, str_a)
		_dot(pl, "P", DrawUtil.COL_TXT, str_a)
		DrawUtil.readout(self, ctr.x, 606.0, t_rdiff, "%.0f" % (r1 - r2), "（常数 2a = %.0f，只取一支）" % (2.0 * ah), str_a)

	if rev > 0.01:
		_panel(rev)


# ---------------------------------------------------------------------------
#  6  抛物线第一定义
# ---------------------------------------------------------------------------
func _parabola(intro: float, def_a: float, str_a: float, rev: float, fo: float, pgt: float) -> void:
	var tmax := 232.0
	var focus := Vector2(p * 0.5, 0.0)
	var direct_x := -p * 0.5

	if intro > 0.01:
		draw_polyline(_parab(p, -tmax, tmax, 110), DrawUtil.with_a(DrawUtil.COL_FAINT, 0.18 * intro), 2.0, true)
	if def_a > 0.01:
		var ac := DrawUtil.with_a(DrawUtil.COL_AXIS, 0.75 * def_a)
		draw_line(ctr + Vector2(-p * 0.5 - 60.0, 0.0), ctr + Vector2(tmax * tmax / (2.0 * p) + 40.0, 0.0), ac, 1.5, true)
		draw_line(ctr + Vector2(direct_x, -tmax - 20.0), ctr + Vector2(direct_x, tmax + 20.0),
				DrawUtil.with_a(DrawUtil.COL_F2, 0.9 * def_a), 2.5, true)
		DrawUtil.tag_tex(self, ctr + Vector2(direct_x, -tmax - 34.0), t_ll, def_a)
	_focus_marker(focus, t_ff, DrawUtil.COL_F1, def_a)

	var t := -tmax + 2.0 * tmax * pgt
	var pl := Vector2(t * t / (2.0 * p), t)
	var foot := Vector2(direct_x, t)
	if str_a > 0.01:
		draw_line(ctr + focus, ctr + pl, DrawUtil.with_a(DrawUtil.COL_S2, str_a), 2.5, true)
		draw_line(ctr + pl, ctr + foot, DrawUtil.with_a(DrawUtil.COL_S1, str_a), 2.5, true)
		draw_circle(ctr + foot, 5.0, DrawUtil.with_a(DrawUtil.COL_S1, str_a))
		DrawUtil.tag_val(self, ctr + (focus + pl) * 0.5 + Vector2(0.0, 20.0), t_dpf,
				"%.0f" % pl.distance_to(focus), 15, str_a)
		DrawUtil.tag_val(self, ctr + (pl + foot) * 0.5 + Vector2(0.0, -22.0), t_dpl,
				"%.0f" % pl.distance_to(foot), 15, str_a)
		var ta := smoothstep(TRACE_FROM, TRACE_FROM + 0.7, time) * fo
		var n := maxi(4, int(round(180.0 * pgt)))
		draw_polyline(_parab(p, -tmax, t, n), DrawUtil.with_a(DrawUtil.COL_TRACE, ta), 3.0, true)
		_dot(pl, "P", DrawUtil.COL_TXT, str_a)
		DrawUtil.readout(self, ctr.x, 606.0, t_dpf, "%.0f" % pl.distance_to(focus), "= d(P,l)  （相等）", str_a)
	if rev > 0.01:
		_panel(rev)


# ---------------------------------------------------------------------------
#  公共绘制
# ---------------------------------------------------------------------------
func _axes(a_alpha: float) -> void:
	if a_alpha <= 0.01:
		return
	var ac := DrawUtil.with_a(DrawUtil.COL_AXIS, 0.7 * a_alpha)
	var ax := maxf(a, foc) + 40.0
	draw_line(ctr + Vector2(-ax, 0.0), ctr + Vector2(ax, 0.0), ac, 1.5, true)
	draw_line(ctr + Vector2(0.0, -ax), ctr + Vector2(0.0, ax), ac, 1.5, true)
	draw_circle(ctr, 3.5, DrawUtil.with_a(DrawUtil.COL_TXT, a_alpha))
	DrawUtil.tag(self, ctr + Vector2(15.0, 13.0), "O", 14, DrawUtil.COL_DIM, a_alpha)


func _focus_marker(local: Vector2, t: Texture2D, col: Color, a: float) -> void:
	if a <= 0.01:
		return
	var pos := ctr + local
	draw_circle(pos, 7.0, DrawUtil.with_a(col, a))
	draw_arc(pos, 7.0, 0.0, TAU, 24, DrawUtil.with_a(DrawUtil.COL_TXT, 0.85 * a), 2.0, true)
	DrawUtil.tag_tex(self, pos + Vector2(0.0, -20.0), t, a)


func _dot(local: Vector2, nm: String, col: Color, a: float) -> void:
	if a <= 0.01:
		return
	var pos := ctr + local
	draw_circle(pos, 6.0, DrawUtil.with_a(col, a))
	draw_arc(pos, 10.0, 0.0, TAU, 28, DrawUtil.with_a(DrawUtil.COL_TRACE, 0.7 * a), 2.0, true)
	if not nm.is_empty():
		DrawUtil.tag(self, pos + Vector2(0.0, -30.0), nm, 16, col, a)


func _dot2(local: Vector2, a: float) -> void:
	if a <= 0.01:
		return
	draw_circle(ctr + local, 6.0, DrawUtil.with_a(DrawUtil.COL_TRACE, a))
	draw_arc(ctr + local, 11.0, 0.0, TAU, 28, DrawUtil.with_a(DrawUtil.COL_TRACE, 0.8 * a), 2.0, true)
	DrawUtil.tag(self, ctr + local + Vector2(0.0, -32.0), "P", 16, DrawUtil.COL_TXT, a)


func _pencil(pos: Vector2, dir: Vector2, a: float) -> void:
	if a <= 0.01 or dir.length() < 0.01:
		return
	var n := dir.orthogonal().normalized()
	var back := pos + dir.normalized() * 22.0
	var pts := PackedVector2Array([pos, back + n * 8.0, back - n * 8.0])
	draw_colored_polygon(pts, DrawUtil.with_a(DrawUtil.COL_TXT, 0.92 * a))
	draw_circle(pos, 6.0, DrawUtil.with_a(DrawUtil.COL_TRACE, 0.9 * a))


func _sum_bar(center: Vector2, w: float, frac: float, lname: String, rname: String, a: float) -> void:
	if a <= 0.01:
		return
	frac = clampf(frac, 0.0, 1.0)
	var x0 := center.x - w * 0.5
	var y := center.y
	draw_rect(Rect2(x0, y, w, 20.0), Color(0.06, 0.08, 0.12, 0.85 * a), true)
	draw_rect(Rect2(x0, y, w * frac, 20.0), DrawUtil.with_a(DrawUtil.COL_S1, 0.95 * a), true)
	draw_rect(Rect2(x0 + w * frac, y, w * (1.0 - frac), 20.0), DrawUtil.with_a(DrawUtil.COL_S2, 0.95 * a), true)
	draw_rect(Rect2(x0, y, w, 20.0), DrawUtil.with_a(DrawUtil.COL_DIM, 0.8 * a), false, 1.5)
	DrawUtil.text(self, Vector2(x0, y - 8.0), lname, 14, DrawUtil.with_a(DrawUtil.COL_S1, a))
	DrawUtil.text_right(self, Vector2(x0 + w, y - 8.0), rname, 14, DrawUtil.with_a(DrawUtil.COL_S2, a))


func _bars(v1: float, v2: float, a: float) -> void:
	if a <= 0.01:
		return
	var x0 := ctr.x - 200.0
	var k := 0.55
	var y1 := 556.0
	var y2 := 586.0
	draw_rect(Rect2(x0, y1, v1 * k, 16.0), DrawUtil.with_a(DrawUtil.COL_TRACE, 0.9 * a), true)
	draw_rect(Rect2(x0, y2, v2 * k, 16.0), DrawUtil.with_a(DrawUtil.COL_S1, 0.9 * a), true)
	draw_line(Vector2(x0 + v2 * k, y1 - 6.0), Vector2(x0 + v2 * k, y2 + 22.0),
			DrawUtil.with_a(DrawUtil.COL_DIM, 0.7 * a), 1.5, true)
	DrawUtil.text(self, Vector2(x0, y1 - 4.0), "2a = %.0f" % v1, 14, DrawUtil.with_a(DrawUtil.COL_TRACE, a))
	DrawUtil.text(self, Vector2(x0, y2 - 4.0), "2c = %.0f（固定）" % v2, 14, DrawUtil.with_a(DrawUtil.COL_S1, a))


func _trace_ell(th_end: float, fo: float) -> void:
	if absf(th_end) <= 0.002:
		return
	var ta := smoothstep(TRACE_FROM, TRACE_FROM + 0.7, time) * fo
	var n := maxi(4, int(round(180.0 * absf(th_end) / TAU)))
	draw_polyline(_ell(a, b, 0.0, th_end, n), DrawUtil.with_a(DrawUtil.COL_TRACE, ta), 3.0, true)


func _trace_circle(xcur: float, fo: float) -> void:
	if time < TRACE_FROM:
		return
	var ta := smoothstep(TRACE_FROM, TRACE_FROM + 0.7, time) * fo
	var phi := acos(clampf(xcur / a, -1.0, 1.0))
	var n := maxi(4, int(round(160.0 * (PI - phi) / PI)))
	var up := _ell(a, b, PI, phi, n)
	var dn := PackedVector2Array()
	for pt in up:
		dn.append(Vector2(pt.x, 2.0 * ctr.y - pt.y))
	draw_polyline(up, DrawUtil.with_a(DrawUtil.COL_TRACE, ta), 3.0, true)
	draw_polyline(dn, DrawUtil.with_a(DrawUtil.COL_TRACE, ta), 3.0, true)


func _asymptotes(a: Color) -> void:
	if a.a <= 0.01 or bh < 1.0:
		return
	var sl := bh / ah
	var dx := 320.0
	draw_line(ctr + Vector2(-dx, -sl * dx), ctr + Vector2(dx, sl * dx), a, 1.0, true)
	draw_line(ctr + Vector2(-dx, sl * dx), ctr + Vector2(dx, -sl * dx), a, 1.0, true)


# ---------------------------------------------------------------------------
#  面板 / 文案
# ---------------------------------------------------------------------------
func _panel(a_alpha: float) -> void:
	var x := 1006.0
	var y := 214.0
	var lines: Array = []
	match mode:
		1:
			lines = [
				"图钉：F₁(−c,0)、F₂(c,0)",
				"细绳总长 = 2a = %.0f" % (2.0 * a),
				"铅笔尖 P 绷紧细绳运动",
				"|PF₁| + |PF₂| = 2a",
				"描出的点集即椭圆",
			]
		2:
			lines = [
				"动圆半径 r₁ 由 a−c 增至 a+c",
				"圆₁: 心 F₁, 半径 r₁",
				"圆₂: 心 F₂, 半径 2a − r₁",
				"两圆交点 P 满足：",
				"|PF₁| + |PF₂| = r₁ + r₂ = 2a",
			]
		3:
			lines = [
				"a = %.1f  b = %.1f  c = %.1f" % [a, b, foc],
				"① 焦点三角形周长：",
				"　PF₁ + PF₂ + F₁F₂ = 2a + 2c",
				"② 焦半径范围：",
				"　|PF| ∈ [a − c, a + c]",
				"③ 最值（定义法）：",
				"　|PA| + |PF₁|",
				"　= 2a + (|PA| − |PF₂|)",
				"　≥ 2a − |AF₂|",
			]
		4:
			lines = [
				"c = %.1f（固定）" % foc,
				"2c = %.1f" % (2.0 * foc),
				"改变 2a 与 2c 比较：",
				"　2a > 2c → 椭圆",
				"　2a = 2c → 线段 F₁F₂",
				"　2a < 2c → 空集",
			]
		5:
			lines = [
				"a = %.1f  b = %.1f  c = %.1f" % [ah, bh, foc],
				"右支上 |PF₁| − |PF₂| = 2a",
				"左支上 |PF₂| − |PF₁| = 2a",
				"即 ||PF₁| − |PF₂|| = 2a",
				"（2a < 2c）",
			]
		_:
			lines = [
				"p = %.1f" % p,
				"焦点 F(%.1f, 0)" % (p * 0.5),
				"准线 l : x = %.1f" % (-p * 0.5),
				"|PF| = d(P,l)",
				"e = 1",
			]
	var h := 58.0 + lines.size() * 24.0 + 6.0
	draw_rect(Rect2(x - 18.0, y - 34.0, 238.0, h), Color(0.09, 0.11, 0.17, 0.6 * a_alpha), true)
	DrawUtil.text(self, Vector2(x, y), _panel_title(), 17, DrawUtil.with_a(DrawUtil.COL_TXT, a_alpha))
	for i in lines.size():
		DrawUtil.text(self, Vector2(x + 8.0, y + 32.0 + i * 24.0), lines[i], 14,
				DrawUtil.with_a(DrawUtil.COL_DIM, a_alpha))


func _panel_title() -> String:
	match mode:
		1:
			return "机械作图"
		2:
			return "圆交法"
		3:
			return "焦半径应用"
		4:
			return "三态讨论"
		5:
			return "双曲线"
		_:
			return "抛物线"


func _header_tex() -> Texture2D:
	match mode:
		1, 2, 4:
			return t_def1
		5:
			return t_def2
		6:
			return t_def3
	return null


func _narration(a: float) -> void:
	if a <= 0.01:
		return
	var s := _subtitle()
	if s.is_empty():
		return
	var fs := UI.fs(17)
	var f := DrawUtil.font_for(s)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var bw := w + 32.0
	var bh := fs * 1.9
	var rect := Rect2(640.0 - bw * 0.5, 64.0, bw, bh)
	draw_rect(rect, Color(0.10, 0.14, 0.22, 0.62 * a), true)
	draw_rect(rect, DrawUtil.with_a(DrawUtil.COL_TRACE, 0.5 * a), false, 1.0)
	DrawUtil.text_center(self, 64.0 + fs * 1.35, s, 17, DrawUtil.with_a(DrawUtil.COL_TXT, a))


func _subtitle() -> String:
	var t := time
	match mode:
		1:
			if t < 1.5:
				return "① 先在纸上固定两枚图钉 F₁、F₂，距离为 2c"
			elif t < 3.5:
				return "② 取一根长为 2a 的细绳，两端分别系在两枚图钉上"
			elif t < TRACE_TO - 0.5:
				return "③ 用铅笔尖绷紧细绳移动：两段绳长之和 |PF₁| + |PF₂| 始终等于 2a"
			return "④ 一切满足「到 F₁、F₂ 距离之和 = 2a」的点 P 描出一条椭圆"
		2:
			if t < 1.5:
				return "① 以 F₁ 为圆心、任意半径 r₁ 作一个圆"
			elif t < 3.5:
				return "② 以 F₂ 为圆心、半径 r₂ = 2a − r₁ 再作一个圆"
			elif t < TRACE_TO - 0.5:
				return "③ 两圆交点 P 满足 |PF₁| = r₁、|PF₂| = r₂，故 |PF₁| + |PF₂| = 2a"
			return "④ 让 r₁ 连续变化，交点 P 的轨迹是一条椭圆"
		3:
			if t < 4.5:
				return "① 焦点三角形 △PF₁F₂ 的周长 = |PF₁| + |PF₂| + |F₁F₂| = 2a + 2c，与点 P 无关"
			return "② 定义法求最值：|PA| + |PF₁| = 2a +（|PA| − |PF₂|）≥ 2a − |AF₂|，取等时 A、P、F₂ 共线"
		4:
			return "不断改变 2a，并与固定的 2c 比较：2a > 2c 是椭圆，2a = 2c 是线段 F₁F₂，2a < 2c 为空集"
		5:
			if t < 1.5:
				return "① 取两定点 F₁、F₂，距离为 2c"
			elif t < 3.5:
				return "② 取常数 2a，且 2a < 2c"
			elif t < TRACE_TO - 0.5:
				return "③ 动点 P 到两焦点距离之差的绝对值 ||PF₁| − |PF₂|| 恒等于 2a"
			return "④ 满足条件的点 P 的轨迹是双曲线（取一支）"
		_:
			if t < 1.5:
				return "① 给定一个定点 F 和一条不过 F 的定直线 l（准线）"
			elif t < TRACE_TO - 0.5:
				return "② 动点 P 到定点 F 的距离，恒等于它到定直线 l 的距离"
			return "③ 满足「到定点与定直线距离相等」的点 P 的轨迹是抛物线"


func _hint(fo: float) -> void:
	pass


func _deriv_dur() -> float:
	return maxf(0.001, float(Deriv.count(DERIV_ID)) / DERIV_FPS)


func _deriv_step(prog: float) -> int:
	return clampi(int(prog * 7.0) + 1, 1, 7)


func _draw_deriv() -> void:
	var app := clampf(deriv_t / 0.35, 0.0, 1.0)
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.03, 0.04, 0.07, 0.82 * app), true)
	DrawUtil.text_center(self, 150.0, "公式推导 · 由第一定义推标准方程（Manim）", 22,
			DrawUtil.with_a(DrawUtil.COL_S2, app))
	var dur := _deriv_dur()
	var prog := clampf(deriv_t / dur, 0.0, 1.0)
	if Deriv.count(DERIV_ID) == 0:
		DrawUtil.text_center(self, 360.0, "推导素材未生成：请运行  tools\\render_manim.ps1 -Id c1",
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
	DrawUtil.text_right(self, Vector2(bx + bw, by - 22.0), "第 %d / 7 步" % _deriv_step(prog), 15,
			DrawUtil.with_a(DrawUtil.COL_S2, app))
	DrawUtil.text_center(self, 700.0, "← / → 逐步查看　·　空格 暂停 / 继续　·　D 关闭",
			15, DrawUtil.with_a(DrawUtil.COL_DIM, app))


# ---------------------------------------------------------------------------
#  曲线采样
# ---------------------------------------------------------------------------
func _ell(a_: float, b_: float, th0: float, th1: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in range(n + 1):
		var th := th0 + (th1 - th0) * float(i) / float(n)
		pts[i] = ctr + Vector2(a_ * cos(th), b_ * sin(th))
	return pts


func _hyper(a_: float, b_: float, t0: float, t1: float, n: int, side: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in range(n + 1):
		var t := t0 + (t1 - t0) * float(i) / float(n)
		pts[i] = ctr + Vector2(side * a_ * cosh(t), b_ * sinh(t))
	return pts


func _parab(p_: float, t0: float, t1: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in range(n + 1):
		var t := t0 + (t1 - t0) * float(i) / float(n)
		pts[i] = ctr + Vector2(t * t / (2.0 * p_), t)
	return pts
