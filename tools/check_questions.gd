extends SceneTree
## 内容校验器（TODO A5）。
##
## 把关卡数据与编校一致性做成可自动跑的检查，并把「内容看板」打出来。
## 用法：
##   godot --headless --path . --script res://tools/check_questions.gd
##   godot --headless --path . --script res://tools/check_questions.gd -- --write-baseline
##
## 退出码：0 = 无「新问题」；1 = 存在不在基线内的新问题。
##
## 基线机制：历史遗留问题（如 B9 的轮次编号错位）记在
##   res://tools/check_questions_baseline.txt
## 里，逐行一条签名；这些记为「已知」，不阻塞 CI。修完后删掉对应行即可。
## 全 AI 批量产内容时，这个机制让「新引入的错误」立刻红灯，而存量债不挡路。
##
## 覆盖的 TODO 条目：
##   A5  结构 / ans 范围 / 选项重复 / 题干重复 / 轮次编号 / inline 覆盖
##   A10 命名公式自检（引用了未声明的 {f:} → 报错；孤儿命名 → 看板）
##   A12 跨文件重名关卡数据
##   A17 命名/映射自检（章节 lab → 数据文件存在性 / 孤儿数据文件 / 单复数近名文件对）
##   B7  图片选项计数（看板）      B9  轮次标签编号错位（清单）
##   B13 口播覆盖率/盲点命令（看板） D2  anim 演示覆盖率（看板）

const DATA_DIR := "res://data"
const BASELINE_PATH := "res://tools/check_questions_baseline.txt"

## 含特殊数学符号的字符集（同 tools/check_inline.gd，用于过滤普通标点噪声）。
const MATH_CHARS := "²³¹⁰⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₉√·×÷±≤≥≠≈∞∈∉⊆⊇∪∩→←⇒⇔∀∃∠°Δαβγθλμπ∅"

## B5 · 干扰项关键词黑名单：命中即「范畴错误型干扰项」（不列式就能排除，诊断价值为零）。
## 词表刻意保守——只收全库审计确认过的通用回避句式；学科专属的范畴错误
## （如在计数题里写「错位相减」）按章逐条整改，不进黑名单。
const BAD_DISTRACTOR := ["画折线图", "求概率密度", "无法判断", "无法确定", "无法比较", "不能确定", "说不清"]

var _issues: Array[String] = []          ## "file|key|detail"
var _known := {}                         ## 基线签名集合
var _label_re: RegEx
var _cjk: RegEx
## B8：解析/提示里按**位置**指代选项（运行时会打乱选项，写死的位置会指错）
var _posref_re: RegEx
## B8 看板用：模糊的顺序措辞（可能指数列的项，不硬报）
var _orderref_re: RegEx
var _order_ref_hits := 0
## B12 看板：hint 与正确项「换说法复述」的题数（硬泄露另走 _add）
var _hint_soft := 0
# ---- 看板统计
var _n_files := 0
var _n_levels := 0
var _n_questions := 0
var _n_choice := 0
var _n_multi := 0
var _n_interact := 0
var _n_input := 0
var _n_explore := 0
var _n_explore_stmt := 0
var _ans_hist := {}
var _img_opt_count := 0
var _img_opt_questions := 0
var _anim_files := {}
var _num_mismatch := 0
var _num_mismatch_files := {}
var _dup_stem := 0
var _bad_distractor := 0
var _key_owner := {}
var _inline_missing := {}
var _inline_checked := 0
## A10 看板：已声明但全库无人引用的命名公式（存量迁移完成后应为空）。
var _named_orphans: Array[String] = []
## B13 口播看板：公式段总数 / 含公式字段数 / 盲点命令计数。
var _n_speech_seg := 0
var _n_speech_field := 0
var _speech_blind := {}
var _re_dollar_b: RegEx = null
var _re_named_b: RegEx = null
## A17：近名文件对（单复数）看板信息，如 "conic/conics(均在用)"。
var _naming_pairs: Array[String] = []
## A10：剥离正文里的 $$LaTeX$$ 片段（已由运行时渲染，不再走 inline_math.json 覆盖检查）。
var _dollar: RegEx
## 每个关卡数据 key 的题目数 / 所属文件（供 E2 的「每章关卡数/题数」看板）。
var _group_q := {}
var _group_file := {}

