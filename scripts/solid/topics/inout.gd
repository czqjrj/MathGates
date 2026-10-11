extends TopicBase

const TOPIC_TITLE := "正四面体 · 内切球与外接球对比"

var ORDER := ["A", "B", "C", "P"]
var P := {
	"A": Vector3(0, 0, 0),
	"B": Vector3(6, 0, 0),
	"C": Vector3(3, 3.0 * sqrt(3.0), 0),
	"P": Vector3(3, sqrt(3.0), 2.0 * sqrt(6.0)),
}
var PCOL := {
	"A": Color("9dff9d"),
	"B": Color("9dc8ff"),
	"C": Color("ffd977"),
	"P": Color("ff9d9d"),
}
var EDGES := [
	["A", "B"], ["A", "C"], ["B", "C"], ["A", "P"], ["B", "P"], ["C", "P"],
]
var O_PRIME := Vector3(3.0, sqrt(3.0), 0.0)
var G := Vector3(3.0, sqrt(3.0), sqrt(6.0) * 0.5)
var H_TOT := 2.0 * sqrt(6.0)
var R_OUT := 3.0 * sqrt(6.0) * 0.5
var R_IN := sqrt(6.0) * 0.5

var STEPS := [
	{"dur": 9.0, "dist": 16.0, "yaw": 0.80, "pitch": 0.30, "focus": Vector3(3.0, 1.7, 2.2)},
	{"dur": 10.0, "dist": 15.0, "yaw": 0.55, "pitch": 0.26, "focus": Vector3(3.0, 1.7, 2.2)},
	{"dur": 10.0, "dist": 14.5, "yaw": 1.00, "pitch": 0.24, "focus": Vector3(3.0, 1.7, 2.2)},
	{"dur": 11.0, "dist": 13.0, "yaw": 0.70, "pitch": 0.26, "focus": Vector3(3.0, 1.7, 1.8)},
	{"dur": 11.0, "dist": 13.0, "yaw": 0.35, "pitch": 0.24, "focus": Vector3(3.0, 1.7, 2.2)},
	{"dur": 12.0, "dist": 15.5, "yaw": 0.90, "pitch": 0.30, "focus": Vector3(3.0, 1.7, 2.2)},
	{"dur": 13.0, "dist": 15.5, "yaw": 0.75, "pitch": 0.30, "focus": Vector3(3.0, 1.7, 2.2)},
]

var TITLES := [
	"问题与关键事实",
	"① 正四面体的高 h",
	"② 球心在两球公共中心",
	"③ 内切球半径 r",
	"④ 外接球半径 R",
	"⑤ 作出内、外接球",
	"⑥ 方法小结",
]

var TEXTS := [
	"""[font_size=26][b]内切球 & 外接球 · 对比[/b][/font_size]

[color=#cfe2ff][b]问题[/b][/color]
正四面体 P-ABC 的棱长 a = 6，
求它的内切球半径 r 与外接球半径 R。

[color=#cfe2ff][b]关键事实[/b][/color]
正四面体的内切球、外接球 [b]同心[/b]，
球心就是正四面体的中心（四心合一）。
沿一条高观察，恒有 [b]R + r = h[/b]（高）。

[color=#7f93b5]拖动旋转 · 滚轮缩放 · 空格自动播放。[/color]""",

	"""[font_size=26][b]① 正四面体的高 h[/b][/font_size]

底面是边长 6 的正三角形，其中心 O' 到底面
顶点的距离（底面外接圆半径）为：

O'A = (√3/3)·6 = 2√3

高：h = √(6² - (2√3)²) = √(36 - 12)
　　= √24 = [b][color=#ffd479]2√6 ≈ 4.899[/color][/b]

也可直接记：h = (√6/3)·a。""",

	"""[font_size=26][b]② 球心在两球公共中心[/b][/font_size]

正四面体高度对称，
内切球与外接球 [b]同心[/b]，
球心 O 就是正四面体的中心（重心）。

重心把高分成 3 : 1，
即 O 在高上，且：

[center][font_size=24][b][color=#7fd8ff]R + r = h[/color][/b][/font_size]

下面分别求 r 与 R。""",

	"""[font_size=26][b]③ 内切球半径 r（等体积法）[/b][/font_size]

V = (1/3)·S表·r，而正四面体 V = (√2/12)a³。

a = 6：V = (√2/12)·216 = 18√2
S表 = 4 × (√3/4)·6² = 36√3

[center][b]r = 3V / S表 = 54√2 / (36√3) = √6/2 ≈ 1.225[/b][/center]

（也等于高的 1/4：r = h/4。）""",

	"""[font_size=26][b]④ 外接球半径 R[/b][/font_size]

球心 O 到底面的距离就是 r = √6/2，
而顶点 P 到底面的距离是 h，

所以 O 到顶点 P 的距离：
[center][b]R = h - r = 2√6 - √6/2 = 3√6/2 ≈ 3.674[/b][/center]

也可由 OA 验证：
OA² = (2√3)² + r² = 12 + 3/2 = 27/2
R = √(27/2) = 3√6/2""",

	"""[font_size=26][b]⑤ 作出内、外接球[/b][/font_size]

两球 [b]同心[/b] 于 O：

· [color=#ffd479]内切球[/color]　r = √6/2 ≈ 1.225，与四个面相切
· [color=#7fd8ff]外接球[/color]　R = 3√6/2 ≈ 3.674，过四个顶点

半径之比：
[center][font_size=24][b]R : r = 3 : 1[/b][/font_size]""",

	"""[font_size=26][b]⑥ 方法小结[/b][/font_size]

[color=#cfe2ff][b]正四面体（棱长 a）的两球[/b][/color]
· 内切球　r = (√6/12)·a
· 外接球　R = (√6/4)·a
· 高　　　h = (√6/3)·a

[color=#ffd479][b]恒有 R = 3r 且 R + r = h[/b][/color]，
两球同心于正四面体的中心。

本例 a = 6：r = √6/2，R = 3√6/2。""",
]

