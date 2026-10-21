class_name StageRules
## A4 第四刀：从 StageBase 切出的**结算纯规则**——无状态、无 IO、无 autoload 依赖。
## 单一来源：星级判定（正确率/陷阱/超时/守关失败/当日重试降级）、奖励合成
## （基础/星级/无失误/连击/首通/极速/连击倍率/金币翻倍）、评级、Boss 首通与极速奖励判定。
## 调用方约定：状态由 StageBase 取出后传入；写入（HUD/存档/动画）仍在 StageBase。
## 单测：tests/Tests.gd::_test_stage_rules()（构造数据）；结算流程由 SMOKE/UI-SMOKE 回归保护。

# ---------------------------------------------------------------- 星级判定
const STAR3_RATIO := 0.8   ## 正确率 ≥ 0.8 → 3 星
const STAR2_RATIO := 0.6   ## 正确率 ≥ 0.6 → 2 星（以下 0 星）

## 结算星级判定(纯)：正确率定基础星级 → 陷阱扣 1 → 超时扣 1（最多降到 1 星）→
## 守关失败归 0 → 当日重试上限。返回 {stars, time_capped, star_capped}。
static func judge_stars(clean: int, total: int, trap_missed: bool,
		timing: bool, time_limit: float, elapsed: float,
		boss_failed: bool, attempt_cap: int) -> Dictionary:
	var ratio := float(clean) / float(maxi(1, total))
	var st := 0
	if ratio >= STAR3_RATIO:
		st = 3
	elif ratio >= STAR2_RATIO:
		st = 2
	if trap_missed and st > 0:
		st -= 1
	var time_capped := false
	if st > 0 and timing and time_limit > 0.0 and elapsed > time_limit:
		if st > 1:
			st -= 1
		time_capped = true
	if boss_failed:
		st = 0
	var star_capped := false
	if st > 0 and st > attempt_cap:
		st = attempt_cap
		star_capped = true
	return { "stars": st, "time_capped": time_capped, "star_capped": star_capped }

# ---------------------------------------------------------------- 奖励合成
const BASE_REWARD := 30        ## 结算基础金币
const PER_CLEAN := 15          ## 每关零失误加成
const PER_STAR := 20           ## 每星加成
const STAR3_BONUS := 60        ## 满星额外加成
const NO_TRAP_BONUS := 30      ## 全程不踩陷阱加成
const PER_STREAK := 3          ## 每 1 连击加成
const SPEED_BONUS := 40        ## 星时内通关的极速奖励

## Boss 首通判定(纯)：守关模式 + 有星 + 此前从未通关（历史最高 0 星）。
static func boss_first_clear(boss_mode: bool, stars: int, prev_best: int) -> bool:
	return boss_mode and stars > 0 and prev_best == 0

## 极速奖励判定(纯)：有星 + 限时 + 星时有效 + 用时不超过星时。
static func speed_bonus_ok(stars: int, timing: bool, star_time: float, elapsed: float) -> bool:
	return stars > 0 and timing and star_time > 0.0 and elapsed <= star_time

## 结算奖励合成(纯)：基础 + 零失误/星级/连击加成 → 首通 → 极速 → 连击倍率 → 金币翻倍。
## combo_mult 来自 ComboBar.multiplier(streak)。返回 {reward, speed_bonus, combo_bonus}。
static func compose_reward(clean: int, stars: int, trap_missed: bool, max_streak: int,
		first_clear_coins: int, speed_ok: bool, combo_mult: float, boosted: bool) -> Dictionary:
	var r := BASE_REWARD + clean * PER_CLEAN + stars * PER_STAR
	if stars >= 3:
		r += STAR3_BONUS
	if not trap_missed:
		r += NO_TRAP_BONUS
	r += max_streak * PER_STREAK
	r += first_clear_coins
	var speed := 0
	if speed_ok:
		speed = SPEED_BONUS
		r += speed
	var combo := 0
	if combo_mult > 1.0:
		combo = int(round(float(r) * (combo_mult - 1.0)))
		r += combo
	if boosted:
		r *= 2
	return { "reward": r, "speed_bonus": speed, "combo_bonus": combo }

# ---------------------------------------------------------------- 选项乱序 / 答题判定
## 顺序相关标记：选项含这些措辞时乱序自动关闭（「以上都对」等）。
const SHUFFLE_MARKERS := ["以上", "都对", "都错", "都正确", "都不正确", "上述", "以下"]

