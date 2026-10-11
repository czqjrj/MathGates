extends TopicBase

const TOPIC_TITLE := "万能几何法 · 求三棱锥的外接球"

const ORDER := ["A", "B", "C", "P"]
const WORDER := ["D", "E", "F"]

var V := {
	"A": Vector3(0, 0, 0),
	"B": Vector3(5, 0, 0),
	"C": Vector3(3.5, 6.0621778, 0),
	"P": Vector3(0, 0, 12),
}
var PCOL := {
	"A": Color("ff9d9d"),
	"B": Color("9dff9d"),
	"C": Color("9dc8ff"),
	"P": Color("ffd977"),
}
var EDGES := [
	["A", "B"], ["A", "C"], ["A", "P"], ["B", "C"], ["B", "P"], ["C", "P"],
]
const CO := Vector3(2.5, 2.5980762, 0)
const SO := Vector3(2.5, 2.5980762, 6)
const R_CIRC := 3.6055513
const R_SPH := 7.0
const H_H := 6.0
const PA_LEN := 12.0

var WV := {
	"D": Vector3(-13.5, 0, 0),
	"E": Vector3(-7.5, 0, 0),
	"F": Vector3(-14.5, 3, 0),
}
var WCOL := {
	"D": Color("ffb0b0"),
	"E": Color("b0ffc0"),
	"F": Color("b0d8ff"),
}
const WQ := Vector3(-10.5, 2.6666667, 0)
const WR := 4.013878

var STEPS := [
	{"dur": 10.0, "dist": 18.5, "yaw": 0.75, "pitch": 0.34, "focus": Vector3(2.5, 3.0, 6.2)},
	{"dur": 15.0, "dist": 15.0, "yaw": 0.65, "pitch": 1.00, "focus": Vector3(2.5, 3.0, 2.8)},
	{"dur": 11.0, "dist": 18.5, "yaw": 1.00, "pitch": 0.45, "focus": Vector3(2.5, 2.6, 6.7)},
	{"dur": 13.0, "dist": 9.5, "yaw": -0.85, "pitch": 0.22, "focus": Vector3(1.6, 2.6, 3.0)},
	{"dur": 13.0, "dist": 11.5, "yaw": -0.70, "pitch": 0.30, "focus": Vector3(1.6, 2.6, 3.5)},
	{"dur": 15.0, "dist": 19.0, "yaw": 0.90, "pitch": 0.30, "focus": Vector3(2.5, 2.6, 6.0)},
	{"dur": 16.0, "dist": 12.0, "yaw": 0.50, "pitch": 0.75, "focus": Vector3(-10.5, 1.2, 0.0)},
	{"dur": 14.0, "dist": 27.0, "yaw": 0.55, "pitch": 0.33, "focus": Vector3(-3.5, 2.5, 5.0)},
]

var TITLES := [
	"问题与总览",
	"① 找底面外心 O′",
	"② 过 O′ 作垂线 l",
	"③ 设 h，列勾股方程",
	"④ 解 h，求出 R",
	"⑤ 作出外接球",
	"⑥ 易错点：外心在外部",
	"⑦ 方法小结",
]

