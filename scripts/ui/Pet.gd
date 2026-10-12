class_name Pet
extends Control
## 萌宠助手(纯代码绘制，无外部素材):
## 大眼睛+高光、软萌身体、小脚小手、触角；会随鼠标看、眨眼、呼吸浮动；
## 有情绪状态(开心/低落/思考/犯困睡觉)、开心时冒星星；可拖动、可点击。
## 智能：可 learn() 记住当前知识点，respond() 时先"思考"再讲出要点。

enum State { IDLE, HAPPY, SAD, SLEEP, THINK, EAT, CURIOUS, LOVE, ANGRY, DANCE }

const COL_BODY := Color("#6fe9ff")
const COL_BODY_DK := Color("#2aa7c4")
const COL_BODY_HI := Color("#d7f8ff")
const COL_BELLY := Color("#eaffff")
const COL_IRIS := Color("#2b6cff")
const COL_IRIS2 := Color("#7fd0ff")
const COL_EYE := Color("#12203a")
const COL_CHEEK := Color("#ff8fb0")
const COL_ANT := Color("#b48cff")
const COL_SPARK := Color("#ffe27a")
const COL_HEART := Color("#ff6f9c")
const COL_NOTE := Color("#a8e6ff")

const TIPS := [
	"今天也一起把定理点亮吧！",
	"错题别怕，复盘一次就记住啦～",
	"拖动我试试，我会跟着鼠标看哦",
	"点地图节点就能进入关卡啦",
	"累了就先休息，回头再来推演～",
	"每个高分，都是一道道题堆出来的！",
	"先看口诀，再做题，又快又准～",
	"卡住了？点提示，不丢人！",
	"问问我知识点，我会告诉你要点哦～",
	"右键喂我吃点东西吧～",
]
const CHEER := ["太棒了！", "稳了稳了～", "这题轻松拿下！", "漂亮，继续保持！", "思路很清晰！"]
const COMFORT := ["别灰心，再想想～", "差一点点，复盘一下！", "看右侧图形，再试试！", "错了正好记住它！"]
const CLINGY_TIERS := [
	[
		"你终于来了！我想死你啦～",
		"你好呀～今天也一起玩吧！",
		"来啦来啦，快来看看我～",
	],
	[
		"呜哇，你回来啦！快抱抱我～",
		"等你好久啦，今天也陪陪我好不好～",
		"我好想你！快摸摸我的头～",
	],
	[
		"你终于回来啦！！我等你等了好久好久～",
		"不许走嘛！再陪我一会儿好不好～",
		"嘿嘿，我就知道你会来！贴贴～",
		"想你想得冒泡泡了！快抱紧我～",
	],
]
const MEDAL_LINES := ["解锁勋章「%s」！好厉害～", "新勋章「%s」到手，快去看看～", "哇，拿到「%s」啦！"]
const HUNGRY_LINES := ["肚子咕咕叫…右键喂我一下嘛～", "有点饿了，投喂我好不好～", "饿扁啦…右键点我喂食嘛！"]

## 好感度等级：由投喂次数决定(0 初识 / 1 熟悉 / 2 黏人)
func affection_tier() -> int:
	return GameData.pet_affection_tier()

func _clingy_pool() -> Array:
	return CLINGY_TIERS[affection_tier()]

## 载入时撒娇：开心蹦跳 + 黏人台词(随好感度变化)
func clingy() -> void:
	_celebration_dur = 1.3
	_celebration = 1.3
	_celebration_big = false
	_happy(1.3)
	var pool := _clingy_pool()
	say(pool[randi() % pool.size()], 4.0)
	Sound.play("select")

var _t := 0.0
var _blink_t := 3.0
var _blinking := false
var _drag := false
var _moved := 0.0
var _last_tip := -1
var _state := State.IDLE
var _state_t := 0.0
var _idle := 0.0
var _auto := true
var _auto_t := 0.0
var _hover := false
var _bubble := 0.0
var _bubble_text := ""
var _sparks: Array = []       # {pos, vel, life, size}
var _know: Dictionary = {}    # {method, summary, hint}
var tap_provider := Callable()  # 点击时由外部注入"智能应答"；为空则随机提示
# 自主漫游
var _target := Vector2.ZERO
var _walk_wait := 0.0
var _walk_phase := 0.0
var _moving := false
var _face := 1.0
var _anchor := Vector2.ZERO
var _anchor_set := false
var _roam_radius := Vector2(46.0, 30.0)   # 只在起点附近的小范围内左右上下漫游
var _celebration := 0.0
var _celebration_dur := 1.9
var _celebration_big := false
var _spark_cd := 0.0
# 智能与养成扩展
var _combo := 0            # 连续答对数(跨题保持，答错清零)
var _grumble := 0          # 连续答错数
var _trick_cd := 3.0       # 自主小动作冷却
var _medal_ready := false  # 限制勋章反应延迟(避免登录回填时齐声庆祝)
var _aura := 0.0           # 光环脉动相位
var _quest: Dictionary = {}  # 当前提议的错题复习任务(点击萌宠前往)
var _quest_t := 0.0          # 任务窗口剩余时间

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(120, 120)
	_blink_t = randf_range(2.0, 4.0)
	mouse_entered.connect(func() -> void:
		_hover = true
		_wake()
	)
	mouse_exited.connect(func() -> void: _hover = false)
	_target = position
	_walk_wait = randf_range(0.8, 2.0)
	GameData.medal_unlocked.connect(_on_medal)
	GameData.pet_evolved.connect(_on_evolve)
	GameData.wrong_cleared.connect(_on_wrong_cleared)
	get_tree().create_timer(0.6).timeout.connect(func() -> void: _medal_ready = true)
	set_process(true)

func _bounds_of() -> Vector2:
	var b := Vector2.ZERO
	var par := get_parent()
	if par is Control:
		b = (par as Control).size
	if b.x < 4.0 or b.y < 4.0:
		b = get_viewport().get_visible_rect().size
	return b

