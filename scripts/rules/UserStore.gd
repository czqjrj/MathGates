class_name UserStore
## A4：存档层（纯规则）——存档 dict ⇄ 运行时字段字典的转换。
## 不读 autoload、不碰磁盘、无 IO；GameData 只负责把成员变量打包 / 回填。
##
## 约定：
## - 运行时字段名与 GameData 的成员变量**同名**，便于用 get/set 批量搬运；
## - 存档键与运行时字段只差一处：`last_chapter_id`（运行时）↔ `last_chapter`（存档）；
## - 旧档缺字段一律取默认值；`stars` 只保留已知关卡 id（由调用方经 base 传入），避免脏档膨胀；
## - `activity`（G3 活动日志）缺失时为空数组，旧档天然兼容。
##
## 单测：tests/Tests.gd::_test_user_store()

## 运行时字段清单（与 GameData 的成员变量同名）。
const FIELDS := [
	"avatar", "player_exp", "coins", "coins_earned", "stars",
	"total_questions", "total_correct", "wrong_log", "srs_plan", "level_records",
	"pet_fed", "regions_seen", "pet_satiety", "pet_mood", "pet_last_seen",
	"pet_parts", "pet_stage", "medals", "chapter_order", "last_chapter_id",
	"owned_avatars", "hint_tokens", "coin_boost", "best_streak", "last_login_date",
	"login_streak", "daily_date", "daily_base", "daily_peak_streak", "daily_claimed",
	"chests_claimed", "events_seen", "activity",
]

## 纯整数字段：存档与运行时同键同义。
const INT_FIELDS := [
	"player_exp", "coins", "total_questions", "total_correct", "pet_fed", "regions_seen",
	"pet_last_seen", "hint_tokens", "coin_boost", "best_streak", "login_streak",
	"daily_peak_streak",
]
## 纯字符串字段。
const STR_FIELDS := ["avatar", "last_login_date", "daily_date"]
## 纯字典字段。
const DICT_FIELDS := [
	"level_records", "medals", "daily_base", "daily_claimed", "chests_claimed",
	"events_seen", "pet_parts",
]

## 新建用户的空白存档（created 由调用方给，避免本文件依赖系统时钟）。
static func blank_user(created: String) -> Dictionary:
	return {
		"avatar": "player", "player_exp": 0, "coins": 0, "stars": {},
		"total_questions": 0, "total_correct": 0, "wrong_log": {}, "srs_plan": {},
		"level_records": {}, "pet_fed": 0, "regions_seen": 0,
		"pet_satiety": 1.0, "pet_mood": 0.8, "pet_last_seen": 0,
		"pet_parts": {}, "pet_stage": 0,
		"medals": {},
		"chapter_order": [],
		"last_chapter": "",
		"coins_earned": 0,
		"owned_avatars": ["player"],
		"hint_tokens": 0, "coin_boost": 0,
		"best_streak": 0, "last_login_date": "", "login_streak": 0,
		"daily_date": "", "daily_base": {}, "daily_peak_streak": 0, "daily_claimed": {},
		"chests_claimed": {}, "events_seen": {}, "activity": [],
		"created": created,
	}

## 运行时状态 → 存档 dict（值按引用搬运，与旧实现一致；state 里没有的字段不写档）。
static func snapshot(state: Dictionary, created: String) -> Dictionary:
	var d := {}
	for f in FIELDS:
		if f == "last_chapter_id" or not state.has(f):
			continue
		d[f] = state.get(f)
	d["last_chapter"] = str(state.get("last_chapter_id", ""))
	d["created"] = created
	return d

