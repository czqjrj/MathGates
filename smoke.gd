extends SceneTree

func _initialize() -> void:
	GameData.create_user("smoke", "player")
	GameData.login("smoke")
	await process_frame
	var paths: Array[String] = [
		"res://scenes/MainHub.tscn",
		"res://scenes/WorldMap.tscn",
		"res://scenes/UserProfile.tscn",
		"res://scenes/Login.tscn",
	]
	for path in paths:
		var ps: PackedScene = load(path)
		if ps == null:
			print("MISSING ", path)
			continue
		var inst := ps.instantiate()
		root.add_child(inst)
		for i in 6:
			await process_frame
		if inst.has_method("_open_panel"):
			inst._open_panel(0)
			for i in 6:
				await process_frame
		inst.queue_free()
		await process_frame
		print("OK ", path)
	GameData.logout()
	GameData.delete_user("smoke")
	print("SMOKE DONE")
	quit()