## 是否允许乱序（纯）：题面 shuffle:false / fixed:true 关闭；选项 <2 关闭；含顺序相关标记关闭。
static func shuffle_allowed(s: Dictionary, opts: Array) -> bool:
	if not bool(s.get("shuffle", true)) or bool(s.get("fixed", false)):
		return false
	if opts.size() < 2:
		return false
	for o in opts:
		var t := str(o)
		for marker in SHUFFLE_MARKERS:
			if t.find(marker) >= 0:
				return false
	return true

## 显示顺序（纯）：_opt_order[显示位置] = 原始下标；不允许乱序时恒等。
static func order_for(s: Dictionary, opts: Array) -> Array[int]:
	var order: Array[int] = []
	for i in opts.size():
		order.append(i)
	if shuffle_allowed(s, opts):
		order.shuffle()
	return order

## 多选判定（纯）：所选集与答案集完全一致才为真（集合语义，顺序无关）。
static func multi_ok(picked_orig: Array, ans: Array) -> bool:
	var want: Dictionary = {}
	for a in ans:
		want[int(a)] = true
	var got: Dictionary = {}
	for p in picked_orig:
		got[int(p)] = true
	if got.size() != want.size():
		return false
	for k in got.keys():
		if not want.has(k):
			return false
	return true

## 填空判定（纯）：数值在容差内视为答对（|差值| <= tol）。
static func num_ok(val: float, ans: float, tol: float) -> bool:
	return absf(val - ans) <= tol

# ---------------------------------------------------------------- 填空解析
## 把常见数学写法(√、²、³、×、÷、π、隐式乘法)转成表达式可解析的形式(纯)。
static func norm_math(text: String) -> String:
	var s := text.strip_edges()
	s = s.replace(" ", "").replace("　", "")
	s = s.replace("×", "*").replace("·", "*").replace("÷", "/")
	s = s.replace("−", "-").replace("–", "-").replace("—", "-")
	s = s.replace("π", "3.141592653589793")
	s = s.replace("²", "^2").replace("³", "^3").replace("¹", "^1").replace("⁰", "^0")
	var re := RegEx.new()
	re.compile("([0-9]+(?:\\.[0-9]+)?)\\^([0-9]+)")
	s = re.sub(s, "pow($1,$2)", true)
	re.compile("√\\s*\\(([^()]*)\\)")
	s = re.sub(s, "sqrt($1)", true)
	re.compile("√\\s*([0-9]+(?:\\.[0-9]+)?)")
	s = re.sub(s, "sqrt($1)", true)
	s = s.replace("√", "sqrt")
	re.compile("([0-9])\\s*([a-zA-Z(])")
	s = re.sub(s, "$1*$2", true)
	re.compile("\\)\\s*([0-9a-zA-Z(])")
	s = re.sub(s, ")*$1", true)
	return s

## 填空解析(纯)：归一化后求值；空串/语法错/非数值返回 null。
static func parse_math(text: String) -> Variant:
	var s := norm_math(text)
	if s == "":
		return null
	if s.is_valid_float():
		return s.to_float()
	if s.is_valid_int():
		return float(s.to_int())
	# 整数字面量统一转 float：否则 Expression 里 1/2 走整数除法得 0，分数填空被误判错。
	# 前后视避开小数("3.5" 的 3/5)与已展开常数，其余位置(含连续除法)安全。
	var lit := RegEx.new()
	lit.compile("(?<![0-9.])([0-9]+)(?![0-9.])")
	s = lit.sub(s, "$1.0", true)
	var e := Expression.new()
	if e.parse(s) != OK:
		return null
	var v: Variant = e.execute()
	if e.has_execute_failed():
		return null
	if v != null and (v is float or v is int):
		return float(v)
	return null

# ---------------------------------------------------------------- 评级
## 结算评级(纯)：S = 3 星 + 全程零失误 + 不踩陷阱；3 星 A；2 星 B；其余 C。
static func grade(stars: int, clean: int, total: int, trap_missed: bool) -> String:
	if stars >= 3 and clean == total and not trap_missed:
		return "S"
	if stars >= 3:
		return "A"
	if stars == 2:
		return "B"
	return "C"
