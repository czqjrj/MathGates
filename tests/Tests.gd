extends Node
## 轻量回归测试(GameData 纯逻辑)。
## 运行： godot --headless --path <项目> res://tests/Tests.tscn
## 退出码 0 = 全部通过，1 = 存在失败。

var _pass := 0
var _fail := 0

func _ready() -> void:
	_run()

func _ok(cond: bool, name: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		printerr("FAIL: " + name)

func _eq(a, b, name: String) -> void:
	_ok(a == b, "%s  (got %s, want %s)" % [name, str(a), str(b)])

func _run() -> void:
	_test_domain_mapping()
	_test_lab_data()
	_test_boss_data()
	_test_rhythm()
	_test_lab_plane()
	_test_anim_player()
	_test_plane_motion()
	_test_motion_tokens()
	_test_reduced_motion()
	_test_demo_controls()
	_test_keyboard_nav()
	_test_idle_power()
	_test_wrong_queries()
	_test_review_order()
	_test_srs_rules()
	_test_srs_store()
	_test_srs_flow()
	_test_user_store()
	_test_report_rules()
	_test_report_flow()
	_test_focus()
	_test_accuracy()
	_test_economy()
	_test_anti_farm()
	_test_tts_policy()
	_test_daily()
	_test_textbook()
	_test_player_rules()
	_test_economy_rules()
	_test_pet_rules()
	_test_mastery_rules()
	_test_stage_rules()
	_test_tree_rules()
	_test_legacy_binding()
	_test_curriculum_rules()
	_test_speech_rules()
	_test_session_reset()
	_test_adventure()
	_test_inline_math()
	_test_content_health()
	print("TESTS: %d passed, %d failed" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)

func _test_domain_mapping() -> void:
	_eq(GameData.domain_id_for_level("recur_add"), "seq", "recur_add -> seq")
	_eq(GameData.domain_id_for_level("set_ops"), "algebra", "set_ops -> algebra")
	_eq(GameData.domain_id_for_level("solid_complement"), "solid", "solid_complement -> solid")
	_eq(GameData.domain_id_for_level("conic_c1"), "conic", "conic_c1 -> conic")
	_eq(GameData.domain_id_for_level("circle_1_1"), "line", "circle_1_1 -> line")
	_eq(GameData.domain_id_for_level("circle_boss"), "line", "circle_boss -> line")
	_eq(GameData.domain_id_for_level("trig_induce"), "algebra", "trig_induce -> algebra")
	_eq(GameData.domain_id_for_level("func_domain"), "algebra", "func_domain -> algebra")
	_eq(GameData.domain_id_for_level("rv_dist"), "algebra", "rv_dist -> algebra")
	_eq(GameData.domain_id_for_level("cd_regress"), "algebra", "cd_regress -> algebra")
	_eq(GameData.domain_id_for_level("stat_sample"), "algebra", "stat_sample -> algebra")
	_eq(GameData.domain_id_for_level("cplx_calc"), "algebra", "cplx_calc -> algebra")
	_eq(GameData.domain_id_for_level("hypo_def"), "conic", "hypo_def -> conic")
	_eq(GameData.domain_id_for_level("para_std"), "conic", "para_std -> conic")
	_eq(GameData.domain_id_for_level("solid_kinds"), "solid", "solid_kinds -> solid")
	_eq(GameData.domain_id_for_level("__missing__"), "", "missing level -> empty")

## 校验「实验探究」章节数据齐备：每个关卡配置存在且含 3 轮(探究/建构/迁移)。
func _test_lab_data() -> void:
	var specs := [
		{ "file": "res://data/trig_levels.json", "ids": ["trig_induce", "trig_identity", "trig_graph", "trig_solve", "trig_apply", "trig_radian", "trig_tan", "trig_concept", "trig_sincos"] },
		{ "file": "res://data/functions_levels.json", "ids": ["func_concept", "func_domain", "func_range", "func_corr", "func_mono", "func_parity", "func_period", "func_exp_log", "func_abstract", "func_zeros", "func_power", "func_apply", "func_bisect"] },
		{ "file": "res://data/set_logic_levels.json", "ids": ["set_ops", "set_interval", "logic_cond", "logic_neg", "logic_special"] },
		{ "file": "res://data/inequalities_levels.json", "ids": ["ineq_quad", "ineq_basic"] },
		{ "file": "res://data/circle_levels.json", "ids": ["circle_1_1", "circle_1_2", "circle_1_3", "circle_2_1", "circle_2_2", "circle_2_3", "circle_3_1", "circle_3_2", "circle_3_3", "circle_4_1", "circle_4_2", "circle_4_3", "circle_5_1", "circle_5_2", "circle_5_3", "circle_6_1", "circle_6_2", "circle_6_3", "circle_boss"] },
		{ "file": "res://data/ellipse_levels.json", "ids": ["ellipse_1_1", "ellipse_1_2", "ellipse_1_3", "ellipse_2_1", "ellipse_2_2", "ellipse_2_3", "ellipse_3_1", "ellipse_3_2", "ellipse_3_3", "ellipse_4_1", "ellipse_4_2", "ellipse_4_3", "ellipse_5_1", "ellipse_5_2", "ellipse_5_3", "ellipse_boss"] },
		{ "file": "res://data/vector_levels.json", "ids": ["vector_1_1", "vector_1_2", "vector_1_3", "vector_2_1", "vector_2_2", "vector_2_3", "vector_3_1", "vector_3_2", "vector_3_3", "vector_4_1", "vector_4_2", "vector_4_3", "vector_5_1", "vector_5_2", "vector_5_3", "vector_6_1", "vector_6_2", "vector_6_3", "vector_boss"] },
		{ "file": "res://data/line_levels.json", "ids": ["line_1_1", "line_1_2", "line_1_3", "line_2_1", "line_2_2", "line_2_3", "line_3_1", "line_3_2", "line_3_3", "line_4_1", "line_4_2", "line_4_3", "line_5_1", "line_5_2", "line_6_1", "line_6_2", "line_6_3", "line_boss"] },
		{ "file": "res://data/vectors_levels.json", "ids": ["vec_ops", "vec_coord", "vec_dot", "vec_collinear"] },
		{ "file": "res://data/sequences_levels.json", "ids": ["seq_concept", "seq_ap", "seq_ap_sum", "seq_gp", "seq_gp_sum", "seq_recur", "seq_construct", "seq_sn", "seq_displace", "seq_split"] },
		{ "file": "res://data/conics_levels.json", "ids": ["conic_line_circle", "conic_def", "conic_pointdiff", "conic_tangent", "conic_fixed", "conic_range"] },
		{ "file": "res://data/probability_levels.json", "ids": ["prob_classic", "prob_cond", "prob_dist", "prob_binom", "prob_stats", "prob_total", "prob_hypergeo", "prob_event", "prob_props", "prob_indep", "prob_freq"] },
		{ "file": "res://data/derivative_levels.json", "ids": ["deriv_formula", "deriv_tangent", "deriv_mono", "deriv_param", "deriv_prove", "deriv_zero"] },
		{ "file": "res://data/complex_levels.json", "ids": ["cplx_calc", "cplx_geo", "cplx_period"] },
		{ "file": "res://data/counting_levels.json", "ids": ["count_rule", "count_comb", "count_indirect", "count_binomial"] },
		{ "file": "res://data/thinking_levels.json", "ids": ["think_func_eq", "think_geo", "think_classify", "think_convert"] },
		{ "file": "res://data/statistics_levels.json", "ids": ["stat_sample", "stat_freq", "stat_avg", "stat_percentile"] },
		{ "file": "res://data/random_var_levels.json", "ids": ["rv_dist", "rv_binom", "rv_normal"] },
		{ "file": "res://data/corr_data_levels.json", "ids": ["cd_scatter", "cd_regress", "cd_indep"] },
		{ "file": "res://data/hyperbola_levels.json", "ids": ["hypo_def", "hypo_std", "hypo_asym", "hypo_ecc", "hypo_apply", "hypo_focal_tri", "hypo_focal_radius", "hypo_pointdiff", "hypo_line", "hypo_conjugate", "hypo_fixed"] },
		{ "file": "res://data/parabola_levels.json", "ids": ["para_def", "para_std", "para_geo", "para_chord", "para_apply", "para_props", "para_focal_chord", "para_pointdiff", "para_line", "para_fixed", "para_maxmin"] },
		{ "file": "res://data/solid_basic_levels.json", "ids": ["solid_kinds", "solid_frustum", "solid_surface", "solid_volume", "solid_diag", "solid_sphere", "solid_view", "solid_axiom", "solid_parallel", "solid_perp_prop", "solid_angle", "solid_distance"] },
		{ "file": "res://data/space_levels.json", "ids": ["space_1_1", "space_1_2", "space_1_3", "space_2_1", "space_2_2", "space_2_3", "space_3_1", "space_3_2", "space_3_3", "space_4_1", "space_4_2", "space_4_3", "space_5_1", "space_5_2", "space_5_3", "space_6_1", "space_6_2", "space_6_3", "space_boss"] },
	]
	for spec in specs:
		var path := str(spec["file"])
		_ok(FileAccess.file_exists(path), path + " exists")
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		_ok(typeof(data) == TYPE_DICTIONARY, path + " parses")
		var explore_total := 0
		for id in spec["ids"]:
			_ok((data as Dictionary).has(id), "lab config has " + id)
			var cfg: Dictionary = (data as Dictionary).get(id, {})
			var lv: Array = cfg.get("levels", [])
			_ok(lv.size() >= 3, id + " has >=3 rounds")
			for r in lv:
				if str((r as Dictionary).get("type", "choice")) == "explore":
					explore_total += 1
		var min_explore: int = min(3, (spec["ids"] as Array).size())
		_ok(explore_total >= min_explore, path + " has >=%d explore rounds" % min_explore)

## 校验 BOSS 关战斗层配置：5 个隐藏 Boss 均有 boss{} 元数据，且被 GameData 的 boss 清单覆盖。
func _test_boss_data() -> void:
	var specs := [
		{ "file": "res://data/line_levels.json", "id": "line_boss" },
		{ "file": "res://data/space_levels.json", "id": "space_boss" },
		{ "file": "res://data/vector_levels.json", "id": "vector_boss" },
		{ "file": "res://data/ellipse_levels.json", "id": "ellipse_boss" },
		{ "file": "res://data/circle_levels.json", "id": "circle_boss" },
	]
	var ids: Array = []
	for spec in specs:
		var path := str(spec["file"])
		var lid := str(spec["id"])
		ids.append(lid)
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		_ok(typeof(data) == TYPE_DICTIONARY, path + " parses (boss)")
		var cfg: Dictionary = (data as Dictionary).get(lid, {})
		_ok(cfg.has("boss"), lid + " has boss{} block")
		var boss: Dictionary = cfg.get("boss", {})
		_ok(str(boss.get("title", "")) != "", lid + " boss.title")
		_ok(str(boss.get("name", "")) != "", lid + " boss.name")
		_ok(str(boss.get("avatar", "")).length() >= 1, lid + " boss.avatar")
		var col := str(boss.get("color", ""))
		_ok(col.begins_with("#") and (col.length() == 7 or col.length() == 9), lid + " boss.color hex")
		_ok(int(boss.get("player_hp_bonus", 0)) >= 0, lid + " boss.player_hp_bonus >= 0")
		var ea := float(boss.get("enrage_at", 0.0))
		_ok(ea > 0.0 and ea <= 1.0, lid + " boss.enrage_at in (0,1]")
		var rw: Dictionary = boss.get("reward", {})
		_ok(int(rw.get("first_clear_coins", 0)) > 0, lid + " boss.reward.first_clear_coins > 0")
	# 勋章 boss_first / boss_all 依赖 GameData.boss_level_ids()：应恰好覆盖这 5 关
	var meta: Array = GameData.boss_level_ids()
	_eq(meta.size(), 5, "boss level count == 5")
	for lid2 in ids:
		_ok(meta.has(lid2), "boss_level_ids has " + lid2)

## 校验 P2 关卡节奏：连击倍率映射、5 个 Boss 关的 rules{} 限时块、以及最快用时存档。
func _test_rhythm() -> void:
	# 连击 → 金币倍率
	_eq(ComboBar.multiplier(0), 1.0, "combo mult x0 = 1.0")
	_eq(ComboBar.multiplier(1), 1.0, "combo mult x1 = 1.0")
	_eq(ComboBar.multiplier(2), 1.0, "combo mult x2 = 1.0")
	_ok(absf(ComboBar.multiplier(3) - 1.1) < 1e-6, "combo mult x3 = 1.1")
	_ok(absf(ComboBar.multiplier(4) - 1.2) < 1e-6, "combo mult x4 = 1.2")
	_ok(absf(ComboBar.multiplier(5) - 1.3) < 1e-6, "combo mult x5 = 1.3")
	_ok(absf(ComboBar.multiplier(99) - ComboBar.MULT_CAP) < 1e-6, "combo mult caps at 1.5")

	# Boss 关 rules{}：限时/星时为正且 星时 < 时限；连击条开启。
	var specs := [
		{ "file": "res://data/line_levels.json", "id": "line_boss" },
		{ "file": "res://data/space_levels.json", "id": "space_boss" },
		{ "file": "res://data/vector_levels.json", "id": "vector_boss" },
		{ "file": "res://data/ellipse_levels.json", "id": "ellipse_boss" },
		{ "file": "res://data/circle_levels.json", "id": "circle_boss" },
	]
	for spec in specs:
		var path := str(spec["file"])
		var lid := str(spec["id"])
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		_ok(typeof(data) == TYPE_DICTIONARY, path + " parses (rhythm)")
		var cfg: Dictionary = (data as Dictionary).get(lid, {})
		_ok(cfg.get("rules") is Dictionary, lid + " has rules{} block")
		var rules: Dictionary = cfg.get("rules", {})
		_ok(float(rules.get("time_limit", 0)) > 0.0, lid + " rules.time_limit > 0")
		_ok(float(rules.get("star_time", 0)) > 0.0, lid + " rules.star_time > 0")
		_ok(float(rules.get("star_time", 0)) < float(rules.get("time_limit", 0)), lid + " star_time < time_limit")
		_ok(bool(rules.get("show_combo_bar", false)), lid + " rules.show_combo_bar true")

	# 最快用时存档(用真实函数；置空 current_user 阻止写盘)
	var saved_user := GameData.current_user
	var saved_records: Dictionary = GameData.level_records.duplicate(true)
	GameData.current_user = ""
	var lid2 := "__test_time__"
	GameData.level_records.erase(lid2)
	_eq(GameData.best_time_of(lid2), 0.0, "best_time default 0")
	_ok(GameData.record_level_time(lid2, 42.5), "first time recorded")
	_ok(absf(GameData.best_time_of(lid2) - 42.5) < 1e-6, "best_time stored")
	_ok(not GameData.record_level_time(lid2, 50.0), "slower time ignored")
	_ok(absf(GameData.best_time_of(lid2) - 42.5) < 1e-6, "best_time unchanged after slower")
	_ok(GameData.record_level_time(lid2, 30.0), "faster time recorded")
	_ok(absf(GameData.best_time_of(lid2) - 30.0) < 1e-6, "best_time improved")
	_ok(not GameData.record_level_time(lid2, 0.0), "non-positive time rejected")
	GameData.level_records = saved_records
	GameData.current_user = saved_user

## 校验 LabPlane 的参数表达式求值与圆场景加载(圆/直线/向量等几何章节复用)。
func _test_lab_plane() -> void:
	_ok(load("res://scripts/modules/lab/LabStage.gd") != null, "LabStage loads")
	var plane = load("res://scripts/modules/lab/LabPlane.gd").new()
	add_child(plane)
	plane.set_scene({
		"range": 7,
		"sliders": [
			{ "name": "a", "min": -5, "max": 5, "value": 2, "step": 1 },
			{ "name": "r", "min": 1, "max": 6, "value": 3, "step": 1 },
		],
		"circles": [ { "c": ["a", 0], "r": "r" } ],
		"segments": [ { "p1": ["a", 0], "p2": ["a+r", 0] } ],
	})
	plane.begin_sliders([
		{ "name": "a", "min": -5, "max": 5, "value": 2, "step": 1 },
		{ "name": "r", "min": 1, "max": 6, "value": 3, "step": 1 },
	])
	_eq(plane._num("a+r", 0.0), 5.0, "expr a+r")
	_eq(plane._num("-r", 0.0), -3.0, "expr -r")
	_eq(plane._num("2*r", 0.0), 6.0, "expr 2*r")
	_eq(plane._num("3-r", 0.0), 0.0, "expr 3-r")
	_eq(plane._num("7", 0.0), 7.0, "expr literal")
	_eq(plane._num("sqrt(16)", 0.0), 4.0, "expr sqrt")
	_eq(plane._num("3*(a+r)-1", 0.0), 14.0, "expr nested")
	_ok(absf(plane._num("cos(60)", 0.0) - 0.5) < 1e-6, "expr cos deg")
	_ok(not plane.slider_summary().is_empty(), "slider summary non-empty")
	plane.set_scene({
		"range": 7,
		"ellipses": [ { "a": 5, "b": 3, "axis": "x" } ],
		"foci": [ { "c": 4, "axis": "x" } ],
		"readouts": [ { "label": "S", "expr": "4*abs(3*sin(t))" } ],
	})
	plane.begin_sliders([ { "name": "t", "min": 0, "max": 360, "value": 60, "step": 5 } ])
	_ok(absf(plane._num("sqrt((5*cos(t)+3)^2+(4*sin(t))^2)+sqrt((5*cos(t)-3)^2+(4*sin(t))^2)", 0.0) - 10.0) < 1e-6, "ellipse def_sum readout = 2a")
	plane.begin_sliders([ { "name": "t", "min": 0, "max": 360, "value": 90, "step": 5 } ])
	_ok(absf(plane._num("4*abs(3*sin(t))", 0.0) - 12.0) < 1e-6, "ellipse focal-tri area max")
	plane.begin_sliders([ { "name": "e", "min": 0.01, "max": 0.99, "value": 0.6, "step": 0.01 } ])
	_ok(absf(plane._num("sqrt(25-(5*e)^2)", 0.0) - 4.0) < 1e-6, "ellipse b from e")
	plane.begin_sliders([ { "name": "b", "min": 1, "max": 5, "value": 4, "step": 0.25 } ])
	_ok(absf(plane._num("sqrt(1-b*b/25)", 0.0) - 0.6) < 1e-6, "ecc from b")
	plane.queue_free()

## D2：2D 演示播放器（scene.anim）真的会带动图形；并校验全库 anim 数据的 vars 目标
## 都能命中场景已声明的滑块、且取值不越界（防止后续批量补数据时写错名字/范围）。
func _test_anim_player() -> void:
	var plane = load("res://scripts/modules/lab/LabPlane.gd").new()
	add_child(plane)
	var slider := [ { "name": "r", "min": 0.5, "max": 5, "value": 4, "step": 0.5 } ]
	plane.set_scene({
		"range": 6,
		"sliders": slider,
		"circles": [ { "c": [0, 0], "r": "r" } ],
		"anim": [ { "a": "vars", "to": { "r": 1 }, "dur": 1.0, "hold": 0.0 } ],
	})
	_ok(plane.has_anim(), "scene.anim 被识别")
	plane.begin_sliders(slider)
	plane.play_anim(plane._scene["anim"])
	_ok(plane.is_demo_playing(), "演示开始播放")
	for _i in 8:
		plane._tick_demo(0.2)
	_ok(absf(plane.slider_value("r") - 1.0) < 0.05, "vars 补间把 r 从 4 带到 1")
	_ok(not plane.is_demo_playing(), "演示播完自动停止")
	plane.set_scene({ "range": 6 })
	_ok(not plane.has_anim(), "无 anim 的场景不显示演示")
	_ok(not plane.is_demo_playing(), "set_scene 会中断演示")
	plane.queue_free()

	# ---- 全库数据完整性 ----
	var dir := DirAccess.open("res://data")
	var checked := 0
	for f in dir.get_files():
		if not f.ends_with("_levels.json"):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + f))
		if typeof(data) != TYPE_DICTIONARY:
			continue
		for key in (data as Dictionary).keys():
			var grp: Variant = data[key]
			if typeof(grp) != TYPE_DICTIONARY:
				continue
			for lv in (grp as Dictionary).get("levels", []):
				if typeof(lv) != TYPE_DICTIONARY:
					continue
				var sc: Variant = lv.get("scene", {})
				if typeof(sc) != TYPE_DICTIONARY or not (sc as Dictionary).has("anim"):
					continue
				var rng := {}
				for s in (sc as Dictionary).get("sliders", []):
					rng[str(s.get("name", ""))] = [float(s.get("min", -1e9)), float(s.get("max", 1e9))]
				var raw_steps: Variant = (sc as Dictionary)["anim"]
				var steps: Array = raw_steps if raw_steps is Array else [raw_steps]
				for st in steps:
					if typeof(st) != TYPE_DICTIONARY or str((st as Dictionary).get("a", "")) != "vars":
						continue
					var to: Dictionary = (st as Dictionary).get("to", {})
					for nm in to.keys():
						checked += 1
						_ok(rng.has(str(nm)), "%s anim 使用已声明滑块 %s" % [f, str(nm)])
						if rng.has(str(nm)):
							var lo := float(rng[str(nm)][0])
							var hi := float(rng[str(nm)][1])
							var v := float(to[nm])
							_ok(v >= lo - 1e-6 and v <= hi + 1e-6, "%s 目标 %s=%s 在 [%s, %s] 内" % [f, str(nm), str(v), str(lo), str(hi)])
	_ok(checked > 0, "全库至少有一条 vars 演示（实际 %d 条）" % checked)

