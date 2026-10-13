extends SceneTree
## MicroTeX 渲染性能探针（开发用）：configure 冷启动、冷/热渲染耗时、缓存命中。
## 用法：godot --headless --path . --script res://tools/mt_bench.gd

const CASES := [
	"x^2+y^2=r^2", "\\frac{a}{b}", "\\sqrt{x+1}", "\\int_0^1 x^2\\,dx",
	"\\sum_{i=1}^{n} i", "\\lim_{x\\to 0}\\frac{\\sin x}{x}",
	"\\begin{bmatrix}a&b\\\\c&d\\end{bmatrix}", "\\vec{AB}\\cdot\\vec{CD}",
	"\\alpha+\\beta=\\gamma", "a_n=a_1+(n-1)d", "\\log_a x", "\\sin^2\\theta+\\cos^2\\theta=1",
	"\\left(1+\\frac1n\\right)^n", "\\Delta=b^2-4ac", "\\dfrac{dy}{dx}",
	"\\binom{n}{k}", "\\overline{AB}", "\\theta=\\frac{\\pi}{3}", "e^{i\\pi}+1=0", "\\forall x\\in\\mathbb{R}",
]

func _initialize() -> void:
	var t0 := Time.get_ticks_usec()
	var ready: bool = InlineMath._mt_ready()
	var t1 := Time.get_ticks_usec()
	print("ready=", ready, "  configure_ms=%.1f" % ((t1 - t0) / 1000.0))

	var mt = Engine.get_singleton("MathTeX")
	# 冷渲染（首次光栅化）
	var t2 := Time.get_ticks_usec()
	for c in CASES:
		mt.render(c, 26.0, InlineMath.MT_COLOR)
	var t3 := Time.get_ticks_usec()
	print("cold  x%d total_ms=%.1f avg_ms=%.2f" % [CASES.size(), (t3 - t2) / 1000.0, (t3 - t2) / 1000.0 / CASES.size()])

	# 热渲染（重复相同输入）
	var t4 := Time.get_ticks_usec()
	for c in CASES:
		mt.render(c, 26.0, InlineMath.MT_COLOR)
	var t5 := Time.get_ticks_usec()
	print("warm  x%d total_ms=%.1f avg_ms=%.2f" % [CASES.size(), (t5 - t4) / 1000.0, (t5 - t4) / 1000.0 / CASES.size()])

	# inline 缓存路径（进程内 md5 命中）
	var t6 := Time.get_ticks_usec()
	for c in CASES:
		InlineMath._mt_inline_bbcode(c, 26, InlineMath.MT_COLOR)
	var t7 := Time.get_ticks_usec()
	print("inline x%d total_ms=%.1f avg_ms=%.3f" % [CASES.size(), (t7 - t6) / 1000.0, (t7 - t6) / 1000.0 / CASES.size()])

	print("static_mem_MB=%.1f  tex_mem_MB=%.1f" % [
		float(OS.get_static_memory_usage()) / 1048576.0,
		float(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)) / 1048576.0])
	quit(0)
