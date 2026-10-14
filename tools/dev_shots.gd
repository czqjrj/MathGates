extends Node
## 开发用：抓取指定关卡的每一轮画面到 build/shots（需真实窗口，勿 --headless）。
## 用法： godot --path . res://tools/dev_shots.tscn

const OUT := "res://build/shots"
const TARGETS := ["func_mono", "func_parity", "func_range", "func_corr"]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	GameData.create_user("shot", "player")
	GameData.login("shot")
	await get_tree().process_frame
	for ci in GameData.chapters.size():
		var levels: Array = GameData.chapters[ci].get("levels", [])
		for li in levels.size():
			var lv: Dictionary = levels[li]
			var id := str(lv.get("id", ""))
			if id not in TARGETS:
				continue
			GameData.start_level(ci, li)
			var ps := load(str(lv.get("scene", "res://scenes/LabStage.tscn"))) as PackedScene
			var inst := ps.instantiate()
			add_child(inst)
			for i in 5:
				await get_tree().process_frame
			var n: int = (inst.get("_stages") as Array).size()
			for r in n:
				inst.set("_idx", r)
				inst.call("_load_q")
				for j in 10:
					await get_tree().process_frame
				var img := get_viewport().get_texture().get_image()
				img.save_png("%s/%s_%d.png" % [OUT, id, r])
			inst.queue_free()
			await get_tree().process_frame
	GameData.logout()
	print("SHOTS DONE")
	get_tree().quit()
