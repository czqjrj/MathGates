extends Node
## F4：桌面端键盘操作层（全局 autoload）。
##
## 只处理**未被 UI 消费**的按键（`_unhandled_key_input`），所以：
##   - 输入框里打字不受影响；
##   - 按钮获得焦点时，Enter/Space 仍走引擎默认激活。
##
## 键位：
##   1..9        选第 n 个选项（与鼠标点击走同一 `pressed` 通道）
##   Enter       提交 / 下一关（实验轮的「确认」优先）
##   ←/→/↑/↓     在「选项 → 下一关 → 提示」之间移动焦点（焦点环由按钮 focus 样式显示）
##   H           提示
##   W/A/S/D     3D 关卡调整视角（仅当舞台有 `_view3d`）
##   Esc / M     仍由 Scene / Sound 的全局处理负责

## 返回是否消费了该按键（便于测试直接驱动，无头环境不用造 InputEvent）。
static func handle(stage: Node, code: int) -> bool:
	if stage == null or not is_instance_valid(stage):
		return false
	# 数字选项
	if code >= KEY_1 and code <= KEY_9:
		return _choose(stage, int(code - KEY_1))
	match code:
		KEY_ENTER, KEY_KP_ENTER:
			return _submit(stage)
		KEY_LEFT, KEY_UP:
			return _move_focus(stage, -1)
		KEY_RIGHT, KEY_DOWN:
			return _move_focus(stage, 1)
		KEY_H:
			return _press(stage.get("_hint"))
		KEY_W, KEY_A, KEY_S, KEY_D:
			return _pan_view(stage, code)
	return false

func _unhandled_key_input(e: InputEvent) -> void:
	var k := e as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if handle(get_tree().current_scene, int(k.keycode)):
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- 内部

static func _visible_buttons(stage: Node) -> Array:
	var out: Array = []
	var btns: Variant = stage.get("_opt_btns")
	if btns is Array:
		for b in (btns as Array):
			if _usable(b):
				out.append(b)
	for nm in ["_next", "_hint", "_kb_confirm"]:
		var b: Variant = stage.get(nm)
		if _usable(b):
			out.append(b)
	return out

static func _usable(b: Variant) -> bool:
	if b == null or not (b is Button) or not is_instance_valid(b):
		return false
	var c := b as Button
	return c.is_visible_in_tree() and not c.disabled

static func _press(b: Variant) -> bool:
	if not _usable(b):
		return false
	(b as Button).grab_focus()
	(b as Button).pressed.emit()
	return true

static func _choose(stage: Node, idx: int) -> bool:
	var opts: Array = []
	var btns: Variant = stage.get("_opt_btns")
	if btns is Array:
		for b in (btns as Array):
			if _usable(b):
				opts.append(b)
	if idx < 0 or idx >= opts.size():
		return false
	return _press(opts[idx])

## Enter：实验轮「确认」优先，其次「下一关」，最后激活当前焦点按钮。
static func _submit(stage: Node) -> bool:
	if _press(stage.get("_kb_confirm")):
		return true
	if _press(stage.get("_next")):
		return true
	var f := stage.get_viewport().gui_get_focus_owner() if stage.is_inside_tree() else null
	if f is Button and _usable(f):
		(f as Button).pressed.emit()
		return true
	return false

## 焦点环：选项 → 下一关 → 提示。（没有焦点时按 dir 落到首/尾）
static func _move_focus(stage: Node, dir: int) -> bool:
	var ring := _visible_buttons(stage)
	if ring.is_empty():
		return false
	var cur: Control = null
	if stage.is_inside_tree():
		cur = stage.get_viewport().gui_get_focus_owner()
	var at := ring.find(cur)
	var n := ring.size()
	var nxt := 0 if at < 0 else (((at + dir) % n) + n) % n
	(ring[nxt] as Button).grab_focus()
	return true

## W/A/S/D → 3D 视角；没有 3D 视图的舞台不消费（避免抢走其他用途）。
static func _pan_view(stage: Node, code: int) -> bool:
	var v: Variant = stage.get("_view3d")
	if v == null or not is_instance_valid(v) or not v.has_method("key_pan"):
		return false
	var dx := 0.0
	var dy := 0.0
	match code:
		KEY_A: dx = -1.0
		KEY_D: dx = 1.0
		KEY_W: dy = -1.0
		KEY_S: dy = 1.0
	v.key_pan(dx, dy)
	return true
