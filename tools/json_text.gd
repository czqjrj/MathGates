extends Object
## G2 · 关卡作者工具链：JSON「文本级」修改工具。
##
## 目标：在**不重排整个文件**的前提下做小范围修改（新增关卡组 / 改单个字段），
## 保证 git diff 最小、不会把整个文件重新序列化（避免数字精度/排版噪声）。
## 所有定位基于「字符串感知的括号匹配」，不依赖缩进风格。
##
## 用法（不注册 class_name，避免全局类缓存问题）：
##   const JsonText = preload("res://tools/json_text.gd")
##
## 约定：调用方在写盘前必须用 JSON.parse_string 校验结果可解析、且结构未意外损坏。

## 跳过一个字符串字面量：i 指向开头的 `"`，返回结束引号后一位；失败返回 -1。
static func skip_string(raw: String, i: int) -> int:
	if i < 0 or i >= raw.length() or raw[i] != "\"":
		return -1
	i += 1
	while i < raw.length():
		var c := raw[i]
		if c == "\\":
			i += 2
			continue
		if c == "\"":
			return i + 1
		i += 1
	return -1

## 匹配括号：open 指向 `{` 或 `[`，返回配对的 `}` 或 `]` 下标；失败返回 -1。
## 同类括号计数即可正确配对（JSON 良构时不同类括号不会交错）。
static func match_bracket(raw: String, open: int) -> int:
	if open < 0 or open >= raw.length():
		return -1
	var open_c := raw[open]
	if open_c != "{" and open_c != "[":
		return -1
	var close_c := "}" if open_c == "{" else "]"
	var depth := 0
	var i := open
	while i < raw.length():
		var c := raw[i]
		if c == "\"":
			i = skip_string(raw, i)
			if i < 0:
				return -1
			continue
		if c == open_c:
			depth += 1
		elif c == close_c:
			depth -= 1
			if depth == 0:
				return i
		i += 1
	return -1

## 在 [from, to) 内查找键 "key"（后跟 `:` 的字符串字面量）。
## 返回 { "k": 键起始下标, "v": 值首字符下标 }；找不到返回 {}。
static func find_key(raw: String, key: String, from: int = 0, to: int = -1) -> Dictionary:
	if to < 0 or to > raw.length():
		to = raw.length()
	var i := from
	while i < to:
		if raw[i] == "\"":
			var kstart := i
			var vend := skip_string(raw, i)
			if vend < 0:
				return {}
			var j := vend
			while j < to and raw[j] in " \t\r\n":
				j += 1
			if j < to and raw[j] == ":":
				if raw.substr(kstart + 1, vend - kstart - 2) == key:
					var v := j + 1
					while v < to and raw[v] in " \t\r\n":
						v += 1
					return {"k": kstart, "v": v}
			i = vend
			continue
		i += 1
	return {}

## 值终点：v 指向值首字符（对象/数组/字符串/原始值），返回值末尾后一位下标；失败返回 -1。
static func value_end(raw: String, v: int) -> int:
	if v < 0 or v >= raw.length():
		return -1
	var c := raw[v]
	if c == "\"":
		return skip_string(raw, v)
	if c == "{" or c == "[":
		var m := match_bracket(raw, v)
		return m + 1 if m >= 0 else -1
	var i := v
	while i < raw.length() and raw[i] not in [",", "}", "]", "\n", " ", "\t"]:
		i += 1
	return i

## 取 [from, to) 内某键的字符串值（经 JSON 解码；非字符串返回 ""）。
static func key_string(raw: String, key: String, from: int, to: int) -> String:
	var f := find_key(raw, key, from, to)
	if f.is_empty():
		return ""
	var v := int(f["v"])
	if raw[v] != "\"":
		return ""
	var lit := raw.substr(v, value_end(raw, v) - v)
	var out = JSON.parse_string(lit)
	return str(out) if out != null else ""

