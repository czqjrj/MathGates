extends CanvasLayer
## 轻量飘字提示 · 玻璃样式

var _active: int = 0

func _ready() -> void:
	layer = UiConst.LAYER_TOAST

func show_toast(text: String) -> void:
	var pc := PanelContainer.new()
	var sb := UI.glass_box(Color(0.04, 0.06, 0.10, 0.94), 10, Color(1, 1, 1, 0.14), 1, 14)
	sb.set_border_width_all(0)
	sb.border_width_left = 3
	sb.border_color = UI.COL_ACCENT
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	pc.add_theme_stylebox_override("panel", sb)
	var lbl := UI.make_label(text, 16, UI.COL_TEXT)
	pc.add_child(lbl)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pc)

	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	var y_off := 150.0 + _active * 56.0
	_active += 1
	pc.position = Vector2((vp.x - pc.size.x) * 0.5, vp.y - y_off)

	pc.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.12)
	tw.tween_interval(1.1)
	tw.tween_property(pc, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		_active -= 1
		pc.queue_free()
	)
