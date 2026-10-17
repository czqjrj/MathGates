extends SceneTree
## 把 gdextension/res 打包成 gdextension/res.zip（MicroTeX 运行时资源）。
## 导出后的 res:// 位于 PCK/APK 内，扩展用 std::ifstream 读不到；运行时改为
## 从该 zip 解压到 user:// 再用（见 scripts/ui/InlineMath.gd::_mt_resolve）。
## 用法：godot --headless --path . --script res://tools/pack_math_res.gd

const SRC_DIR := "res://gdextension/res"
const OUT_ZIP := "res://gdextension/res.bin"

## 打包时排除的目录（F7）：greek/ 与 cyrillic/ 的字体随上游 MicroTeX 附带 GPLv3 许可，
## 与本项目「专有发布」不兼容；本应用只做中文+数学排版，数学希腊字母来自 base/cmmi10 等字体，
## 不依赖这两个目录（全仓源码亦无任何引用）。排除后 APK 更小、许可更干净。
const EXCLUDE_DIRS := ["greek", "cyrillic"]

func _initialize() -> void:
	var packer := ZIPPacker.new()
	var err := packer.open(OUT_ZIP)
	if err != OK:
		push_error("pack_math_res: 无法创建 %s (err=%d)" % [OUT_ZIP, err])
		quit(1)
		return
	var count := _add_dir(packer, SRC_DIR, "")
	packer.close()
	print("pack_math_res: %d files -> %s (%d bytes)" % [count, OUT_ZIP, FileAccess.get_file_as_bytes(OUT_ZIP).size()])
	quit(0)

func _add_dir(packer: ZIPPacker, dir_path: String, prefix: String) -> int:
	var d := DirAccess.open(dir_path)
	if d == null:
		return 0
	var n := 0
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		var rel := name if prefix == "" else prefix + "/" + name
		if d.current_is_dir():
			if not (name in EXCLUDE_DIRS):
				n += _add_dir(packer, full, rel)
		elif not name.ends_with(".import") and name != ".gdignore":
			packer.start_file(rel)
			packer.write_file(FileAccess.get_file_as_bytes(full))
			n += 1
		name = d.get_next()
	d.list_dir_end()
	return n
