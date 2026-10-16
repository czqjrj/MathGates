extends Node
## 全局设置：字号、音效、萌宠、全屏、界面动效等可配置项统一在此定义、持久化并分发。
## 其余系统一律从这里取值(如 UI.fs() 读 UI.S)，不再硬编码。
## 存档：user://settings.json

signal changed

const PATH := "user://settings.json"

const FONT_MIN := 1.0
const FONT_MAX := 2.0
const FONT_STEP := 0.1

const DEFAULTS := {
	"font_scale": 1.4,
	"sfx_volume": 1.0,
	"show_pet": true,
	"fullscreen": false,
	"animations": true,
	"voice": true,
	"voice_rate": 1.0,
	"voice_id": "",
	"tts_engine": "online",
	"tts_provider": "baidu",
	"textbook": "sujiao",
	"editor_mode": false,
	"challenge_timer": true,
}

var font_scale: float = 1.4
var sfx_volume: float = 1.0
var show_pet: bool = true
var fullscreen: bool = false
var animations: bool = true
var voice: bool = true
var voice_rate: float = 1.0
var voice_id: String = ""
var tts_engine: String = "online"
var tts_provider: String = "baidu"
## 高中数学教材版本(苏教/人教A/北师大…)：决定知识体系与方法推演的章节排序与分册归属。
var textbook: String = "sujiao"
## 编辑模式：开启后可无条件解锁所有关卡，方便测试与编辑
var editor_mode: bool = false
## 关卡计时：关闭后，带时限的关卡不再计时(不显示计时、无超时/极速奖励)。
var challenge_timer: bool = true

func _ready() -> void:
	load_settings()
	apply(false)

func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	font_scale = clampf(float(data.get("font_scale", DEFAULTS["font_scale"])), FONT_MIN, FONT_MAX)
	sfx_volume = clampf(float(data.get("sfx_volume", DEFAULTS["sfx_volume"])), 0.0, 1.0)
	show_pet = bool(data.get("show_pet", DEFAULTS["show_pet"]))
	fullscreen = bool(data.get("fullscreen", DEFAULTS["fullscreen"]))
	animations = bool(data.get("animations", DEFAULTS["animations"]))
	voice = bool(data.get("voice", DEFAULTS["voice"]))
	voice_rate = clampf(float(data.get("voice_rate", DEFAULTS["voice_rate"])), 0.5, 1.8)
	voice_id = str(data.get("voice_id", DEFAULTS["voice_id"]))
	tts_engine = str(data.get("tts_engine", DEFAULTS["tts_engine"]))
	tts_provider = str(data.get("tts_provider", DEFAULTS["tts_provider"]))
	textbook = str(data.get("textbook", DEFAULTS["textbook"]))
	editor_mode = bool(data.get("editor_mode", DEFAULTS["editor_mode"]))
	challenge_timer = bool(data.get("challenge_timer", DEFAULTS["challenge_timer"]))

func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	var out := {}
	for k in DEFAULTS.keys():
		out[k] = get(k)
	f.store_string(JSON.stringify(out))

## 把设置同步到各子系统(启动与「恢复默认」时调用)
func apply(notify: bool = true) -> void:
	UI.S = font_scale
	UI.animations = animations
	if Sound != null:
		Sound.volume_scale = sfx_volume
	UI.tts_configure(voice, voice_rate, 1.0, voice_id, tts_engine, tts_provider)
	_apply_fullscreen()
	if GameData != null:
		GameData.set_free_roam(editor_mode)
	if notify:
		changed.emit()

func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)

# ---------------------------------------------------------------- 修改入口
func set_font_scale(v: float) -> void:
	font_scale = clampf(v, FONT_MIN, FONT_MAX)
	UI.S = font_scale
	save()
	changed.emit()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	if Sound != null:
		Sound.volume_scale = sfx_volume
	save()
	changed.emit()

func set_show_pet(v: bool) -> void:
	show_pet = v
	save()
	changed.emit()

func set_fullscreen(v: bool) -> void:
	fullscreen = v
	_apply_fullscreen()
	save()
	changed.emit()

func set_animations(v: bool) -> void:
	animations = v
	UI.animations = animations
	save()
	changed.emit()

func set_voice(v: bool) -> void:
	voice = v
	UI.tts_configure(voice, voice_rate, 1.0, voice_id, tts_engine, tts_provider)
	save()
	changed.emit()

func set_voice_rate(v: float) -> void:
	voice_rate = clampf(v, 0.5, 1.8)
	UI.tts_configure(voice, voice_rate, 1.0, voice_id, tts_engine, tts_provider)
	save()
	changed.emit()

func set_voice_id(id: String) -> void:
	voice_id = id
	UI.tts_configure(voice, voice_rate, 1.0, voice_id, tts_engine, tts_provider)
	save()
	changed.emit()

func set_tts_engine(v: String) -> void:
	tts_engine = v if v in ["system", "online"] else "system"
	UI.tts_configure(voice, voice_rate, 1.0, voice_id, tts_engine, tts_provider)
	save()
	changed.emit()

func set_tts_provider(v: String) -> void:
	tts_provider = v if v in ["baidu", "youdao"] else "baidu"
	UI.tts_configure(voice, voice_rate, 1.0, voice_id, tts_engine, tts_provider)
	save()
	changed.emit()

## 切换教材版本：同步给 GameData(重排章节、清空自定义排序)，再持久化。
func set_textbook(v: String) -> void:
	textbook = v
	if GameData != null:
		GameData.set_textbook(v)
	save()
	changed.emit()

func set_editor_mode(v: bool) -> void:
	editor_mode = v
	if GameData != null:
		GameData.set_free_roam(v)
	save()
	changed.emit()

func set_challenge_timer(v: bool) -> void:
	challenge_timer = v
	save()
	changed.emit()

func reset_defaults() -> void:
	for k in DEFAULTS.keys():
		set(k, DEFAULTS[k])
	if GameData != null:
		GameData.set_textbook(str(DEFAULTS["textbook"]))
	apply()
	save()