var edge_mat: StandardMaterial3D
var face_mat: StandardMaterial3D
var h_mat: StandardMaterial3D
var r_mat: StandardMaterial3D
var R_mat: StandardMaterial3D
var out_ring_mat: StandardMaterial3D
var out_fill_mat: StandardMaterial3D
var in_ring_mat: StandardMaterial3D
var in_fill_mat: StandardMaterial3D
var g_mat: StandardMaterial3D
var o1_mat: StandardMaterial3D

var vertex_nodes := {}
var name_labels := {}
var edge_segs := []
var faces_mesh: MeshInstance3D
var h_seg: Node3D
var h_label: Label3D
var r_seg: Node3D
var r_label: Label3D
var R_segs := []
var R_label: Label3D
var g_point: Node3D
var g_label: Label3D
var o1_point: Node3D
var o1_label: Label3D
var out_root: Node3D
var in_root: Node3D


func build() -> void:
	build_grid(-2, 9, -3, 8)
	build_tetra()
	build_aux()
	build_center()
	build_spheres()


func build_tetra() -> void:
	face_mat = mk_mat(Color("5f9bff"), 0.15)
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
		[P["A"], P["B"], P["P"]],
		[P["A"], P["C"], P["P"]],
		[P["B"], P["C"], P["P"]],
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


func build_aux() -> void:
	h_mat = fade_mat(Color("cfe2ff"), 0.85)
	h_seg = mk_seg(self, mv(O_PRIME), mv(P["P"]), 0.018, h_mat, true)
	h_label = mk_label("h = 2√6", mv(O_PRIME).lerp(mv(P["P"]), 0.5) + Vector3(0.45, 0, 0), 48, Color("cfe2ff"), 11)
	h_label.modulate.a = 0.0

	R_mat = fade_mat(Color("7fd8ff"), 1.0)
	R_label = mk_label("R = 3√6/2", mv(G).lerp(mv(P["P"]), 0.55) + Vector3(0.5, 0, 0), 50, Color("7fd8ff"), 11)
	R_label.modulate.a = 0.0


func build_center() -> void:
	g_mat = fade_mat(Color("ffd479"), 1.0, true)
	o1_mat = fade_mat(Color("ff9ad5"), 1.0, true)

	o1_point = mk_ball(mv(O_PRIME), 0.11, o1_mat)
	o1_label = mk_label("O'", mv(O_PRIME) + Vector3(-0.5, -0.4, 0), 54, Color("ff9ad5"), 11)
	o1_label.modulate.a = 0.0

	g_point = mk_ball(mv(G), 0.13, g_mat)
	g_label = mk_label("O", mv(G) + Vector3(-0.55, 0.35, 0), 62, Color("ffd479"), 12)
	g_label.modulate.a = 0.0

	r_mat = fade_mat(Color("ffb84d"), 1.0)
	r_seg = mk_seg(self, mv(G), mv(O_PRIME), 0.03, r_mat, true)
	r_label = mk_label("r = √6/2", mv(G).lerp(mv(O_PRIME), 0.5) + Vector3(-0.55, 0, 0), 48, Color("ffb84d"), 11)
	r_label.modulate.a = 0.0