func _initialize() -> void:
	_label_re = RegEx.new()
	_label_re.compile("^([0-9]+)[-.．]")
	_cjk = RegEx.new()
	_cjk.compile("[\\x{2e80}-\\x{303f}\\x{31c0}-\\x{9fff}\\x{f900}-\\x{faff}\\x{fe30}-\\x{fe4f}\\x{ff00}-\\x{ffef}]+")
	_posref_re = RegEx.new()
	_posref_re.compile("选项\\s*[0-9A-D]")
	_orderref_re = RegEx.new()
	_orderref_re.compile("最后\\s*[一两二三1-4]\\s*项|第\\s*[1-4]\\s*项|依次是")
	_dollar = RegEx.new()
	_dollar.compile("\\$\\$[^$]+\\$\\$")
	# 触发 inline_math.json 加载（纯中文入参，不会触发 MicroTeX 渲染）
	InlineMath.inline("预热", 24)

	_load_baseline()
	for f in _level_files():
		_check_file(f)
	_check_cross_file_dups()
	_check_naming()
	_check_named_formulas()
	_report()

# ---------------------------------------------------------------- 文件收集

func _level_files() -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(DATA_DIR)
	if d == null:
		push_error("无法打开 " + DATA_DIR)
		return out
	for f in d.get_files():
		if f.ends_with("_levels.json"):
			out.append(DATA_DIR + "/" + f)
	out.sort()
	return out

# ---------------------------------------------------------------- 单文件校验

func _check_file(path: String) -> void:
	var raw := FileAccess.get_file_as_string(path)
	if raw == "":
		_add(path, "*", "空文件或读取失败")
		return
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		_add(path, "*", "顶层不是 JSON 对象（解析失败？）")
		return
	_n_files += 1
	var group_no := 0
	var stem_seen := {}
	for key in data.keys():
		group_no += 1
		var k := str(key)
		if not _key_owner.has(k):
			_key_owner[k] = []
		(_key_owner[k] as Array).append(path)
		var g = data[key]
		if typeof(g) != TYPE_DICTIONARY:
			_add(path, k, "关卡不是对象")
			continue
		var lv = g.get("levels", null)
		if typeof(lv) != TYPE_ARRAY or (lv as Array).is_empty():
			_add(path, k, "缺少非空 levels 数组")
			continue
		_n_levels += 1
		# 关卡级标题/综述也参与公式覆盖检查
		_check_inline(path, k, "title", str((g as Dictionary).get("title", "")))
		_check_inline(path, k, "summary", str((g as Dictionary).get("summary", "")))
		var stages: Array = lv
		var q_before := _n_questions
		for i in stages.size():
			_check_stage(path, k, group_no, i, stages[i], stem_seen)
		_group_q[k] = int(_group_q.get(k, 0)) + (_n_questions - q_before)
		_group_file[k] = path

