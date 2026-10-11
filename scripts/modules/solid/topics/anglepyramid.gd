extends TopicBase

const TOPIC_TITLE := "二面角与线面角 · 正四棱锥"

var ORDER := ["A", "B", "C", "D", "P"]
var P := {
	"A": Vector3(-2, -2, 0),
	"B": Vector3(2, -2, 0),
	"C": Vector3(2, 2, 0),
	"D": Vector3(-2, 2, 0),
	"P": Vector3(0, 0, 2.0 * sqrt(3.0)),
}
var PCOL := {
	"A": Color("9dff9d"),
	"B": Color("9dc8ff"),
	"C": Color("ffd977"),
	"D": Color("ff9ad5"),
	"P": Color("ff9d9d"),
}
var EDGES := [
	["A", "B"], ["B", "C"], ["C", "D"], ["D", "A"],
	["P", "A"], ["P", "B"], ["P", "C"], ["P", "D"],
]
var O := Vector3(0, 0, 0)
var M := Vector3(0, -2, 0)

var STEPS := [
	{"dur": 9.0, "dist": 17.0, "yaw": 0.72, "pitch": 0.30, "focus": Vector3(0, 0, 1.7)},
	{"dur": 10.0, "dist": 16.0, "yaw": 0.55, "pitch": 0.26, "focus": Vector3(0, 0, 1.7)},
	{"dur": 10.0, "dist": 15.0, "yaw": 0.90, "pitch": 0.24, "focus": Vector3(0, 0, 1.8)},
	{"dur": 11.0, "dist": 14.5, "yaw": 0.35, "pitch": 0.20, "focus": Vector3(0, 0, 1.6)},
	{"dur": 11.0, "dist": 13.5, "yaw": -0.10, "pitch": 0.18, "focus": Vector3(0, 0, 1.6)},
	{"dur": 13.0, "dist": 16.0, "yaw": 0.72, "pitch": 0.30, "focus": Vector3(0, 0, 1.7)},
]

var TITLES := [
	"问题与图形",
	"① 线面角：先找射影",
	"② 计算线面角",
	"③ 二面角：作平面角",
	"④ 计算二面角",
	"⑤ 方法小结",
]

var TEXTS := [
	"""[font_size=26][b]二面角 & 线面角[/b][/font_size]

[color=#cfe2ff][b]问题[/b][/color]
正四棱锥 P-ABCD，底面边长 a = 4，
高 PO = 2√3（O 为底面中心）。

求：
· [color=#7fd8ff]侧棱 PA 与底面[/color] 所成的线面角
· [color=#ffd479]侧面 PAB 与底面[/color] 所成的二面角 P-AB-C

[color=#7f93b5]拖动旋转 · 滚轮缩放 · 空格自动播放。[/color]""",

	"""[font_size=26][b]① 线面角：先找射影[/b][/font_size]

直线与平面所成的角，
就是它与 [b]它在平面内的射影[/b] 的夹角。

PO ⊥ 底面 → O 是 P 在底面的射影，
所以 PA 在底面的射影是 [color=#7fd8ff]AO[/color]，

[center][b]∠PAO 就是 PA 与底面所成的角[/b][/center]

在直角 △POA 中：PO ⊥ OA。""",

	"""[font_size=26][b]② 计算线面角[/b][/font_size]

底面是边长 4 的正方形，
对角线一半  OA = (√2/2)·4 = 2√2。

[center][b]tan∠PAO = PO / OA[/b]
[b]= 2√3 / (2√2) = √6/2 ≈ 1.225[/b][/center]

所以 ∠PAO = arctan(√6/2) ≈ 50.8°。

关键：把斜线、垂线、射影放进直角三角形。""",

	"""[font_size=26][b]③ 二面角：作出平面角[/b][/font_size]

取棱 AB 的中点 M，连 PM、OM。

· OM ⊥ AB（正方形性质，OM 是△OAB 的高）
· PM ⊥ AB（△PAB 等腰，PM 是中线也是高）

[center][b]∴ ∠PMO 就是二面角 P-AB-C 的平面角[/b][/center]

要点：两条垂线都垂直于 [b]棱 AB[/b]，
垂足同为 M。""",

	"""[font_size=26][b]④ 计算二面角[/b][/font_size]

O 是底面中心，M 是 AB 中点，
OM 就是 O 到 AB 的距离：
OM = a/2 = 2。

PO ⊥ 底面 → PO ⊥ OM。

[center][b]tan∠PMO = PO / OM = 2√3 / 2 = √3[/b][/center]

所以 ∠PMO = 60°，
即二面角 P-AB-C = [b][color=#ffd479]60°[/color][/b]。""",

	"""[font_size=26][b]⑤ 方法小结[/b][/font_size]

[color=#7fd8ff][b]线面角[/b][/color]
· 找斜线在平面内的射影 → 直角三角形
· tan∠PAO = PO / OA = √6/2 ≈ 50.8°

[color=#ffd479][b]二面角[/b][/color]
· 在棱上取点，作两条垂线 → 平面角 ∠PMO
· tan∠PMO = PO / OM = √3 → 60°

[color=#cfe2ff][b]共同核心：都化为直角三角形求角。[/b][/color]""",
]