var TEXTS := [
	"""[font_size=26][b]万能几何法 · 求外接球[/b][/font_size]

[color=#cfe2ff][b]问题[/b][/color]
三棱锥 P-ABC 中，PA ⊥ 底面 ABC，
AB = 5，AC = 7，∠BAC = 60°，PA = 12，
求外接球的表面积。

[color=#cfe2ff][b]适用[/b][/color]
一条棱垂直底面；侧棱相等；底面任意三角形。

[color=#cfe2ff][b]四步[/b][/color]
① 找底面外心 O′（外接圆圆心）
② 过 O′ 作垂线 l → 球心 O 在 l 上
③ 设 OO′ = h，列方程 R² = r² + h²
④ 由已知解 h，求出 R

[color=#7f93b5]拖动旋转 · 滚轮缩放 · 空格自动播放[/color]""",

	"""[font_size=26][b]① 找底面外心 O′[/b][/font_size]

外心 O′ = 外接圆圆心，到 A、B、C 等距。

[color=#ffd479][b]正弦定理求 r[/b][/color]
[center][b]2r = a / sin A[/b][/center]

本例：BC = √39，∠A = 60°
2r = √39 ÷ (√3 / 2) = 2√13
[center][color=#ffd479][b]r = √13 ≈ 3.61[/b][/color]

[b]三种特殊情况[/b]
· 直角三角形：外心 = 斜边中点
· 正三角形：中心（四心重合）
· 普通三角形：正弦定理求 r

图中粉色为两边的垂直平分线，
其交点就是外心 O′。""",

	"""[font_size=26][b]② 过 O′ 作底面的垂线 l[/b][/font_size]

过外心 O′ 作底面的垂线 l（金色）。

[center][color=#7fd8ff][b]球心 O 一定在垂线 l 上[/b][/color]

理由：球心 O 到 A、B、C 三点等距，
所以 O 在底面上的射影恰好是外心 O′。

于是球心只可能落在 l 上，
具体位置由题设条件确定。""",

	"""[font_size=26][b]③ 设 h，列勾股方程[/b][/font_size]

设 OO′ = h，O′A = r，OA = R。

在 Rt△OO′A 中，∠OO′A = 90°：

[center][font_size=24][color=#ffd479][b]R² = r² + h²[/b][/color][/font_size]

代入 r² = 13：
[center][b]R² = 13 + h²[/b][/center]

又球心 O 到 P 的距离也是 R，
即 OA = OP，联立即可解出 h。""",

	"""[font_size=26][b]④ 解 h，求出 R[/b][/font_size]

由 OA = OP，两边平方：

13 + h² = 13 + (12 − h)²

（PA ⊥ 底面，竖直方向差 12 − h）

h² = (12 − h)²
[center][color=#ffd479][b]h = 6 = PA / 2[/b][/color]

R² = r² + h² = 13 + 36 = 49
[center][font_size=24][color=#ffd479][b]R = 7[/b][/color][/font_size]""",

	"""[font_size=26][b]⑤ 作出外接球[/b][/font_size]

以 O 为球心、7 为半径作球：

[center][b][color=#7fd8ff]OA = OB = OC = OP = 7[/color][/b][/center]

四点都在球面上，球即为所求。

[color=#cfe2ff]球心 O 在底面的射影是外心 O′，
OO′ = h = 6，R = 7。[/color]

表面积 S = 4πR² = [b]196π[/b] ≈ 615.75
体积 V = 4πR³/3 = [b]1372π/3[/b] ≈ 1436.76""",

	"""[font_size=26][color=#ff9a9a][b]⑥ 易错点[/b][/color][/font_size]

[color=#ff9a9a][b]钝角三角形的外心在三角形外部！[/b][/color]

图中钝角 △DEF 中，外心 Q 落在
三角形 [b]外部[/b]，外接圆仍过 D、E、F。

画图时不要凭感觉把外心画在内部，
要作垂直平分线、取实际交点。""",

	"""[font_size=26][b]⑦ 方法小结[/b][/font_size]

[color=#cfe2ff][b]万能几何法 四步[/b][/color]
① 底面外心 O′：2r = a / sin A
② 过 O′ 作垂线 l，球心 O ∈ l
③ 设 OO′ = h，列 R² = r² + h²
④ 用 OA = OP 等条件解 h，得 R

[color=#ffd479]本例 r = √13，h = 6，R = 7，
S = 4πR² = 196π[/color]

[color=#ff9a9a]注意：钝角三角形的外心在
三角形外部！[/color]""",
]

var edge_mat: StandardMaterial3D
var face_mat: StandardMaterial3D
var pink_mat: StandardMaterial3D
var gold_mat: StandardMaterial3D
var cyan_mat: StandardMaterial3D
var o1_ball_mat: StandardMaterial3D
var o_ball_mat: StandardMaterial3D
var sphere_fill_mat: StandardMaterial3D
var ring_mat: StandardMaterial3D
var w_edge_mat: StandardMaterial3D
var w_face_mat: StandardMaterial3D
var w_circ_mat: StandardMaterial3D
var w_ball_mat: StandardMaterial3D

