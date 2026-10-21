class_name StageBase
extends Control
## 2D「闯关式」关卡共享骨架：顶栏 HUD、左侧答题面板、选项行、结算面板与上下关导航。
##
## 子类只需实现：_load()/_build_view()/_load_q()/_on_confirm()/_build_interact()/
## _build_explore()，并按需覆写配置钩子
## (_module/_pet_message/_wrong_text/_default_color/_default_title/_use_rich_text 等)。

## 关卡选项内联公式图的缩放系数(单一来源 UI)。
const CHOICE_FORMULA_SCALE := UI.CHOICE_FORMULA_SCALE

# ---------------------------------------------------------------- 数据
var _all: Dictionary = {}
var _id := ""
var _cfg: Dictionary = {}
var _stages: Array = []
var _pet: Pet

# ---------------------------------------------------------------- HUD
var _ui: Control
var _top_fill: ColorRect
var _prog: Label
var _coins: Label
var _combo_bar: ComboBar
## 计时读数(P2，仅启用限时的关卡显示)。
var _time_lbl: Label
var _panel: PanelContainer
var _action_bar: PanelContainer
var _title: Label
var _q: RichTextLabel
var _ans: VBoxContainer
var _feed: Control
var _next: Button
var _hint: Button
var _victory: PanelContainer
var _v_title: Label
var _v_star_row: HBoxContainer
var _v_rate: Label
var _v_score: Label
## 「下一星差在哪」引导(P2)。
var _v_guide: Label
var _v_coins: Label
var _dim: ColorRect
var _nav_prev: Button
var _nav_next: Button
var _live: Label
## 题干的可朗读文案(与显示文本对应，但公式转成口播而非图片标记)。
var _q_speak := ""

# ---------------------------------------------------------------- 选项
var _opt_btns: Array[Button] = []
var _opt_panels: Array[PanelContainer] = []
var _opt_badges: Array[PanelContainer] = []
var _opt_contents: Array[Control] = []
var _opt_marks: Array[Label] = []
## 选项显示顺序(乱序)：_opt_order[显示位置] = 原始下标，用于防止学生靠位置记答案。
var _opt_order: Array[int] = []
## 多选(题面 ans 为数组):可多选 + 确认作答(固定在选项与反馈之间，始终可见)。
var _multi_sel: Dictionary = {}
var _multi_row: CenterContainer
var _multi_btn: Button
## 数值/公式填空(B1，题面 type="input"):单行输入 + 提交。
var _input_edit: LineEdit

# ---------------------------------------------------------------- 状态
var _idx := 0
var _clean: Array[int] = []
var _wrongs := 0
var _hint_used := false
var _solved := false
var _done := false
var _trap_missed := false
var _q_recorded := false
var _last_picked := -1
var _explore_done := false
var _streak := 0
var _max_streak := 0
## 错题优先复习：显示下标→原始题号；记录作答时用 _q_index() 与错题账本对齐。
var _qid: Array[int] = []
var _review := false

# ---------------------------------------------------------------- BOSS 战(可选层)
## 仅当关卡 archetype==BOSS 或关卡配置显式含 boss{} 时启用，普通关不创建。
var _boss_mode := false
var _boss_cfg: Dictionary = {}
var _boss_hud: BossHud
## 推演者血量耗尽 → 强制失败结算。
var _boss_failed := false

# ---------------------------------------------------------------- 节奏(P2，可选层)
## 关卡级 rules{}：连击条默认开；限时/星时为可选(见 _apply_rules)。
var _combo_on := true
var _rules: Dictionary = {}
## 计时口径：从 _reset() 起累计，_done 后停止。
var _elapsed := 0.0
## 本关是否启用计时(Settings 总开关 ∩ 关卡 rules 含 time_limit/star_time)。
var _timing := false
var _time_limit := 0.0
var _star_time := 0.0
## 结算读取/写入的最快用时(仅计时关卡)。
var _prev_best_time := 0.0
var _new_time_rec := false
## 超时降星 / 极速奖励金币。
var _time_capped := false
var _speed_bonus := 0

func _ready() -> void:
	_load()
	_apply_review()
	_boss_mode = _boss_enabled()
	_boss_cfg = _boss_config()
	_apply_rules()
	add_child(TechBg.new())
	_build_view()
	_build_ui()
	_add_pet()
	_reset()
	_enter_fx()

## 读取关卡级节奏配置(全部可选，缺省沿用旧行为：无限时、连击条开启)。
func _apply_rules() -> void:
	var r: Variant = _cfg.get("rules")
	_rules = r if r is Dictionary else {}
	_combo_on = bool(_rules.get("show_combo_bar", true))
	_time_limit = maxf(0.0, float(_rules.get("time_limit", 0)))
	_star_time = maxf(0.0, float(_rules.get("star_time", 0)))
	_timing = Settings.challenge_timer and (_time_limit > 0.0 or _star_time > 0.0)
	set_process(_timing)

## 计时累计：仅在启用计时的关卡里推进，结算后停止。
func _process(delta: float) -> void:
	if _done or not _timing:
		return
	_elapsed += delta
	_refresh_time()

## 若本关存在历史错题，则重排题序让错题优先，并记录原始题号映射。
func _apply_review() -> void:
	var r := GameData.review_order(GameData.current_level_id(), _stages, GameData.review_focus)
	_stages = r["stages"]
	_qid = r["order"]
	_review = r["review"]

func _q_index() -> int:
	return _qid[_idx] if _idx >= 0 and _idx < _qid.size() else _idx

## 关卡界面入场：题干面板从右侧滑入 + 底部操作条上浮回弹(下一步/提示/问萌宠)。
func _enter_fx() -> void:
	if not UI.fx_on() or not is_instance_valid(_panel):
		return
	await get_tree().process_frame
	if not is_instance_valid(_panel):
		return
	slide_from(_panel, false)
	if is_instance_valid(_action_bar):
		slide_from(_action_bar, true)

