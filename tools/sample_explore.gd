extends SceneTree
## B4 人工抽检器：把全库探究轮按「实验 → 追问」闭环情况分类，最可疑的排前面。
##
## 用法：godot --headless --path . --script res://tools/sample_explore.gd
##       godot --headless --path . --script res://tools/sample_explore.gd -- 12   （每张清单最多 12 条）
##
## 为什么不做成硬闸门：B4 原计划的静态口径「追问里的数值是否落在 `scene.sliders` 值域内」
## 实测**假阳性 21/25**——题干里的方程常数（`(x−2)²+(y+1)²=9` 的 9）会被当成「学生够不到的
## 参数」；而 B4 自己举的反例 `seq_ap/1`（`a₁=1、d=2` 恰是滑块当前值）反而被判「闭环」。
## 所以机器只兜得住一条最硬的（A 类，已进 `check_questions`），其余交人工按清单读。
##
## 四张清单：
##   A 说能拖但没得拖 —— 文案承诺拖动/滑块，场景没有任何可拖方言（硬规则，应为 0）
##   B 能拖但追问与当前状态无关 —— 追问里的数字没有一个等于滑块当前值（拖了也不改答案）
##   C 静态示意图 + 追问要另算 —— 无可拖元素，正确答案也不在画面文本里（人读：该不该改成看图作答）
##   D 追问答案直接印在图上 —— 闭环，但可能过易（B3 要的是「读图」，不是「读答案」）

const DATA_DIR := "res://data"
const UI_KEYS := ["sliders", "slider", "drag", "break"]
const D3_KEYS := ["solids", "faces", "planes", "spheres", "view"]
const DRAG_WORDS := ["拖动", "拉动", "拖一下", "调节"]
const SLIDER_WORDS := ["滑块", "滑动"]

var _n := 8
var _total := 0
var _ui := 0
var _a: Array = []
var _b: Array = []
var _c: Array = []
var _d: Array = []
var _num_re: RegEx

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and str(args[0]).is_valid_int():
		_n = maxi(1, int(args[0]))
	_num_re = RegEx.create_from_string("-?\\d+(?:\\.\\d+)?")
	_scan()
	print("EXPLORE: %d 轮 / 可拖 %d / 静态 %d" % [_total, _ui, _total - _ui])
	_show("A 说能拖但没得拖（硬规则，应为 0）", _a)
	_show("B 能拖但追问与当前状态无关（数字都不等于滑块当前值）", _b)
	_show("C 静态示意图 + 追问要另算（答案不在画面文本）", _c)
	_show("D 追问答案直接印在图上（闭环但可能过易）", _d)
	quit(0)

func _scan() -> void:
	var d := DirAccess.open(DATA_DIR)
	if d == null:
		print("EXPLORE-FAIL: 无法打开 " + DATA_DIR)
		return
	var names: Array = []
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if not d.current_is_dir() and n.ends_with("_levels.json"):
			names.append(n)
		n = d.get_next()
	d.list_dir_end()
	names.sort()
	for f in names:
		var raw = JSON.parse_string(FileAccess.get_file_as_string(DATA_DIR + "/" + str(f)))
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		for gk in raw:
			var g = raw[gk]
			if typeof(g) != TYPE_DICTIONARY:
				continue
			var levels = g.get("levels", null)
			if not levels is Array:
				continue
			var i := 0
			for lv in levels:
				i += 1
				if not lv is Dictionary:
					continue
				if str(lv.get("type", "")) != "explore":
					continue
				_total += 1
				_check("%s|%s#%d" % [str(f), str(gk), i], lv)
	if _total == 0:
		print("EXPLORE-FAIL: 没扫到任何探究轮，扫描口径已失效")

