extends Node
## 全场景冒烟测试：无上下文场景直接实例化；带关卡上下文的场景按课程表逐关进入，
## 统一捕获运行时报错。用法(无头):
##   godot --headless --path . res://tools/smoke_scene.tscn

func _ready() -> void:
	GameData.create_user("smoke", "player")
	GameData.login("smoke")
	await get_tree().process_frame

	var ok := 0
	var fail := 0

	# ---- 无关卡上下文的独立场景 ----
	var standalone: Array[String] = [
		"res://scenes/MainHub.tscn",
		"res://scenes/WorldMap.tscn",
		"res://scenes/UserProfile.tscn",
		"res://scenes/Login.tscn",
		"res://scenes/TheoremTree.tscn",
		"res://scenes/WrongNotebook.tscn",
		"res://scenes/DailyMissions.tscn",
		"res://scenes/Achievements.tscn",
		"res://scenes/Shop.tscn",
		"res://scenes/BootSplash.tscn",
	]
	for path in standalone:
		if await _probe(path, true):
			ok += 1
		else:
			fail += 1

	# ---- 带关卡上下文的场景：按课程表逐关进入 ----
	for ci in GameData.chapters.size():
		var levels: Array = GameData.chapters[ci].get("levels", [])
		for li in levels.size():
			var lv: Dictionary = levels[li]
			var scene := str(lv.get("scene", ""))
			if scene == "":
				continue   # A3：缺 scene 的关卡不可导航（curriculum 实测 275/275 全带 scene）
			GameData.start_level(ci, li)
			if await _probe(scene, true):
				ok += 1
			else:
				fail += 1

	GameData.logout()
	GameData.delete_user("smoke")
	print("SMOKE: %d ok, %d fail" % [ok, fail])
	get_tree().quit()

func _probe(path: String, open_panel: bool) -> bool:
	var ps := load(path) as PackedScene
	if ps == null:
		print("MISSING ", path)
		return false
	var inst := ps.instantiate()
	add_child(inst)
	for i in 3:
		await get_tree().process_frame
	if open_panel and inst.has_method("_open_panel"):
		inst.call("_open_panel", 0)
		for i in 3:
			await get_tree().process_frame
	inst.queue_free()
	await get_tree().process_frame
	print("OK   ", path)
	return true