## 让控件从预设锚点方向滑入(上下左右固定一侧)，回弹落位。
static func slide_from(c: Control, from_bottom: bool, dur: float = 0.42) -> void:
	var sz := c.size
	if sz.x <= 0.0 or sz.y <= 0.0:
		UI.popup_in(c)
		return
	c.pivot_offset = sz * 0.5
	c.modulate.a = 0.0
	var off := Vector2(sz.x * 0.32, sz.y * 0.5) if from_bottom else Vector2(sz.x * 0.5, 0.0)
	c.position += off
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, dur * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "position", c.position - off, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ================================================================ 配置钩子(子类覆写)
func _module() -> String: return ""
func _pet_message() -> String: return "加油！卡住就点提示～"
func _wrong_text() -> String: return "不对，再想想。"
func _victory_text(passed: bool) -> String:
	return "推演通关" if passed else "推演失败 · 请复盘"
func _default_color() -> String: return "#5ee6ff"
func _default_title() -> String: return ""
func _back_text() -> String: return "← " + Scene.origin_label("知识体系")
func _back_row_text() -> String: return "返回" + Scene.origin_label("知识体系")
func _back_scene() -> String: return "res://scenes/TheoremTree.tscn"
func _panel_label() -> String: return "QUERY"
func _report_label() -> String: return "MISSION REPORT"
func _prog_prefix() -> String: return "SEQ"
## true 时题干/反馈走内联公式(RichTextLabel)，否则纯文本(Label)。
func _use_rich_text() -> bool: return false
## 答对时的面板脉冲反馈(部分关卡没有)。
func _level_ok_fx() -> void: pass
func _next_min_width() -> int: return 200
func _bottom_half_width() -> int: return 300

# ================================================================ 子类必须实现
func _load() -> void: pass
func _build_view() -> void: pass
func _load_q() -> void: pass

## 设置题干：显示走内联公式，另存一份可朗读文案供「朗读」按钮使用（公式念内容，不念“公式”）。
func _set_q(raw: String) -> void:
	_q.text = UI.inline_formulas(raw)
	_q_speak = UI.strip_formulas(raw)

## 进入追问阶段：把标题/题干切换为追问问题(可选字段 ask，缺省给通用提示)。
func _set_followup_question(s: Dictionary) -> void:
	var ask := str(s.get("ask", ""))
	if ask.is_empty():
		ask = "根据刚才的观察，选出正确结论："
	_title.text = "追问"
	if _use_rich_text():
		_set_q(ask)
	else:
		_q.text = ask
		# 追问轮与普通轮共用同一条口播路径(B13:曾一处 strip、一处不 strip)
	_q_speak = UI.strip_formulas(ask)
	UI.tts_say(_q_speak)

# ================================================================ 萌宠
func _add_pet() -> void:
	var msg := _pet_message()
	if _review:
		msg = "这关有你的历史错题，我先排到前面了～ " + msg
	_pet = Pet.spawn(self, msg)
	_pet.tap_provider = _pet_point

func _pet_point() -> String:
	var s := _current()
	if s.has("point"):
		return str(s["point"])
	var method := str(_cfg.get("method", ""))
	var summary := str(_cfg.get("summary", ""))
	var hint := str(s.get("hint", ""))
	if hint != "":
		return "【%s】%s\n方法：%s" % [method, summary, hint]
	return "【%s】%s" % [method, summary]

func _ask_pet() -> void:
	if _pet == null:
		return
	_pet.respond(_pet_point())
	Sound.play("select")

func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.0005:
		return str(int(roundf(v)))
	return "%.2f" % v

func _current() -> Dictionary:
	if _stages.is_empty():
		return {}
	return _stages[clampi(_idx, 0, _stages.size() - 1)]

# ---------------------------------------------------------------- 流程
func _reset() -> void:
	_idx = 0
	_wrongs = 0
	_hint_used = false
	_solved = false
	_done = false
	_trap_missed = false
	_streak = 0
	_max_streak = 0
	_boss_failed = false
	_elapsed = 0.0
	_time_capped = false
	_speed_bonus = 0
	_prev_best_time = 0.0
	_new_time_rec = false
	_refresh_combo()
	_refresh_time()
	set_process(_timing)
	if _boss_mode and _boss_hud != null:
		_boss_hud.reset()
	_clean.clear()
	for i in _stages.size():
		_clean.append(0)
	if _victory != null:
		_victory.visible = false
	if _dim != null:
		_dim.visible = false
	_load_q()

func _clear_opts() -> void:
	_opt_btns.clear()
	_opt_panels.clear()
	_opt_badges.clear()
	_opt_contents.clear()
	_opt_marks.clear()
	_opt_order.clear()
	_multi_sel.clear()
	_input_edit = null
	if _multi_row != null:
		_multi_row.visible = false

func _build_choices(s: Dictionary) -> void:
	var opts: Array = s.get("opts", [])
	_opt_order = _opt_order_for(s, opts)
	for k in opts.size():
		_ans.add_child(_choice_row(k, str(opts[_opt_order[k]])))
	# 多选题:ans 为数组 -> 显示「确认作答」
	_multi_sel.clear()
	if _multi_row != null:
		_multi_row.visible = s.get("ans") is Array
	if _multi_btn != null:
		_multi_btn.disabled = true

