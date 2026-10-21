extends Node
## A11 · UI/交互层自动化断言（headless）。
## 运行： godot --headless --path . res://tests/UiSmoke.tscn
##
## 覆盖：
##   1. StageBase 家族舞台（LabStage/Lab3DStage/SequenceStage）关键节点存在；
##   2. 选项数 == 数据 opts 数、badge/panel 与按钮数一致；
##   3. 选项乱序是「排列」且 disp/orig 往返一致、顺序相关选项(以上都对)不打乱；
##   4. 乱序确实生效（同一轮多次构建顺序不恒定，保护 B8）；
##   5. 结算面板可弹出（_finish → _victory/_dim 可见）；
##   6. 字号随 UI.S 线性生效；
##   7. 官方收编舞台（ConicStage/SolidChallenge，TODO A2 收编）可构建且关卡数据已载入。
##
## 退出码：0 = 全通过；1 = 有失败（供 CI 判定）。
## 反向验证：故意注释掉 StageBase._ready() 里的 _build_ui() 调用，本测试应红灯。

const NODE_LABELS := {
	"_ui": "UI 根",
	"_panel": "答题面板",
	"_ans": "选项容器",
	"_q": "题干",
	"_next": "下一关按钮",
	"_hint": "提示按钮",
	"_victory": "结算面板",
	"_dim": "遮罩",
	"_v_title": "结算标题",
	"_v_rate": "结算评级",
	"_v_star_row": "结算星级行",
	"_v_score": "结算得分",
	"_prog": "进度标签",
	"_coins": "金币标签",
}

var _pass := 0
var _fail := 0
var _samples: Dictionary = {}