func _check_stage(path: String, key: String, group_no: int, idx: int, s: Variant, stem_seen: Dictionary) -> void:
	var where := "第 %d 轮" % (idx + 1)
	if typeof(s) != TYPE_DICTIONARY:
		_add(path, key, "%s 不是对象" % where)
		return
	var st: Dictionary = s
	var rtype := str(st.get("type", ""))
	var is_interact := rtype == "interact" or st.has("gate") or st.has("answers")
	var is_input := rtype == "input"
	var q := str(st.get("q", ""))
	if rtype == "explore":
		_n_explore += 1
		if q.find("？") < 0 and q.find("?") < 0:
			_n_explore_stmt += 1
	if q.strip_edges() == "" and not is_interact:
		_add(path, key, "%s 缺少 q（且非 interact/gate 轮）" % where)
	elif q.strip_edges() != "":
		# 题干重复（同文件内）；确定性重复多为复制残留
		var h := q.hash()
		if stem_seen.has(h):
			_dup_stem += 1
			_add(path, key, "%s 题干与 %s 重复：%s" % [where, stem_seen[h], q.substr(0, 24)])
		else:
			stem_seen[h] = "%s/%s" % [key, where]

	# ---- 选项 / 答案
	var opts = st.get("opts", null)
	if opts == null:
		if is_input:
			_n_input += 1
			_n_questions += 1
			if not st.has("ans"):
				_add(path, key, "%s 填空轮缺少 ans" % where)
		elif is_interact:
			_n_interact += 1
		_check_inline(path, key, where + ".q", q)
		_check_inline(path, key, where + ".ask", str(st.get("ask", "")))
		_check_hint_leak(path, key, where, st)
		_check_label(path, key, group_no, where, st)
		_check_anim(path, st)
		return
	if typeof(opts) != TYPE_ARRAY:
		_add(path, key, "%s opts 不是数组" % where)
		return
	var arr: Array = opts
	if arr.size() < 2:
		_add(path, key, "%s 选项少于 2 个" % where)
	_n_questions += 1
	var ans = st.get("ans", null)
	var multi := ans is Array
	if multi:
		_n_multi += 1
	else:
		_n_choice += 1
		if ans != null:
			var ai0 := int(ans)
			_ans_hist[ai0] = int(_ans_hist.get(ai0, 0)) + 1
	var seen := {}
	var n_img_here := 0
	for o in arr:
		var t := str(o)
		if seen.has(t):
			_add(path, key, "%s 选项重复：%s" % [where, t.substr(0, 30)])
		seen[t] = true
		if t.begins_with("res://"):
			_img_opt_count += 1
			n_img_here += 1
		else:
			_check_inline(path, key, where + ".opt", t)
	if n_img_here > 0:
		_img_opt_questions += 1
	# ans 合法性
	if ans == null:
		if not is_interact:
			_add(path, key, "%s 有 opts 但缺 ans" % where)
	elif ans is Array:
		var seen_a := {}
		for v in (ans as Array):
			var ai := int(v)
			if ai < 0 or ai >= arr.size():
				_add(path, key, "%s ans 下标越界：%d（共 %d 项）" % [where, ai, arr.size()])
			if seen_a.has(ai):
				_add(path, key, "%s ans 下标重复：%d" % [where, ai])
			seen_a[ai] = true
	else:
		var ai2 := int(ans)
		if ai2 < 0 or ai2 >= arr.size():
			_add(path, key, "%s ans 下标越界：%d（共 %d 项）" % [where, ai2, arr.size()])

	# B5：干扰项黑名单（只查错误项，正确项里出现同词是正常表述）
	var correct := {}
	if ans is Array:
		for v in (ans as Array):
			correct[int(v)] = true
	elif ans != null:
		correct[int(ans)] = true
	for oi in arr.size():
		if correct.has(oi):
			continue
		var ot := str(arr[oi])
		for bad in BAD_DISTRACTOR:
			if ot.find(bad) >= 0:
				_bad_distractor += 1
				_add(path, key, "%s 干扰项黑名单「%s」：%s" % [where, bad, ot.substr(0, 30)])

	_check_inline(path, key, where + ".q", q)
	_check_inline(path, key, where + ".ask", str(st.get("ask", "")))
	_check_inline(path, key, where + ".hint", str(st.get("hint", "")))
	_check_inline(path, key, where + ".explain", str(st.get("explain", "")))
	_check_inline(path, key, where + ".success", str(st.get("success", "")))
	_check_inline(path, key, where + ".goal", str(st.get("goal", "")))
	_check_inline(path, key, where + ".tip", str(st.get("tip", "")))
	_check_option_refs(path, key, where, st)
	_check_hint_leak(path, key, where, st)
	_check_label(path, key, group_no, where, st)
	_check_anim(path, st)

## B8：解析/提示里**按位置指代选项**是隐性错误——`StageBase` 按**显示位置**标 A/B/C/D，
## 而选项默认会被打乱（`StageRules.order_for`），所以「选项2 混淆了 ∈ 与 ⊆」这类写法
## 一旦乱序就指向另一个选项，比写错更糟的是它看起来还很确定。
##
## 硬规则只收语义无歧义的「选项+下标/字母」；「第 N 项 / 最后一项 / 依次是」只进看板——
## 数学文本里它们常指数列的项、裂项求和项，硬报会大量误伤。
func _check_option_refs(path: String, key: String, where: String, st: Dictionary) -> void:
	if st.get("opts", null) == null:
		return
	for f in ["hint", "explain", "success", "tip"]:
		var t := str(st.get(f, ""))
		if t == "":
			continue
		for m in _posref_re.search_all(t):
			_add(path, key, "%s.%s 按位置指代选项「%s」（选项会被打乱，请改成直接引用选项内容）"
				% [where, f, m.get_string()])
		for _m in _orderref_re.search_all(t):
			_order_ref_hits += 1

