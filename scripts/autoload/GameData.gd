extends Node
## 全局数据：课程表、进度、存档

signal progress_changed
## 达成新勋章时发出(供 UI 反应；Toast/音效通知已在 GameData 内统一处理)
signal medal_unlocked(medal: Dictionary)
## 萌宠掌握新知识领域、形态进化时发出(stage=进化后形态等级，domain=新掌握领域定义)
signal pet_evolved(stage: int, domain: Dictionary)
## 某道错题被答对、彻底结清时发出(复习清债；coin 为奖励金币)
signal wrong_cleared(level_id: String, qi: int)

const CURRICULUM_PATH := "res://data/curriculum.json"
const QUESTIONS_PATH := "res://data/questions.json"
const SAVE_PATH := "user://save.json"
const USERS_PATH := "user://users.json"
const USERS_TMP := "user://users.tmp"   # 原子写入的临时文件
const USERS_BAK := "user://users.bak"   # 上一个良好存档的备份

## 可选头像
const AVATARS := [
	{ "id": "player", "icon": "player", "color": "#5ee6ff" },
	{ "id": "boss", "icon": "boss_generic", "color": "#fb7185" },
	{ "id": "book", "icon": "icon_book", "color": "#ffa64d" },
	{ "id": "map", "icon": "icon_map", "color": "#45C7E5" },
	{ "id": "tree", "icon": "icon_tree", "color": "#a878ff" },
	{ "id": "train", "icon": "icon_train", "color": "#4dd6a8" },
]

## 称号阶梯：按「满星比例」达成，课程扩充时自动适配，无需改数值。
const RANKS := [
	{ "title": "窥数者",     "ratio": 0.00 },
	{ "title": "演算者",     "ratio": 0.06 },
	{ "title": "衍算师",     "ratio": 0.15 },
	{ "title": "定理执笔人", "ratio": 0.30 },
	{ "title": "公理谛听者", "ratio": 0.50 },
	{ "title": "衍数尊者",   "ratio": 0.70 },
	{ "title": "衍数阁主",   "ratio": 0.88 },
]

## 勋章/成就定义。symbol 为徽章中央字符；达成条件见 _medal_met()。
const MEDALS := [
	{ "id": "first_clear",   "name": "初露锋芒", "desc": "首次通关任意关卡",             "symbol": "初", "color": "#5ee6ff" },
	{ "id": "clear_10",      "name": "小有心得", "desc": "通关 10 个关卡",               "symbol": "十", "color": "#5ee6ff" },
	{ "id": "clear_30",      "name": "登堂入室", "desc": "通关 30 个关卡",               "symbol": "堂", "color": "#a878ff" },
	{ "id": "clear_60",      "name": "融会贯通", "desc": "通关 60 个关卡",               "symbol": "贯", "color": "#a878ff" },
	{ "id": "perfect_1",     "name": "一丝不苟", "desc": "首次满星通关",                 "symbol": "满", "color": "#ffd479" },
	{ "id": "perfect_10",    "name": "完美主义", "desc": "满星关卡达到 10 个",           "symbol": "完", "color": "#ffd479" },
	{ "id": "perfect_30",    "name": "精益求精", "desc": "满星关卡达到 30 个",           "symbol": "精", "color": "#f6bd16" },
	{ "id": "chapter_master","name": "章节通解", "desc": "任意章节集满全部星星",         "symbol": "章", "color": "#45C7E5" },
	{ "id": "stars_50",      "name": "星辉初绽", "desc": "累计获得 50 颗星",             "symbol": "星", "color": "#5ee6ff" },
	{ "id": "stars_150",     "name": "星河璀璨", "desc": "累计获得 150 颗星",            "symbol": "河", "color": "#a878ff" },
	{ "id": "stars_300",     "name": "满天星斗", "desc": "累计获得 300 颗星",            "symbol": "斗", "color": "#ffd479" },
	{ "id": "answer_100",    "name": "勤学不辍", "desc": "累计作答 100 题",              "symbol": "勤", "color": "#34d399" },
	{ "id": "answer_500",    "name": "博览群题", "desc": "累计作答 500 题",              "symbol": "博", "color": "#34d399" },
	{ "id": "accuracy_80",   "name": "精准推演", "desc": "作答满 50 题且正确率 ≥ 80%",    "symbol": "准", "color": "#34d399" },
	{ "id": "coins_1000",    "name": "富甲一方", "desc": "金币累计达到 1000",            "symbol": "金", "color": "#ffd479" },
	{ "id": "boss_first",    "name": "破阵者",   "desc": "通关任意隐藏 Boss",            "symbol": "破", "color": "#fb7185" },
	{ "id": "boss_all",      "name": "无冕之王", "desc": "通关全部隐藏 Boss",            "symbol": "王", "color": "#fb7185" },
	{ "id": "pet_3",         "name": "亲密伙伴", "desc": "投喂萌宠 3 次",                "symbol": "友", "color": "#4dd6a8" },
	{ "id": "pet_10",         "name": "形影不离", "desc": "投喂萌宠 10 次",               "symbol": "伴", "color": "#4dd6a8" },
]

## 知识领域：把课程章节归入 7 个领域，用于「掌握度」聚合与萌宠知识进化。
## chapters 为该领域涵盖的章节 id；掌握度由领域内关卡的星级 / 清关质量 / 错题聚合而来。
const DOMAINS := [
	{ "id": "seq",     "title": "数列·律动",     "color": "#ff99c3",
		"chapters": ["recurrence_methods", "sequences"] },
	{ "id": "solid",   "title": "立体几何·形体", "color": "#45c7e5",
		"chapters": ["solid"] },
	{ "id": "conic",   "title": "圆锥曲线·曲线", "color": "#5ad8a6",
		"chapters": ["conic", "conics", "ellipse"] },
	{ "id": "line",    "title": "直线方程·轨迹", "color": "#a878ff",
		"chapters": ["line_eq"] },
	{ "id": "space",   "title": "空间向量·维度", "color": "#45c7e5",
		"chapters": ["space"] },
	{ "id": "vector",  "title": "平面向量·方向", "color": "#9270ca",
		"chapters": ["vector", "vectors"] },
	{ "id": "algebra", "title": "代数综合·根基", "color": "#5ee6ff",
		"chapters": ["set_logic", "inequalities", "functions", "trig", "probability",
			"derivative", "complex", "counting", "thinking"] },
]

