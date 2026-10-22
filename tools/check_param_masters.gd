extends SceneTree
## B1「参数母版」脚手架 → 引擎方言兼容性闸门（TODO B1 接入前置）。
##
## 用法：godot --headless --path . --script res://tools/check_param_masters.gd
##       godot --headless --path . --script res://tools/check_param_masters.gd -- --write-baseline
## 输出：PARAM-CHECK: <files> files / <levels> levels / <scenes> scenes / <new> new / <known> known / <warn> warnings
##       有新增问题时打印 PARAM-CHECK-FAIL 并以非零码退出。
##
## 为什么需要它：`data/param_master_*.json` / `data/*_param_auto.json` 这批内容**不以
## `_levels.json` 结尾**，所以 `check_questions` / `check_content_health` 的扫描口径都不覆盖它们
## ——写错引擎不认识的字段时不会有任何红灯，接进关卡后是**静默坏给学生看**：
##   · `scene.range` 写成数组 → `LabPlane.set_scene()` 里 `float(Array)` 直接报运行时错误，视野停在旧值；
##   · `curves[].fn` 写了引擎没有的类型 → `_f_y()` 的 match 落回默认分支，**曲线全画成正弦波**；
##   · `readouts[].expr` 写比较式（`abs(a-1)<0.15`）→ 表达式解析器只支持算术，**读数恒等于兜底值**；
##   · `gate:true` 但 `answers` 的键对不上滑块名 → `is_sliders_correct()` 恒 false，**学生永远提交不过**。
## 上面四条都由本工具穷举，且都在 Godot 4.7.2 上实测复现过。
##
## 口径：hard（E_*）= 接进关卡一定会坏；warn（W_*）= 语义丢失/文案口径问题，不挡闸门。

const DATA_DIR := "res://data"
const BASELINE_PATH := "res://tools/param_master_baseline.txt"

## 脚手架文件的识别方式（与 check_questions 的 `*_levels.json` 口径互补，不重叠）。
const GROUP_PREFIX := "param_master"
const SUFFIXES := ["_param_auto.json", "_param_master.json", "_levels_param.json"]

## LabPlane._f_y() 的 match 分支——曲线类型的唯一真源。
const CURVE_FN := ["sin", "cos", "tan", "exp", "log", "ln", "pow", "sqrt", "recip", "quad",
	"linear", "linrecip", "abs", "const", "hyp", "hypv", "parr", "parl", "paru"]
## LabPlane._ex_func() 支持的表达式函数——超出的一律返回 0.0。
const EXPR_FN := ["sqrt", "abs", "sin", "cos", "tan"]
## LabPlane._draw_curve() 真正读取的曲线键；其它键被静默忽略（写了等于没写）。
const CURVE_KEYS := ["fn", "a", "b", "c", "d", "mirror", "color", "width", "from", "to", "dash", "label"]

var _files := 0
var _levels := 0
var _scenes := 0
var _issues: Array = []
var _warns: Array = []
var _known := {}

func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--write-baseline"):
		_scan()
		_write_baseline()
		quit(0)
		return
	_load_baseline()
	_scan()
	var new_issues: Array = []
	var known_hits := 0
	for i in _issues:
		if _known.has(i):
			known_hits += 1
		else:
			new_issues.append(i)
	for s in new_issues:
		print("  [FAIL] ", s)
	for w in _warns:
		print("  [warn] ", w)
	print("PARAM-CHECK: %d files / %d levels / %d scenes / %d new / %d known / %d warnings"
		% [_files, _levels, _scenes, new_issues.size(), known_hits, _warns.size()])
	if new_issues.is_empty():
		print("OK: 无新增方言不兼容问题（已知 %d 条在基线内）" % known_hits)
		quit(0)
	else:
		print("PARAM-CHECK-FAIL: %d 条新增问题——接进关卡前必须先改数据或扩引擎" % new_issues.size())
		quit(1)

# ---------------------------------------------------------------- 扫描
func _scan() -> void:
	_self_check()
	var d := DirAccess.open(DATA_DIR)
	if d == null:
		print("PARAM-CHECK-FAIL: 无法打开 " + DATA_DIR)
		quit(1)
		return
	var names: Array = []
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if not d.current_is_dir() and n.ends_with(".json") and _is_scaffold(n):
			names.append(n)
		n = d.get_next()
	d.list_dir_end()
	names.sort()
	for f in names:
		_files += 1
		_scan_file(DATA_DIR + "/" + f, f)

## 白名单自查：本文件的 CURVE_FN / EXPR_FN 是从 LabPlane 抄来的，抄漏就会把**能跑的**内容
## 判成不兼容（假阳性），抄多则放过**跑不了的**（假阴性）。这里直接回读 LabPlane 源码核对，
## 让闸门自己守住「口径与引擎一致」这条命门。
const LAB_PLANE := "res://scripts/modules/lab/LabPlane.gd"