## B12：hint 是**直接显示**的（选项会打乱，提示不会），所以提示里出现正确项原文
## 就等于把答案抄给学生。硬规则只抓「字面包含」（≥3 字，`ContentRules`）；
## 「换个说法复述」判不了代数等价，只进看板，靠 `tools/sample_hints.gd` 抽检。
func _check_hint_leak(path: String, key: String, where: String, st: Dictionary) -> void:
	var hint := str(st.get("hint", ""))
	if hint.strip_edges() == "":
		return
	var ans: Variant = st.get("ans", null)
	if ans == null:
		return
	var opts: Variant = st.get("opts", null)
	if typeof(opts) == TYPE_ARRAY and (opts as Array).size() >= 2:
		var arr: Array = opts
		if ans is Array:
			# 多选：泄露「其中一个」不等于泄露答案，只进看板
			for v in (ans as Array):
				var t := str(arr[int(v)])
				if ContentRules.hint_leaks(hint, t) \
						or ContentRules.repeat_ratio(hint, t) >= ContentRules.SOFT_RATIO:
					_hint_soft += 1
			return
		var correct := str(arr[int(ans)])
		if ContentRules.repeat_ratio(hint, correct) >= ContentRules.SOFT_RATIO:
			_hint_soft += 1
		if ContentRules.hint_leaks(hint, correct):
			_add(path, key, "%s hint 含正确项原文「%s」（B12：提示只给方法，不给结论）"
				% [where, correct.substr(0, 24)])
		return
	# 填空/输入轮：ans 是数值，hint 里直接写出这个数同样是泄露
	if typeof(ans) == TYPE_FLOAT or typeof(ans) == TYPE_INT:
		var nt := ContentRules.num_text(ans)
		if ContentRules.hint_leaks_num(hint, nt):
			_add(path, key, "%s hint 含答案数值「%s」（B12：提示只给方法，不给结论）" % [where, nt])

## B9：轮次标签编号必须等于该关卡在本文件中的序号（如第 3 关的轮次应形如 "3-x"）。
func _check_label(path: String, key: String, group_no: int, where: String, st: Dictionary) -> void:
	var nm := str(st.get("name", ""))
	if nm == "":
		return
	var m := _label_re.search(nm)
	if m == null:
		# 无编号前缀（如「实验一」「实验探究 · 描点连线」）同样视为错位（见 B9）。
		_num_mismatch += 1
		_num_mismatch_files[path] = true
		_add(path, key, "%s 标签无编号前缀（应形如 %d-x）：%s" % [where, group_no, nm])
		return
	var n := int(m.get_string(1))
	if n != group_no:
		_num_mismatch += 1
		_num_mismatch_files[path] = true
		_add(path, key, "%s 标签编号 %d- 与关卡序号 %d 不符：%s" % [where, n, group_no, nm])

func _check_anim(path: String, st: Dictionary) -> void:
	if st.has("anim"):
		_anim_files[path] = true
		return
	var sc = st.get("scene", null)
	if typeof(sc) == TYPE_DICTIONARY and (sc as Dictionary).has("anim"):
		_anim_files[path] = true

# ---------------------------------------------------------------- 跨文件重名

func _check_cross_file_dups() -> void:
	for k in _key_owner.keys():
		var owners: Array = _key_owner[k]
		if owners.size() > 1:
			_add("res://data/*_levels.json", str(k), "关卡数据 key 跨文件重复：%s" % ", ".join(owners))

# ---------------------------------------------------------------- 命名/映射自检（A17）