func _check(tag: String, lv: Dictionary) -> void:
	var sc = lv.get("scene", null)
	var s: Dictionary = sc if sc is Dictionary else {}
	var has_ui := false
	for k in UI_KEYS:
		var v = s.get(k, null)
		if v == null:
			continue
		if v is Array and (v as Array).is_empty():
			continue
		if v is Dictionary and (v as Dictionary).is_empty():
			continue
		has_ui = true
	if has_ui:
		_ui += 1
	var is_3d := false
	for k in D3_KEYS:
		if s.has(k):
			is_3d = true
	var claim_text := "%s %s %s" % [str(lv.get("q", "")), str(lv.get("goal", "")), str(lv.get("tip", ""))]
	var steps = lv.get("steps", null)
	if steps is Array:
		for x in steps:
			claim_text += " " + str(x)
	if not has_ui and _claims_ui(claim_text) and (not is_3d or _claims_slider(claim_text)):
		_a.append("%s | %s" % [tag, _short(str(lv.get("q", "")))])
	var ask := str(lv.get("ask", ""))
	var opts = lv.get("opts", null)
	var ans = lv.get("ans", null)
	var answer := ""
	var is_idx := typeof(ans) == TYPE_INT or typeof(ans) == TYPE_FLOAT
	if opts is Array and is_idx and int(ans) >= 0 and int(ans) < (opts as Array).size():
		answer = str((opts as Array)[int(ans)])
	var scene_text := _strings(s)
	var visible := answer != "" and scene_text.find(answer) >= 0
	if visible:
		_d.append("%s | 答案「%s」 | %s" % [tag, _short(answer), _short(ask)])
	elif not has_ui:
		_c.append("%s | %s | 答：%s" % [tag, _short(ask), _short(answer)])
	if has_ui and not visible:
		var ask_nums := _nums(ask)
		if not ask_nums.is_empty() and not _touches_current(ask_nums, s):
			_b.append("%s | %s | 当前值 %s" % [tag, _short(ask), str(_currents(s))])

## 场景里**真正显示给学生的文字**（只取字符串值，不取键名/坐标数字，
## 否则答案「1」会匹配到 `"x": [-1, 5]` 里，把「答案可见」判成一片假阳性）。
func _strings(v: Variant) -> String:
	if v is String:
		return v + " "
	if v is Array:
		var out := ""
		for x in v:
			out += _strings(x)
		return out
	if v is Dictionary:
		var out2 := ""
		for k in v:
			out2 += _strings(v[k])
		return out2
	return ""

func _claims_slider(t: String) -> bool:
	for w in SLIDER_WORDS:
		if t.find(w) >= 0:
			return true
	return false

func _claims_ui(t: String) -> bool:
	if _claims_slider(t):
		return true
	for w in DRAG_WORDS:
		if t.find(w) >= 0:
			return true
	return false

## 追问里出现的数字（去掉公式段后取数值），用于判断「条件是不是实验当前状态」。
func _nums(t: String) -> Array:
	var s := t.replace("−", "-")
	var out: Array = []
	for m in _num_re.search_all(s):
		out.append(float(m.get_string()))
	return out

## 场景里所有可调参数的当前值（滑块 value / 分界点 value / 拖点 start 与 answer）。
func _currents(s: Dictionary) -> Array:
	var out: Array = []
	var sls = s.get("sliders", null)
	if sls is Array:
		for sl in sls:
			if sl is Dictionary and sl.has("value"):
				out.append(float(sl["value"]))
	var one = s.get("slider", null)
	if one is Dictionary and one.has("value"):
		out.append(float(one["value"]))
	var br = s.get("break", null)
	if br is Dictionary and br.has("value"):
		out.append(float(br["value"]))
	var dr = s.get("drag", null)
	if dr is Dictionary:
		for k in ["start", "answer"]:
			var v = dr.get(k, null)
			if v is Array:
				for x in v:
					out.append(float(x))
	return out

func _touches_current(nums: Array, s: Dictionary) -> bool:
	var cur := _currents(s)
	for n in nums:
		for c in cur:
			# 题干里的 `(x−2)²` 会被正则连负号抓成 −2，而滑块当前值是 2：
			# 符号来自「x−2」的减号，不是参数的符号，所以带绝对值再比一次。
			if absf(float(n) - float(c)) <= 0.000001 or absf(absf(float(n)) - absf(float(c))) <= 0.000001:
				return true
	return false

func _short(t: String) -> String:
	var s := t.replace("\n", " ").strip_edges()
	return s.substr(0, 60)

func _show(title: String, rows: Array) -> void:
	print("")
	print("== %s：%d 条 ==" % [title, rows.size()])
	for i in mini(_n, rows.size()):
		print("  " + str(rows[i]))
	if rows.size() > _n:
		print("  ...还有 %d 条" % (rows.size() - _n))
