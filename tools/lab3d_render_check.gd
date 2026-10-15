extends Node
## 立体几何/空间向量 3D 场景「渲染自检」(需真实窗口，勿加 --headless)。
##
## headless 冒烟只能验证数据可载入、控件创建成功，无法发现「3D 视口一片空白」。
## 本工具把每个关卡的 scene 交给独立的 Lab3DView 渲染(无 HUD 遮挡)：
##   1) 渲染真实场景 → 存 PNG 到 build/shots3d/ 供人工目视；
##   2) 在同一相机角度渲染「只有天空」的基线；
##   3) 逐像素比较，得到「内容像素占比」= 真正被画出来的几何/棱线/标注的比例。
## 占比接近 0 说明该场景没有画出任何东西(空白)。
##
## 用法： godot --path . res://tools/lab3d_render_check.tscn

const FILES := {
	"solid_basic": "res://data/solid_basic_levels.json",
	"space": "res://data/space_levels.json",
}
const OUT_DIR := "res://build/shots3d"
const DIFF_EPS := 0.06    # 与天空基线的颜色差阈值(曼哈顿距离)
const WARN_FRAC := 0.001  # 内容占比低于此值视为可疑(近乎空白)

func _ready() -> void:
	GameData.create_user("rchk", "player")
	GameData.login("rchk")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var win := get_viewport().get_visible_rect().size
	var bad: Array[String] = []
	var checked := 0
	for lab in FILES.keys():
		var path: String = FILES[lab]
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY:
			print("RENDER_ERR 无法解析 ", path)
			continue
		for id in (data as Dictionary).keys():
			var ls: Array = ((data as Dictionary)[id] as Dictionary).get("levels", [])
			for li in ls.size():
				var lv: Dictionary = ls[li]
				if not lv.has("scene"):
					continue
				var scene: Dictionary = lv["scene"]
				var vars := {}
				for sl in scene.get("sliders", []):
					vars[str((sl as Dictionary).get("name", ""))] = float((sl as Dictionary).get("value", 0.0))
				var shot := "%s/%s_%s_%d.png" % [OUT_DIR, lab, id, li]
				var frac := await _render(scene, vars, win, shot)
				checked += 1
				var tag := "  <<< 可疑" if frac < WARN_FRAC else ""
				if tag != "":
					bad.append("%s/%s[%d]" % [lab, id, li])
				print("RENDER %s/%s[%d] content=%.4f%s" % [lab, id, li, frac, tag])
	GameData.logout()
	GameData.delete_user("rchk")
	print("RENDER_SUMMARY checked=%d bad=%d" % [checked, bad.size()])
	if bad.size() > 0:
		print("RENDER_BAD ", ", ".join(bad))
	get_tree().quit(0)

func _render(scene: Dictionary, vars: Dictionary, win: Vector2, shot: String) -> float:
	var real := await _shot(scene, vars, win, shot)
	var sky := await _shot({ "view": scene.get("view", {}) }, vars, win, "")
	return _diff_frac(real, sky)

## 渲染一个 scene；固定天空时间、冻结处理，抓取整幅画面。
func _shot(scene: Dictionary, vars: Dictionary, win: Vector2, path: String) -> Image:
	var view := Lab3DView.new()
	add_child(view)
	view.size = win
	view.set_scene(scene, vars)
	view.set("_reveal", 1.0)
	view.set("_reveal_target", 1.0)
	view.call("reset_view", false)
	for i in 18:
		await get_tree().process_frame
	view.set("_t", 0.0)
	view.set_process(false)
	var sm := view.get("_sky_mat") as ShaderMaterial
	if sm != null:
		sm.set_shader_parameter("time", 0.0)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if path != "":
		img.save_png(path)
	view.queue_free()
	await get_tree().process_frame
	return img

func _diff_frac(a: Image, b: Image) -> float:
	if a == null or b == null or a.get_width() != b.get_width() or a.get_height() != b.get_height():
		return -1.0
	var w := a.get_width()
	var h := a.get_height()
	var total := 0
	var diff := 0
	var step := 2
	var y := 0
	while y < h:
		var x := 0
		while x < w:
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > DIFF_EPS:
				diff += 1
			total += 1
			x += step
		y += step
	return float(diff) / float(maxi(total, 1))
