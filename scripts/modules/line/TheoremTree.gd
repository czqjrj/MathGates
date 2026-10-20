extends Control
## 双层导航学习地图：第一层「分册」标签，第二层当前分册下的「章节」卡片，点章节进入知识点节点地图。
## 同一套 UI 同时服务两条线，由 kind 区分：
##   kind="knowledge" → 知识体系(TheoremTree.tscn)
##   kind="method"    → 方法推演(WorldMap.tscn)，章节为「专题方法实验」
## 章节按 curriculum.json 的 "kind" 过滤，分册归属/章号由 data/textbooks.json 决定；
## 有独立 scene 的关卡走对应场景;缺 scene 属坏数据(A3 起不再兜底 Battle),原地报错;新增章节只需写进 curriculum.json 即会自动出现。

## 展示哪一类章节（knowledge / method）
@export var kind := "knowledge"
## 顶栏标题与副标题（按场景覆盖）
@export var header_title := "知识体系"
@export var header_sub := "KNOWLEDGE MAP"


## 各模块主题(单元)名，与关卡名 "N-M xxx" 的 N 对应(1 起)
const GROUP_TITLES := {
	"line_eq": ["倾斜角 · 斜率", "直线方程的四种形式", "平行与垂直", "距离公式", "直线系方程", "对称与最值"],
	"circle_eq": ["圆的方程", "一般方程", "点 · 直线与圆", "切线", "圆与圆的位置关系", "轨迹与最值"],
	"space":  ["空间向量基础", "方向向量 · 位置关系", "空间角", "距离问题", "三垂线 · 翻折", "球与最值"],
	"vector": ["基础本源", "共线与线性运算", "基底与坐标", "数量积与夹角", "投影与几何恒等式", "最值与范围"],
	"ellipse": ["椭圆定义与轨迹", "标准方程与几何性质", "焦半径与焦点三角形", "中点弦 · 点差法", "直线与椭圆 · 硬解定理"],
	"hyperbola": ["双曲线的定义", "标准方程与 a、b、c", "渐近线", "离心率", "双曲线综合应用", "焦点三角形", "焦半径", "点差法 · 中点弦", "直线与双曲线", "共轭双曲线", "定点定值与最值"],
	"parabola": ["抛物线的定义", "四种标准方程", "焦点与焦半径", "焦点弦与通径", "抛物线的综合应用", "几何性质", "焦点弦性质", "点差法 · 中点弦", "直线与抛物线", "定点定值", "最值与距离"],
	"solid_basic": ["基本立体图形", "棱台与圆台", "表面积与展开", "体积", "体对角线与截面", "球与组合体", "直观图与三视图", "空间点线面位置关系", "平行关系", "垂直关系", "空间角", "空间距离"],
	"trig": ["三角函数探究"],
	"functions": ["函数实验探究"],
	"set_logic": ["集合与逻辑探究"],
	"inequalities": ["不等式探究"],
	"vectors": ["平面向量探究"],
	"sequences": ["数列的概念", "等差数列", "等差数列的前n项和", "等比数列", "等比数列的前n项和", "递推数列", "构造法求通项", "通项与前n项和的关系", "错位相减求和", "裂项相消求和"],
	"conics": ["解析几何探究"],
	"probability": ["概率与统计探究"],
	"derivative": ["导数探究"],
	"complex": ["复数探究"],
	"counting": ["计数原理探究"],
	"thinking": ["数学思想探究"],
	"statistics": ["统计探究"],
	"random_var": ["随机变量探究"],
	"corr_data": ["相关与回归探究"],
}

## 教材分册、章节分册归属、教材章号均由「教材版本」决定(见 data/textbooks.json)，
## 运行期通过 GameData.book_defs() / book_of_chapter() / chapter_no() 读取，
## 切换版本后章节排序与分册自动跟随。数学思想综合无教材章号，显示「综合」。

const NODE_W := 208.0
const NODE_H := 182.0
const BOSS_W := 240.0
const BOSS_H := 204.0
const TOP_MARGIN := 220.0
const ROW_H := 208.0
const BOTTOM_MARGIN := 240.0
const MIN_W := 1120.0
## 单行节点数上限：超过则折到下一行，保证节点标题之间留出空隙不压字。
const MAX_ROW_COLS := 5

## 沿路径流动的脉冲点
class Pulse extends Control:
	var color := Color("#5ee6ff")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 14.0, Color(color, 0.10))
		draw_circle(c, 5.5, Color(color, 0.9))
		draw_circle(c, 2.4, Color(1, 1, 1, 0.95))

