extends Node
## 全局音效：纹理同级——按名在 res://audio/ 自动加载，找不到就静默跳过。
## 所有 Button 自动接线：按下 → click，悬停/聚焦 → hover。
## 特殊事件用 Sound.play("correct") 等手动触发。
##
## 素材文件名：click / hover / select / correct / wrong / star / unlock / error / complete / begin / deal
## 放 .wav / .ogg / .mp3 均可。

const DIR := "res://audio/"
const EXTS := [".wav", ".ogg", ".mp3"]
const POOL_SIZE := 14
const NAMES := ["click", "hover", "select", "correct", "wrong", "star", "unlock", "error", "complete", "begin", "deal"]

var enabled: bool = true
## 音效音量系数(0..1)，由 Settings 注入；0 视为静音。
var volume_scale: float = 1.0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _hover_cd: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	get_tree().node_added.connect(_on_node_added)
	for nm in NAMES:
		_load(nm)

func _process(delta: float) -> void:
	if _hover_cd > 0.0:
		_hover_cd -= delta

# ---------------------------------------------------------------- 播放
func _load(nm: String) -> AudioStream:
	if _streams.has(nm):
		return _streams[nm]
	var found: AudioStream = null
	for e in EXTS:
		var p: String = DIR + nm + e
		if ResourceLoader.exists(p):
			found = load(p)
			break
	_streams[nm] = found
	return found

func has(nm: String) -> bool:
	return _load(nm) != null

func play(nm: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not enabled:
		return
	var s := _load(nm)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.volume_db = volume_db + _gain_db()
	p.pitch_scale = pitch
	p.play()

func _gain_db() -> float:
	if volume_scale <= 0.001:
		return -80.0
	return linear_to_db(volume_scale)

## 带轻微随机音高，避免连续触发时机械重复
func play_varied(nm: String, volume_db: float = 0.0, spread: float = 0.06) -> void:
	play(nm, volume_db, 1.0 + randf_range(-spread, spread))

## 延迟播放(秒)
func play_delayed(nm: String, delay: float, volume_db: float = 0.0) -> void:
	if not enabled:
		return
	get_tree().create_timer(delay).timeout.connect(func(): play(nm, volume_db))

func toggle() -> void:
	enabled = not enabled

# ---------------------------------------------------------------- 按钮自动接线
func _on_node_added(n: Node) -> void:
	if n is Button and not n.has_meta("sfx_wired"):
		n.set_meta("sfx_wired", true)
		n.pressed.connect(_btn_pressed.bind(n))
		n.mouse_entered.connect(_btn_hover.bind(n))
		n.focus_entered.connect(_btn_hover.bind(n))

func _btn_pressed(btn: Button) -> void:
	var which := str(btn.get_meta("sfx_click", "click"))
	if which == "none":
		return
	play(which)

func _btn_hover(btn: Button) -> void:
	if btn.disabled or _hover_cd > 0.0:
		return
	_hover_cd = 0.035
	play_varied("hover", -7.0, 0.05)

# ---------------------------------------------------------------- 快捷键静音
func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_M:
		toggle()
		Toast.show_toast("音效已%s" % ("开启" if enabled else "关闭"))