## 领域掌握度达标即解锁对应萌宠部件(只增不减)
const MASTERY_UNLOCK := 0.5
## 已解锁领域掌握度低于此值视为「生疏」(仅影响萌宠表现，不回收形态)
const MASTERY_STALE := 0.35
## 萌宠形态名(下标 = 已解锁部件数)
const PET_FORMS := ["初芽", "萌芽", "启智", "明理", "通达", "博识", "睿智", "衍数·完形"]

## 馆灵记忆碑文：每掌握一个领域，寻回一段失落的档案(与 DOMAINS 的 id 对应)。
const LORE := [
	{ "id": "seq",     "title": "碑文·归序", "text": "万物流转皆有其序，离散之间，自见通项。" },
	{ "id": "solid",   "title": "碑文·筑形", "text": "平面不足立物，便向上升起一维，形体自会闭合。" },
	{ "id": "conic",   "title": "碑文·弧光", "text": "一束光斜切圆锥，弧线便得有了名字。" },
	{ "id": "line",    "title": "碑文·直轨", "text": "两点定其向，一点与斜率定其形。" },
	{ "id": "space",   "title": "碑文·维度", "text": "给每个方向一个坐标，空间便不再幽深难测。" },
	{ "id": "vector",  "title": "碑文·方向", "text": "有向的线段，藏着长度与夹角两种真相。" },
	{ "id": "algebra", "title": "碑文·根基", "text": "一切推演，皆从数与式的根基生长。" },
]

var chapters: Array = []
var stars: Dictionary = {}      # level_id -> int(0..3)
var player_exp: int = 0
var coins: int = 0
var medals: Dictionary = {}     # medal_id -> 解锁时间戳
var pet_parts: Dictionary = {}  # domain_id -> 解锁时间戳(知识进化部件，只增不减)
var pet_stage: int = 0          # 已解锁部件数(萌宠形态等级)
var _level_mastery: Dictionary = {}   # 缓存：level_id -> 0..1
var _domain_mastery: Dictionary = {}  # 缓存：domain_id -> 0..1

# ---- 用户系统(多用户) ----
var users: Dictionary = {}              # 用户名 -> 存档 dict
var current_user: String = ""           # 当前登录用户名("" 表示未登录)
var avatar: String = "player"
var total_questions: int = 0            # 累计作答数
var total_correct: int = 0              # 累计答对数
var wrong_log: Dictionary = {}          # "level_id#qi" -> {level_id, qi, name, module, count, last_chose, correct}
var level_records: Dictionary = {}      # level_id -> {attempts, best_stars, last_clean, last_total, trap_missed}
var pet_fed: int = 0                    # 萌宠投喂次数
var pet_satiety: float = 1.0            # 饱食度 0..1(随时间下降，投喂回满)
var pet_mood: float = 0.8               # 心情 0..1(答对/投喂上升，答错/久未互动下降)
var pet_last_seen: int = 0              # 上次互动时间戳(秒)；用于跨会话衰减
var pet_away_days: float = 0.0          # 本次登录距上次互动天数(不存档，供萌宠问候)
var regions_seen: int = 0               # 已见过的解锁区域数(用于"解锁新区域"庆祝)
var pet_greeted_session: bool = false   # 本次运行是否已让萌宠撒娇(不存档)
var chapter_order: Array = []           # 知识体系首页章节卡片的自定义顺序(章节 id 列表)

# 当前进入的关卡(供战斗场景读取)
var current_chapter_index: int = -1
var current_level_index: int = -1
var current_level: Dictionary = {}
var last_chapter_id: String = ""   # 上次学习的章节 id(跨启动记住「正在学习」，即使重开也应置顶)

var _questions: Dictionary = {}   # level_id -> Array[Dictionary]

func _ready() -> void:
	_load_curriculum()
	_load_questions()
	_load_users()

