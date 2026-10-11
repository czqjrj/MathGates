class_name TechBg
extends Control
## 动态科技背景：深空渐变 + 漂移网格 + 极光辉光 + 扫描光束 + 星尘
## + 漂浮数学公式 + 数学图形动画(多边形/抛物线/正弦波/旋转角)。
## 纯代码/着色器绘制，无任何图片资源。场景 _ready 第一行 add_child(TechBg.new())。
## 结构：着色器底图(ColorRect)在下，内容层(Fx)在上，两者全屏。

const SHADER_CODE := """
shader_type canvas_item;

uniform vec3 c_top : source_color = vec3(0.035, 0.055, 0.095);
uniform vec3 c_bottom : source_color = vec3(0.062, 0.102, 0.180);
uniform vec3 accent : source_color = vec3(0.369, 0.902, 1.0);
uniform vec2 resolution = vec2(1280.0, 720.0);
uniform float time = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float grid_line(vec2 px, float spacing, float width) {
	vec2 g = abs(fract(px / spacing - 0.5) - 0.5) * spacing;
	float d = min(g.x, g.y);
	return 1.0 - smoothstep(0.0, width, d);
}

void fragment() {
	vec2 uv = UV;
	float aspect = resolution.x / max(resolution.y, 1.0);
	vec2 px = uv * resolution;

	vec3 col = mix(c_top, c_bottom, uv.y);

	// 极光辉光(缓慢漂移)
	vec2 p1 = vec2(0.30 + 0.10 * sin(time * 0.06), 0.32 + 0.08 * cos(time * 0.045));
	float d1 = length((uv - p1) * vec2(aspect, 1.0));
	col += accent * 0.16 * exp(-d1 * 3.6);

	vec2 p2 = vec2(0.74 + 0.08 * cos(time * 0.05 + 1.7), 0.70 + 0.07 * sin(time * 0.04 + 0.9));
	float d2 = length((uv - p2) * vec2(aspect, 1.0));
	col += accent * 0.11 * exp(-d2 * 4.2);

	// 漂移网格(双尺度)
	vec2 gp = px + vec2(time * 3.0, time * 1.4);
	float g1 = grid_line(gp, 96.0, 1.1);
	float g2 = grid_line(gp, 24.0, 0.8) * 0.4;
	col += accent * (g1 * 0.10 + g2 * 0.05);

	// 上下扫描光束(呼吸下移)
	float beam = exp(-pow(abs(fract(time * 0.06 + 0.4) - uv.y) * 16.0, 2.0));
	col += accent * 0.10 * beam * (0.55 + 0.45 * sin(time * 2.0));

	// 暗角
	float vd = length((uv - vec2(0.5)) * vec2(aspect * 0.7, 1.0));
	col *= mix(0.78, 1.0, smoothstep(0.9, 0.2, vd));

	// 细颗粒
	col += (hash(px + vec2(fract(time) * 43.0)) - 0.5) * 0.02;

	COLOR = vec4(col, 1.0);
}
"""

## 漂浮公式池(仅使用常见数学字体覆盖的字形)
const FORMULAS: Array[String] = [
	"x² + y² = r²",
	"sin²θ + cos²θ = 1",
	"e^(iπ) + 1 = 0",
	"∫ f(x) dx",
	"Σ k = n(n+1)/2",
	"√(a² + b²) = c",
	"Δ = b² − 4ac",
	"y = ax² + bx + c",
	"π ≈ 3.14159265",
	"n! = n × (n−1)!",
	"(a+b)² = a² + 2ab + b²",
	"x = (−b ± √(b²−4ac)) / 2a",
	"∠AOB = 90°",
	"V = (4/3)πR³",
	"S = πR²",
	"log₂ 8 = 3",
	"a ⊥ b",
	"P(A∪B) = P(A) + P(B)",
	"−1 ≤ sin x ≤ 1",
	"tan θ = sin θ / cos θ",
	"a² = b² + c² − 2bc·cos A",
	"180° = π rad",
	"C(n,k) = n!/(k!(n−k)!)",
	"f′(x) = lim Δy/Δx",
]

const N_FORMS := 20
const N_FIGS := 8

