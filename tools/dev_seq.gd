extends Control
## 开发用：直接驱动 SequencePlane，遍历 data/recurrence_levels.json 所有方法/关卡/动画相位，
## 暴露运行期绘图错误。运行：godot --path . res://tools/dev_seq.tscn

var _fails := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	GameData.create_user("dev", "player")
	GameData.login("dev")
	await get_tree().process_frame
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/recurrence_levels.json"))
	if typeof(data) != TYPE_DICTIONARY:
		print("DEVSEQ: cannot load levels json")
		get_tree().quit()
		return
	for key in data.keys():
		var dict: Dictionary = data[key]
		await _test_method(str(key), dict)
	GameData.logout()
	GameData.delete_user("dev")
	print("DEVSEQ DONE fails=", _fails)
	for i in 900:
		await get_tree().process_frame
	get_tree().quit()

func _test_method(key: String, dict: Dictionary) -> void:
	print("DEVSEQ start ", key)
	var stages: Array = dict.get("levels", [])
	for li in stages.size():
		var sc: Dictionary = (stages[li] as Dictionary).get("scene", {})
		if sc.is_empty():
			continue
		var p := SequencePlane.new()
		p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(p)
		await _frame(2)
		p.set_scene(sc)
		await _frame(2)
		print("DEVSEQ ", key, " li=", li, " size=", p.size, " tex_an=", p._tex("an") != null, " tex_op=", p._tex("op_cdot") != null)
		for v in _samples(sc):
			p._anim = v
			p.queue_redraw()
			await _frame(2)
			_capture(key, li, v)
		p.queue_free()
		await _frame(1)

func _samples(sc: Dictionary) -> Array:
	var k := str(sc.get("seq", "add"))
	if k in ["add", "mul"]:
		var out: Array = []
		var v := 0.05
		while v < 6.6:
			out.append(v)
			v += 0.45
		return out
	return [0.2, 0.8, 1.6, 3.0, 6.0]

func _frame(n: int) -> void:
	for i in n:
		await get_tree().process_frame

var _shot_sub := 0

func _capture(key: String, li: int, v: float) -> void:
	if li != 0:
		return
	if not (v >= 1.0 and (key in ["recur_add", "recur_mul"] or v >= 3.0)):
		return
	var dir := ProjectSettings.globalize_path("res://build/shots/dev")
	DirAccess.make_dir_recursive_absolute(dir)
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s_%02d_%s.png" % [dir, key, _shot_sub, ("%.1f" % v)]
	img.save_png(path)
	_shot_sub += 1
	print("DEVSEQ shot ", key, " ", path)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		pass