class_name MtTextureLoader
extends ResourceFormatLoader
## 让 RichTextLabel 的 bbcode [img] 能引用运行时由 MicroTeX 渲染的公式纹理。
## 这些纹理写入 user://mt_cache/*.mttex(实为 PNG 字节),用私有扩展名以避开
## 内建 PNG 加载器,从而由本加载器直接读盘并返回 ImageTexture。

const CACHE_DIR := "user://mt_cache"
const EXT := "mttex"

func _recognize_path(path: String, _type: StringName) -> bool:
	return path.begins_with(CACHE_DIR) and path.get_extension() == EXT

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray([EXT])

func _handles_type(_type: StringName) -> bool:
	return true

func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Resource:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var img := Image.new()
	if img.load_png_from_buffer(bytes) != OK or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)