class Star:
	var pos := Vector2.ZERO
	var r := 1.0
	var tw := 1.0
	var ph := 0.0
	var vy := 0.006

class Form:
	var text := ""
	var pos := Vector2.ZERO   # 归一化坐标
	var px := 18              # 字号
	var vy := 0.0             # 归一化速度(+/− 向下/向上)
	var vx := 0.0
	var ph := 0.0
	var fr := 0.3             # 明暗闪烁频率

class Fig:
	var kind := 0             # 0多边形 1抛物线 2正弦波 3旋转角
	var pos := Vector2.ZERO   # 归一化中心
	var rad := 60.0           # 半径(px)
	var ph := 0.0
	var n := 4                # 多边形边数
	var spin := 0.2           # 自转速度
	var vx := 0.0             # 水平缓移
	var par := Vector3.ZERO   # 抛物线 a,b,c
	var wav := Vector3.ZERO   # 正弦 频率，相速，振幅

## 内容层：置于着色器底图(ColorRect)之上，承载星尘/公式/图形绘制
class Fx extends Control:
	var owner_bg: TechBg

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if owner_bg != null:
			owner_bg._paint(self)

var _t: float = 0.0
var _shade_mat: ShaderMaterial
var _fx: Fx
var _stars: Array[Star] = []
var _forms: Array[Form] = []
var _figs: Array[Fig] = []
static var _math_font: Font

## 数学符号字体栈：Cambria Math 覆盖绝大多数字形，其余按字形回退
static func math_font() -> Font:
	if _math_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray([
			"Cambria Math", "Segoe UI Symbol", "DejaVu Sans",
			"Microsoft YaHei UI", "sans-serif"
		])
		_math_font = f
	return _math_font

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shade := ColorRect.new()
	shade.color = Color.WHITE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER_CODE
	mat.shader = sh
	shade.material = mat
	add_child(shade)
	full_rect(shade)
	_shade_mat = mat
	mat.set_shader_parameter("resolution", size)
	shade.resized.connect(func() -> void:
		mat.set_shader_parameter("resolution", shade.size)
	)

	_fx = Fx.new()
	_fx.owner_bg = self
	add_child(_fx)
	full_rect(_fx)

	for i in 120:
		var s := Star.new()
		s.pos = Vector2(randf(), randf())
		s.r = randf_range(0.6, 2.2)
		s.tw = randf_range(0.4, 1.4)
		s.ph = randf_range(0.0, TAU)
		s.vy = randf_range(0.002, 0.012)
		_stars.append(s)

	for i in N_FORMS:
		var m := Form.new()
		m.text = FORMULAS.pick_random()
		m.pos = Vector2(randf_range(0.04, 0.88), randf_range(0.03, 0.96))
		m.px = randi_range(19, 34)
		var up := 1.0 if randf() < 0.5 else -1.0
		m.vy = randf_range(0.004, 0.013) * up
		m.vx = randf_range(-0.004, 0.004)
		m.ph = randf_range(0.0, TAU)
		m.fr = randf_range(0.15, 0.5)
		_forms.append(m)

	var kinds: Array[int] = [0, 1, 2, 3, 0, 2, 1, 3]
	for i in N_FIGS:
		var g := Fig.new()
		g.kind = kinds[i]
		g.pos = Vector2(randf_range(0.10, 0.90), randf_range(0.14, 0.86))
		g.rad = randf_range(56, 130)
		g.ph = randf_range(0.0, TAU)
		g.vx = randf_range(-0.006, 0.006) * (1.0 if randf() < 0.5 else -1.0)
		g.n = randi_range(3, 6)
		g.spin = randf_range(-0.35, 0.35)
		if g.spin == 0.0:
			g.spin = 0.2
		if g.kind == 1:
			var a := randf_range(0.35, 0.8) * (1.0 if randf() < 0.5 else -1.0)
			g.par = Vector3(a, randf_range(-0.5, 0.5), randf_range(-0.35, 0.35))
		else:
			g.wav = Vector3(randf_range(1.0, 2.5), randf_range(0.4, 1.2), randf_range(0.4, 0.7))
		_figs.append(g)

	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	if _shade_mat != null:
		_shade_mat.set_shader_parameter("time", _t)
	for s in _stars:
		s.pos.y -= s.vy * delta
		if s.pos.y < -0.02:
			s.pos.y = 1.02
			s.pos.x = randf()
	for m in _forms:
		m.pos.y += m.vy * delta
		m.pos.x += m.vx * delta
		if m.pos.y < -0.08:
			m.pos.y = 1.06
			m.pos.x = randf_range(0.05, 0.88)
		elif m.pos.y > 1.08:
			m.pos.y = -0.06
			m.pos.x = randf_range(0.05, 0.88)
		if m.pos.x < 0.02 or m.pos.x > 0.96:
			m.vx = -m.vx
			m.pos.x = clampf(m.pos.x, 0.02, 0.96)
	for g in _figs:
		g.pos.x += g.vx * delta
		if g.pos.x < 0.06 or g.pos.x > 0.94:
			g.vx = -g.vx
			g.pos.x = clampf(g.pos.x, 0.06, 0.94)
	if _fx != null:
		_fx.queue_redraw()

