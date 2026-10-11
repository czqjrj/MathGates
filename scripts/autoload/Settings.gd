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

func reset_defaults() -> void:
	for k in DEFAULTS.keys():
		set(k, DEFAULTS[k])
	apply()
	save()
