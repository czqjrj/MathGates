extends SceneTree
## 双端比对用：把指定 LaTeX 渲染到 <temp>/mt_compare/<md5>.png（与设备端缓存同名）。
## 用法：godot --headless --path . --script res://tools/mt_render_cases.gd

const CASES := [
	["\\to", 22],
	["a_{2},a_{3},\\dots", 26],
	["a_{1} = 1", 26],
	["a_{n+1} - a_{n} = 2n", 26],
	["a_{3}-a_{2}=f(2)", 26],
	["a_{n} - a_{1}", 26],
	["a_{2}-a_{1}=f(1)", 26],
]

func _initialize() -> void:
	InlineMath._mt_ready()
	var mt = Engine.get_singleton("MathTeX")
	var dir := OS.get_temp_dir().path_join("mt_compare")
	DirAccess.make_dir_recursive_absolute(dir)
	for c in CASES:
		var latex: String = c[0]
		var h: int = c[1]
		var key := "%s|%s|%d|%s" % [InlineMath.MT_CACHE_VERSION, latex, h, InlineMath.MT_COLOR.to_html(true)]
		var md5 := key.md5_text()
		var img: Image = mt.render(latex, float(maxi(8, h)), InlineMath.MT_COLOR)
		if img == null:
			print("null ", latex)
			continue
		img.save_png(dir.path_join(md5 + ".png"))
		print("%s  %dx%d  %s" % [md5.substr(0, 6), img.get_width(), img.get_height(), latex])
	quit(0)