# ---------------------------------------------------------------- 课程
func _load_curriculum() -> void:
	if not FileAccess.file_exists(CURRICULUM_PATH):
		push_error("找不到 curriculum.json")
		return
	var f := FileAccess.open(CURRICULUM_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or not data.has("chapters"):
		push_error("curriculum.json 格式错误")
		return
	chapters = data["chapters"]
	for ch in chapters:
		for lv in ch.get("levels", []):
			if not stars.has(lv["id"]):
				stars[lv["id"]] = 0

# ---------------------------------------------------------------- 题库
func _load_questions() -> void:
	if not FileAccess.file_exists(QUESTIONS_PATH):
		return
	var f := FileAccess.open(QUESTIONS_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		_questions = data

func questions_for(level_id: String) -> Array:
	return _questions.get(level_id, [])

func level_name(level_id: String) -> String:
	for ch in chapters:
		for lv in ch.get("levels", []):
			if lv["id"] == level_id:
				return lv["name"]
	return ""

# 进入关卡：记录上下文，返回是否成功
func start_level(chapter_index: int, level_index: int) -> bool:
	if chapter_index < 0 or chapter_index >= chapters.size():
		return false
	var levels: Array = chapters[chapter_index]["levels"]
	if level_index < 0 or level_index >= levels.size():
		return false
	current_chapter_index = chapter_index
	current_level_index = level_index
	current_level = levels[level_index]
	last_chapter_id = str(chapters[chapter_index].get("id", ""))
	_save()
	return true

## 上次学习的章节在 chapters 中的下标（本会话优先用运行时下标，重开时回退到存档里的 id）
func last_chapter_index() -> int:
	if current_chapter_index >= 0 and current_chapter_index < chapters.size():
		return current_chapter_index
	if last_chapter_id != "":
		for i in chapters.size():
			if str(chapters[i].get("id", "")) == last_chapter_id:
				return i
	return -1

func current_level_id() -> String:
	return current_level.get("id", "")

# ---------------------------------------------------------------- 关卡导航
## 按课程顺序展开当前「体系」(方法推演/知识体系)内的全部关卡,用于「上一关 / 下一关」,
## 避免两个体系互相串关。
func _flat_levels() -> Array:
	var kind := chapter_kind(current_chapter_index)
	var out: Array = []
	for ci in chapters.size():
		if kind != "" and chapter_kind(ci) != kind:
			continue
		var levels: Array = chapters[ci].get("levels", [])
		for li in levels.size():
			out.append({ "ci": ci, "li": li, "level": levels[li] })
	return out

func _flat_index() -> int:
	var flat := _flat_levels()
	for i in flat.size():
		var e: Dictionary = flat[i]
		if int(e["ci"]) == current_chapter_index and int(e["li"]) == current_level_index:
			return i
	return -1

## 关卡是否可进入:有独立场景走 scene,否则统一进入通用战斗场景 Battle(题面未录入时显示占位)。
## 因此课程表内的所有关卡都可导航,「上一关/下一关」不会因某章没有 scene 而被误判为不可用。
func has_prev_level() -> bool:
	return _flat_index() > 0

func has_next_level() -> bool:
	var flat := _flat_levels()
	var idx := _flat_index()
	if idx < 0 or idx >= flat.size() - 1:
		return false
	var nxt: Dictionary = flat[idx + 1]
	return is_level_unlocked(int(nxt["ci"]), int(nxt["li"]))

func goto_prev_level() -> void:
	var flat := _flat_levels()
	var idx := _flat_index()
	if idx <= 0:
		return
	_enter_level(flat[idx - 1])

func goto_next_level() -> void:
	var flat := _flat_levels()
	var idx := _flat_index()
	if idx < 0 or idx >= flat.size() - 1:
		return
	var e: Dictionary = flat[idx + 1]
	if not is_level_unlocked(int(e["ci"]), int(e["li"])):
		return
	_enter_level(e)

func _enter_level(e: Dictionary) -> void:
	if not start_level(int(e["ci"]), int(e["li"])):
		return
	Sound.play("begin")
	Scene.goto(str(e["level"].get("scene", "res://scenes/Battle.tscn")))

# ---------------------------------------------------------------- 进度查询
## 章节分类: "method"=方法推演(专题方法实验与汇总) / "knowledge"=知识体系(知识点由来与简单运用)。
## 两套体系各自成链,互不串轨。
func chapter_kind(index: int) -> String:
	if index < 0 or index >= chapters.size():
		return "knowledge"
	return str(chapters[index].get("kind", "knowledge"))

## 该章是否有真正可进入的关卡(带独立场景);纯占位章节不算,解锁不依赖它们。
func _chapter_playable(ch: Dictionary) -> bool:
	for lv in ch.get("levels", []):
		if str(lv.get("scene", "")) != "":
			return true
	return false

func is_chapter_unlocked(index: int) -> bool:
	if index <= 0:
		return true
	# 只找「同体系」里上一个可进入的章节作为解锁门槛,方法推演与知识体系互不干扰
	var kind := chapter_kind(index)
	for i in range(index - 1, -1, -1):
		if chapter_kind(i) != kind:
			continue
		if not _chapter_playable(chapters[i]):
			continue
		return chapter_stars(chapters[i]) > 0
	return true

func chapter_stars(chapter: Dictionary) -> int:
	var total := 0
	for lv in chapter.get("levels", []):
		total += int(stars.get(lv["id"], 0))
	return total

func chapter_max_stars(chapter: Dictionary) -> int:
	return chapter.get("levels", []).size() * 3

func is_level_unlocked(chapter_index: int, level_index: int) -> bool:
	if chapter_index < 0 or chapter_index >= chapters.size():
		return false
	if not is_chapter_unlocked(chapter_index):
		return false
	if level_index <= 0:
		return true
	var prev: Dictionary = chapters[chapter_index]["levels"][level_index - 1]
	return int(stars.get(prev["id"], 0)) >= 1

func total_stars() -> int:
	var total := 0
	for v in stars.values():
		total += int(v)
	return total

func total_max_stars() -> int:
	var total := 0
	for ch in chapters:
		total += chapter_max_stars(ch)
	return total

func player_level() -> int:
	return 1 + int(total_stars() / 8.0)

## 等级进度(每 8 星升 1 级)：{level, cur, span, ratio}
func level_progress() -> Dictionary:
	var s := total_stars()
	var into := s % 8
	return { "level": 1 + int(s / 8.0), "cur": into, "span": 8, "ratio": float(into) / 8.0 }

# ---------------------------------------------------------------- 称号阶梯
## 当前称号在 RANKS 中的下标(按满星比例达成)
func rank_index() -> int:
	var s := total_stars()
	var mx := maxi(1, total_max_stars())
	var idx := 0
	for i in RANKS.size():
		if s >= int(ceil(float(RANKS[i]["ratio"]) * float(mx))):
			idx = i
	return idx

func rank_title() -> String:
	return str(RANKS[rank_index()]["title"])

## 称号进度：{title, next_title, cur, span, need, ratio}(已满级 next_title 为空)
func rank_progress() -> Dictionary:
	var s := total_stars()
	var mx := maxi(1, total_max_stars())
	var idx := rank_index()
	var prev := int(ceil(float(RANKS[idx]["ratio"]) * float(mx)))
	var has_next := idx < RANKS.size() - 1
	var target := mx if not has_next else int(ceil(float(RANKS[idx + 1]["ratio"]) * float(mx)))
	var span := maxi(1, target - prev)
	var into := clampi(s - prev, 0, span)
	return {
		"title": str(RANKS[idx]["title"]),
		"next_title": str(RANKS[idx + 1]["title"]) if has_next else "",
		"cur": into, "span": span,
		"need": maxi(0, target - s),
		"ratio": float(into) / float(span),
	}

# ---------------------------------------------------------------- 勋章 / 成就
func medal_def(id: String) -> Dictionary:
	for m in MEDALS:
		if str(m["id"]) == id:
			return m
	return {}

func is_medal_unlocked(id: String) -> bool:
	return medals.has(id)

func medal_count() -> int:
	return medals.size()

## 已解锁勋章(按 MEDALS 顺序)
func unlocked_medals() -> Array:
	var arr: Array = []
	for m in MEDALS:
		if medals.has(str(m["id"])):
			arr.append(m)
	return arr

## 隐藏 Boss 关卡 id 列表(以 _boss 结尾)
func _boss_level_ids() -> Array:
	var arr: Array = []
	for ch in chapters:
		for lv in ch.get("levels", []):
			if str(lv.get("id", "")).ends_with("_boss"):
				arr.append(str(lv["id"]))
	return arr

func _cleared_level_count() -> int:
	var n := 0
	for ch in chapters:
		for lv in ch.get("levels", []):
			if int(stars.get(lv["id"], 0)) >= 1:
				n += 1
	return n

func _full_star_level_count() -> int:
	var n := 0
	for ch in chapters:
		for lv in ch.get("levels", []):
			if int(stars.get(lv["id"], 0)) >= 3:
				n += 1
	return n

func _boss_cleared_count() -> int:
	var n := 0
	for id in _boss_level_ids():
		if int(stars.get(id, 0)) >= 1:
			n += 1
	return n

## 单枚勋章的达成判定
func _medal_met(id: String) -> bool:
	match id:
		"first_clear":    return _cleared_level_count() >= 1
		"clear_10":       return _cleared_level_count() >= 10
		"clear_30":       return _cleared_level_count() >= 30
		"clear_60":       return _cleared_level_count() >= 60
		"perfect_1":      return _full_star_level_count() >= 1
		"perfect_10":     return _full_star_level_count() >= 10
		"perfect_30":     return _full_star_level_count() >= 30
		"chapter_master":
			for ch in chapters:
				if chapter_max_stars(ch) > 0 and chapter_stars(ch) >= chapter_max_stars(ch):
					return true
			return false
		"stars_50":       return total_stars() >= 50
		"stars_150":      return total_stars() >= 150
		"stars_300":      return total_stars() >= 300
		"answer_100":     return total_questions >= 100
		"answer_500":     return total_questions >= 500
		"accuracy_80":    return total_questions >= 50 and accuracy() >= 0.8
		"coins_1000":     return coins >= 1000
		"boss_first":     return _boss_cleared_count() >= 1
		"boss_all":
			var total := _boss_level_ids().size()
			return total > 0 and _boss_cleared_count() >= total
		"pet_3":          return pet_fed >= 3
		"pet_10":         return pet_fed >= 10
	return false

## 结算勋章：解锁新达成的成就。notify=true 时弹提示音+飘字(登录回填时传 false)。
func _eval_medals(notify: bool = true) -> void:
	for m in MEDALS:
		var id := str(m["id"])
		if medals.has(id):
			continue
		if _medal_met(id):
			medals[id] = Time.get_datetime_string_from_system(false, true)
			medal_unlocked.emit(m)
			if notify:
				Sound.play("unlock")
				Toast.show_toast("解锁勋章 · %s" % str(m["name"]))

# ---------------------------------------------------------------- 修改
func grant_stars(level_id: String, n: int) -> void:
	stars[level_id] = maxi(int(stars.get(level_id, 0)), n)
	player_exp += 10 * n
	_eval_mastery()
	_eval_medals()
	_save()
	progress_changed.emit()

func reset_progress() -> void:
	for k in stars.keys():
		stars[k] = 0
	player_exp = 0
	coins = 0
	total_questions = 0
	total_correct = 0
	wrong_log.clear()
	level_records.clear()
	medals.clear()
	pet_fed = 0
	pet_satiety = 1.0
	pet_mood = 0.8
	pet_last_seen = 0
	pet_parts.clear()
	pet_stage = 0
	_level_mastery.clear()
	_domain_mastery.clear()
	_save()
	progress_changed.emit()

func add_coins(n: int) -> void:
	coins += n
	_eval_medals()
	_save()
	progress_changed.emit()

func add_pet_fed() -> void:
	pet_fed += 1
	pet_satiety = 1.0
	pet_mood = minf(1.0, pet_mood + 0.12)
	pet_last_seen = int(Time.get_unix_time_from_system())
	_eval_medals()
	_save()

# ---------------------------------------------------------------- 萌宠养成
const PET_DECAY_PER_DAY := 0.32   # 每天饱食度自然下降
const PET_MOOD_BASE := 0.55       # 心情自然回落基准

## 好感度等级：由投喂次数决定(0 初识 / 1 熟悉 / 2 黏人)
func pet_affection_tier() -> int:
	if pet_fed >= 8:
		return 2
	if pet_fed >= 3:
		return 1
	return 0

func pet_hungry() -> bool:
	return pet_satiety < 0.35

func pet_mood_label() -> String:
	if pet_mood >= 0.75:
		return "开心"
	if pet_mood >= 0.45:
		return "一般"
	return "低落"

func pet_satiety_label() -> String:
	if pet_satiety >= 0.7:
		return "吃饱"
	if pet_satiety >= 0.4:
		return "半饱"
	return "好饿"

## 跨会话衰减：按距上次互动的天数降低饱食度、使心情回落；记录离开天数供问候
func pet_decay() -> void:
	var now := int(Time.get_unix_time_from_system())
	if pet_last_seen <= 0:
		pet_last_seen = now
		pet_away_days = 0.0
		return
	pet_away_days = float(now - pet_last_seen) / 86400.0
	if pet_away_days > 0.0:
		pet_satiety = clampf(pet_satiety - PET_DECAY_PER_DAY * pet_away_days, 0.15, 1.0)
		pet_mood = clampf(lerpf(pet_mood, PET_MOOD_BASE, clampf(pet_away_days, 0.0, 1.0)), 0.2, 1.0)
	pet_last_seen = now

## 互动打点：刷新"最近互动"时间(缩短下次的离开天数)
func pet_touch() -> void:
	pet_last_seen = int(Time.get_unix_time_from_system())

# ---------------------------------------------------------------- 知识掌握 / 萌宠进化
## 单关掌握度 0..1(缓存)：星级 + 清关质量 - 错题惩罚；未通关不判掌握。
func level_mastery(level_id: String) -> float:
	return float(_level_mastery.get(level_id, 0.0))

## 领域掌握度 0..1(缓存)：领域内关卡掌握度的平均。
func domain_mastery(domain_id: String) -> float:
	return float(_domain_mastery.get(domain_id, 0.0))

func domain_entries() -> Array:
	return DOMAINS

func domain_def(domain_id: String) -> Dictionary:
	for d in DOMAINS:
		if str(d["id"]) == domain_id:
			return d
	return {}

## 该领域是否已解锁萌宠部件
func pet_part_unlocked(domain_id: String) -> bool:
	return pet_parts.has(domain_id)

func pet_part_count() -> int:
	return pet_parts.size()

func pet_form_name() -> String:
	return PET_FORMS[clampi(pet_stage, 0, PET_FORMS.size() - 1)]

# ------------------------------------------------ 叙事：馆灵记忆碑文
func lore_for(domain_id: String) -> Dictionary:
	for l in LORE:
		if str(l["id"]) == domain_id:
			return l
	return {}

func lore_entries() -> Array:
	return LORE

## 该领域碑文是否已寻回(与萌宠部件解锁同步)
func lore_unlocked(domain_id: String) -> bool:
	return pet_parts.has(domain_id)

func lore_restored_count() -> int:
	return pet_parts.size()

## 记忆恢复度 0..1
func memory_ratio() -> float:
	return float(pet_parts.size()) / float(maxi(1, DOMAINS.size()))

## 已解锁但当前掌握度偏低的领域(生疏，仅影响萌宠表现)
func pet_stale_domains() -> Array:
	var arr: Array = []
	for d in DOMAINS:
		var id := str(d["id"])
		if pet_parts.has(id) and domain_mastery(id) < MASTERY_STALE:
			arr.append(d)
	return arr

## 重算掌握度缓存(关卡 → 领域)。仅在进度变化时调用，避免每帧遍历。
func _recompute_mastery() -> void:
	var wsum: Dictionary = {}
	for k in wrong_log.keys():
		var w: Dictionary = wrong_log[k]
		var lid := str(w.get("level_id", ""))
		wsum[lid] = float(wsum.get(lid, 0.0)) + minf(0.5, float(int(w.get("count", 0))) * 0.1)
	_level_mastery.clear()
	for ch in chapters:
		for lv in ch.get("levels", []):
			var id := str(lv["id"])
			var st := float(int(stars.get(id, 0))) / 3.0
			var m := 0.0
			if st > 0.0:
				var rec: Dictionary = level_records.get(id, {})
				var clean := 0.0
				if not rec.is_empty():
					clean = float(int(rec.get("last_clean", 0))) / float(maxi(1, int(rec.get("last_total", 0))))
				m = clampf(st * 0.65 + clean * 0.25 - minf(float(wsum.get(id, 0.0)), 0.4), 0.0, 1.0)
			_level_mastery[id] = m
	_domain_mastery.clear()
	for d in DOMAINS:
		var sum := 0.0
		var cnt := 0
		for ch in chapters:
			if not (str(ch.get("id", "")) in d["chapters"]):
				continue
			for lv in ch.get("levels", []):
				sum += level_mastery(str(lv["id"]))
				cnt += 1
		_domain_mastery[str(d["id"])] = (sum / float(cnt)) if cnt > 0 else 0.0

## 结算掌握度：重算缓存并解锁新达标的萌宠部件。notify=false 用于登录回填(静默)。
func _eval_mastery(notify: bool = true) -> void:
	_recompute_mastery()
	var newly: Array = []
	for d in DOMAINS:
		var id := str(d["id"])
		if pet_parts.has(id):
			continue
		if domain_mastery(id) >= MASTERY_UNLOCK:
			pet_parts[id] = Time.get_datetime_string_from_system(false, true)
			newly.append(d)
	pet_stage = pet_parts.size()
	if notify and not newly.is_empty():
		for d in newly:
			pet_evolved.emit(pet_stage, d)
		Sound.play("unlock")
		Toast.show_toast("萌宠进化 · 掌握「%s」" % str(newly[0]["title"]))

func unlocked_region_count() -> int:
	var c := 0
	for i in chapters.size():
		if is_chapter_unlocked(i):
			c += 1
	return c

func set_regions_seen(n: int) -> void:
	regions_seen = n
	_save()

## 记录知识体系首页章节卡片的拖拽顺序(章节 id 列表)
func set_chapter_order(ids: Array) -> void:
	chapter_order = ids.duplicate()
	_save()

# ---------------------------------------------------------------- 用户系统
## 记录一次作答(出错位置与重点的数据来源)
func record_answer(level_id: String, qi: int, qname: String, correct: bool, chose: int, ans: int, module: String) -> void:
	total_questions += 1
	if correct:
		total_correct += 1
		# 答对即偿还该题历史错账：逐次递减，结清时清出并奖励
		var key := "%s#%d" % [level_id, qi]
		if wrong_log.has(key):
			var w: Dictionary = wrong_log[key]
			var c := int(w.get("count", 1)) - 1
			if c <= 0:
				wrong_log.erase(key)
				coins += 5
				wrong_cleared.emit(level_id, qi)
			else:
				w["count"] = c
				wrong_log[key] = w
	else:
		var key := "%s#%d" % [level_id, qi]
		var rec: Dictionary = wrong_log.get(key, {})
		wrong_log[key] = {
			"level_id": level_id, "qi": qi, "name": qname, "module": module,
			"count": int(rec.get("count", 0)) + 1,
			"last_chose": chose, "correct": ans,
		}
	pet_mood = clampf(pet_mood + (0.04 if correct else -0.05), 0.2, 1.0)
	_eval_mastery()
	_eval_medals()
	_save()
	progress_changed.emit()

## 记录一次关卡结果
func record_level_result(level_id: String, level_stars: int, clean: int, total: int, trap_missed: bool) -> void:
	var r: Dictionary = level_records.get(level_id, {})
	r["attempts"] = int(r.get("attempts", 0)) + 1
	r["best_stars"] = maxi(int(r.get("best_stars", 0)), level_stars)
	r["last_clean"] = clean
	r["last_total"] = total
	r["trap_missed"] = trap_missed
	level_records[level_id] = r
	_eval_mastery()
	_eval_medals()
	_save()
	progress_changed.emit()

func accuracy() -> float:
	return float(total_correct) / float(maxi(1, total_questions))

## 出错位置：按错误次数从多到少
func wrong_list() -> Array:
	var arr: Array = []
	for k in wrong_log.keys():
		arr.append(wrong_log[k])
	arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["count"]) > int(b["count"]))
	return arr

