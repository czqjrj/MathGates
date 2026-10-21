extends Control
## 品牌启动屏(场景级)：动态科技背景 + 旋转品牌徽标 + 标题弹入 + 扫光下划线 + 载入指示。
## 徽标/下划线由 BrandMark 绘制(纯代码)；标语用 UI.title_font() 渲染，与首页品牌字体一致。

const DUR := 2.6
const FADE := 0.5
const SLOGAN := "闯关长学识，推演破难题"
const BRAND := "衍 数 阁"

var _t := 0.0
var _done := false
var _out := false
var _load_lbl: Label

func _ready() -> void:
	add_child(TechBg.new())

	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.02, 0.05, 0.32)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(veil)
	add_child(veil)

	var center := CenterContainer.new()
	UI.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)

	var mark := BrandMark.new()
	mark.custom_minimum_size = Vector2(156, 156)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(mark)

	var title := UI.make_label(BRAND, 60, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", UI.title_font())
	UI.outlined(title, 5, Color(0, 0, 0, 0.45))
	title.pivot_offset = title.size * 0.5
	title.resized.connect(func() -> void: title.pivot_offset = title.size * 0.5)
	vb.add_child(title)

	var under := BrandMark.Underline.new()
	under.custom_minimum_size = Vector2(220, 3)
	under.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(under)

	var sub := UI.mono_label("MATH GATES // 推演终端", 15, Color(UI.COL_ACCENT, 0.85), HORIZONTAL_ALIGNMENT_CENTER)
	vb.add_child(sub)

	vb.add_child(UI.make_label(SLOGAN, 22, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	_load_lbl = UI.mono_label("", 13, Color(UI.COL_TEXT_DIM, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	vb.add_child(_load_lbl)

	# 入场：整体淡入 + 徽标弹入 + 标题弹入
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, FADE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	mark.pivot_offset = mark.custom_minimum_size * 0.5
	mark.scale = Vector2(0.4, 0.4)
	create_tween().tween_property(mark, "scale", Vector2.ONE, UI.DUR_SCENE) \
		.set_delay(0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	title.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(title, "scale", Vector2.ONE, UI.DUR_SCENE) \
		.set_delay(0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _load_lbl != null and is_instance_valid(_load_lbl):
		_load_lbl.text = "LOADING" + ".".repeat(int(_t * 3.0) % 4)
	if _t >= DUR and not _out:
		_out = true
		create_tween().tween_property(self, "modulate:a", 0.0, FADE)
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
