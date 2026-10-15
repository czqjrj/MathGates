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
	_test_lab_plane()
	_test_wrong_queries()
	_test_review_order()
	_test_focus()
	_test_accuracy()
	_test_economy()
	_test_daily()
	_test_textbook()
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
		{ "file": "res://data/sequences_levels.json", "ids": ["seq_basic", "seq_recur", "seq_construct", "seq_displace", "seq_split", "seq_sn", "seq_concept"] },
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
		{ "file": "res://data/solid_basic_levels.json", "ids": ["solid_kinds", "solid_surface", "solid_volume", "solid_diag", "solid_sphere", "solid_axiom", "solid_parallel", "solid_view", "solid_frustum", "solid_par_prop", "solid_perp_prop", "solid_angle", "solid_distance"] },
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

	# 勋章判定改用累计金币
	GameData.coins_earned = 999
	_ok(not GameData._medal_met("coins_1000"), "coins_1000 needs earned>=1000")
	GameData.coins_earned = 1000
	_ok(GameData._medal_met("coins_1000"), "coins_1000 met at earned=1000")

	GameData.coins = s_coins
	GameData.coins_earned = s_earned
	GameData.owned_avatars = s_owned
	GameData.hint_tokens = s_hint
	GameData.coin_boost = s_boost
	GameData.last_login_date = s_date
	GameData.login_streak = s_lstreak
	GameData.current_user = saved_user

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
