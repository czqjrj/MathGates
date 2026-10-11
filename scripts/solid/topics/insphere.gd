extends TopicBase

const TOPIC_TITLE := "等体积法 · 求三棱锥的内切球"

var ORDER := ["A", "B", "C", "P"]
var P := {
	"A": Vector3(6, 0, 0),
	"B": Vector3(0, 6, 0),
	"C": Vector3(0, 0, 6),
	"P": Vector3(0, 0, 0),
}
var PCOL := {
	"A": Color("9dff9d"),
	"B": Color("9dc8ff"),
	"C": Color("ffd977"),
	"P": Color("ff9d9d"),
}
var EDGES := [
	["P", "A"], ["P", "B"], ["P", "C"], ["A", "B"], ["A", "C"], ["B", "C"],
]
var IN_R := 3.0 - sqrt(3.0)
var I_CENTER := Vector3(IN_R, IN_R, IN_R)
var TANG := [
	Vector3(IN_R, IN_R, 0.0),
	Vector3(0.0, IN_R, IN_R),
	Vector3(IN_R, 0.0, IN_R),
	Vector3(2.0, 2.0, 2.0),
]

var STEPS := [
	{"dur": 8.5, "dist": 15.5, "yaw": 0.80, "pitch": 0.32, "focus": Vector3(2.0, 2.0, 2.0)},
	{"dur": 9.0, "dist": 15.0, "yaw": 0.62, "pitch": 0.30, "focus": Vector3(2.0, 2.0, 2.0)},
	{"dur": 10.0, "dist": 15.5, "yaw": 1.05, "pitch": 0.28, "focus": Vector3(2.3, 2.3, 2.2)},
	{"dur": 9.5, "dist": 14.5, "yaw": 0.55, "pitch": 0.26, "focus": Vector3(2.0, 2.0, 2.0)},
	{"dur": 11.0, "dist": 13.5, "yaw": 0.85, "pitch": 0.28, "focus": Vector3(2.0, 2.0, 2.0)},
	{"dur": 11.5, "dist": 13.5, "yaw": 0.60, "pitch": 0.30, "focus": Vector3(2.0, 2.0, 2.0)},
	{"dur": 13.0, "dist": 15.5, "yaw": 0.85, "pitch": 0.30, "focus": Vector3(2.0, 2.0, 2.0)},
]

var TITLES := [
	"问题与思路",
	"① 三棱两两垂直且相等",
	"② 算体积 V 与表面积 S表",
	"③ 等体积法列式",
	"④ 解出 r，确定球心",
	"⑤ 作出内切球与切点",
	"⑥ 方法小结",
]

var TEXTS := [
	"""[font_size=26][b]等体积法 · 求三棱锥的内切球[/b][/font_size]

[color=#cfe2ff][b]问题[/b][/color]
三棱锥 P-ABC 中，PA、PB、PC 两两垂直且相等，
PA = PB = PC = 6，求它的内切球半径 r。

[color=#cfe2ff][b]思路（等体积法）[/b][/color]
把球心 I 与四个面相连，棱锥被分成四个小棱锥，
它们都以 r 为高。
由体积关系 V = (1/3)·S表·r，反解出 r = 3V / S表。

[color=#7f93b5]拖动旋转 · 滚轮缩放 · 空格自动播放。[/color]""",

	"""[font_size=26][b]① 三棱两两垂直且相等[/b][/font_size]

以公共顶点 P 为原点，三条棱沿坐标轴：

[color=#9dff9d][b]A(6, 0, 0)[/b][/color]　[color=#9dc8ff][b]B(0, 6, 0)[/b][/color]　[color=#ffd977][b]C(0, 0, 6)[/b][/color]

三个侧面是直角等腰三角形，
底面 △ABC 是边长 [b]6√2[/b] 的正三角形。

这是“墙角模型”的等棱特例，高度对称，
内切球球心必在对称轴（过 P 的体对角线）上。""",

	"""[font_size=26][b]② 算体积 V 与表面积 S表[/b][/font_size]

[color=#ffd479][b]体积[/b][/color]
V = (1/6)·PA·PB·PC = (1/6)·6³ = [b]36[/b]

[color=#ffd479][b]表面积[/b][/color]
· 三个侧面：3 × (½·6·6) = 54
· 底面正三角形：边长 6√2
　S(△ABC) = (√3/4)(6√2)² = 18√3

S表 = 54 + 18√3 ≈ [b]85.18[/b]""",

	"""[font_size=26][b]③ 等体积法列式[/b][/font_size]

设内切球半径为 r，球心 I 到四个面的距离
都等于 r（即各面与球相切）。

把 I 与四个面连成四个小棱锥，高均为 r，
四者体积之和等于原棱锥体积：

[center][font_size=24][b]V = (1/3) · S表 · r[/b][/font_size]

代入：
36 = (1/3)(54 + 18√3) · r""",

	"""[font_size=26][b]④ 解出 r，确定球心[/b][/font_size]

[center][b]r = 3V / S表 = 108 / (54 + 18√3)[/b][/center]

分母有理化：
r = 6 / (3 + √3) = [b][color=#ffd479]3 - √3 ≈ 1.268[/color][/b]

球心在对称轴上：
[center][b][color=#ffd479]I(r, r, r) ≈ (1.268, 1.268, 1.268)[/color][/b][/center]""",

	"""[font_size=26][b]⑤ 作出内切球与切点[/b][/font_size]

以 I 为球心、r = 3-√3 为半径作球，
与四个面都相切。

[color=#cfe2ff][b]切点[/b][/color]
· 三个侧面：(r,r,0)、(0,r,r)、(r,0,r)
· 底面 △ABC：(2, 2, 2)

球心与切点的连线垂直于相应的面。""",

	"""[font_size=26][b]⑥ 方法小结[/b][/font_size]

[color=#cfe2ff][b]等体积法求内切球半径[/b][/color]
[center][font_size=24][b]r = 3V / S表[/b][/font_size]

· V 为多面体体积
· S表 为全面积
· 适用于存在内切球的多面体（尤其三棱锥）

原理：球心到各面距离相等，把多面体分割成
若干以 r 为高的锥体，体积之和即为总体积。""",
]

