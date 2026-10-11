extends SceneTree

func _initialize() -> void:
	var files: Array[String] = []
	_collect("res://", files)
	var fails := 0
	for f in files:
		var res: Variant = load(f)
		if res == null:
			fails += 1
			print("FAILED: ", f)
	print("CHECKED %d scripts, %d failures" % [files.size(), fails])
	quit()

func _collect(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n.begins_with("."):
			n = d.get_next()
			continue
		var full := dir_path.path_join(n)
		if d.current_is_dir():
			_collect(full, out)
		elif n.ends_with(".gd"):
			out.append(full)
		n = d.get_next()
	d.list_dir_end()