## D1：拖动的「过程」表达 —— 补间（中间态真的存在）+ 残影 + 轨迹。
## 无头环境难做像素截图，这里用「显示值严格落在起止之间 / 轨迹帧数 > 0」证明中间态，
## 与人工目视结合即为验收（截图抓帧见 TODO D1 的说明）。
func _test_plane_motion() -> void:
	var plane = load("res://scripts/modules/lab/LabPlane.gd").new()
	add_child(plane)
	var slider := [ { "name": "r", "min": 0.5, "max": 5, "value": 1, "step": 0.5 } ]
	plane.set_scene({
		"range": 6,
		"sliders": slider,
		"circles": [ { "c": [0, 0], "r": "r" } ],
		"points": [ { "p": ["r", 0] } ],
		"readouts": [ { "label": "r", "expr": "r" } ],
		"links": [ { "a": [0, 0], "b": ["r", 0], "label": "r" } ],
		"pulses": [ { "p": ["r", 0], "label": "切点" } ],
	})
	plane.begin_sliders(slider)
	_eq(plane._num("r", 0.0), 1.0, "初始显示值 = 滑块值（无残余缓动）")
	# 模拟一次拖动：滑块目标 1 → 3
	plane._sliders[0]["value"] = 3.0
	plane._process(0.04)
	var mid: float = plane._num("r", 0.0)
	_ok(mid > 1.0 and mid < 3.0, "中间态存在（%.3f 落在 1 与 3 之间）" % mid)
	_ok(plane._ghost_a > 0.0, "残影已激活（记录变化起点）")
	_ok(plane._trail.size() > 0, "轨迹已记录（%d 帧）" % plane._trail.size())
	# D3 delta_highlight：用旧参数算同一表达式，应确实得到不同的值
	var prev: float = plane._num_with(plane._ghost_disp, "r", 0.0)
	_ok(absf(prev - mid) > 1e-4, "delta_highlight 能算出「变了多少」（%.3f → %.3f）" % [prev, mid])
	# D3 pulse_at：停稳后触发一次
	var ticks := 0
	while not plane._settled and ticks < 300:
		plane._process(0.02)
		ticks += 1
	_ok(plane._settled, "补间最终收敛（%d 帧）" % ticks)
	_ok(plane._pulse_t > 0.0, "停稳后触发 pulse（标记特殊点）")
	for _i in 60:
		plane._process(0.02)
	_ok(absf(plane._num("r", 0.0) - 3.0) < 1e-3, "补间最终精确到位 r=3")
	_ok(plane._ghost_a <= 0.0, "残影会自动淡出")
	_ok(plane._trail.is_empty(), "轨迹会自动消失")
	_ok(plane._pulse_t <= 0.0, "脉冲会自动结束")
	# 无滑块场景不应残留任何过程状态
	plane.set_scene({ "range": 6 })
	_ok(plane._disp.is_empty() and plane._trail.is_empty() and plane._ghost_a <= 0.0,
		"换场景会清空补间/残影/轨迹状态")
	plane.queue_free()

	# D3 数据完整性：links 的 a/b、pulses 的 p 都必须是二元数组（写错就静默画不出）
	var dir := DirAccess.open("res://data")
	var n_links := 0
	var n_pulses := 0
	for f in dir.get_files():
		if not f.ends_with("_levels.json"):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + f))
		if typeof(data) != TYPE_DICTIONARY:
			continue
		for key in (data as Dictionary).keys():
			var grp: Variant = data[key]
			if typeof(grp) != TYPE_DICTIONARY:
				continue
			for lv in (grp as Dictionary).get("levels", []):
				if typeof(lv) != TYPE_DICTIONARY:
					continue
				var sc: Variant = lv.get("scene", {})
				if typeof(sc) != TYPE_DICTIONARY:
					continue
				for l in (sc as Dictionary).get("links", []):
					n_links += 1
					_ok(l is Dictionary and (l as Dictionary).get("a") is Array and (l as Dictionary)["a"].size() == 2
						and (l as Dictionary).get("b") is Array and (l as Dictionary)["b"].size() == 2,
						"%s links 端点必须是二元数组" % f)
				for p in (sc as Dictionary).get("pulses", []):
					n_pulses += 1
					_ok(p is Dictionary and (p as Dictionary).get("p") is Array and (p as Dictionary)["p"].size() == 2,
						"%s pulses 坐标必须是二元数组" % f)
	_ok(n_links >= 1 and n_pulses >= 2, "至少各有一处 link/pulse 试点（links=%d, pulses=%d）" % [n_links, n_pulses])

## D4：动效令牌 + 减弱动效语义 + 演示控制。
func _test_motion_tokens() -> void:
	_ok(UI.DUR_TINY < UI.DUR_FAST and UI.DUR_FAST < UI.DUR_NORMAL
		and UI.DUR_NORMAL < UI.DUR_SLOW and UI.DUR_SLOW < UI.DUR_XSLOW
		and UI.DUR_XSLOW < UI.DUR_LONG and UI.DUR_LONG < UI.DUR_SCENE
		and UI.DUR_SCENE < UI.DUR_AMBIENT, "时长令牌单调递增")
	var tw := create_tween()
	_ok(UI.ease(tw) == tw, "UI.ease 返回同一 Tween 以支持链式调用")
	tw.kill()

func _test_reduced_motion() -> void:
	var old_a := UI.animations
	var old_r := UI.reduced_motion
	UI.animations = true
	UI.reduced_motion = false
	_ok(UI.fx_on(), "默认播放装饰动效")
	UI.reduced_motion = true
	_ok(not UI.fx_on(), "减弱动效档关闭装饰动效")
	UI.animations = false
	_ok(not UI.fx_on(), "装饰总开关关闭时也停止")
	# 表意动效不受影响：数学补间照常
	var plane = load("res://scripts/modules/lab/LabPlane.gd").new()
	add_child(plane)
	var slider := [ { "name": "r", "min": 0.5, "max": 5, "value": 1, "step": 0.5 } ]
	plane.set_scene({ "range": 6, "sliders": slider, "circles": [ { "c": [0, 0], "r": "r" } ] })
	plane.begin_sliders(slider)
	plane._sliders[0]["value"] = 3.0
	plane._process(0.04)
	var mid: float = plane._num("r", 0.0)
	_ok(mid > 1.0 and mid < 3.0, "减弱动效下数学补间仍然生效（表意动效常开）")
	plane.queue_free()
	UI.animations = old_a
	UI.reduced_motion = old_r

func _test_demo_controls() -> void:
	# 2D
	var plane = load("res://scripts/modules/lab/LabPlane.gd").new()
	add_child(plane)
	var slider := [ { "name": "r", "min": 0.5, "max": 5, "value": 1, "step": 0.5 } ]
	plane.set_scene({ "range": 6, "sliders": slider, "circles": [ { "c": [0, 0], "r": "r" } ] })
	plane.begin_sliders(slider)
	plane.play_anim([ { "a": "vars", "to": { "r": 4 }, "dur": 0.5, "hold": 0.0 } ])
	_ok(plane.is_demo_playing(), "2D 演示开始")
	plane.pause_demo()
	_ok(plane.is_demo_paused(), "2D 演示可暂停")
	var before: float = plane.slider_value("r")
	plane.step_demo(0.2)
	_ok(absf(plane.slider_value("r") - before) > 1e-4, "2D 单步会推进参数")
	plane.restart_demo()
	_ok(not plane.is_demo_paused() and plane.is_demo_playing(), "2D 重播解除暂停并重新播放")
	plane.queue_free()
	# 3D（用 reveal 步骤，避免依赖 3D 构建器）
	var v = load("res://scripts/modules/lab3d/Lab3DView.gd").new()
	v.play_anim([ { "a": "reveal", "dur": 1.0, "hold": 0.0 } ])
	_ok(v.is_anim_playing(), "3D 演示开始")
	v.pause_anim()
	_ok(v.is_anim_paused(), "3D 演示可暂停")
	var t0: float = v._anim_t
	v.step_anim(0.2)
	_ok(v._anim_t > t0, "3D 单步推进时间轴")
	v.restart_anim()
	_ok(v._anim_t == 0.0 and v._anim_i == 0 and not v.is_anim_paused(), "3D 重播回到起点")
	v.queue_free()

## F4：键盘导航 —— 数字选项、Enter 提交优先级、焦点环、3D 视角。
## 用 test double 承载 StageBase 暴露的那几个字段，避免依赖具体关卡内容。
class FakeStage extends Node:
	var _opt_btns: Array = []
	var _next: Button
	var _hint: Button
	var _kb_confirm: Button
	var _view3d: Node
	var picked := -1
	var next_hits := 0
	var hint_hits := 0
	var confirm_hits := 0

	func _make_option(i: int) -> Button:
		var b := Button.new()
		b.text = "opt%d" % i
		b.pressed.connect(func() -> void: picked = i)
		add_child(b)
		return b

func _test_keyboard_nav() -> void:
	var st := FakeStage.new()
	add_child(st)
	for i in 4:
		st._opt_btns.append(st._make_option(i))
	st._next = Button.new()
	st._next.text = "next"
	st._next.pressed.connect(func() -> void: st.next_hits += 1)
	st.add_child(st._next)
	st._hint = Button.new()
	st._hint.text = "hint"
	st._hint.pressed.connect(func() -> void: st.hint_hits += 1)
	st.add_child(st._hint)
	st._kb_confirm = Button.new()
	st._kb_confirm.text = "confirm"
	st._kb_confirm.pressed.connect(func() -> void: st.confirm_hits += 1)
	st.add_child(st._kb_confirm)

	_ok(KeyNav.handle(st, KEY_3), "数字键被消费")
	_eq(st.picked, 2, "数字 3 选中第 3 个选项（0 基）")
	_ok(not KeyNav.handle(st, KEY_9), "越界数字不消费")

	# Enter：确认按钮优先于下一关
	_ok(KeyNav.handle(st, KEY_ENTER), "Enter 被消费")
	_eq(st.confirm_hits, 1, "Enter 触发实验轮「确认」")
	_eq(st.next_hits, 0, "确认存在时不误触下一关")
	st._kb_confirm.disabled = true
	_ok(KeyNav.handle(st, KEY_ENTER), "确认禁用后 Enter 仍可用")
	_eq(st.next_hits, 1, "确认禁用后 Enter 落到下一关")

	_ok(KeyNav.handle(st, KEY_H), "H 被消费")
	_eq(st.hint_hits, 1, "H 触发提示")

	# 焦点环：首项 → 右移到第二项
	st._opt_btns[0].grab_focus()
	_ok(KeyNav.handle(st, KEY_RIGHT), "方向键被消费")
	var f := st.get_viewport().gui_get_focus_owner()
	_eq(f, st._opt_btns[1], "→ 焦点移到下一个选项")
	KeyNav.handle(st, KEY_LEFT)
	_eq(st.get_viewport().gui_get_focus_owner(), st._opt_btns[0], "← 焦点回到上一个选项")

	# 3D：W/A/S/D 改视角（用真实 Lab3DView）
	var view = load("res://scripts/modules/lab3d/Lab3DView.gd").new()
	st._view3d = view
	var yaw0: float = view.yaw_goal
	var pitch0: float = view.pitch_goal
	_ok(KeyNav.handle(st, KEY_D), "3D 下 D 被消费")
	_ok(view.yaw_goal > yaw0, "D 向右转视角")
	_ok(KeyNav.handle(st, KEY_W), "3D 下 W 被消费")
	_ok(view.pitch_goal < pitch0, "W 抬高视角")
	view.queue_free()
	_ok(not KeyNav.handle(null, KEY_1), "空舞台不崩溃")
	st.queue_free()

## F3：静止降耗 —— 自转会在 8s 停、渲染在 10s 关；交互唤醒；后台停帧。
func _test_idle_power() -> void:
	var v = load("res://scripts/modules/lab3d/Lab3DView.gd").new()
	add_child(v)
	_ok(v._sv != null, "3D 视口已建立")
	_ok(v._sv.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "初始按需之外先保持渲染")
	var yaw0: float = v.yaw_goal
	for _i in 60:
		v._process(0.1)
	_ok(v.yaw_goal > yaw0, "前 6s 仍在自转")
	for _i in 30:
		v._process(0.1)
	var yaw_stop: float = v.yaw_goal
	for _i in 5:
		v._process(0.1)
	_ok(absf(v.yaw_goal - yaw_stop) < 1e-6, "空闲 8s 后自转停止")
	for _i in 60:
		v._process(0.1)
	_ok(v._sv.render_target_update_mode == SubViewport.UPDATE_DISABLED, "静止 10s 后停止 3D 渲染")
	v._wake()
	_ok(v._sv.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "交互会唤醒渲染")
	v._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_ok(v._sv.render_target_update_mode == SubViewport.UPDATE_DISABLED, "切后台停渲染")
	v._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_ok(v._sv.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "回前台恢复渲染")
	v.queue_free()

	# 背景层：动效关闭时整条处理循环停掉，而不是每帧空转判断
	var old_a := UI.animations
	var old_r := UI.reduced_motion
	var bg = load("res://scripts/ui/TechBg.gd").new()
	add_child(bg)
	UI.animations = false
	UI.reduced_motion = false
	bg._process(0.016)
	_ok(not bg.is_processing(), "关闭动效后背景停止处理（省电）")
	UI.animations = true
	bg._on_settings_changed()
	_ok(bg.is_processing(), "重新开启动效后背景恢复")
	bg.queue_free()
	UI.animations = old_a
	UI.reduced_motion = old_r

	# LabPlane：静止后不应再重绘（连续 20 帧计数不增）
	var plane = load("res://scripts/modules/lab/LabPlane.gd").new()
	add_child(plane)
	var slider := [ { "name": "r", "min": 0.5, "max": 5, "value": 2, "step": 0.5 } ]
	plane.set_scene({ "range": 6, "sliders": slider, "circles": [ { "c": [0, 0], "r": "r" } ] })
	plane.begin_sliders(slider)
	for _i in 40:
		plane._process(0.1)      # 越过 2.5s 入场显现
	var c0: int = plane.redraw_count
	for _i in 20:
		plane._process(0.1)
	_eq(plane.redraw_count, c0, "2D 平面静止后不再重绘（省电）")
	# 拖动时仍会重绘
	plane._sliders[0]["value"] = 4.0
	plane._process(0.1)
	_ok(plane.redraw_count > c0, "参数变化时恢复重绘")
	plane.queue_free()