# ---------------------------------------------------------------- 数值/公式填空(B1)
## 题面 "type":"input"：学生输入数值/公式，与 "ans"(数值) 比较；"tol" 为容差(默认 0.05)。
## 常见写法(√、²、³、π、×、÷、隐式乘法)由 StageRules.parse_math 归一化为表达式求值。
func _build_input(s: Dictionary) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_ans.add_child(col)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	col.add_child(hb)
	_input_edit = LineEdit.new()
	_input_edit.placeholder_text = str(s.get("placeholder", "输入数值，如 3.5、√2、1/2"))
	_input_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_edit.add_theme_font_size_override("font_size", UI.fs(19))
	_input_edit.custom_minimum_size = Vector2(0, 52)
	_input_edit.add_theme_color_override("font_color", UI.COL_TEXT)
	_input_edit.add_theme_color_override("font_placeholder_color", Color(UI.COL_TEXT_DIM, 0.7))
	_input_edit.add_theme_color_override("caret_color", UI.COL_ACCENT)
	_input_edit.add_theme_color_override("selection_color", Color(UI.COL_ACCENT, 0.3))
	_input_edit.add_theme_stylebox_override("normal", UI.glass_box(Color(0, 0, 0, 0.3), 10, Color(1, 1, 1, 0.16), 1, 10))
	_input_edit.add_theme_stylebox_override("focus", UI.glass_box(Color(0, 0, 0, 0.3), 10, Color(UI.COL_ACCENT, 0.6), 1, 10))
	_input_edit.text_submitted.connect(func(_t: String) -> void: _submit_input())
	hb.add_child(_input_edit)
	var b := Button.new()
	b.text = str(s.get("submit", "提交"))
	UI.primary_button(b)
	b.custom_minimum_size = Vector2(96, 52)
	b.pressed.connect(_submit_input)
	hb.add_child(b)
	# 数学符号快捷输入(触屏友好)
	var keys := HBoxContainer.new()
	keys.add_theme_constant_override("separation", 6)
	col.add_child(keys)
	for sym in ["√", "²", "³", "π", "×", "÷", "(", ")", "/", "."]:
		var kb := Button.new()
		kb.text = sym
		kb.focus_mode = Control.FOCUS_NONE
		kb.custom_minimum_size = Vector2(40, 40)
		kb.add_theme_font_size_override("font_size", UI.fs(19))
		kb.add_theme_color_override("font_color", UI.COL_TEXT)
		kb.add_theme_stylebox_override("normal", UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(1, 1, 1, 0.16), 1, 4))
		kb.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.1), 8, Color(UI.COL_ACCENT, 0.5), 1, 4))
		kb.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.3), 8, Color(UI.COL_ACCENT, 0.8), 1, 4))
		kb.pressed.connect(_insert_symbol.bind(sym))
		keys.add_child(kb)

func _insert_symbol(sym: String) -> void:
	if _input_edit == null:
		return
	_input_edit.grab_focus()
	_input_edit.insert_text_at_caret(sym)

## 提交填空：归一化后求值，与 ans 在 tol 内视为答对。
func _submit_input() -> void:
	if _solved or _done or _input_edit == null or _stages.is_empty():
		return
	_last_picked = -1
	var s := _current()
	var val = StageRules.parse_math(_input_edit.text.strip_edges())
	if val == null:
		_wrong("没看懂这个式子，试试输入数值或 sqrt(2)。")
		return
	var tol := float(s.get("tol", 0.05))
	if StageRules.num_ok(float(val), float(s.get("ans", 0.0)), tol):
		_level_ok()
	else:
		_wrong(str(s.get("wrong", "还差一点，再算算？")))

## 选项乱序：默认打乱，防止学生记住答案位置；题面写 "shuffle": false 或 "fixed": true
## 可关闭，含「以上都对」等顺序相关选项时也自动关闭。返回 [显示位置 -> 原始下标]。
func _opt_order_for(s: Dictionary, opts: Array) -> Array:
	return StageRules.order_for(s, opts)

## 显示位置 -> 原始下标(乱序关闭时恒等)。
func _orig_of(k: int) -> int:
	if k >= 0 and k < _opt_order.size():
		return _opt_order[k]
	return k

## 原始下标 -> 显示位置(找不到返回 -1)。
func _disp_of(orig: int) -> int:
	return _opt_order.find(orig)

func _choice_row(k: int, opt: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.04), 12, Color(1, 1, 1, 0.13), 1, 12))
	p.custom_minimum_size = Vector2(0, 52)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	p.add_child(hb)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(UI.COL_ACCENT, 0.5), 1, 0))
	badge.custom_minimum_size = Vector2(34, 32)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bl := UI.mono_label("ABCD".substr(k, 1), 16, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	hb.add_child(badge)

	var content: Control
	if opt.begins_with("res://") and ResourceLoader.exists(opt):
		var tex := load(opt) as Texture2D
		var tex_r := TextureRect.new()
		tex_r.texture = tex
		tex_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if tex != null:
			tex_r.custom_minimum_size = tex.get_size() * CHOICE_FORMULA_SCALE
		tex_r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content = tex_r
	else:
		var opt_txt := UI.inline_formulas(opt, 24)
		if opt_txt.find("[img") >= 0:
			var rt := RichTextLabel.new()
			rt.bbcode_enabled = true
			rt.fit_content = true
			rt.scroll_active = false
			rt.text = opt_txt
			rt.add_theme_font_override("normal_font", UI.font())
			rt.add_theme_font_override("bold_font", UI.font_bold())
			rt.add_theme_font_override("italics_font", UI.font())
			rt.add_theme_font_size_override("normal_font_size", UI.fs(18))
			rt.add_theme_font_size_override("bold_font_size", UI.fs(18))
			rt.add_theme_font_size_override("italics_font_size", UI.fs(18))
			rt.add_theme_color_override("default_color", UI.COL_TEXT)
			rt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content = rt
		else:
			var l := UI.make_label(opt_txt, 18, UI.COL_TEXT)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content = l
	hb.add_child(content)

	var mark := UI.make_label("", 20, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	mark.custom_minimum_size = Vector2(26, 0)
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(mark)

	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.set_meta("sfx_click", "none")
	btn.add_theme_stylebox_override("normal", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	btn.add_theme_stylebox_override("hover", UI.glass_box(Color(1, 1, 1, 0.07), 12, Color(UI.COL_ACCENT, 0.55), 1, 0))
	btn.add_theme_stylebox_override("pressed", UI.glass_box(Color(0, 0, 0, 0.28), 12, Color(UI.COL_ACCENT, 0.8), 1, 0))
	btn.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, Color(UI.COL_ACCENT, 0.3), 1, 0))
	btn.add_theme_stylebox_override("disabled", UI.stylebox(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0))
	btn.pressed.connect(_on_choice.bind(k))
	p.add_child(btn)

	_opt_btns.append(btn)
	_opt_panels.append(p)
	_opt_badges.append(badge)
	_opt_contents.append(content)
	_opt_marks.append(mark)
	return p

func _on_choice(k: int) -> void:
	if _solved or _done or _stages.is_empty():
		return
	if _current().get("ans") is Array:
		_multi_toggle(k)
		return
	_last_picked = k
	var correct := int(_current().get("ans", -1))
	_reveal_choices(k, _disp_of(correct))
	if _orig_of(k) == correct:
		_level_ok()
	else:
		_wrong(_wrong_text())

## 多选:切换某选项的选中态(青边高亮)，由「确认作答」结算。
func _multi_toggle(k: int) -> void:
	if _multi_sel.has(k):
		_multi_sel.erase(k)
	else:
		_multi_sel[k] = true
	for i in _opt_panels.size():
		if _multi_sel.has(i):
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_ACCENT, 0.16), 12, UI.COL_ACCENT, 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_ACCENT, 0.30), 8, UI.COL_ACCENT, 1, 0))
		else:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.04), 12, Color(1, 1, 1, 0.13), 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(UI.COL_ACCENT, 0.5), 1, 0))
	if _multi_btn != null:
		_multi_btn.disabled = _multi_sel.is_empty()

