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
	_test_wrong_queries()
	_test_review_order()
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
	_test_adventure()
	_test_inline_math()
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