## 存档 dict → 运行时状态 dict（缺字段取默认值、越界值钳制）。
## base：当前运行时状态（用于取已知星级键）；avatar_ids：全部头像 id（旧档缺 owned_avatars 时视为全解锁）。
static func parse(d: Dictionary, base: Dictionary, avatar_ids: Array) -> Dictionary:
	var st := {}
	for f in INT_FIELDS:
		st[f] = _int_of(d, f, 0)
	for f in STR_FIELDS:
		st[f] = _str_of(d, f, "")
	for f in DICT_FIELDS:
		st[f] = _dict_of(d, f)
	# —— 默认值依赖别的字段的几项 ——
	st["coins_earned"] = _int_of(d, "coins_earned", _int_of(d, "coins", 0))
	var pp: Dictionary = st["pet_parts"]
	st["pet_stage"] = _int_of(d, "pet_stage", pp.size())
	st["pet_satiety"] = clampf(_float_of(d, "pet_satiety", 1.0), 0.15, 1.0)
	st["pet_mood"] = clampf(_float_of(d, "pet_mood", 0.8), 0.2, 1.0)
	var oa = d.get("owned_avatars", null)
	if typeof(oa) == TYPE_ARRAY:
		st["owned_avatars"] = (oa as Array).duplicate()
	else:
		st["owned_avatars"] = avatar_ids.duplicate()
	var co = d.get("chapter_order", null)
	st["chapter_order"] = (co as Array).duplicate() if typeof(co) == TYPE_ARRAY else []
	var ac = d.get("activity", null)
	st["activity"] = (ac as Array).duplicate() if typeof(ac) == TYPE_ARRAY else []
	st["last_chapter_id"] = _str_of(d, "last_chapter", "")
	# —— 星级：只保留已知关卡 id（未知 id 丢弃）——
	var stars := {}
	var bs = base.get("stars", null)
	if typeof(bs) == TYPE_DICTIONARY:
		var bsd: Dictionary = bs
		for k in bsd.keys():
			stars[k] = 0
	var sv = d.get("stars", null)
	if typeof(sv) == TYPE_DICTIONARY:
		var svd: Dictionary = sv
		for k in svd.keys():
			if stars.has(k):
				stars[k] = _int_of(svd, str(k), 0)
	st["stars"] = stars
	# —— 错题账与复习排程：类型兜底 + 迁移钳制 ——
	st["wrong_log"] = _dict_of(d, "wrong_log")
	st["srs_plan"] = SrsStore.normalize(_dict_of(d, "srs_plan"))
	return st

# ---------------------------------------------------------------- 脏档兜底
## 取整数（缺失 / null / 非数字 → 默认值）——手改过的脏档不该让载入整个炸掉。
static func _int_of(d: Dictionary, key: String, def: int) -> int:
	var v = d.get(key, null)
	if v == null:
		return def
	var t := typeof(v)
	if t == TYPE_INT or t == TYPE_FLOAT or t == TYPE_BOOL:
		return int(v)
	if t == TYPE_STRING and str(v).is_valid_int():
		return int(str(v))
	return def

## 取浮点（缺失 / null / 非数字 → 默认值）。
static func _float_of(d: Dictionary, key: String, def: float) -> float:
	var v = d.get(key, null)
	if v == null:
		return def
	var t := typeof(v)
	if t == TYPE_INT or t == TYPE_FLOAT or t == TYPE_BOOL:
		return float(v)
	if t == TYPE_STRING and str(v).is_valid_float():
		return float(str(v))
	return def

## 取字符串（缺失 / null → 默认值）。
static func _str_of(d: Dictionary, key: String, def: String = "") -> String:
	var v = d.get(key, null)
	return def if v == null else str(v)

## 取字典（缺失 / null / 非字典 → 空字典）。
static func _dict_of(d: Dictionary, key: String) -> Dictionary:
	var v = d.get(key, null)
	return v if typeof(v) == TYPE_DICTIONARY else {}

## 迁移：把历史错题记录的 module 统一为规范领域 id（旧档可能是 ""、"line" 或章节 id）。
## domain_of：level_id -> domain id 的取法（由调用方注入，保持本文件无 autoload 依赖）。
static func normalize_wrong_modules(wrong_log: Dictionary, domain_of: Callable) -> Dictionary:
	var out := {}
	for key in wrong_log.keys():
		var rec = wrong_log[key]
		if typeof(rec) != TYPE_DICTIONARY:
			out[key] = rec
			continue
		var r: Dictionary = rec
		var did := str(domain_of.call(str(r.get("level_id", ""))))
		if did != "" and str(r.get("module", "")) != did:
			r["module"] = did
		out[key] = r
	return out

## 用户列表摘要（供登录页/档案库列表）：名字、头像、总星数、最高连击，按名字升序。
## 纯聚合，不读 autoload；users：{ 名字 -> 存档 dict }。
static func list_summaries(users: Dictionary) -> Array:
	var arr: Array = []
	for k in users.keys():
		var d: Dictionary = users[k]
		var used := 0
		var sv = d.get("stars", {})
		if typeof(sv) == TYPE_DICTIONARY:
			for kk in (sv as Dictionary).keys():
				used += int((sv as Dictionary)[kk])
		arr.append({ "name": k, "avatar": str(d.get("avatar", "player")),
			"stars": used, "best_streak": int(d.get("best_streak", 0)) })
	arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["name"]) < str(b["name"]))
	return arr
