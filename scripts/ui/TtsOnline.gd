extends Node
## 在线语音合成(HTTP GET，无需密钥)：支持百度翻译 / 有道词典的 TTS 接口。
## 流程：按句切分 → 逐句请求 MP3 → 缓存到 user://tts_cache → 顺序播放。
## 失败时静默跳过(不抛出)；由 UI 负责是否回退系统 TTS。

const CACHE_DIR := "user://tts_cache"
const MAX_CHARS := 120
const UA := "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

var _provider := "baidu"
var _speed := 5            # 百度 spd 1..5
var _pitch := 1.0          # 播放音调(兼变速)
var _volume_db := 0.0
var _token := 0
var _chunks: Array = []
var _idx := 0

var _req: HTTPRequest
var _players: Array[AudioStreamPlayer] = []
var _setup_done := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_setup()

func _ensure_setup() -> void:
	if _setup_done:
		return
	_setup_done = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_req = HTTPRequest.new()
	add_child(_req)

## 朗读一段文本；会打断上一段。rate 0.5..1.8，cute 时音调更高更萌。
func speak(text: String, provider: String, rate: float, cute: bool) -> void:
	_ensure_setup()
	stop()
	_provider = provider if provider in ["baidu", "youdao"] else "baidu"
	_speed = clampi(int(round(5.0 * rate)), 1, 5)
	_pitch = 1.12 if cute else 1.0
	_chunks = _split(text)
	_idx = 0
	if _chunks.is_empty():
		return
	_run(_token)

func stop() -> void:
	_token += 1
	for p in _players:
		p.stop()
	if _req != null:
		_req.cancel_request()
# ---------------------------------------------------------------- 内部流程
func _run(token: int) -> void:
	# 等待一帧，确保节点(及其 HTTPRequest 子节点)已进入场景树。
	if not is_inside_tree():
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			await tree.process_frame
	while token == _token and _idx < _chunks.size():
		var chunk := str(_chunks[_idx])
		_idx += 1
		var bytes := await _fetch(chunk)
		if token != _token:
			return
		if bytes.is_empty():
			continue
		await _play(bytes, token)

func _fetch(chunk: String) -> PackedByteArray:
	var path := "%s/%s.mp3" % [CACHE_DIR, _cache_key(chunk)]
	if FileAccess.file_exists(path):
		var cached := FileAccess.get_file_as_bytes(path)
		if cached.size() > 0:
			return cached
	_req.cancel_request()
	var err := _req.request(_build_url(chunk), _headers())
	if err != OK:
		return PackedByteArray()
	var res: Array = await _req.request_completed
	var code := int(res[1])
	var body: PackedByteArray = res[3]
	if code == 200 and body.size() > 0:
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_buffer(body)
		return body
	return PackedByteArray()

func _play(bytes: PackedByteArray, token: int) -> void:
	var mp3 := AudioStreamMP3.new()
	mp3.data = bytes
	var p := _free_player()
	p.stream = mp3
	p.pitch_scale = _pitch
	p.volume_db = _volume_db
	p.play()
	var dur := mp3.get_length() / maxf(_pitch, 0.1) + 0.06
	await get_tree().create_timer(dur).timeout

func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

func _build_url(chunk: String) -> String:
	var q := chunk.uri_encode()
	if _provider == "youdao":
		return "https://dict.youdao.com/dictvoice?le=zh&audio=%s" % q
	return "https://fanyi.baidu.com/gettts?lan=zh&text=%s&spd=%d&source=web" % [q, _speed]

func _headers() -> PackedStringArray:
	if _provider == "youdao":
		return PackedStringArray([
			"User-Agent: " + UA,
			"Referer: https://dict.youdao.com/",
		])
	return PackedStringArray([
		"User-Agent: " + UA,
		"Referer: https://fanyi.baidu.com/",
	])

func _cache_key(chunk: String) -> String:
	var c := HashingContext.new()
	c.start(HashingContext.HASH_SHA256)
	c.update(("%s|%d|%s" % [_provider, _speed, chunk]).to_utf8_buffer())
	return c.finish().hex_encode()

## 按标点切成 <= MAX_CHARS 的短句，避免长文本被接口截断。
func _split(text: String) -> Array:
	var out: Array = []
	var buf := ""
	var seps := "。！？!?；;，,、\n"
	for i in text.length():
		var ch := text[i]
		buf += ch
		var is_sep := seps.find(ch) != -1
		if (is_sep and buf.length() >= 8) or buf.length() >= MAX_CHARS:
			var s := buf.strip_edges()
			if not s.is_empty():
				out.append(s)
			buf = ""
	if not buf.strip_edges().is_empty():
		out.append(buf.strip_edges())
	return out