func _ok(cond: bool, name: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", name)

func _eq(a: Variant, b: Variant, name: String) -> void:
	_ok(a == b, "%s (got %s, want %s)" % [name, str(a), str(b)])

func _ready() -> void:
	GameData.create_user("uismoke", "player")
	GameData.login("uismoke")
	await get_tree().process_frame

	_test_font_scale()
	_collect_samples()

	for scene_path in ["res://scenes/LabStage.tscn", "res://scenes/Lab3DStage.tscn", "res://scenes/SequenceStage.tscn"]:
		await _test_stagebase(scene_path, _pick(scene_path, 3))

	for scene_path in ["res://scenes/ConicStage.tscn", "res://scenes/SolidChallenge.tscn"]:
		await _test_legacy(scene_path, _pick(scene_path, 1))

	await _test_keyboard_stage()
	await _test_srs_review_entry()
	await _test_report_screen()
	await _test_content_fallback()

	print("UI-SMOKE: %d ok, %d fail" % [_pass, _fail])
	GameData.logout()
	GameData.delete_user("uismoke")
	await get_tree().process_frame
	get_tree().quit(1 if _fail > 0 else 0)

# ---------------------------------------------------------------- 采样

func _collect_samples() -> void:
	for ci in GameData.chapters.size():
		var levels: Array = GameData.chapters[ci].get("levels", [])
		for li in levels.size():
			var sc := str(levels[li].get("scene", ""))
			if sc == "":
				continue   # A3：缺 scene 的关卡不可导航（curriculum 实测 275/275 全带 scene）
			if not _samples.has(sc):
				_samples[sc] = []
			_samples[sc].append([ci, li])

## 取每个场景最多 n 个样本（优先包含 boss / 末尾关卡，覆盖面更广）。
func _pick(scene_path: String, n: int) -> Array:
	var all: Array = _samples.get(scene_path, [])
	if all.size() <= n:
		return all
	var out: Array = []
	var boss: Array = []
	for p in all:
		var lid := str(GameData.chapters[p[0]]["levels"][p[1]].get("id", ""))
		if lid.find("boss") >= 0:
			boss.append(p)
	# 均摊取样 + 至少一个 boss
	var step := int(ceil(float(all.size()) / float(n)))
	var i := 0
	while i < all.size() and out.size() < n - (1 if not boss.is_empty() else 0):
		out.append(all[i])
		i += step
	if not boss.is_empty() and out.size() < n:
		out.append(boss[0])
	return out

# ---------------------------------------------------------------- 字号

func _test_font_scale() -> void:
	var saved: float = UI.S
	UI.S = 1.0
	_eq(UI.fs(20), 20, "fs(20)@S=1.0")
	UI.S = 1.4
	_eq(UI.fs(20), 28, "fs(20)@S=1.4")
	UI.S = 2.0
	_eq(UI.fs(20), 40, "fs(20)@S=2.0")
	_ok(UI.fs(1) >= 1, "fs 最小为 1")
	_ok(UI.fs(30) > UI.fs(15), "fs 随字号单调")
	UI.S = saved

# ---------------------------------------------------------------- StageBase 家族

## F4：真实 LabStage 上的键盘选择必须走与鼠标同一条回调（_on_choice）。
func _test_keyboard_stage() -> void:
	var picks := _pick("res://scenes/LabStage.tscn", 1)
	if picks.is_empty():
		_ok(false, "keyboard: 缺少 LabStage 样本")
		return
	if not GameData.start_level(picks[0][0], picks[0][1]):
		_ok(false, "keyboard: start_level 失败")
		return
	var st = load("res://scenes/LabStage.tscn").instantiate()
	add_child(st)
	await get_tree().process_frame
	await get_tree().process_frame
	var done := false
	for i in st._stages.size():
		st._idx = i
		st._load_q()
		await get_tree().process_frame
		if st._opt_btns.size() >= 2 and not st._solved:
			_ok(KeyNav.handle(st, KEY_1), "真实 LabStage：数字键被消费")
			_eq(st._last_picked, 0, "真实 LabStage：键盘选中走同一回调")
			done = true
			break
	if not done:
		_ok(false, "keyboard: 未找到可键盘作答的轮次")
	st.queue_free()
	await get_tree().process_frame

func _test_stagebase(scene_path: String, picks: Array) -> void:
	if picks.is_empty():
		print("  [skip] 无样本：", scene_path)
		return
	for p in picks:
		if not GameData.start_level(p[0], p[1]):
			_fail += 1
			print("  [FAIL] start_level ", p)
			continue
		var lid := GameData.current_level_id()
		var tag := "%s [%s]" % [scene_path.get_file(), lid]
		var st = load(scene_path).instantiate()
		add_child(st)
		await get_tree().process_frame
		await get_tree().process_frame
		_expect_nodes(st, tag)
		await _expect_rounds(st, tag)
		await _expect_finish(st, tag)
		st.queue_free()
		await get_tree().process_frame

func _expect_nodes(st: Node, tag: String) -> void:
	for key in NODE_LABELS:
		_ok(st.get(key) != null, "%s 节点存在：%s" % [tag, NODE_LABELS[key]])

func _expect_rounds(st: Node, tag: String) -> void:
	var stages: Array = st._stages
	_ok(stages.size() > 0, tag + " 有关卡轮次")
	var choice_rounds := 0
	var non_identity := 0
	var shuffle_candidate := -1
	for i in stages.size():
		var s: Dictionary = stages[i]
		if s.has("opts"):
			var opts: Array = s.get("opts", [])
			_ok(opts.size() >= 2, "%s 轮%d 选项数≥2" % [tag, i])
			var ans: Variant = s.get("ans")
			if ans is int:
				_ok(int(ans) >= 0 and int(ans) < opts.size(), "%s 轮%d ans 在范围内" % [tag, i])
			elif ans is Array:
				var arr: Array = ans
				_ok(arr.size() >= 1 and arr.size() < maxi(1, opts.size()), "%s 轮%d 多选非全选" % [tag, i])
		st._idx = i
		st._load_q()
		await get_tree().process_frame
		# D2/D1：带 anim 的轮次必须显示「▶ 演示」，且能真正启动2D播放器
		var demo_btn: Variant = st.get("_demo_btn")
		if demo_btn != null:
			var sc_round: Variant = s.get("scene", {})
			var want := s.has("anim") or (sc_round is Dictionary and (sc_round as Dictionary).has("anim"))
			_eq(demo_btn.visible, want, "%s 轮%d 演示按钮可见性" % [tag, i])
			if want:
				st._play_demo()
				_ok(st._plane.is_demo_playing(), "%s 轮%d 演示已启动" % [tag, i])
		if st._opt_btns.size() <= 0:
			continue
		choice_rounds += 1
		var opts: Array = s.get("opts", [])
		_eq(st._opt_btns.size(), opts.size(), "%s 轮%d 按钮数==opts数" % [tag, i])
		_eq(st._opt_badges.size(), st._opt_btns.size(), "%s 轮%d badge数一致" % [tag, i])
		_eq(st._opt_panels.size(), st._opt_btns.size(), "%s 轮%d panel数一致" % [tag, i])
		_eq(st._opt_order.size(), opts.size(), "%s 轮%d order 长度" % [tag, i])
		_ok(_is_perm(st._opt_order), "%s 轮%d order 是排列" % [tag, i])
		var rt := true
		for k in st._opt_btns.size():
			if st._disp_of(st._orig_of(k)) != k:
				rt = false
		_ok(rt, "%s 轮%d disp/orig 往返一致" % [tag, i])
		if not _is_identity(st._opt_order):
			non_identity += 1
		if _has_order_marker(opts):
			_ok(_is_identity(st._opt_order), "%s 轮%d 顺序相关选项不打乱" % [tag, i])
		elif shuffle_candidate < 0 and opts.size() >= 3 and StageRules.shuffle_allowed(s, opts):
			shuffle_candidate = i
	_ok(choice_rounds > 0, tag + " 至少 1 轮构建出选项")
	if shuffle_candidate >= 0:
		await _expect_shuffle_effective(st, tag, shuffle_candidate)

## 同一轮反复构建，选项顺序不应恒定（保护 B8 的乱序修复）。
func _expect_shuffle_effective(st: Node, tag: String, idx: int) -> void:
	var seen := {}
	for _r in 12:
		st._idx = idx
		st._load_q()
		await get_tree().process_frame
		seen[str(st._opt_order)] = true
	_ok(seen.size() >= 2, "%s 轮%d 乱序生效（%d 种顺序）" % [tag, idx, seen.size()])

func _expect_finish(st: Node, tag: String) -> void:
	if st._stages.is_empty():
		return
	st._finish()
	await get_tree().create_timer(1.1).timeout
	_ok(st._victory != null and st._victory.visible, tag + " 结算面板弹出")
	_ok(st._dim != null and st._dim.visible, tag + " 遮罩显示")
	_ok(st._v_star_row != null and st._v_star_row.get_child_count() > 0, tag + " 结算星级已渲染")
	_ok(st._v_title != null and st._v_title.text != "", tag + " 结算标题非空")

# ---------------------------------------------------------------- legacy 舞台

func _test_legacy(scene_path: String, picks: Array) -> void:
	if picks.is_empty():
		# 无课程表样本（如不在用的历史场景）时，用任意真实关卡上下文实例化，只验「能构建」。
		picks = [[0, 0]]
	for p in picks:
		if not GameData.start_level(p[0], p[1]):
			continue
		var tag := "%s [%s]" % [scene_path.get_file(), GameData.current_level_id()]
		var st = load(scene_path).instantiate()
		add_child(st)
		await get_tree().process_frame
		await get_tree().process_frame
		_ok(st.get_child_count() > 0, tag + " 构建出子节点")
		var stages = st.get("_stages")
		_ok(stages is Array and (stages as Array).size() > 0, tag + " 关卡数据已载入")
		st.queue_free()
		await get_tree().process_frame

# ---------------------------------------------------------------- G1 复习入口

## G1：错题间隔重复的 UI 入口——首页顶栏「复习 N」按钮 + 错题本「今日待复习」卡片。
func _test_srs_review_entry() -> void:
	var lid := ""
	for ci in GameData.chapters.size():
		var levels: Array = GameData.chapters[ci].get("levels", [])
		for li in levels.size():
			if str(levels[li].get("scene", "")) != "":
				lid = str(levels[li].get("id", ""))
				break
		if lid != "":
			break
	if lid == "":
		_ok(false, "srs ui: 找不到可用的真实关卡")
		return
	var qi := 0
	GameData.record_answer(lid, qi, "uismoke 题", false, 1, 2, "seq")
	_ok(GameData.srs_due_count() >= 1, "srs ui: 新错题今日到期")

	# 首页：顶栏出现「复习 N」，错题笔记卡片带角标
	var hub = load("res://scenes/MainHub.tscn").instantiate()
	add_child(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	var rb = hub.get("_review_btn")
	_ok(rb != null, "srs ui: 首页有复习按钮")
	if rb != null:
		_ok(rb.visible, "srs ui: 复习按钮可见")
		_eq(rb.text, "复习 %d" % GameData.srs_due_count(), "srs ui: 复习按钮显示待复习数")
	var badge = hub.get("_badges")
	_ok(badge is Dictionary and (badge as Dictionary).has("错题笔记"), "srs ui: 错题笔记卡片有角标位")
	if badge is Dictionary:
		var bl: Variant = (badge as Dictionary)["错题笔记"]
		_ok(bl is Label and (bl as Label).visible, "srs ui: 角标可见")
		_ok(bl is Label and (bl as Label).text.find("待复习") >= 0, "srs ui: 角标显示待复习数")
	hub.queue_free()
	await get_tree().process_frame

	# 错题本：出现「今日待复习」卡片与「开始复习」按钮
	var nb = load("res://scenes/WrongNotebook.tscn").instantiate()
	add_child(nb)
	await get_tree().process_frame
	await get_tree().process_frame
	var found := false
	for n in _walk(nb):
		if n is Button and (n as Button).text.find("开始复习") >= 0:
			found = true
	_ok(found, "srs ui: 错题本有「开始复习」按钮")
	nb.queue_free()
	await get_tree().process_frame

	# 清理：抹掉本用例造出来的错题与排程
	GameData.wrong_log.erase("%s#%d" % [lid, qi])
	GameData.srs_plan.erase("%s#%d" % [lid, qi])

## G3：学习报告页——概览/趋势/家长只读摘要卡、本地导出入口与周期切换。
func _test_report_screen() -> void:
	var scr = load("res://scenes/LearningReport.tscn").instantiate()
	add_child(scr)
	await get_tree().process_frame
	await get_tree().process_frame

	var labels := ""
	var btns := []
	for n in _walk(scr):
		if n is Label:
			labels += (n as Label).text + "\n"
		elif n is Button:
			btns.append(str((n as Button).text))
	_ok(labels.find("学习概览") >= 0, "report ui: 有学习概览卡")
	_ok(labels.find("逐日趋势") >= 0, "report ui: 有逐日趋势卡")
	_ok(labels.find("薄弱领域") >= 0, "report ui: 有薄弱领域卡")
	_ok(labels.find("家长视图") >= 0, "report ui: 有家长视图卡")
	_ok(labels.find("不含题目原文") >= 0, "report ui: 家长视图标注了隐私规则")
	_ok(labels.find("不联网") >= 0, "report ui: 标注本地生成不联网")
	var has_csv := false
	var has_json := false
	for b in btns:
		if b.find("导出 CSV") >= 0:
			has_csv = true
		if b.find("导出 JSON") >= 0:
			has_json = true
	_ok(has_csv, "report ui: 有 CSV 导出按钮")
	_ok(has_json, "report ui: 有 JSON 导出按钮")

	# 周期切换：切到「本月」后窗口应变 30 天，且按钮显示选中态
	var wk = scr.get("_wk_btn")
	var mo = scr.get("_mo_btn")
	_ok(wk != null and mo != null, "report ui: 顶栏有周期切换按钮")
	if mo != null:
		(mo as Button).emit_signal("pressed")
		await get_tree().process_frame
		await get_tree().process_frame
		var s = scr.get("_summary")
		_ok(s is Dictionary, "report ui: 有报告汇总数据")
		if s is Dictionary:
			_eq(int((s as Dictionary).get("days", 0)), 30, "report ui: 切到本月后窗口为 30 天")
		_ok((mo as Button).text.find("✓") >= 0, "report ui: 本月按钮显示选中态")
	scr.queue_free()
	await get_tree().process_frame

## A18：内容数据异常时的用户可见兜底——卡片 / 横幅 / 复制文本。
func _test_content_fallback() -> void:
	var problems := [
		{"code": "E_DUP_ID", "where": "ch1/lv1", "message": "关卡 id「lv1」重复"},
		{"code": "E_NO_SCENE", "where": "ch2/lv2", "message": "关卡没有场景"},
	]
	var card := ContentFallback.card(problems, Callable(), Callable())
	add_child(card)
	await get_tree().process_frame
	var labels := ""
	var btns := []
	for n in _walk(card):
		if n is Label:
			labels += (n as Label).text + "\n"
		elif n is Button:
			btns.append(str((n as Button).text))
	_ok(labels.find("内容数据加载失败") >= 0, "content ui: 兜底卡有标题")
	_ok(labels.find("E_DUP_ID") >= 0, "content ui: 兜底卡列出问题码")
	_ok(labels.find("ch1/lv1") >= 0, "content ui: 兜底卡列出问题位置")
	_ok(labels.find("不联网") >= 0, "content ui: 兜底卡标注了不联网")
	var has_retry := false
	var has_copy := false
	for b in btns:
		if b.find("重试加载") >= 0:
			has_retry = true
		if b.find("复制错误信息") >= 0:
			has_copy = true
	_ok(has_retry, "content ui: 兜底卡有重试按钮")
	_ok(has_copy, "content ui: 兜底卡有复制按钮")
	card.queue_free()
	await get_tree().process_frame

	# 复制文本：只含内容结构信息
	var txt := ContentFallback.detail_text(problems)
	_ok(txt.find("E_NO_SCENE") >= 0, "content ui: 复制文本含问题码")
	_ok(txt.find("问题数：2") >= 0, "content ui: 复制文本含问题数")
	_ok(txt.find("不对外发送") >= 0 or txt.find("不联网") >= 0, "content ui: 复制文本标注本地生成")

	# 横幅：主城顶部的一句提示
	var ban := ContentFallback.banner()
	add_child(ban)
	await get_tree().process_frame
	var blabels := ""
	for n in _walk(ban):
		if n is Label:
			blabels += (n as Label).text + "\n"
	_ok(blabels.find("内容数据异常") >= 0, "content ui: 横幅有提示语")
	ban.queue_free()
	await get_tree().process_frame

	# 铺页：内容坏掉时知识体系页走这条路径（原来是一张空白页）
	var saved := GameData.content_problems
	GameData.content_problems = problems
	var holder := Control.new()
	add_child(holder)
	ContentFallback.fill(holder, 0)
	await get_tree().process_frame
	var hl := ""
	for n in _walk(holder):
		if n is Label:
			hl += (n as Label).text + "\n"
	_ok(hl.find("内容数据加载失败") >= 0, "content ui: 铺页后有兜底卡")
	holder.queue_free()
	await get_tree().process_frame
	GameData.content_problems = saved

# ---------------------------------------------------------------- 工具

## 递归收集子节点。
func _walk(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_walk(c))
	return out

func _is_perm(order: Array) -> bool:
	var n := order.size()
	var seen := {}
	for v in order:
		var iv := int(v)
		if iv < 0 or iv >= n or seen.has(iv):
			return false
		seen[iv] = true
	return seen.size() == n

func _is_identity(order: Array) -> bool:
	for i in order.size():
		if int(order[i]) != i:
			return false
	return true

func _has_order_marker(opts: Array) -> bool:
	for o in opts:
		var t := str(o)
		for marker in ["以上", "都对", "都错", "都正确", "都不正确", "上述", "以下"]:
			if t.find(marker) >= 0:
				return true
	return false