## 多选结算:所选集合与答案集合完全一致才算对。
func _multi_confirm() -> void:
	if _solved or _done or _stages.is_empty():
		return
	_last_picked = -1
	var s := _current()
	var arr: Array = s.get("ans", [])
	var correct_set: Dictionary = {}
	for a in arr:
		correct_set[int(a)] = true
	var picked_orig: Array = []
	for kk in _multi_sel.keys():
		picked_orig.append(_orig_of(int(kk)))
	var ok := StageRules.multi_ok(picked_orig, arr)
	var correct_disp: Dictionary = {}
	for o in correct_set.keys():
		correct_disp[_disp_of(int(o))] = true
	for i in _opt_btns.size():
		_opt_btns[i].disabled = true
		var is_c := correct_disp.has(i)
		var picked := _multi_sel.has(i)
		if is_c:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_SUCCESS, 0.15), 12, UI.COL_SUCCESS, 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_SUCCESS, 0.35), 8, UI.COL_SUCCESS, 1, 0))
			_opt_marks[i].text = "✓"
			_opt_marks[i].add_theme_color_override("font_color", UI.COL_SUCCESS)
			if _opt_contents[i] is Label:
				(_opt_contents[i] as Label).add_theme_color_override("font_color", UI.COL_TEXT)
		elif picked:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_DANGER, 0.15), 12, UI.COL_DANGER, 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_DANGER, 0.35), 8, UI.COL_DANGER, 1, 0))
			_opt_marks[i].text = "✗"
			_opt_marks[i].add_theme_color_override("font_color", UI.COL_DANGER)
		else:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(0, 0, 0, 0.18), 12, Color(1, 1, 1, 0.06), 1, 12))
			_opt_marks[i].modulate.a = 0.0
	if _multi_btn != null:
		_multi_btn.disabled = true
	if ok:
		_level_ok()
	else:
		_wrong(_wrong_text())

func _reveal_choices(picked: int, correct: int) -> void:
	for i in _opt_btns.size():
		_opt_btns[i].disabled = true
		if i == correct:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_SUCCESS, 0.15), 12, UI.COL_SUCCESS, 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_SUCCESS, 0.35), 8, UI.COL_SUCCESS, 1, 0))
			_opt_marks[i].text = "✓"
			_opt_marks[i].add_theme_color_override("font_color", UI.COL_SUCCESS)
		elif i == picked:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_DANGER, 0.15), 12, UI.COL_DANGER, 1, 12))
			_opt_badges[i].add_theme_stylebox_override("panel", UI.glass_box(Color(UI.COL_DANGER, 0.35), 8, UI.COL_DANGER, 1, 0))
			_opt_marks[i].text = "✗"
			_opt_marks[i].add_theme_color_override("font_color", UI.COL_DANGER)
		else:
			_opt_panels[i].add_theme_stylebox_override("panel", UI.glass_box(Color(0, 0, 0, 0.18), 12, Color(1, 1, 1, 0.06), 1, 12))
			_opt_marks[i].modulate.a = 0.0
		if _opt_contents[i] is Label:
			(_opt_contents[i] as Label).add_theme_color_override("font_color", UI.COL_TEXT if i == correct else Color(1, 1, 1, 0.32))
		elif _opt_contents[i] is TextureRect:
			var tex_r := _opt_contents[i] as TextureRect
			tex_r.modulate = Color(1, 1, 1, 1) if i == correct else (Color(1, 0.55, 0.6, 0.95) if i == picked else Color(1, 1, 1, 0.32))

func _level_ok() -> void:
	if _solved:
		return
	_solved = true
	if _wrongs == 0:
		_clean[_idx] = 1
	if not _q_recorded:
		_q_recorded = true
		GameData.record_answer(GameData.current_level_id(), _q_index(), str(_current().get("name", "")), true, -1, -1, _module())
	Sound.play("correct")
	if _pet != null:
		_pet.cheer()
	var s := _current()
	var msg := "回答正确！"
	if bool(s.get("trap", false)):
		msg = "漂亮，成功规避陷阱！"
	if s.has("explain"):
		msg += "  " + UI.inline_formulas(str(s["explain"]), 22)
	_show_feed(msg, UI.COL_SUCCESS)
	_next.disabled = false
	_streak += 1
	_max_streak = maxi(_max_streak, _streak)
	GameData.note_streak(_streak)
	_refresh_combo()
	if _boss_mode and _boss_hud != null:
		_boss_hud.set_streak(_streak)
		if _boss_hud.hit_boss():
			_on_boss_enraged()
	_fx_correct(_last_picked)
	_level_ok_fx()

## 答对动效：选项处冲击爆发 + 漂浮文字(连击时金色、字更大)。
func _fx_correct(k: int) -> void:
	if _ui == null or not is_instance_valid(_ui):
		return
	var pos := _ui.size * 0.5
	if k >= 0 and k < _opt_panels.size():
		pos = Vfx.center_of(_opt_panels[k], pos)
	Vfx.burst(_ui, pos, UI.COL_SUCCESS)
	if _streak >= 2:
		Vfx.float_text(_ui, pos, "连击 x%d" % _streak, Color("#ffd479"), 34)
		if _streak % 3 == 0:
			Vfx.star_burst(_ui, pos, 12, 0.9)
	else:
		Vfx.float_text(_ui, pos, "正确", UI.COL_SUCCESS, 28)
	Vfx.screen_flash(_ui, UI.COL_SUCCESS, 0.10, 0.38)