func _self_check() -> void:
	if not FileAccess.file_exists(LAB_PLANE):
		_add("check_param_masters.gd", "*", "E_SELF|找不到 %s，白名单无从核对" % LAB_PLANE)
		return
	var src := FileAccess.get_file_as_string(LAB_PLANE)
	# 只看 match 分支的**标签行**（`\t\t"name":`），不匹配分支体里的 return——
	# `log` / `ln` / `sqrt` 的分支是多行写法，早先按「标签紧跟 return」扫会把它们漏掉，
	# 反过来把能跑的内容判成不兼容（假阳性）。
	var engine_fns := _match_labels(_slice(src, "func _f_y(", "func _draw_curve("))
	var ex_fns := _match_labels(_slice(src, "func _ex_func(", "func _ex_var("))
	if engine_fns.is_empty():
		_add("check_param_masters.gd", "CURVE_FN", "E_SELF|没从 _f_y() 里扫出任何分支，切片标记已失效")
	if ex_fns.is_empty():
		_add("check_param_masters.gd", "EXPR_FN", "E_SELF|没从 _ex_func() 里扫出任何分支，切片标记已失效")
	for fn in CURVE_FN:
		if not engine_fns.has(fn):
			_add("check_param_masters.gd", "CURVE_FN",
				"E_SELF_DRIFT|白名单里的 %s 在 LabPlane._f_y 已不存在 → 假阳性，须同步" % fn)
	for fn in EXPR_FN:
		if not ex_fns.has(fn):
			_add("check_param_masters.gd", "EXPR_FN",
				"E_SELF_DRIFT|白名单里的 %s 在 LabPlane._ex_func 已不存在" % fn)
	for fn in engine_fns:
		if not fn in CURVE_FN:
			_add("check_param_masters.gd", "CURVE_FN",
				"E_SELF_DRIFT|LabPlane._f_y 有 %s 但白名单没有 → 假阴性，须补进白名单" % fn)
	print("SELF-CHECK: LabPlane._f_y 实有 %d 个曲线类型 / _ex_func 实有 %d 个表达式函数；白名单 %d / %d"
		% [engine_fns.size(), ex_fns.size(), CURVE_FN.size(), EXPR_FN.size()])

## 收集 match 分支标签：形如 `\t\t"sin":` 的行，返回 {名字: true}。
func _match_labels(body: String) -> Dictionary:
	var out := {}
	var re := RegEx.create_from_string("^\\t+\"([a-z]+)\":")
	for line in body.split("\n"):
		var m := re.search(line)
		if m != null:
			out[m.get_string(1)] = true
	return out

## 取 src 中 [起始标记, 结束标记) 之间的片段（结束标记缺失时取到文件尾）。
func _slice(src: String, a: String, b: String) -> String:
	var i := src.find(a)
	if i < 0:
		return ""
	var j := src.find(b, i + a.length())
	return src.substr(i, j - i) if j > i else src.substr(i)

func _is_scaffold(f: String) -> bool:
	if f.begins_with(GROUP_PREFIX) and f.ends_with(".json"):
		return true
	for s in SUFFIXES:
		if f.ends_with(s):
			return true
	return false

func _scan_file(path: String, fname: String) -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(raw) != TYPE_DICTIONARY:
		_add(fname, "*", "E_BAD_JSON|文件不是对象")
		return
	for gk in raw:
		var g: Dictionary = raw[gk]
		if typeof(g) != TYPE_DICTIONARY or not g.has("levels"):
			continue
		var li := 0
		for lv in g["levels"]:
			li += 1
			if typeof(lv) != TYPE_DICTIONARY:
				continue
			_levels += 1
			_check_level(fname, "%s#%d" % [str(gk), li], lv)

