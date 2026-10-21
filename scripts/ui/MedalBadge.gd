class_name MedalBadge
extends Control
## 勋章徽章(纯代码绘制)：六边形护符 + 中央字符。
## unlocked=false 时呈灰色问号剪影；解锁后带描边、内环与弹入动画。

var col: Color = UI.COL_ACCENT
var symbol: String = "?"
var unlocked: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(64, 64)
	resized.connect(queue_redraw)
	if unlocked and UI.fx_on():
		_pop()

## 解锁徽章弹入(等一帧布局完成后再取 size 作轴心)
func _pop() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	pivot_offset = size * 0.5
	scale = Vector2(0.5, 0.5)
	create_tween().tween_property(self, "scale", Vector2.ONE, UI.DUR_XSLOW) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hex(c: Vector2, r: float, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := rot - PI * 0.5 + TAU * float(i) / 6.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0
	if r <= 2.0:
		return
	var pts := _hex(c, r)
	if unlocked:
		draw_colored_polygon(pts, Color(col, 0.16))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(col, 0.9), 2.0)
		var inner := _hex(c, r * 0.76)
		draw_polyline(inner + PackedVector2Array([inner[0]]), Color(col, 0.45), 1.0)
		_draw_glyph(c, r, symbol, col.lightened(0.25))
	else:
		draw_colored_polygon(pts, Color(1, 1, 1, 0.03))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(UI.COL_TEXT_DIM, 0.3), 2.0)
		_draw_glyph(c, r, "?", Color(UI.COL_TEXT_DIM, 0.5))

func _draw_glyph(c: Vector2, r: float, text: String, tint: Color) -> void:
	var font := UI.font()
	var fs := maxi(10, int(r * 0.95))
	var w := r * 2.0
	var pos := Vector2(c.x - r, c.y + float(fs) * 0.34)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, tint)