func clear_wrong(level_id: String, qi: int) -> void:
	wrong_log.erase("%s#%d" % [level_id, qi])
	_save()
	progress_changed.emit()

## 重点：按累计错误次数排序的知识点(关卡)
func key_points() -> Array:
	var agg: Dictionary = {}
	for k in wrong_log.keys():
		var r: Dictionary = wrong_log[k]
		var lid := str(r["level_id"])
		if not agg.has(lid):
			agg[lid] = { "level_id": lid, "count": 0, "module": str(r.get("module", "")) }
		agg[lid]["count"] = int(agg[lid]["count"]) + int(r["count"])
	var arr: Array = []
	for k in agg.keys():
		arr.append(agg[k])
	arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["count"]) > int(b["count"]))
	return arr

func level_info(level_id: String) -> Dictionary:
	for ch in chapters:
		for lv in ch.get("levels", []):
			if lv["id"] == level_id:
				return { "chapter": str(ch.get("title", "")), "name": str(lv.get("name", "")) }
	return { "chapter": "", "name": level_id }

# ---------------------------------------------------------------- 萌宠复习任务(错题生成)
## 该关卡所在知识领域(供任务标注)
func _domain_of_level(level_id: String) -> Dictionary:
	var cid := ""
	for ch in chapters:
		for lv in ch.get("levels", []):
			if str(lv.get("id", "")) == level_id:
				cid = str(ch.get("id", ""))
				break
		if cid != "":
			break
	for d in DOMAINS:
		if cid in d["chapters"]:
			return d
	return {}