func _test_wrong_queries() -> void:
	var saved: Dictionary = GameData.wrong_log
	GameData.wrong_log = {
		"A#0": {"level_id": "A", "qi": 0, "name": "q0", "module": "seq", "count": 1, "last_chose": 0, "correct": 1},
		"A#1": {"level_id": "A", "qi": 1, "name": "q1", "module": "seq", "count": 3, "last_chose": 2, "correct": 3},
		"B#0": {"level_id": "B", "qi": 0, "name": "q0", "module": "algebra", "count": 2, "last_chose": 0, "correct": 0},
	}
	_eq(GameData.wrong_list().size(), 3, "wrong_list size")
	_eq(int(GameData.wrong_list()[0]["count"]), 3, "wrong_list sorted desc")
	_eq(GameData.wrong_count_for("A", 1), 3, "wrong_count_for hit")
	_eq(GameData.wrong_count_for("A", 9), 0, "wrong_count_for miss")
	var kp := GameData.key_points()
	_eq(kp.size(), 2, "key_points groups by level")
	_eq(str(kp[0]["level_id"]), "A", "key_points orders by total")
	_eq(int(kp[0]["count"]), 4, "key_points sums counts")
	GameData.wrong_log = saved

func _test_review_order() -> void:
	var saved: Dictionary = GameData.wrong_log
	GameData.wrong_log = {
		"L#1": {"level_id": "L", "qi": 1, "name": "", "module": "seq", "count": 3, "last_chose": -1, "correct": -1},
		"L#0": {"level_id": "L", "qi": 0, "name": "", "module": "seq", "count": 1, "last_chose": -1, "correct": -1},
	}
	var r := GameData.review_order("L", [{}, {}, {}])
	_eq(r["review"], true, "review_order active when wrong exists")
	_eq(str(r["order"]), str([1, 0, 2]), "review_order puts most-wrong first")
	var rf := GameData.review_order("L", [{}, {}, {}], 2)
	_eq(str(rf["order"]), str([2, 1, 0]), "review_order focus moves chosen to front")
	GameData.wrong_log = saved

## G1：SRS 纯规则（构造数据，不依赖存档与系统时间）。
func _test_srs_rules() -> void:
	# 间隔阶梯 1/3/7/16/35 天
	_eq(SrsRules.interval_days(0), 1, "srs: ladder step0 = 1 day")
	_eq(SrsRules.interval_days(1), 3, "srs: ladder step1 = 3 days")
	_eq(SrsRules.interval_days(2), 7, "srs: ladder step2 = 7 days")
	_eq(SrsRules.interval_days(3), 16, "srs: ladder step3 = 16 days")
	_eq(SrsRules.interval_days(4), 35, "srs: ladder step4 = 35 days")
	_eq(SrsRules.interval_days(99), 35, "srs: ladder clamps to last")
	_eq(SrsRules.interval_days(-3), 1, "srs: ladder clamps to first")

	# 新计划：阶梯 0、明天到期
	var p := SrsRules.new_plan("L", 0, "q", "seq", 1000, 20000)
	_eq(int(p["step"]), 0, "srs: new plan step 0")
	_eq(int(p["ok_streak"]), 0, "srs: new plan streak 0")
	_eq(int(p["interval_days"]), 1, "srs: new plan interval 1")
	_eq(int(p["due_day"]), 20001, "srs: new plan due tomorrow")
	_eq(int(p["wrong_count"]), 1, "srs: new plan wrong_count 1")

	# 模拟推进：间隔按 1 → 3 → 7 → 16 → 35 增长
	var cur: Dictionary = p
	var seen: Array[int] = [1]
	for i in 5:
		cur = SrsRules.advance(cur, true, 20000 + i, 20000 + i)
		seen.append(int(cur["interval_days"]))
	_eq(str(seen), str([1, 3, 7, 16, 35, 35]), "srs: ladder grows 1/3/7/16/35")
	_eq(bool(cur.get("graduated", false)), true, "srs: 4 consecutive corrects graduate")

	# 答错重置：阶梯归零、明天再来、连对清零
	var bad := SrsRules.advance(cur, false, 30000, 21000)
	_eq(int(bad["step"]), 0, "srs: wrong resets step")
	_eq(int(bad["interval_days"]), 1, "srs: wrong resets interval to 1 day")
	_eq(int(bad["ok_streak"]), 0, "srs: wrong clears streak")
	_eq(int(bad["due_day"]), 21001, "srs: wrong due tomorrow")
	_eq(int(bad["wrong_count"]), 2, "srs: wrong grows wrong_count")
	_eq(bool(bad.get("graduated", false)), false, "srs: wrong never graduates")

	# 到期判定：今天刚错过 → 今天到期（保留即时复练）；答对后按间隔推后
	_eq(SrsRules.is_due(p, 20000), true, "srs: fresh miss due today")
	_eq(SrsRules.is_due(p, 20001), true, "srs: still due tomorrow")
	var ok := SrsRules.advance(p, true, 20000, 20000)
	_eq(SrsRules.is_due(ok, 20000), false, "srs: not due right after a correct answer")
	_eq(SrsRules.is_due(ok, 20003), true, "srs: due again after 3 days")
	_eq(SrsRules.days_left(ok, 20000), 3, "srs: days_left counts the interval")
	_eq(SrsRules.due_text(ok, 20000), "3 天后复习", "srs: due_text in N days")
	_eq(SrsRules.due_text(ok, 20003), "今天到期", "srs: due_text today")
	_eq(SrsRules.due_text(p, 20000), "今天到期", "srs: fresh miss shows due today")

	# 旧档（无 due_day）→ 立即到期
	var legacy := {"level_id": "L", "qi": 0}
	_eq(SrsRules.due_day_of(legacy), 0, "srs: legacy due_day 0")
	_eq(SrsRules.is_due(legacy, 20000), true, "srs: legacy treated as due now")

	# 排序：到期日升序 → 错次多优先 → 题号稳定
	var a := {"due_day": 100, "wrong_count": 1, "qi": 5}
	var b := {"due_day": 100, "wrong_count": 3, "qi": 9}
	var c := {"due_day": 50, "wrong_count": 1, "qi": 1}
	var d := {"due_day": 200500, "wrong_count": 2, "qi": 2}
	_eq(SrsRules.plan_less(c, a, 20000), true, "srs: earlier due goes first")
	_eq(SrsRules.plan_less(b, a, 20000), true, "srs: more wrong goes first on tie")
	_eq(SrsRules.plan_less(a, b, 20000), false, "srs: fewer wrong goes last")
	_eq(SrsRules.count_due([a, b, c, d], 20000), 3, "srs: count_due counts due plans")

	# 当日奖励去重
	_eq(SrsRules.rewarded_today({"last_reward_day": "2026-10-21"}, "2026-10-21"), true, "srs: rewarded today")
	_eq(SrsRules.rewarded_today({"last_reward_day": "2026-10-21"}, "2026-10-22"), false, "srs: not rewarded tomorrow")
	_eq(SrsRules.rewarded_today({}, "2026-10-21"), false, "srs: never rewarded")

## G1：SRS 存档层（纯字典操作，不依赖 autoload 与系统时间）。
func _test_srs_store() -> void:
	_eq(SrsStore.key("L1", 3), "L1#3", "store: plan key format")

	# 旧档合成：无时间戳 → 立即到期
	var legacy := SrsStore.legacy_plan({"level_id": "L1", "qi": 3, "name": "q", "module": "seq", "count": 2})
	_eq(int(legacy["due_day"]), 0, "store: legacy plan due_day 0")
	_eq(int(legacy["wrong_count"]), 2, "store: legacy plan keeps wrong count")
	_eq(SrsRules.is_due(legacy, 100), true, "store: legacy plan is due now")

	# plan_for：排程优先 → 旧档兜底 → 空
	var plans := {"L1#3": {"level_id": "L1", "qi": 3, "due_day": 500, "wrong_count": 1}}
	var wrong_log := {"L1#3": {"level_id": "L1", "qi": 3, "count": 5}, "L2#0": {"level_id": "L2", "qi": 0, "count": 1}}
	_eq(int(SrsStore.plan_for(plans, wrong_log, "L1", 3)["due_day"]), 500, "store: plan wins over wrong log")
	_eq(int(SrsStore.plan_for(plans, wrong_log, "L2", 0)["due_day"]), 0, "store: wrong log falls back to legacy")
	_eq(SrsStore.plan_for(plans, wrong_log, "L9", 9).is_empty(), true, "store: unknown question has no plan")

	# due_list：只含到期项，旧档无时间戳即到期
	var dl := SrsStore.due_list(plans, wrong_log, 100)
	_eq(dl.size(), 1, "store: due list only holds due items")
	_eq(str(dl[0]["level_id"]), "L2", "store: legacy item is due")

	# answer：答错建计划、答对进阶、同日不重复发奖、连对毕业
	var p2 := {}
	var r1 := SrsStore.answer(p2, "L1", 0, "q", "seq", false, 1000, 100, "2026-01-01")
	_eq(p2.size(), 1, "store: wrong creates a plan")
	_eq(int(r1["coins"]), 0, "store: wrong pays no bonus")
	var r2 := SrsStore.answer(p2, "L1", 0, "q", "seq", true, 1000, 100, "2026-01-01")
	_eq(int(r2["coins"]), SrsRules.REVIEW_COINS, "store: correct review pays a bonus")
	_eq(int(p2["L1#0"]["interval_days"]), 3, "store: correct advances to 3 days")
	var r3 := SrsStore.answer(p2, "L1", 0, "q", "seq", true, 1000, 100, "2026-01-01")
	_eq(int(r3["coins"]), 0, "store: no double bonus on the same day")
	_eq(int(p2["L1#0"]["interval_days"]), 7, "store: 2nd correct advances to 7 days")
	SrsStore.answer(p2, "L1", 0, "q", "seq", true, 1000, 101, "2026-01-02")
	var r4 := SrsStore.answer(p2, "L1", 0, "q", "seq", true, 1000, 102, "2026-01-03")
	_eq(bool(r4["graduated"]), true, "store: graduation flag raised")
	_eq(p2.size(), 0, "store: graduation removes the plan")
	_eq(int(r4["coins"]), SrsRules.GRADUATE_COINS, "store: graduation pays a bonus")

	# answer：从未错过且答对 → 不进计划
	var p3 := {}
	SrsStore.answer(p3, "L9", 0, "q", "seq", true, 1000, 100, "2026-01-01")
	_eq(p3.size(), 0, "store: correct on a clean question creates no plan")

	# normalize：字段补全与钳制、丢弃非法条目
	var norm := SrsStore.normalize({"L1#0": {"level_id": "L1"}, "bad": 42})
	_eq(norm.size(), 1, "store: normalize drops non-dictionary entries")
	var np: Dictionary = norm["L1#0"]
	_eq(int(np["qi"]), 0, "store: normalize fills qi")
	_eq(int(np["step"]), 0, "store: normalize clamps step")
	_eq(int(np["interval_days"]), 1, "store: normalize fills interval")
	_eq(str(np["last_reward_day"]), "", "store: normalize fills reward day")

	# review_order：到期项前置、深链置顶
	var p4 := {"L1#2": {"level_id": "L1", "qi": 2, "due_day": 0, "wrong_count": 1}}
	var ro := SrsStore.review_order("L1", [{}, {}, {}], -1, p4, {}, 100)
	_eq(str(ro["order"]), str([2, 0, 1]), "store: due item pulled to front")
	_eq(bool(ro["review"]), true, "store: review flag set")
	var ro2 := SrsStore.review_order("L1", [{}, {}, {}], 1, p4, {}, 100)
	_eq(str(ro2["order"]), str([1, 2, 0]), "store: focus jumps to front")
	var ro3 := SrsStore.review_order("L1", [{}, {}, {}], -1, {}, {}, 100)
	_eq(bool(ro3["review"]), false, "store: no review flag without wrong entries")

	# pet_quests：到期优先、未到期错题补位
	var meta := func(_lid: String) -> Dictionary:
		return {"valid": true, "chapter": "序", "level_name": "L", "domain": {}}
	var plans5 := {
		"L1#2": {"level_id": "L1", "qi": 2, "due_day": 100, "wrong_count": 1},
		"L1#3": {"level_id": "L1", "qi": 3, "due_day": 500, "wrong_count": 9},
	}
	var wl5 := {"L1#1": {"level_id": "L1", "qi": 1, "name": "q1", "module": "seq", "count": 2}}
	var wrongs5 := [{"level_id": "L1", "qi": 3, "name": "q3", "module": "seq", "count": 9}]
	var quests := SrsStore.pet_quests(5, plans5, wl5, wrongs5, meta, 100)
	_eq(quests.size(), 3, "store: quests = due items plus filler")
	_eq(int(quests[0]["qi"]), 1, "store: overdue legacy quest first")
	_eq(int(quests[1]["qi"]), 2, "store: due plan quest second")
	_eq(int(quests[2]["qi"]), 3, "store: not-due wrong item last")
	_eq(str(quests[1]["chapter"]), "序", "store: quest carries chapter meta")

## G1：SRS 门面流程——错→建计划、答对进阶、答错重置、连对毕业、旧档兼容。
func _test_srs_flow() -> void:
	var saved_wrong: Dictionary = GameData.wrong_log
	var saved_plan: Dictionary = GameData.srs_plan
	var saved_coins := GameData.coins
	var saved_earned := GameData.coins_earned
	var saved_q := GameData.total_questions
	var saved_c := GameData.total_correct
	var saved_user := GameData.current_user
	GameData.current_user = ""      # 避免落盘真实存档
	GameData.wrong_log = {}
	GameData.srs_plan = {}
	GameData.coins = 0
	GameData.coins_earned = 0

	# ① 答错 → 进复习计划（阶梯 0、明天到期），今天仍算到期（即时复练）
	GameData.record_answer("__srs__", 0, "q0", false, 1, 2, "seq")
	_eq(GameData.srs_plan.size(), 1, "srs: wrong creates a plan")
	var p: Dictionary = GameData.srs_plan.get("__srs__#0", {})
	_eq(int(p.get("step", -1)), 0, "srs: new plan step 0")
	_eq(int(p.get("interval_days", 0)), 1, "srs: new plan interval 1 day")
	_eq(int(p.get("wrong_count", 0)), 1, "srs: wrong_count 1")
	_eq(GameData.srs_due_count(), 1, "srs: fresh mistake is due today")
	_eq(GameData.srs_due_list().size(), 1, "srs: due list contains it")

	# ② 答对 → 阶梯 +1、间隔 3 天、到期日推后；错账结清 + 复习奖励
	var today := GameData.today_day()
	GameData.record_answer("__srs__", 0, "q0", true, -1, -1, "seq")
	p = GameData.srs_plan.get("__srs__#0", {})
	_eq(int(p.get("step", -1)), 1, "srs: correct advances step")
	_eq(int(p.get("interval_days", 0)), 3, "srs: correct -> 3 days")
	_eq(int(p.get("due_day", 0)), today + 3, "srs: due pushed 3 days")
	_eq(int(p.get("ok_streak", 0)), 1, "srs: ok_streak 1")
	_eq(GameData.srs_due_count(), 0, "srs: not due right after a correct answer")
	_eq(GameData.coins, GameData.WRONG_CLEAR_COINS + SrsRules.REVIEW_COINS, "srs: clear + review bonus paid")

	# ③ 同日再答对 → 阶梯再进（7 天），但当日不重复发奖（防刷）
	GameData.record_answer("__srs__", 0, "q0", true, -1, -1, "seq")
	_eq(int(GameData.srs_plan["__srs__#0"].get("interval_days", 0)), 7, "srs: 2nd correct -> 7 days")
	_eq(GameData.coins, GameData.WRONG_CLEAR_COINS + SrsRules.REVIEW_COINS, "srs: no double bonus same day")

	# ④ 答错 → 重置到 1 天、错次 +1、连对清零
	GameData.record_answer("__srs__", 0, "q0", false, 1, 2, "seq")
	p = GameData.srs_plan.get("__srs__#0", {})
	_eq(int(p.get("step", -1)), 0, "srs: wrong resets step")
	_eq(int(p.get("interval_days", 0)), 1, "srs: wrong resets interval")
	_eq(int(p.get("wrong_count", 0)), 2, "srs: wrong grows wrong_count")
	_eq(int(p.get("ok_streak", 0)), 0, "srs: wrong clears streak")
	_eq(GameData.srs_due_count(), 1, "srs: wrong again is due today")

	# ⑤ 连续答对 4 次 → 毕业（移出复习计划）
	var c_before := GameData.coins
	GameData.record_answer("__srs__", 0, "q0", true, -1, -1, "seq")
	GameData.record_answer("__srs__", 0, "q0", true, -1, -1, "seq")
	GameData.record_answer("__srs__", 0, "q0", true, -1, -1, "seq")
	_eq(int(GameData.srs_plan["__srs__#0"].get("ok_streak", 0)), 3, "srs: streak 3 before graduation")
	GameData.record_answer("__srs__", 0, "q0", true, -1, -1, "seq")
	_eq(GameData.srs_plan.size(), 0, "srs: graduated removes the plan")
	_eq(GameData.coins - c_before, GameData.WRONG_CLEAR_COINS + SrsRules.GRADUATE_COINS, "srs: graduation pays clear + graduate bonus")
	_eq(GameData.srs_due_count(), 0, "srs: graduated leaves nothing due")

	# ⑥ 旧档兼容：只有错题记录、没有复习计划 → 视为立即到期
	GameData.wrong_log = {"__legacy__#0": {"level_id": "__legacy__", "qi": 0, "name": "q", "module": "seq", "count": 2}}
	GameData.srs_plan = {}
	_eq(GameData.srs_due_count(), 1, "srs: legacy wrong entry is due now")
	var ro := GameData.review_order("__legacy__", [{}, {}, {}])
	_eq(str(ro["order"]), str([0, 1, 2]), "srs: legacy wrong entry pulled to front")
	_eq(bool(ro["review"]), true, "srs: review flag on for legacy wrong entry")

	GameData.wrong_log = saved_wrong
	GameData.srs_plan = saved_plan
	GameData.coins = saved_coins
	GameData.coins_earned = saved_earned
	GameData.total_questions = saved_q
	GameData.total_correct = saved_c
	GameData.current_user = saved_user

