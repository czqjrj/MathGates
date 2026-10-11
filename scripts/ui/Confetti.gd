class_name Confetti
extends Control
## 关卡通关庆祝彩带（各主题关卡共享）。
## 用法：
##   var c := Confetti.new()
##   parent.add_child(c)
##   UI.full_rect(c)
##   c.begin()

const COLS := [Color("#5ee6ff"), Color("#7fd8ff"), Color("#ffd479"), Color("#34d399"), Color("#a878ff"), Color("#fb7185")]

## 彩带配色，可在 begin() 前覆盖。
var cols: Array = COLS

var pieces: Array = []
var _life := 0.0
var _max_life := 4.5
var _w := 1280.0
var _h := 720.0

## 便捷生成：挂到 parent 并铺满，随后开始播放(各关卡通关共用)。
static func spawn(parent: Control) -> Confetti:
	var c := Confetti.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	UI.full_rect(c)
	c.begin()
	return c

func begin() -> void:
	_w = size.x if size.x > 1.0 else 1280.0
	_h = size.y if size.y > 1.0 else 720.0
	for i in 120:
		pieces.append(_new_piece(randf_range(-_h, -6.0)))
	set_process(true)

func _new_piece(start_y: float) -> Dictionary:
	return {
		"pos": Vector2(randf_range(0.0, _w), start_y),
		"vel": Vector2(randf_range(-60.0, 60.0), randf_range(70.0, 190.0)),
		"rot": randf_range(0.0, TAU),
		"spin": randf_range(-7.0, 7.0),
		"size": Vector2(randf_range(6.0, 12.0), randf_range(9.0, 17.0)),
		"col": cols[randi() % cols.size()],
	}

func _process(delta: float) -> void:
	_life += delta
	for p in pieces:
		var v: Vector2 = p["vel"]
		v.y += 260.0 * delta
		v.x *= (1.0 - minf(0.9 * delta, 0.9))
		p["vel"] = v
		p["pos"] = (p["pos"] as Vector2) + v * delta
		p["rot"] = float(p["rot"]) + float(p["spin"]) * delta
		if (p["pos"] as Vector2).y > _h + 50.0:
			if _life < _max_life:
				p["pos"] = Vector2(randf_range(0.0, _w), randf_range(-70.0, -10.0))
				p["vel"] = Vector2(randf_range(-60.0, 60.0), randf_range(70.0, 190.0))
			else:
				p["pos"] = Vector2((p["pos"] as Vector2).x, 1e9)
	if _life > _max_life + 3.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var fade := clampf(1.0 - maxf(_life - _max_life, 0.0) / 3.0, 0.0, 1.0)
	for p in pieces:
		var base: Vector2 = p["pos"]
		if base.y > _h + 200.0:
			continue
		var s: Vector2 = p["size"]
		var c: Color = p["col"]
		c.a *= fade
		var r := float(p["rot"])
		var cs := cos(r)
		var sn := sin(r)
		var hx := s.x * 0.5
		var hy := s.y * 0.5
		var pts := PackedVector2Array()
		for cor in [Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)]:
			pts.append(base + Vector2(cor.x * cs - cor.y * sn, cor.x * sn + cor.y * cs))
		draw_colored_polygon(pts, c)
