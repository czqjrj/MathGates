extends SceneTree
## 发版版本号同步（TODO F2）：改一处版本，多个导出预设一起变，避免漏改被商店拒包。
##
## 用法（`--` 之后的参数为用户参数）：
##   godot --headless --path . --script res://tools/bump_version.gd -- --bump patch
##   godot --headless --path . --script res://tools/bump_version.gd -- --name 1.2.0
##   godot --headless --path . --script res://tools/bump_version.gd -- --code 12 --name 1.2.0
##
## 行为：
##   - `version/code`（Android/iOS 等）整型递增（--bump 或 +1）；
##   - `version/name`（semver）按 --bump patch|minor|major 递增，或由 --name 显式指定；
##   - Windows 预设的 `application/file_version` 与 `application/product_version` 同步为 `x.y.z.0`。
## 退出码：0 = 成功；1 = 参数非法。

const PRESETS_PATH := "res://export_presets.cfg"

func _initialize() -> void:
	var argv := OS.get_cmdline_user_args()
	var usr := {}
	var i := 0
	while i < argv.size():
		var a := argv[i]
		if a.begins_with("--"):
			var key := a.substr(2)
			# 支持 --key=value 与 --key value
			var eq := key.find("=")
			if eq != -1:
				usr[key.substr(0, eq)] = key.substr(eq + 1)
			elif i + 1 < argv.size() and not argv[i + 1].begins_with("--"):
				usr[key] = argv[i + 1]
				i += 1
			else:
				usr[key] = "true"
		i += 1

	var text := FileAccess.get_file_as_string(PRESETS_PATH)
	if text == "":
		printerr("无法读取 " + PRESETS_PATH)
		quit(1)
		return
	var lines := text.split("\n")

	var cur_name := "1.0.0"
	var cur_code := 1
	for ln in lines:
		var s := str(ln).strip_edges()
		if s.begins_with("version/name=") and cur_name == "1.0.0":
			cur_name = s.split("=", true, 1)[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
		elif s.begins_with("version/code=") and cur_code == 1:
			cur_code = int(s.split("=", true, 1)[1].strip_edges())

	var new_name := str(usr.get("name", ""))
	if new_name == "":
		var kind := str(usr.get("bump", "patch"))
		new_name = _bump(cur_name, kind)
	var new_code := int(usr.get("code", "-1"))
	if new_code < 0:
		new_code = cur_code + 1

	var win_ver := "%s.0" % new_name
	var out: Array[String] = []
	var n_code := 0
	var n_name := 0
	var n_win := 0
	for ln in lines:
		var s := str(ln)
		if s.begins_with("version/code="):
			out.append("version/code=%d" % new_code)
			n_code += 1
		elif s.begins_with("version/name="):
			out.append("version/name=\"%s\"" % new_name)
			n_name += 1
		elif s.begins_with("application/file_version=") or s.begins_with("application/product_version="):
			out.append("%s=\"%s\"" % [s.substr(0, s.find("=")), win_ver])
			n_win += 1
		else:
			out.append(s)

	var f := FileAccess.open(PRESETS_PATH, FileAccess.WRITE)
	if f == null:
		printerr("无法写入 " + PRESETS_PATH)
		quit(1)
		return
	f.store_string("\n".join(out))
	f.close()

	print("版本已更新：%s -> %s（version/code %d -> %d）" % [cur_name, new_name, cur_code, new_code])
	print("同步：version/code×%d  version/name×%d  Windows file/product_version×%d -> %s" % [n_code, n_name, n_win, win_ver])
	print("提示：release 签名口令与 keystore 不入库（见 docs/环境配置.md 第 6 节）。")
	quit(0)

## 语义化版本递增：1.2.3 -> patch=1.2.4 / minor=1.3.0 / major=2.0.0。
func _bump(v: String, kind: String) -> String:
	var parts := v.split(".")
	while parts.size() < 3:
		parts.append("0")
	var major := int(parts[0])
	var minor := int(parts[1])
	var patch := int(parts[2])
	match kind:
		"major":
			major += 1
			minor = 0
			patch = 0
		"minor":
			minor += 1
			patch = 0
		_:
			patch += 1
	return "%d.%d.%d" % [major, minor, patch]
