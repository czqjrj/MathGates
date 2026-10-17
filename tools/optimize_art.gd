extends SceneTree
## A13 · 美术资源降采样（幂等，可反复运行）。
##
## 用法：
##   godot --headless --path . --script res://tools/optimize_art.gd            # 预览(dry-run)
##   godot --headless --path . --script res://tools/optimize_art.gd -- --apply # 写回
##
## 规则：
##   - 显式规则(`RULES`)：如项目图标 `res://icon.png` 最长边压到 512
##     （Godot 官方建议项目图标 128~512；Android 图标另由 art/android/* 提供，不受影响）；
##   - 扫描 `res://art` 下所有 PNG：最长边超过 DEFAULT_MAX 的等比缩小（防未来误入超大图）。
##
## 只做「等比降采样」，不做有损/格式转换，观感回退风险最小。

const DEFAULT_MAX := 2048
const RULES := {
	"res://icon.png": 512,
}
const SCAN_DIRS := ["res://art"]

func _initialize() -> void:
	var apply := OS.get_cmdline_user_args().has("--apply")
	var jobs: Array = []
	for path in RULES:
		jobs.append([path, int(RULES[path])])
	for dir in SCAN_DIRS:
		_scan(dir, jobs)
	var before := 0
	var after := 0
	var changed := 0
	for job in jobs:
		var path: String = job[0]
		var limit: int = job[1]
		if not FileAccess.file_exists(path):
			continue
		var old_size := FileAccess.get_file_as_bytes(path).size()
		before += old_size
		var img := Image.load_from_file(path)
		if img == null:
			push_warning("optimize_art: 无法读取 %s" % path)
			continue
		var w := img.get_width()
		var h := img.get_height()
		if maxi(w, h) <= limit:
			after += old_size
			continue
		var scale := float(limit) / float(maxi(w, h))
		var nw := maxi(1, int(round(w * scale)))
		var nh := maxi(1, int(round(h * scale)))
		if not apply:
			print("  [dry] %s  %dx%d -> %dx%d" % [path, w, h, nw, nh])
			after += old_size
			continue
		img.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
		var err := img.save_png(path)
		if err != OK:
			push_error("optimize_art: 写回失败 %s (err=%d)" % [path, err])
			continue
		var new_size := FileAccess.get_file_as_bytes(path).size()
		after += new_size
		changed += 1
		print("  %s  %dx%d -> %dx%d  %.2fMB -> %.2fMB" % [path, w, h, nw, nh, old_size / 1048576.0, new_size / 1048576.0])
	print("optimize_art: %s, 涉及 %d 张, 已处理 %d 张, 节省 %.2fMB" % ["已写回" if apply else "预览(加 -- --apply 写回)", jobs.size(), changed, (before - after) / 1048576.0])
	quit(0)

func _scan(dir_path: String, jobs: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var p := dir_path.path_join(n)
		if d.current_is_dir():
			if not n.begins_with("."):
				_scan(p, jobs)
		elif n.to_lower().ends_with(".png"):
			jobs.append([p, DEFAULT_MAX])
		n = d.get_next()
	d.list_dir_end()