## 关卡导航信息：{ci, li, scene}；不存在返回 {}
func _level_nav(level_id: String) -> Dictionary:
	for ci in chapters.size():
		var levels: Array = chapters[ci].get("levels", [])
		for li in levels.size():
			if str(levels[li].get("id", "")) == level_id:
				return {
					"ci": ci, "li": li,
					"scene": str(levels[li].get("scene", "res://scenes/Battle.tscn")),
				}
	return {}

## 由错题生成复习任务(错得越多越靠前)，最多 limit 条。
func pet_quests(limit: int = 3) -> Array:
	var out: Array = []
	for rec in wrong_list():
		if out.size() >= limit:
			break
		var lid := str(rec.get("level_id", ""))
		if _level_nav(lid).is_empty():
			continue
		var info := level_info(lid)
		out.append({
			"level_id": lid, "qi": int(rec.get("qi", 0)),
			"name": str(rec.get("name", "")),
			"module": str(rec.get("module", "")),
			"count": int(rec.get("count", 0)),
			"chapter": str(info.get("chapter", "")),
			"level_name": str(info.get("name", "")),
			"domain": _domain_of_level(lid),
		})
	return out

## 任务的深链目标：{ci, li, scene, qi}
func quest_target(q: Dictionary) -> Dictionary:
	var nav := _level_nav(str(q.get("level_id", "")))
	if nav.is_empty():
		return {}
	nav["qi"] = int(q.get("qi", 0))
	return nav