var edge_mat: StandardMaterial3D
var face_mat: StandardMaterial3D
var in_mat: StandardMaterial3D
var rad_mat: StandardMaterial3D
var tang_mat: StandardMaterial3D
var ring_mat: StandardMaterial3D
var sphere_fill_mat: StandardMaterial3D

var vertex_nodes := {}
var name_labels := {}
var coord_labels := {}
var edge_segs := []
var marks := []
var faces_mesh: MeshInstance3D
var marker: Node3D
var ilabel: Label3D
var rad_segs := []
var rad_labels := []
var tang_nodes := []
var tang_labels := []

var sphere_root: Node3D


func build() -> void:
	build_axes(7.0)
	build_grid(-1, 7, -1, 7)
	build_tetra()
	build_marks()
	build_center()
	build_tangents()
	build_sphere()


func build_tetra() -> void:
	face_mat = mk_mat(Color("5f9bff"), 0.16)
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
		var coord := "%s(%d, %d, %d)" % [k, int(P[k].x), int(P[k].y), int(P[k].z)]
		var cl := mk_label(coord, mv(P[k]) + Vector3(0, -0.5, 0), 40, Color(1, 1, 1, 0.95), 10)
		cl.modulate.a = 0.0
		coord_labels[k] = cl

	for e in EDGES:
		edge_segs.append(mk_seg(self, mv(P[e[0]]), mv(P[e[1]]), 0.03, edge_mat, true))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := [
		[P["P"], P["A"], P["B"]],
		[P["P"], P["A"], P["C"]],
		[P["P"], P["B"], P["C"]],
		[P["A"], P["B"], P["C"]],
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
	var o: Vector3 = P["P"]
	marks.append(mk_seg(self, mv(o), mv(o + Vector3(0.8, 0, 0)), 0.022, edge_mat))
	marks.append(mk_seg(self, mv(o), mv(o + Vector3(0, 0.8, 0)), 0.022, edge_mat))
	marks.append(mk_seg(self, mv(o), mv(o + Vector3(0, 0, 0.8)), 0.022, edge_mat))


func build_center() -> void:
	in_mat = fade_mat(Color("ffb84d"), 1.0, true)

	marker = mk_ball(mv(I_CENTER), 0.12, in_mat)
	ilabel = mk_label("I", mv(I_CENTER) + Vector3(0, 0.42, 0), 70, Color("ffb84d"), 12)
	ilabel.modulate.a = 0.0

	rad_mat = fade_mat(Color("ff9ad5"), 0.95)
	var names := ["(r,r,0)", "(0,r,r)", "(r,0,r)", "(2,2,2)"]
	for i in TANG.size():
		rad_segs.append(mk_seg(self, mv(I_CENTER), mv(TANG[i]), 0.02, rad_mat, true))
		var lb := mk_label("r", mv(I_CENTER).lerp(mv(TANG[i]), 0.5), 46, Color("ff9ad5"), 11)
		lb.modulate.a = 0.0
		rad_labels.append(lb)
		lb.set_meta("ptxt", names[i])


func build_tangents() -> void:
	tang_mat = fade_mat(Color("ff6b6b"), 1.0, true)
	for i in TANG.size():
		tang_nodes.append(mk_ball(mv(TANG[i]), 0.1, tang_mat))
		var lb := mk_label("", mv(TANG[i]) + Vector3(0, -0.42, 0), 40, Color("ff6b6b"), 10)
		lb.modulate.a = 0.0
		tang_labels.append(lb)


func build_sphere() -> void:
	ring_mat = fade_mat(Color("8fe4ff"), 1.0)
	sphere_fill_mat = fade_mat(Color("ffb84d"), 0.14)
	sphere_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	sphere_root = Node3D.new()
	sphere_root.position = mv(I_CENTER)
	sphere_root.visible = false
	add_child(sphere_root)

	var fill := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = IN_R
	sm.height = IN_R * 2.0
	sm.radial_segments = 48
	sm.rings = 24
	sm.material = sphere_fill_mat
	fill.mesh = sm
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sphere_root.add_child(fill)

	for h in [-1.05, -0.6, 0.0, 0.6, 1.05]:
		var r := sqrt(maxf(IN_R * IN_R - h * h, 0.001))
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = maxf(r - 0.02, 0.015)
		tm.outer_radius = r + 0.02
		tm.rings = 64
		tm.ring_segments = 8
		tm.material = ring_mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.position = Vector3(0, h, 0)
		sphere_root.add_child(tor)

	for ang in [0.0, 30.0, 60.0, 90.0, 120.0, 150.0]:
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = IN_R - 0.02
		tm.outer_radius = IN_R + 0.02
		tm.rings = 64
		tm.ring_segments = 8
		tm.material = ring_mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.basis = Basis(Vector3.UP, deg_to_rad(ang)) * Basis(Vector3.RIGHT, PI * 0.5)
		sphere_root.add_child(tor)


func apply(g: float) -> void:
	var k_ax := smooth_k(g, 0.0, 0.6)
	for am in axis_mats:
		(am as StandardMaterial3D).albedo_color.a = k_ax
	for lb in axis_labels:
		lb.modulate.a = k_ax
	axis_root.visible = k_ax > 0.01
	grid_mat.albedo_color.a = 0.5 * smooth_k(g, 0.3, 1.0)

	for i in ORDER.size():
		var k := ease_pop(smooth_k(g, 0.3 + i * 0.1, 0.65 + i * 0.1))
		var vn: MeshInstance3D = vertex_nodes[ORDER[i]]
		vn.visible = k > 0.02
		vn.scale = Vector3.ONE * k
		name_labels[ORDER[i]].modulate.a = k
		coord_labels[ORDER[i]].modulate.a = smooth_k(g, 1.15 + i * 0.12, 1.55 + i * 0.12)

	for i in edge_segs.size():
		set_grow(edge_segs[i], smooth_k(g, 0.5 + i * 0.06, 0.85 + i * 0.06))

	face_mat.albedo_color.a = 0.16 * smooth_k(g, 0.8, 1.15)
	faces_mesh.visible = face_mat.albedo_color.a > 0.004

	for s in marks:
		set_grow(s, smooth_k(g, 1.0, 1.35))

	var k_i := ease_pop(smooth_k(g, 3.15, 3.5))
	marker.visible = k_i > 0.02
	marker.scale = Vector3.ONE * k_i
	ilabel.position = mv(I_CENTER) + Vector3(0, 0.45, 0)
	ilabel.modulate.a = smooth_k(g, 3.3, 3.65)

	rad_mat.albedo_color.a = 0.95 * smooth_k(g, 3.5, 3.9)
	for i in rad_segs.size():
		set_grow(rad_segs[i], smooth_k(g, 3.55 + i * 0.08, 3.95 + i * 0.08))
		rad_labels[i].position = mv(I_CENTER).lerp(mv(TANG[i]), 0.5)
		rad_labels[i].modulate.a = smooth_k(g, 3.9 + i * 0.06, 4.25 + i * 0.06)

	var k_s := ease_out(smooth_k(g, 4.1, 4.9))
	sphere_root.visible = k_s > 0.01
	sphere_root.scale = Vector3.ONE * maxf(k_s, 0.001)
	sphere_fill_mat.albedo_color.a = 0.13 * k_s
	ring_mat.albedo_color.a = k_s

	tang_mat.albedo_color.a = smooth_k(g, 4.8, 5.2)
	for i in tang_nodes.size():
		var kt := ease_pop(smooth_k(g, 4.8 + i * 0.07, 5.1 + i * 0.07))
		tang_nodes[i].visible = kt > 0.02
		tang_nodes[i].scale = Vector3.ONE * kt
		tang_labels[i].position = mv(TANG[i]) + Vector3(0, -0.44, 0)
		tang_labels[i].text = (rad_labels[i].get_meta("ptxt") as String) if i < rad_labels.size() else ""
		tang_labels[i].modulate.a = smooth_k(g, 5.05 + i * 0.07, 5.4 + i * 0.07)