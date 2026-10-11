extends Node
## 线程化场景切换：后台预加载目标场景，加载完成后切换，避免切换瞬间掉帧。
## 用法：Scene.goto("res://scenes/WorldMap.tscn")
## 维护「场景历史栈」，供手机返回键 / 返回操作逐级回退；到根场景无路可退时询问退出。

const MAX_HISTORY := 24
## 根场景：从这里返回应退出程序(或询问退出)，而不是继续回退。
const ROOT_SCENES := ["res://scenes/MainHub.tscn", "res://scenes/Login.tscn"]

var _pending := ""
## 上一个场景路径(供「设置」等模态页返回)
var previous: String = ""

var _history: Array[String] = []
var _last_back_msec := -100000

func goto(path: String, record: bool = true) -> void:
	if path.is_empty():
		return
	var cur := get_tree().current_scene
	var cur_path := ""
	if cur != null and not cur.scene_file_path.is_empty():
		cur_path = cur.scene_file_path
		previous = cur_path
		if record and cur_path != path:
			if _history.is_empty() or _history[_history.size() - 1] != cur_path:
				_history.push_back(cur_path)
				if _history.size() > MAX_HISTORY:
					_history.pop_front()
	# 进入根场景(登录/首页)时清空历史，避免返回时回到启动屏等入口造成循环
	if path in ROOT_SCENES:
		_history.clear()
	if not ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
		return
	if _pending == path:
		return
	_pending = path
	var err := ResourceLoader.load_threaded_request(path, "", true)
	if err != OK:
		_pending = ""
		get_tree().change_scene_to_file(path)
		return
	set_process(true)

## 回退到上一个场景；成功返回 true，无路可退返回 false。
func back() -> bool:
	var cur := get_tree().current_scene
	var cur_path := ""
	if cur != null:
		cur_path = cur.scene_file_path
	var target := ""
	while not _history.is_empty():
		var p: String = _history.pop_back()
		if p != cur_path and ResourceLoader.exists(p):
			target = p
			break
	if target.is_empty():
		return false
	_pending = ""
	goto(target, false)
	return true

## 处理一次「返回」请求：先关闭弹窗/面板，再存档，然后回退；无路可退才询问退出。
func handle_back() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_back_msec < 250:
		return
	_last_back_msec = now
	# 1) 已弹出的确认框：先关闭它
	if UI._active_confirm != null and is_instance_valid(UI._active_confirm):
		UI._active_confirm.queue_free()
		UI._active_confirm = null
		return
	# 2) 当前场景若有面板/弹窗，交给它自行处理(返回 true 表示已消费)
	var cur := get_tree().current_scene
	if cur != null and cur.has_method("_on_back_requested"):
		if bool(cur.call("_on_back_requested")):
			return
	# 3) 存档后再回退，确保「返回」不会丢进度
	if GameData.current_user != "":
		GameData.save_now()
	if back():
		return
	# 4) 无路可退：询问退出
	if cur != null and cur is CanvasItem:
		UI.confirm(cur, "退出游戏", "确定要退出吗？", func() -> void:
			if GameData.current_user != "":
				GameData.save_now()
			get_tree().quit())
	else:
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	# 桌面 Esc / Android 软返回若映射到 ui_cancel，统一走返回逻辑
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		handle_back()

func _notification(what: int) -> void:
	# Android 物理/手势返回键
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back()

func _process(_delta: float) -> void:
	if _pending.is_empty():
		set_process(false)
		return
	var status := ResourceLoader.load_threaded_get_status(_pending)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var packed := ResourceLoader.load_threaded_get(_pending) as PackedScene
			var target := _pending
			_pending = ""
			set_process(false)
			if packed != null:
				get_tree().change_scene_to_packed(packed)
			else:
				get_tree().change_scene_to_file(target)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			var target := _pending
			_pending = ""
			set_process(false)
			get_tree().change_scene_to_file(target)