func _check_level(fname: String, where: String, lv: Dictionary) -> void:
	var sc: Dictionary = lv.get("scene", {})
	var names := _slider_names(sc)
	if not sc.is_empty():
		_scenes += 1
	# ① 取域：LabPlane 只认 `x`/`y` 数组，或标量 `range`
	if sc.has("range") and sc["range"] is Array:
		_add(fname, where, "E_RANGE_ARRAY|scene.range 是数组 %s → float(Array) 运行时报错，须改写为 x/y 或标量 range" % str(sc["range"]))
	if not sc.has("x") and not sc.has("y") and not sc.has("range"):
		_add(fname, where, "E_RANGE_MISSING|scene 无 x/y/range，视野用引擎默认值")
	# ② 曲线类型
	for cu in sc.get("curves", []):
		if typeof(cu) != TYPE_DICTIONARY:
			continue
		var fn := str(cu.get("fn", ""))
		if fn != "" and not fn in CURVE_FN:
			_add(fname, where, "E_CURVE_FN|fn=\"%s\" 引擎不认识 → _f_y() 落回默认分支画成正弦波" % fn)
		for ck in cu:
			if not str(ck) in CURVE_KEYS:
				_warn(fname, where, "W_CURVE_KEY|曲线键 \"%s\" 引擎不读（写了等于没写，语义丢失）" % str(ck))
	# ③ 读数表达式：解析器只支持 + - * / ^ 括号与 5 个函数，**不支持比较运算**
	for rd in sc.get("readouts", []):
		if typeof(rd) != TYPE_DICTIONARY:
			continue
		var e := str(rd.get("expr", ""))
		if "<" in e or ">" in e or "==" in e or "!=" in e:
			_add(fname, where, "E_READOUT_CMP|expr=\"%s\" 含比较运算 → 解析器回退兜底值，读数恒为 0" % e)
		for fnm in _call_names(e):
			if not fnm in EXPR_FN:
				_add(fname, where, "E_READOUT_FUNC|expr=\"%s\" 用了函数 %s()，引擎只有 %s" % [e, fnm, str(EXPR_FN)])
	# ④ 门控：gate 与 answers/tol 的键必须落在滑块名上
	var gate := bool(lv.get("gate", sc.get("gate", false)))
	if gate:
		var ans: Dictionary = lv.get("answers", sc.get("answers", {}))
		if ans.is_empty():
			_add(fname, where, "E_GATE_NO_ANSWER|gate=true 但没有 answers → is_sliders_correct() 恒 false，永远提交不过")
		if names.is_empty():
			_add(fname, where, "E_GATE_NO_SLIDER|gate=true 但 scene.sliders 为空，无可判定参数")
		for ak in ans:
			if not str(ak) in names:
				_add(fname, where, "E_GATE_KEY|answers 键 \"%s\" 不在滑块名 %s 里 → 该判定永不生效" % [str(ak), str(names)])
		var tol: Dictionary = lv.get("tol", sc.get("tol", {}))
		for tk in tol:
			if not str(tk) in names:
				_add(fname, where, "E_GATE_KEY|tol 键 \"%s\" 不在滑块名 %s 里" % [str(tk), str(names)])
	# ⑤ 文案口径：全项目为简体
	var trad := _trad_count(lv)
	if trad > 0:
		_warn(fname, where, "W_TRAD|本关文案含繁体字 %d 处，接入前须转简" % trad)

func _slider_names(sc: Dictionary) -> Array:
	var out: Array = []
	for s in sc.get("sliders", []):
		if typeof(s) == TYPE_DICTIONARY:
			out.append(str(s.get("name", "")))
	return out

## 表达式里的 `名字(` 调用（用于核对 _ex_func 白名单）。
func _call_names(e: String) -> Array:
	var re := RegEx.create_from_string("[A-Za-z_][A-Za-z0-9_]*\\s*\\(")
	var out: Array = []
	for m in re.search_all(e):
		var nm := str(m.get_string()).replace("(", "").strip_edges()
		if not nm in out:
			out.append(nm)
	return out

## 繁体命中数。用常见繁体字表粗筛（闸门只报 warn，不追求字表完备）。
const TRAD := "數點動關參觀證選擇錯誤確認圖形圖像學習題語詞說讀順變現記錄條線圓錐曲應試驗舊遷減廣開閥閉問間閱風雲電龍龜歷曆歸屬廠戶極權歡戀愛應內製簡體術語義習慣"
func _trad_count(v: Variant) -> int:
	if v is String:
		var c := 0
		for ch in v:
			if TRAD.find(ch) >= 0:
				c += 1
		return c
	if v is Array:
		var t := 0
		for x in v:
			t += _trad_count(x)
		return t
	if v is Dictionary:
		var t2 := 0
		for k in v:
			t2 += _trad_count(v[k])
		return t2
	return 0

func _add(file: String, key: String, detail: String) -> void:
	_issues.append("%s|%s|%s" % [file, key, detail.strip_edges()])

func _warn(file: String, key: String, detail: String) -> void:
	_warns.append("%s|%s|%s" % [file, key, detail.strip_edges()])

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
		print("PARAM-CHECK-FAIL: 无法写入 " + BASELINE_PATH)
		quit(1)
		return
	f.store_string("# B1 参数母版脚手架 → 引擎方言兼容基线（TODO B1）：每行一条已知问题签名，修完请删行。\n")
	f.store_string("# 生成：godot --headless --path . --script res://tools/check_param_masters.gd -- --write-baseline\n")
	for k in keys:
		f.store_string(str(k) + "\n")
	print("已写入基线 %d 条 -> %s" % [keys.size(), BASELINE_PATH])
