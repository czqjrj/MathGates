extends SceneTree
## 验证「导出态资源路径」链路：res.bin → 解压到 user:// → configure → 渲染。
## 用法：godot --headless --path . --script res://tools/mt_extract_test.gd

func _initialize() -> void:
	print("cache_dir=", InlineMath._mt_cache_dir())
	print("dev_resolve=", InlineMath._mt_resolve())
	print("mt_ready=", InlineMath._mt_ready())
	var dst := OS.get_temp_dir().path_join("mathtex_res_test")
	_rm(dst)
	var ok: bool = InlineMath._mt_extract_zip("res://gdextension/res.bin", dst)
	print("extract ok=", ok)
	print("marker=", FileAccess.file_exists(dst + "/.clatexmath-res_root"))
	print("font=", FileAccess.file_exists(dst + "/fonts/latin/cmr10.ttf"))
	var mt = Engine.get_singleton("MathTeX")
	var real := ProjectSettings.globalize_path(dst)
	mt.configure(real)
	print("ready=", mt.is_ready(), " path=", real)
	var img: Image = mt.render("\\frac{1}{2}+\\sqrt{x}", 32.0, Color.WHITE)
	if img == null:
		print("render=null")
	else:
		print("render=%dx%d" % [img.get_width(), img.get_height()])
	quit(0)

func _rm(p: String) -> void:
	var d := DirAccess.open(p)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var f := p + "/" + n
		if d.current_is_dir():
			_rm(f)
		else:
			DirAccess.remove_absolute(f)
		n = d.get_next()
	d.list_dir_end()
	DirAccess.remove_absolute(p)
