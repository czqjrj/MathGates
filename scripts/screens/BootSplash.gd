extends Control
## 品牌启动屏(场景级)：纯黑底 + 居中标语(行书字体) + 渐入渐出。
## 标语用 UI.title_font() 渲染(优先 res://art/fonts/ 内置行书字体),与首页品牌字体一致。

const DUR := 1.7
const FADE := 0.45
const SLOGAN := "闯关长学识，推演破难题"

var _t := 0.0
var _done := false
var _out := false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	UI.full_rect(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	UI.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 20)
	center.add_child(vb)

	var slogan := UI.make_label(SLOGAN, 56, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	slogan.add_theme_font_override("font", UI.title_font())
	slogan.add_theme_constant_override("outline_size", 3)
	slogan.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	vb.add_child(slogan)

	var line := ColorRect.new()
	line.color = Color(UI.COL_ACCENT, 0.7)
	line.custom_minimum_size = Vector2(180, 2)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(line)

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, FADE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _t >= DUR and not _out:
		_out = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, FADE)
	if _t >= DUR + FADE:
		_go()

func _unhandled_input(event: InputEvent) -> void:
	if not _done and event.is_pressed() and _t > 0.25:
		_go()

func _go() -> void:
	if _done:
		return
	_done = true
	Scene.goto("res://scenes/MainHub.tscn")