## A4：存档层拆分（rules/UserStore.gd）——空白档、快照、载入钳制与错题迁移（纯字典，不碰磁盘）。
func _test_user_store() -> void:
	# blank_user：字段齐全，created 由调用方给（本文件不依赖系统时钟）
	var b := UserStore.blank_user("2026-10-21")
	_eq(str(b["created"]), "2026-10-21", "store: blank user keeps created")
	_eq(int(b["coins"]), 0, "store: blank user starts with 0 coins")
	_eq((b["wrong_log"] as Dictionary).size(), 0, "store: blank user has an empty wrong log")
	_eq((b["activity"] as Array).size(), 0, "store: blank user has an empty activity log")

	# snapshot：运行时状态 → 存档 dict（last_chapter_id ↔ last_chapter）
	var st := {
		"avatar": "boss", "player_exp": 12, "coins": 30, "coins_earned": 40, "stars": {"L1": 2},
		"total_questions": 9, "total_correct": 7, "wrong_log": {"L1#0": {"count": 1}},
		"srs_plan": {}, "level_records": {}, "pet_fed": 2, "regions_seen": 1,
		"pet_satiety": 0.5, "pet_mood": 0.6, "pet_last_seen": 99, "pet_parts": {}, "pet_stage": 0,
		"medals": {}, "chapter_order": ["c1"], "last_chapter_id": "ch1",
		"owned_avatars": ["player"], "hint_tokens": 1, "coin_boost": 2, "best_streak": 4,
		"last_login_date": "2026-10-20", "login_streak": 3, "daily_date": "2026-10-21",
		"daily_base": {}, "daily_peak_streak": 5, "daily_claimed": {}, "chests_claimed": {},
		"events_seen": {}, "activity": [{"date": "2026-10-21", "answered": 3}],
	}
	var snap := UserStore.snapshot(st, "2026-10-01")
	_eq(str(snap["last_chapter"]), "ch1", "store: snapshot maps last_chapter_id")
	_eq(snap.has("last_chapter_id"), false, "store: snapshot drops the runtime-only key")
	_eq(str(snap["created"]), "2026-10-01", "store: snapshot keeps created")
	_eq(int(snap["coins"]), 30, "store: snapshot copies coins")
	_eq((snap["activity"] as Array).size(), 1, "store: snapshot keeps the activity log")

	# parse：缺字段取默认值
	var base := {"stars": {"L1": 0, "L2": 0}}
	var ids := ["player", "boss"]
	var p := UserStore.parse({}, base, ids)
	_eq(int(p["coins"]), 0, "store: parse defaults coins")
	_eq(float(p["pet_satiety"]), 1.0, "store: parse defaults satiety")
	_eq(float(p["pet_mood"]), 0.8, "store: parse defaults mood")
	_eq((p["owned_avatars"] as Array).size(), 2, "store: a legacy save unlocks every avatar")
	_eq((p["chapter_order"] as Array).size(), 0, "store: parse defaults the chapter order")
	_eq((p["activity"] as Array).size(), 0, "store: parse defaults the activity log")
	_eq((p["stars"] as Dictionary).size(), 2, "store: parse keeps the known star keys")

	# parse：越界值钳制、未知关卡 id 丢弃
	var p2 := UserStore.parse({"pet_satiety": 9.0, "pet_mood": -3.0, "stars": {"L1": 3, "ZZ": 5}}, base, ids)
	_eq(float(p2["pet_satiety"]), 1.0, "store: parse clamps satiety")
	_eq(float(p2["pet_mood"]), 0.2, "store: parse clamps mood")
	_eq(int(p2["stars"]["L1"]), 3, "store: parse restores a known star")
	_eq(p2["stars"].has("ZZ"), false, "store: parse drops unknown star ids")

	# parse：默认值依赖别的字段的几项
	var p3 := UserStore.parse({"coins_earned": 77, "pet_parts": {"seq": 1}}, base, ids)
	_eq(int(p3["coins_earned"]), 77, "store: parse keeps coins_earned")
	_eq(int(p3["pet_stage"]), 1, "store: parse defaults pet_stage from pet_parts")
	var p4 := UserStore.parse({"coins": 50}, base, ids)
	_eq(int(p4["coins_earned"]), 50, "store: parse falls back coins_earned to coins")

	# 迁移：错题 module 统一为规范领域 id
	var wl := {"L1#0": {"level_id": "L1", "module": ""}, "bad": 42}
	var fixed := UserStore.normalize_wrong_modules(wl, func(_id: String) -> String: return "seq")
	_eq(str(fixed["L1#0"]["module"]), "seq", "store: wrong module migrated to the domain id")
	_eq(fixed.has("bad"), true, "store: non-dictionary entries survive the migration")

## G3：学习报告规则（rules/ReportRules.gd + rules/ReportExport.gd）——日历日、活动日志、汇总、家长视图与导出。
func _test_report_rules() -> void:
	# 日历日换算：纯日历，不涉时区
	_eq(ReportRules.date_of(ReportRules.index_of("2026-10-21")), "2026-10-21", "report: date round-trips")
	_eq(ReportRules.index_of("2026-10-22") - ReportRules.index_of("2026-10-21"), 1, "report: consecutive days differ by 1")
	_eq(ReportRules.index_of("2026-03-01") - ReportRules.index_of("2026-02-28"), 1, "report: leap-year day math")
	_eq(ReportRules.index_of("2026-12-31") - ReportRules.index_of("2026-01-01"), 364, "report: year span is 365 days")
	_eq(ReportRules.index_of("bad"), 0, "report: an invalid date maps to 0")

	# 最近 N 天：升序，末位是今天
	var dates := ReportRules.recent_dates("2026-10-21", 7)
	_eq(dates.size(), 7, "report: 7 days requested")
	_eq(str(dates[0]), "2026-10-15", "report: the range starts 6 days ago")
	_eq(str(dates[6]), "2026-10-21", "report: the range ends today")

	# 活动日志：累加、建日、排序
	var act: Array = []
	act = ReportRules.bump(act, "2026-10-21", "answered", 3)
	_eq(act.size(), 1, "report: the first bump creates a day")
	_eq(int((act[0] as Dictionary)["answered"]), 3, "report: bump accumulates")
	act = ReportRules.bump(act, "2026-10-20", "correct", 2)
	act = ReportRules.bump(act, "2026-10-20", "answered", 2)
	_eq(act.size(), 2, "report: another day is added")
	_eq(str((act[0] as Dictionary)["date"]), "2026-10-20", "report: the activity log stays sorted")
	_eq(int(ReportRules.day_record(act, "2026-10-21")["answered"]), 3, "report: day record found")
	_eq(ReportRules.day_record(act, "1999-01-01").size(), 0, "report: a missing day returns an empty record")

	# 汇总：只统计窗口内，正确率与活跃天
	var sum := ReportRules.summarize(act, "2026-10-21", 7)
	_eq(int(sum["answered"]), 5, "report: summary counts the answers")
	_eq(int(sum["correct"]), 2, "report: summary counts the correct answers")
	_eq(int(round(float(sum["accuracy"]) * 100.0)), 40, "report: summary accuracy")
	_eq(int(sum["active_days"]), 2, "report: summary active days")
	_eq((sum["daily"] as Array).size(), 7, "report: summary has one row per day")
	_eq(str((sum["daily"] as Array)[6]["date"]), "2026-10-21", "report: the daily row ends today")
	var sum30 := ReportRules.summarize(act, "2026-10-21", 30)
	_eq((sum30["daily"] as Array).size(), 30, "report: the month report has 30 rows")
	_eq(int(sum30["answered"]), 5, "report: the month report keeps the same answers")

	# 薄弱点：领域级，不带关卡名
	var weak := ReportRules.weak_points([
		{"domain": {"id": "seq", "title": "数列·律动"}, "mastery": 0.42, "wrong_count": 5},
		{"domain": {"id": "conic", "title": "圆锥曲线·曲线"}, "mastery": 0.31, "wrong_count": 3},
	], 1)
	_eq(weak.size(), 1, "report: weak points honor the limit")
	_eq(str(weak[0]["title"]), "数列·律动", "report: weak point title")
	_eq(int(weak[0]["mastery"]), 42, "report: weak point mastery is a percentage")
	_eq(weak[0].has("name"), false, "report: a weak point carries no level name")

	# 家长视图：只有汇总量与领域名
	var pv := ReportRules.parent_view(sum, weak)
	_eq(int(pv["answered"]), 5, "report: parent view answers")
	_eq(int(pv["accuracy"]), 40, "report: parent view accuracy")
	_eq((pv["weak_titles"] as Array).size(), 1, "report: parent view weak titles")
	_eq(str(pv["note"]).contains("不含题目原文"), true, "report: parent view states the privacy rule")
	_eq(ReportExport.parent_advice(pv).contains("数列"), true, "report: parent advice names the weak domain")
	_eq(ReportExport.parent_advice({"answered": 0, "weak_titles": []}), "本期暂无学习记录。", "report: empty parent advice")

	# 导出：文本 / CSV / JSON
	var txt := ReportExport.report_text(sum, weak)
	_eq(txt.contains("2026-10-15"), true, "report: the text report carries the range")
	_eq(txt.contains("正确率"), true, "report: the text report carries the accuracy")
	_eq(txt.contains("不联网"), true, "report: the text report states it is local")
	var csv := ReportExport.report_csv(sum)
	_eq(csv.begins_with("date,answered,correct,stars,clears,reviews"), true, "report: csv header")
	_eq(csv.strip_edges().split("\n").size(), 8, "report: csv has one row per day")
	_eq(typeof(JSON.parse_string(ReportExport.report_json(sum))), TYPE_DICTIONARY, "report: json parses back")

## G3：门面流程——作答进活动日志、报告汇总、家长视图不泄露题目、导出可用。
func _test_report_flow() -> void:
	var saved_act: Array = GameData.activity
	var saved_wrong: Dictionary = GameData.wrong_log
	var saved_plan: Dictionary = GameData.srs_plan
	var saved_q := GameData.total_questions
	var saved_c := GameData.total_correct
	var saved_user := GameData.current_user
	GameData.current_user = ""      # 避免落盘真实存档
	GameData.activity = []
	GameData.wrong_log = {}
	GameData.srs_plan = {}
	GameData.total_questions = 0
	GameData.total_correct = 0

	# ① 答对 + 答错各一次 → 当日 answered=2、correct=1
	GameData.record_answer("__rep__", 0, "q0", true, -1, -1, "seq")
	GameData.record_answer("__rep__", 1, "q1", false, 1, 2, "seq")
	var today_rec := ReportRules.day_record(GameData.activity, GameData._today())
	_eq(int(today_rec.get("answered", 0)), 2, "report: answers are logged")
	_eq(int(today_rec.get("correct", 0)), 1, "report: correct answers are logged")

	# ② 汇总门面反映活动
	var s := GameData.report_summary(7)
	_eq(int(s["answered"]), 2, "report: the summary sees the answers")
	_eq(int(round(float(s["accuracy"]) * 100.0)), 50, "report: the summary accuracy")
	_eq(int(s["active_days"]), 1, "report: the summary active days")

	# ③ 家长视图：不含题目原文、不含题号
	var pv := GameData.parent_view(7)
	_eq(int(pv["answered"]), 2, "report: the parent view sees the answers")
	var pj := JSON.stringify(pv)
	_eq(pj.contains("__rep__"), false, "report: the parent view leaks no level id")
	_eq(pj.contains("q0"), false, "report: the parent view leaks no question text")

	# ④ 导出三种格式都可用
	_eq(GameData.report_csv(7).contains("answered"), true, "report: csv export")
	_eq(typeof(JSON.parse_string(GameData.report_json(7))), TYPE_DICTIONARY, "report: json export")
	_eq(GameData.report_text(7).contains("不联网"), true, "report: text export")

	# ⑤ 活动日志能进存档、也能读回来
	var snap := UserStore.snapshot({"activity": GameData.activity}, "2026-10-21")
	_eq((snap["activity"] as Array).size(), 1, "report: the activity log enters the save file")
	var back := UserStore.parse(snap, {"stars": {}}, ["player"])
	_eq((back["activity"] as Array).size(), 1, "report: the activity log survives the round-trip")

	GameData.activity = saved_act
	GameData.wrong_log = saved_wrong
	GameData.srs_plan = saved_plan
	GameData.total_questions = saved_q
	GameData.total_correct = saved_c
	GameData.current_user = saved_user

func _test_focus() -> void:
	var saved: Dictionary = GameData.wrong_log
	var saved_user := GameData.current_user
	GameData.current_user = ""   # 避免 start_level 的 _save() 触碰真实存档
	GameData.wrong_log = {
		"L#1": {"level_id": "L", "qi": 1, "name": "", "module": "seq", "count": 3, "last_chose": -1, "correct": -1},
	}
	GameData.start_level_focus(0, 0, 1)
	_eq(GameData.review_focus, 1, "start_level_focus sets review_focus")
	var ro := GameData.review_order("L", [{}, {}, {}], GameData.review_focus)
	_eq(str(ro["order"]), str([1, 0, 2]), "stage reorder honors review_focus")
	GameData.start_level(0, 0)
	_eq(GameData.review_focus, -1, "start_level clears review_focus")
	GameData.wrong_log = saved
	GameData.current_user = saved_user

func _test_accuracy() -> void:
	var q := GameData.total_questions
	var c := GameData.total_correct
	GameData.total_questions = 10
	GameData.total_correct = 7
	_eq(GameData.accuracy(), 0.7, "accuracy 7/10")
	GameData.total_questions = 0
	GameData.total_correct = 0
	_eq(GameData.accuracy(), 0.0, "accuracy zero-safe")
	GameData.total_questions = q
	GameData.total_correct = c

func _test_economy() -> void:
	var saved_user := GameData.current_user
	var s_coins := GameData.coins
	var s_earned := GameData.coins_earned
	var s_owned: Array = GameData.owned_avatars.duplicate()
	var s_hint := GameData.hint_tokens
	var s_boost := GameData.coin_boost
	var s_date := GameData.last_login_date
	var s_lstreak := GameData.login_streak
	GameData.current_user = ""   # 阻止测试触碰真实存档

	# spend_coins 余额判定
	GameData.coins = 100
	_ok(GameData.spend_coins(30), "spend_coins enough -> true")
	_eq(GameData.coins, 70, "spend_coins deducts")
	_ok(not GameData.spend_coins(999), "spend_coins insufficient -> false")
	_eq(GameData.coins, 70, "spend_coins no change when short")

	# 头像解锁
	GameData.owned_avatars = ["player"]
	GameData.coins = 200
	_ok(GameData.unlock_avatar("tree", 120), "unlock_avatar ok")
	_ok(GameData.has_avatar("tree"), "unlock_avatar grants")
	_eq(GameData.coins, 80, "unlock_avatar charges")
	_ok(not GameData.unlock_avatar("tree", 120), "unlock_avatar no double-buy")

	# 道具库存
	GameData.hint_tokens = 0
	GameData.add_hint_tokens(2)
	_eq(GameData.hint_tokens, 2, "add_hint_tokens")
	_ok(GameData.consume_hint_token(), "consume_hint_token ok")
	_eq(GameData.hint_tokens, 1, "consume_hint_token decrements")
	GameData.coin_boost = 0
	GameData.add_coin_boosts(1)
	_ok(GameData.consume_coin_boost(), "consume_coin_boost ok")

	# 每日登录
	GameData.last_login_date = ""
	GameData.login_streak = 0
	_ok(GameData.daily_available(), "daily_available first time")
	var r := GameData.claim_daily()
	_ok(bool(r.get("ok", false)), "claim_daily ok")
	_eq(GameData.login_streak, 1, "claim_daily streak=1")
	_ok(not GameData.daily_available(), "daily_available false after claim")
	_ok(not bool(GameData.claim_daily().get("ok", true)), "claim_daily twice blocked")

	# 勋章判定改用累计金币(规则在 PlayerRules，GameData._medal_ctx() 汇总快照)
	GameData.coins_earned = 999
	_ok(not PlayerRules.medal_met("coins_1000", GameData._medal_ctx()), "coins_1000 needs earned>=1000")
	GameData.coins_earned = 1000
	_ok(PlayerRules.medal_met("coins_1000", GameData._medal_ctx()), "coins_1000 met at earned=1000")

	GameData.coins = s_coins
	GameData.coins_earned = s_earned
	GameData.owned_avatars = s_owned
	GameData.hint_tokens = s_hint
	GameData.coin_boost = s_boost
	GameData.last_login_date = s_date
	GameData.login_streak = s_lstreak
	GameData.current_user = saved_user