func _wrong(msg: String) -> void:
	if _solved or _done:
		return
	_wrongs += 1
	if bool(_current().get("trap", false)):
		_trap_missed = true
	if not _q_recorded:
		_q_recorded = true
		var ansv: Variant = _current().get("ans", -1)
		var ansi: int = -1 if ansv is Array else int(ansv)
		GameData.record_answer(GameData.current_level_id(), _q_index(), str(_current().get("name", "")), false, _orig_of(_last_picked), ansi, _module())
	Sound.play("wrong")
	if _pet != null:
		_pet.comfort()
	if _current().has("explain"):
		msg += "\n[复盘] " + UI.inline_formulas(str(_current()["explain"]), 22)
	_show_feed(msg, UI.COL_DANGER)
	_streak = 0
	_refresh_combo()
	_fx_wrong()
	if _boss_mode and _boss_hud != null:
		_boss_hud.set_streak(0)
		if _boss_hud.hit_player():
			_boss_player_down()

## 答错动效：所选项旋转摇头 + 红环扩散 + 画面红闪。
func _fx_wrong() -> void:
	if _ui == null or not is_instance_valid(_ui):
		return
	var pos := _ui.size * 0.5
	if _last_picked >= 0 and _last_picked < _opt_panels.size():
		Vfx.wobble(_opt_panels[_last_picked])
		pos = Vfx.center_of(_opt_panels[_last_picked], pos)
	Vfx.ring(_ui, pos, UI.COL_DANGER, 96.0, 0.55)
	Vfx.float_text(_ui, pos, "再想想", UI.COL_DANGER, 24)
	Vfx.screen_flash(_ui, UI.COL_DANGER, 0.14, 0.4)

## 顶栏连击条：连击≥2 时显示，条越亮、金币倍率越高；断连则隐藏。
func _refresh_combo() -> void:
	if _combo_bar == null or not is_instance_valid(_combo_bar):
		return
	_combo_bar.visible = _combo_on
	_combo_bar.set_streak(_streak if _combo_on else 0)

## 顶栏计时读数：超星时转金、超时限转红，提醒节奏。
func _refresh_time() -> void:
	if _time_lbl == null or not is_instance_valid(_time_lbl):
		return
	_time_lbl.visible = _timing
	if not _timing:
		return
	_time_lbl.text = "计时 %.1fs" % _elapsed
	var col := UI.COL_TEXT_DIM
	if _time_limit > 0.0 and _elapsed > _time_limit:
		col = UI.COL_DANGER
	elif _star_time > 0.0 and _elapsed > _star_time:
		col = Color("#ffd479")
	_time_lbl.add_theme_color_override("font_color", col)

func _use_hint() -> void:
	if _solved or _done or _hint_used or _stages.is_empty():
		return
	_hint_used = true
	_hint.disabled = true
	if GameData.consume_hint_token():
		_show_feed("[提示卡] " + str(_current().get("hint", "")), Color("#5ee6ff"))
		# 道具即时演出：提示卡化为光点在面板上炸开。
		if _ui != null and is_instance_valid(_ui):
			var pos := Vfx.center_of(_panel, _ui.size * 0.5)
			Vfx.burst(_ui, pos, Color("#5ee6ff"), 0.9)
			Vfx.float_text(_ui, pos, "提示卡", Color("#5ee6ff"), 26)
	else:
		_wrongs += 1
		_show_feed("[提示] " + str(_current().get("hint", "")), Color("#ffd479"))

func _next_pressed() -> void:
	if not _solved or _done:
		return
	if _idx < _stages.size() - 1:
		_idx += 1
		_load_q()
	else:
		_finish()

# ---------------------------------------------------------------- BOSS 战
## 是否启用战斗层：关卡 archetype==BOSS，或关卡配置显式含 boss{}。
func _boss_enabled() -> bool:
	return str(GameData.current_level.get("archetype", "")) == "BOSS" or _cfg.get("boss") is Dictionary

func _boss_config() -> Dictionary:
	var b: Variant = _cfg.get("boss")
	return b if b is Dictionary else {}

func _boss_first_clear_coins() -> int:
	var r: Variant = _boss_cfg.get("reward")
	if r is Dictionary:
		return int((r as Dictionary).get("first_clear_coins", 200))
	return 200

## 守关者血量过半：狂暴反馈(仅视觉，不改题序)。
func _on_boss_enraged() -> void:
	if _boss_hud == null or not is_instance_valid(_boss_hud):
		return
	var col := _boss_hud.boss_color()
	Vfx.float_text(_ui, _boss_hud.boss_avatar_center(), "狂暴！", col, 30)
	Vfx.screen_flash(_ui, Color(col, 0.5), 0.22, 0.5)

## 推演者血量耗尽 → 短暂停顿后强制失败结算。
func _boss_player_down() -> void:
	if _done or _boss_failed:
		return
	_boss_failed = true
	if _boss_hud != null:
		_boss_hud.player_down()
	_show_feed("推演能量耗尽 · 守关者压制了你。", UI.COL_DANGER)
	await get_tree().create_timer(0.8).timeout
	if not _done:
		_finish()

## 结算评级：S(全对满分无陷阱) / A(三星) / B(二星) / C(其余)
func _grade(st: int, clean: int, total: int, trap_missed: bool) -> String:
	return StageRules.grade(st, clean, total, trap_missed)

## P2 · 三星条件显式化：结算给出「下一星差在哪」的引导文案(无引导返回空串)。
func _next_star_hint(st: int, clean: int, total: int) -> String:
	if _boss_failed:
		return "推演能量归零 · 补齐一次完整推演即可重新挑战"
	var msg := ""
	if st <= 0:
		var need2 := int(ceil(0.6 * float(total)))
		msg = "零失误 %d / %d 轮即可拿到 2 星（当前 %d）" % [need2, total, clean]
	elif st == 2:
		var need3 := int(ceil(0.8 * float(total)))
		var lack := maxi(0, need3 - clean)
		if lack > 0:
			msg = "再 %d 轮零失误即可升到 3 星（需 %d / %d）" % [lack, need3, total]
	elif _trap_missed:
		msg = "不踩陷阱即可拿到 S 评级"
	elif clean < total:
		msg = "全程 %d 轮零失误可拿 S 评级" % total
	if _time_capped:
		var t := "超时降星：用时压到 %.0f 秒内可升回" % _time_limit
		msg = t if msg == "" else msg + "  ·  " + t
	return msg

