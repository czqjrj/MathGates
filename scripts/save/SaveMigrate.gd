class_name SaveMigrate
extends RefCounted
## F5：存档版本化与升版迁移（纯规则，无 IO、不碰 autoload）。
##
## 存档顶层带 `schema` 整数版本号。载入时先 `migrate()` 把旧档升到当前版本，
## 再交给 `UserStore.parse()`。这样将来**改存档结构**时只需在本文件追加一段
## `_v{n}_to_v{n+1}`，旧档自动升级，而不是「只能丢档」。
##
## 约定：
## - 版本号**只增不减**，且 `CURRENT` 必须等于最后一段迁移的目标版本；
## - 无 `schema` 字段的历史档视为版本 **0**（`UserStore.parse` 的 `.get(key, default)`
##   已能兜住缺字段，故 0→1 只补版本号，不改数据）；
## - 未识别的「更高版本」档（如用户在新版导出、旧版导入）**不静默降级**：
##   `migrate` 返回 `downgraded=true`，由调用方决定是否拒绝导入。
##
## 单测：tests/Tests.gd::_test_save_migrate()

## 当前存档结构版本。**每次改存档结构必须 +1 并补一段迁移**。
const CURRENT := 1

## 把任意版本的存档 dict 升到 `CURRENT`。
## 返回 { "data": Dictionary, "from": int, "to": int, "downgraded": bool }。
static func migrate(d: Dictionary) -> Dictionary:
	var from := int(d.get("schema", 0))
	var out := d.duplicate(true)
	if from > CURRENT:
		# 来自更新版本的存档：不动数据，标记出来让上层决定
		out["schema"] = from
		return { "data": out, "from": from, "to": from, "downgraded": true }
	var v := from
	while v < CURRENT:
		out = _step(v, out)
		v += 1
	out["schema"] = CURRENT
	return { "data": out, "from": from, "to": CURRENT, "downgraded": false }

## 单步迁移：v → v+1。新增结构改动时在此追加分支。
static func _step(v: int, d: Dictionary) -> Dictionary:
	match v:
		0:
			# 0 → 1：历史档无版本号（字段全靠 .get 默认值兜）。仅登记版本，不动数据。
			return d
		_:
			return d

## 便捷：只管数据、不要元信息。downgraded 时原样返回（上层可用 `is_current` 判定）。
static func upgrade(d: Dictionary) -> Dictionary:
	return migrate(d)["data"]

## 存档是否已被本版本认识（未降级）。
static func recognized(d: Dictionary) -> bool:
	return int(d.get("schema", 0)) <= CURRENT
