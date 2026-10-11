class_name Tts
extends RefCounted
## 语音朗读子系统(从 UI 抽出，UI.tts_* 保留薄转发)。
## 系统 TTS(system)离线朗读，或在线音源(online: 百度/有道)；
## 平台不支持或未装引擎时所有接口安全空操作。开关/语速由 Settings 经 configure() 注入。

## 语音引擎：system(离线系统 TTS) / online(在线百度·有道)。
static var engine := "system"
## 在线音源：baidu / youdao。
static var provider := "baidu"
static var enabled := true
static var rate := 1.0
static var volume := 1.0
## 用户选择的声线 id；空串表示"自动"。
static var voice_id := ""

static var _online_script := preload("res://scripts/ui/TtsOnline.gd")
static var _online: Node

static var _done := false
static var _supported := false
static var _default_voice := ""
static var _default_cute := ""
static var _voice := ""
static var _cute_voice := ""
static var _last := ""
static var _last_cute := false

## 萌宠音色关键词：优先童声/女声，读起来更萌。
const CUTE_KEYS := ["yaoyao", "yao", "xiaoxiao", "xiaoyi", "huihui", "xiaomo",
	"child", "kid", "girl", "female", "女", "童"]

static func _ensure() -> void:
	if _done:
		return
	_done = true
	_supported = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
	if _supported:
		_default_voice = _pick_voice()
		_default_cute = _pick_cute_voice(_default_voice)
	_select_voice()

## 依据 voice_id 决定实际使用的(主/萌宠)声线；用户选择优先，非法或为空则用默认。
static func _select_voice() -> void:
	if not _supported:
		_voice = ""
		_cute_voice = ""
		return
	if not voice_id.is_empty() and voice_id in _all_ids():
		_voice = voice_id
		_cute_voice = voice_id
	else:
		_voice = _default_voice
		_cute_voice = _default_cute

static func _all_ids() -> Array:
	var ids: Array = []
	for v in DisplayServer.tts_get_voices():
		ids.append(str(v.get("id", "")))
	return ids

static func _pick_voice() -> String:
	for lang in ["zh_CN", "zh", "zh_TW", "zh_Hans"]:
		var vs := DisplayServer.tts_get_voices_for_language(lang)
		if vs.size() > 0:
			return vs[0]
	var all := DisplayServer.tts_get_voices()
	if all.size() > 0:
		return str(all[0].get("id", ""))
	return ""

## 在(中文)声线里挑一个"萌"音色：匹配关键词，找不到就用 fallback。
static func _pick_cute_voice(fallback: String) -> String:
	var zh := DisplayServer.tts_get_voices_for_language("zh_CN")
	if zh.is_empty():
		zh = DisplayServer.tts_get_voices_for_language("zh")
	var pool: Array = []
	for vid in zh:
		pool.append(str(vid))
	if pool.is_empty():
		for v in DisplayServer.tts_get_voices():
			pool.append(str(v.get("id", "")))
	for key in CUTE_KEYS:
		for vid in pool:
			if vid.to_lower().find(key) != -1:
				return vid
	return fallback

static func available() -> bool:
	if engine == "online":
		return true
	_ensure()
	return _supported and not _voice.is_empty()

## 列出可切换的声线：中文优先，其余在后；每项 {id, name, language}。
static func list_voices() -> Array:
	_ensure()
	var all: Array = []
	for v in DisplayServer.tts_get_voices():
		all.append({
			"id": str(v.get("id", "")),
			"name": str(v.get("name", "")),
			"language": str(v.get("language", "")),
		})
	all.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var az := str(a["language"]).begins_with("zh")
		var bz := str(b["language"]).begins_with("zh")
		if az != bz:
			return az
		return str(a["name"]) < str(b["name"]))
	return all

static func configure(p_enabled: bool, p_rate: float, p_volume: float = 1.0, p_voice_id: String = "", p_engine: String = "system", p_provider: String = "baidu") -> void:
	enabled = p_enabled
	rate = clampf(p_rate, 0.5, 1.8)
	volume = clampf(p_volume, 0.0, 1.0)
	voice_id = p_voice_id
	engine = p_engine
	provider = p_provider
	_ensure()
	_select_voice()
	if not enabled:
		stop()

## 在线引擎的常驻节点(懒创建)。
static func _online_manager() -> Node:
	if _online != null and is_instance_valid(_online):
		return _online
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var n: Node = _online_script.new()
	n.name = "TtsOnline"
	tree.root.add_child.call_deferred(n)
	_online = n
	return n

## cute=true 用萌宠音色 + 高音调 + 略快语速。
static func say(text: String, interrupt: bool = true, cute: bool = false) -> void:
	if not enabled:
		return
	var t := sanitize(text)
	if t.is_empty():
		return
	_last = t
	_last_cute = cute
	if engine == "online":
		var mgr := _online_manager()
		if mgr != null:
			mgr.speak(t, provider, rate, cute)
			return
	if not available():
		return
	var voice := _voice
	var pv := 1.0
	var rv := rate
	if cute:
		if not _cute_voice.is_empty():
			voice = _cute_voice
		pv = 1.55
		rv = rate * 1.06
	DisplayServer.tts_speak(t, voice, int(round(volume * 100.0)), pv, rv, 0, interrupt)

static func repeat() -> void:
	if not _last.is_empty():
		say(_last, true, _last_cute)

static func stop() -> void:
	if _online != null and is_instance_valid(_online):
		_online.stop()
	_ensure()
	if _supported:
		DisplayServer.tts_stop()

## 清洗文本：去除 BBCode 标记，并把常用数学符号转成可朗读文字。
static func sanitize(text: String) -> String:
	var t := text.replace("\r", "\n")
	var out := ""
	var i := 0
	var n := t.length()
	while i < n:
		var c := t[i]
		if c == "[":
			var j := t.find("]", i)
			if j != -1:
				i = j + 1
				continue
		out += c
		i += 1
	out = out.replace("\n", "，").replace("\t", " ")
	var rep := {
		"√": "根号", "≤": "小于等于", "≥": "大于等于", "≠": "不等于",
		"≈": "约等于", "±": "正负", "⊥": "垂直", "∥": "平行",
		"∠": "角", "△": "三角形", "°": "度", "π": "派",
		"·": "点", "×": "乘以", "÷": "除以", "→": "到",
		"Δ": "德尔塔", "α": "阿尔法", "β": "贝塔", "θ": "西塔",
		"∞": "无穷", "∈": "属于", "∪": "并", "∩": "交",
		"∑": "求和", "φ": "斐", "λ": "兰姆达",
	}
	for k in rep:
		out = out.replace(k, rep[k])
	return out.strip_edges()