## A4 第一刀：纯规则层 PlayerRules(称号/等级/星级统计/勋章/防刷公式)。
## 全部用构造数据单测，不依赖存档状态——GameData 门面的一致性由 _test_anti_farm 等既有用例覆盖。
func _test_player_rules() -> void:
	# —— 称号阶梯(按满星比例达成) ——
	var mx := 100
	_eq(PlayerRules.rank_index(0, mx), 0, "rank 0★ -> 窥数者")
	_eq(PlayerRules.rank_index(5, mx), 0, "rank 5/100 still 窥数者(6% 未达)")
	_eq(PlayerRules.rank_index(6, mx), 1, "rank 6/100 -> 演算者")
	_eq(PlayerRules.rank_index(15, mx), 2, "rank 15/100 -> 衍算师")
	_eq(PlayerRules.rank_index(mx, mx), PlayerRules.RANKS.size() - 1, "rank 全满星 -> 顶阶")
	_eq(PlayerRules.rank_index(0, 0), 0, "max=0 守卫为 1 不崩")
	var rp: Dictionary = PlayerRules.rank_progress(6, mx)
	_eq(rp["title"], "演算者", "rank_progress 当前称号")
	_eq(rp["next_title"], "衍算师", "rank_progress 下一称号")
	_eq(rp["need"], 9, "6★/100 距 15% 还需 9★")
	rp = PlayerRules.rank_progress(mx, mx)
	_eq(rp["next_title"], "", "顶阶 next_title 空")
	_eq(rp["need"], 0, "顶阶 need=0")

	# —— 玩家等级(每 8 星升 1 级) ——
	_eq(PlayerRules.player_level(0), 1, "lv 0★ -> 1")
	_eq(PlayerRules.player_level(8), 2, "lv 8★ -> 2")
	_eq(PlayerRules.player_level(17), 3, "lv 17★ -> 3")
	var lp: Dictionary = PlayerRules.level_progress(10)
	_eq(lp["level"], 2, "level_progress.level")
	_eq(lp["cur"], 2, "level_progress.cur")
	_eq(lp["span"], 8, "level_progress.span")
	_ok(absf(float(lp["ratio"]) - 0.25) < 0.0001, "level_progress.ratio=2/8")

	# —— 星级统计(构造课程) ——
	var ch := { "levels": [ { "id": "a" }, { "id": "b" }, { "id": "c_boss" } ] }
	var st := { "a": 1, "b": 3, "c_boss": 3 }
	_eq(PlayerRules.chapter_stars(ch, st), 7, "chapter_stars 累加")
	_eq(PlayerRules.chapter_max_stars(ch), 9, "chapter_max_stars = 关数×3")
	_eq(PlayerRules.chapter_stars({ "levels": [] }, st), 0, "空章 stars=0")
	_eq(PlayerRules.cleared_level_count([ch], st), 3, "cleared 计 ≥1★")
	_eq(PlayerRules.full_star_level_count([ch], st), 2, "full_star 计 =3★")
	_eq(PlayerRules.boss_level_ids([ch]), ["c_boss"], "boss ids 按 _boss 后缀")
	_eq(PlayerRules.boss_cleared_count([ch], st), 1, "boss_cleared 计数")
	var chs := [ { "levels": [ { "id": "x" }, { "id": "y" } ] }, { "levels": [ { "id": "z" } ] } ]
	_ok(not PlayerRules.chapter_master_any(chs, { "x": 3, "y": 2, "z": 2 }), "chapter_master_any 两章均差星为 false")
	_ok(PlayerRules.chapter_master_any(chs, { "x": 3, "y": 2, "z": 3 }), "chapter_master_any 第 2 章满星即 true")

	# —— 勋章判定(构造 ctx 快照) ——
	var ctx := {
		"cleared": 10, "full_star": 1, "total_stars": 50, "total_questions": 60,
		"accuracy": 0.85, "coins_earned": 999, "pet_fed": 3,
		"boss_total": 5, "boss_cleared": 1, "chapter_master": false,
	}
	_ok(PlayerRules.medal_met("first_clear", ctx), "medal first_clear 达成")
	_ok(PlayerRules.medal_met("clear_10", ctx), "medal clear_10 达成(=10)")
	_ok(not PlayerRules.medal_met("clear_30", ctx), "medal clear_30 未达")
	_ok(PlayerRules.medal_met("perfect_1", ctx), "medal perfect_1 达成")
	_ok(not PlayerRules.medal_met("perfect_10", ctx), "medal perfect_10 未达")
	_ok(not PlayerRules.medal_met("chapter_master", ctx), "medal chapter_master 未达")
	_ok(PlayerRules.medal_met("stars_50", ctx), "medal stars_50 达成(=50)")
	_ok(not PlayerRules.medal_met("stars_150", ctx), "medal stars_150 未达")
	_ok(not PlayerRules.medal_met("answer_100", ctx), "medal answer_100 未达(60<100)")
	_ok(PlayerRules.medal_met("accuracy_80", ctx), "medal accuracy_80 达成(60题85%)")
	_ok(not PlayerRules.medal_met("coins_1000", ctx), "medal coins_1000 未达(999)")
	_ok(PlayerRules.medal_met("boss_first", ctx), "medal boss_first 达成")
	_ok(not PlayerRules.medal_met("boss_all", ctx), "medal boss_all 未达(1/5)")
	_ok(PlayerRules.medal_met("pet_3", ctx), "medal pet_3 达成(=3)")
	ctx["boss_cleared"] = 5
	_ok(PlayerRules.medal_met("boss_all", ctx), "medal boss_all 5/5 达成")
	ctx["total_questions"] = 20
	ctx["accuracy"] = 0.95
	_ok(not PlayerRules.medal_met("accuracy_80", ctx), "accuracy_80 需满 50 题")
	ctx["boss_total"] = 0
	ctx["boss_cleared"] = 0
	_ok(not PlayerRules.medal_met("boss_all", ctx), "boss_all 课程无 Boss 时不达成")
	_ok(not PlayerRules.medal_met("no_such_medal", ctx), "未知勋章 id 判定 false")
	_eq(PlayerRules.medal_def("clear_10").get("name", ""), "小有心得", "medal_def 查表")
	_eq(PlayerRules.medal_def("nope").size(), 0, "medal_def 未知 id 空字典")

	# —— 防刷公式(C1/C2) ——
	_eq(PlayerRules.star_cap(0), 3, "star_cap 当日第 1 次前=3")
	_eq(PlayerRules.star_cap(2), 3, "star_cap 2 次内=3")
	_eq(PlayerRules.star_cap(3), 2, "star_cap 第 3 次起=2")
	_eq(PlayerRules.repeat_grant(100, 0), 30, "repeat_grant ×0.3")
	_eq(PlayerRules.repeat_grant(100, 2), 30, "repeat_grant 3 次内仍折扣")
	_eq(PlayerRules.repeat_grant(100, 3), 0, "repeat_grant 当日封顶=0")
	_eq(PlayerRules.repeat_grant(0, 0), 0, "repeat_grant 基数 0")
	_eq(PlayerRules.repeat_grant(-10, 0), 0, "repeat_grant 负基数守卫")

## A4 第二刀：经济结算纯规则 EconomyRules(星级经验/登录/结算判定/消费/任务进度)。
## 全部构造数据单测；GameData 门面行为由既有 _test_economy/_test_anti_farm/_test_daily 回归保护。
func _test_economy_rules() -> void:
	# —— 星级 → 经验(C1：只按新增星计发) ——
	_eq(EconomyRules.exp_for_star_gain(0, 3), 30, "exp 0->3 = 30")
	_eq(EconomyRules.exp_for_star_gain(2, 3), 10, "exp 2->3 = 10")
	_eq(EconomyRules.exp_for_star_gain(3, 3), 0, "exp 重复通关 = 0")
	_eq(EconomyRules.exp_for_star_gain(3, 1), 0, "exp 星级不回退不倒扣")

	# —— 每日登录：连击推进 ——
	_eq(EconomyRules.next_login_streak(5, "2026-10-20", "2026-10-20"), 6, "streak 昨天签到 -> +1")
	_eq(EconomyRules.next_login_streak(5, "2026-10-18", "2026-10-20"), 1, "streak 断签 -> 1")
	_eq(EconomyRules.next_login_streak(0, "", "2026-10-20"), 1, "streak 首次 -> 1")

	# —— 每日登录：奖励数值(基数 50/20，每日 +20%) ——
	var rw: Dictionary = EconomyRules.login_reward(1)
	_eq(rw["coins"], 50, "login 第1天金币 50")
	_eq(rw["exp"], 20, "login 第1天经验 20")
	rw = EconomyRules.login_reward(2)
	_eq(rw["coins"], 60, "login 第2天金币 60")
	_eq(rw["exp"], 24, "login 第2天经验 24")
	rw = EconomyRules.login_reward(6)
	_eq(rw["coins"], 100, "login 第6天金币 100")
	_eq(rw["exp"], 40, "login 第6天经验 40")

	# —— 关卡结算判定(C1/C2) ——
	var res: Dictionary = EconomyRules.settle_grant(100, 3, 0, "2026-10-21", "2026-10-19", 2)
	_eq(res["granted"], 100, "settle 首达全额")
	_ok(bool(res["full"]), "settle 首达 full=true")
	_eq(res["paid_date"], "2026-10-19", "settle 首达 paid_date 不动")
	_eq(res["paid_today"], 2, "settle 首达 paid_today 不动")
	res = EconomyRules.settle_grant(100, 2, 3, "2026-10-21", "2026-10-21", 0)
	_eq(res["granted"], 30, "settle 重复第1次 30")
	_eq(res["paid_today"], 1, "settle 重复计数 +1")
	res = EconomyRules.settle_grant(100, 2, 3, "2026-10-21", "2026-10-21", PlayerRules.REPEAT_PAID_PER_DAY)
	_eq(res["granted"], 0, "settle 当日封顶 0")
	_eq(res["paid_today"], PlayerRules.REPEAT_PAID_PER_DAY, "settle 封顶不再计数")
	res = EconomyRules.settle_grant(100, 2, 3, "2026-10-21", "2026-10-20", 3)
	_eq(res["granted"], 30, "settle 跨天重置后再发 30")
	_eq(res["paid_date"], "2026-10-21", "settle 跨天 paid_date 更新")
	_eq(res["paid_today"], 1, "settle 跨天计数从 1")
	res = EconomyRules.settle_grant(0, 3, 0, "2026-10-21", "", 0)
	_eq(res["granted"], 0, "settle 基数 0")
	res = EconomyRules.settle_grant(-10, 3, 0, "2026-10-21", "", 0)
	_eq(res["granted"], 0, "settle 负基数守卫")

	# —— 消费判定 ——
	_ok(EconomyRules.can_spend(100, 50), "can_spend 余额足")
	_ok(not EconomyRules.can_spend(100, 150), "can_spend 余额不足")
	_ok(EconomyRules.can_spend(50, 50), "can_spend 正好等于余额")
	_ok(EconomyRules.can_spend(0, 0), "can_spend 0 费用")
	_ok(EconomyRules.can_spend(0, -5), "can_spend 负费用恒 true")
	_ok(not EconomyRules.can_spend(0, 1), "can_spend 0 余额支付")

	# —— 每日任务进度 ——
	_eq(EconomyRules.mission_progress("streak", 20, 7, 0, 999), 7, "mission streak 取峰值")
	_eq(EconomyRules.mission_progress("streak", 20, 25, 0, 999), 20, "mission streak 封顶 goal")
	_eq(EconomyRules.mission_progress("answers", 10, 0, 100, 105), 5, "mission 当日增量")
	_eq(EconomyRules.mission_progress("answers", 10, 0, 100, 100), 0, "mission 无增量 0")
	_eq(EconomyRules.mission_progress("answers", 10, 0, 105, 100), 0, "mission 指标回退守卫 0")
	_eq(EconomyRules.mission_progress("answers", 10, 0, 100, 130), 10, "mission 超额封顶 goal")

## A4 第三刀：萌宠养成纯规则 PetRules(好感分层/饥饿/标签/跨会话衰减/投喂)。全部构造数据单测。
func _test_pet_rules() -> void:
	# —— 好感度分层(投喂次数 3/8 分界) ——
	_eq(PetRules.affection_tier(0), 0, "tier 0 次 = 初识")
	_eq(PetRules.affection_tier(2), 0, "tier 2 次 = 初识")
	_eq(PetRules.affection_tier(3), 1, "tier 3 次 = 熟悉")
	_eq(PetRules.affection_tier(7), 1, "tier 7 次 = 熟悉")
	_eq(PetRules.affection_tier(8), 2, "tier 8 次 = 黏人")
	_eq(PetRules.affection_tier(99), 2, "tier 99 次 = 黏人")

	# —— 饥饿判定(0.35 边界) ——
	_ok(PetRules.is_hungry(0.34), "hungry 0.34")
	_ok(not PetRules.is_hungry(0.35), "hungry 0.35 边界不算饿")
	_ok(not PetRules.is_hungry(0.9), "hungry 0.9")

	# —— 状态标签 ——
	_eq(PetRules.mood_label(0.75), "开心", "mood 0.75 开心")
	_eq(PetRules.mood_label(0.5), "一般", "mood 0.5 一般")
	_eq(PetRules.mood_label(0.44), "低落", "mood 0.44 低落")
	_eq(PetRules.satiety_label(0.7), "吃饱", "satiety 0.7 吃饱")
	_eq(PetRules.satiety_label(0.5), "半饱", "satiety 0.5 半饱")
	_eq(PetRules.satiety_label(0.39), "好饿", "satiety 0.39 好饿")

	# —— 跨会话衰减 ——
	var d: Dictionary = PetRules.decay(1.0, 0.8, 0.0)
	_ok(is_equal_approx(float(d["satiety"]), 1.0) and is_equal_approx(float(d["mood"]), 0.8),
		"decay 0 天原样返回")
	d = PetRules.decay(1.0, 0.8, 1.0)
	_ok(is_equal_approx(float(d["satiety"]), 0.68), "decay 1 天饱食 1.0->0.68")
	_ok(is_equal_approx(float(d["mood"]), 0.55), "decay 1 天心情回到基准 0.55")
	d = PetRules.decay(1.0, 0.9, 0.5)
	_ok(is_equal_approx(float(d["mood"]), 0.725), "decay 半天心情 lerp -> 0.725")
	d = PetRules.decay(0.2, 0.9, 30.0)
	_ok(is_equal_approx(float(d["satiety"]), 0.15), "decay 30 天饱食地板 0.15")
	_ok(is_equal_approx(float(d["mood"]), 0.55), "decay 30 天心情=基准")
	d = PetRules.decay(1.0, 0.1, 0.01)
	_ok(is_equal_approx(float(d["mood"]), 0.2), "decay 心情地板 0.2")
	d = PetRules.decay(1.0, 0.3, 1.0)
	_ok(is_equal_approx(float(d["mood"]), 0.55), "心情低于基准时向基准回升")

	# —— 投喂心情 ——
	_ok(is_equal_approx(PetRules.feed_mood(0.5), 0.62), "feed 心情 +0.12")
	_ok(is_equal_approx(PetRules.feed_mood(0.9), 1.0), "feed 心情封顶 1.0")

