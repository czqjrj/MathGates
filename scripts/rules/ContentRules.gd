class_name ContentRules
extends RefCounted
## B12 · 提示语泄露答案的判定（纯函数，无 IO、无 UI）。
##
## 为什么需要单列一层：`hint` 是**直接显示给学生**的，而选项会被打乱。
## 若 hint 里出现正确项的原文，等于把答案抄在提示里——学生点开提示（虽然会扣分）
## 仍然不用自己算。这是内容错误，不是排版口味。
##
## 判定分两档：
## - **硬**（`hint_leaks`）：hint 里出现正确项原文（归一化后长度 ≥ 3）。
##   能机械判定、零歧义，`check_questions.gd` 直接红灯。
##   数值答案另走 `hint_leaks_num`（数字是精确记号，2 位即可判，且校验数字边界）。
## - **软**（`repeat_ratio`）：正确项有多大比例被 hint「换个说法说了一遍」
##   （如 hint 写 `y−1=2(x−1)`、答案是 `y=2x−1`）。静态判不了代数等价，
##   所以只进看板，靠 `tools/sample_hints.gd` 抽检人读。

## 短于此长度的答案不判硬泄露：「圆」「1」这类太容易巧合命中（且本身信息量小）。
const MIN_LEAK_LEN := 3
## 数值答案另算：数字是**精确记号**，2 位就够判（`16` 出现在 `b²=16` 里就是泄露）。
## 用数字边界校验，避免 `16` 命中 `2016` / `160`。
const MIN_NUM_LEN := 2
## 软指标的最短答案长度：太短的答案 LCS 比例没有意义。
const SOFT_LEN := 5
## 软指标阈值：正确项 ≥70% 的字符被 hint 里某个连续片段覆盖。
const SOFT_RATIO := 0.7

## 归一化：剥掉 `$$` 定界符（**保留**内容，公式写 LaTeX 也一样能比）、空白与中英标点。
## 只剥定界符不剥内容是关键：否则 hint 用 `$$…$$` 写公式就绕过了检查。
const PUNCT := "，。、；：（）「」『』“”‘’！？【】《》,.;:()[]!? \t\r\n—…·"

static func norm_text(t: String) -> String:
	var s := t.replace("$$", " ")
	var out := ""
	for i in s.length():
		var c := s[i]
		if PUNCT.find(c) < 0:
			out += c
	return out

## 最长公共子串长度：短文本（<200 字）直接 O(n·m) 动态规划，够快也够简单。
static func lcs_len(a: String, b: String) -> int:
	var n := a.length()
	var m := b.length()
	if n == 0 or m == 0:
		return 0
	var prev := PackedInt32Array()
	prev.resize(m + 1)
	var best := 0
	for i in range(1, n + 1):
		var cur := PackedInt32Array()
		cur.resize(m + 1)
		var ca := a[i - 1]
		for j in range(1, m + 1):
			if ca == b[j - 1]:
				var v := prev[j - 1] + 1
				cur[j] = v
				if v > best:
					best = v
		prev = cur
	return best

## 硬判定：提示里出现正确项原文。
static func hint_leaks(hint: String, answer_text: String) -> bool:
	var a := norm_text(answer_text)
	if a.length() < MIN_LEAK_LEN:
		return false
	return norm_text(hint).find(a) >= 0

## 软判定：正确项被提示「照着说」的比例（0~1）。
static func repeat_ratio(hint: String, answer_text: String) -> float:
	var a := norm_text(answer_text)
	if a.length() < SOFT_LEN:
		return 0.0
	return float(lcs_len(norm_text(hint), a)) / float(a.length())

## 数值答案的硬判定：hint 里出现这个数，且左右**不是别的数字**。
## 为什么要单独一条：`16` 出现在 `b²=16` 里是真泄露，但只有 2 个字符，
## 走 `MIN_LEAK_LEN = 3` 会被漏掉；而数字是精确记号，2 位就足以判定。
static func hint_leaks_num(hint: String, num_text: String) -> bool:
	var h := norm_text(hint)
	var n := norm_text(num_text)
	if n.length() < MIN_NUM_LEN:
		return false
	var at := h.find(n, 0)
	while at >= 0:
		var ok_before := at == 0 or not _is_digit(h[at - 1])
		var after := at + n.length()
		var ok_after := after >= h.length() or not _is_digit(h[after])
		if ok_before and ok_after:
			return true
		at = h.find(n, at + 1)
	return false

static func _is_digit(c: String) -> bool:
	return c >= "0" and c <= "9"

## 数值答案的字面形式（12.0 → "12"，避免 hint 里写 12 反而漏判）。
static func num_text(v: Variant) -> String:
	if typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v))):
		return str(int(roundf(float(v))))
	return str(v)
