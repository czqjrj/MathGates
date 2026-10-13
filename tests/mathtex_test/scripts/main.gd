extends Node

var _failures := 0

func _ready() -> void:
	print("=== MathTeX GDExtension test (Godot ", Engine.get_version_info().string, ") ===")
	var res_ok: bool = MathTeX.configure("res://gdextension/res")
	print("configure() -> ", res_ok, "  is_ready=", MathTeX.is_ready(), "  res_path=", MathTeX.get_res_path())
	if not res_ok:
		print("FAIL: configure() returned false")
		get_tree().quit(1)
		return

	_check(24.0)
	_check(40.0, Color(0.2, 0.6, 1.0, 1.0))

	print("=== done. failures=", _failures)
	get_tree().quit(_failures)


func _check(font_size: float, col := Color.WHITE) -> void:
	var cases := {
		"frac": "\\frac{2x^3}{y^2+1}",
		"sqrt": "\\sqrt[3]{x^2+y}",
		"int": "\\int_0^1 \\frac{\\,dx}{1+x^2}",
		"sum": "\\sum_{i=1}^{n} i^2 = \\frac{n(n+1)(2n+1)}{6}",
		"matrix": "\\begin{bmatrix} a & b \\\\ c & d \\end{bmatrix}",
		"textcjk": "x^2 \\text{中文} + 5",
		"big": "\\left( 1+\\frac{1}{n} \\right)^n \\to e",
		"beta": "\\beta = \\dfrac{\\Delta y}{\\Delta x}",
	}
	for name in cases:
		var latex: String = cases[name]
		var img := MathTeX.render(latex, font_size, col)
		if img.is_empty():
			print("F", name, ": render returned null")
			_failures += 1
			continue
		var path := "res://out_%s_%d.png" % [name, int(font_size)]
		var err := img.save_png(path)
		print(name.lpad(8), " size=", img.get_width(), "x", img.get_height(), "  save=", err)
		if err != OK:
			_failures += 1

	var tex := MathTeX.render_latex("\\frac{1}{2}+\\frac{1}{3}", font_size, col)
	if tex == null or tex.get_image() == null:
		print("FAIL: render_latex returned null")
		_failures += 1
	else:
		print("render_latex ok: ", tex.get_image().get_width(), "x", tex.get_image().get_height())