func has_wrong_entries() -> bool:
	return not wrong_log.is_empty()

## 某题的历史错误次数(键为 level_id#qi)
func wrong_count_for(level_id: String, qi: int) -> int:
	return int((wrong_log.get("%s#%d" % [level_id, qi], {}) as Dictionary).get("count", 0))

# ---------------------------------------------------------------- 错题优先复习
## 错题优先：把历史错过的题(错得越多越靠前)重排到关卡最前面，其余保持原序。
## 返回 { stages: 重排后的题列表, order: Array[int](显示下标→原始下标), review: bool }。
## 注意：order[i] 为该显示位置对应的原始题号，记录作答时须用它作为 qi，才能与错题账本对齐。
func review_order(level_id: String, stages: Array) -> Dictionary:
	var order: Array[int] = []
	for i in stages.size():
		order.append(i)
	var any_wrong := false
	for i in stages.size():
		if wrong_count_for(level_id, i) > 0:
			any_wrong = true
			break
	if not any_wrong or stages.size() < 2:
		return { "stages": stages, "order": order, "review": false }
	order.sort_custom(func(a: int, b: int) -> bool:
		var wa := wrong_count_for(level_id, a)
		var wb := wrong_count_for(level_id, b)
		if wa != wb:
			return wa > wb
		return a < b)
	var re: Array = []
	for i in order:
		re.append(stages[i])
	return { "stages": re, "order": order, "review": true }