func build_spheres() -> void:
	out_ring_mat = fade_mat(Color("8fe4ff"), 1.0)
	out_fill_mat = fade_mat(Color("57c8ff"), 0.08)
	out_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	in_ring_mat = fade_mat(Color("ffd479"), 1.0)
	in_fill_mat = fade_mat(Color("ffb84d"), 0.14)
	in_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	out_root = Node3D.new()
	out_root.position = mv(G)
	out_root.visible = false
	add_child(out_root)
	var ofill := MeshInstance3D.new()
	var osm := SphereMesh.new()
	osm.radius = R_OUT
	osm.height = R_OUT * 2.0
	osm.radial_segments = 56
	osm.rings = 28
	osm.material = out_fill_mat
	ofill.mesh = osm
	ofill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	out_root.add_child(ofill)
	for h in [-3.0, -1.9, 0.0, 1.9, 3.0]:
		if absf(h) >= R_OUT:
			continue
		var rr := sqrt(R_OUT * R_OUT - h * h)
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = maxf(rr - 0.02, 0.02)
		tm.outer_radius = rr + 0.02
		tm.rings = 72
		tm.ring_segments = 8
		tm.material = out_ring_mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.position = Vector3(0, h, 0)
		out_root.add_child(tor)
	for ang in [0.0, 30.0, 60.0, 90.0, 120.0, 150.0]:
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = R_OUT - 0.02
		tm.outer_radius = R_OUT + 0.02
		tm.rings = 72
		tm.ring_segments = 8
		tm.material = out_ring_mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.basis = Basis(Vector3.UP, deg_to_rad(ang)) * Basis(Vector3.RIGHT, PI * 0.5)
		out_root.add_child(tor)

	in_root = Node3D.new()
	in_root.position = mv(G)
	in_root.visible = false
	add_child(in_root)
	var ifill := MeshInstance3D.new()
	var ism := SphereMesh.new()
	ism.radius = R_IN
	ism.height = R_IN * 2.0
	ism.radial_segments = 48
	ism.rings = 24
	ism.material = in_fill_mat
	ifill.mesh = ism
	ifill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	in_root.add_child(ifill)
	for h in [-1.05, -0.6, 0.0, 0.6, 1.05]:
		var rr := sqrt(maxf(R_IN * R_IN - h * h, 0.001))
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = maxf(rr - 0.018, 0.015)
		tm.outer_radius = rr + 0.018
		tm.rings = 64
		tm.ring_segments = 8
		tm.material = in_ring_mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.position = Vector3(0, h, 0)
		in_root.add_child(tor)
	for ang in [0.0, 45.0, 90.0, 135.0]:
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = R_IN - 0.018
		tm.outer_radius = R_IN + 0.018
		tm.rings = 64
		tm.ring_segments = 8
		tm.material = in_ring_mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.basis = Basis(Vector3.UP, deg_to_rad(ang)) * Basis(Vector3.RIGHT, PI * 0.5)
		in_root.add_child(tor)

	for k in ORDER:
		R_segs.append(mk_seg(self, mv(G), mv(P[k]), 0.018, R_mat, true))


func apply(g: float) -> void:
	grid_mat.albedo_color.a = 0.45 * smooth_k(g, 0.0, 0.6)

	for i in edge_segs.size():
		set_grow(edge_segs[i], smooth_k(g, 0.25 + i * 0.05, 0.6 + i * 0.05))
	face_mat.albedo_color.a = 0.15 * smooth_k(g, 0.7, 1.05)
	faces_mesh.visible = face_mat.albedo_color.a > 0.004

	for i in ORDER.size():
		var k := ease_pop(smooth_k(g, 0.2 + i * 0.1, 0.55 + i * 0.1))
		var vn: MeshInstance3D = vertex_nodes[ORDER[i]]
		vn.visible = k > 0.02
		vn.scale = Vector3.ONE * k
		name_labels[ORDER[i]].modulate.a = k

	set_grow(h_seg, smooth_k(g, 1.15, 1.75))
	h_label.position = mv(O_PRIME).lerp(mv(P["P"]), 0.5) + Vector3(0.45, 0, 0)
	h_label.modulate.a = smooth_k(g, 1.6, 1.95)

	var k_o1 := ease_pop(smooth_k(g, 1.9, 2.2))
	o1_point.visible = k_o1 > 0.02
	o1_point.scale = Vector3.ONE * k_o1
	o1_label.modulate.a = smooth_k(g, 2.0, 2.3)

	var k_g := ease_pop(smooth_k(g, 2.2, 2.55))
	g_point.visible = k_g > 0.02
	g_point.scale = Vector3.ONE * k_g
	g_label.modulate.a = smooth_k(g, 2.35, 2.65)

	set_grow(r_seg, smooth_k(g, 3.15, 3.7))
	r_label.position = mv(G).lerp(mv(O_PRIME), 0.5) + Vector3(-0.55, 0, 0)
	r_label.modulate.a = smooth_k(g, 3.6, 3.95)

	R_mat.albedo_color.a = smooth_k(g, 4.05, 4.4)
	for i in R_segs.size():
		set_grow(R_segs[i], smooth_k(g, 4.05 + i * 0.06, 4.45 + i * 0.06))
	R_label.position = mv(G).lerp(mv(P["P"]), 0.55) + Vector3(0.5, 0, 0)
	R_label.modulate.a = smooth_k(g, 4.5, 4.85)

	var k_in := ease_out(smooth_k(g, 4.9, 5.5))
	in_root.visible = k_in > 0.01
	in_root.scale = Vector3.ONE * maxf(k_in, 0.001)
	in_fill_mat.albedo_color.a = 0.14 * k_in
	in_ring_mat.albedo_color.a = k_in

	var k_out := ease_out(smooth_k(g, 5.2, 5.9))
	out_root.visible = k_out > 0.01
	out_root.scale = Vector3.ONE * maxf(k_out, 0.001)
	out_fill_mat.albedo_color.a = 0.08 * k_out
	out_ring_mat.albedo_color.a = k_out