func _finish() -> void:
	_done = true
	var total := _stages.size()
	var clean := 0
	for c in _clean:
		clean += c
	var ratio := float(clean) / float(maxi(1, total))
	var lid := GameData.current_level_id()
	# C2 · 当日重试降级 + P2 超时/陷阱/守关失败：星级判定收口在 StageRules。
	var cap := GameData.star_cap_for_attempt(lid) if lid != "" else 3
	var judged := StageRules.judge_stars(clean, total, _trap_missed, _timing, _time_limit,
		_elapsed, _boss_failed, cap)
	var st := int(judged["stars"])
	_time_capped = bool(judged["time_capped"])
	var star_capped := bool(judged["star_capped"])
	var lv0 := GameData.player_level()
	var prev_best := int(GameData.level_records.get(lid, {}).get("best_stars", 0)) if lid != "" else 0
	# P2 · 读取历史最快用时(在写入前)，用于结算展示与「新速度纪录」判定。
	_prev_best_time = GameData.best_time_of(lid) if (lid != "" and _timing) else 0.0
	# 奖励合成收口在 StageRules：基础/零失误/星级/连击/首通/极速/倍率/翻倍。
	var first_clear := StageRules.boss_first_clear(_boss_mode, st, prev_best)
	var boosted := GameData.consume_coin_boost()
	var combo_mult := ComboBar.multiplier(_max_streak)
	var rw := StageRules.compose_reward(clean, st, _trap_missed, _max_streak,
		_boss_first_clear_coins() if first_clear else 0,
		StageRules.speed_bonus_ok(st, _timing, _star_time, _elapsed), combo_mult, boosted)
	var reward := int(rw["reward"])
	_speed_bonus = int(rw["speed_bonus"])
	var combo_bonus := int(rw["combo_bonus"])
	if _max_streak > GameData.best_streak:
		GameData.best_streak = _max_streak
	# C1/C2 · 星级/经验/金币/记录收口结算：首次达成给全额，重复通关给折扣且每日封顶。
	var granted := reward
	var repeat_discounted := false
	if lid != "":
		var settle := GameData.settle_level(lid, st, clean, total, _trap_missed, reward)
		granted = int(settle.get("granted", reward))
		repeat_discounted = not bool(settle.get("full", true))
	else:
		GameData.add_coins(reward)
	if _timing and lid != "" and st > 0:
		_new_time_rec = _prev_best_time <= 0.0 or _elapsed < _prev_best_time
		GameData.record_level_time(lid, _elapsed)
	var lv1 := GameData.player_level()
	_update_hud()

	var pct := int(round(ratio * 100.0))
	var passed := st > 0
	if passed and _pet != null:
		var inten := 1.6 if st >= 3 else 1.0
		if lv1 > lv0:
			inten = maxf(inten, 1.5)
		_pet.celebrate(inten)
		if lv1 > lv0:
			_pet.on_level_up(lv1)
	if _boss_mode:
		_v_title.text = "击败守关者！" if passed else "被守关者压制 · 请复盘"
	else:
		_v_title.text = _victory_text(passed)
	_v_title.add_theme_color_override("font_color", UI.COL_TEXT if passed else UI.COL_DANGER)
	var grade := _grade(st, clean, total, _trap_missed)
	if st >= 3:
		_v_rate.text = "评级 %s   ·   正确率 %d%%   ·   完美通关！" % [grade, pct]
		_v_rate.add_theme_color_override("font_color", Color("#ffd479"))
	else:
		_v_rate.text = "评级 %s   ·   正确率 %d%%" % [grade, pct]
		_v_rate.add_theme_color_override("font_color", UI.COL_ACCENT if passed else UI.COL_DANGER)
	var score_txt := "无失误 %d / %d 关" % [clean, total]
	if _max_streak >= 2:
		score_txt += "   ·   最高连击 x%d" % _max_streak
	if combo_bonus > 0:
		score_txt += "   ·   连击奖励 +%d (×%.1f)" % [combo_bonus, combo_mult]
	if _speed_bonus > 0:
		score_txt += "   ·   极速奖励 +%d" % _speed_bonus
	if _timing:
		var t_txt := "用时 %.1fs" % _elapsed
		if _new_time_rec:
			t_txt += " · 新速度纪录！"
		elif _prev_best_time > 0.0:
			t_txt += "（最快 %.1fs）" % _prev_best_time
		score_txt += "   ·   " + t_txt
	if _time_capped:
		score_txt += "   ·   超时降星"
	if passed and st > prev_best and prev_best > 0:
		score_txt += "   ·   新纪录！"
	if boosted:
		score_txt += "   ·   双倍金币"
	if star_capped:
		score_txt += "   ·   今日重试：星级上限 %d" % PlayerRules.STAR_CAP_REPEAT
	if repeat_discounted:
		score_txt += "   ·   重复通关奖励 ×%.1f" % PlayerRules.REPEAT_REWARD_RATE
	if first_clear:
		score_txt += "   ·   首通奖励 +%d" % _boss_first_clear_coins()
	_v_score.text = score_txt
	_v_guide.text = _next_star_hint(st, clean, total)
	if star_capped:
		var cap_txt := "今日重试：本关上星上限 %d 星" % PlayerRules.STAR_CAP_REPEAT
		_v_guide.text = cap_txt if _v_guide.text == "" else _v_guide.text + "  ·  " + cap_txt
	_v_guide.visible = _v_guide.text != ""
	for c in _v_star_row.get_children():
		_v_star_row.remove_child(c)
		c.free()
	var tex_full := UI.icon("icon_star_full", 54, UI.COL_ACCENT)
	var tex_empty := UI.icon("icon_star_empty", 54, Color("#3c4a66"))
	for i in 3:
		var filled := i < st
		var tex_r := TextureRect.new()
		tex_r.texture = tex_full if (filled and tex_full != null) else tex_empty
		if tex_r.texture != null:
			tex_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_r.custom_minimum_size = Vector2(54, 54)
		tex_r.pivot_offset = Vector2(27, 27)
		tex_r.scale = Vector2(0.01, 0.01)
		tex_r.modulate.a = 0.0
		_v_star_row.add_child(tex_r)
		var delay := 0.35 + i * 0.2
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(tex_r, "scale", Vector2.ONE, UI.DUR_XSLOW).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(tex_r, "modulate:a", 1.0, UI.DUR_NORMAL)
		if filled:
			get_tree().create_timer(delay).timeout.connect(func() -> void: Sound.play("star"))
	_v_coins.text = "金币  +0"
	Sound.play("complete" if passed else "error")
	_refresh_nav()
	if _boss_mode and _boss_hud != null and passed:
		_boss_hud.boss_defeated()
		Vfx.burst(_ui, _boss_hud.boss_avatar_center(), _boss_hud.boss_color(), 1.3)
		Vfx.float_text(_ui, _boss_hud.boss_avatar_center(), "击败！", _boss_hud.boss_color(), 40)
		await get_tree().create_timer(0.9).timeout
	_dim.visible = true
	_victory.visible = true
	if passed:
		_spawn_confetti()
	await get_tree().process_frame
	if is_instance_valid(_victory):
		UI.popup_in(_victory)
	var tc := create_tween()
	tc.tween_interval(0.75)
	tc.tween_callback(func() -> void:
		if not is_instance_valid(_ui) or not is_instance_valid(_victory):
			return
		Vfx.celebrate(_ui, Vfx.center_of(_victory, _ui.size * 0.5), UI.COL_ACCENT)
		Vfx.coin_fly(_ui, Vfx.center_of(_victory, _ui.size * 0.5), Vfx.center_of(_coins, Vector2(_ui.size.x - 120.0, 30.0)), 12))
	tc.tween_method(func(v: float) -> void: _v_coins.text = "金币  +%d" % int(v), 0.0, float(granted), 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.tween_callback(func() -> void:
		if is_instance_valid(_v_coins):
			_v_coins.text = "金币  +%d      (共 %d)" % [granted, GameData.coins])

func _show_feed(msg: String, col: Color) -> void:
	if _feed == null:
		return
	if _feed is RichTextLabel:
		(_feed as RichTextLabel).text = "[color=#%s]%s[/color]" % [col.to_html(false), UI.inline_formulas(msg)]
		UI.tts_say(UI.strip_formulas(msg))
	else:
		(_feed as Label).text = msg
		(_feed as Label).add_theme_color_override("font_color", col)
		UI.tts_say(msg)
	_pop_feed()

## 反馈行出现时轻微提亮闪烁，提示刚才的判定进来了。
func _pop_feed() -> void:
	if not UI.fx_on() or not is_instance_valid(_feed):
		return
	_feed.modulate.a = 0.35
	var tw := _feed.create_tween().set_parallel(true)
	tw.tween_property(_feed, "modulate:a", 1.0, UI.DUR_SLOW).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## 清空反馈区(供子类 _load_q 使用)。
func _feed_clear() -> void:
	if _feed is RichTextLabel:
		(_feed as RichTextLabel).text = ""
	elif _feed is Label:
		(_feed as Label).text = ""

func _update_hud() -> void:
	if _prog == null:
		return
	_prog.text = "%s %02d / %02d" % [_prog_prefix(), _idx + 1, _stages.size()]
	if _coins != null:
		_coins.text = "◆ %d" % GameData.coins
	var total := maxi(1, _stages.size())
	var tw := create_tween()
	tw.tween_property(_top_fill, "anchor_right", float(_idx) / float(total), UI.DUR_XSLOW).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------- UI
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = UiConst.LAYER_STAGE_UI
	add_child(layer)
	_ui = Control.new()
	_ui.theme = UI.make_theme()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(_ui)
	layer.add_child(_ui)

	var tl := Control.new()
	tl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tl.offset_bottom = 3
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(tl)
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.07)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(track)
	tl.add_child(track)
	_top_fill = ColorRect.new()
	_top_fill.color = Color(str(_cfg.get("color", _default_color())))
	_top_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top_fill.anchor_right = 0.0
	_top_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(_top_fill)

	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.topbar_box())
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 62)
	bar.offset_bottom = 62
	_ui.add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	bar.add_child(hb)
	hb.add_child(UI.ghost_button(_back_text(), func() -> void:
		Scene.goto_origin(_back_scene())
	))
	var vl := ColorRect.new()
	vl.color = UI.COL_LINE
	vl.custom_minimum_size = Vector2(1, 18)
	vl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vl)
	hb.add_child(UI.make_label(str(_cfg.get("title", _default_title())), 21))
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UI.glass_box(Color(1, 1, 1, 0.05), 8, Color(UI.COL_ACCENT, 0.3), 1, 10))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cl := UI.mono_label(str(_cfg.get("method", "")), 13, Color(UI.COL_ACCENT, 0.85))
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(cl)
	hb.add_child(chip)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_combo_bar = ComboBar.new()
	_combo_bar.visible = false
	hb.add_child(_combo_bar)
	_time_lbl = UI.mono_label("", 15, UI.COL_TEXT_DIM)
	_time_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_time_lbl.visible = false
	hb.add_child(_time_lbl)
	_coins = UI.mono_label("◆ 0", 16, Color("#ffd479"))
	_coins.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_coins)
	_prog = UI.mono_label("%s 00 / 00" % _prog_prefix(), 17, UI.COL_ACCENT)
	_prog.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_prog)

	_panel = UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.3), 14, 18)
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 1.0
	var lay := UI.stage_layout()
	_panel.offset_left = float(lay["left"])
	_panel.offset_right = float(lay["left"]) + float(lay["width"])
	_panel.offset_top = 62
	_panel.offset_bottom = -90
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 12)
	_panel.add_child(pv)
	pv.add_child(UI.mono_label(_panel_label(), 13, UI.COL_ACCENT))
	_title = UI.make_label("", 22, Color("#ffd479"))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(_title)
	var hl := ColorRect.new()
	hl.color = UI.COL_LINE
	hl.custom_minimum_size = Vector2(0, 1)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(hl)
	_q = RichTextLabel.new()
	_q.bbcode_enabled = true
	_q.fit_content = true
	_q.scroll_active = true
	_q.selection_enabled = false
	_q.focus_mode = Control.FOCUS_NONE
	_q.custom_minimum_size = Vector2(0, 124)
	_q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_q.add_theme_font_override("normal_font", UI.font())
	_q.add_theme_font_override("bold_font", UI.font())
	_q.add_theme_font_size_override("normal_font_size", UI.fs(18))
	_q.add_theme_font_size_override("bold_font_size", UI.fs(18))
	_q.add_theme_color_override("default_color", UI.COL_TEXT)
	_q.add_theme_constant_override("line_separation", 5)
	pv.add_child(_q)
	var ans_scroll := ScrollContainer.new()
	ans_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ans_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(ans_scroll)
	_ans = VBoxContainer.new()
	_ans.add_theme_constant_override("separation", 10)
	_ans.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ans_scroll.add_child(_ans)
	UI.enable_touch_scroll(ans_scroll)
	# 多选确认条：固定在“选项区”与“反馈区”之间，不随选项滚动，始终可见。
	_multi_row = CenterContainer.new()
	_multi_row.visible = false
	_multi_btn = Button.new()
	_multi_btn.text = "确认作答"
	_multi_btn.custom_minimum_size = Vector2(180, 46)
	_multi_btn.disabled = true
	UI.primary_button(_multi_btn)
	_multi_btn.pressed.connect(_multi_confirm)
	_multi_row.add_child(_multi_btn)
	pv.add_child(_multi_row)
	if _use_rich_text():
		var fr := RichTextLabel.new()
		fr.bbcode_enabled = true
		fr.fit_content = true
		fr.scroll_active = false
		fr.selection_enabled = false
		fr.focus_mode = Control.FOCUS_NONE
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fr.custom_minimum_size = Vector2(0, 44)
		fr.add_theme_font_override("normal_font", UI.font())
		fr.add_theme_font_override("bold_font", UI.font())
		fr.add_theme_font_size_override("normal_font_size", UI.fs(15))
		fr.add_theme_color_override("default_color", UI.COL_TEXT_DIM)
		fr.add_theme_constant_override("line_separation", 4)
		_feed = fr
	else:
		var fl := UI.make_label("", 15, UI.COL_TEXT_DIM)
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fl.custom_minimum_size = Vector2(0, 44)
		_feed = fl
	pv.add_child(_feed)

	if _boss_mode:
		_boss_hud = BossHud.new()
		_boss_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(_boss_hud)
		_boss_hud.configure(_boss_cfg, _stages.size(), str(_cfg.get("method", "守关者")))

	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.offset_left = -_bottom_half_width()
	bottom.offset_right = _bottom_half_width()
	bottom.offset_top = -88
	bottom.offset_bottom = -26
	bottom.add_theme_stylebox_override("panel", UI.glass_box(Color(0.03, 0.05, 0.09, 0.88), 12, Color(UI.COL_ACCENT, 0.25), 1, 12))
	bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(bottom)
	_action_bar = bottom
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 14)
	bottom.add_child(bh)
	_hint = UI.ghost_button("提示 (−评分)", _use_hint, 16)
	bh.add_child(_hint)
	bh.add_child(UI.ghost_button("问萌宠", _ask_pet, 16))
	bh.add_child(UI.voice_button(func() -> void: UI.tts_say(_q_speak if _q_speak != "" else _q.text), 16))
	bh.add_child(UI.ghost_button("重新挑战", func() -> void: _reset(), 16))
	_next = Button.new()
	_next.text = "下一关 →"
	_next.custom_minimum_size = Vector2(_next_min_width(), 52)
	UI.primary_button(_next)
	_next.disabled = true
	_next.pressed.connect(_next_pressed)
	bh.add_child(_next)

	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.02, 0.05, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_dim)
	_victory = UI.card(true, UI.COL_ACCENT, UI.COL_GLASS, Color(UI.COL_ACCENT, 0.4), 16, 26)
	_victory.set_anchors_preset(Control.PRESET_CENTER)
	_victory.custom_minimum_size = Vector2(540, 0)
	_victory.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_victory.grow_vertical = Control.GROW_DIRECTION_BOTH
	_victory.offset_left = -270
	_victory.offset_right = 270
	_victory.offset_top = -216
	_victory.offset_bottom = 216
	_victory.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_victory)
	var vv := VBoxContainer.new()
	vv.alignment = BoxContainer.ALIGNMENT_CENTER
	vv.add_theme_constant_override("separation", 14)
	_victory.add_child(vv)
	vv.add_child(UI.mono_label(_report_label(), 13, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	_v_title = UI.make_label(_victory_text(true), 30, UI.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_title)
	var vll := ColorRect.new()
	vll.color = UI.COL_LINE
	vll.custom_minimum_size = Vector2(0, 1)
	vll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vv.add_child(vll)
	_v_star_row = HBoxContainer.new()
	_v_star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_v_star_row.add_theme_constant_override("separation", 14)
	vv.add_child(_v_star_row)
	_v_rate = UI.make_label("", 20, UI.COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_rate)
	_v_score = UI.make_label("", 16, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_score)
	_v_guide = UI.make_label("", 15, Color("#ffd479"), HORIZONTAL_ALIGNMENT_CENTER)
	_v_guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vv.add_child(_v_guide)
	_v_coins = UI.make_label("", 22, Color("#ffd479"), HORIZONTAL_ALIGNMENT_CENTER)
	vv.add_child(_v_coins)
	vv.add_child(UI.make_label(str(_cfg.get("summary", "")), 15, UI.COL_TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vv.add_child(row)
	_nav_prev = UI.ghost_button("上一关", func() -> void: GameData.goto_prev_level(), 15)
	row.add_child(_nav_prev)
	row.add_child(UI.ghost_button(_back_row_text(), func() -> void:
		Scene.goto_origin(_back_scene())
	, 16))
	var again := Button.new()
	again.text = "重新推演"
	again.custom_minimum_size = Vector2(180, 56)
	UI.primary_button(again)
	again.pressed.connect(func() -> void: _reset())
	row.add_child(again)
	_nav_next = UI.ghost_button("下一关", func() -> void: GameData.goto_next_level(), 15)
	row.add_child(_nav_next)
	_victory.visible = false
	_dim.visible = false

func _refresh_nav() -> void:
	if _nav_prev != null:
		_nav_prev.disabled = not GameData.has_prev_level()
	if _nav_next != null:
		_nav_next.disabled = not GameData.has_next_level()

func _spawn_confetti() -> void:
	Confetti.spawn(_ui)
