class_name SaveIO
extends RefCounted
## 存档文件读写(从 GameData 抽出)：
## - read_dict: 读取并解析 JSON，失败/空文件返回空字典(不抛出)；
## - write_atomic: 先写临时文件并校验 → 备份旧档 → 再替换主档，避免中途被杀导致存档损坏；
## - load_users / write_users (F5): 用户存档的读取(含升版迁移与三级兜底)与带版本号写入。

## 从指定文件读取并解析存档，失败返回空字典(不抛出)。
static func read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var txt := FileAccess.get_file_as_string(path)
	if txt.strip_edges().is_empty():
		return {}
	var data = JSON.parse_string(txt)
	return data if typeof(data) == TYPE_DICTIONARY else {}

## 原子写入：先写临时文件并校验，备份旧档，再替换主档，避免中途被杀导致存档损坏。
static func write_atomic(path: String, tmp: String, bak: String, text: String) -> void:
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		# 退路：直接写主档
		var d := FileAccess.open(path, FileAccess.WRITE)
		if d != null:
			d.store_string(text)
		return
	f.store_string(text)
	f.close()
	# 校验临时文件可解析
	if typeof(JSON.parse_string(FileAccess.get_file_as_string(tmp))) != TYPE_DICTIONARY:
		return
	# 备份当前良好存档
	if FileAccess.file_exists(path):
		var cur := FileAccess.get_file_as_string(path)
		if not cur.strip_edges().is_empty() and typeof(JSON.parse_string(cur)) == TYPE_DICTIONARY:
			var b := FileAccess.open(bak, FileAccess.WRITE)
			if b != null:
				b.store_string(cur)
				b.close()
	# 替换主档
	DirAccess.remove_absolute(path)
	DirAccess.rename_absolute(tmp, path)

# ---------------------------------------------------------------- F5 用户存档读写
## 读取用户存档并升版迁移，带「主档 → 备份 → 旧版单人档」三级兜底。
## 返回 { "users": Dictionary, "current": String, "recovered": bool,
##        "downgraded": bool, "schema": int }——纯数据，不碰 autoload。
static func load_users(path: String, bak: String, legacy_single: String) -> Dictionary:
	var data := read_dict(path)
	var recovered := false
	if data.is_empty():
		data = read_dict(bak)
		recovered = not data.is_empty()
	var downgraded := false
	var schema := 0
	if not data.is_empty():
		var mig := SaveMigrate.migrate(data)
		data = mig["data"]
		downgraded = bool(mig["downgraded"])
		schema = int(mig["from"])
	var out := { "users": {}, "current": "", "recovered": recovered,
		"downgraded": downgraded, "schema": schema }
	var u = data.get("users", {})
	if typeof(u) == TYPE_DICTIONARY:
		out["users"] = u
		out["current"] = str(data.get("current", ""))
	# 兼容旧版单人存档（save.json）→ 迁移为「推演者」
	if (out["users"] as Dictionary).is_empty() and FileAccess.file_exists(legacy_single):
		var old = JSON.parse_string(FileAccess.get_file_as_string(legacy_single))
		if typeof(old) == TYPE_DICTIONARY:
			old["avatar"] = "player"
			out["users"] = { "推演者": old }
			out["current"] = "推演者"
	return out

## 写入用户存档：带上当前 schema 版本号后原子落盘。
static func write_users(path: String, tmp: String, bak: String, current: String, users: Dictionary) -> void:
	write_atomic(path, tmp, bak,
		JSON.stringify({ "schema": SaveMigrate.CURRENT, "current": current, "users": users }))