## A4 第三刀：领域掌握度纯公式 MasteryRules(错题权重/单关掌握度/领域均值/阈值)。
func _test_mastery_rules() -> void:
	# —— 错题权重(0.1/次，封顶 0.5) ——
	_ok(is_equal_approx(MasteryRules.mistake_weight(0), 0.0), "mistake 0 次 = 0")
	_ok(is_equal_approx(MasteryRules.mistake_weight(3), 0.3), "mistake 3 次 = 0.3")
	_ok(is_equal_approx(MasteryRules.mistake_weight(5), 0.5), "mistake 5 次 = 0.5 封顶")
	_ok(is_equal_approx(MasteryRules.mistake_weight(9), 0.5), "mistake 9 次仍 0.5")

	# —— 单关掌握度(0.65 星级 + 0.25 清关 - 惩罚) ——
	_ok(is_equal_approx(MasteryRules.level_mastery(0, 3, 3, 0.0), 0.0), "mastery 未通关恒 0")
	_ok(is_equal_approx(MasteryRules.level_mastery(3, 3, 3, 0.0), 0.9), "mastery 满表现 0.9")
	var expect := 0.65 / 3.0 + 0.25 * 2.0 / 3.0 - 0.3
	_ok(absf(MasteryRules.level_mastery(1, 2, 3, 0.3) - expect) < 0.0001, "mastery 1星 对2/3 错0.3 加权")
	_ok(is_equal_approx(MasteryRules.level_mastery(3, 3, 3, 1.0), 0.5), "mastery 错题惩罚封顶 0.4")
	_ok(is_equal_approx(MasteryRules.level_mastery(3, 0, 3, 0.4), 0.25), "mastery 全错清关 0.25")
	_ok(is_equal_approx(MasteryRules.level_mastery(3, 0, 0, 0.0), 0.65), "mastery 无记录除零守卫")
	_ok(is_equal_approx(MasteryRules.level_mastery(1, 0, 0, 5.0), 0.0), "mastery 惩罚过深 clamp 下界 0")

	# —— 领域均值 ——
	_ok(is_equal_approx(MasteryRules.domain_mean(2.0, 4), 0.5), "domain_mean 2/4 = 0.5")
	_ok(is_equal_approx(MasteryRules.domain_mean(0.0, 0), 0.0), "domain_mean 空 = 0 不除零")

	# —— 达标/生疏阈值(萌宠部件解锁与生疏判定的单一来源) ——
	_ok(is_equal_approx(MasteryRules.MASTERY_UNLOCK, 0.5), "解锁阈值 0.5")
	_ok(is_equal_approx(MasteryRules.MASTERY_STALE, 0.35), "生疏阈值 0.35")

## A4 第四刀：StageBase 结算纯规则 StageRules(星级判定/奖励合成/评级/首通/极速)。全部构造数据单测。
func _test_stage_rules() -> void:
	# —— 星级判定：正确率 0.8 / 0.6 分界 ——
	_eq(StageRules.judge_stars(8, 10, false, false, 0.0, 0.0, false, 3)["stars"], 3, "stars 8/10 = 3")
	_eq(StageRules.judge_stars(6, 10, false, false, 0.0, 0.0, false, 3)["stars"], 2, "stars 6/10 = 2")
	_eq(StageRules.judge_stars(5, 10, false, false, 0.0, 0.0, false, 3)["stars"], 0, "stars 5/10 = 0")
	_eq(StageRules.judge_stars(0, 0, false, false, 0.0, 0.0, false, 3)["stars"], 0, "stars 0 关 = 0")
	# 陷阱扣 1 星
	_eq(StageRules.judge_stars(8, 10, true, false, 0.0, 0.0, false, 3)["stars"], 2, "stars 陷阱 3->2")
	_eq(StageRules.judge_stars(6, 10, true, false, 0.0, 0.0, false, 3)["stars"], 1, "stars 陷阱 2->1")
	_eq(StageRules.judge_stars(5, 10, true, false, 0.0, 0.0, false, 3)["stars"], 0, "stars 陷阱 0 不变")
	# 超时降 1 星（保底 1）
	var j: Dictionary = StageRules.judge_stars(8, 10, false, true, 30.0, 40.0, false, 3)
	_eq(j["stars"], 2, "stars 超时 3->2")
	_ok(bool(j["time_capped"]), "time_capped 超时置位")
	j = StageRules.judge_stars(6, 10, false, true, 30.0, 40.0, false, 3)
	_eq(j["stars"], 1, "stars 超时 2->1 保底")
	# 用时刚好等于限时不降
	j = StageRules.judge_stars(8, 10, false, true, 30.0, 30.0, false, 3)
	_eq(j["stars"], 3, "stars 用时=限时不降")
	_ok(not bool(j["time_capped"]), "time_capped 未超时不置位")
	# 0 星不判超时
	j = StageRules.judge_stars(5, 10, false, true, 30.0, 40.0, false, 3)
	_ok(not bool(j["time_capped"]), "time_capped 0 星不置位")
	# 守关失败归 0
	_eq(StageRules.judge_stars(8, 10, false, false, 0.0, 0.0, true, 3)["stars"], 0, "stars 守关失败归 0")
	# 当日重试上限（C2）
	j = StageRules.judge_stars(8, 10, false, false, 0.0, 0.0, false, 2)
	_eq(j["stars"], 2, "stars 重试上限 2")
	_ok(bool(j["star_capped"]), "star_capped 置位")
	j = StageRules.judge_stars(6, 10, false, false, 0.0, 0.0, false, 2)
	_ok(not bool(j["star_capped"]), "star_capped 未超上限不置位")

	# —— 奖励合成 ——
	# 2 关零失误 3 星 连击 3：30+30+60 → +60 满星 → +30 无陷阱 → +9 连击 = 219
	var rw: Dictionary = StageRules.compose_reward(2, 3, false, 3, 0, false, 1.0, false)
	_eq(rw["reward"], 219, "reward 基础合成 219")
	_eq(rw["speed_bonus"], 0, "reward 无极速 0")
	_eq(rw["combo_bonus"], 0, "reward 无连击倍率 0")
	# 极速 +40 → 259；连击 ×1.2 → +round(259×0.2)=52 → 311；翻倍 → 622
	rw = StageRules.compose_reward(2, 3, false, 3, 0, true, 1.2, false)
	_eq(rw["reward"], 311, "reward 极速+连击 311")
	_eq(rw["speed_bonus"], 40, "reward 极速 40")
	_eq(rw["combo_bonus"], 52, "reward 连击 52")
	rw = StageRules.compose_reward(2, 3, false, 3, 0, true, 1.2, true)
	_eq(rw["reward"], 622, "reward 翻倍 622")
	# 0 星踩陷阱：只剩基础 30
	rw = StageRules.compose_reward(0, 0, true, 0, 0, false, 1.0, false)
	_eq(rw["reward"], 30, "reward 失败底价 30")
	# 首通 +200：30+15+60+60+200 = 365
	rw = StageRules.compose_reward(1, 3, true, 0, 200, false, 1.0, false)
	_eq(rw["reward"], 365, "reward 首通 +200")

	# —— Boss 首通判定 ——
	_ok(StageRules.boss_first_clear(true, 3, 0), "首通 boss 3 星 prev0")
	_ok(not StageRules.boss_first_clear(true, 0, 0), "首通 0 星不算")
	_ok(not StageRules.boss_first_clear(true, 3, 2), "首通 有历史不算")
	_ok(not StageRules.boss_first_clear(false, 3, 0), "首通 非 boss 不算")

	# —— 极速奖励判定 ——
	_ok(StageRules.speed_bonus_ok(3, true, 30.0, 30.0), "speed 用时=星时可拿")
	_ok(not StageRules.speed_bonus_ok(3, true, 30.0, 30.1), "speed 超时不可拿")
	_ok(not StageRules.speed_bonus_ok(0, true, 30.0, 10.0), "speed 0 星不可拿")
	_ok(not StageRules.speed_bonus_ok(3, false, 30.0, 10.0), "speed 非限时不可拿")
	_ok(not StageRules.speed_bonus_ok(3, true, 0.0, 10.0), "speed 星时未设不可拿")

	# —— 评级 ——
	_eq(StageRules.grade(3, 3, 3, false), "S", "grade 3星全对无陷阱 S")
	_eq(StageRules.grade(3, 2, 3, false), "A", "grade 3星非全对 A")
	_eq(StageRules.grade(3, 3, 3, true), "A", "grade 3星踩陷阱 A")
	_eq(StageRules.grade(2, 3, 3, false), "B", "grade 2星 B")
	_eq(StageRules.grade(1, 3, 3, false), "C", "grade 1星 C")
	_eq(StageRules.grade(0, 3, 3, false), "C", "grade 0星 C")

	# —— 选项乱序判定 ——
	_ok(StageRules.shuffle_allowed({}, ["A", "B"]), "shuffle 默认可乱序")
	_ok(not StageRules.shuffle_allowed({ "shuffle": false }, ["A", "B"]), "shuffle:false 关闭")
	_ok(not StageRules.shuffle_allowed({ "fixed": true }, ["A", "B"]), "fixed:true 关闭")
	_ok(not StageRules.shuffle_allowed({}, ["A"]), "shuffle 单选项关闭")
	_ok(not StageRules.shuffle_allowed({}, ["A", "以上都对"]), "shuffle 含『以上』关闭")
	_ok(not StageRules.shuffle_allowed({}, ["A", "B", "以下都不正确"]), "shuffle 含『以下』关闭")
	_ok(not StageRules.shuffle_allowed({}, ["A", "都对"]), "shuffle 含『都对』关闭")

	# 顺序：禁止乱序 → 恒等；允许 → 仍是 0..n-1 的排列
	_eq(StageRules.order_for({ "shuffle": false }, ["A", "B", "C"]), [0, 1, 2], "order 关闭乱序恒等")
	var perm: Array = StageRules.order_for({}, ["A", "B", "C", "D"])
	_eq(perm.size(), 4, "order 乱序长度不变")
	var sorted_perm := perm.duplicate()
	sorted_perm.sort()
	_eq(sorted_perm, [0, 1, 2, 3], "order 乱序是排列(不丢不重)")
	_eq(StageRules.order_for({}, ["A"]), [0], "order 单选项恒等")

	# —— 多选判定(集合语义) ——
	_ok(StageRules.multi_ok([0, 2], [2, 0]), "multi 顺序无关")
	_ok(StageRules.multi_ok([], []), "multi 双空为真")
	_ok(not StageRules.multi_ok([0], [0, 2]), "multi 漏选为假")
	_ok(not StageRules.multi_ok([0, 1, 2], [0, 2]), "multi 多选为假")
	_ok(not StageRules.multi_ok([0, 0], [0, 2]), "multi 重复选不凑数")
	_ok(StageRules.multi_ok([1], [1]), "multi 单选集合")

	# —— 填空容差 ——
	_ok(StageRules.num_ok(1.0, 1.0, 0.05), "num 完全相等")
	_ok(StageRules.num_ok(1.04, 1.0, 0.05), "num 容差内")
	_ok(StageRules.num_ok(1.5, 1.0, 0.5), "num 恰好容差(精确可表示)")
	_ok(not StageRules.num_ok(1.06, 1.0, 0.05), "num 超出容差")
	_ok(StageRules.num_ok(-2.0, -2.03, 0.05), "num 负数容差")
	_ok(not StageRules.num_ok(2.0, -2.0, 0.05), "num 正负号不同")

	# —— 填空解析 StageRules.parse_math / norm_math ——
	_ok(is_equal_approx(float(StageRules.parse_math("3.5")), 3.5), "parse 整数小数")
	_ok(is_equal_approx(float(StageRules.parse_math("1/2")), 0.5), "parse 分数")
	_ok(is_equal_approx(float(StageRules.parse_math("1/3")), 1.0 / 3.0), "parse 1/3")
	_ok(is_equal_approx(float(StageRules.parse_math("2²")), 4.0), "parse 上标平方")
	_ok(is_equal_approx(float(StageRules.parse_math("2³")), 8.0), "parse 上标立方")
	_ok(is_equal_approx(float(StageRules.parse_math("2^3")), 8.0), "parse 幂 pow 化")
	_ok(is_equal_approx(float(StageRules.parse_math("2×3")), 6.0), "parse 乘号 ×")
	_ok(is_equal_approx(float(StageRules.parse_math("6÷3")), 2.0), "parse 除号 ÷")
	_ok(is_equal_approx(float(StageRules.parse_math("−5")), -5.0), "parse 减号 −")
	_ok(is_equal_approx(float(StageRules.parse_math("(1+2)×3")), 9.0), "parse 括号乘法")
	_ok(is_equal_approx(float(StageRules.parse_math("√9")), 3.0), "parse √数字")
	_ok(is_equal_approx(float(StageRules.parse_math("√(9)")), 3.0), "parse √括号")
	_ok(is_equal_approx(float(StageRules.parse_math("π")), 3.141592653589793), "parse π 常数")
	_ok(StageRules.parse_math("") == null, "parse 空串 null")
	_ok(StageRules.parse_math("   ") == null, "parse 全空白 null")
	_ok(StageRules.parse_math("abc") == null, "parse 非法表达式 null")
	_ok(StageRules.parse_math("(1+2") == null, "parse 括号不配 null")
	_ok(is_equal_approx(float(StageRules.parse_math("5+3")), 8.0), "parse 整数相加")
	_ok(is_equal_approx(float(StageRules.parse_math("3.5+1")), 4.5), "parse 小数不被 float 化破坏")
	_ok(is_equal_approx(float(StageRules.parse_math("1/2/3")), 1.0 / 6.0), "parse 连续除法左结合")
	_eq(StageRules.norm_math("2 × 3"), "2*3", "norm 去空格换乘号")
	_eq(StageRules.norm_math("10 − 3"), "10-3", "norm 统一减号")
	_eq(StageRules.norm_math("2²"), "pow(2,2)", "norm 上标转 pow")
	_eq(StageRules.norm_math("2π"), "23.141592653589793", "norm π 展开(已知怪癖:数字前不插 *)")

## A4 第六刀：知识树布局纯规则 TreeRules(关卡分组/Catmull-Rom 平滑)。全部构造数据单测。
func _test_tree_rules() -> void:
	# —— 分组："N-M" 编号 + 单元标题 + Boss 殿后 ——
	var levels: Array = [
		{ "id": "a", "name": "1-1 集合的含义" },
		{ "id": "b", "name": "1-2 集合的运算" },
		{ "id": "c", "name": "2-1 命题" },
		{ "id": "d", "name": "隐藏Boss · 终局" },
	]
	var groups: Array = TreeRules.disasm_groups(levels, ["集合单元", "命题单元"], "集合论")
	_eq(groups.size(), 3, "tree 3 组(含 Boss)")
	_eq(groups[0]["title"], "集合单元", "tree 组 0 标题")
	_eq(groups[0]["items"].size(), 2, "tree 组 0 两关")
	_eq(groups[0]["items"][0]["code"], "1-1", "tree code 1-1")
	_eq(groups[0]["items"][1]["code"], "1-2", "tree code 1-2")
	_eq(groups[1]["items"][0]["code"], "2-1", "tree code 2-1")
	_ok(bool(groups[2]["boss"]), "tree Boss 组标记")
	_eq(groups[2]["title"], "隐藏挑战", "tree Boss 标题")
	_eq(groups[2]["items"][0]["title"], "终局", "tree Boss 名清理")

	# —— 显式 group 字段优先，无编号用顺序号 ——
	levels = [
		{ "id": "a", "name": "集合的交并补", "group": "基本概念" },
		{ "id": "b", "name": "2-1 命题", "group": "基本概念" },
		{ "id": "c", "name": "3-1 推理", "group": "推理" },
	]
	groups = TreeRules.disasm_groups(levels, [], "集合论")
	_eq(groups.size(), 2, "tree 显式 group 两组")
	_eq(groups[0]["title"], "基本概念", "tree 显式组名")
	_eq(groups[0]["items"][0]["code"], "01", "tree 无编号用顺序号")
	_eq(groups[0]["items"][1]["code"], "2-1", "tree 有编号仍用 N-M")
	_eq(groups[1]["title"], "推理", "tree 第二显式组名")
	_eq(groups[1]["items"][0]["code"], "3-1", "tree 有编号仍用 N-M")

	# —— 单组回退模块标题；多组回退「单元 N」——
	groups = TreeRules.disasm_groups([{ "id": "a", "name": "1-1 甲" }], [], "集合论")
	_eq(groups.size(), 1, "tree 单组")
	_eq(groups[0]["title"], "集合论", "tree 单组回退模块名")
	groups = TreeRules.disasm_groups([
		{ "id": "a", "name": "1-1 甲" },
		{ "id": "b", "name": "2-1 乙" },
	], [], "X")
	_eq(groups[0]["title"], "单元 1", "tree 多组回退单元 1")
	_eq(groups[1]["title"], "单元 2", "tree 多组回退单元 2")

	# —— 只有 Boss / 空列表 ——
	groups = TreeRules.disasm_groups([{ "id": "x", "name": "隐藏Boss · 唯一" }], [], "X")
	_eq(groups.size(), 1, "tree 只有 Boss 也成组")
	_ok(bool(groups[0]["boss"]), "tree 只有 Boss 标记")
	_eq(groups[0]["title"], "隐藏挑战", "tree 只有 Boss 标题")
	_eq(groups[0]["items"][0]["title"], "唯一", "tree 只有 Boss 名清理")
	_eq(TreeRules.disasm_groups([], [], "X").size(), 0, "tree 空列表")

	# —— 关卡元数据透传 ——
	groups = TreeRules.disasm_groups([
		{ "id": "a", "name": "1-1 集合", "technique": "韦恩图", "optional": true, "after": "lvl_x" },
	], [], "X")
	_eq(groups[0]["items"][0]["li"], 0, "tree li 透传")
	_eq(groups[0]["items"][0]["technique"], "韦恩图", "tree technique 透传")
	_ok(bool(groups[0]["items"][0]["optional"]), "tree optional 透传")
	_eq(groups[0]["items"][0]["after"], "lvl_x", "tree after 透传")

	# —— Catmull-Rom 平滑 ——
	_eq(TreeRules.catmull_rom(PackedVector2Array(), 12).size(), 0, "curve 空输入")
	_eq(TreeRules.catmull_rom(PackedVector2Array([Vector2(3, 4)]), 12).size(), 1, "curve 单点原样")
	var c2 := TreeRules.catmull_rom(PackedVector2Array([Vector2(0, 0), Vector2(10, 0)]), 2)
	_eq(c2.size(), 3, "curve 两点 2 段/段 → 3 点")
	_ok(c2[0].is_equal_approx(Vector2(0, 0)), "curve 起点保留")
	_ok(c2[1].is_equal_approx(Vector2(5, 0)), "curve 中点 5")
	_ok(c2[2].is_equal_approx(Vector2(10, 0)), "curve 终点保留")
	var c3 := TreeRules.catmull_rom(PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(20, 0)]), 4)
	_eq(c3.size(), 9, "curve 三点 4 段/段 → 9 点")
	_ok(c3[0].is_equal_approx(Vector2(0, 0)) and c3[8].is_equal_approx(Vector2(20, 0)), "curve 三端点保留")
	var flat := true
	for p in c3:
		if absf(p.y) > 0.0001:
			flat = false
	_ok(flat, "curve 共线点保持直线")
	var c4 := TreeRules.catmull_rom(PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(20, 0)]), 1)
	_eq(c4.size(), 3, "curve per_seg=1 点数=输入")
	_ok(c4[0].is_equal_approx(Vector2(0, 0)) and c4[1].is_equal_approx(Vector2(10, 0)) and c4[2].is_equal_approx(Vector2(20, 0)),
		"curve per_seg=1 恒等")

	# —— 解锁判定 level_unlocked / region_stars / level_li_by_id ——
	var ulv: Array = [
		{ "id": "l1", "name": "1-1 甲" },
		{ "id": "l2", "name": "1-2 乙" },
		{ "id": "l3", "name": "隐藏Boss · 丙", "gate": { "need_stars": 3 } },
	]
	_ok(TreeRules.level_unlocked(0, ulv, {}, false), "unlock 首关恒开")
	_ok(TreeRules.level_unlocked(0, ulv, {}, true), "unlock 首关自由模式")
	_ok(not TreeRules.level_unlocked(1, ulv, {}, false), "unlock 次关需上一关星")
	_ok(TreeRules.level_unlocked(1, ulv, { "l1": 1 }, false), "unlock 上一关 1 星解锁")
	_ok(not TreeRules.level_unlocked(3, ulv, {}, false), "unlock 越界关卡锁定")
	_ok(TreeRules.level_unlocked(1, ulv, { "l2": 2 }, false), "unlock 已通关可重玩")
	_ok(not TreeRules.level_unlocked(2, ulv, { "l1": 1, "l2": 1 }, false), "unlock Boss 门星数不足")
	_ok(TreeRules.level_unlocked(2, ulv, { "l1": 1, "l2": 2 }, false), "unlock Boss 门星数达标")
	_ok(TreeRules.level_unlocked(2, ulv, { "l3": 1 }, false), "unlock Boss 门已通关可重玩")
	_eq(TreeRules.region_stars(ulv, { "l1": 2, "l3": 1 }), 3, "unlock 区域星数累计")
	_eq(TreeRules.region_stars(ulv, {}), 0, "unlock 区域星数空")
	_eq(TreeRules.level_li_by_id(ulv, "l3"), 2, "unlock 按 id 查索引")
	_eq(TreeRules.level_li_by_id(ulv, "nope"), -1, "unlock 按 id 查不到 -1")
	ulv = [
		{ "id": "l1", "name": "1-1 甲" },
		{ "id": "l2", "name": "1-2 乙", "gate": { "need_stars": 0 } },
	]
	_ok(not TreeRules.level_unlocked(1, ulv, {}, false), "unlock gate=0 回退上一关")
	_ok(TreeRules.level_unlocked(1, ulv, { "l1": 1 }, false), "unlock gate=0 上一关星解锁")

