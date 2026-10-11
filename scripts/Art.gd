class_name Art
extends RefCounted
## 美术资源自动加载器
## 有图就用图，没图就返回 null，调用方自动退回"代码绘制"风格。
##
## 把你用豆包生成的图放进 res://art/，按下面文件名命名即可自动生效，
## 支持 .png / .webp / .jpg(透明件请用 png 或 webp)。
##
## 素材文件名清单：
##   bg_mainhub        主城背景(1920x1080，不透明)
##   bg_worldmap       世界地图背景(1920x1080，不透明)
##   island_unlocked   章节浮岛·已解锁(512x512，透明)
##   island_locked     章节浮岛·锁定(512x512，透明)
##   ui_panel          通用面板框 9-patch(透明)
##   ui_button / ui_button_hover / ui_button_pressed / ui_button_disabled  按钮(透明，只需 ui_button 也可)
##   icon_star_full    满星(透明)   icon_star_empty  空星(透明)
##   icon_map / icon_tree / icon_book / icon_train   主城四个功能图标(透明)
##
## 9-patch 边框默认按 PATCH_BUTTON / PATCH_PANEL 像素切；不贴合时改下面两个常量。

const DIR := "res://art/"
const EXTS := [".png", ".webp", ".jpg", ".jpeg"]

const PATCH_BUTTON := 40
const PATCH_PANEL := 48

static var _cache: Dictionary = {}
static var _cache_sized: Dictionary = {}

static func tex(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var found: Texture2D = null
	for e in EXTS:
		var p: String = DIR + name + e
		if ResourceLoader.exists(p):
			found = load(p)
			break
	_cache[name] = found
	return found

static func has(name: String) -> bool:
	return tex(name) != null

## 返回缩放到 size x size 的纹理(用于图标限宽)；失败则返回原纹理
static func tex_sized(name: String, size: int) -> Texture2D:
	var key := name + "#" + str(size)
	if _cache_sized.has(key):
		return _cache_sized[key]
	var t := tex(name)
	var out: Texture2D = t
	if t != null:
		var img := t.get_image()
		if img != null and not img.is_empty():
			img.resize(size, size, Image.INTERPOLATE_LANCZOS)
			out = ImageTexture.create_from_image(img)
	_cache_sized[key] = out
	return out

## 用纹理做 9-patch 样式框；纹理不存在则返回 fallback
static func panel(name: String, fallback: StyleBox, margin: int = PATCH_PANEL) -> StyleBox:
	var t := tex(name)
	if t == null:
		return fallback
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.set_texture_margin_all(margin)
	sb.set_content_margin_all(margin)
	return sb