## 中心区域自动减淡，保证前景可读
func _col(alpha: float, npos: Vector2) -> Color:
	var d := (npos - Vector2(0.5, 0.5)).length() * 2.0
	var atten := clampf(0.75 + 0.25 * d, 0.0, 1.0)
	return Color(0.44, 0.86, 1.0, alpha * atten)

## 内容层绘制(ci 为 Fx 节点，在其 _draw() 内以它为目标画布)
func _paint(ci: Control) -> void:
	for s in _stars:
		var a := 0.35 + 0.55 * (0.5 + 0.5 * sin(_t * s.tw + s.ph))
		var p := s.pos * ci.size
		if s.r > 1.5:
			ci.draw_circle(p, s.r * 3.5, Color(0.37, 0.9, 1.0, a * 0.18))
		ci.draw_circle(p, s.r, Color(0.82, 0.93, 1.0, a))
	_draw_forms(ci)
	for g in _figs:
		_draw_fig(g, ci)

func _draw_forms(ci: Control) -> void:
	var f := math_font()
	for m in _forms:
		var env := 0.7 + 0.3 * sin(_t * m.fr + m.ph)
		var edge := smoothstep(0.0, 0.10, m.pos.y) * (1.0 - smoothstep(0.90, 1.0, m.pos.y))
		var c := _col(0.30 * env * edge, m.pos)
		if c.a < 0.006:
			continue
		ci.draw_string(f, m.pos * ci.size, m.text, HORIZONTAL_ALIGNMENT_LEFT, -1, m.px, c)

func _draw_fig(g: Fig, ci: Control) -> void:
	var env := 0.7 + 0.3 * sin(_t * 0.45 + g.ph)
	var base := 0.24 * env
	var c := g.pos * ci.size
	match g.kind:
		0: _fig_poly(c, g, base, ci)
		1: _fig_parab(c, g, base, ci)
		2: _fig_wave(c, g, base, ci)
		3: _fig_angle(c, g, base, ci)

## 外接虚圆 + 旋转正多边形 + 顶点
func _fig_poly(c: Vector2, g: Fig, base: float, ci: Control) -> void:
	var rot := _t * g.spin + g.ph
	var line := _col(base, g.pos)
	var faint := _col(base * 0.45, g.pos)
	var rr := g.rad * 1.24
	var segs := 36
	for i in segs:
		if i % 2 == 1:
			continue
		var a0 := TAU * float(i) / float(segs) + rot * 0.3
		var a1 := TAU * float(i + 0.7) / float(segs) + rot * 0.3
		ci.draw_arc(c, rr, a0, a1, 4, faint, 1.0)
	var pts := PackedVector2Array()
	for i in g.n + 1:
		var ang := rot + TAU * float(i % g.n) / float(g.n) - PI / 2.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * g.rad)
	ci.draw_polyline(pts, line, 1.6, true)
	for i in g.n:
		ci.draw_circle(pts[i], 2.4, _col(base * 1.6, g.pos))