## A2 收编：legacy 场景（SolidChallenge/ConicStage）仍是官方场景——课程表引用的
## method/conic key 必须在对应数据文件里存在（打错 key = 静默空关），且两类场景保持在用。
func _test_legacy_binding() -> void:
	var solid_ids := {}
	var solid = JSON.parse_string(FileAccess.get_file_as_string("res://data/solid_methods.json"))
	if typeof(solid) == TYPE_DICTIONARY and (solid as Dictionary).has("methods"):
		for k in ((solid as Dictionary)["methods"] as Dictionary).keys():
			solid_ids[str(k)] = true
	var conic_ids := {}
	var conic = JSON.parse_string(FileAccess.get_file_as_string("res://data/conic_levels.json"))
	if typeof(conic) == TYPE_DICTIONARY:
		for k in (conic as Dictionary).keys():
			conic_ids[str(k)] = true
	_ok(solid_ids.size() > 0, "收编 solid_methods.json 可解析出 methods")
	_ok(conic_ids.size() > 0, "收编 conic_levels.json 可解析出关卡")
	var n_solid := 0
	var n_conic := 0
	for ch in GameData.chapters:
		for lv in (ch as Dictionary).get("levels", []):
			if typeof(lv) != TYPE_DICTIONARY:
				continue
			var sc := str((lv as Dictionary).get("scene", ""))
			var lid := str((lv as Dictionary).get("id", "?"))
			if sc.ends_with("SolidChallenge.tscn"):
				n_solid += 1
				_ok(solid_ids.has(str((lv as Dictionary).get("method", ""))), "收编 SolidChallenge 绑定 " + lid)
			elif sc.ends_with("ConicStage.tscn"):
				n_conic += 1
				_ok(conic_ids.has(str((lv as Dictionary).get("conic", ""))), "收编 ConicStage 绑定 " + lid)
	_ok(n_solid > 0, "收编 SolidChallenge 仍被课程表引用（%d 关）" % n_solid)
	_ok(n_conic > 0, "收编 ConicStage 仍被课程表引用（%d 关）" % n_conic)

## A4 第九刀：教材章节重排/合并纯规则 CurriculumRules(纯单测,输入显式,不依赖 GameData 状态)。
func _test_curriculum_rules() -> void:
	var raw := [
		{ "id": "k_line", "kind": "knowledge", "title": "直线方程", "levels": [{ "id": "l1" }] },
		{ "id": "m_vec", "kind": "method", "title": "向量法", "levels": [] },
		{ "id": "k_circle", "kind": "knowledge", "title": "圆的方程", "levels": [{ "id": "c1" }] },
	]
	var tb := {
		"method_order": ["m_vec"],
		"knowledge_order": ["k_circle", "k_line"],
		"chapter_book": { "k_line": "b1", "k_circle": "b1", "m_vec": "b2" },
		"chapter_no": { "k_line": "第2章", "k_circle": "第2章", "m_vec": "第1章" },
		"unit_titles": { "b1|第2章": "直线和圆的方程" },
	}
	# —— apply_order：方法在前、知识按版本序；未知版本原样复制 ——
	var out := CurriculumRules.apply_order(raw, tb)
	_eq(out.size(), 3, "order 3 章")
	_eq(out[0]["id"], "m_vec", "order 方法在前")
	_eq(out[1]["id"], "k_circle", "order 知识按版本序")
	_eq(out[2]["id"], "k_line", "order 末位")
	var keep := CurriculumRules.apply_order(raw, {})
	_eq(keep.size(), 3, "order 空定义原样")
	_eq(keep[0]["id"], "k_line", "order 空定义保序")
	# 未列出的章节按原始顺序补齐且不丢；重复列出不重复出现
	var out2 := CurriculumRules.apply_order(raw, { "knowledge_order": ["k_circle"] })
	_eq(out2.size(), 3, "order 未列不丢")
	_eq(out2[0]["id"], "k_circle", "order 列出优先")
	_eq(CurriculumRules.apply_order(raw, { "knowledge_order": ["k_line", "k_line"] }).size(), 3,
		"order 重复列出不重复")
	# —— group_key_of：method/缺项返回 {} ——
	_eq(CurriculumRules.group_key_of({ "id": "m_vec", "kind": "method" }, tb).size(), 0, "gk method 空")
	_eq(CurriculumRules.group_key_of({ "id": "x" }, tb).size(), 0, "gk 缺分册章号 空")
	_eq(str(CurriculumRules.group_key_of({ "id": "k_line" }, tb)["key"]), "b1|第2章", "gk 合并键")
	# —— group_chapters：同分册同章号合并；method 不合并；unit_titles 覆盖标题 ——
	var res := CurriculumRules.group_chapters(out, tb)
	var chs: Array = res["chapters"]
	_eq(chs.size(), 2, "merge 2 卡(直线圆合并+向量)")
	_eq(chs[0]["id"], "m_vec", "merge 方法章独立")
	_eq(chs[1]["id"], "k_circle", "merge 首成员为卡 id")
	_eq(chs[1]["title"], "直线和圆的方程", "merge unit_titles 覆盖标题")
	_eq((chs[1]["levels"] as Array).size(), 2, "merge 两关保留")
	_eq(str((chs[1]["levels"] as Array)[0]["group"]), "圆的方程", "merge 首关 group=原章标题")
	_eq(str((chs[1]["levels"] as Array)[1]["group"]), "直线方程", "merge 次关 group=原章标题")
	var members: Dictionary = res["members"]
	_eq(members["k_circle"].size(), 2, "merge members 两成员")
	# —— chapter_in_domain：合并章按成员归属；无映射按自身 ——
	var d := { "chapters": ["k_line"] }   # domain 列表里是原章 id
	_ok(CurriculumRules.chapter_in_domain("k_circle", d, members), "domain 合并卡按成员归属")
	_ok(not CurriculumRules.chapter_in_domain("m_vec", d, members), "domain 方法章不归属")
	_ok(CurriculumRules.chapter_in_domain("k_line", d, {}), "domain 无合并映射按自身")

## B13 第一步：口播转换器 SpeechRules 单测(纯函数)。三条路径共用一个出口:
## $$LaTeX$$ / {f:名称} / Unicode 数学符号 → 可朗读中文。
func _test_speech_rules() -> void:
	# —— 旧转换器行为保持(回归) ——
	var s1 := SpeechRules.latex_to_speech("\\frac{1}{a}")
	_ok(s1.find("a分之") >= 0, "speech frac 分母在前 " + s1)
	_ok(SpeechRules.latex_to_speech("x^{2}").find("平方") >= 0, "speech 上标平方")
	_ok(SpeechRules.latex_to_speech("\\sqrt{2}").find("根号") >= 0, "speech 根号")
	_ok(SpeechRules.latex_to_speech("|x|").find("绝对值") >= 0, "speech 绝对值")
	_ok(SpeechRules.latex_to_speech("a\\le b").find("小于等于") >= 0, "speech \\le")
	# —— B13 扩展 ——
	_ok(SpeechRules.latex_to_speech("\\dfrac{a}{b}").find("b分之") >= 0, "speech dfrac")
	_ok(SpeechRules.latex_to_speech("a_{n}").find("下标") >= 0, "speech 下标带括号")
	_ok(SpeechRules.latex_to_speech("a_n").find("下标") >= 0, "speech 下标裸写")
	_eq(SpeechRules.latex_to_speech("\\vec{AB}"), "AB向量", "speech 向量")
	_eq(SpeechRules.latex_to_speech("\\bar{x}"), "x拔", "speech 均值横线")
	_eq(SpeechRules.latex_to_speech("\\hat{p}"), "p帽", "speech 估计记号")
	_eq(SpeechRules.latex_to_speech("\\mathbb{R}"), "实数集", "speech 数集 R")
	_ok(SpeechRules.latex_to_speech("A\\Rightarrow B").find("推出") >= 0, "speech 右箭头推出")
	_ok(SpeechRules.latex_to_speech("\\forall x").find("对任意") >= 0, "speech 全称量词")
	_ok(SpeechRules.latex_to_speech("\\chi^{2}").find("卡方") >= 0, "speech 卡方")
	_ok(SpeechRules.latex_to_speech("60^{\\circ}").find("60度") >= 0, "speech 角度不在幂替换前被吃")
	_ok(SpeechRules.latex_to_speech("\\triangle ABC").find("三角形") >= 0, "speech 三角形")
	_eq(SpeechRules.latex_to_speech("\\overline{z}"), "z的共轭", "speech 共轭")
	_ok(SpeechRules.latex_to_speech("\\varnothing").find("空集") >= 0, "speech 空集")
	# —— Unicode 正文符号 ——
	_eq(SpeechRules.unicode_speech("x²≤3"), "x的平方小于等于3", "speech unicode²≤")
	_eq(SpeechRules.unicode_speech("aₙ的极限"), "a下标n的极限", "speech unicode 下标")
	_eq(SpeechRules.unicode_speech("A∪B∩C"), "A并B交C", "speech unicode 并交")
	# —— 统一入口(注入映射) ——
	var out := SpeechRules.strip_formulas("当 $$x>0$$ 时, {f:zzz} 与 x²", { "foo": "甲" }, { "bar": "b^2" })
	_ok(out.find("大于") >= 0, "speech strip $$ 内大于")
	_ok(out.find("公式") >= 0, "speech strip 未知命名回退公式")
	_ok(out.find("平方") >= 0, "speech strip 正文 unicode")
	# —— 盲点命令统计 ——
	_eq(SpeechRules.unmapped_commands("\\foo \\bar \\foo").size(), 1, "speech 盲点去重")
	_eq(SpeechRules.unmapped_commands("\\frac{x}{y}").size(), 0, "speech 已知命令非盲点")

## A19：切用户后会话态不得残留（同进程 A→B 切换仍应有萌宠问候）。
## 会话态 = 不存档变量：pet_greeted_session / pet_away_days / review_focus / _save_pending。
func _test_session_reset() -> void:
	var saved_user := GameData.current_user
	GameData.create_user("a19_a", "player")
	# 模拟 A 用户已问候过萌宠、停在错题深链题号上
	GameData.pet_greeted_session = true
	GameData.pet_away_days = 2.5
	GameData.review_focus = 3
	GameData.create_user("a19_b", "player")
	_ok(not GameData.pet_greeted_session, "切用户后 pet_greeted_session 复位（B 用户仍会得到问候）")
	_eq(GameData.pet_away_days, 0.0, "切用户后 pet_away_days 复位")
	_eq(GameData.review_focus, -1, "切用户后 review_focus 复位")
	# 已登录状态下直接 login 另一个用户，同样复位
	GameData.login("a19_a")
	_eq(GameData.current_user, "a19_a", "login 切回 A")
	GameData.pet_greeted_session = true
	GameData.login("a19_b")
	_ok(not GameData.pet_greeted_session, "login 切用户后复位")
	# logout 也要复位
	GameData.pet_greeted_session = true
	GameData.logout()
	_eq(GameData.current_user, "", "logout 清空当前用户")
	_ok(not GameData.pet_greeted_session, "logout 后复位")
	# 反向：会话复位不得破坏关卡导航（current_level 由 start_level 显式设置，不参与复位）
	GameData.login("a19_a")
	GameData.start_level(0, 1)
	var lid := GameData.current_level_id()
	GameData.logout()
	GameData.login("a19_a")
	_eq(GameData.current_level_id(), lid, "复位会话不关卡导航（current_level 由 start_level 设置）")
	GameData.delete_user("a19_a")
	GameData.delete_user("a19_b")
	if saved_user != "":
		GameData.login(saved_user)

## C1/C2：重复通关不再无限刷经验/金币；当日重试降级星级上限。
func _test_anti_farm() -> void:
	var saved_user := GameData.current_user
	var s_stars: Dictionary = GameData.stars.duplicate(true)
	var s_records: Dictionary = GameData.level_records.duplicate(true)
	var s_exp := GameData.player_exp
	var s_coins := GameData.coins
	var s_earned := GameData.coins_earned
	GameData.current_user = ""   # 阻止测试触碰真实存档

	var lid := "__farm_test__"
	GameData.stars.erase(lid)
	GameData.level_records.erase(lid)
	GameData.player_exp = 0
	GameData.coins = 0
	GameData.coins_earned = 0

	# 首次三星：全额 + 经验 30
	var r0 := GameData.settle_level(lid, 3, 3, 3, false, 100)
	_eq(int(r0["granted"]), 100, "first clear full reward")
	_ok(bool(r0["full"]), "first clear full flag")
	_eq(GameData.player_exp, 30, "first clear exp += 30")
	_eq(GameData.coins, 100, "first clear coins += 100")

	# 重复通关：折扣 ×0.3，每日最多 3 次；经验不再增长
	var got: Array = []
	for i in 5:
		got.append(int(GameData.settle_level(lid, 3, 3, 3, false, 100)["granted"]))
	_eq(got, [30, 30, 30, 0, 0], "repeat rewards discounted & capped per day")
	_eq(GameData.player_exp, 30, "repeat clear gives no exp")
	_eq(GameData.coins, 190, "repeat coins converge")

	# 当日尝试数 >= 3 → 星级上限降为 2（盲猜无法刷满三星）
	_eq(GameData.attempts_today(lid), 6, "attempts_today accumulates")
	_eq(GameData.star_cap_for_attempt(lid), 2, "star cap drops to 2 on 3rd+ daily attempt")

	# 跨天归零（模拟：把 attempt_date 改到过去）
	GameData.level_records[lid]["attempt_date"] = "1970-01-01"
	_eq(GameData.attempts_today(lid), 0, "attempts_today resets on new day")
	_eq(GameData.star_cap_for_attempt(lid), 3, "star cap restored next day")

	# grant_stars 只在星级提升时给经验
	GameData.stars[lid] = 3
	var exp_before := GameData.player_exp
	GameData.grant_stars(lid, 2)
	_eq(GameData.player_exp, exp_before, "lower stars gives no exp")
	GameData.stars[lid] = 1
	GameData.grant_stars(lid, 2)
	_eq(GameData.player_exp, exp_before + 10, "star improvement gives delta exp")

	# 还原
	GameData.stars = s_stars
	GameData.level_records = s_records
	GameData.player_exp = s_exp
	GameData.coins = s_coins
	GameData.coins_earned = s_earned
	GameData.current_user = saved_user

