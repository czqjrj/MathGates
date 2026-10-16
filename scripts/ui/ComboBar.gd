class_name ComboBar
extends Control
## 关卡内「连击进度条」：把答题连击量化为可见的进度与金币倍率。
##
## 纯展示控件(不拦截输入)，由 `StageBase` 放在顶栏更新：连击 <2 时隐藏。
## 倍率只影响结算金币，不改题目难度；连击越高条越亮、档位越高。
##
## 坐标约定：本控件嵌在顶栏 HBox 内，尺寸由容器给定(默认约 168×26)，不自绘全屏特效。

## 进度条满格所需连击数(超过后只取满格，倍率仍在 cap 收敛)。
const COMBO_MAX := 8
## 金币倍率上限。
const MULT_CAP := 1.5

## 连击 → 金币倍率：≥3 起每多 1 连击 +0.1，封顶 1.5。
## streak 0/1/2 → 1.0；3 → 1.1；4 → 1.2 … 7 及以上 → 1.5。
static func multiplier(streak: int) -> float:
	if streak < 2:
		return 1.0
	return minf(MULT_CAP, 1.0 + 0.1 * float(streak - 2))

## 连击档位配色：2+ 金 → 3+ 橙 → 5+ 红。
static func tier_color(streak: int) -> Color:
	if streak >= 5:
		return Color("#fb7185")
	if streak >= 3:
		return Color("#ffa64d")
	return Color("#ffd479")

var streak := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(168, 26)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resized.connect(queue_redraw)
	visible = false

## 更新连击数并重绘；连击 ≥2 才显示，出现时轻微回弹强调。
func set_streak(n: int) -> void:
	streak = n
	visible = n >= 2
	queue_redraw()
	if visible and UI.animations:
		pivot_offset = size * 0.5
		scale = Vector2(1.18, 1.18)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	if size.x <= 4.0 or size.y <= 4.0:
		return
	var col := tier_color(streak)
	var radius := int(size.y * 0.5)

	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.42)
	track.set_corner_radius_all(radius)
	track.set_border_width_all(1)
	track.border_color = Color(col, 0.35)
	draw_style_box(track, Rect2(Vector2.ZERO, size))

	var ratio := clampf(float(streak) / float(COMBO_MAX), 0.0, 1.0)
	if ratio > 0.0:
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(col, 0.85)
		fill.set_corner_radius_all(radius)
		fill.shadow_color = Color(col, 0.5)
		fill.shadow_size = 10
		var fw := maxf((size.x - 4.0) * ratio, size.y - 4.0)
		draw_style_box(fill, Rect2(Vector2(2, 2), Vector2(fw, size.y - 4.0)))

	for i in range(1, COMBO_MAX):
		var x := 2.0 + (size.x - 4.0) * float(i) / float(COMBO_MAX)
		draw_rect(Rect2(x - 0.5, size.y * 0.28, 1.0, size.y * 0.44), Color(0, 0, 0, 0.35))

	var txt := "连击 x%d  ×%.1f" % [streak, multiplier(streak)]
	var f := UI.font()
	var fs := int(size.y * 0.5)
	if fs < 10:
		fs = 10
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2((size.x - w) * 0.5, size.y * 0.5 + float(fs) * 0.36), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.96))
