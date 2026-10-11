class_name SaveIO
extends RefCounted
## 存档文件读写(从 GameData 抽出)：
## - read_dict: 读取并解析 JSON，失败/空文件返回空字典(不抛出)；
## - write_atomic: 先写临时文件并校验 → 备份旧档 → 再替换主档，避免中途被杀导致存档损坏。

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
