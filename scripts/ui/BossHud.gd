class_name BossHud
extends Control
## BOSS 关战斗 HUD(仅 BOSS 关由 StageBase 启用，普通关不创建)。
##
## 呈现「推演者 ↔ 守关者」双方六边形头像与血条，以及连击读数。
## 血量映射：守关者 = 剩余关卡数(答对扣 1)；推演者 = 关卡数 + 容错 − 累计错答。
## 血量归零判定由 StageBase 负责，本类只维护数值与本地观感(抖动/淡出)。
##
## 坐标约定：本控件是覆盖在图形区顶部的一条窄带，**不是**铺满屏幕的层，
## 因此不在此处调用需要全屏父级的 Vfx.burst/float_text——那些由 StageBase 用 _ui 播。

## 守关者血量首次降到阈值及以下时发出(供 StageBase 播「狂暴」反馈)。
signal enraged

class HexAvatar extends Control:
	var letter := "?"
	var col := Color("#5ee6ff")
	var fs := 30

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 3.0
		if r <= 1.0:
			return
		var pts := PackedVector2Array()
		for i in range(6):
			var a := -PI / 2.0 + float(i) * TAU / 6.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Color(0.05, 0.07, 0.12, 0.78))
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(col, 0.85), 2.0, true)
		var inner := PackedVector2Array()
		for i in range(6):
			var a := -PI / 2.0 + float(i) * TAU / 6.0
			inner.append(c + Vector2(cos(a), sin(a)) * (r * 0.8))
		inner.append(inner[0])
		draw_polyline(inner, Color(col, 0.22), 1.0, true)
		var f := UI.font()
		var w := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, c + Vector2(-w * 0.5, fs * 0.35), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.COL_TEXT)

class HpBar extends Control:
	var value := 5
	var max_value := 5
	var base_color: Color = UI.COL_ACCENT

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func set_hp(v: int) -> void:
		value = v
		queue_redraw()

	func _draw() -> void:
		var track := StyleBoxFlat.new()
		track.bg_color = Color(0, 0, 0, 0.4)
		track.set_corner_radius_all(4)
		track.set_border_width_all(1)
		track.border_color = Color(1, 1, 1, 0.16)
		draw_style_box(track, Rect2(Vector2.ZERO, size))

		var ratio := clampf(float(value) / float(maxi(1, max_value)), 0.0, 1.0)
		if ratio > 0.01:
			var hot := ratio <= 0.34
			var fc: Color = UI.COL_DANGER if hot else base_color
			var fill := StyleBoxFlat.new()
			fill.bg_color = fc
			fill.set_corner_radius_all(4)
			fill.shadow_color = Color(fc, 0.5)
			fill.shadow_size = 12
			fill.shadow_offset = Vector2.ZERO
			draw_style_box(fill, Rect2(Vector2(2, 2), Vector2(maxf((size.x - 4.0) * ratio, 1.0), size.y - 4.0)))

		if max_value > 1:
			for i in range(1, max_value):
				var x := size.x * float(i) / float(max_value)
				draw_rect(Rect2(x - 1.0, 6.0, 2.0, size.y - 12.0), Color(0, 0, 0, 0.5))

# ---------------------------------------------------------------- 状态
var _boss_title := "守关者"
var _boss_name := "守关者"
var _boss_avatar := "验"
var _boss_color := Color("#ff5e7a")

var _boss_max := 5
var _boss_hp := 5
var _player_max := 5
var _player_hp := 5
var _enrage_at := 0.5
var _enraged := false

# ---------------------------------------------------------------- 控件
var _pbar: HpBar
var _bbar: HpBar
var _plbl: Label
var _blbl: Label
var _streak_lbl: Label
var _title_lbl: Label
var _bav: Control
var _pav: Control

## 按配置与关卡总数构建战斗 HUD。total = 关卡阶段数。
## boss 可用字段：title/name/avatar/color/enrage_at/player_hp_bonus。
func configure(boss: Dictionary, total: int, fallback_title: String = "守关者") -> void:
	_boss_title = str(boss.get("title", fallback_title))
	_boss_name = str(boss.get("name", _boss_title))
	_boss_avatar = str(boss.get("avatar", "验"))
	_boss_color = Color(str(boss.get("color", "#ff5e7a")))
	_boss_max = maxi(1, total)
	_boss_hp = _boss_max
	_player_max = maxi(1, total + int(boss.get("player_hp_bonus", 1)))
	_player_hp = _player_max
	_enrage_at = clampf(float(boss.get("enrage_at", 0.5)), 0.05, 1.0)
	_enraged = false
	_build()

