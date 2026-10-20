extends Node
## UI 截图工具(开发用，非游戏运行路径)：逐屏实例化并抓取窗口画面到 build/shots。
## 用法(需真实渲染窗口，不要 --headless):
##   godot --path . res://tools/capture_scene.tscn

const SHOTS_DIR := "res://build/shots"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS_DIR))
	GameData.create_user("shot", "player")
	GameData.login("shot")
	await get_tree().process_frame

	# 无上下文场景
	var standalone := [
		["BootSplash", "res://scenes/BootSplash.tscn", -1, -1],
		["MainHub", "res://scenes/MainHub.tscn", -1, -1],
		["Login", "res://scenes/Login.tscn", -1, -1],
		["Settings", "res://scenes/Settings.tscn", -1, -1],
		["WorldMap", "res://scenes/WorldMap.tscn", -1, -1],
		["UserProfile", "res://scenes/UserProfile.tscn", -1, -1],
		["TheoremTree", "res://scenes/TheoremTree.tscn", -1, -1],
	]

	# 每个场景取课程表中首个使用它的关卡作为上下文
	var seen := {}
	for ci in GameData.chapters.size():
		var levels: Array = GameData.chapters[ci].get("levels", [])
		for li in levels.size():
			var lv: Dictionary = levels[li]
			var scene := str(lv.get("scene", ""))
			if scene == "":
				continue   # A3：缺 scene 的关卡不可导航（curriculum 实测 275/275 全带 scene）
			if not seen.has(scene):
				seen[scene] = [ci, li]

	var shots: Array = []
	shots.append_array(standalone)
	for scene in seen.keys():
		var ctx: Array = seen[scene]
		shots.append([scene.get_file().get_basename(), scene, int(ctx[0]), int(ctx[1])])

	for s in shots:
		await _shoot(str(s[0]), str(s[1]), int(s[2]), int(s[3]))

	GameData.logout()
	GameData.delete_user("shot")
	print("CAPTURE DONE")
	get_tree().quit()

func _shoot(name: String, path: String, ci: int, li: int) -> void:
	if ci >= 0:
		GameData.start_level(ci, li)
	var ps := load(path) as PackedScene
	if ps == null:
		print("MISSING ", path)
		return
	var inst := ps.instantiate()
	add_child(inst)
	for i in 36:
		await get_tree().process_frame
	# 触发所有按钮的悬停/按压动效路径，以便暴露运行期错误
	_exercise(inst)
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var out := "%s/%s.png" % [SHOTS_DIR, name]
	img.save_png(ProjectSettings.globalize_path(out))
	print("SHOT   ", name, " -> ", out)
	# 额外抓一张「已作答」态(战斗类场景作答后会展开解析与按钮)
	if inst.has_method("_on_answer"):
		inst.call("_on_answer", 0)
		for i in 24:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img2 := get_viewport().get_texture().get_image()
		var out2 := "%s/%s_answered.png" % [SHOTS_DIR, name]
		img2.save_png(ProjectSettings.globalize_path(out2))
		print("SHOT   ", name, "_answered -> ", out2)
	inst.queue_free()
	await get_tree().process_frame

func _exercise(node: Node) -> void:
	if node is Button:
		var b := node as Button
		if b.is_inside_tree():
			b.mouse_entered.emit()
			b.button_down.emit()
			b.button_up.emit()
			b.mouse_exited.emit()
	for c in node.get_children():
		_exercise(c)