var vertex_nodes := {}
var name_labels := {}
var edge_segs := []
var faces_mesh: MeshInstance3D
var pa_marks := []
var bis_segs := []
var circ_segs := []
var o1_point: Node3D
var o1_label: Label3D
var r_segs := []
var r_lbl1: Label3D
var r_lbl2: Label3D
var l_seg: Node3D
var l_label: Label3D
var o1_mark := []
var marker: Node3D
var qmark_label: Label3D
var olabel: Label3D
var h_seg: Node3D
var h_lbl1: Label3D
var h_lbl2: Label3D
var r_seg: Node3D
var R_lbl1: Label3D
var R_lbl2: Label3D
var sphere_root: Node3D
var rad_segs := []
var rad_labels := []
var w_vertex_nodes := {}
var w_name_labels := {}
var w_edge_segs := []
var w_faces_mesh: MeshInstance3D
var w_circ_segs := []
var w_point: Node3D
var w_label: Label3D
var w_note: Label3D

const Z_DRIFT_END := 6.0 + 2.0 * sin(0.9 * 5.5)


func build() -> void:
	build_grid(-15, 9, -3, 8)
	build_tetra()
	build_marks()
	build_circum()
	build_line_l()
	build_center()
	build_sphere()
	build_warn()


func build_tetra() -> void:
	face_mat = fade_mat(Color("5f9bff"), 0.16)
	face_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	edge_mat = fade_mat(Color("dfeaff"), 1.0)

	for k in ORDER:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.115
		sm.height = 0.23
		sm.radial_segments = 28
		sm.rings = 14
		sm.material = mk_mat(PCOL[k], 1.0, true)
		mi.mesh = sm
		mi.position = mv(V[k])
		mi.visible = false
		add_child(mi)
		vertex_nodes[k] = mi
		var nl := mk_label(k, mv(V[k]) + Vector3(0, 0.4, 0), 76, PCOL[k], 13)
		name_labels[k] = nl

	for e in EDGES:
		edge_segs.append(mk_seg(self, mv(V[e[0]]), mv(V[e[1]]), 0.032, edge_mat, true))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := [
		[V["A"], V["B"], V["C"]],
		[V["A"], V["B"], V["P"]],
		[V["A"], V["C"], V["P"]],
		[V["B"], V["C"], V["P"]],
	]
	for tri in tris:
		var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
		for v in tri:
			st.set_normal(n)
			st.add_vertex(mv(v))
	st.index()
	faces_mesh = MeshInstance3D.new()
	faces_mesh.mesh = st.commit()
	faces_mesh.material_override = face_mat
	faces_mesh.visible = false
	add_child(faces_mesh)


func build_marks() -> void:
	var up := Vector3(0, 0, 1)
	var dB: Vector3 = (V["B"] - V["A"]).normalized()
	var dC: Vector3 = (V["C"] - V["A"]).normalized()
	pa_marks.append(mk_seg(self, mv(V["A"]), mv(V["A"] + dB * 0.42), 0.02, edge_mat))
	pa_marks.append(mk_seg(self, mv(V["A"]), mv(V["A"] + up * 0.42), 0.02, edge_mat))
	pa_marks.append(mk_seg(self, mv(V["A"]), mv(V["A"] + dC * 0.42), 0.02, edge_mat))
	pa_marks.append(mk_seg(self, mv(V["A"]), mv(V["A"] + up * 0.42), 0.02, edge_mat))


