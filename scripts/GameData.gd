extends Node
## 全局数据：课程表、进度、存档

signal progress_changed

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

var chapters: Array = []
var stars: Dictionary = {}      # level_id -> int(0..3)
var player_exp: int = 0
var coins: int = 0

# ---- 用户系统(多用户) ----
var users: Dictionary = {}              # 用户名 -> 存档 dict
var current_user: String = ""           # 当前登录用户名("" 表示未登录)
var avatar: String = "player"
var total_questions: int = 0            # 累计作答数
var total_correct: int = 0              # 累计答对数
var wrong_log: Dictionary = {}          # "level_id#qi" -> {level_id, qi, name, module, count, last_chose, correct}
var level_records: Dictionary = {}      # level_id -> {attempts, best_stars, last_clean, last_total, trap_missed}
var pet_fed: int = 0                    # 萌宠投喂次数
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
func _playable(_e: Dictionary) -> bool:
	return true

func has_prev_level() -> bool:
	var flat := _flat_levels()
	var idx := _flat_index()
	return idx > 0 and _playable(flat[idx - 1])

func has_next_level() -> bool:
	var flat := _flat_levels()
	var idx := _flat_index()
	if idx < 0 or idx >= flat.size() - 1:
		return false
	var nxt: Dictionary = flat[idx + 1]
	return _playable(nxt) and is_level_unlocked(int(nxt["ci"]), int(nxt["li"]))

func goto_prev_level() -> void:
	var flat := _flat_levels()
	var idx := _flat_index()
	if idx <= 0 or not _playable(flat[idx - 1]):
		return
	_enter_level(flat[idx - 1])

func goto_next_level() -> void:
	var flat := _flat_levels()
	var idx := _flat_index()
	if idx < 0 or idx >= flat.size() - 1:
		return
	var e: Dictionary = flat[idx + 1]
	if not _playable(e) or not is_level_unlocked(int(e["ci"]), int(e["li"])):
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

func rank_title() -> String:
	var s := total_stars()
	if s < 5:
		return "见习推演者"
	elif s < 15:
		return "初级推演者"
	elif s < 30:
		return "中级推演者"
	elif s < 50:
		return "高级推演者"
	return "首席推演官"

# ---------------------------------------------------------------- 修改
func grant_stars(level_id: String, n: int) -> void:
	stars[level_id] = maxi(int(stars.get(level_id, 0)), n)
	player_exp += 10 * n
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
	pet_fed = 0
	_save()
	progress_changed.emit()

func add_coins(n: int) -> void:
	coins += n
	_save()
	progress_changed.emit()

func add_pet_fed() -> void:
	pet_fed += 1
	_save()

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
	else:
		var key := "%s#%d" % [level_id, qi]
		var rec: Dictionary = wrong_log.get(key, {})
		wrong_log[key] = {
			"level_id": level_id, "qi": qi, "name": qname, "module": module,
			"count": int(rec.get("count", 0)) + 1,
			"last_chose": chose, "correct": ans,
		}
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
	regions_seen = int(d.get("regions_seen", 0))
	var co = d.get("chapter_order", [])
	chapter_order = co.duplicate() if typeof(co) == TYPE_ARRAY else []
	last_chapter_id = str(d.get("last_chapter", ""))
	var wl = d.get("wrong_log", {})
	wrong_log = wl if typeof(wl) == TYPE_DICTIONARY else {}
	var lr = d.get("level_records", {})
	level_records = lr if typeof(lr) == TYPE_DICTIONARY else {}
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
	_apply(users[nm])
	current_user = nm
	_write_users()
	progress_changed.emit()
	return true

func login(nm: String) -> bool:
	if not users.has(nm):
		return false
	current_user = nm
	_apply(users[nm])
	_write_users()
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
	if not FileAccess.file_exists(path):
		return {}
	var txt := FileAccess.get_file_as_string(path)
	if txt.strip_edges().is_empty():
		return {}
	var data = JSON.parse_string(txt)
	return data if typeof(data) == TYPE_DICTIONARY else {}

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
	var txt := JSON.stringify({ "current": current_user, "users": users })
	var f := FileAccess.open(USERS_TMP, FileAccess.WRITE)
	if f == null:
		# 退路：直接写主档
		var d := FileAccess.open(USERS_PATH, FileAccess.WRITE)
		if d != null:
			d.store_string(txt)
		return
	f.store_string(txt)
	f.close()
	# 校验临时文件可解析
	if typeof(JSON.parse_string(FileAccess.get_file_as_string(USERS_TMP))) != TYPE_DICTIONARY:
		return
	# 备份当前良好存档
	if FileAccess.file_exists(USERS_PATH):
		var cur := FileAccess.get_file_as_string(USERS_PATH)
		if not cur.strip_edges().is_empty() and typeof(JSON.parse_string(cur)) == TYPE_DICTIONARY:
			var b := FileAccess.open(USERS_BAK, FileAccess.WRITE)
			if b != null:
				b.store_string(cur)
				b.close()
	# 替换主档
	DirAccess.remove_absolute(USERS_PATH)
	DirAccess.rename_absolute(USERS_TMP, USERS_PATH)

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