func _pick_target() -> void:
	var r := _roam_radius
	var t := _anchor + Vector2(randf_range(-r.x, r.x), randf_range(-r.y, r.y))
	var b := _bounds_of()
	t.x = clampf(t.x, 0.0, maxf(b.x - size.x, 0.0))
	t.y = clampf(t.y, 0.0, maxf(b.y - size.y, 0.0))
	_target = t

func _roam_update(delta: float) -> void:
	if not _anchor_set:
		_anchor = position
		_anchor_set = true
	if _drag or _state == State.SLEEP or _bubble > 0.0:
		_moving = false
		return
	if _walk_wait > 0.0:
		_walk_wait -= delta
		_moving = false
		if _walk_wait <= 0.0:
			_pick_target()
		return
	var to := _target - position
	var dist := to.length()
	if dist < 5.0:
		_walk_wait = randf_range(1.0, 2.6)
		_moving = false
		return
	_moving = true
	var dir := to / dist
	position += dir * 22.0 * delta
	_walk_phase += delta * 6.0
	if absf(dir.x) > 0.05:
		_face = signf(dir.x)
	var b := _bounds_of()
	position.x = clampf(position.x, 0.0, maxf(b.x - size.x, 0.0))
	position.y = clampf(position.y, 0.0, maxf(b.y - size.y, 0.0))