func build_circum() -> void:
	pink_mat = fade_mat(Color("ff9ad5"), 0.95)

	var dAB: Vector3 = (V["B"] - V["A"])
	var mAB: Vector3 = (V["A"] + V["B"]) * 0.5
	var pAB1: Vector3 = mAB - dAB.normalized() * 2.6
	var pAB2: Vector3 = mAB + dAB.normalized() * 2.6
	bis_segs.append(mk_seg(self, mv(pAB1), mv(pAB2), 0.02, pink_mat))

	var dAC: Vector3 = (V["C"] - V["A"])
	var mAC: Vector3 = (V["A"] + V["C"]) * 0.5
	var perp := Vector3(-dAC.y, dAC.x, 0).normalized()
	bis_segs.append(mk_seg(self, mv(mAC - perp * 3.0), mv(mAC + perp * 3.0), 0.02, pink_mat))

	for i in 48:
		var a0 := TAU * i / 48.0
		var a1 := TAU * (i + 1) / 48.0
		var p0 := CO + Vector3(cos(a0) * R_CIRC, sin(a0) * R_CIRC, 0)
		var p1 := CO + Vector3(cos(a1) * R_CIRC, sin(a1) * R_CIRC, 0)
		circ_segs.append(mk_seg(self, mv(p0), mv(p1), 0.026, pink_mat))

	o1_ball_mat = fade_mat(Color("ff9ad5"), 1.0, true)
	o1_point = mk_ball(mv(CO), 0.12, o1_ball_mat)
	o1_label = mk_label("O′", mv(CO + Vector3(-0.55, 0.55, 0.45)), 62, Color("ff9ad5"), 12)

	for k in ["A", "B", "C"]:
		r_segs.append(mk_seg(self, mv(CO), mv(V[k]), 0.026, pink_mat))

	r_lbl1 = mk_label("r", mv(CO).lerp(mv(V["A"]), 0.5) + Vector3(0, 0.38, 0), 54, Color("ff9ad5"), 11)
	r_lbl2 = mk_label("r = √13", mv(CO).lerp(mv(V["A"]), 0.5) + Vector3(0, 0.38, 0), 54, Color("ff9ad5"), 11)


func build_line_l() -> void:
	gold_mat = fade_mat(Color("ffd479"), 1.0)
	var bottom := mv(CO + Vector3(0, 0, -1.0))
	var top := mv(CO + Vector3(0, 0, 13.6))
	l_seg = mk_seg(self, bottom, top, 0.024, gold_mat)
	l_label = mk_label("l", mv(CO + Vector3(0, 0, 10.9)) + Vector3(0, 0.3, 0), 64, Color("ffd479"), 12)

	var dToA: Vector3 = (V["A"] - CO).normalized()
	var up := Vector3(0, 0, 1)
	o1_mark.append(mk_seg(self, mv(CO), mv(CO + dToA * 0.45), 0.022, gold_mat))
	o1_mark.append(mk_seg(self, mv(CO), mv(CO + up * 0.45), 0.022, gold_mat))


func build_center() -> void:
	cyan_mat = fade_mat(Color("7fd8ff"), 1.0)

	marker = mk_ball(mv(SO), 0.16, o_ball_mat if o_ball_mat != null else gold_mat)
	o_ball_mat = fade_mat(Color("ffd479"), 1.0, true)
	marker.get_child(0).mesh.material = o_ball_mat

	qmark_label = mk_label("?", mv(SO) + Vector3(0, 0.5, 0), 96, Color("ffe9a8"), 16)
	olabel = mk_label("O", mv(SO) + Vector3(0, 0.5, 0), 76, Color("ffd479"), 13)

	h_seg = mk_seg(self, mv(SO), mv(CO), 0.052, gold_mat, true)
	h_lbl1 = mk_label("h", mv(SO).lerp(mv(CO), 0.5) + Vector3(0.5, 0, 0), 56, Color("ffd479"), 11)
	h_lbl2 = mk_label("h = 6", mv(SO).lerp(mv(CO), 0.5) + Vector3(0.5, 0, 0), 56, Color("ffd479"), 11)

	r_seg = mk_seg(self, mv(SO), mv(V["A"]), 0.032, cyan_mat, true)
	R_lbl1 = mk_label("R", mv(SO).lerp(mv(V["A"]), 0.5) + Vector3(0, 0.35, 0), 58, Color("7fd8ff"), 11)
	R_lbl2 = mk_label("R = 7", mv(SO).lerp(mv(V["A"]), 0.5) + Vector3(0, 0.35, 0), 58, Color("7fd8ff"), 11)