## 第 n 个数组元素的 { "start", "end" }（下标均指向字符本身；n 从 0 起）；失败返回 {}。
static func nth_element(raw: String, arr_v: int, n: int) -> Dictionary:
	if arr_v < 0 or arr_v >= raw.length() or raw[arr_v] != "[":
		return {}
	var i := arr_v + 1
	var idx := 0
	while i < raw.length():
		while i < raw.length() and raw[i] in " \t\r\n":
			i += 1
		if i >= raw.length() or raw[i] == "]":
			return {}
		if idx == n:
			var e := value_end(raw, i)
			if e < 0:
				return {}
			return {"start": i, "end": e}
		i = value_end(raw, i)
		if i < 0:
			return {}
		idx += 1
		while i < raw.length() and raw[i] in " \t\r\n":
			i += 1
		if i < raw.length() and raw[i] == ",":
			i += 1
			continue
		return {}
	return {}

## idx 所在行的缩进（纯空格）。
static func line_indent(raw: String, idx: int) -> String:
	var i := raw.rfind("\n", idx)
	i += 1
	var out := ""
	while i < idx and raw[i] == " ":
		out += " "
		i += 1
	return out

## 把值序列化为可嵌入文本：JSON.stringify 两空格缩进，第 2 行起加前缀 prefix。
static func embed(value: Variant, prefix: String) -> String:
	return JSON.stringify(value, "  ").replace("\n", "\n" + prefix)

## 在对象末尾（obj_end 指向 `}`）插入一个新键值对。
## pair_text 形如 `"key": <value>`，其续行缩进应为 close_indent + "  "（调用方用 embed 预嵌入）。
static func insert_into_object(raw: String, obj_end: int, pair_text: String) -> String:
	if obj_end < 0 or obj_end >= raw.length() or raw[obj_end] != "}":
		return raw
	var i := obj_end - 1
	while i >= 0 and raw[i] in " \t\r\n":
		i -= 1
	if i < 0:
		return raw
	var head := raw.substr(0, i + 1)
	var tail := raw.substr(obj_end)
	var close_ind := line_indent(raw, obj_end)
	var sep := ",\n" if raw[i] != "{" else "\n"
	return head + sep + close_ind + "  " + pair_text + "\n" + close_ind + tail

## 在数组末尾（arr_v 指向 `[`）追加一个元素；自动处理空数组与逗号。
static func append_into_array(raw: String, arr_v: int, item: Variant) -> String:
	if arr_v < 0 or arr_v >= raw.length() or raw[arr_v] != "[":
		return raw
	var arr_end := match_bracket(raw, arr_v)
	if arr_end < 0:
		return raw
	var close_ind := line_indent(raw, arr_end)
	var i := arr_v + 1
	while i < arr_end and raw[i] in " \t\r\n":
		i += 1
	var empty := i >= arr_end or raw[i] == "]"
	var inner := line_indent(raw, i) if not empty else close_ind + "  "
	var text := embed(item, inner)
	var head := raw.substr(0, arr_end)
	# 去掉 head 尾部空白，让逗号紧跟最后一个元素
	var he := head.length()
	while he > 0 and head[he - 1] in " \t\r\n":
		he -= 1
	head = head.substr(0, he)
	if empty:
		return head + "\n" + inner + text + "\n" + close_ind + raw.substr(arr_end)
	return head + ",\n" + inner + text + "\n" + close_ind + raw.substr(arr_end)

## 替换 [from, to) 内某键的值文本；键不存在时返回原串。
static func replace_key_value(raw: String, key: String, from: int, to: int, v_text: String) -> String:
	var f := find_key(raw, key, from, to)
	if f.is_empty():
		return raw
	var v := int(f["v"])
	var e := value_end(raw, v)
	if e < 0:
		return raw
	return raw.substr(0, v) + v_text + raw.substr(e)

## 顶层对象的收尾 `}` 下标（跳过尾部空白）；失败返回 -1。
static func top_close(raw: String) -> int:
	var i := raw.length() - 1
	while i >= 0 and raw[i] in " \t\r\n":
		i -= 1
	if i >= 0 and raw[i] == "}":
		return i
	return -1
