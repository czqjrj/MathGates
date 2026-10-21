class_name ProgressLine
extends Control
## 细长的进度条(纯代码绘制)：圆角轨道 + 圆角填充，可带辉光。
## ratio 0..1；set_ratio() 平滑过渡(受设置里的界面动效开关控制)。

var ratio: float = 0.0
var col: Color = UI.COL_ACCENT
var bg: Color = Color(1, 1, 1, 0.10)
var glow: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(0, 8)
	resized.connect(queue_redraw)

func set_ratio(r: float, animate: bool = true) -> void:
	var target := clampf(r, 0.0, 1.0)
	if animate and UI.fx_on() and is_inside_tree():
		if has_meta("_pl_tw"):
			var old: Variant = get_meta("_pl_tw")
			if old is Tween and (old as Tween).is_valid():
				(old as Tween).kill()
		var tw := create_tween()
		set_meta("_pl_tw", tw)
		tw.tween_method(func(v: float) -> void: ratio = v; queue_redraw(), ratio, target, 0.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		ratio = target
		queue_redraw()

func _draw() -> void:
	var h := size.y
	var rad := int(h * 0.5)
	var track := UI.stylebox(bg, rad, Color(0, 0, 0, 0), 0, 0)
	draw_style_box(track, Rect2(Vector2.ZERO, size))
	var w := size.x * clampf(ratio, 0.0, 1.0)
	if w <= 0.5:
		return
	var fill := UI.stylebox(col if not glow else col, rad, Color(0, 0, 0, 0), 0, 0)
	if glow:
		fill.shadow_color = Color(col, 0.5)
		fill.shadow_size = int(h)
		fill.shadow_offset = Vector2.ZERO
	draw_style_box(fill, Rect2(Vector2.ZERO, Vector2(w, h)))