## A17：数据文件命名易混（conic/conics、vector/vectors、solid/solid_basic），改错文件会**静默失效**。
## 四件事：
##   ① 章节 lab → data/<lab>_levels.json 必须存在（LabStage/Lab3DStage 载入口径，缺了 = 静默空章）；
##   ② 代码里的显式 res://data/*.json 路径同样登记为「已引用」；
##   ③ 每个 *_levels.json 必须被 curriculum 的 lab 或代码显式路径引用，否则记孤儿；
##   ④ 单复数近名文件对若恰好只有一半被引用 → 记错（另一半疑似「改错文件名」的受害者）。
func _check_naming() -> void:
	var referenced := {}
	# ① curriculum：lab → <lab>_levels.json
	var raw := FileAccess.get_file_as_string("res://data/curriculum.json")
	var data = JSON.parse_string(raw)
	if typeof(data) == TYPE_DICTIONARY:
		for ch in (data as Dictionary).get("chapters", []):
			if typeof(ch) != TYPE_DICTIONARY:
				continue
			for lv in (ch as Dictionary).get("levels", []):
				if typeof(lv) != TYPE_DICTIONARY:
					continue
				var lvd: Dictionary = lv
				var lab := str(lvd.get("lab", ""))
				if lab == "":
					continue
				var f := "%s_levels.json" % lab
				referenced[f] = "curriculum:" + str(lvd.get("id", "?"))
				if not FileAccess.file_exists(DATA_DIR + "/" + f):
					_add("res://data/curriculum.json", str(lvd.get("id", "?")),
						"章节 lab=%s 指向的 %s 不存在（LabStage 静默空章）" % [lab, f])
	# ② 代码里的显式路径（scripts/tests/tools 的 *.gd）
	var re := RegEx.new()
	re.compile("res://data/([A-Za-z0-9_]+\\.json)")
	for sub in ["scripts", "tests", "tools"]:
		_scan_dir_refs(DirAccess.open("res://" + sub), "res://" + sub, re, referenced)
	# ③④ 近名对与孤儿
	var present: Array[String] = []
	var bases := {}
	var dd := DirAccess.open(DATA_DIR)
	if dd != null:
		for f in dd.get_files():
			if f.ends_with("_levels.json"):
				present.append(f)
				bases[f.substr(0, f.length() - "_levels.json".length())] = f
	if not referenced.is_empty():
		for f in present:
			if not referenced.has(f):
				_add(DATA_DIR + "/" + f, "*",
					"孤儿数据文件：无任何章节 lab/代码路径引用（疑似改错文件名或遗留）")
	var pair_seen := {}
	for f in present:
		var b := f.substr(0, f.length() - "_levels.json".length())
		if not b.ends_with("s"):
			continue
		var sg := b.substr(0, b.length() - 1)
		if not bases.has(sg):
			continue
		var pk := sg + "|" + b
		if pair_seen.has(pk):
			continue
		pair_seen[pk] = true
		var ref_sg: bool = referenced.has(sg + "_levels.json")
		var ref_pl: bool = referenced.has(b + "_levels.json")
		if ref_sg != ref_pl:
			# 只有一半在用：改错文件名的典型事故（如把 conics 章误写进 conic_levels.json）
			var used := (sg if ref_sg else b) + "_levels.json"
			var dead := (b if ref_sg else sg) + "_levels.json"
			_add(DATA_DIR + "/" + dead, "*",
				"近名文件对 %s/%s 只有 %s 被引用，%s 疑似改错文件名的受害者" % [sg, b, used, dead])
		else:
			_naming_pairs.append("%s/%s(%s)" % [sg, b, "均在用" if ref_sg else "均未引用"])

## 递归扫 *.gd 里的 res://data/*.json 显式路径，登记为「已引用」。
func _scan_dir_refs(d: DirAccess, base: String, re: RegEx, referenced: Dictionary) -> void:
	if d == null:
		return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		var p := base + "/" + f
		if d.current_is_dir():
			if f != "." and f != "..":
				_scan_dir_refs(DirAccess.open(p), p, re, referenced)
		elif f.ends_with(".gd"):
			for m in re.search_all(FileAccess.get_file_as_string(p)):
				referenced[m.get_string(1)] = p
		f = d.get_next()
	d.list_dir_end()

# ---------------------------------------------------------------- A10 命名公式自检

## A10：数据里引用的 {f:名称} 必须在 InlineMath.FORMULA_LATEX 声明——
## 否则运行时静默回退成「公式」两个字（题目直接不可答）。
## 另把「已声明但全库无人引用」的孤儿名字记进看板（存量迁移完成后应为空）。
func _check_named_formulas() -> void:
	var re := RegEx.new()
	re.compile("\\{f:([A-Za-z0-9_]+)\\}")
	var referenced := {}
	var dd := DirAccess.open(DATA_DIR)
	if dd == null:
		return
	for f in dd.get_files():
		if not f.ends_with(".json"):
			continue
		for m in re.search_all(FileAccess.get_file_as_string(DATA_DIR + "/" + f)):
			referenced[m.get_string(1)] = f
	for name in referenced:
		if not InlineMath.FORMULA_LATEX.has(name):
			_add(DATA_DIR + "/" + str(referenced[name]), str(name),
				"引用了未声明的命名公式 {f:%s}（运行时静默变「公式」，题目不可答；" % name +
				"A10 起新内容请直接写 $$LaTeX$$）")
	for name in InlineMath.FORMULA_LATEX:
		if not referenced.has(name):
			_named_orphans.append(str(name))

# ---------------------------------------------------------------- 公式覆盖