var edge_mat: StandardMaterial3D
var face_mat: StandardMaterial3D
var h_mat: StandardMaterial3D
var proj_mat: StandardMaterial3D
var diag_mat: StandardMaterial3D
var om_mat: StandardMaterial3D
var pm_mat: StandardMaterial3D
var ab_mat: StandardMaterial3D
var o_mat: StandardMaterial3D
var m_mat: StandardMaterial3D
var ang1_mat: StandardMaterial3D
var ang2_mat: StandardMaterial3D

var vertex_nodes := {}
var name_labels := {}
var edge_segs := []
var faces_mesh: MeshInstance3D
var h_seg: Node3D
var proj_seg: Node3D
var diag_seg: Node3D
var om_seg: Node3D
var pm_seg: Node3D
var ab_seg: Node3D
var o_point: Node3D
var o_label: Label3D
var m_point: Node3D
var m_label: Label3D
var ang1_segs := []
var ang2_segs := []
var ang1_label: Label3D
var ang2_label: Label3D


func build() -> void:
	build_grid(-4, 4, -4, 4)
	build_pyramid()
	build_aux()
	build_angles()


func build_pyramid() -> void:
	face_mat = mk_mat(Color("5f9bff"), 0.13)
	face_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	edge_mat = fade_mat(Color("dfeaff"), 1.0)

	for k in ORDER:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		sm.radial_segments = 28
		sm.rings = 14
		sm.material = mk_mat(PCOL[k], 1.0, true)
		mi.mesh = sm
		mi.position = mv(P[k])
		mi.visible = false
		add_child(mi)
		vertex_nodes[k] = mi
		var nl := mk_label(k, mv(P[k]) + Vector3(0, 0.42, 0), 76, PCOL[k], 13)
		nl.modulate.a = 0.0
		name_labels[k] = nl

	for e in EDGES:
		edge_segs.append(mk_seg(self, mv(P[e[0]]), mv(P[e[1]]), 0.03, edge_mat, true))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := [
		[P["A"], P["B"], P["C"]],
		[P["A"], P["C"], P["D"]],
		[P["P"], P["A"], P["B"]],
		[P["P"], P["B"], P["C"]],
		[P["P"], P["C"], P["D"]],
		[P["P"], P["D"], P["A"]],
	]
	for tri in tris:
		var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
		if n.z < 0.0:
			n = -n
		for v in tri:
			st.set_normal(n)
			st.add_vertex(mv(v))
	st.index()
	faces_mesh = MeshInstance3D.new()
	faces_mesh.mesh = st.commit()
	faces_mesh.material_override = face_mat
	faces_mesh.visible = false
	add_child(faces_mesh)


func build_aux() -> void:
	h_mat = fade_mat(Color("cfe2ff"), 0.85)
	proj_mat = fade_mat(Color("7fd8ff"), 1.0)
	diag_mat = fade_mat(Color("6f86ab"), 0.6)
	om_mat = fade_mat(Color("ffb84d"), 1.0)
	pm_mat = fade_mat(Color("ff9ad5"), 1.0)
	ab_mat = fade_mat(Color("ffd479"), 1.0)
	o_mat = fade_mat(Color("ffd479"), 1.0, true)
	m_mat = fade_mat(Color("ff9ad5"), 1.0, true)

	h_seg = mk_seg(self, mv(O), mv(P["P"]), 0.02, h_mat, true)
	diag_seg = mk_seg(self, mv(P["A"]), mv(P["C"]), 0.014, diag_mat, true)
	proj_seg = mk_seg(self, mv(P["A"]), mv(O), 0.03, proj_mat, true)
	om_seg = mk_seg(self, mv(O), mv(M), 0.03, om_mat, true)
	pm_seg = mk_seg(self, mv(P["P"]), mv(M), 0.03, pm_mat, true)
	ab_seg = mk_seg(self, mv(P["A"]), mv(P["B"]), 0.055, ab_mat, true)

	o_point = mk_ball(mv(O), 0.12, o_mat)
	o_label = mk_label("O", mv(O) + Vector3(0.42, -0.15, 0.42), 58, Color("ffd479"), 12)
	o_label.modulate.a = 0.0
	m_point = mk_ball(mv(M), 0.11, m_mat)
	m_label = mk_label("M", mv(M) + Vector3(0.55, -0.2, -0.35), 58, Color("ff9ad5"), 12)
	m_label.modulate.a = 0.0