func build_sphere() -> void:
	ring_mat = fade_mat(Color("8fe4ff"), 1.0)
	sphere_fill_mat = fade_mat(Color("57c8ff"), 0.10)
	sphere_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	sphere_root = Node3D.new()
	sphere_root.position = mv(SO)
	sphere_root.visible = false
	add_child(sphere_root)

	var fill := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = R_SPH
	sm.height = R_SPH * 2.0
	sm.radial_segments = 56
	sm.rings = 28
	sm.material = sphere_fill_mat
	fill.mesh = sm
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sphere_root.add_child(fill)

	for h in [-5.6, -3.9, -2.0, 0.0, 2.0, 3.9, 5.6]:
		var r := sqrt(R_SPH * R_SPH - h * h)
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = maxf(r - 0.025, 0.02)
		tm.outer_radius = r + 0.025
		tm.rings = 72
		tm.ring_segments = 8
		tm.material = ring_mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.position = Vector3(0, h, 0)
		sphere_root.add_child(tor)

	for ang in [0.0, 30.0, 60.0, 90.0, 120.0, 150.0]:
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = R_SPH - 0.025
		tm.outer_radius = R_SPH + 0.025
		tm.rings = 72
		tm.ring_segments = 8
		tm.material = ring_mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.basis = Basis(Vector3.UP, deg_to_rad(ang)) * Basis(Vector3.RIGHT, PI * 0.5)
		sphere_root.add_child(tor)

	for k in ["B", "C", "P"]:
		rad_segs.append(mk_seg(self, mv(SO), mv(V[k]), 0.022, cyan_mat))
		rad_labels.append(mk_label("7", mv(SO).lerp(mv(V[k]), 0.5), 54, Color("7fd8ff"), 11))


func build_warn() -> void:
	w_edge_mat = fade_mat(Color("ffd9d9"), 1.0)
	w_face_mat = fade_mat(Color("ff8f8f"), 0.18)
	w_face_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	w_circ_mat = fade_mat(Color("ff9ad5"), 0.95)
	w_ball_mat = fade_mat(Color("ff6b6b"), 1.0, true)

	for k in WORDER:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.11
		sm.height = 0.22
		sm.radial_segments = 26
		sm.rings = 13
		sm.material = mk_mat(WCOL[k], 1.0, true)
		mi.mesh = sm
		mi.position = mv(WV[k])
		mi.visible = false
		add_child(mi)
		w_vertex_nodes[k] = mi
		w_name_labels[k] = mk_label(k, mv(WV[k]) + Vector3(0, 0.38, 0), 70, WCOL[k], 13)

	var wedges := [["D", "E"], ["E", "F"], ["D", "F"]]
	for e in wedges:
		w_edge_segs.append(mk_seg(self, mv(WV[e[0]]), mv(WV[e[1]]), 0.03, w_edge_mat))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri := [WV["D"], WV["E"], WV["F"]]
	var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
	for v in tri:
		st.set_normal(n)
		st.add_vertex(mv(v))
	st.index()
	w_faces_mesh = MeshInstance3D.new()
	w_faces_mesh.mesh = st.commit()
	w_faces_mesh.material_override = w_face_mat
	w_faces_mesh.visible = false
	add_child(w_faces_mesh)

	for i in 44:
		var a0 := TAU * i / 44.0
		var a1 := TAU * (i + 1) / 44.0
		var p0 := WQ + Vector3(cos(a0) * WR, sin(a0) * WR, 0)
		var p1 := WQ + Vector3(cos(a1) * WR, sin(a1) * WR, 0)
		w_circ_segs.append(mk_seg(self, mv(p0), mv(p1), 0.024, w_circ_mat))

	w_point = mk_ball(mv(WQ), 0.13, w_ball_mat)
	w_label = mk_label("Q", mv(WQ) + Vector3(0, 0.45, 0), 74, Color("ff8f8f"), 14)
	w_note = mk_label("外心 Q 在 △DEF 外部", mv(WQ) + Vector3(-0.4, -1.4, 0), 52, Color("ff9a9a"), 11)