## 通用入口：任何关卡场景只要调用 Pet.spawn(self) 即可获得萌宠。
static func spawn(parent: Node, greet: String = "") -> Pet:
	var layer := CanvasLayer.new()
	layer.name = "PetLayer"
	layer.layer = UiConst.LAYER_PET
	parent.add_child(layer)
	var pet := Pet.new()
	pet.size = Vector2(116, 116)
	var vp := parent.get_viewport().get_visible_rect().size
	pet.position = Vector2(vp.x - 150.0, vp.y - 172.0)
	layer.add_child(pet)
	# 出场弹入
	pet.pivot_offset = pet.size * 0.5
	if UI.animations:
		pet.scale = Vector2(0.25, 0.25)
		pet.create_tween().tween_property(pet, "scale", Vector2.ONE, 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not Settings.show_pet:
		pet.visible = false
		pet.set_process(false)
	if greet != "":
		pet.say(greet, 3.0)
	pet.try_autogreet()
	return pet

func learn(d: Dictionary) -> void:
	_know = d

func _process(delta: float) -> void:
	_t += delta
	# 眨眼
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blinking = not _blinking
		_blink_t = 0.12 if _blinking else randf_range(2.2, 4.5)
	# 情绪计时
	if _state == State.HAPPY or _state == State.SAD or _state == State.THINK \
		or _state == State.EAT or _state == State.LOVE or _state == State.CURIOUS \
		or _state == State.ANGRY or _state == State.DANCE:
		_state_t -= delta
		if _state_t <= 0.0:
			if _state == State.EAT:
				say("好吃！再来一个～", 2.0)
				_love(0.9)
			else:
				_state = State.IDLE
	# 待机 / 犯困
	if _state == State.IDLE:
		_idle += delta
		if _idle > 16.0:
			_state = State.SLEEP
	else:
		_idle = 0.0
	# 自主小动作(饿了讨食 / 跳舞 / 好奇歪头)
	_trick_cd -= delta
	if _auto and _state == State.IDLE and _bubble <= 0.0 and not _drag and _trick_cd <= 0.0:
		_trick_cd = randf_range(8.0, 16.0)
		_do_trick()
	# 智能提示
	_auto_t += delta
	if _auto and _state == State.IDLE and _auto_t > 30.0:
		_auto_t = 0.0
		if GameData.pet_hungry():
			say(HUNGRY_LINES[randi() % HUNGRY_LINES.size()], 3.2)
		elif _quest.is_empty() and GameData.has_wrong_entries() and randf() < 0.55:
			diagnose_me()
		elif _quest.is_empty() and randf() < 0.6:
			_offer_quest()
		else:
			say(TIPS[randi() % TIPS.size()], 3.0)
	# 光环 / 复习任务窗口
	_aura += delta
	_quest_t = maxf(_quest_t - delta, 0.0)
	if _quest_t <= 0.0 and not _quest.is_empty():
		_quest = {}
	# 气泡
	if _bubble > 0.0:
		_bubble = maxf(_bubble - delta, 0.0)
	# 星星 / 爱心 / 音符 / 光环
	var alive: Array = []
	for s in _sparks:
		s["life"] = float(s["life"]) - delta
		var kind := str(s.get("kind", "star"))
		match kind:
			"heart", "note":
				s["pos"] = (s["pos"] as Vector2) + (s["vel"] as Vector2) * delta
				s["vel"] = (s["vel"] as Vector2) + Vector2(0, -26.0) * delta
				(s["pos"] as Vector2).x += sin((s["pos"] as Vector2).y * 0.1) * 6.0 * delta
			"ring":
				s["radius"] = float(s.get("radius", 12.0)) + 90.0 * delta
			_:
				s["pos"] = (s["pos"] as Vector2) + (s["vel"] as Vector2) * delta
				s["vel"] = (s["vel"] as Vector2) + Vector2(0, 40.0) * delta
		if float(s["life"]) > 0.0:
			alive.append(s)
	_sparks = alive
	# 庆祝：连续冒星
	if _celebration > 0.0:
		_celebration = maxf(_celebration - delta, 0.0)
		_spark_cd -= delta
		if _spark_cd <= 0.0:
			_spark_cd = 0.26 if not _celebration_big else 0.16
			_spawn_sparks()
	_roam_update(delta)
	queue_redraw()

func _wake() -> void:
	if _state == State.SLEEP:
		_state = State.IDLE
	_idle = 0.0

# ---------------------------------------------------------------- 发言
func say(text: String, dur: float = 3.0, speak: bool = false) -> void:
	_bubble_text = text
	_bubble = dur
	_wake()
	if speak:
		UI.tts_say(text, true, true)

func _pop() -> void:
	if not _quest.is_empty():
		_goto_quest()
		return
	_happy(1.2)
	GameData.pet_touch()
	GameData.pet_mood = clampf(GameData.pet_mood + 0.03, 0.2, 1.0)
	var chance := 0.2 + affection_tier() * 0.15
	if randf() < chance:
		var pool := _clingy_pool()
		say(pool[randi() % pool.size()], 3.5, true)
	elif tap_provider.is_valid():
		say(str(tap_provider.call()), 3.5, true)
	else:
		var i := randi() % TIPS.size()
		if i == _last_tip:
			i = (i + 1) % TIPS.size()
		_last_tip = i
		say(TIPS[i], 3.0, true)
	Sound.play("select")

func _feed() -> void:
	if _state == State.EAT:
		return
	_state = State.EAT
	_state_t = 1.1
	_wake()
	GameData.add_pet_fed()
	_spawn_hearts(5)
	Sound.play("select")

# ---------------------------------------------------------------- 智能
## 勋章解锁反应(GameData 广播；登录回填延迟后自动忽略避免齐声庆祝)
func _on_medal(m: Dictionary) -> void:
	if not _medal_ready or not visible:
		return
	var nm := str(m.get("name", ""))
	_love(1.4)
	say(MEDAL_LINES[randi() % MEDAL_LINES.size()] % nm, 3.4, true)
	Sound.play("star")

## 知识进化反应：掌握新领域时炫彩庆祝 + 台词(登录回填不触发，因 GameData 静默解锁)
func _on_evolve(stage: int, domain: Dictionary) -> void:
	if not visible:
		return
	_celebration_dur = 2.3
	_celebration = 2.3
	_celebration_big = true
	_spark_cd = 0.0
	_love(2.3)
	_spawn_ring()
	var nm := str(domain.get("title", ""))
	var lore := GameData.lore_for(str(domain.get("id", "")))
	var line := "掌握「%s」啦！我进化成「%s」～" % [nm, GameData.pet_form_name()]
	if not lore.is_empty():
		line += "\n我想起一段碑文「%s」：%s" % [str(lore["title"]), str(lore["text"])]
	say(line, 7.0, true)
	Sound.play("star")

## 错题复习结清：萌宠替你高兴一下(任务由外部/自动提议)
func _on_wrong_cleared(_level_id: String, _qi: int) -> void:
	if not visible:
		return
	if not _quest.is_empty():
		_quest = {}
		_quest_t = 0.0
	_love(1.3)
	say("这道错题清掉啦！真棒～", 2.8, true)

## 提议一条复习任务(来自错题，越多越靠前)；已提议则不打断
func offer_quest(force: bool = false) -> bool:
	if not visible or GameData.pet_hungry():
		return false
	if not _quest.is_empty():
		return not _quest.is_empty()
	var qs := GameData.pet_quests()
	if qs.is_empty():
		return false
	if not force and randf() > 0.7:
		return false
	var q: Dictionary = qs[randi() % qs.size()]
	_quest = q
	_quest_t = 8.0
	var ch := str(q.get("chapter", ""))
	var lv := str(q.get("level_name", ""))
	say("「%s · %s」这题我以前算错过，点我去复习好不好～" % [ch, lv], 6.0)
	_curious(1.4)
	return true

func _offer_quest() -> void:
	offer_quest()

## 主动学情诊断：说出薄弱领域，并把「最该练的关卡」设为可点击任务。
func diagnose_me() -> bool:
	if not visible:
		return false
	var line := GameData.diagnosis_line()
	var rec := GameData.recommended_level()
	if not rec.is_empty():
		_quest = {
			"level_id": str(rec.get("level_id", "")), "qi": 0,
			"name": str(rec.get("level_name", "")),
			"level_name": str(rec.get("level_name", "")),
			"chapter": str((rec.get("domain", {}) as Dictionary).get("title", "")),
		}
		_quest_t = 9.0
		line += "\n（点我去练）"
	_curious(1.6)
	say(line, 7.0, true)
	return true

## 前往任务关卡(由点击萌宠触发)
func _goto_quest() -> void:
	var q := _quest
	_quest = {}
	_quest_t = 0.0
	var tgt := GameData.quest_target(q)
	if tgt.is_empty():
		return
	_dance(1.0)
	say("走！这次一定拿下～", 2.4)
	Sound.play("begin")
	GameData.start_level(int(tgt["ci"]), int(tgt["li"]))
	Scene.goto(str(tgt["scene"]))

## 升级反应：接在外部 celebrate 之后补一句台词与舞蹈
func on_level_up(level: int) -> void:
	if not visible:
		return
	_dance(1.4)
	say("升级啦！现在 Lv.%d，好厉害～" % level, 3.2)

## 出场问候：优先"好久不见"，其次"饿了"。返回是否已自行问候(供主城跳过普通问候)
func try_autogreet() -> bool:
	if not visible:
		return false
	if GameData.pet_away_days >= 1.0:
		_love(1.2)
		say("好久不见啦，我好想你～", 3.6)
		return true
	if GameData.pet_hungry():
		_state = State.ANGRY
		_state_t = 1.4
		say(HUNGRY_LINES[randi() % HUNGRY_LINES.size()], 3.4)
		return true
	return false

## 自主小动作：饿了讨食 / 生疏提醒 / 跳舞 / 好奇歪头
func _do_trick() -> void:
	if GameData.pet_hungry():
		say(HUNGRY_LINES[randi() % HUNGRY_LINES.size()], 3.0)
		return
	var stale := GameData.pet_stale_domains()
	if not stale.is_empty() and randf() < 0.45:
		_curious(1.8)
		say("「%s」有点生疏了，一起复习嘛～" % str(stale[0].get("title", "")), 3.6)
		return
	if randf() < 0.5:
		_dance(1.5)
	else:
		_curious(1.4)

func _love(dur: float) -> void:
	_state = State.LOVE
	_state_t = dur
	_wake()
	_spawn_hearts(6)

func _dance(dur: float) -> void:
	_state = State.DANCE
	_state_t = dur
	_wake()
	_spawn_notes(5)
	Sound.play("select")

func _curious(dur: float) -> void:
	_state = State.CURIOUS
	_state_t = dur
	_wake()

func _spawn_hearts(n: int) -> void:
	for i in n:
		_sparks.append({
			"kind": "heart",
			"pos": size * 0.5 + Vector2(randf_range(-22.0, 22.0), randf_range(-12.0, 6.0)),
			"vel": Vector2(randf_range(-20.0, 20.0), randf_range(-46.0, -20.0)),
			"life": randf_range(0.7, 1.1),
			"size": randf_range(5.0, 8.5),
		})

func _spawn_notes(n: int) -> void:
	for i in n:
		_sparks.append({
			"kind": "note",
			"pos": size * 0.5 + Vector2(randf_range(-24.0, 24.0), randf_range(-6.0, 10.0)),
			"vel": Vector2(randf_range(-24.0, 24.0), randf_range(-52.0, -24.0)),
			"life": randf_range(0.7, 1.1),
			"size": 1.0,
		})

func _spawn_ring() -> void:
	_sparks.append({
		"kind": "ring",
		"pos": size * 0.5,
		"vel": Vector2.ZERO,
		"radius": 12.0,
		"life": 0.6,
		"size": 1.0,
	})

## 每日问候语(按时段变化)
static func daily_greeting(nm: String) -> String:
	var h := int(Time.get_datetime_dict_from_system().hour)
	var when := "你好呀"
	if h >= 5 and h < 11:
		when = "早上好"
	elif h >= 11 and h < 14:
		when = "中午好"
	elif h >= 14 and h < 18:
		when = "下午好"
	elif h >= 18 and h < 23:
		when = "晚上好"
	else:
		when = "夜深了"
	var pool := [
		"%s，%s！今天也一起把定理点亮吧～" % [when, nm],
		"%s，%s！错题我都帮你记好啦～" % [when, nm],
		"%s，%s！先从薄弱点练起吧～" % [when, nm],
		"%s，%s！右键喂我一下？嘿嘿～" % [when, nm],
	]
	return pool[randi() % pool.size()]

## 答对鼓励：累积连击，里程碑时加大庆祝与专属台词。
func cheer() -> void:
	_combo += 1
	_grumble = 0
	_happy(1.2)
	GameData.pet_mood = clampf(GameData.pet_mood + 0.01, 0.2, 1.0)
	var milestone := _combo == 3 or _combo == 5 or _combo == 8 or (_combo >= 8 and _combo % 4 == 0)
	if milestone:
		celebrate(1.1)
	var line := ""
	match _combo:
		3: line = "三连击！手感正热～"
		5: line = "五连击！太顺了，稳住～"
		8: line = "八连击！！你太强了吧～"
		_:
			if _combo >= 8 and _combo % 4 == 0:
				line = "连击 x%d！势不可挡～" % _combo
	if line == "":
		line = CHEER[randi() % CHEER.size()]
	say(line, 2.6)

func comfort() -> void:
	_combo = 0
	_grumble += 1
	GameData.pet_mood = clampf(GameData.pet_mood - 0.02, 0.2, 1.0)
	if _grumble >= 3 and randf() < 0.6:
		_state = State.ANGRY
		_state_t = 1.6
		say("哼，认真点嘛！我陪你一起想～", 2.8)
	else:
		_state = State.SAD
		_state_t = 1.6
		say(COMFORT[randi() % COMFORT.size()], 2.8)

## 智能回答：先"思考一下"，再讲出要点(可配合 learn() 记住的知识点)
func respond(text: String) -> void:
	_state = State.THINK
	_state_t = 0.7
	say("让我想想…", 0.6)
	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(self):
		return
	_state = State.IDLE
	say(text, 6.5, true)

func _happy(dur: float) -> void:
	_state = State.HAPPY
	_state_t = dur
	_wake()
	_spawn_sparks()

## 通关庆祝：连续蹦跳 + 不断冒星星。intensity 越大跳得越久越多。
func celebrate(intensity: float = 1.0) -> void:
	_celebration_dur = 1.9 * intensity
	_celebration = _celebration_dur
	_celebration_big = intensity > 1.2
	_spark_cd = 0.0
	_happy(_celebration_dur)
	_spawn_ring()
	say("完美通关！太强啦！" if intensity > 1.2 else "通关啦！太厉害啦～", 3.2)
	Sound.play("star")

func _spawn_sparks() -> void:
	for i in 6:
		var a := randf_range(-PI * 0.9, -PI * 0.1)
		_sparks.append({
			"pos": size * 0.5 + Vector2(randf_range(-24.0, 24.0), randf_range(-30.0, -6.0)),
			"vel": Vector2(cos(a), sin(a)) * randf_range(20.0, 55.0),
			"life": randf_range(0.5, 0.9),
			"size": randf_range(3.0, 6.0),
		})

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	var c := size * 0.5
	var bob := sin(_t * 2.0) * 3.0
	var breath := 1.0 + 0.03 * sin(_t * 2.6)
	var hop := 0.0
	if _state == State.HAPPY:
		var p := clampf((1.2 - _state_t) / 1.2, 0.0, 1.0)
		hop = -sin(p * PI) * 16.0
	if _celebration > 0.0:
		var cp := 1.0 - _celebration / maxf(_celebration_dur, 0.01)
		hop = -absf(sin(cp * PI * 3.0)) * (30.0 if _celebration_big else 24.0)
	if _state == State.SLEEP:
		bob = sin(_t * 1.2) * 2.0
	if _state == State.DANCE:
		hop = -absf(sin(_t * 8.0)) * 9.0
	var R := 36.0 * breath
	var step := sin(_walk_phase) * (4.0 if _moving else 0.0)
	var walk := absf(sin(_walk_phase)) * 2.5 if _moving else 0.0
	var lean := _face * (2.0 if _moving else 0.0)
	var center := c + Vector2(lean, bob + hop - walk)

	# 影子
	draw_circle(Vector2(c.x, size.y - 6.0), 24.0, Color(0, 0, 0, 0.20))
	# 好感光环(高好感/庆祝/示好时脉动)
	if affection_tier() > 0 or _celebration > 0.0 or _state == State.LOVE:
		draw_circle(center, R + 15.0, Color(COL_BODY_HI, 0.10 + 0.07 * sin(_aura * 2.4)))
	# 挤压缩放(跳起拉长、落地压扁)：以 center 为轴缩放身体部件
	var sy := clampf(1.0 - hop / 260.0, 0.88, 1.20)
	var sx := 1.0 / sy
	draw_set_transform(Vector2((1.0 - sx) * center.x, (1.0 - sy) * center.y), 0.0, Vector2(sx, sy))
	# 小尾巴(走路时摆动)
	draw_circle(center + Vector2(R * 0.9, R * 0.35 + step * 0.5), 6.0, COL_BODY_DK)
	# 小脚(交替迈步)
	draw_circle(center + Vector2(-R * 0.42, R * 0.92 + step), 7.0, COL_BODY_DK)
	draw_circle(center + Vector2(R * 0.42, R * 0.92 - step), 7.0, COL_BODY_DK)
	# 触角
	draw_line(center + Vector2(0, -R + 4), center + Vector2(0, -R - 16), COL_ANT, 2.6)
	draw_circle(center + Vector2(0, -R - 20), 9.0, Color(COL_ANT, 0.18))
	draw_circle(center + Vector2(0, -R - 20), 5.0, COL_ANT)
	draw_circle(center + Vector2(-1.6, -R - 21.6), 1.6, Color(1, 1, 1, 0.9))
	# 知识部件(背景层：向量之翼 / 数列之尾)
	_draw_parts_back(center, R)
	# 身体(两层：深色描边 + 主体 + 高光)
	draw_circle(center, R, COL_BODY_DK)
	draw_circle(center, R - 2.0, COL_BODY)
	draw_circle(center + Vector2(-R * 0.32, -R * 0.34), R * 0.52, Color(COL_BODY_HI, 0.55))
	# 肚皮
	draw_circle(center + Vector2(0, R * 0.34), R * 0.60, Color(COL_BELLY, 0.55))
	# 小手
	var arm_y := R * 0.05
	var arm_dx := R * 0.86
	if _state == State.HAPPY:
		draw_line(center + Vector2(-R * 0.7, arm_y), center + Vector2(-arm_dx, -R * 0.35), COL_BODY_DK, 5.0)
		draw_line(center + Vector2(R * 0.7, arm_y), center + Vector2(arm_dx, -R * 0.35), COL_BODY_DK, 5.0)
		draw_circle(center + Vector2(-arm_dx, -R * 0.35), 4.5, COL_BODY_DK)
		draw_circle(center + Vector2(arm_dx, -R * 0.35), 4.5, COL_BODY_DK)
	else:
		draw_line(center + Vector2(-R * 0.7, arm_y), center + Vector2(-arm_dx, arm_y + R * 0.2), COL_BODY_DK, 5.0)
		draw_line(center + Vector2(R * 0.7, arm_y), center + Vector2(arm_dx, arm_y + R * 0.2), COL_BODY_DK, 5.0)
		draw_circle(center + Vector2(-arm_dx, arm_y + R * 0.2), 4.5, COL_BODY_DK)
		draw_circle(center + Vector2(arm_dx, arm_y + R * 0.2), 4.5, COL_BODY_DK)
	# 腮红
	draw_circle(center + Vector2(-R * 0.58, R * 0.22), 5.5, Color(COL_CHEEK, 0.65))
	draw_circle(center + Vector2(R * 0.58, R * 0.22), 5.5, Color(COL_CHEEK, 0.65))
	# 眼睛 / 嘴
	_draw_face(center, R)
	# 知识部件(前景层：曲线光环 / 向量角 / 形体护甲 / 直线镜 / 代数核心)
	_draw_parts_front(center, R)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 喂食：饼干落下
	if _state == State.EAT:
		var prog := clampf((1.1 - _state_t) / 1.1, 0.0, 1.0)
		var cp := center + Vector2(0, -R - 8.0 + prog * (R * 0.5))
		draw_circle(cp, 7.0, Color("#a9713a"))
		draw_circle(cp, 5.6, Color("#d19a5f"))
		draw_circle(cp + Vector2(-2.0, -1.5), 1.5, Color("#5a3417"))
		draw_circle(cp + Vector2(2.0, 1.0), 1.5, Color("#5a3417"))
		draw_circle(cp + Vector2(0.5, -2.8), 1.2, Color("#5a3417"))
	# 星星 / 爱心 / 音符 / 光环
	for s in _sparks:
		var kind := str(s.get("kind", "star"))
		var a := clampf(float(s["life"]) / 0.9, 0.0, 1.0)
		match kind:
			"heart": _draw_heart(s["pos"], float(s["size"]), a)
			"note": _draw_note(s["pos"], a)
			"ring": draw_arc(s["pos"], float(s.get("radius", 12.0)), 0.0, TAU, 32, Color(UI.COL_ACCENT, a * 0.8), 2.0, true)
			_: _draw_spark(s["pos"], float(s["size"]), a)
	# 状态标记：饿(感叹号) / 好奇(问号) / 生气(怒筋)
	if GameData.pet_hungry() and _state != State.EAT and _bubble <= 0.0 and (_state == State.IDLE or _state == State.SLEEP):
		var hp := center + Vector2(R * 0.55, -R - 28.0)
		draw_circle(hp, 9.0, Color("#ffd479"))
		draw_string(UI.font(), hp + Vector2(-6.0, 5.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#5a3a00"))
	if _state == State.CURIOUS and _bubble <= 0.0:
		var qp := center + Vector2(R * 0.30, -R - 30.0)
		draw_string(UI.font(), qp + Vector2(-10.0, 0.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(UI.COL_ACCENT, 0.9))
	if _state == State.ANGRY:
		var ap := center + Vector2(R + 2.0, -R - 6.0)
		draw_line(ap + Vector2(-5, -5), ap + Vector2(5, 5), Color("#ff6b6b"), 2.4)
		draw_line(ap + Vector2(5, -5), ap + Vector2(-5, 5), Color("#ff6b6b"), 2.4)
	# 复习任务提示徽章(点击萌宠前往)
	if not _quest.is_empty():
		var qp := center + Vector2(-R * 0.55, -R - 30.0)
		var qpulse := 0.5 + 0.5 * sin(_aura * 3.0)
		draw_circle(qp, 12.0 + qpulse * 2.5, Color("#5ee6ff", 0.16))
		draw_circle(qp, 11.0, Color("#0b2a33"))
		draw_arc(qp, 11.0, 0.0, TAU, 28, Color(UI.COL_ACCENT, 0.9), 2.0, true)
		draw_string(UI.font(), qp + Vector2(-4.0, 6.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UI.COL_ACCENT)
	# 睡觉 Z + 做梦小云朵
	if _state == State.SLEEP:
		var f := UI.font()
		for i in 3:
			var zz := "z"
			var ph := fposmod(_t * 0.5 + i * 0.33, 1.0)
			var pos := center + Vector2(R + 16.0 + i * 10.0, -R - 6.0 - ph * 22.0)
			draw_string(f, pos, zz, HORIZONTAL_ALIGNMENT_LEFT, -1, 14 + i * 4, Color(1, 1, 1, 0.7 * (1.0 - ph)))
		var dp := center + Vector2(-R * 0.3, -R - 88.0 + 6.0 * sin(_t * 3.0))
		draw_circle(dp, 13.0, Color(1, 1, 1, 0.08))
		draw_arc(dp, 13.0, 0.0, TAU, 24, Color(1, 1, 1, 0.30), 1.2, true)
		_draw_spark(dp, 6.0, 0.9)
	# 气泡(按萌宠在屏幕中的位置自动上/下翻转：位于下半屏时气泡在上方，
	# 避免遮挡底部的交互信息栏；位于上半屏时改为在下方，避免超出屏幕顶部)
	if _bubble > 0.0 and _bubble_text != "":
		var bpos := center + Vector2(0, -R - 32)
		var above := (global_position.y + bpos.y) > get_viewport_rect().size.y * 0.5
		_draw_bubble(bpos, above)

func _draw_face(center: Vector2, R: float) -> void:
	var ex := R * 0.40
	var ey := -R * 0.12
	match _state:
		State.EAT:
			draw_arc(center + Vector2(-ex, ey), 7.5, PI + 0.5, TAU - 0.5, 16, COL_EYE, 3.0, true)
			draw_arc(center + Vector2(ex, ey), 7.5, PI + 0.5, TAU - 0.5, 16, COL_EYE, 3.0, true)
			_draw_mouth(center, R, 2.0)
		State.SLEEP:
			draw_arc(center + Vector2(-ex, ey), 7.0, PI, TAU, 16, COL_EYE, 2.6, true)
			draw_arc(center + Vector2(ex, ey), 7.0, PI, TAU, 16, COL_EYE, 2.6, true)
			_draw_mouth(center, R, 0.0)
		State.HAPPY, State.DANCE:
			draw_arc(center + Vector2(-ex, ey), 7.5, PI + 0.5, TAU - 0.5, 16, COL_EYE, 3.0, true)
			draw_arc(center + Vector2(ex, ey), 7.5, PI + 0.5, TAU - 0.5, 16, COL_EYE, 3.0, true)
			_draw_mouth(center, R, 2.0)
		State.LOVE:
			_draw_eye_heart(center + Vector2(-ex, ey), 9.0)
			_draw_eye_heart(center + Vector2(ex, ey), 9.0)
			_draw_mouth(center, R, 2.0)
		State.ANGRY:
			_draw_eye(center, ex, ey, 8.0, Vector2.ZERO)
			draw_line(center + Vector2(-ex - 6.0, ey - 12.0), center + Vector2(-ex + 5.0, ey - 7.0), COL_EYE, 2.6)
			draw_line(center + Vector2(ex + 6.0, ey - 12.0), center + Vector2(ex - 5.0, ey - 7.0), COL_EYE, 2.6)
			_draw_mouth(center, R, -1.0)
		State.CURIOUS:
			_draw_eye(center, ex, ey, 10.0, Vector2(0.0, -2.0))
			draw_line(center + Vector2(-ex - 5.0, ey - 12.0), center + Vector2(-ex + 3.0, ey - 15.0), COL_EYE, 2.2)
			draw_line(center + Vector2(ex - 3.0, ey - 15.0), center + Vector2(ex + 5.0, ey - 12.0), COL_EYE, 2.2)
			_draw_mouth(center, R, 0.0)
		_:
			var look := (get_local_mouse_position() - center)
			if _state == State.THINK:
				look = Vector2(-12.0, -10.0)
			look = Vector2(clampf(look.x, -10.0, 10.0), clampf(look.y, -8.0, 8.0)) * 0.10
			_draw_eye(center, ex, ey, 9.0 if _hover else 8.0, look)
			# 眉毛(低落时下垂)
			if _state == State.SAD:
				draw_line(center + Vector2(-ex - 5.0, ey - 11.0), center + Vector2(-ex + 4.0, ey - 8.0), COL_EYE, 2.0)
				draw_line(center + Vector2(ex + 5.0, ey - 11.0), center + Vector2(ex - 4.0, ey - 8.0), COL_EYE, 2.0)
			_draw_mouth(center, R, -1.0 if _state == State.SAD else 0.0)

func _draw_eye(center: Vector2, ex: float, ey: float, eye_r: float, look: Vector2) -> void:
	for sx in [-1.0, 1.0]:
		var ec := center + Vector2(sx * ex, ey)
		draw_circle(ec, eye_r, Color(1, 1, 1, 0.96))
		draw_arc(ec, eye_r, 0.0, TAU, 20, Color(COL_BODY_DK, 0.5), 1.0, true)
		draw_circle(ec + look, eye_r * 0.62, COL_IRIS)
		draw_circle(ec + look + Vector2(0, eye_r * 0.22), eye_r * 0.30, COL_IRIS2)
		draw_circle(ec + look, eye_r * 0.34, COL_EYE)
		draw_circle(ec + look + Vector2(-eye_r * 0.28, -eye_r * 0.30), eye_r * 0.22, Color(1, 1, 1, 0.95))

func _draw_eye_heart(pos: Vector2, sz: float) -> void:
	var col := COL_HEART
	draw_circle(pos + Vector2(-sz * 0.4, -sz * 0.28), sz * 0.5, col)
	draw_circle(pos + Vector2(sz * 0.4, -sz * 0.28), sz * 0.5, col)
	draw_colored_polygon(PackedVector2Array([
		Vector2(pos.x - sz * 0.9, pos.y - sz * 0.25),
		Vector2(pos.x + sz * 0.9, pos.y - sz * 0.25),
		Vector2(pos.x, pos.y + sz * 0.95),
	]), col)

func _draw_mouth(center: Vector2, R: float, mood: float) -> void:
	var my := center + Vector2(0, R * 0.26)
	if mood > 1.0:
		draw_circle(my + Vector2(0, 2.0), 6.0, Color("#c0324a"))
		draw_circle(my + Vector2(0, 4.0), 3.5, Color("#ffb3c1"))
	elif mood < -0.5:
		draw_arc(my - Vector2(0, 3.0), 7.0, PI + 0.3, TAU - 0.3, 16, COL_EYE, 2.2, true)
	else:
		draw_arc(my, 7.5, 0.30, PI - 0.30, 16, COL_EYE, 2.2, true)

func _draw_spark(pos: Vector2, sz: float, a: float) -> void:
	var col := Color(COL_SPARK, a)
	draw_line(pos + Vector2(-sz, 0), pos + Vector2(sz, 0), col, 1.8)
	draw_line(pos + Vector2(0, -sz), pos + Vector2(0, sz), col, 1.8)
	draw_line(pos + Vector2(-sz * 0.6, -sz * 0.6), pos + Vector2(sz * 0.6, sz * 0.6), col, 1.2)
	draw_line(pos + Vector2(-sz * 0.6, sz * 0.6), pos + Vector2(sz * 0.6, -sz * 0.6), col, 1.2)

func _draw_heart(pos: Vector2, sz: float, a: float) -> void:
	var col := Color(COL_HEART, a)
	draw_circle(pos + Vector2(-sz * 0.4, -sz * 0.28), sz * 0.5, col)
	draw_circle(pos + Vector2(sz * 0.4, -sz * 0.28), sz * 0.5, col)
	draw_colored_polygon(PackedVector2Array([
		Vector2(pos.x - sz * 0.9, pos.y - sz * 0.25),
		Vector2(pos.x + sz * 0.9, pos.y - sz * 0.25),
		Vector2(pos.x, pos.y + sz * 0.95),
	]), col)

func _draw_note(pos: Vector2, a: float) -> void:
	var col := Color(COL_NOTE, a)
	draw_line(pos, pos + Vector2(0, -11.0), col, 2.0)
	draw_line(pos + Vector2(0, -11.0), pos + Vector2(5.0, -9.0), col, 2.0)
	draw_circle(pos + Vector2(-2.0, 0), 3.4, col)

# ---------------------------------------------------------------- 知识部件(纯代码，随掌握度解锁)
## 背景层：空间之翼 / 数列之尾
func _draw_parts_back(center: Vector2, R: float) -> void:
	if GameData.pet_part_unlocked("space"):
		_draw_wings(center, R)
	if GameData.pet_part_unlocked("seq"):
		_draw_seq_tail(center, R)

## 前景层：曲线光环 / 向量角 / 形体护甲 / 直线镜 / 代数核心
func _draw_parts_front(center: Vector2, R: float) -> void:
	if GameData.pet_part_unlocked("conic"):
		_draw_halo(center, R)
	if GameData.pet_part_unlocked("vector"):
		_draw_horns(center, R)
	if GameData.pet_part_unlocked("solid"):
		_draw_armor(center, R)
	if GameData.pet_part_unlocked("line"):
		_draw_lens(center, R)
	if GameData.pet_part_unlocked("algebra"):
		_draw_core(center, R)

## 空间之翼：随呼吸轻扇的半透明羽翼
func _draw_wings(center: Vector2, R: float) -> void:
	var flap := sin(_t * 2.2) * 0.12
	for s in [-1.0, 1.0]:
		var shoulder := center + Vector2(s * R * 0.7, -R * 0.08)
		for i in 3:
			var b := 0.38 + 0.30 * float(i) + flap
			var dir := Vector2(s * sin(b), -cos(b))
			var ln := R * (1.55 - 0.16 * float(i))
			var tip := shoulder + dir * ln
			var perp := dir.rotated(PI * 0.5) * (R * 0.17)
			var col := Color("#8ef0d8", 0.52 - 0.09 * float(i))
			draw_colored_polygon(PackedVector2Array([
				shoulder + perp * 0.3, tip + perp, tip - perp, shoulder - perp * 0.3]), col)

## 数列之尾：粉色卷曲尾 + 尾尖宝珠
func _draw_seq_tail(center: Vector2, R: float) -> void:
	var base := center + Vector2(R * 0.85, R * 0.30)
	draw_arc(base, R * 0.55, -PI * 0.75, PI * 0.55, 22, Color("#ff99c3", 0.9), 4.0, true)
	draw_circle(base + Vector2(R * 0.5, R * 0.38), 4.5, Color("#ffd1e6"))
	draw_circle(base + Vector2(R * 0.5, R * 0.38), 2.0, Color.WHITE)

## 曲线光环：头顶缓转的圆环 + 环绕光点
func _draw_halo(center: Vector2, R: float) -> void:
	var col := Color("#5ad8a6")
	var hp := center + Vector2(0, -R - 40.0 + sin(_t * 1.6) * 2.0)
	draw_arc(hp, 15.0, 0.0, TAU, 40, Color(col, 0.85), 3.0, true)
	draw_arc(hp, 15.0, -PI * 0.5 + _t * 1.4, -PI * 0.5 + _t * 1.4 + PI, 24, Color(1, 1, 1, 0.85), 2.0, true)
	for i in 2:
		var a := _t * 1.8 + PI * float(i)
		draw_circle(hp + Vector2(cos(a), sin(a)) * 15.0, 2.4, Color.WHITE)

## 方向之角：头顶一对小尖角
func _draw_horns(center: Vector2, R: float) -> void:
	var col := Color("#c9b3ff")
	for s in [-1.0, 1.0]:
		var base := center + Vector2(s * R * 0.42, -R * 0.70)
		var tip := base + Vector2(s * R * 0.30, -R * 0.58)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-s * 6.0, -1.0), base + Vector2(s * 6.0, 3.0), tip]), col)
		draw_circle(tip, 2.4, Color(1, 1, 1, 0.95))

## 形体护甲：腹部六边护心镜
func _draw_armor(center: Vector2, R: float) -> void:
	var col := Color("#45c7e5")
	var pc := center + Vector2(0, R * 0.40)
	var pts := PackedVector2Array()
	for i in 6:
		var a := -PI * 0.5 + TAU * float(i) / 6.0
		pts.append(pc + Vector2(cos(a), sin(a)) * (R * 0.34))
	draw_colored_polygon(pts, Color(col, 0.30))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color(col, 0.9), 2.0, true)

