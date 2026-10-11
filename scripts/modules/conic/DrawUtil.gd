class_name DrawUtil
extends RefCounted

# Shared palette and drawing helpers for all conic-section scenes.

const COL_TXT := Color(0.93, 0.96, 1.0, 1.0)
const COL_DIM := Color(0.62, 0.68, 0.8, 1.0)
const COL_AXIS := Color(0.5, 0.56, 0.7, 1.0)
const COL_FAINT := Color(0.45, 0.6, 0.85, 1.0)
const COL_TRACE := Color(0.3, 0.9, 1.0, 1.0)
const COL_F1 := Color(1.0, 0.45, 0.5, 1.0)
const COL_F2 := Color(0.55, 0.7, 1.0, 1.0)
const COL_S1 := Color(1.0, 0.76, 0.28, 1.0)
const COL_S2 := Color(0.4, 1.0, 0.62, 1.0)

const CJK_FONTS := [
	"Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "Arial Unicode MS"
]

static var _font_def: Font
static var _font_cjk: Font


static func ensure() -> void:
	if _font_def == null:
		_font_def = ThemeDB.fallback_font
	if _font_cjk == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(CJK_FONTS)
		_font_cjk = sf


static func font_for(s: String) -> Font:
	ensure()
	for i in s.length():
		if s.unicode_at(i) > 127:
			return _font_cjk
	return _font_def


static func with_a(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, col.a * a)


static func tex(name: String) -> Texture2D:
	return load("res://art/conic/formulas/%s.png" % name)


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color) -> void:
	if col.a <= 0.01 or s.is_empty():
		return
	ci.draw_string(font_for(s), pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(size), col)


static func text_center(ci: CanvasItem, base_y: float, s: String, size: int, col: Color) -> void:
	if col.a <= 0.01 or s.is_empty():
		return
	ci.draw_string(font_for(s), Vector2(0.0, base_y), s, HORIZONTAL_ALIGNMENT_CENTER,
			ci.get_viewport_rect().size.x, UI.fs(size), col)


static func text_right(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color) -> void:
	if col.a <= 0.01 or s.is_empty():
		return
	ci.draw_string(font_for(s), pos, s, HORIZONTAL_ALIGNMENT_RIGHT, -1, UI.fs(size), col)


static func tag(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, a: float = 1.0) -> void:
	var c := with_a(col, a)
	if c.a <= 0.01 or s.is_empty():
		return
	var px := UI.fs(size)
	var f := font_for(s)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var rect := Rect2(pos.x - w * 0.5 - 6.0, pos.y - px * 0.8, w + 12.0, px * 1.4)
	ci.draw_rect(rect, Color(0.05, 0.07, 0.11, 0.72 * c.a), true)
	ci.draw_string(f, Vector2(rect.position.x + 6.0, pos.y + px * 0.35),
			s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)


static func tag_tex(ci: CanvasItem, pos: Vector2, t: Texture2D, a: float) -> void:
	if t == null or a <= 0.01:
		return
	var rect := Rect2(pos - t.get_size() * 0.5 - Vector2(6.0, 5.0),
			t.get_size() + Vector2(12.0, 10.0))
	ci.draw_rect(rect, Color(0.05, 0.07, 0.11, 0.72 * a), true)
	ci.draw_texture(t, pos - t.get_size() * 0.5, Color(1.0, 1.0, 1.0, a))


static func tag_val(ci: CanvasItem, pos: Vector2, t: Texture2D, val: String, size: int, a: float) -> void:
	if t == null or a <= 0.01:
		return
	var px := UI.fs(size)
	var vw := font_for(val).get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var pad := 6.0
	var w := t.get_width() + 4.0 + vw + pad * 2.0
	var h := float(maxi(t.get_height() + 4, int(px * 1.4)))
	var rect := Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h)
	ci.draw_rect(rect, Color(0.05, 0.07, 0.11, 0.72 * a), true)
	ci.draw_texture(t, Vector2(rect.position.x + pad, pos.y - t.get_height() * 0.5),
			Color(1.0, 1.0, 1.0, a))
	ci.draw_string(font_for(val), Vector2(rect.position.x + pad + t.get_width() + 4.0,
			pos.y + px * 0.35), val, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
			with_a(COL_TXT, a))


static func tex_centered(ci: CanvasItem, t: Texture2D, center: Vector2, a: float, k: float = 1.0) -> Rect2:
	if t == null:
		return Rect2()
	var s := t.get_size() * k
	var rect := Rect2(center - s * 0.5, s)
	if a > 0.01:
		ci.draw_texture_rect(t, rect, false, Color(1.0, 1.0, 1.0, a))
	return rect


# Draws [ tex  value  tail ] horizontally centered on [center_x], returning total width.
static func readout(ci: CanvasItem, center_x: float, y: float, t: Texture2D,
		val: String, tail: String, a: float, tail_col: Color = COL_DIM) -> void:
	if a <= 0.01:
		return
	var num_size := UI.fs(20)
	var tail_size := UI.fs(16)
	var num_w := font_for(val).get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, num_size).x
	var tail_w := font_for(tail).get_string_size(tail, HORIZONTAL_ALIGNMENT_LEFT, -1, tail_size).x
	var sz := t.get_size() if t != null else Vector2.ZERO
	var gap := 10.0
	var total := sz.x + gap + num_w + gap + tail_w
	var x := center_x - total * 0.5
	var tint := Color(1.0, 1.0, 1.0, a)
	if t != null:
		ci.draw_texture_rect(t, Rect2(Vector2(x, y - sz.y * 0.5), sz), false, tint)
		x += sz.x + gap
	ci.draw_string(font_for(val), Vector2(x, y + num_size * 0.35), val,
			HORIZONTAL_ALIGNMENT_LEFT, -1, num_size, tint)
	x += num_w + gap
	ci.draw_string(font_for(tail), Vector2(x, y + tail_size * 0.35), tail,
			HORIZONTAL_ALIGNMENT_LEFT, -1, tail_size, with_a(tail_col, a))