# ---------------------------------------------------------------- 学情诊断
## 各领域错题统计：{ domain_id: { count, levels: { level_id: count } } }
func _domain_wrong_stats() -> Dictionary:
	var out: Dictionary = {}
	for k in wrong_log.keys():
		var w: Dictionary = wrong_log[k]
		var d := _domain_of_level(str(w.get("level_id", "")))
		if d.is_empty():
			continue
		var id := str(d["id"])
		if not out.has(id):
			out[id] = { "count": 0, "levels": {} }
		var it: Dictionary = out[id]
		it["count"] = int(it["count"]) + int(w.get("count", 0))
		var lid := str(w.get("level_id", ""))
		it["levels"][lid] = int(it["levels"].get(lid, 0)) + int(w.get("count", 0))
	return out

## 学情诊断：按「掌握度低 + 错题集中」排序薄弱领域，并列出优势领域。
## 返回 { weak: [{domain, mastery, wrong_count, score}], strong: [{domain, mastery}], ready: bool }
func diagnose() -> Dictionary:
	var ready := false
	for d in chapters:
		for lv in d.get("levels", []):
			if int(stars.get(lv["id"], 0)) >= 1:
				ready = true
				break
		if ready:
			break
	if not ready:
		return { "weak": [], "strong": [], "ready": false }
	var stats := _domain_wrong_stats()
	var weak: Array = []
	var strong: Array = []
	for d in DOMAINS:
		var id := str(d["id"])
		var dm := domain_mastery(id)
		var wc := int((stats.get(id, {}) as Dictionary).get("count", 0))
		if dm >= 0.75:
			strong.append({ "domain": d, "mastery": dm })
			continue
		var score := (1.0 - dm) + minf(float(wc), 8.0) * 0.06
		weak.append({ "domain": d, "mastery": dm, "wrong_count": wc, "score": score })
	weak.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	return { "weak": weak, "strong": strong, "ready": true }

## 某领域内最该练的(已解锁)关卡：错多、掌握低、未满星者优先。
func _weakest_level_in_domain(domain_id: String) -> Dictionary:
	var d := domain_def(domain_id)
	if d.is_empty():
		return {}
	var stats := _domain_wrong_stats()
	var lv_wrong: Dictionary = (stats.get(domain_id, {}) as Dictionary).get("levels", {})
	var best: Dictionary = {}
	var best_key := INF
	for ci in chapters.size():
		if not (str(chapters[ci].get("id", "")) in d["chapters"]):
			continue
		var levels: Array = chapters[ci].get("levels", [])
		for li in levels.size():
			if not is_level_unlocked(ci, li):
				continue
			var lv: Dictionary = levels[li]
			var lid := str(lv["id"])
			var key := level_mastery(lid) * 2.0 - minf(float(int(lv_wrong.get(lid, 0))), 6.0) * 0.2
			if int(stars.get(lid, 0)) >= 3:
				key += 3.0
			if key < best_key:
				best_key = key
				best = {
					"level_id": lid, "level_name": str(lv.get("name", "")),
					"ci": ci, "li": li,
					"scene": str(lv.get("scene", "res://scenes/Battle.tscn")),
				}
	return best

## 兜底推荐：首个已解锁且未满星的关卡。
func _first_unmastered_level() -> Dictionary:
	for ci in chapters.size():
		if not is_chapter_unlocked(ci):
			continue
		var levels: Array = chapters[ci].get("levels", [])
		for li in levels.size():
			var lid := str(levels[li]["id"])
			if is_level_unlocked(ci, li) and int(stars.get(lid, 0)) < 3:
				return {
					"level_id": lid, "level_name": str(levels[li].get("name", "")),
					"ci": ci, "li": li,
					"scene": str(levels[li].get("scene", "res://scenes/Battle.tscn")),
					"reason": "继续巩固",
				}
	return {}

## 诊断建议：优先补最弱领域里的薄弱关卡；全都很强则推下一个未满星关卡。
## 返回 { level_id, level_name, ci, li, scene, reason, domain }
func recommended_level() -> Dictionary:
	var diag := diagnose()
	if not diag["ready"]:
		return {}
	var weak: Array = diag["weak"]
	for w in weak:
		var d: Dictionary = w["domain"]
		var pick := _weakest_level_in_domain(str(d["id"]))
		if pick.is_empty():
			continue
		pick["domain"] = d
		pick["reason"] = "「%s」掌握 %d%% · 错题 %d 处" % [str(d["title"]), int(round(float(w["mastery"]) * 100.0)), int(w["wrong_count"])]
		return pick
	var fb := _first_unmastered_level()
	if not fb.is_empty():
		var dd := _domain_of_level(str(fb["level_id"]))
		if not dd.is_empty():
			fb["domain"] = dd
		return fb
	return {}

## 一句学情诊断台词(供萌宠口播)
func diagnosis_line() -> String:
	var diag := diagnose()
	if not diag["ready"]:
		return "我们还没开始呢，先随便挑一关试试吧～"
	var weak: Array = diag["weak"]
	var strong: Array = diag["strong"]
	if weak.is_empty():
		if strong.is_empty():
			return "状态不错！继续把每个知识点都点亮吧～"
		return "你的强项是「%s」，要不要试试更难的？" % str(strong[0]["domain"]["title"])
	var w: Dictionary = weak[0]
	var d: Dictionary = w["domain"]
	var rec := recommended_level()
	var tail := ""
	if not rec.is_empty():
		tail = "建议先练「%s」。" % str(rec.get("level_name", ""))
	return "我发现你在「%s」比较薄弱（掌握 %d%%，错 %d 处）。%s" % [
		str(d["title"]), int(round(float(w["mastery"]) * 100.0)), int(w["wrong_count"]), tail]

# ---------------------------------------------------------------- 用户系统(多用户)
func is_logged_in() -> bool:
	return current_user != ""

func avatar_info(id: String) -> Dictionary:
	for a in AVATARS:
		if a["id"] == id:
			return a
	return AVATARS[0]