## F1：在线 TTS 隐私策略 —— 默认关闭、默认离线引擎、需明确同意才外发文本。
func _test_tts_policy() -> void:
	_eq(Settings.DEFAULTS.get("voice", true), false, "F1: 语音朗读默认关闭")
	_eq(Settings.DEFAULTS.get("tts_engine", "online"), "system", "F1: 默认离线系统语音")
	_eq(Settings.DEFAULTS.get("tts_online_consent", true), false, "F1: 默认未同意在线朗读")
	# 未同意时，在线引擎的 say() 不得触达在线管理器（改走离线/静默）。
	var saved_consent := Settings.tts_online_consent
	var saved_enabled := Tts.enabled
	Settings.tts_online_consent = false
	Tts.engine = "online"
	Tts.enabled = true
	Tts.say("测试文本", true, false)
	_ok(Tts._online == null, "F1: 无同意时不创建在线管理器(不外发文本)")
	# sanitize 仍需正常工作(纯本地)。
	_ok(Tts.sanitize("a²+b²").find("的平方") != -1, "F1: sanitize 本地清洗仍生效")
	# 还原，避免影响其他用例。
	Tts.engine = "system"
	Tts.enabled = saved_enabled
	Settings.tts_online_consent = saved_consent

func _test_daily() -> void:
	var saved_user := GameData.current_user
	var s_coins := GameData.coins
	var s_earned := GameData.coins_earned
	var s_q := GameData.total_questions
	var s_date := GameData.daily_date
	var s_base: Dictionary = GameData.daily_base.duplicate()
	var s_peak := GameData.daily_peak_streak
	var s_claimed: Dictionary = GameData.daily_claimed.duplicate()
	GameData.current_user = ""

	# 视作新的一天：基准应归零
	GameData.daily_date = ""
	GameData.daily_base = {}
	GameData.daily_peak_streak = 0
	GameData.daily_claimed = {}
	GameData.total_questions = 0
	GameData.coins_earned = 0
	var ms := GameData.daily_missions()
	_eq(ms.size(), GameData.DAILY_MISSIONS.size(), "daily_missions count")
	_eq(GameData.daily_mission_progress(GameData.DAILY_MISSIONS[0]), 0, "daily baseline zero")

	# 作答增量 -> 达标(并截断到目标值)
	GameData.total_questions = 25
	var m0 := {}
	for m in GameData.daily_missions():
		if str(m["id"]) == "d_answer":
			m0 = m
	_eq(int(m0["cur"]), 20, "d_answer progress clamps to goal")
	_ok(bool(m0["done"]), "d_answer done")
	_ok(not GameData.claim_daily_mission("d_clear"), "claim incomplete -> false")

	# 领取与防重复
	GameData.coins = 0
	_ok(GameData.claim_daily_mission("d_answer"), "claim d_answer ok")
	_ok(not GameData.claim_daily_mission("d_answer"), "claim twice -> false")
	_ok(bool(GameData.daily_claimed.get("d_answer", false)), "daily_claimed flag set")

	# 连击峰值取最大
	GameData.note_streak(3)
	GameData.note_streak(5)
	GameData.note_streak(4)
	_eq(GameData.daily_peak_streak, 5, "daily peak keeps max")
	var streak_done := false
	for m in GameData.daily_missions():
		if str(m["id"]) == "d_streak":
			streak_done = bool(m["done"])
	_ok(streak_done, "d_streak done at peak 5")

	# 跨天重置
	GameData.daily_date = "1970-01-01"
	GameData.daily_claimed = { "d_answer": true }
	_eq(GameData.daily_claimable_count(), 0, "claimable reset on new day")

	GameData.coins = s_coins
	GameData.coins_earned = s_earned
	GameData.total_questions = s_q
	GameData.daily_date = s_date
	GameData.daily_base = s_base
	GameData.daily_peak_streak = s_peak
	GameData.daily_claimed = s_claimed
	GameData.current_user = saved_user

## 校验教材版本切换：章节重排、按教材章号合并、分册归属与章号齐备，方法章节在前。
func _test_textbook() -> void:
	var saved := GameData.textbook
	_ok(GameData.textbook_list().size() >= 3, "textbook_list has >=3 versions")
	for v in GameData.textbook_list():
		var vid := str(v["id"])
		GameData.set_textbook(vid)
		var seen := {}
		var k_ids: Array = []
		var m_ids: Array = []
		for ch in GameData.chapters:
			var cid := str(ch["id"])
			_ok(not seen.has(cid), "%s no dup %s" % [vid, cid])
			seen[cid] = true
			if str(ch.get("kind", "knowledge")) == "method":
				m_ids.append(cid)
			else:
				k_ids.append(cid)
				_ok(GameData.book_of_chapter(cid) != "", "%s book of %s" % [vid, cid])
				_ok(GameData.chapter_no(cid) != "", "%s chapter_no of %s" % [vid, cid])
		# 知识章节按 (分册, 教材章号) 合并：展示章节数 = 去重后的分组数
		var groups := {}
		var listed := {}
		for id in v.get("knowledge_order", []):
			listed[str(id)] = true
		for ch in GameData._chapters_raw:
			if str(ch.get("kind", "knowledge")) == "method":
				continue
			var cid := str(ch["id"])
			_ok(listed.has(cid), "%s knowledge_order lists %s" % [vid, cid])
			groups[GameData.book_of_chapter(cid) + "|" + GameData.chapter_no(cid)] = true
		_eq(k_ids.size(), groups.size(), "%s merged knowledge count" % vid)
		var m_want: Array = []
		for id in v.get("method_order", []):
			if seen.has(str(id)):
				m_want.append(str(id))
		_eq(str(m_ids), str(m_want), "%s method order" % vid)
		# 方法章节整体排在知识章节之前(方法推演地图与知识体系地图各自连续)
		if not m_ids.is_empty() and not k_ids.is_empty():
			var first_k: int = k_ids.size()
			var last_m := -1
			for i in GameData.chapters.size():
				var cid2 := str(GameData.chapters[i]["id"])
				if cid2 in m_ids:
					last_m = i
			for i in GameData.chapters.size():
				if str(GameData.chapters[i]["id"]) == str(k_ids[0]):
					first_k = i
					break
			_ok(last_m < first_k, "%s method chapters before knowledge" % vid)
		_ok(GameData.book_defs().size() > 0, "%s has books" % vid)
	# 未知版本回退为原始顺序且不报错
	GameData.set_textbook("__nope__")
	_eq(GameData.chapters.size(), GameData._chapters_raw.size(), "unknown version keeps raw chapters")
	GameData.set_textbook(saved)

## 校验 P3 地图冒险数据(curriculum 的 gate/chest/event/optional)与 GameData 冒险接口。
func _test_adventure() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/curriculum.json"))
	_ok(typeof(data) == TYPE_DICTIONARY, "curriculum parses (adventure)")
	var want := {
		"line_eq": "line_boss", "space": "space_boss", "vector": "vector_boss",
		"ellipse": "ellipse_boss", "circle_eq": "circle_boss",
	}
	for ch in (data as Dictionary).get("chapters", []):
		var cid := str(ch.get("id", ""))
		if not want.has(cid):
			continue
		var levels: Array = ch.get("levels", [])
		var boss_id := str(want[cid])
		var ids := {}
		for lv in levels:
			ids[str(lv.get("id", ""))] = true
		var chests := 0
		var events := 0
		var optionals := 0
		for lv in levels:
			var lid := str(lv.get("id", ""))
			if lid == boss_id:
				_ok(lv.get("gate") is Dictionary, cid + " boss has gate{}")
				_ok(int((lv.get("gate", {}) as Dictionary).get("need_stars", 0)) > 0, cid + " gate.need_stars > 0")
			if lv.get("chest") is Dictionary:
				chests += 1
				_ok(int((lv.get("chest", {}) as Dictionary).get("need_stars", 0)) >= 0, cid + " chest need_stars >= 0")
			if lv.get("event") is Dictionary:
				events += 1
			if bool(lv.get("optional", false)):
				optionals += 1
				var after := str(lv.get("after", ""))
				_ok(after != "" and ids.has(after), cid + " optional.after exists: " + lid)
		_ok(chests >= 1, cid + " has >=1 chest")
		_ok(events >= 1, cid + " has >=1 event")
		_ok(optionals >= 1, cid + " has >=1 optional branch")

	# GameData 冒险接口(置空 current_user 阻止写盘)
	var saved_user := GameData.current_user
	var saved_chests: Dictionary = GameData.chests_claimed.duplicate(true)
	var saved_events: Dictionary = GameData.events_seen.duplicate(true)
	var saved_coins := GameData.coins
	var saved_earned := GameData.coins_earned
	var saved_hint := GameData.hint_tokens
	var saved_boost := GameData.coin_boost
	GameData.current_user = ""

	_eq(GameData.stars_of(["__none_a__", "__none_b__"]), 0, "stars_of unknown = 0")
	var s_stars: Dictionary = GameData.stars.duplicate()
	GameData.stars["__adv_a__"] = 2
	GameData.stars["__adv_b__"] = 3
	_eq(GameData.stars_of(["__adv_a__", "__adv_b__"]), 5, "stars_of sums")
	GameData.stars = s_stars

	_ok(not GameData.is_chest_claimed("__adv_chest__"), "chest not claimed initially")
	_ok(GameData.claim_chest("__adv_chest__", { "coins": 50, "hint_tokens": 1 }), "claim_chest grants")
	_ok(GameData.is_chest_claimed("__adv_chest__"), "chest claimed after")
	_eq(GameData.coins, saved_coins + 50, "claim_chest adds coins")
	_eq(GameData.hint_tokens, saved_hint + 1, "claim_chest adds hint token")
	_ok(not GameData.claim_chest("__adv_chest__", { "coins": 50 }), "double claim rejected")
	_eq(GameData.coins, saved_coins + 50, "double claim adds nothing")

	_ok(not GameData.is_event_seen("__adv_evt__"), "event unseen initially")
	_ok(GameData.mark_event_seen("__adv_evt__"), "mark_event_seen first true")
	_ok(not GameData.mark_event_seen("__adv_evt__"), "mark_event_seen second false")
	GameData.grant_reward({ "coins": 10, "coin_boost": 2 })
	_eq(GameData.coins, saved_coins + 60, "grant_reward adds coins")
	_eq(GameData.coin_boost, saved_boost + 2, "grant_reward adds coin_boost")

	GameData.chests_claimed = saved_chests
	GameData.events_seen = saved_events
	GameData.coins = saved_coins
	GameData.coins_earned = saved_earned
	GameData.hint_tokens = saved_hint
	GameData.coin_boost = saved_boost
	GameData.current_user = saved_user

func _test_inline_math() -> void:
	# A10：$$...$$ 内联 LaTeX(无需 FORMULA_LATEX 命名)，且不残留 $$ 标记
	var s := InlineMath.strip_formulas("当 $$x>0$$ 时")
	_ok(s.find("$$") < 0, "strip_formulas 去掉 $$ 标记")
	_ok(s.find("大于") >= 0, "strip_formulas 把 > 读作「大于」")
	var f := InlineMath.strip_formulas("恒有 $$\\frac{1}{a}>\\frac{1}{b}$$")
	_ok(f.find("$$") < 0, "strip 分式无 $$ 残留")
	_ok(f.find("分之") >= 0, "strip 分式读作「分之」")
	var r := InlineMath.inline_formulas("当 $$x>0$$ 时")
	_ok(r.find("$$") < 0, "inline_formulas 去掉 $$ 标记")
	_ok(r.find("[img=") >= 0 or r.find("x>0") >= 0, "$$ 渲染或回退")
	# {f:名称} 老路径仍可用
	_ok(InlineMath.inline_formulas("看 {f:pw_xge_a}").find("{f:") < 0, "{f:} 仍被替换")

## A18：内容数据体检——坏数据要能变成「问题码 + 位置 + 人话」，好数据不许误报。
func _test_content_health() -> void:
	# 空课程表
	var empty := ContentHealth.check([])
	_eq(empty["ok"], false, "content: an empty curriculum is not healthy")
	_eq(str((empty["problems"][0] as Dictionary)["code"]), "E_EMPTY", "content: empty code")
	_eq(ContentHealth.describe([]), "内容数据完整", "content: describe on a clean list")

	# 好数据：一切齐全，不许误报
	var good := [{
		"id": "ch1", "title": "第一章", "levels": [
			{"id": "lv1", "name": "第一关", "scene": "res://scenes/A.tscn", "lab": "circle", "lab_ref": "circle_1_1"},
		],
	}]
	var ok_res := ContentHealth.check(good, {"res://scenes/A.tscn": true}, {"lab:circle": ["circle_1_1"]})
	_eq(ok_res["ok"], true, "content: well-formed data is healthy")
	_eq(int(ok_res["count"]), 0, "content: no false positives")

	# 关卡 id 重复
	var dup := ContentHealth.check([{
		"id": "ch1", "title": "第一章", "levels": [
			{"id": "lv1", "name": "甲", "scene": "s", "lab": "circle", "lab_ref": "k"},
			{"id": "lv1", "name": "乙", "scene": "s", "lab": "circle", "lab_ref": "k"},
		],
	}])
	_eq(dup["ok"], false, "content: duplicate ids are rejected")
	_ok(ContentHealth.codes(dup["problems"]).has("E_DUP_ID"), "content: duplicate id code")
	_eq(ContentHealth.codes(dup["problems"]).size(), 1, "content: codes are de-duplicated")

	# 空章节
	var no_lv := ContentHealth.check([{"id": "ch1", "title": "第一章", "levels": []}])
	_ok(ContentHealth.codes(no_lv["problems"]).has("E_NO_LEVEL"), "content: a chapter without levels is rejected")

	# 缺名字 / 缺场景 / 场景文件不存在
	var no_name := ContentHealth.check([{"id": "ch1", "levels": [{"id": "lv1", "scene": "s", "lab": "circle", "lab_ref": "k"}]}])
	_ok(ContentHealth.codes(no_name["problems"]).has("E_NO_TITLE"), "content: a level without a name is rejected")
	var no_scene := ContentHealth.check([{"id": "ch1", "levels": [{"id": "lv1", "name": "甲", "lab": "circle", "lab_ref": "k"}]}])
	_ok(ContentHealth.codes(no_scene["problems"]).has("E_NO_SCENE"), "content: a level without a scene is rejected")
	var ghost_scene := ContentHealth.check(
		[{"id": "ch1", "levels": [{"id": "lv1", "name": "甲", "scene": "s", "lab": "circle", "lab_ref": "k"}]}],
		{"other": true})
	_ok(ContentHealth.codes(ghost_scene["problems"]).has("E_NO_SCENE"), "content: a missing scene file is rejected")

	# 引用定位不到
	var no_ref := ContentHealth.check([{"id": "ch1", "levels": [{"id": "lv1", "name": "甲", "scene": "s"}]}])
	_ok(ContentHealth.codes(no_ref["problems"]).has("E_BAD_REF"), "content: a level without content is rejected")
	var lost_key := ContentHealth.check(
		[{"id": "ch1", "levels": [{"id": "lv1", "name": "甲", "scene": "s", "lab": "circle", "lab_ref": "nope"}]}],
		{}, {"lab:circle": ["k"]})
	_ok(ContentHealth.codes(lost_key["problems"]).has("E_BAD_REF"), "content: an unresolvable group key is rejected")
	var lost_src := ContentHealth.check(
		[{"id": "ch1", "levels": [{"id": "lv1", "name": "甲", "scene": "s", "lab": "circle", "lab_ref": "k"}]}],
		{}, {"lab:other": ["k"]})
	_ok(ContentHealth.codes(lost_src["problems"]).has("E_BAD_REF"), "content: a missing data source is rejected")

	# 引用映射：lab 取 lab_ref，其余同名
	_eq(str((ContentHealth.ref_of({"lab": "circle", "lab_ref": "circle_1_1"})[0])), "lab:circle", "content: lab source key")
	_eq(str((ContentHealth.ref_of({"lab": "circle", "lab_ref": "circle_1_1"})[1])), "circle_1_1", "content: lab group key")
	_eq(str((ContentHealth.ref_of({"sequence": "recur_add"})[0])), "sequence", "content: sequence source key")
	_eq(str((ContentHealth.ref_of({"conic": "C1"})[0])), "conic", "content: conic source key")
	_eq(str((ContentHealth.ref_of({"method": "complement"})[0])), "method", "content: method source key")
	_eq(ContentHealth.ref_of({"id": "lv1", "name": "甲", "scene": "s"}).size(), 0, "content: a level without a reference has none")

	# 真数据必须体检通过（改数据改坏了要红）
	var real := ContentHealth.check(GameData.chapters)
	_eq(real["ok"], true, "content: the shipped curriculum passes the health check")
	_eq(GameData.content_ok(), true, "content: GameData reports healthy content")
	_eq((GameData.content_health()["problems"] as Array).size(), 0, "content: GameData has no problems")