func _check_inline(path: String, key: String, field: String, t: String) -> void:
	if t.strip_edges() == "":
		return
	_speech_scan(t)   # B13:在 $$ 段被剥掉前统计口播覆盖
	if _dollar != null and t.find("$$") >= 0:
		t = _dollar.sub(t, " ", true)
	_inline_checked += 1
	var last := 0
	for m in _cjk.search_all(t):
		_inline_piece(path, key, field, t.substr(last, m.get_start() - last))
		last = m.get_end()
	_inline_piece(path, key, field, t.substr(last))

## B13：口播覆盖统计——每个文本字段扫 $$LaTeX$$ 段与 {f:} 标记,记录段数与
## 「盲点」(SpeechRules 不认识的 LaTeX 命令 / 未定义的命名公式)。
func _speech_scan(t: String) -> void:
	if _re_dollar_b == null:
		_re_dollar_b = RegEx.new()
		_re_dollar_b.compile("\\$\\$([^$]+)\\$\\$")
	if _re_named_b == null:
		_re_named_b = RegEx.new()
		_re_named_b.compile("\\{f:([A-Za-z0-9_]+)\\}")
	var segs := 0
	var dollars := _re_dollar_b.search_all(t)
	var named := _re_named_b.search_all(t)
	segs += dollars.size() + named.size()
	for m in dollars:
		for c in SpeechRules.unmapped_commands(m.get_string(1)):
			_speech_blind[c] = int(_speech_blind.get(c, 0)) + 1
	for m in named:
		var nm := m.get_string(1)
		if not InlineMath.FORMULA_SPEECH.has(nm) and not InlineMath.FORMULA_LATEX.has(nm):
			_speech_blind["{f:" + nm + "}"] = int(_speech_blind.get("{f:" + nm + "}", 0)) + 1
	if segs > 0:
		_n_speech_field += 1
	_n_speech_seg += segs

func _inline_piece(path: String, key: String, field: String, gap: String) -> void:
	if gap.strip_edges() == "":
		return
	var core := InlineMath._inline_trim(gap)
	if core == "":
		return
	if InlineMath._inline_math.has(core):
		return
	if not _has_math_char(core):
		return
	_inline_missing[core] = int(_inline_missing.get(core, 0)) + 1

func _has_math_char(s: String) -> bool:
	for i in s.length():
		var c := s[i]
		if c == "·":
			var prev_ws := i == 0 or s[i - 1] == " "
			var next_ws := i == s.length() - 1 or s[i + 1] == " "
			if prev_ws or next_ws:
				continue
		if MATH_CHARS.find(c) >= 0:
			return true
	return false

# ---------------------------------------------------------------- 问题收集 / 基线

func _add(file: String, key: String, detail: String) -> void:
	# detail 统一 strip：基线的逐行读取也做 strip，否则尾随空格会造成「永远不匹配」。
	_issues.append("%s|%s|%s" % [file, key, detail.strip_edges()])

func _load_baseline() -> void:
	if not FileAccess.file_exists(BASELINE_PATH):
		return
	for line in FileAccess.get_file_as_string(BASELINE_PATH).split("\n"):
		var t := line.strip_edges()
		if t == "" or t.begins_with("#"):
			continue
		_known[t] = true