func _blank_user() -> Dictionary:
	return {
		"avatar": "player", "player_exp": 0, "coins": 0, "stars": {},
		"total_questions": 0, "total_correct": 0, "wrong_log": {}, "level_records": {}, "pet_fed": 0, "regions_seen": 0,
		"pet_satiety": 1.0, "pet_mood": 0.8, "pet_last_seen": 0,
		"pet_parts": {}, "pet_stage": 0,
		"medals": {},
		"chapter_order": [],
		"last_chapter": "",
		"created": Time.get_datetime_string_from_system(false, true),
	}

## 把当前运行时的进度打包成存档 dict
func _snapshot() -> Dictionary:
	return {
		"avatar": avatar, "player_exp": player_exp, "coins": coins, "stars": stars,
		"total_questions": total_questions, "total_correct": total_correct,
		"wrong_log": wrong_log, "level_records": level_records, "pet_fed": pet_fed, "regions_seen": regions_seen,
		"pet_satiety": pet_satiety, "pet_mood": pet_mood, "pet_last_seen": pet_last_seen,
		"pet_parts": pet_parts, "pet_stage": pet_stage,
		"medals": medals,
		"chapter_order": chapter_order,
		"last_chapter": last_chapter_id,
		"created": users.get(current_user, {}).get("created", Time.get_datetime_string_from_system(false, true)),
	}

## 把某个用户的存档载入运行时
func _apply(d: Dictionary) -> void:
	player_exp = int(d.get("player_exp", 0))
	coins = int(d.get("coins", 0))
	avatar = str(d.get("avatar", "player"))
	total_questions = int(d.get("total_questions", 0))
	total_correct = int(d.get("total_correct", 0))
	pet_fed = int(d.get("pet_fed", 0))
	pet_satiety = clampf(float(d.get("pet_satiety", 1.0)), 0.15, 1.0)
	pet_mood = clampf(float(d.get("pet_mood", 0.8)), 0.2, 1.0)
	pet_last_seen = int(d.get("pet_last_seen", 0))
	var pp = d.get("pet_parts", {})
	pet_parts = pp if typeof(pp) == TYPE_DICTIONARY else {}
	pet_stage = int(d.get("pet_stage", pet_parts.size()))
	regions_seen = int(d.get("regions_seen", 0))
	var co = d.get("chapter_order", [])
	chapter_order = co.duplicate() if typeof(co) == TYPE_ARRAY else []
	last_chapter_id = str(d.get("last_chapter", ""))
	var wl = d.get("wrong_log", {})
	wrong_log = wl if typeof(wl) == TYPE_DICTIONARY else {}
	var lr = d.get("level_records", {})
	level_records = lr if typeof(lr) == TYPE_DICTIONARY else {}
	var md = d.get("medals", {})
	medals = md if typeof(md) == TYPE_DICTIONARY else {}
	for k in stars.keys():
		stars[k] = 0
	var sv = d.get("stars", {})
	if typeof(sv) == TYPE_DICTIONARY:
		for k in sv.keys():
			if stars.has(k):
				stars[k] = int(sv[k])

func list_users() -> Array:
	var arr: Array = []
	for k in users.keys():
		var d: Dictionary = users[k]
		var used := 0
		var sv = d.get("stars", {})
		if typeof(sv) == TYPE_DICTIONARY:
			for kk in sv.keys():
				used += int(sv[kk])
		arr.append({ "name": k, "avatar": str(d.get("avatar", "player")), "stars": used })
	arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["name"]) < str(b["name"]))
	return arr

func create_user(nm: String, av: String) -> bool:
	nm = nm.strip_edges()
	if nm == "" or users.has(nm):
		return false
	users[nm] = _blank_user()
	users[nm]["avatar"] = av
	current_user = nm
	_apply(users[nm])
	_eval_mastery(false)
	_eval_medals(false)
	_save()
	progress_changed.emit()
	return true

func login(nm: String) -> bool:
	if not users.has(nm):
		return false
	current_user = nm
	_apply(users[nm])
	pet_decay()
	_eval_mastery(false)
	_eval_medals(false)
	_save()
	progress_changed.emit()
	return true

func logout() -> void:
	if current_user != "":
		users[current_user] = _snapshot()
	_write_users()
	current_user = ""
	progress_changed.emit()

func delete_user(nm: String) -> void:
	users.erase(nm)
	if current_user == nm:
		current_user = ""
	_write_users()
	progress_changed.emit()

## 从指定文件读取并解析存档，失败返回空字典(不抛出)
func _read_users_file(path: String) -> Dictionary:
	return SaveIO.read_dict(path)

func _load_users() -> void:
	# 依次尝试：主存档 → 备份 → 旧版单人存档，任一损坏都能恢复
	var data := _read_users_file(USERS_PATH)
	var recovered := false
	if data.is_empty():
		data = _read_users_file(USERS_BAK)
		recovered = not data.is_empty()
	if not data.is_empty():
		var u = data.get("users", {})
		if typeof(u) == TYPE_DICTIONARY:
			users = u
		current_user = str(data.get("current", ""))
	# 兼容旧版单人存档 → 迁移为「推演者」
	if users.is_empty() and FileAccess.file_exists(SAVE_PATH):
		var old = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if typeof(old) == TYPE_DICTIONARY:
			old["avatar"] = "player"
			users["推演者"] = old
			current_user = "推演者"
	if current_user != "" and users.has(current_user):
		_apply(users[current_user])
	else:
		current_user = ""
	# 从备份恢复后，立即把主存档写回，避免下次继续读备份
	if recovered and current_user != "":
		_write_users()

## 原子写入：先写临时文件并校验，备份旧档，再替换主档，避免中途被杀导致存档损坏
func _write_users() -> void:
	SaveIO.write_atomic(USERS_PATH, USERS_TMP, USERS_BAK, JSON.stringify({ "current": current_user, "users": users }))

## 应用退到后台 / 关闭 时立即落盘，防止系统随时回收进程丢失进度
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_save()

## 立即落盘(供返回键/退出等时机显式调用)
func save_now() -> void:
	_save()

func _save() -> void:
	if current_user == "":
		return
	users[current_user] = _snapshot()
	_write_users()