func dim_of(g: float) -> float:
	var down := smooth_k(g, 6.05, 6.5)
	var up := smooth_k(g, 7.0, 7.45)
	return lerpf(lerpf(1.0, 0.16, down), 1.0, up)


func marker_pos_at(g: float) -> Vector3:
	var mz := H_H
	if g >= 3.1 and g < 4.0:
		mz = H_H + 2.0 * sin((g - 3.1) * 5.5)
	elif g >= 4.0:
		mz = lerpf(Z_DRIFT_END, H_H, ease_out(smooth_k(g, 4.0, 4.45)))
	return mv(Vector3(CO.x, CO.y, mz))


func apply(g: float) -> void:
	var dm := dim_of(g)

	grid_mat.albedo_color.a = 0.45 * smooth_k(g, 0.0, 0.6) * dm

	for i in edge_segs.size():
		set_grow(edge_segs[i], smooth_k(g, 0.15 + i * 0.06, 0.55 + i * 0.06))
	face_mat.albedo_color.a = 0.16 * smooth_k(g, 0.55, 0.95) * dm
	faces_mesh.visible = face_mat.albedo_color.a > 0.004
	edge_mat.albedo_color.a = dm

	for i in ORDER.size():
		var k := ease_pop(smooth_k(g, 0.25 + i * 0.12, 0.6 + i * 0.12))
		var vn: MeshInstance3D = vertex_nodes[ORDER[i]]
		vn.visible = k > 0.02
		vn.scale = Vector3.ONE * k
		name_labels[ORDER[i]].visible = k > 0.02
		name_labels[ORDER[i]].modulate.a = k * dm

	var k_pa := smooth_k(g, 0.8, 1.2)
	for s in pa_marks:
		set_grow(s, k_pa)

	pink_mat.albedo_color.a = 0.95 * dm
	gold_mat.albedo_color.a = dm
	cyan_mat.albedo_color.a = dm
	o1_ball_mat.albedo_color.a = dm
	o_ball_mat.albedo_color.a = dm

	for i in bis_segs.size():
		set_grow(bis_segs[i], smooth_k(g, 1.05 + i * 0.1, 1.5 + i * 0.1))
	reveal_segs(circ_segs, smooth_k(g, 1.35, 1.95))

	var k_o1 := ease_pop(smooth_k(g, 1.7, 1.95))
	o1_point.visible = k_o1 > 0.02
	o1_point.scale = Vector3.ONE * k_o1
	o1_label.visible = k_o1 > 0.02
	o1_label.modulate.a = smooth_k(g, 1.75, 1.98) * dm

	for i in r_segs.size():
		set_grow(r_segs[i], smooth_k(g, 1.8 + i * 0.05, 2.05 + i * 0.05))
	var k_r_in := smooth_k(g, 1.9, 2.1)
	var k_r_swap := smooth_k(g, 4.1, 4.4)
	r_lbl1.visible = k_r_in > 0.02
	r_lbl2.visible = k_r_in > 0.02
	r_lbl1.modulate.a = k_r_in * (1.0 - k_r_swap) * dm
	r_lbl2.modulate.a = k_r_in * k_r_swap * dm

	set_grow(l_seg, smooth_k(g, 2.1, 2.7))
	l_label.visible = g > 2.6
	l_label.modulate.a = smooth_k(g, 2.6, 2.9) * dm
	for s in o1_mark:
		set_grow(s, smooth_k(g, 2.7, 3.0))

	var mp := marker_pos_at(g)
	marker.position = mp
	var k_mk := ease_pop(smooth_k(g, 3.1, 3.4))
	marker.visible = k_mk > 0.02
	marker.scale = Vector3.ONE * k_mk

	var k_q_in := smooth_k(g, 3.25, 3.55)
	var k_q_out := smooth_k(g, 4.05, 4.35)
	qmark_label.position = mp + Vector3(0, 0.52, 0)
	qmark_label.visible = k_q_in > 0.02
	qmark_label.modulate.a = k_q_in * (1.0 - k_q_out) * dm

	var k_o_in := smooth_k(g, 4.1, 4.4)
	olabel.position = mp + Vector3(0, 0.52, 0)
	olabel.visible = k_o_in > 0.02
	olabel.modulate.a = k_o_in * dm

	h_seg.set_meta("p1", mp)
	h_seg.set_meta("p2", mv(CO))
	set_grow(h_seg, smooth_k(g, 3.4, 3.85))
	var k_h_in := smooth_k(g, 3.8, 4.05)
	var k_h_swap := smooth_k(g, 4.4, 4.7)
	var hmid := mp.lerp(mv(CO), 0.5) + Vector3(0.5, 0, 0)
	h_lbl1.position = hmid
	h_lbl2.position = hmid
	h_lbl1.visible = k_h_in > 0.02
	h_lbl2.visible = k_h_in > 0.02
	h_lbl1.modulate.a = k_h_in * (1.0 - k_h_swap) * dm
	h_lbl2.modulate.a = k_h_in * k_h_swap * dm

	r_seg.set_meta("p1", mp)
	r_seg.set_meta("p2", mv(V["A"]))
	set_grow(r_seg, smooth_k(g, 3.9, 4.35))
	var k_R_in := smooth_k(g, 4.1, 4.35)
	var k_R_swap := smooth_k(g, 4.7, 5.0)
	var Rmid := mp.lerp(mv(V["A"]), 0.5) + Vector3(0, 0.35, 0)
	R_lbl1.position = Rmid
	R_lbl2.position = Rmid
	R_lbl1.visible = k_R_in > 0.02
	R_lbl2.visible = k_R_in > 0.02
	R_lbl1.modulate.a = k_R_in * (1.0 - k_R_swap) * dm
	R_lbl2.modulate.a = k_R_in * k_R_swap * dm

	var k_s := ease_out(smooth_k(g, 5.15, 5.95))
	sphere_root.visible = k_s > 0.01
	sphere_root.scale = Vector3.ONE * maxf(k_s, 0.001)
	sphere_fill_mat.albedo_color.a = 0.10 * k_s * dm
	ring_mat.albedo_color.a = k_s * dm

	for i in rad_segs.size():
		set_grow(rad_segs[i], smooth_k(g, 5.7 + i * 0.1, 6.1 + i * 0.1))
		rad_labels[i].visible = g > 6.05 + i * 0.05
		rad_labels[i].modulate.a = smooth_k(g, 6.05 + i * 0.05, 6.4 + i * 0.05) * dm

	w_edge_mat.albedo_color.a = 1.0
	for i in WORDER.size():
		var k := smooth_k(g, 6.4 + i * 0.06, 6.8 + i * 0.06)
		var vn: MeshInstance3D = w_vertex_nodes[WORDER[i]]
		vn.visible = k > 0.02
		vn.scale = Vector3.ONE * ease_pop(k)
		w_name_labels[WORDER[i]].visible = k > 0.02
		w_name_labels[WORDER[i]].modulate.a = k
	for i in w_edge_segs.size():
		set_grow(w_edge_segs[i], smooth_k(g, 6.2 + i * 0.06, 6.75 + i * 0.06))
	w_face_mat.albedo_color.a = 0.18 * smooth_k(g, 6.55, 6.9)
	w_faces_mesh.visible = w_face_mat.albedo_color.a > 0.004
	w_circ_mat.albedo_color.a = 0.95
	reveal_segs(w_circ_segs, smooth_k(g, 6.6, 7.05))
	var k_wq := ease_pop(smooth_k(g, 6.9, 7.15))
	w_point.visible = k_wq > 0.02
	w_point.scale = Vector3.ONE * k_wq
	w_label.visible = k_wq > 0.02
	w_label.modulate.a = smooth_k(g, 7.0, 7.25)
	w_note.visible = g > 7.1
	w_note.modulate.a = smooth_k(g, 7.1, 7.35)