func _write_baseline() -> void:
	var uniq := {}
	for i in _issues:
		uniq[i] = true
	var keys: Array = uniq.keys()
	keys.sort()
	var f := FileAccess.open(BASELINE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("无法写入 " + BASELINE_PATH)
		return
	f.store_string("# 内容校验基线（TODO A5）：每行一条已知问题签名，修完请删行。\n")
	f.store_string("# 生成：godot --headless --path . --script res://tools/check_questions.gd -- --write-baseline\n")
	for k in keys:
		f.store_string(str(k) + "\n")
	f.close()
	print("已写入基线 %d 条 -> %s" % [keys.size(), BASELINE_PATH])

# ---------------------------------------------------------------- 章节看板（E2）

## 每章「关卡数 / 题数」看板：由 curriculum.json 反查「数据 key → 教材章节」，
## 输出按题量升序的章节清单，并对薄弱章节(<18 题)告警（见 E2 验收）。
func _chapter_board() -> void:
	var raw := FileAccess.get_file_as_string("res://data/curriculum.json")
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		print("[看板] 章节题量: curriculum.json 解析失败")
		return
	var solid := _solid_method_counts()
	var rows: Array = []
	var on_board := {}
	for ch in (data as Dictionary).get("chapters", []):
		if typeof(ch) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = ch
		var lvs: Array = c.get("levels", [])
		var q := 0
		for lv in lvs:
			if typeof(lv) != TYPE_DICTIONARY:
				continue
			var lvd: Dictionary = lv
			var key := _data_key_of(lvd)
			if key == "":
				continue
			if solid.has(key):
				on_board[key] = true
				q += int(solid[key])
			elif _group_q.has(key):
				on_board[key] = true
				q += int(_group_q[key])
		rows.append({"t": str(c.get("title", c.get("id", "?"))), "lv": lvs.size(), "q": q})
	rows.sort_custom(func(a, b): return int(a["q"]) < int(b["q"]))
	print("[看板] 章节题量（章 · 关/题，按题量升序，共 %d 章）:" % rows.size())
	var line := ""
	for r in rows:
		line += "%s %d/%d   " % [r["t"], int(r["lv"]), int(r["q"])]
		if line.length() > 64:
			print("        " + line.strip_edges())
			line = ""
	if line.strip_edges() != "":
		print("        " + line.strip_edges())
	var thin: Array[String] = []
	for r in rows:
		if int(r["q"]) < 18:
			thin.append("%s(%d 关/%d 题)" % [r["t"], int(r["lv"]), int(r["q"])])
	if not thin.is_empty():
		print("WARN: 薄弱章节 %d 个（<18 题，见 E2）：%s" % [thin.size(), "，".join(thin)])
	var orphan: Array[String] = []
	for k in _group_q.keys():
		if not on_board.has(k):
			orphan.append("%s(%d)" % [str(k), int(_group_q[k])])
	for k in solid.keys():
		if not on_board.has(k):
			orphan.append("%s(%d)" % [str(k), int(solid[k])])
	if not orphan.is_empty():
		orphan.sort()
		print("[看板] 未被教材章节引用的数据 key %d 个: %s" % [orphan.size(), ", ".join(orphan)])

## 关卡 → 数据 key 的解析必须与实际载入器一致（否则章节题量会串号）：
##   LabStage/Lab3DStage 用 lab_ref；SequenceStage 用 sequence；ConicStage 用 conic；
##   SolidChallenge 用 method（题目在 solid_methods.json，非 *_levels.json）。
func _data_key_of(lv: Dictionary) -> String:
	var sc := str(lv.get("scene", ""))
	if sc.ends_with("SequenceStage.tscn"):
		return str(lv.get("sequence", ""))
	if sc.ends_with("SolidChallenge.tscn"):
		return str(lv.get("method", ""))
	if sc.ends_with("ConicStage.tscn"):
		return str(lv.get("conic", ""))
	if lv.has("lab_ref"):
		return str(lv["lab_ref"])
	return str(lv.get("id", ""))

## solid_methods.json 是嵌套结构({"methods":{id:{levels:[...]}}})，不在 *_levels.json 口径内，
## 但立体几何「方法章」的 6 关题目在里面，补进来才能让章节题量看板准确。
func _solid_method_counts() -> Dictionary:
	var out := {}
	var raw := FileAccess.get_file_as_string("res://data/solid_methods.json")
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		return out
	var methods = (data as Dictionary).get("methods", {})
	if typeof(methods) != TYPE_DICTIONARY:
		return out
	for mid in (methods as Dictionary).keys():
		var m = methods[mid]
		if typeof(m) != TYPE_DICTIONARY:
			continue
		var lvs = (m as Dictionary).get("levels", [])
		if typeof(lvs) != TYPE_ARRAY:
			continue
		var n := 0
		for s in (lvs as Array):
			if typeof(s) == TYPE_DICTIONARY and (s as Dictionary).has("opts"):
				n += 1
		out[str(mid)] = n
	return out

# ---------------------------------------------------------------- 报告

func _report() -> void:
	var write_baseline := OS.get_cmdline_user_args().has("--write-baseline")
	if write_baseline:
		_write_baseline()
		quit(0)
		return

	var new_issues: Array[String] = []
	var known_hits := 0
	# B8：正确项位置分布是全库指标，不挂在某一关上，所以在这里补一条硬性检查。
	# 存量已从 90.8% 修到 ~25%；此后新增内容若又把正确项堆在第 1 位，直接红灯（不可进基线）。
	var a0 := int(_ans_hist.get(0, 0))
	if _n_choice > 0 and float(a0) / float(_n_choice) > 0.35:
		_issues.append("__global__||ans==0 占 %d/%d（%.1f%%，>35%%）：见 B8，用 tools/shuffle_options.py 重排"
			% [a0, _n_choice, 100.0 * float(a0) / float(_n_choice)])
	for i in _issues:
		if _known.has(i):
			known_hits += 1
		else:
			new_issues.append(i)

	var warns: Array[String] = []
	if _dup_stem > 0:
		warns.append("题干重复 %d 处（warn）" % _dup_stem)
	if _inline_missing.size() > 0:
		warns.append("inline 公式未覆盖片段 %d 个（见 B7/A10；另见 tools/check_inline.gd）" % _inline_missing.size())

	print("QUESTION-CHECK: %d files / %d levels / %d questions / %d new / %d known / %d warnings"
		% [_n_files, _n_levels, _n_questions, new_issues.size(), known_hits, warns.size()])
	print("[看板] 题型: 单选=%d 多选=%d interact=%d 填空=%d" % [_n_choice, _n_multi, _n_interact, _n_input])
	var n_total := _n_choice + _n_multi + _n_interact + _n_input
	if n_total > 0:
		print("[看板] 非四选一占比: %.1f%%（B1 目标 ≤30%%，即四选一 ≤70%%）"
			% [100.0 * float(n_total - _n_choice) / float(n_total)])
	if _n_explore > 0:
		print("[看板] 探究轮题面陈述句(无「？」): %d/%d（%.1f%%，B3 目标 <20%%）"
			% [_n_explore_stmt, _n_explore, 100.0 * float(_n_explore_stmt) / float(_n_explore)])
	print("[看板] 选项: 图片 %d 处（%d 题）" % [_img_opt_count, _img_opt_questions])
	print("[看板] ans 原始分布: 0=%d(%.1f%%) 1=%d 2=%d 3=%d"
		% [a0, (100.0 * float(a0) / float(maxi(1, _n_choice))),
			int(_ans_hist.get(1, 0)), int(_ans_hist.get(2, 0)), int(_ans_hist.get(3, 0))])
	print("[看板] anim 演示覆盖: %d/%d 文件" % [_anim_files.size(), _n_files])
	print("[看板] 轮次编号错位: %d 处（%d 文件，见 B9）" % [_num_mismatch, _num_mismatch_files.size()])
	print("[看板] 干扰项黑名单命中: %d 处（B5 目标 0；范畴错误型干扰项须换成错误路径型）" % _bad_distractor)
	print("[看板] 解析按顺序指代选项（模糊类，需人读）: %d 处（B8；硬规则只兜「选项N」）" % _order_ref_hits)
	print("[看板] hint 换说法复述正确项（模糊类，需人读）: %d 题（B12；硬规则只兜「含原文」）" % _hint_soft)
	if not _naming_pairs.is_empty():
		print("[看板] A17 近名文件对: %s（编辑时勿改错）" % "，".join(_naming_pairs))
	var blind := ""
	if not _speech_blind.is_empty():
		var keys := _speech_blind.keys()
		keys.sort()
		blind = "；盲点: " + str(keys)
	print("[看板] B13 口播: 公式段 %d 处（分布 %d 个文本字段）;盲点命令/公式 %d 种%s"
		% [_n_speech_seg, _n_speech_field, _speech_blind.size(), blind])
	print("[看板] A10 命名公式: 已声明 %d 个，孤儿（全库无人引用）%d 个%s"
		% [InlineMath.FORMULA_LATEX.size(), _named_orphans.size(),
			"" if _named_orphans.is_empty() else "：" + "，".join(_named_orphans)])
	_chapter_board()
	if _inline_missing.size() > 0:
		var tops: Array = _inline_missing.keys()
		tops.sort_custom(func(a, b): return int(_inline_missing[a]) > int(_inline_missing[b]))
		var show: Array[String] = []
		for i in mini(10, tops.size()):
			show.append("<%s>x%d" % [str(tops[i]), int(_inline_missing[tops[i]])])
		print("[看板] inline 未覆盖 Top10: " + ", ".join(show))

	for w in warns:
		print("WARN: " + str(w))

	if new_issues.is_empty():
		print("OK: 无新增问题（已知问题 %d 条在基线内）" % known_hits)
		quit(0)
		return

	print("")
	print("新增问题 %d 条（前 40 条）：" % new_issues.size())
	for i in mini(40, new_issues.size()):
		print("  " + str(new_issues[i]))
	if new_issues.size() > 40:
		print("  ...还有 %d 条" % (new_issues.size() - 40))
	print("提示：确认这些是历史遗留而非新引入时，可用 --write-baseline 记入基线。")
	quit(1)
