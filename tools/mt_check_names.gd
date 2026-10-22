extends SceneTree
## 诊断：把 FORMULA_LATEX 里的命名公式逐个渲染成 PNG（排查运行时渲染 vs PNG 回退）。
## 注：A10 迁移后 FORMULA_LATEX 已清空（全库改用 $$LaTeX$$），本工具仅在重新引入
## 命名公式时才有意义，届时会打印 `mt-ok N / N`。
func _initialize() -> void:
	InlineMath._mt_ready()
	var mt = Engine.get_singleton("MathTeX")
	var dir := OS.get_temp_dir().path_join("mt_names")
	DirAccess.make_dir_recursive_absolute(dir)
	var ok := 0
	for name in InlineMath.FORMULA_LATEX:
		var bb: String = InlineMath.formula_img(name, 26)
		var is_mt := bb.find(".mttex") >= 0
		var is_png := bb.find("/formulas/") >= 0
		var img: Image = mt.render(InlineMath.FORMULA_LATEX[name], 26.0, InlineMath.MT_COLOR)
		if img != null:
			img.save_png(dir.path_join(name + ".png"))
		print("%s  mt=%s png=%s  %s" % [name, is_mt, is_png, bb.substr(0, bb.find("]") + 1)])
		if is_mt:
			ok += 1
		print("     语音：", InlineMath.strip_formulas("{f:%s}" % name))
	print("mt-ok %d / %d" % [ok, InlineMath.FORMULA_LATEX.size()])
	quit(0)