func _build() -> void:
	for c in get_children():
		c.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var lay := UI.stage_layout()
	offset_left = float(lay["view_left"])
	offset_right = -18.0
	offset_top = 70.0
	offset_bottom = 70.0 + 92.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UI.glass_box(Color(0.03, 0.05, 0.09, 0.82), 14, Color(_boss_color, 0.4), 1, 12, Color(_boss_color, 0.25), 10))
	UI.full_rect(panel)
	add_child(panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hb)

	# 左：推演者
	_pav = _hex("推", UI.COL_ACCENT, 56)
	hb.add_child(_pav)
	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 5)
	pvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pvb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(pvb)
	_plbl = UI.mono_label("推演者", 12, Color(UI.COL_ACCENT, 0.95))
	pvb.add_child(_plbl)
	_pbar = HpBar.new()
	_pbar.base_color = UI.COL_ACCENT
	_pbar.custom_minimum_size = Vector2(0, 20)
	_pbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pvb.add_child(_pbar)

	# 中：守关者称号 + 连击
	var mvb := VBoxContainer.new()
	mvb.add_theme_constant_override("separation", 5)
	mvb.alignment = BoxContainer.ALIGNMENT_CENTER
	mvb.custom_minimum_size = Vector2(140, 0)
	hb.add_child(mvb)
	_title_lbl = UI.mono_label(_boss_title, 13, Color(_boss_color, 0.95), HORIZONTAL_ALIGNMENT_CENTER)
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mvb.add_child(_title_lbl)
	_streak_lbl = UI.mono_label("", 14, Color("#ffd479"), HORIZONTAL_ALIGNMENT_CENTER)
	mvb.add_child(_streak_lbl)

	# 右：守关者
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 5)
	bvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bvb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(bvb)
	_blbl = UI.mono_label(_boss_name, 12, Color(_boss_color, 0.95), HORIZONTAL_ALIGNMENT_RIGHT)
	bvb.add_child(_blbl)
	_bbar = HpBar.new()
	_bbar.base_color = _boss_color
	_bbar.custom_minimum_size = Vector2(0, 20)
	_bbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bvb.add_child(_bbar)

	_bav = _hex(_boss_avatar, _boss_color, 56)
	hb.add_child(_bav)

	_refresh()

func _hex(letter: String, col: Color, px: int) -> Control:
	var box := CenterContainer.new()
	box.custom_minimum_size = Vector2(px, px)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HexAvatar.new()
	h.letter = letter
	h.col = col
	h.fs = int(px * 0.42)
	h.custom_minimum_size = Vector2(px, px)
	box.add_child(h)
	return box

func _refresh() -> void:
	if _pbar != null:
		_pbar.max_value = _player_max
		_pbar.set_hp(_player_hp)
	if _bbar != null:
		_bbar.max_value = _boss_max
		_bbar.set_hp(_boss_hp)
	if _plbl != null:
		_plbl.text = "推演者  %d / %d" % [_player_hp, _player_max]
	if _blbl != null:
		_blbl.text = "%s  %d / %d" % [_boss_name, _boss_hp, _boss_max]

func set_streak(n: int) -> void:
	if _streak_lbl == null:
		return
	_streak_lbl.text = "连击 x%d" % n if n >= 2 else ""

func boss_color() -> Color:
	return _boss_color

func boss_avatar_center() -> Vector2:
	if _bav == null or not is_instance_valid(_bav):
		return global_position + size * 0.5
	return _bav.get_global_rect().get_center()

func player_avatar_center() -> Vector2:
	if _pav == null or not is_instance_valid(_pav):
		return global_position + size * 0.5
	return _pav.get_global_rect().get_center()

## 答对：守关者掉 1 血。返回本次是否触发狂暴。
func hit_boss() -> bool:
	_boss_hp = maxi(0, _boss_hp - 1)
	_refresh()
	if _bbar != null:
		Vfx.wobble(_bbar, 9.0, 0.4)
	if _bav != null:
		Vfx.wobble(_bav, 9.0, 0.4)
	var now := false
	if not _enraged and float(_boss_hp) / float(maxi(1, _boss_max)) <= _enrage_at:
		_enraged = true
		now = true
		enraged.emit()
	return now

## 答错：推演者掉 1 血。返回玩家是否已倒下。
func hit_player() -> bool:
	_player_hp = maxi(0, _player_hp - 1)
	_refresh()
	if _pbar != null:
		Vfx.wobble(_pbar, 9.0, 0.4)
	if _pav != null:
		Vfx.wobble(_pav, 9.0, 0.4)
	return _player_hp <= 0

func is_player_down() -> bool:
	return _player_hp <= 0

func is_enraged() -> bool:
	return _enraged

## 重置血量为满值、清除狂暴与淡出状态(供「重新挑战」)。
func reset() -> void:
	_boss_hp = _boss_max
	_player_hp = _player_max
	_enraged = false
	if _bav != null and is_instance_valid(_bav):
		_bav.modulate.a = 1.0
		_bav.scale = Vector2.ONE
	if _pav != null and is_instance_valid(_pav):
		_pav.modulate = Color.WHITE
	set_streak(0)
	_refresh()

## 击败演出：守关者头像淡出 + 缩放。
func boss_defeated() -> void:
	if _bav != null and is_instance_valid(_bav):
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_bav, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_bav, "scale", Vector2(1.4, 1.4), 0.7).set_trans(Tween.TRANS_BACK)

## 推演者倒下：推演者头像变暗。
func player_down() -> void:
	if _pav != null and is_instance_valid(_pav):
		var tw := create_tween()
		tw.tween_property(_pav, "modulate", Color(0.5, 0.5, 0.5, 0.5), 0.5)
