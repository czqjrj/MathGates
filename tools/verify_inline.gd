extends SceneTree
## 全表抽查：遍历 inline_math.json，确认每个带 latex 的条目都能经 MicroTeX 渲染出 bbcode。

func _initialize() -> void:
	var ok := InlineMath._mt_ready()
	print("MT_READY=", ok)
	InlineMath.inline("x", 26) # 触发加载
	var map: Dictionary = InlineMath._inline_math
	print("ENTRIES=", map.size())
	var total := 0
	var fail := 0
	var no_latex := 0
	var shown := 0
	for k in map.keys():
		var info: Dictionary = map[k]
		var latex := str(info.get("latex", ""))
		if latex == "":
			no_latex += 1
			continue
		total += 1
		var bb := InlineMath._formula_bbcode(info, 26)
		if bb == "":
			fail += 1
			if shown < 40:
				print("  RENDER-FAIL <", k, ">  latex=", latex)
				shown += 1
	print("VERIFY_TABLE: total=", total, " fail=", fail, " no_latex=", no_latex)
	quit(0 if fail == 0 else 1)
