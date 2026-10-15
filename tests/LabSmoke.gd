extends Node
## 几何章节「实验探究」运行期冒烟测试（headless）。
## 运行： godot --headless --path <项目> res://tests/LabSmoke.tscn
## 作用：为各几何章节的关键关卡实例化 LabStage（2D）/ Lab3DStage（真实 3D），
##       确认数据可被载入、视图控件创建成功、无脚本错误（打印 TMP_OK 即正常）。

func _ready() -> void:
	var cases := [
		["circle", ["circle_1_1", "circle_2_2", "circle_3_2", "circle_5_2", "circle_6_3", "circle_boss"]],
		["ellipse", ["ellipse_1_1", "ellipse_2_1", "ellipse_3_2", "ellipse_4_2", "ellipse_5_1", "ellipse_boss"]],
		["vector", ["vector_1_1", "vector_1_2", "vector_2_1", "vector_2_2", "vector_2_3", "vector_3_2", "vector_3_3", "vector_4_1", "vector_4_3", "vector_5_1", "vector_5_2", "vector_6_3", "vector_boss"]],
		["line", ["line_1_1", "line_1_3", "line_2_2", "line_2_3", "line_3_1", "line_3_2", "line_3_3", "line_4_1", "line_4_2", "line_4_3", "line_5_1", "line_5_2", "line_6_1", "line_6_2", "line_6_3", "line_boss"]],
	]
	for c in cases:
		var lab: String = c[0]
		for id in c[1]:
			GameData.current_level = {
				"id": id, "lab": lab, "lab_ref": id,
				"scene": "res://scenes/LabStage.tscn",
			}
			var st = load("res://scenes/LabStage.tscn").instantiate()
			add_child(st)
			await get_tree().process_frame
			await get_tree().process_frame
			var stages: Array = st._stages
			var t0 := "choice"
			if stages.size() > 0:
				t0 = str((stages[0] as Dictionary).get("type", "choice"))
			print("TMP %s/%s rounds=%d type0=%s plane=%s" % [lab, id, stages.size(), t0, str(st._plane != null)])
			st.queue_free()
			await get_tree().process_frame
	await _smoke_3d()
	print("TMP_OK")
	get_tree().quit(0)

## 立体几何 / 空间向量章节：真实 3D 关卡冒烟。
func _smoke_3d() -> void:
	var cases := [
		["solid_basic", ["solid_kinds", "solid_frustum", "solid_surface", "solid_volume", "solid_diag", "solid_sphere", "solid_view", "solid_axiom", "solid_parallel", "solid_perp_prop", "solid_angle", "solid_distance"]],
		["space", ["space_1_1", "space_1_2", "space_1_3", "space_2_1", "space_2_2", "space_2_3", "space_3_1", "space_3_2", "space_3_3", "space_4_1", "space_4_2", "space_4_3", "space_5_1", "space_5_2", "space_5_3", "space_6_1", "space_6_2", "space_6_3", "space_boss"]],
	]
	for c in cases:
		var lab: String = c[0]
		for id in c[1]:
			GameData.current_level = {
				"id": id, "lab": lab, "lab_ref": id,
				"scene": "res://scenes/Lab3DStage.tscn",
			}
			var st = load("res://scenes/Lab3DStage.tscn").instantiate()
			add_child(st)
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			var stages: Array = st._stages
			var t0 := "choice"
			if stages.size() > 0:
				t0 = str((stages[0] as Dictionary).get("type", "choice"))
			print("TMP3D %s/%s rounds=%d type0=%s view3d=%s" % [lab, id, stages.size(), t0, str(st._view3d != null)])
			st.queue_free()
			await get_tree().process_frame
