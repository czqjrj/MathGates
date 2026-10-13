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
		{ "file": "res://data/functions_levels.json", "ids": ["func_domain", "func_mono", "func_period", "func_exp_log", "func_abstract", "func_zeros", "func_power", "func_apply", "func_bisect"] },
		{ "file": "res://data/set_logic_levels.json", "ids": ["set_ops", "set_interval", "logic_cond", "logic_neg", "logic_special"] },
		{ "file": "res://data/inequalities_levels.json", "ids": ["ineq_quad", "ineq_basic"] },
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
		{ "file": "res://data/solid_basic_levels.json", "ids": ["solid_kinds", "solid_surface", "solid_volume", "solid_diag", "solid_sphere", "solid_axiom", "solid_parallel", "solid_view", "solid_frustum", "solid_par_prop", "solid_perp_prop"] },
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
			_ok(lv.size() == 3, id + " has 3 rounds")
			for r in lv:
				if str((r as Dictionary).get("type", "choice")) == "explore":
					explore_total += 1
		var min_explore: int = min(3, (spec["ids"] as Array).size())
		_ok(explore_total >= min_explore, path + " has >=%d explore rounds" % min_explore)

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

## 校验教材版本切换：章节重排、分册归属与章号齐备，方法章节在前。
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
		_eq(k_ids.size(), 23, "%s knowledge count" % vid)
		_eq(m_ids.size(), 3, "%s method count" % vid)
		var k_want: Array = []
		for id in v.get("knowledge_order", []):
			if seen.has(str(id)):
				k_want.append(str(id))
		_eq(str(k_ids), str(k_want), "%s knowledge order" % vid)
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