## 地图上的知识点节点：科技环形节点(细环 + 进度弧 + 等宽编号)
class MapNode extends Control:
	signal activated

	var li := -1
	var code := ""
	var title := ""
	var sub := ""
	var color := Color("#5B8FF9")
	var unlocked := true
	var stars := 0
	var max_stars := 3
	var is_boss := false
	## 标题/技法文字的最大绘制宽度(由布局按列间距给定，超出则省略号收尾，避免相邻节点压字)
	var title_max_w := 0.0

	# ---- 冒险标记(P3) ----
	var has_chest := false
	var chest_state := 0        # 0=无 1=条件未达 2=可领取 3=已领取
	var has_event := false
	var event_done := false
	var gate_need := 0          # >0 表示 Boss 门：需本单元累计星数
	var gate_have := 0
	var optional := false       # 支线节点(分支路线)

	var _hover := false
	var _t := 0.0

	var _press := false
	var _press_pos := Vector2.ZERO
	var _press_scroll := 0.0

	func _ready() -> void:
		# PASS:让触摸拖动穿透到外层 ScrollContainer,手机上才能上下滑动
		mouse_filter = Control.MOUSE_FILTER_PASS
		custom_minimum_size = size
		mouse_entered.connect(func() -> void: _hover = true; queue_redraw())
		mouse_exited.connect(func() -> void: _hover = false; queue_redraw())
		set_process(true)

	func _scroll_v() -> float:
		var n := get_parent()
		while n != null:
			if n is ScrollContainer:
				return (n as ScrollContainer).scroll_vertical
			n = n.get_parent()
		return 0.0

	func _process(delta: float) -> void:
		if not UI.animations:
			return
		_t += delta
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		# 在「抬起且未拖动/未滚屏」时才激活,避免滑动地图时误进关卡;
		# 不 accept_event(),让事件继续传到 ScrollContainer 以支持触摸滚动。
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index != MOUSE_BUTTON_LEFT:
				return
			if mb.pressed:
				_press = true
				_press_pos = mb.global_position
				_press_scroll = _scroll_v()
			elif _press:
				_press = false
				var moved: float = (mb.global_position - _press_pos).length()
				if moved < 12.0 and absf(_scroll_v() - _press_scroll) < 4.0:
					activated.emit()

	func _draw() -> void:
		var f := UI.font()
		var mf := UI.mono_font()
		var cx := size.x * 0.5
		var cy := 54.0 + sin(_t * 1.5 + float(li)) * 3.0
		var R := 54.0 if is_boss else 46.0
		var base_col := color
		if not unlocked:
			base_col = Color("#4a4f63")

		if unlocked and _hover:
			draw_circle(Vector2(cx, cy), R + 16.0, Color(UI.COL_ACCENT.r, UI.COL_ACCENT.g, UI.COL_ACCENT.b, 0.10))

		# HUD 刻度环
		var tick_col := Color(base_col, 0.55 if unlocked else 0.22)
		for i in 24:
			var a := TAU * float(i) / 24.0 - PI / 2.0
			var ln := 5.0 if i % 6 == 0 else 2.0
			var d := Vector2(cos(a), sin(a))
			draw_line(Vector2(cx, cy) + d * (R + 4.0), Vector2(cx, cy) + d * (R + 4.0 + ln), tick_col, 1.2, true)

		draw_circle(Vector2(cx, cy), R, Color(0.05, 0.07, 0.12, 0.82))
		draw_arc(Vector2(cx, cy), R, 0.0, TAU, 64, Color(base_col, 0.75 if unlocked else 0.30), 2.4, true)

		# 旋转外弧
		if unlocked:
			var spin := _t * 0.6 + float(li)
			draw_arc(Vector2(cx, cy), R + 12.0, spin, spin + PI * 0.45, 14, Color(base_col, 0.55), 1.6, true)
			draw_arc(Vector2(cx, cy), R + 12.0, spin + PI, spin + PI * 1.45, 14, Color(base_col, 0.55), 1.6, true)

		var prog := 0.0
		if max_stars > 0:
			prog = clampf(float(stars) / float(max_stars), 0.0, 1.0)
		if unlocked and prog > 0.001:
			draw_arc(Vector2(cx, cy), R, -PI / 2.0, -PI / 2.0 + TAU * prog, 64, UI.COL_ACCENT, 3.0, true)

		if unlocked and _hover:
			draw_arc(Vector2(cx, cy), R + 5.0, 0.0, TAU, 64, Color(UI.COL_ACCENT, 0.55), 1.5, true)
			_draw_brackets(cx, cy, R + 6.0, Color(UI.COL_ACCENT, 0.75))

		if is_boss and unlocked:
			var ph := 0.5 + 0.5 * sin(_t * 3.0)
			draw_arc(Vector2(cx, cy), R + ph * 14.0, 0.0, TAU, 48, Color(1.0, 0.45, 0.52, 0.4 * (1.0 - ph)), 2.0, true)

		var num_col := Color(1, 1, 1, 0.94) if unlocked else Color(1, 1, 1, 0.40)
		_center(mf, code, cx, cy + 10.0, 26, num_col)
		if is_boss:
			_center(mf, "BOSS", cx, cy - R - 8.0, 11, Color("#fb7185", 0.95))

		if not unlocked:
			_draw_lock(Vector2(cx + R - 14.0, cy - R + 8.0), Color(1, 1, 1, 0.5))

		var tcol := UI.COL_TEXT if unlocked else Color(UI.COL_TEXT_DIM, 0.75)
		_center(f, title, cx, cy + R + 24.0, 16, tcol, title_max_w)
		if sub != "":
			_center(mf, sub, cx, cy + R + 42.0, 11, Color(UI.COL_TEXT_DIM, 0.85), title_max_w)
		_draw_stars(cx, size.y - 12.0)
		_draw_adventure(cx, cy, R, mf)

	## 冒险标记：宝箱角标(右下)、随机事件菱形(左上)、Boss 门星数进度(底部)。
	func _draw_adventure(cx: float, cy: float, R: float, mf: Font) -> void:
		if has_event:
			_draw_event(Vector2(cx - R * 0.72, cy - R * 0.72))
		if has_chest:
			_draw_chest(Vector2(cx + R * 0.72, cy + R * 0.66))
		if optional and unlocked:
			_center(mf, "支线", cx, cy - R - 20.0, 11, Color("#c4b5fd", 0.9))
		if gate_need > 0 and not unlocked:
			_center(mf, "★ %d/%d" % [gate_have, gate_need], cx, size.y - 30.0, 12, Color("#ffd479"))

	func _draw_chest(at: Vector2) -> void:
		var col := Color("#ffd479")
		if chest_state == 3:
			col = Color("#5AD8A6")
		elif chest_state == 1:
			col = Color(UI.COL_TEXT_DIM, 0.8)
		var w := 22.0
		var h := 16.0
		var r := Rect2(at - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
		draw_rect(r, Color(0.06, 0.08, 0.13, 0.92), true)
		draw_rect(r, col, false, 2.0)
		draw_line(Vector2(r.position.x, r.position.y + h * 0.42), Vector2(r.position.x + w, r.position.y + h * 0.42), col, 1.6, true)
		draw_circle(Vector2(at.x, r.position.y + h * 0.42), 2.2, col)
		if chest_state == 2:
			var ph := 0.5 + 0.5 * sin(_t * 3.5)
			draw_arc(at, 15.0 + ph * 5.0, 0, TAU, 28, Color(col, 0.5 * (1.0 - ph)), 1.6, true)

	func _draw_event(at: Vector2) -> void:
		var col := Color("#5ee6ff") if not event_done else Color(UI.COL_TEXT_DIM, 0.7)
		var s := 7.0
		var pts := PackedVector2Array([
			at + Vector2(0, -s), at + Vector2(s, 0), at + Vector2(0, s), at + Vector2(-s, 0),
		])
		draw_colored_polygon(pts, Color(col, 0.95 if not event_done else 0.4))
		if not event_done:
			var ph := 0.5 + 0.5 * sin(_t * 4.0)
			draw_arc(at, s + 3.0 + ph * 3.0, 0, TAU, 20, Color(col, 0.5 * (1.0 - ph)), 1.5, true)

	func _draw_lock(at: Vector2, col: Color) -> void:
		draw_arc(at + Vector2(0, -4), 5.0, PI, TAU, 20, col, 2.0, true)
		draw_rect(Rect2(at + Vector2(-7, -4), Vector2(14, 10)), col, true)

	func _draw_stars(cx: float, baseline_y: float) -> void:
		var sz := 16.0
		var gap := 4.0
		var total := 3.0 * sz + 2.0 * gap
		var x := cx - total * 0.5
		var top := baseline_y - sz
		for i in 3:
			var full := i < stars
			var tex := UI.icon("icon_star_full" if full else "icon_star_empty", int(sz),
				UI.COL_ACCENT if unlocked else Color("#3c4a66"))
			if tex != null:
				var mod := Color(1, 1, 1, 1) if unlocked else Color(0.5, 0.53, 0.62)
				draw_texture_rect(tex, Rect2(Vector2(x, top), Vector2(sz, sz)), false, mod)
			else:
				var f := UI.font()
				draw_string(f, Vector2(x, baseline_y), "★" if full else "☆",
					HORIZONTAL_ALIGNMENT_LEFT, -1, int(UI.fs(int(sz))),
					UI.COL_ACCENT if full else Color("#3c4a66"))
			x += sz + gap

	func _center(f: Font, text: String, cx: float, by: float, size_px: int, col: Color, max_w := 0.0) -> void:
		var px := UI.fs(size_px)
		var shown := _fit(f, text, px, max_w)
		var w := f.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var pos := Vector2(cx - w * 0.5, by)
		draw_string_outline(f, pos, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(2, int(px * 0.22)), Color(0, 0, 0, 0.7))
		draw_string(f, pos, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

	## 超过 max_w(max_w<=0 视为不限制)时逐字裁掉并以省略号收尾。
	func _fit(f: Font, text: String, px: int, max_w: float) -> String:
		if max_w <= 0.0:
			return text
		if f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= max_w:
			return text
		var t := text
		while t.length() > 1:
			t = t.substr(0, t.length() - 1)
			if f.get_string_size(t + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= max_w:
				return t + "…"
		return "…"

	func _draw_brackets(cx: float, cy: float, half: float, col: Color) -> void:
		var L := 12.0
		draw_polyline(PackedVector2Array([Vector2(cx - half, cy - half + L), Vector2(cx - half, cy - half), Vector2(cx - half + L, cy - half)]), col, 2.0, true)
		draw_polyline(PackedVector2Array([Vector2(cx + half - L, cy - half), Vector2(cx + half, cy - half), Vector2(cx + half, cy - half + L)]), col, 2.0, true)
		draw_polyline(PackedVector2Array([Vector2(cx - half, cy + half - L), Vector2(cx - half, cy + half), Vector2(cx - half + L, cy + half)]), col, 2.0, true)
		draw_polyline(PackedVector2Array([Vector2(cx + half - L, cy + half), Vector2(cx + half, cy + half), Vector2(cx + half, cy + half - L)]), col, 2.0, true)

## 分册标签：HUD 斜切面板(册代码 + 册名 + 进度 + 章节数)。
class BookTab extends Control:
	var owner_tree: Control
	var bi := 0
	var title := ""
	var code := ""
	var color := Color(UI.COL_ACCENT)
	var active := false
	var locked := false
	var stars := 0
	var max_stars := 0
	var chapters := 0

	var _hover := false
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(func() -> void: pivot_offset = size * 0.5)
		mouse_entered.connect(func() -> void: _hover = true; _lift(true); queue_redraw())
		mouse_exited.connect(func() -> void: _hover = false; _lift(false); queue_redraw())
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		set_process(true)

	func _process(delta: float) -> void:
		if not UI.animations:
			return
		_t += delta
		if active:
			queue_redraw()

	func _lift(on: bool) -> void:
		var target := Vector2(1.035, 1.035) if on else Vector2.ONE
		if not UI.animations:
			scale = target
			return
		pivot_offset = size * 0.5
		create_tween().tween_property(self, "scale", target, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				owner_tree.call("_select_book", bi)
				accept_event()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var accent := color if not locked else Color(0.42, 0.45, 0.52)
		var cut := 13.0
		var pts := PackedVector2Array([
			Vector2(cut, 0), Vector2(w, 0), Vector2(w, h - cut),
			Vector2(w - cut, h), Vector2(0, h), Vector2(0, cut),
		])
		var pulse := 0.5 + 0.5 * sin(_t * 2.6)

		var bg := Color(0.04, 0.06, 0.11, 0.9)
		if active:
			bg = Color(accent.r, accent.g, accent.b, 0.20)
		elif _hover:
			bg = Color(1, 1, 1, 0.10)
		draw_colored_polygon(pts, bg)
		if active:
			draw_colored_polygon(pts, Color(accent.r, accent.g, accent.b, 0.06 + 0.06 * pulse))

		var brd := Color(accent, 0.85 + 0.15 * pulse) if active else Color(1, 1, 1, 0.30 if _hover else 0.14)
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, brd, 1.8 if active else 1.0, true)
		draw_line(Vector2(cut + 2, 1.5), Vector2(w - 2, 1.5), Color(accent, 0.95 if active else 0.35), 2.0)

		var mf := UI.mono_font()
		var fb := UI.font_bold()
		draw_string(mf, Vector2(11, 21), code, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(12), Color(accent, 0.95))
		draw_string(fb, Vector2(cut + 8, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(16), UI.COL_TEXT if not locked else Color(UI.COL_TEXT_DIM, 0.85))
		var ct := "%d章" % chapters
		var ctw := mf.get_string_size(ct, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(11)).x
		draw_string(mf, Vector2(w - 10 - ctw, 21), ct, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(11), Color(UI.COL_TEXT_DIM, 0.9))

		var bar := Rect2(11, h - 14, w - 22, 6)
		draw_rect(bar, Color(0, 0, 0, 0.4), true)
		var ratio := 0.0
		if max_stars > 0:
			ratio = clampf(float(stars) / float(max_stars), 0.0, 1.0)
		if ratio > 0.001:
			var fw := maxf(bar.size.x * ratio, 4.0)
			draw_rect(Rect2(bar.position, Vector2(fw, bar.size.y)), accent, true)
			draw_circle(Vector2(bar.position.x + fw, bar.position.y + bar.size.y * 0.5), 3.0, Color(1, 1, 1, 0.95))

## 章节卡片：卡片化外观 + 可拖拽排序 + 悬停/呼吸动画。
class TabCard extends Control:
	var owner_tree: Control
	var mi := 0
	var num := 0
	var title := ""
	var chapter_label := ""
	var color := Color("#5B8FF9")
	var active := false
	var locked := false
	var stars := 0
	var max_stars := 0
	var levels_count := 0

	var _hover := false
	var _t := 0.0
	var _drag_begun := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(func() -> void: pivot_offset = size * 0.5)
		mouse_entered.connect(func() -> void: _hover = true; _lift(true))
		mouse_exited.connect(func() -> void: _hover = false; _lift(false))
		set_process(true)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_DRAG_BEGIN:
			_drag_begun = true
		elif what == NOTIFICATION_DRAG_END:
			_drag_begun = false

	func _process(delta: float) -> void:
		if not UI.animations:
			return
		_t += delta
		if active:
			queue_redraw()

	func _lift(on: bool) -> void:
		var target := Vector2(1.045, 1.045) if on else Vector2.ONE
		if not UI.animations:
			scale = target
			return
		pivot_offset = size * 0.5
		var tw := create_tween()
		tw.tween_property(self, "scale", target, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_drag_begun = false
				elif not _drag_begun:
					owner_tree.call("_select_module", mi)
					accept_event()

	# 拖拽排序：整张卡片可作为拖拽源/放置目标
	func _get_drag_data(_at: Vector2) -> Variant:
		_drag_begun = true
		var pv := PanelContainer.new()
		pv.add_theme_stylebox_override("panel", UI.glass_box(Color(color, 0.4), 10, color, 2, 14))
		var l := UI.make_label(title, 16, UI.COL_TEXT)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv.add_child(l)
		pv.custom_minimum_size = Vector2(150, 42)
		set_drag_preview(pv)
		return { "type": "chapter_tab", "mi": mi }

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and str((data as Dictionary).get("type", "")) == "chapter_tab"

	func _drop_data(_at: Vector2, data: Variant) -> void:
		owner_tree.call("_reorder_cards", int((data as Dictionary).get("mi", mi)), mi)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var accent := color if not locked else Color(0.42, 0.45, 0.52)
		var cut := 12.0
		var pulse := 0.5 + 0.5 * sin(_t * 2.6)

		# HUD 斜切面板
		var pts := PackedVector2Array([
			Vector2(cut, 0), Vector2(w, 0), Vector2(w, h - cut),
			Vector2(w - cut, h), Vector2(0, h), Vector2(0, cut),
		])
		var bg := Color(0.05, 0.07, 0.12, 0.85)
		if active:
			bg = Color(color.r, color.g, color.b, 0.16 + 0.06 * pulse)
		elif _hover:
			bg = Color(1, 1, 1, 0.09)
		draw_colored_polygon(pts, bg)
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color(accent, 0.9) if active else Color(1, 1, 1, 0.30 if _hover else 0.14), 2.0 if active else 1.0, true)
		draw_line(Vector2(cut + 2, 1.5), Vector2(w - 2, 1.5), Color(accent, 0.95), 2.0)

		var mf := UI.mono_font()
		var fb := UI.font_bold()

		# 章号徽章(左上)
		var label := chapter_label if chapter_label != "" else "%02d" % num
		var bw := mf.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(12)).x + 16.0
		var by := 8.0
		var bpts := PackedVector2Array([
			Vector2(12, by), Vector2(12 + bw, by), Vector2(12 + bw + 6, by + 11),
			Vector2(12 + bw, by + 22), Vector2(12, by + 22), Vector2(12 + 6, by + 11),
		])
		draw_colored_polygon(bpts, Color(accent, 0.16))
		var bclosed := bpts.duplicate()
		bclosed.append(bpts[0])
		draw_polyline(bclosed, Color(accent, 0.75), 1.2, true)
		draw_string(mf, Vector2(12 + 8, by + 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(12), Color(accent, 0.98))

		# 状态(右上,小圆点 + 文本)
		var scol := Color(UI.COL_TEXT_DIM, 0.85)
		var stxt := "已解锁"
		if active:
			scol = Color(color, 0.98)
			stxt = "正在学习"
		elif locked:
			scol = Color(1, 1, 1, 0.42)
			stxt = "未解锁"
		var sf := UI.fs(12)
		var sw := UI.font().get_string_size(stxt, HORIZONTAL_ALIGNMENT_LEFT, -1, sf).x
		draw_circle(Vector2(w - 16 - sw - 8, by + 11), 3.0, scol)
		draw_string(UI.font(), Vector2(w - 16 - sw, by + 15), stxt, HORIZONTAL_ALIGNMENT_LEFT, -1, sf, scol)

		# 标题
		var tcol := UI.COL_TEXT if not locked else Color(UI.COL_TEXT_DIM, 0.7)
		var tfit := _fit_title(fb, title, w - 32.0)
		draw_string(fb, Vector2(16, 60), str(tfit[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(tfit[0]), tcol)

		# 副标题(关卡数) + 星数
		draw_string(mf, Vector2(16, 80), "%d 关" % levels_count, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(11), Color(UI.COL_TEXT_DIM, 0.8))
		var s := "★ %d / %d" % [stars, max_stars]
		var sw2 := mf.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(12)).x
		draw_string(mf, Vector2(w - 16 - sw2, 80), s, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(12), Color(UI.COL_ACCENT if not locked else UI.COL_TEXT_DIM, 0.95))

		# 进度条
		var bar := Rect2(16, h - 13, w - 32, 6)
		draw_rect(bar, Color(0, 0, 0, 0.4), true)
		var ratio := 0.0
		if max_stars > 0:
			ratio = clampf(float(stars) / float(max_stars), 0.0, 1.0)
		if ratio > 0.001:
			draw_rect(Rect2(bar.position, Vector2(maxf(bar.size.x * ratio, 4.0), bar.size.y)), accent, true)

		# active 扫描线
		if active:
			var sy := fposmod(_t * 26.0, h)
			draw_line(Vector2(3, sy), Vector2(w - 3, sy), Color(color, 0.18), 2.0)

		# 角标(悬停/激活)
		if _hover or active:
			_draw_brackets(w, h, Color(accent, 0.9 if active else 0.6))

		# 拖拽把手
		for k in 3:
			draw_circle(Vector2(w - 14, h * 0.5 - 10 + k * 10), 1.6, Color(1, 1, 1, 0.35))

	## 标题过长时先缩小字号，仍放不下则省略号收尾，避免撑破卡片。
	func _fit_title(f: Font, text: String, max_w: float) -> Array:
		for base in [18, 16, 14, 13]:
			var px := UI.fs(base)
			if f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= max_w:
				return [px, text]
		var px2 := UI.fs(13)
		var t := text
		while t.length() > 1:
			t = t.substr(0, t.length() - 1)
			if f.get_string_size(t + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, px2).x <= max_w:
				return [px2, t + "…"]
		return [px2, "…"]

	func _draw_brackets(w: float, h: float, col: Color) -> void:
		var L := 10.0
		var o := 4.0
		draw_polyline(PackedVector2Array([Vector2(o, o + L), Vector2(o, o), Vector2(o + L, o)]), col, 2.0, true)
		draw_polyline(PackedVector2Array([Vector2(w - o - L, o), Vector2(w - o, o), Vector2(w - o, o + L)]), col, 2.0, true)
		draw_polyline(PackedVector2Array([Vector2(o, h - o - L), Vector2(o, h - o), Vector2(o + L, h - o)]), col, 2.0, true)
		draw_polyline(PackedVector2Array([Vector2(w - o - L, h - o), Vector2(w - o, h - o), Vector2(w - o, h - o - L)]), col, 2.0, true)

## 单元标题条：HUD 括号 + 两侧导轨 + 等宽编号。
class UnitHeader extends Control:
	var prefix := ""
	var title := ""
	var color := Color(UI.COL_ACCENT)
	var boss := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_meta("unit_label", true)
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var cy := size.y * 0.5
		var f := UI.mono_font()
		var txt := prefix + title
		var px := UI.fs(15)
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var x0 := (w - tw) * 0.5
		var lx := x0 - 14.0
		var rx := x0 + tw + 14.0
		var rail := Color(color, 0.22)
		draw_line(Vector2(48, cy), Vector2(lx - 9.0, cy), rail, 1.0)
		draw_line(Vector2(rx + 9.0, cy), Vector2(w - 48, cy), rail, 1.0)
		draw_circle(Vector2(48, cy), 2.0, Color(color, 0.55))
		draw_circle(Vector2(w - 48, cy), 2.0, Color(color, 0.55))
		var L := 9.0
		draw_polyline(PackedVector2Array([Vector2(lx, cy - L), Vector2(lx - 8, cy), Vector2(lx, cy + L)]), color, 2.0, true)
		draw_polyline(PackedVector2Array([Vector2(rx, cy - L), Vector2(rx + 8, cy), Vector2(rx, cy + L)]), color, 2.0, true)
		draw_string(f, Vector2(x0, cy + px * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)

## 顶栏底部动态扫描线。
class HudLine extends Control:
	var color := Color(UI.COL_ACCENT)
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
		set_process(true)

	func _process(delta: float) -> void:
		if not UI.animations:
			return
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var y := size.y * 0.5
		draw_line(Vector2(0, y), Vector2(w, y), Color(color, 0.16), 1.0)
		var seg := 110.0
		var x := fposmod(_t * 150.0, w + seg) - seg
		draw_line(Vector2(maxf(x, 0.0), y), Vector2(minf(x + seg, w), y), Color(color, 0.85), 2.0)

var _star_lbl: Label
var _module_idx := 0
var _book_row: HBoxContainer
var _book_present: Array = []
var _book_idx := 0
var _tabs: HBoxContainer
var _tab_scroll: ScrollContainer
var _content: Control
var _scroll: ScrollContainer
var _panel_layer: CanvasLayer
var _mods: Array = []
var _levels: Array = []
var _groups: Array = []
var _mod_col := Color.WHITE
var _chapter_index := -1
var _path_pts := PackedVector2Array()
var _pulse: Pulse
var _pulse_t := 0.0
## 本会话已「记录为已解锁」的关卡 id(供解锁礼花只放一次)
var _unlocked_seen := {}

func _ready() -> void:
	theme = UI.make_theme()
	add_child(TechBg.new())
	_build_modules()
	# 从某关返回时,默认定位到该关卡所属章节(按 id 定位,顺序可能被拖拽重排过)
	var ci := GameData.last_chapter_index()
	if ci >= 0 and ci < GameData.chapters.size():
		var cid := str(GameData.chapters[ci].get("id", ""))
		_module_idx = maxi(0, _find_module(cid))
	_compute_books()
	_build_topbar()
	if GameData.chapters.is_empty():
		return
	_build_scroll()
	_build_map(true)
	Pet.spawn(self, "沿地图路径逐点点亮知识点吧！")
	GameData.progress_changed.connect(_on_progress)
	set_process(true)

func _on_progress() -> void:
	_refresh_star()
	_rebuild_tabs()
	_build_map(false)

func _process(delta: float) -> void:
	if not UI.animations:
		return
	if _path_pts.size() < 2 or _pulse == null or not is_instance_valid(_pulse):
		return
	_pulse_t = fposmod(_pulse_t + delta * 0.05, 1.0)
	var idx := int(_pulse_t * float(_path_pts.size() - 1))
	_pulse.position = _path_pts[idx] - Vector2(15, 15)



func _chapter_index_of(module_id: String) -> int:
	for i in GameData.chapters.size():
		if str(GameData.chapters[i].get("id", "")) == module_id:
			return i
	return -1

## 由课程表生成当前体系(kind)各模块(章节),新增章节无需改代码。
## 顺序：自定义拖拽顺序优先；随后把「正在学习」的章节提到最前。
func _build_modules() -> void:
	_mods.clear()
	for ci in GameData.chapters.size():
		var ch: Dictionary = GameData.chapters[ci]
		if GameData.chapter_kind(ci) != kind:
			continue
		_mods.append({
			"id": str(ch.get("id", "")),
			"title": str(ch.get("title", "")),
			"color": str(ch.get("color", "#5B8FF9")),
		})
	_apply_saved_order()

## 按存档里的自定义顺序重排(未列出的章节按原顺序补在后面)
func _apply_saved_order() -> void:
	var order: Array = GameData.chapter_order
	if order.is_empty():
		return
	var by_id: Dictionary = {}
	for m in _mods:
		by_id[str(m["id"])] = m
	var out: Array = []
	for id in order:
		var key := str(id)
		if by_id.has(key):
			out.append(by_id[key])
			by_id.erase(key)
	for m in _mods:
		if by_id.has(str(m["id"])):
			out.append(m)
	_mods = out

func _find_module(id: String) -> int:
	for i in _mods.size():
		if str(_mods[i]["id"]) == id:
			return i
	return -1

# ---------------------------------------------------------------- 分册
## 计算存在的分册列表(含知识章节的册),并把当前选中章节所属册设为当前册。
func _compute_books() -> void:
	_book_present = []
	for b in GameData.book_defs():
		if _count_in_book(str(b["id"])) > 0:
			_book_present.append(str(b["id"]))
	_book_idx = maxi(0, _book_present.find(_book_of(_module_idx)))

func _count_in_book(bk: String) -> int:
	var n := 0
	for m in _mods:
		if GameData.book_of_chapter(str(m["id"])) == bk:
			n += 1
	return n

## 某全局模块索引所属的分册 id
func _book_of(mi: int) -> String:
	if mi < 0 or mi >= _mods.size():
		return ""
	return GameData.book_of_chapter(str(_mods[mi]["id"]))

## 当前分册下的模块全局索引(按 _mods 顺序)
func _visible_mis() -> Array:
	var out: Array = []
	if _book_idx < 0 or _book_idx >= _book_present.size():
		return out
	var bk := str(_book_present[_book_idx])
	for mi in _mods.size():
		if _book_of(mi) == bk:
			out.append(mi)
	return out

func _build_book_tabs() -> void:
	if _book_row == null:
		return
	for c in _book_row.get_children():
		c.queue_free()
	for i in _book_present.size():
		_book_row.add_child(_book_button(i))

func _book_button(i: int) -> Control:
	var bk := str(_book_present[i])
	var title := bk
	for b in GameData.book_defs():
		if str(b["id"]) == bk:
			title = str(b["title"])
	var code := bk.to_upper()
	match bk:
		"bx1": code = "B1"
		"bx2": code = "B2"
		"bx3": code = "B3"
		"xb1": code = "X1"
		"xb2": code = "X2"
		"xb3": code = "X3"
		"idea": code = "Σ"
	var tab := BookTab.new()
	tab.owner_tree = self
	tab.bi = i
	tab.title = title
	tab.code = code
	tab.color = _book_color(bk)
	tab.active = i == _book_idx
	tab.locked = _book_locked(bk)
	tab.chapters = _count_in_book(bk)
	var agg := _book_stars(bk)
	tab.stars = int(agg[0])
	tab.max_stars = int(agg[1])
	tab.custom_minimum_size = Vector2(172, 52)
	tab.size = Vector2(172, 52)
	return tab

func _book_color(bk: String) -> Color:
	for b in GameData.book_defs():
		if str(b["id"]) == bk:
			return Color(str(b.get("color", "#5ee6ff")))
	return Color("#5ee6ff")

## 某分册下所有章节的 [累计星数, 累计满星]
func _book_stars(bk: String) -> Array:
	var s := 0
	var m := 0
	for mi in _mods.size():
		if _book_of(mi) != bk:
			continue
		var ci := _chapter_index_of(str(_mods[mi]["id"]))
		if ci >= 0:
			s += GameData.chapter_stars(GameData.chapters[ci])
			m += GameData.chapter_max_stars(GameData.chapters[ci])
	return [s, m]

## 分册是否全部未解锁
func _book_locked(bk: String) -> bool:
	for mi in _mods.size():
		if _book_of(mi) != bk:
			continue
		var ci := _chapter_index_of(str(_mods[mi]["id"]))
		if ci >= 0 and GameData.is_chapter_unlocked(ci):
			return false
	return true

## 切换分册:若当前选中章节不属于该册,自动选中该册第一张卡片。
func _select_book(i: int) -> void:
	if i < 0 or i >= _book_present.size() or i == _book_idx:
		return
	_book_idx = i
	Sound.play("select")
	var ids := _visible_mis()
	if not ids.is_empty() and _book_of(_module_idx) != str(_book_present[i]):
		_module_idx = int(ids[0])
	_build_book_tabs()
	_rebuild_tabs()
	_build_map(true)

# ---------------------------------------------------------------- 顶栏
func _build_topbar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.topbar_box())
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 64)
	bar.offset_bottom = 64
	add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	bar.add_child(hb)
	hb.add_child(UI.ghost_button("← 返回终端", func() -> void:
		Scene.goto("res://scenes/MainHub.tscn")
	))
	hb.add_child(UI.hairline(Vector2(1, 18)))
	hb.add_child(UI.make_label(header_title, 22))
	hb.add_child(UI.mono_label(header_sub, 13, Color(UI.COL_TEXT_DIM, 0.7)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_star_lbl = UI.mono_label("", 17, UI.COL_ACCENT)
	hb.add_child(_star_lbl)
	_refresh_star()

	# 顶栏底部动态扫描线
	var hl := HudLine.new()
	hl.color = UI.COL_ACCENT
	hl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hl.offset_top = 62
	hl.offset_bottom = 64
	add_child(hl)

	# 第一层:分册选择(必修一/必修二/选必一/选必二/数学思想)
	var book_bar := PanelContainer.new()
	book_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	book_bar.offset_top = 64
	book_bar.offset_bottom = 126
	book_bar.add_theme_stylebox_override("panel", UI.glass_box(Color(0.03, 0.05, 0.09, 0.9), 0, Color(UI.COL_ACCENT, 0.14), 1, 8))
	book_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(book_bar)
	_book_row = HBoxContainer.new()
	_book_row.add_theme_constant_override("separation", 10)
	_book_row.alignment = BoxContainer.ALIGNMENT_CENTER
	book_bar.add_child(_book_row)

	# 第二层:当前分册下的章节卡片(左右箭头翻页 + 可横向滑动,兼容鼠标与触摸)
	var tab_bar := PanelContainer.new()
	tab_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tab_bar.offset_top = 126
	tab_bar.offset_bottom = 246
	tab_bar.add_theme_stylebox_override("panel", UI.glass_box(Color(0.03, 0.05, 0.09, 0.85), 0, Color(UI.COL_ACCENT, 0.2), 1, 8))
	tab_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(tab_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	tab_bar.add_child(row)
	row.add_child(_tab_arrow(-1))
	_tab_scroll = ScrollContainer.new()
	_tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_tab_scroll)
	row.add_child(_tab_arrow(1))
	_tabs = HBoxContainer.new()
	_tabs.alignment = BoxContainer.ALIGNMENT_BEGIN
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tabs.add_theme_constant_override("separation", 12)
	_tab_scroll.add_child(_tabs)
	# 说明：标签条不接管触摸拖动(交给卡片拖拽),横向浏览用左右箭头或鼠标滚轮。
	_build_book_tabs()
	_rebuild_tabs()

## 翻页箭头:手机无鼠标滚轮,靠它切换被遮住的章节标签
func _tab_arrow(dir: int) -> Button:
	var b := UI.ghost_button("◀" if dir < 0 else "▶", func() -> void: _scroll_tabs(dir), 18)
	b.custom_minimum_size = Vector2(46, 0)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return b

func _scroll_tabs(dir: int) -> void:
	if _tab_scroll == null:
		return
	var page := maxf(_tab_scroll.size.x * 0.7, 220.0)
	_tab_scroll.scroll_horizontal = int(maxf(0.0, float(_tab_scroll.scroll_horizontal) + dir * page))

func _rebuild_tabs() -> void:
	for c in _tabs.get_children():
		c.queue_free()
	var ids := _visible_mis()
	for mi in ids:
		_tabs.add_child(_tab_card(int(mi)))
	_tab_entrance()
	# 让当前选中的章节卡片自动滚动到可见位置
	if _tab_scroll != null and _module_idx >= 0:
		var pos := ids.find(_module_idx)
		if pos >= 0 and pos < _tabs.get_child_count():
			_tab_scroll.call_deferred("ensure_control_visible", _tabs.get_child(pos))

## 把某章做成一张可拖拽的卡片(状态: 正在学习 / 已解锁 / 未解锁)
func _tab_card(mi: int) -> Control:
	var mod: Dictionary = _mods[mi]
	var card := TabCard.new()
	card.owner_tree = self
	card.mi = mi
	card.title = str(mod["title"])
	card.chapter_label = GameData.chapter_no(str(mod["id"]))
	card.color = Color(str(mod["color"]))
	card.active = mi == _module_idx
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ci := _chapter_index_of(str(mod["id"]))
	if ci >= 0:
		card.num = ci + 1
		card.locked = (not GameData.is_chapter_unlocked(ci)) and (not GameData.free_roam)
		card.stars = GameData.chapter_stars(GameData.chapters[ci])
		card.max_stars = GameData.chapter_max_stars(GameData.chapters[ci])
		card.levels_count = (GameData.chapters[ci]["levels"] as Array).size()
	card.custom_minimum_size = Vector2(212, 104)
	card.size = Vector2(212, 104)
	return card

## 选中某章(切换地图)
func _select_module(mi: int) -> void:
	if mi < 0 or mi >= _mods.size() or mi == _module_idx:
		return
	_module_idx = mi
	Sound.play("select")
	_rebuild_tabs()
	_build_map(true)

## 卡片拖拽排序：仅在当前分册内调整先后顺序，并把整体顺序持久化。
func _reorder_cards(from_mi: int, to_mi: int) -> void:
	var ids := _visible_mis()
	var pf := ids.find(from_mi)
	var pt := ids.find(to_mi)
	if pf < 0 or pt < 0 or pf == pt:
		return
	var selected_id := ""
	if _module_idx >= 0 and _module_idx < _mods.size():
		selected_id = str(_mods[_module_idx]["id"])
	var ordered: Array = []
	for mi in ids:
		ordered.append(_mods[int(mi)])
	var moving = ordered[pf]
	ordered.remove_at(pf)
	ordered.insert(pt, moving)
	# ids 为升序索引，直接回填到原有位置，保持其它分册条目不动
	for k in ids.size():
		_mods[int(ids[k])] = ordered[k]
	var out_ids: Array = []
	for x in _mods:
		out_ids.append(str(x["id"]))
	GameData.set_chapter_order(out_ids)
	_module_idx = maxi(0, _find_module(selected_id))
	Sound.play("click")
	_rebuild_tabs()

## 卡片入场动画：轻微缩放 + 淡入，依次错峰
func _tab_entrance() -> void:
	if not UI.animations:
		return
	var i := 0
	for c in _tabs.get_children():
		if not (c is Control):
			continue
		var ctl := c as Control
		ctl.modulate.a = 0.0
		ctl.scale = Vector2(0.9, 0.9)
		ctl.pivot_offset = ctl.custom_minimum_size * 0.5
		var d := 0.03 * float(mini(i, 12))
		var tw := ctl.create_tween().set_parallel(true)
		tw.tween_property(ctl, "modulate:a", 1.0, 0.24).set_delay(d)
		tw.tween_property(ctl, "scale", Vector2.ONE, 0.34).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1

func _refresh_star() -> void:
	if _star_lbl != null:
		_star_lbl.text = "★ %d / %d" % [GameData.total_stars(), GameData.total_max_stars()]

# ---------------------------------------------------------------- 滚动区
func _build_scroll() -> void:
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = 246
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll)
	_content = Control.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(_content)
	UI.enable_touch_scroll(_scroll)
	UI.style_scrollbar(_scroll)

# ---------------------------------------------------------------- 地图
func _build_map(recenter_map: bool) -> void:
	if _content == null or _mods.is_empty():
		return
	for c in _content.get_children():
		c.queue_free()
	_path_pts = PackedVector2Array()
	_pulse = null

	var mod: Dictionary = _mods[_module_idx]
	_mod_col = Color(str(mod["color"]))
	_chapter_index = _chapter_index_of(str(mod["id"]))
	if _chapter_index < 0:
		return
	_levels = GameData.chapters[_chapter_index]["levels"]
	_groups = _disasm_groups()

	# 支线节点(optional)从主路径抽离，单独排一行并用连线挂回主节点。
	var main_groups: Array = []
	var branch_items: Array = []
	for g in _groups:
		var keep: Array = []
		for it in g["items"]:
			if bool(it.get("optional", false)):
				branch_items.append(it)
			else:
				keep.append(it)
		if not keep.is_empty():
			main_groups.append({ "title": g["title"], "boss": g["boss"], "items": keep })
	var render_groups: Array = main_groups
	if not branch_items.is_empty():
		render_groups = main_groups.duplicate()
		render_groups.append({ "title": "支线探索", "boss": false, "items": branch_items })

	var vp := get_viewport_rect().size
	var content_w := maxf(MIN_W, vp.x)
	var edge_pad := clampf(content_w * 0.045, 44.0, 96.0)
	var avail := maxf(240.0, content_w - 2.0 * edge_pad)
	# 一行放不下太多节点(会互相压字)，按可用宽度估算单行上限。
	var max_cols := clampi(int(floor(avail / 205.0)), 3, MAX_ROW_COLS)

	# 把各单元按单行上限切成"行段"：同一单元可能占多行，仅首行显示单元标题条。
	var rows_def: Array = []
	for gi in render_groups.size():
		var items: Array = render_groups[gi]["items"]
		var from := 0
		var first := true
		while from < items.size():
			var to := mini(from + max_cols, items.size())
			rows_def.append({ "gi": gi, "items": items.slice(from, to), "first": first })
			first = false
			from = to
	var rows := rows_def.size()
	var content_h := TOP_MARGIN + maxf(0.0, float(rows - 1)) * ROW_H + BOTTOM_MARGIN
	_content.custom_minimum_size = Vector2(content_w, content_h)

	var main_centers := PackedVector2Array()
	var li_center: Dictionary = {}
	var infos: Array = []
	for ri in rows:
		var rd: Dictionary = rows_def[ri]
		var g: Dictionary = render_groups[int(rd["gi"])]
		var items: Array = rd["items"]
		var m := items.size()
		var y := TOP_MARGIN + float(ri) * ROW_H
		var reverse := (ri % 2) == 1
		if bool(rd["first"]):
			_content.add_child(_unit_header(g, int(rd["gi"]), content_w, y))
		var col_gap := avail / float(m + 1)
		var title_w := maxf(96.0, col_gap - 14.0)
		for j in m:
			var it: Dictionary = items[j]
			var t := (float(j) + 1.0) / (float(m) + 1.0)
			if reverse:
				t = 1.0 - t
			var x := edge_pad + t * avail
			var c := Vector2(x, y)
			if bool(it.get("optional", false)):
				c.y += 42.0
			else:
				main_centers.append(c)
			li_center[int(it["li"])] = c
			infos.append({
				"c": c, "it": it,
				"boss": bool(g.get("boss", false)), "title_w": title_w,
			})

	if main_centers.size() >= 2:
		var smooth := _catmull_rom(main_centers, 12)
		_path_pts = smooth
		_add_path(smooth, 18.0, Color(0, 0, 0, 0.42))
		_add_path(smooth, 7.0, Color(_mod_col, 0.16))
		_add_path(smooth, 2.2, Color(_mod_col, 0.55))
		var flag := Pulse.new()
		flag.color = _mod_col
		flag.size = Vector2(30, 30)
		flag.custom_minimum_size = Vector2(30, 30)
		_content.add_child(flag)
		flag.position = smooth[0] - Vector2(15, 15)
		_pulse = flag

	# 支线连线：从 after 主节点弯向支线节点(主路径 Catmull 不含支线点)。
	for bit in branch_items:
		var after_id := str(bit.get("after", ""))
		var parent_li := _level_li_by_id(after_id)
		var bli := int(bit["li"])
		if parent_li < 0 or not li_center.has(parent_li) or not li_center.has(bli):
			continue
		var a: Vector2 = li_center[parent_li]
		var b: Vector2 = li_center[bli]
		var mid := (a + b) * 0.5 + Vector2(0, 26)
		var pts := PackedVector2Array()
		for s in 13:
			var u := float(s) / 12.0
			var p := a.lerp(mid, u).lerp(mid.lerp(b, u), u)
			pts.append(p)
		_add_path(pts, 1.6, Color(_mod_col, 0.32))

	for info in infos:
		var c0: Vector2 = info["c"]
		var it0: Dictionary = info["it"]
		var n0 := _add_level_node(c0, it0, int(it0["li"]), bool(info["boss"]), float(info["title_w"]))
		_note_unlock(n0, recenter_map)

	if UI.animations and recenter_map:
		_stagger_entrance(_content)

	_refresh_star()
	if recenter_map:
		_recenter()

func _unit_header(g: Dictionary, gi: int, content_w: float, y: float) -> Control:
	var boss := bool(g.get("boss", false))
	var h := UnitHeader.new()
	h.prefix = "HIDDEN BOSS · " if boss else "UNIT %02d · " % (gi + 1)
	h.title = str(g["title"])
	h.boss = boss
	h.color = Color("#fb7185") if boss else Color(_mod_col, 0.92)
	h.position = Vector2(0, y - NODE_H * 0.5 - 34.0)
	h.size = Vector2(content_w, 24)
	h.custom_minimum_size = Vector2(content_w, 24)
	return h

func _add_level_node(c: Vector2, it: Dictionary, li: int, boss: bool, title_w: float = 0.0) -> MapNode:
	var n := MapNode.new()
	n.li = li
	n.is_boss = boss
	n.code = str(it["code"])
	n.title = str(it["title"])
	n.sub = str(it["technique"])
	n.title_max_w = title_w
	n.color = _mod_col
	n.unlocked = _level_unlocked(li)
	var lv: Dictionary = _levels[li]
	n.stars = int(GameData.stars.get(str(lv["id"]), 0))
	n.max_stars = 3
	var region := _region_stars()
	if lv.get("chest") is Dictionary:
		var ch: Dictionary = lv["chest"]
		n.has_chest = true
		if GameData.is_chest_claimed(str(lv["id"])):
			n.chest_state = 3
		elif region >= int(ch.get("need_stars", 0)):
			n.chest_state = 2
		else:
			n.chest_state = 1
	if lv.get("event") is Dictionary:
		n.has_event = true
		n.event_done = GameData.is_event_seen(str(lv["id"]))
	var gate: Variant = lv.get("gate")
	if gate is Dictionary and int(gate.get("need_stars", 0)) > 0:
		n.gate_need = int(gate["need_stars"])
		n.gate_have = region
	n.optional = bool(lv.get("optional", false))
	var w := NODE_W
	var h := NODE_H
	if boss:
		w = BOSS_W
		h = BOSS_H
	n.size = Vector2(w, h)
	n.position = c - Vector2(w * 0.5, h * 0.5)
	n.activated.connect(func() -> void: _on_node_selected(li))
	_content.add_child(n)
	return n

## 解锁礼花：重绘(recenter)时只登记现状；进度刷新时对「本次新解锁」的节点放一次礼花。
func _note_unlock(n: MapNode, recenter: bool) -> void:
	if n == null or not n.unlocked:
		return
	var id := str(_levels[n.li].get("id", ""))
	if recenter or _unlocked_seen.has(id):
		_unlocked_seen[id] = true
		return
	_unlocked_seen[id] = true
	if UI.animations:
		Vfx.star_burst(self, n.get_global_rect().get_center(), 16, 0.9)

## 知识点节点/单元标题逐个浮现（先轻微缩小淡入，再弹回原位）。
## 若刷新前后节点数一致，尽量让同一节点的旧位置不动（新增节点错峰补入）。
func _stagger_entrance(container: Control) -> void:
	var i := 0
	for c in container.get_children():
		if not (c is Control):
			continue
		if not (c is MapNode or (c as Control).has_meta("unit_label")):
			continue
		var ctl := c as Control
		if ctl.is_queued_for_deletion():
			continue
		ctl.pivot_offset = ctl.size * 0.5
		ctl.modulate.a = 0.0
		ctl.scale = Vector2(0.35, 0.35)
		var delay := 0.05 * float(i)
		var tw := ctl.create_tween().set_parallel(true)
		tw.tween_property(ctl, "modulate:a", 1.0, 0.28).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(ctl, "scale", Vector2.ONE, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1

func _add_path(points: PackedVector2Array, width: float, color: Color) -> void:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	_content.add_child(line)

func _catmull_rom(pts: PackedVector2Array, per_seg: int) -> PackedVector2Array:
	if pts.size() < 2:
		return pts
	var ext := PackedVector2Array()
	ext.append(pts[0])
	ext.append_array(pts)
	ext.append(pts[pts.size() - 1])
	var out := PackedVector2Array()
	for i in range(1, ext.size() - 2):
		var p0 := ext[i - 1]
		var p1 := ext[i]
		var p2 := ext[i + 1]
		var p3 := ext[i + 2]
		for s in range(per_seg):
			var t := float(s) / float(per_seg)
			var t2 := t * t
			var t3 := t2 * t
			var p := 0.5 * (
				(2.0 * p1)
				+ (-p0 + p2) * t
				+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			out.append(p)
	out.append(pts[pts.size() - 1])
	return out

func _recenter() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _scroll == null:
		return
	_scroll.scroll_horizontal = 0
	_scroll.scroll_vertical = 0

func _disasm_groups() -> Array:
	var explicit := false
	for lv in _levels:
		if str((lv as Dictionary).get("group", "")) != "":
			explicit = true
			break
	var gmap: Dictionary = {}
	var order: Array = []
	var gtitle: Dictionary = {}
	for li in _levels.size():
		var lv: Dictionary = _levels[li]
		var nm := str(lv.get("name", ""))
		var is_boss := nm.contains("Boss") or nm.contains("隐藏")
		var key := ""
		var code := ""
		if is_boss:
			key = "b"
			code = "BOSS"
		else:
			# 关卡名形如 "1-2 平行判定" 时用 "1-2" 作节点编号并按单元分组;
			# 否则(如"集合的交并补")用顺序号,避免整段标题塞进节点圆环。
			var parts := nm.split(" ", false)
			var first := parts[0] if parts.size() > 0 else ""
			var np := first.split("-", false)
			var has_num := np.size() == 2 and np[0].is_valid_int() and np[1].is_valid_int()
			if has_num:
				code = first
			else:
				code = "%02d" % (li + 1)
			# 合并章节各关卡自带 group(原章节标题) → 按该字段分单元；
			# 普通章节沿用 "N-M" 的 N 分组。
			var grp := str(lv.get("group", ""))
			if explicit and grp != "":
				key = "g:" + grp
				gtitle[key] = grp
			else:
				key = "n:" + (str(int(np[0]) - 1) if has_num else "0")
		if not gmap.has(key):
			gmap[key] = { "items": [] }
			if not is_boss:
				order.append(key)
		var item_title := str(nm)
		if is_boss:
			item_title = nm.replace("隐藏Boss · ", "").strip_edges()
		gmap[key]["items"].append({
			"li": li, "code": code,
			"title": item_title,
			"technique": str(lv.get("technique", "")),
			"optional": bool(lv.get("optional", false)),
			"after": str(lv.get("after", "")),
		})
	# 隐藏挑战(Boss)始终排在所有单元之后
	if gmap.has("b"):
		order.append("b")

	var group_names: Array = GROUP_TITLES.get(str(_mods[_module_idx]["id"]), [])
	var out: Array = []
	for key in order:
		var boss: bool = key == "b"
		var title := "隐藏挑战"
		if not boss and gtitle.has(key):
			title = str(gtitle[key])
		elif not boss:
			var gidx := int(str(key).substr(2))
			if gidx < group_names.size():
				title = str(group_names[gidx])
			elif order.size() == 1:
				title = str(_mods[_module_idx]["title"])
			else:
				title = "单元 %d" % (gidx + 1)
		out.append({ "title": title, "boss": boss, "items": gmap[key]["items"] })
	return out

# ---------------------------------------------------------------- 解锁与面板
## 当前单元(章节)的累计星数，用于 Boss 门 / 宝箱门槛。
func _region_stars() -> int:
	var ids: Array = []
	for lv in _levels:
		ids.append(str((lv as Dictionary).get("id", "")))
	return GameData.stars_of(ids)

func _level_li_by_id(level_id: String) -> int:
	for i in _levels.size():
		if str((_levels[i] as Dictionary).get("id", "")) == level_id:
			return i
	return -1

func _level_unlocked(li: int) -> bool:
	if GameData.free_roam:
		return true
	if li <= 0:
		return true
	if li >= _levels.size():
		return false
	var lv: Dictionary = _levels[li]
	# 已通关的关卡始终可重玩(避免新增门槛后把已通关节点锁回去)。
	if int(GameData.stars.get(str(lv.get("id", "")), 0)) >= 1:
		return true
	# Boss 门：配置 gate 时以「本单元累计星数」为唯一解锁条件。
	var gate: Variant = lv.get("gate")
	if gate is Dictionary and int(gate.get("need_stars", 0)) > 0:
		return _region_stars() >= int(gate["need_stars"])
	if li - 1 >= _levels.size():
		return false
	return int(GameData.stars.get(_levels[li - 1]["id"], 0)) >= 1

func _on_node_selected(li: int) -> void:
	var lv: Dictionary = _levels[li]
	var has_adv := lv.get("chest") is Dictionary or lv.get("event") is Dictionary or lv.get("gate") is Dictionary
	if not _level_unlocked(li) and not has_adv:
		Sound.play("error")
		Toast.show_toast("尚未解锁：先通关上一节点")
		return
	Sound.play("select")
	_open_panel(li)

func _open_panel(li: int) -> void:
	_close_panel()
	var lv: Dictionary = _levels[li]
	var mod: Dictionary = _mods[_module_idx]
	var col := Color(str(mod["color"]))

	_panel_layer = CanvasLayer.new()
	_panel_layer.layer = UiConst.LAYER_PANEL
	add_child(_panel_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.full_rect(dim)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_panel()
	)
	_panel_layer.add_child(dim)

	var center := CenterContainer.new()
	UI.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_layer.add_child(center)

	var panel := UI.card(true, col, UI.COL_GLASS, Color(col, 0.4), 14, 26)
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	vb.add_child(head)
	var bar := ColorRect.new()
	bar.color = col
	bar.custom_minimum_size = Vector2(4, 24)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(bar)
	head.add_child(UI.make_label(str(lv["name"]), 25, UI.COL_TEXT))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	head.add_child(UI.mono_label(_stars_str(int(GameData.stars.get(lv["id"], 0))), 17, UI.COL_ACCENT))

	vb.add_child(UI.hairline(Vector2(0, 1)))
	vb.add_child(UI.mono_label("%s · %s" % [str(mod["title"]), str(lv.get("technique", ""))], 14, UI.COL_TEXT_DIM))

	var unlocked := _level_unlocked(li)

	# Boss 门：星数门槛进度
	var gate: Variant = lv.get("gate")
	if gate is Dictionary and int(gate.get("need_stars", 0)) > 0:
		vb.add_child(UI.hairline(Vector2(0, 1)))
		vb.add_child(_gate_section(int(gate["need_stars"])))

	# 宝箱节点
	if lv.get("chest") is Dictionary:
		vb.add_child(UI.hairline(Vector2(0, 1)))
		vb.add_child(_chest_section(li))

	# 随机事件节点
	if lv.get("event") is Dictionary:
		vb.add_child(UI.hairline(Vector2(0, 1)))
		vb.add_child(_event_section(li, unlocked))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vb.add_child(row)
	row.add_child(UI.ghost_button("关闭", _close_panel, 16))
	var enter := Button.new()
	enter.text = "进入推演 →" if unlocked else "尚未解锁"
	enter.disabled = not unlocked
	enter.custom_minimum_size = Vector2(200, 54)
	UI.primary_button(enter)
	enter.pressed.connect(func() -> void: _enter(li))
	row.add_child(enter)

	await get_tree().process_frame
	if _panel_layer != null and is_instance_valid(_panel_layer):
		UI.popup_in(panel)

func _enter(li: int) -> void:
	var sc := str(_levels[li].get("scene", ""))
	if sc == "" or not ResourceLoader.exists(sc):
		# A3：Battle 兜底已删；缺 scene 属坏数据(curriculum 实测 275/275 全带 scene)，原地报错。
		push_error("TheoremTree: 关卡 %s 缺少 scene(或路径不存在)，无法进入" % str(_levels[li].get("id", "")))
		Sound.play("error")
		Toast.show_toast("该关卡缺少场景数据")
		return
	if not GameData.start_level(_chapter_index, li):
		Sound.play("error")
		Toast.show_toast("无法进入该节点")
		return
	Sound.play("begin")
	_close_panel()
	Scene.goto(sc)

func _close_panel() -> void:
	if _panel_layer != null and is_instance_valid(_panel_layer):
		_panel_layer.queue_free()
	_panel_layer = null

## 返回键：若关卡面板开着，先关面板；否则返回 false 让全局回退到上一场景
func _on_back_requested() -> bool:
	if _panel_layer != null and is_instance_valid(_panel_layer):
		_close_panel()
		return true
	return false

func _stars_str(s: int) -> String:
	return "★".repeat(s) + "☆".repeat(maxi(0, 3 - s))

func _progress(have: int, need: int, col: Color) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 12)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.13, 0.2, 0.9)
	UI.full_rect(bg)
	wrap.add_child(bg)
	var ratio := clampf(float(have) / maxf(1.0, float(need)), 0.0, 1.0)
	var fill := ColorRect.new()
	fill.color = col
	fill.anchor_left = 0.0
	fill.anchor_top = 0.0
	fill.anchor_bottom = 1.0
	fill.anchor_right = ratio
	fill.offset_left = 0
	fill.offset_top = 0
	fill.offset_right = 0
	fill.offset_bottom = 0
	wrap.add_child(fill)
	return wrap

func _reward_text(reward: Dictionary) -> String:
	var parts: Array = []
	if int(reward.get("coins", 0)) > 0:
		parts.append("金币 +%d" % int(reward.get("coins", 0)))
	if int(reward.get("hint_tokens", 0)) > 0:
		parts.append("提示卡 +%d" % int(reward.get("hint_tokens", 0)))
	if int(reward.get("coin_boost", 0)) > 0:
		parts.append("金币加成 +%d" % int(reward.get("coin_boost", 0)))
	return " · ".join(parts) if not parts.is_empty() else "—"

func _gate_section(need: int) -> Control:
	var have := _region_stars()
	var ok := have >= need
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(UI.make_label("Boss 门 · 单元星数", 15, Color("#ffd479")))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.mono_label("%d / %d" % [have, need], 16, Color("#ffd479" if not ok else UI.COL_SUCCESS)))
	box.add_child(head)
	box.add_child(_progress(have, need, Color("#ffd479")))
	var msg := "已开启，可挑战隐藏 Boss" if ok else "再得 %d ★ 即可开启隐藏 Boss" % (need - have)
	box.add_child(UI.mono_label(msg, 12, Color(UI.COL_TEXT_DIM, 0.9)))
	return box

func _chest_section(li: int) -> Control:
	var lv: Dictionary = _levels[li]
	var ch: Dictionary = lv["chest"]
	var need := int(ch.get("need_stars", 0))
	var have := _region_stars()
	var claimed := GameData.is_chest_claimed(str(lv["id"]))
	var ready := have >= need
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(UI.make_label(str(ch.get("title", "补给箱")), 15, Color("#ffd479")))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.mono_label(_reward_text(ch.get("reward", {})), 13, UI.COL_TEXT_DIM))
	box.add_child(head)
	if not ready:
		box.add_child(_progress(have, need, Color("#ffd479")))
		box.add_child(UI.mono_label("需本单元累计 %d ★（当前 %d）" % [need, have], 12, Color(UI.COL_TEXT_DIM, 0.9)))
		return box
	if claimed:
		box.add_child(UI.mono_label("已领取", 13, UI.COL_SUCCESS))
		return box
	var b := Button.new()
	b.text = "开启宝箱"
	b.custom_minimum_size = Vector2(0, 44)
	UI.primary_button(b)
	b.pressed.connect(func() -> void: _claim_chest(li))
	box.add_child(b)
	return box

func _claim_chest(li: int) -> void:
	var lv: Dictionary = _levels[li]
	var ch: Dictionary = lv["chest"]
	if int(_region_stars()) < int(ch.get("need_stars", 0)):
		Sound.play("error")
		Toast.show_toast("星数不足，宝箱未解锁")
		return
	var reward: Dictionary = ch.get("reward", {})
	if not GameData.claim_chest(str(lv["id"]), reward):
		Sound.play("error")
		Toast.show_toast("宝箱已领取")
		return
	Sound.play("star")
	Toast.show_toast("宝箱开启：%s" % _reward_text(reward))
	if _panel_layer != null and is_instance_valid(_panel_layer):
		Vfx.celebrate(self, get_viewport_rect().get_center())
	_close_panel()
	_build_map(false)

func _event_section(li: int, unlocked: bool) -> Control:
	var lv: Dictionary = _levels[li]
	var ev: Dictionary = lv["event"]
	var done := GameData.is_event_seen(str(lv["id"]))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(UI.make_label(str(ev.get("title", "随机事件")), 15, Color("#5ee6ff")))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.mono_label(_reward_text(ev.get("reward", {})), 13, UI.COL_TEXT_DIM))
	box.add_child(head)
	if done:
		box.add_child(UI.mono_label("已触发", 13, UI.COL_SUCCESS))
		return box
	if not unlocked:
		box.add_child(UI.mono_label("通关本关后可触发", 12, Color(UI.COL_TEXT_DIM, 0.9)))
		return box
	# 首次展示时触发一次
	var reward: Dictionary = ev.get("reward", {})
	if GameData.mark_event_seen(str(lv["id"])):
		GameData.grant_reward(reward)
		Sound.play("complete")
		Toast.show_toast("随机事件触发：%s" % _reward_text(reward))
		Vfx.celebrate(self, get_viewport_rect().get_center())
		_build_map(false)
	box.add_child(UI.mono_label("事件已触发", 13, UI.COL_SUCCESS))
	return box
