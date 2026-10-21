extends Node
## F3 性能基线探针（CPU 侧，headless 可跑）。
##
## 用法：
##   godot --headless --path . res://tools/perf_probe.tscn
##
## 说明：headless 没有 GPU，测不出 FPS/GPU 时间与真实耗电；这里量的是
##   `Performance.TIME_PROCESS`（本帧脚本处理耗时）与主循环壁钟耗时，
##   用于**发现回归趋势**。Android 真机的 FPS / 功耗 / 内存需真机测量（见 TODO F3）。
##
## 输出格式（便于 CI 采集）：
##   PERF <case> proc_avg_us=<n> proc_p95_us=<n> frame_avg_us=<n> mem_kb=<n>

const FRAMES := 240
const WARMUP := 600

func _ready() -> void:
	if GameData != null:
		GameData.create_user("perf", "player")
		GameData.login("perf")
	await get_tree().process_frame

	await _case("idle", func() -> Node: return null, Callable())
	await _case("lab_plane", _new_plane, _setup_plane)
	await _case("lab3d", _new_3d, _setup_3d, 1700)

	if GameData != null:
		GameData.logout()
		GameData.delete_user("perf")
	get_tree().quit(0)

func _new_plane() -> Node:
	var plane = load("res://scripts/modules/lab/LabPlane.gd").new()
	plane.size = Vector2(900, 620)
	return plane

func _setup_plane(plane: Node) -> void:
	var slider := [ { "name": "r", "min": 0.5, "max": 5, "value": 1, "step": 0.5 } ]
	plane.set_scene({
		"range": 6,
		"sliders": slider,
		"circles": [ { "c": [0, 0], "r": "r" } ],
		"points": [ { "p": ["r", 0] } ],
		"readouts": [ { "label": "r", "expr": "r" } ],
	})
	plane.begin_sliders(slider)
	# 让补间一直有活干：模拟拖动
	plane._sliders[0]["value"] = 4.0

func _new_3d() -> Node:
	var v = load("res://scripts/modules/lab3d/Lab3DView.gd").new()
	v.size = Vector2(900, 620)
	return v

func _setup_3d(v: Node) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/space_levels.json"))
	if typeof(data) != TYPE_DICTIONARY:
		return
	for key in (data as Dictionary).keys():
		var lv: Variant = (data as Dictionary)[key]
		if typeof(lv) != TYPE_DICTIONARY:
			continue
		for item in (lv as Dictionary).get("levels", []):
			if typeof(item) == TYPE_DICTIONARY and (item as Dictionary).has("scene"):
				var vars := {}
				for sl in (item as Dictionary)["scene"].get("sliders", []):
					vars[str((sl as Dictionary).get("name", ""))] = float((sl as Dictionary).get("value", 0.0))
				v.set_scene((item as Dictionary)["scene"], vars)
				return

func _case(name: String, factory: Callable, setup: Callable, warmup: int = WARMUP) -> void:
	var node: Node = factory.call()
	if node != null:
		add_child(node)
		if setup.is_valid():
			setup.call(node)
	await get_tree().process_frame
	for _i in warmup:
		await get_tree().process_frame

	var procs := PackedFloat64Array()
	var walls := PackedInt64Array()
	var mem0 := OS.get_static_memory_usage()
	for _i in FRAMES:
		var t0 := Time.get_ticks_usec()
		await get_tree().process_frame
		walls.append(Time.get_ticks_usec() - t0)
		procs.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.0)
	var mem1 := OS.get_static_memory_usage()
	procs.sort()
	walls.sort()
	print("PERF %s proc_avg_us=%d proc_p95_us=%d frame_avg_us=%d mem_kb=%d" % [
		name,
		int(_avg(procs)), int(_p95(procs)),
		int(_avg_i(walls)), int((mem1 - mem0) / 1024)])
	if node != null:
		node.queue_free()
		await get_tree().process_frame

func _avg(a: PackedFloat64Array) -> float:
	var t := 0.0
	for v in a:
		t += v
	return t / maxf(1.0, float(a.size()))

func _avg_i(a: PackedInt64Array) -> float:
	var t := 0
	for v in a:
		t += v
	return float(t) / maxf(1.0, float(a.size()))

func _p95(a: PackedFloat64Array) -> float:
	return a[int(float(a.size()) * 0.95)]
