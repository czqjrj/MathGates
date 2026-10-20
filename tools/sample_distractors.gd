extends SceneTree
## B5 验收① 工具：从全部关卡数据文件里**确定性**抽样 30 道四选一，打印题干/选项/答案/解析，
## 供逐题判定「每个干扰项是否至少对应一条真实错误路径」。
## 用法：godot --headless --path . --script res://tools/sample_distractors.gd -- [n]
## 抽样口径：文件名排序 → 组出现序 → 轮序展开成一维序列，取第 floor((j+0.5)*total/n) 题（j 从 0 起）。
## 说明：explore 轮的追问题干在 "ask" 字段（"q" 是探究指令），故优先取 ask。
## 排除 questions.json（遗留通用题库，去留见 TODO A2/A3/A12）。

func _initialize() -> void:
	var n := 30
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and str(args[0]).is_valid_int():
		n = maxi(1, int(args[0]))
	var dir := DirAccess.open("res://data")
	if dir == null:
		print("SAMPLE: cannot open res://data")
		quit(1)
		return
	var names: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_levels.json") and fname != "questions.json":
			names.append(fname)
		fname = dir.get_next()
	names.sort()
	var rows: Array = []
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
				var opts: Variant = s.get("opts", null)
				if typeof(opts) != TYPE_ARRAY or (opts as Array).size() < 2:
					continue
				if not s.has("ans") or s["ans"] is Array:
					continue
				rows.append({
					"f": f, "k": k, "i": i,
					"q": str(s.get("ask", s.get("q", ""))),
					"opts": opts,
					"ans": int(s["ans"]),
					"ex": str(s.get("explain", "")),
				})
	print("SAMPLE-DISTRACTORS: %d choice rounds / %d sampled" % [rows.size(), n])
	var total := rows.size()
	var picked := mini(n, total)
	for j in picked:
		var r: Dictionary = rows[int(floor((float(j) + 0.5) * float(total) / float(picked)))]
		print("##### 抽检#%d [%s | %s | 第%d轮] #####" % [j + 1, r["f"], r["k"], r["i"]])
		print("q: %s" % r["q"])
		print("opts: %s" % JSON.stringify(r["opts"]))
		print("ans: %d" % r["ans"])
		print("explain: %s" % r["ex"])
		print("")
	quit(0)