func angle_pos(vertex: Vector3, p_a: Vector3, p_b: Vector3, out_len := 1.15) -> Vector3:
	var va := (p_a - vertex)
	var vb := (p_b - vertex)
	if va.length() < 0.001:
		va = Vector3.UP
	if vb.length() < 0.001:
		vb = Vector3.RIGHT
	var dir := (va.normalized() + vb.normalized())
	if dir.length() < 0.001:
		dir = Vector3.UP
	return vertex + dir.normalized() * out_len


func build_angles() -> void:
	ang1_mat = fade_mat(Color("7fd8ff"), 1.0)
	ang2_mat = fade_mat(Color("ffd479"), 1.0)

	var vA := mv(P["A"])
	var vO := mv(O)
	var vP := mv(P["P"])
	var vM := mv(M)
	ang1_segs.append(mk_seg(self, vA, vA.lerp(vO, 0.45), 0.045, ang1_mat, false))
	ang1_segs.append(mk_seg(self, vA, vA.lerp(vP, 0.32), 0.045, ang1_mat, false))
	ang1_label = mk_label("∠PAO", angle_pos(vA, vO, vP, 1.5) + Vector3(0, 0.15, 0), 52, Color("7fd8ff"), 12)
	ang1_label.modulate.a = 0.0

	ang2_segs.append(mk_seg(self, vM, vM.lerp(vO, 0.5), 0.045, ang2_mat, false))
	ang2_segs.append(mk_seg(self, vM, vM.lerp(vP, 0.32), 0.045, ang2_mat, false))
	ang2_label = mk_label("∠PMO = 60°", angle_pos(vM, vO, vP, 1.7) + Vector3(-0.2, 0.15, 0), 50, Color("ffd479"), 12)
	ang2_label.modulate.a = 0.0


func apply(g: float) -> void:
	grid_mat.albedo_color.a = 0.45 * smooth_k(g, 0.0, 0.6)

	for i in edge_segs.size():
		set_grow(edge_segs[i], smooth_k(g, 0.25 + i * 0.04, 0.6 + i * 0.04))
	face_mat.albedo_color.a = 0.13 * smooth_k(g, 0.75, 1.1)
	faces_mesh.visible = face_mat.albedo_color.a > 0.004

	for i in ORDER.size():
		var k := ease_pop(smooth_k(g, 0.2 + i * 0.09, 0.5 + i * 0.09))
		var vn: MeshInstance3D = vertex_nodes[ORDER[i]]
		vn.visible = k > 0.02
		vn.scale = Vector3.ONE * k
		name_labels[ORDER[i]].modulate.a = k

	set_grow(h_seg, smooth_k(g, 1.1, 1.6))
	var k_o := ease_pop(smooth_k(g, 1.5, 1.8))
	o_point.visible = k_o > 0.02
	o_point.scale = Vector3.ONE * k_o
	o_label.modulate.a = smooth_k(g, 1.6, 1.9)

	diag_mat.albedo_color.a = 0.6 * smooth_k(g, 1.8, 2.2)
	set_grow(diag_seg, smooth_k(g, 1.8, 2.3))
	set_grow(proj_seg, smooth_k(g, 1.95, 2.5))
	ang1_mat.albedo_color.a = smooth_k(g, 2.0, 2.4)
	for s in ang1_segs:
		s.visible = ang1_mat.albedo_color.a > 0.05
	ang1_label.modulate.a = smooth_k(g, 2.55, 2.9)

	set_grow(om_seg, smooth_k(g, 3.15, 3.6))
	var k_m := ease_pop(smooth_k(g, 3.3, 3.6))
	m_point.visible = k_m > 0.02
	m_point.scale = Vector3.ONE * k_m
	m_label.modulate.a = smooth_k(g, 3.4, 3.7)
	set_grow(pm_seg, smooth_k(g, 3.55, 4.0))
	ab_mat.albedo_color.a = smooth_k(g, 3.4, 3.8)
	set_grow(ab_seg, smooth_k(g, 3.4, 3.85))

	ang2_mat.albedo_color.a = smooth_k(g, 3.9, 4.3)
	for s in ang2_segs:
		s.visible = ang2_mat.albedo_color.a > 0.05
	ang2_label.modulate.a = smooth_k(g, 4.35, 4.7)