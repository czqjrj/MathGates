extends SceneTree
## B12 验收工具：按「提示与正确项的重合度」从高到低列出 hint，供人读判定。
##
## 用法：
##   godot --headless --path . --script res://tools/sample_hints.gd          # 默认 30 条
##   godot --headless --path . --script res://tools/sample_hints.gd -- 60    # 看 60 条
##
## 口径：
##   - **硬泄露**（`ContentRules.hint_leaks`）：hint 里出现正确项原文（≥3 字）——
##     `check_questions.gd` 已当红灯，这里只做汇总。
##   - **软重合**（`ContentRules.repeat_ratio`）：正确项有 ≥70% 的字符被 hint 里某个
##     连续片段复述。静态判不了代数等价（`y−1=2(x−1)` vs `y=2x−1`），所以靠人读。
##
## 为什么取「最靠前的 N 条」而不是均匀抽样：验收要证明的是「全库重合度低于阈值」，
## 那么只要**最高的一批**都通过了，全体就都通过了——比随机抽 30 条更有说服力。

func _initialize() -> void:
	var n := 30
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and str(args[0]).is_valid_int():
		n = maxi(1, int(args[0]))

	var dir := DirAccess.open("res://data")
	if dir == null:
		print("SAMPLE-HINTS: cannot open res://data")
		quit(1)
		return
	var names: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_levels.json"):
			names.append(fname)
		fname = dir.get_next()
	names.sort()

	var rows: Array = []
	var n_hint := 0
	var n_hard := 0
	var n_soft := 0
	for f in names:
		var data = JSON.parse_string(FileAccess.open("res://data/" + f, FileAccess.READ).get_as_text())
		if typeof(data) != TYPE_DICTIONARY:
			continue
		for k in (data as Dictionary):
			var g: Variant = (data as Dictionary)[k]
			if typeof(g) != TYPE_DICTIONARY or not (g as Dictionary).has("levels"):
				continue
			var i := 0
			for st in (g as Dictionary)["levels"]:
				i += 1
				if typeof(st) != TYPE_DICTIONARY:
					continue
				var s: Dictionary = st
				var hint := str(s.get("hint", ""))
				if hint.strip_edges() == "" or not s.has("ans"):
					continue
				n_hint += 1
				var correct := _correct_text(s)
				if correct == "":
					continue
				var hard := ContentRules.hint_leaks_num(hint, correct) \
					if not s.has("opts") else ContentRules.hint_leaks(hint, correct)
				var ratio := ContentRules.repeat_ratio(hint, correct)
				if hard:
					n_hard += 1
				if ratio >= ContentRules.SOFT_RATIO:
					n_soft += 1
				rows.append({
					"f": f, "k": k, "i": i,
					"q": str(s.get("ask", s.get("q", ""))),
					"hint": hint,
					"ans": correct,
					"hard": hard, "ratio": ratio,
				})

	rows.sort_custom(func(a, b): return float(a["ratio"]) > float(b["ratio"]))
	print("SAMPLE-HINTS: %d rounds with hint / hard=%d / soft>=%.1f=%d"
		% [n_hint, n_hard, ContentRules.SOFT_RATIO, n_soft])
	var picked := mini(n, rows.size())
	for j in picked:
		var r: Dictionary = rows[j]
		print("##### #%d [%s | %s | 第%d轮] 重合=%.2f%s #####"
			% [j + 1, r["f"], r["k"], r["i"], float(r["ratio"]),
				"  【硬泄露】" if bool(r["hard"]) else ""])
		print("q   : %s" % str(r["q"]).substr(0, 100))
		print("hint: %s" % str(r["hint"]).substr(0, 120))
		print("ans : %s" % str(r["ans"]).substr(0, 100))
		print("")
	quit(0)

## 正确项文本：多选取最长的一项（泄露任一都值得看），填空取数值字面。
func _correct_text(s: Dictionary) -> String:
	var ans: Variant = s.get("ans")
	var opts: Variant = s.get("opts", null)
	if typeof(opts) == TYPE_ARRAY and (opts as Array).size() >= 2:
		var arr: Array = opts
		if ans is Array:
			var best := ""
			for v in (ans as Array):
				var t := str(arr[int(v)])
				if t.length() > best.length():
					best = t
			return best
		return str(arr[int(ans)])
	if typeof(ans) == TYPE_FLOAT or typeof(ans) == TYPE_INT:
		return ContentRules.num_text(ans)
	return ""
