class_name ProgressCode
extends RefCounted
## F5：进度导出 / 导入——把单个用户的存档编成一段**可复制的文本码**，
## 经系统分享 / 聊天 / 便签在设备间搬运，**不引入账号体系、不联网**。
##
## 格式：`MG1:` + Base64(JSON)。JSON 里带 `schema`（交由 SaveMigrate 升版）
## 与 `name`（用户名，导入时由用户决定是否沿用），**不含**其它用户的存档。
##
## 安全：Base64 只是编码，不是加密——文本码确实是明文进度，界面须提示用户
## 「像密码一样自行保管、不要公开分享」。
##
## 纯规则：不读写文件、不碰 autoload；存档 dict 的取得与写回由 GameData 负责。
##
## 单测：tests/Tests.gd::_test_progress_code()

## 文本码前缀（版本化魔数，便于将来换格式时识别老码）。
const PREFIX := "MG1:"

## Base64 字符集预检（避免把坏串丢给解码器触发引擎 ERROR 噪声）。
static var _B64_RE: RegEx = null

static func _b64_re() -> RegEx:
	if _B64_RE == null:
		_B64_RE = RegEx.new()
		_B64_RE.compile("^[A-Za-z0-9+/=]+$")
	return _B64_RE

## 把「单个用户的存档 dict + 用户名」编成文本码。
static func encode(name: String, user: Dictionary) -> String:
	var payload := {
		"schema": SaveMigrate.CURRENT,
		"name": name,
		"user": user,
	}
	var b64 := Marshalls.utf8_to_base64(JSON.stringify(payload))
	return PREFIX + b64

## 解码文本码 → { "ok": bool, "error": String, "name": String, "user": Dictionary }。
## 任何解析/校验失败都返回 ok=false，绝不抛出（用户在界面上手输，脏码是常态）。
static func decode(code: String) -> Dictionary:
	var bad := func(msg: String) -> Dictionary:
		return { "ok": false, "error": msg, "name": "", "user": {} }
	var s := code.strip_edges()
	if s == "":
		return bad.call("文本码为空")
	if not s.begins_with(PREFIX):
		return bad.call("不是本应用的进度码（应以 %s 开头）" % PREFIX)
	var b64 := s.substr(PREFIX.length()).strip_edges()
	# 容忍用户粘贴时折行/夹空格
	b64 = b64.replace("\n", "").replace("\r", "").replace(" ", "")
	if b64 == "":
		return bad.call("文本码内容为空")
	# 先做字符集/长度预检，避免把坏串丢给 base64 解码器（引擎会打 ERROR 噪声）
	if not _b64_re().search(b64) or b64.length() % 4 != 0:
		return bad.call("文本码损坏（Base64 无法解码）")
	var raw := Marshalls.base64_to_utf8(b64)
	if raw == "":
		return bad.call("文本码损坏（Base64 无法解码）")
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return bad.call("文本码内容不是有效的存档")
	var payload: Dictionary = parsed
	var u = payload.get("user", null)
	if typeof(u) != TYPE_DICTIONARY:
		return bad.call("文本码缺少存档数据")
	var ud: Dictionary = u
	if ud.is_empty():
		return bad.call("存档数据为空")
	return {
		"ok": true, "error": "", "name": str(payload.get("name", "")),
		"user": SaveMigrate.upgrade(ud),
	}

## 简要描述一段文本码里的进度（给「导入前确认」弹窗用）。
## 只读几个关键计数，不暴露题目原文。
static func summary(user: Dictionary) -> String:
	var wl = user.get("wrong_log", {})
	var stars := 0
	var sv = user.get("stars", {})
	if typeof(sv) == TYPE_DICTIONARY:
		for k in (sv as Dictionary).keys():
			stars += int((sv as Dictionary)[k])
	var medals := 0
	var mv = user.get("medals", {})
	if typeof(mv) == TYPE_DICTIONARY:
		medals = (mv as Dictionary).size()
	return "★%d · 作答 %d · 错题 %d · 勋章 %d · 萌宠形态 %d" % [
		stars,
		int(user.get("total_questions", 0)),
		(wl as Dictionary).size() if typeof(wl) == TYPE_DICTIONARY else 0,
		medals,
		int(user.get("pet_stage", 0)),
	]

## 直接给弹窗用：解码 + 摘要。解码失败时返回错误文案。
static func describe(code: String) -> String:
	var dec := decode(code)
	if not bool(dec["ok"]):
		return str(dec["error"])
	return summary(dec["user"])

## 为导入的用户挑一个不与既有用户冲突的名字（用户偏好名 > 码里的名字 > 缺省）。
## 冲突时加 ` (2)`、` (3)`… 后缀，绝不覆盖既有进度。existing：既有用户名集合。
static func pick_name(code_name: String, preferred: String, existing: Dictionary) -> String:
	var nm := preferred.strip_edges()
	if nm == "":
		nm = code_name.strip_edges()
	if nm == "":
		nm = "导入的用户"
	var base := nm
	var n := 2
	while existing.has(nm):
		nm = "%s (%d)" % [base, n]
		n += 1
	return nm
