class_name Deriv
extends RefCounted

# Playback helper for Manim-rendered derivation clips.
# Clips live as transparent RGBA PNG sequences in res://derivations/<id>/f_0000.png ...
# rendered by tools/render_manim.ps1. Frames are loaded once and cached.


static var _cache: Dictionary = {}
static var _fps: Dictionary = {}


static func frames(id: String) -> Array:
	if _cache.has(id):
		return _cache[id]
	var arr: Array = []
	var dir_path := "res://art/conic/derivations/%s" % id
	var dir := DirAccess.open(dir_path)
	if dir != null:
		var names := dir.get_files()
		names.sort()
		for n in names:
			if n.get_extension().to_lower() == "png":
				arr.append(load(dir_path + "/" + n))
	_cache[id] = arr
	return arr


static func count(id: String) -> int:
	return frames(id).size()


# Draws the clip's frame for normalized progress [prog] in [0,1] into [rect].
static func draw(ci: CanvasItem, id: String, rect: Rect2, prog: float, a: float) -> void:
	var arr := frames(id)
	if arr.is_empty() or a <= 0.01:
		return
	var idx := clampi(int(floor(prog * float(arr.size()))), 0, arr.size() - 1)
	ci.draw_texture_rect(arr[idx], rect, false, Color(1.0, 1.0, 1.0, a))