## 轨迹之镜：双眼外的科技细环
func _draw_lens(center: Vector2, R: float) -> void:
	var col := Color("#a878ff")
	for s in [-1.0, 1.0]:
		var ec := center + Vector2(s * R * 0.40, -R * 0.12)
		draw_arc(ec, 12.5, 0.0, TAU, 28, Color(col, 0.55), 1.6, true)

## 代数核心：胸口脉动宝珠
func _draw_core(center: Vector2, R: float) -> void:
	var col := Color("#5ee6ff")
	var gp := center + Vector2(0, R * 0.02)
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	draw_circle(gp, 7.0 + pulse * 2.0, Color(col, 0.22))
	draw_circle(gp, 4.6, Color(col, 0.95))
	draw_circle(gp, 2.0, Color.WHITE)

func _draw_bubble(pos: Vector2, above: bool = true) -> void:
	var f := UI.font()
	var fsz := UI.fs(14)
	var lh := float(fsz) + 5.0
	var maxw := minf(210.0 * float(fsz) / 14.0, 300.0)
	var lines := _wrap(f, fsz, maxw, _bubble_text)
	var w := 0.0
	for ln in lines:
		w = maxf(w, f.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x)
	var bh := 12.0 + lines.size() * lh
	# above=true: 气泡在锚点上方；above=false: 气泡在锚点下方
	var rect := Rect2(pos - Vector2(w * 0.5 + 10.0, bh if above else 0.0), Vector2(w + 20.0, bh))
	# 以全局坐标夹取：rect 用的是本地坐标，直接用视口尺寸夹会因萌宠位置而漂移出屏
	var vp := get_viewport_rect()
	var gp := global_position + rect.position
	gp.x = clampf(gp.x, 6.0, maxf(vp.size.x - rect.size.x - 6.0, 6.0))
	gp.y = clampf(gp.y, 6.0, maxf(vp.size.y - rect.size.y - 6.0, 6.0))
	rect.position = gp - global_position
	draw_rect(rect, Color(0.05, 0.07, 0.12, 0.94), true)
	draw_rect(rect, Color(UI.COL_ACCENT, 0.55), false, 1.5)
	var tx := clampf(pos.x, rect.position.x + 10.0, rect.end.x - 10.0)
	if above:
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - 7.0, rect.end.y - 1.0),
			Vector2(tx + 7.0, rect.end.y - 1.0),
			Vector2(tx, rect.end.y + 9.0)]), Color(0.05, 0.07, 0.12, 0.94))
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - 7.0, rect.position.y + 1.0),
			Vector2(tx + 7.0, rect.position.y + 1.0),
			Vector2(tx, rect.position.y - 9.0)]), Color(0.05, 0.07, 0.12, 0.94))
	var y := rect.position.y + 5.0
	for ln in lines:
		draw_string(f, Vector2(rect.position.x + 10.0, y + fsz), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, UI.COL_TEXT)
		y += lh

func _wrap(f: Font, size_px: int, maxw: float, text: String) -> Array:
	var out: Array = []
	for seg in text.split("\n"):
		var line := ""
		for i in seg.length():
			var ch := seg.substr(i, 1)
			var test := line + ch
			if line != "" and f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x > maxw:
				out.append(line)
				line = ch
			else:
				line = test
		out.append(line)
	return out

# ---------------------------------------------------------------- 交互
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_feed()
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag = true
			_moved = 0.0
			_wake()
			accept_event()
		else:
			if _drag and _moved < 6.0:
				_pop()
			_drag = false
			accept_event()
	elif event is InputEventMouseMotion and _drag:
		position += event.relative
		_moved += event.relative.length()
		var par := get_parent()
		if par is Control:
			var ps: Vector2 = (par as Control).size
			position.x = clampf(position.x, 0.0, maxf(ps.x - size.x, 0.0))
			position.y = clampf(position.y, 0.0, maxf(ps.y - size.y, 0.0))
		accept_event()