## 坐标轴 + 抛物线自绘(循环：绘出→淡出→重绘)
func _fig_parab(c: Vector2, g: Fig, base: float, ci: Control) -> void:
	var w := g.rad * 1.35
	var axis := _col(base * 0.6, g.pos)
	ci.draw_line(c + Vector2(-w, 0), c + Vector2(w, 0), axis, 1.0)
	ci.draw_line(c + Vector2(0, -w * 0.72), c + Vector2(0, w * 0.72), axis, 1.0)
	ci.draw_line(c + Vector2(w, 0), c + Vector2(w - 7, -4), axis, 1.0)
	ci.draw_line(c + Vector2(w, 0), c + Vector2(w - 7, 4), axis, 1.0)
	ci.draw_line(c + Vector2(0, -w * 0.72), c + Vector2(-4, -w * 0.72 + 7), axis, 1.0)
	ci.draw_line(c + Vector2(0, -w * 0.72), c + Vector2(4, -w * 0.72 + 7), axis, 1.0)

	var prog := fposmod(_t * 0.13 + g.ph / TAU, 1.0)
	var frac := clampf(prog / 0.55, 0.0, 1.0)
	var fade := smoothstep(0.0, 0.1, prog) * (1.0 - smoothstep(0.65, 0.98, prog))
	var a := base * fade
	if a < 0.004:
		return
	var steps := 44
	var pts := PackedVector2Array()
	var last := Vector2.ZERO
	for i in int(steps * frac) + 1:
		var x := -1.0 + 2.0 * float(i) / float(steps)
		var y := clampf(g.par.x * x * x + g.par.y * x + g.par.z, -1.1, 1.1)
		last = c + Vector2(x * w, -y * w * 0.66)
		pts.append(last)
	if pts.size() >= 2:
		ci.draw_polyline(pts, _col(a, g.pos), 2.0, true)
		if frac < 1.0:
			ci.draw_circle(last, 3.0, _col(a * 1.6, g.pos))

## 坐标轴 + 滚动正弦曲线
func _fig_wave(c: Vector2, g: Fig, base: float, ci: Control) -> void:
	var w := g.rad * 1.35
	var axis := _col(base * 0.6, g.pos)
	ci.draw_line(c + Vector2(-w, 0), c + Vector2(w, 0), axis, 1.0)
	ci.draw_line(c + Vector2(0, -w * 0.72), c + Vector2(0, w * 0.72), axis, 1.0)

	var pts := PackedVector2Array()
	var amp := w * 0.5 * g.wav.z
	var steps := 56
	for i in steps + 1:
		var x := -1.0 + 2.0 * float(i) / float(steps)
		var ph := g.wav.x * x * PI + _t * g.wav.y + g.ph
		pts.append(c + Vector2(x * w, sin(ph) * amp))
	ci.draw_polyline(pts, _col(base * 1.1, g.pos), 1.8, true)

## 圆 + 旋转终边 + 角弧 + 实时角度
func _fig_angle(c: Vector2, g: Fig, base: float, ci: Control) -> void:
	ci.draw_arc(c, g.rad, 0.0, TAU, 56, _col(base * 0.7, g.pos), 1.2)
	ci.draw_line(c + Vector2(-g.rad, 0), c + Vector2(g.rad, 0), _col(base * 0.45, g.pos), 1.0)
	ci.draw_line(c + Vector2(0, -g.rad), c + Vector2(0, g.rad), _col(base * 0.45, g.pos), 1.0)

	var ang := fposmod(_t * 0.55 + g.ph, TAU)
	var tip := c + Vector2(cos(ang), sin(ang)) * g.rad
	ci.draw_line(c, tip, _col(base * 1.2, g.pos), 1.6)
	ci.draw_circle(tip, 3.0, _col(base * 1.8, g.pos))
	ci.draw_circle(c, 2.4, _col(base * 1.4, g.pos))
	ci.draw_arc(c, g.rad * 0.32, 0.0, ang, 28, _col(base * 1.3, g.pos), 1.6)

	var deg := int(rad_to_deg(ang))
	var lp := c + Vector2(cos(ang * 0.5), sin(ang * 0.5)) * g.rad * 0.55
	ci.draw_string(math_font(), lp + Vector2(-10, 4), "%d°" % deg, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, _col(base * 2.2, g.pos))

func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
