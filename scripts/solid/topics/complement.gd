extends TopicBase

const TOPIC_TITLE := "补形法 · 求三棱锥的外接球"

var ORDER := ["A", "B", "C", "P"]
var P := {
	"A": Vector3(3, 0, 0),
	"B": Vector3(0, 4, 0),
	"C": Vector3(0, 0, 5),
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
var DIM := Vector3(3, 4, 5)
var CUBE_CENTER := Vector3(1.5, 2, 2.5)
var CUBE_R := sqrt(50.0) * 0.5
var OPP := Vector3(3, 4, 5)

var STEPS := [
	{"dur": 8.0, "dist": 13.5, "yaw": 0.80, "pitch": 0.32, "focus": Vector3(1.5, 2.0, 2.2)},
	{"dur": 9.0, "dist": 12.0, "yaw": 0.65, "pitch": 0.30, "focus": Vector3(1.5, 2.0, 2.2)},
	{"dur": 11.0, "dist": 15.0, "yaw": 1.10, "pitch": 0.34, "focus": Vector3(1.5, 2.0, 2.5)},
	{"dur": 9.5, "dist": 11.0, "yaw": 0.35, "pitch": 0.24, "focus": Vector3(1.5, 2.0, 2.5)},
	{"dur": 12.0, "dist": 12.5, "yaw": 0.90, "pitch": 0.30, "focus": Vector3(1.5, 2.0, 2.5)},
	{"dur": 13.0, "dist": 15.5, "yaw": 0.85, "pitch": 0.30, "focus": Vector3(1.5, 2.0, 2.5)},
]

var TITLES := [
	"问题与思路",
	"① 墙角模型：三棱两两垂直",
	"② 补成长方体",
	"③ 体对角线 = 球直径",
	"④ 求半径 R",
	"⑤ 方法小结",
]

var TEXTS := [
	"""[font_size=26][b]补形法 · 求三棱锥的外接球[/b][/font_size]

[color=#cfe2ff][b]问题[/b][/color]
三棱锥 P-ABC 中，PA、PB、PC 两两垂直，
PA = 3，PB = 4，PC = 5，求它的外接球半径。

[color=#cfe2ff][b]思路（补形法 / 构造法）[/b][/color]
三条棱两两垂直 → 可以补成一个长方体，
三棱锥的四个顶点恰好是长方体的顶点，
于是它们的外接球相同，直接求长方体的外接球。

[color=#7f93b5]拖动旋转 · 滚轮缩放 · 空格自动播放。[/color]""",

	"""[font_size=26][b]① 墙角模型[/b][/font_size]

以公共顶点 P 为原点，三条两两垂直的棱
PA、PB、PC 分别沿 x、y、z 轴：

[color=#9dff9d][b]A(3, 0, 0)[/b][/color]　[color=#9dc8ff][b]B(0, 4, 0)[/b][/color]　[color=#ffd977][b]C(0, 0, 5)[/b][/color]

顶点 P 处三棱两两垂直（墙角），
这是补形法最典型的适用模型。""",

	"""[font_size=26][b]② 补成长方体[/b][/font_size]

以 3、4、5 为长、宽、高，
把三棱锥补成一个长方体。

原三棱锥的四个顶点 P、A、B、C
[color=#7fd8ff][b]恰好是长方体的一组顶点[/b][/color]，
所以它们拥有同一个外接球。""",

	"""[font_size=26][b]③ 体对角线 = 球的直径[/b][/font_size]

长方体的外接球球心在体对角线中点，
直径就是这条体对角线：

[center][font_size=24][b]2R = √(a² + b² + c²)[/b][/font_size]

2R = √(3² + 4² + 5²) = √50 = 5√2 ≈ 7.071""",

	"""[font_size=26][b]④ 求半径 R[/b][/font_size]

球心 O 是长方体中心：
[center][b][color=#ffd479]O(1.5, 2, 2.5)[/color][/b][/center]

R = ½√50 = 5√2 / 2 ≈ [b][color=#ffd479]3.536[/color][/b]

球面方程：
[center][b][color=#7fd8ff](x-1.5)² + (y-2)² + (z-2.5)² = 12.5[/color][/b][/center]""",

	"""[font_size=26][b]⑤ 方法小结[/b][/font_size]

[color=#cfe2ff][b]补形法适用条件[/b][/color]
· 三条棱两两垂直（墙角模型）
· 或三组对棱分别相等

[color=#cfe2ff][b]核心结论[/b][/color]
[center][font_size=24][b]2R = √(a² + b² + c²)[/b][/font_size]

本例 a=3，b=4，c=5：
R = 5√2 / 2 ≈ [color=#ffd479][b]3.536[/b][/color]。""",
]

var edge_mat: StandardMaterial3D
var face_mat: StandardMaterial3D
var cube_mat: StandardMaterial3D
var diag_mat: StandardMaterial3D
var rad_mat: StandardMaterial3D
var ring_mat: StandardMaterial3D
var sphere_fill_mat: StandardMaterial3D

var vertex_nodes := {}
var name_labels := {}
var coord_labels := {}
var edge_segs := []
var marks := []
var faces_mesh: MeshInstance3D
var cube_segs := []
var diag_seg: Node3D
var marker: Node3D
var olabel: Label3D
var rad_segs := []
var rad_labels := []

var sphere_root: Node3D


func build() -> void:
	build_axes(6.2)
	build_grid(-1, 5, -1, 5)
	build_tetra()
	build_marks()
	build_cuboid()
	build_diag()
	build_center()
	build_sphere()


func build_tetra() -> void:
	face_mat = mk_mat(Color("5f9bff"), 0.16)
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
		mi.position = mv(P[k])
		mi.visible = false
		add_child(mi)
		vertex_nodes[k] = mi
		var nl := mk_label(k, mv(P[k]) + Vector3(0, 0.4, 0), 76, PCOL[k], 13)
		nl.modulate.a = 0.0
		name_labels[k] = nl
		var coord := "%s(%d, %d, %d)" % [k, int(P[k].x), int(P[k].y), int(P[k].z)]
		var cl := mk_label(coord, mv(P[k]) + Vector3(0, -0.48, 0), 40, Color(1, 1, 1, 0.95), 10)
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
	marks.append(mk_seg(self, mv(o), mv(o + Vector3(0.7, 0, 0)), 0.02, edge_mat))
	marks.append(mk_seg(self, mv(o), mv(o + Vector3(0, 0.7, 0)), 0.02, edge_mat))
	marks.append(mk_seg(self, mv(o), mv(o + Vector3(0, 0, 0.7)), 0.02, edge_mat))


func cuboid_corners() -> Array:
	var out := []
	for xi in [0.0, DIM.x]:
		for yi in [0.0, DIM.y]:
			for zi in [0.0, DIM.z]:
				out.append(Vector3(xi, yi, zi))
	return out


func cuboid_edges() -> Array:
	var c := cuboid_corners()
	var e := []
	for i in c.size():
		for j in range(i + 1, c.size()):
			var d: Vector3 = c[j] - c[i]
			var nz := 0
			if absf(d.x) > 0.001:
				nz += 1
			if absf(d.y) > 0.001:
				nz += 1
			if absf(d.z) > 0.001:
				nz += 1
			if nz == 1:
				e.append([c[i], c[j]])
	return e


func build_cuboid() -> void:
	cube_mat = fade_mat(Color("7fd8ff"), 0.85)
	for e in cuboid_edges():
		cube_segs.append(mk_seg(self, mv(e[0]), mv(e[1]), 0.02, cube_mat, true))


func build_diag() -> void:
	diag_mat = fade_mat(Color("ffd479"), 1.0)
	diag_seg = mk_seg(self, mv(Vector3.ZERO), mv(OPP), 0.032, diag_mat, true)


func build_center() -> void:
	rad_mat = fade_mat(Color("ff9ad5"), 0.95)

	marker = mk_ball(mv(CUBE_CENTER), 0.15, mk_mat(Color("ffd479"), 1.0, true))

	olabel = mk_label("O(1.5, 2, 2.5)", mv(CUBE_CENTER) + Vector3(0, 0.5, 0), 50, Color("ffd479"), 12)
	olabel.modulate.a = 0.0

	for k in ["P", "A", "B", "C"]:
		rad_segs.append(mk_seg(self, mv(CUBE_CENTER), mv(P[k]), 0.016, rad_mat, true))
		var lb := mk_label("R", mv(CUBE_CENTER).lerp(mv(P[k]), 0.5), 48, Color("ff9ad5"), 11)
		lb.modulate.a = 0.0
		rad_labels.append(lb)


func build_sphere() -> void:
	ring_mat = fade_mat(Color("8fe4ff"), 1.0)
	sphere_fill_mat = fade_mat(Color("57c8ff"), 0.10)
	sphere_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	sphere_root = Node3D.new()
	sphere_root.position = mv(CUBE_CENTER)
	sphere_root.visible = false
	add_child(sphere_root)

	var fill := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = CUBE_R
	sm.height = CUBE_R * 2.0
	sm.radial_segments = 56
	sm.rings = 28
	sm.material = sphere_fill_mat
	fill.mesh = sm
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sphere_root.add_child(fill)

	for h in [-2.9, -2.0, -1.0, 0.0, 1.0, 2.0, 2.9]:
		if absf(h) >= CUBE_R:
			continue
		var r := sqrt(CUBE_R * CUBE_R - h * h)
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = maxf(r - 0.022, 0.02)
		tm.outer_radius = r + 0.022
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
		tm.inner_radius = CUBE_R - 0.022
		tm.outer_radius = CUBE_R + 0.022
		tm.rings = 72
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
		coord_labels[ORDER[i]].modulate.a = smooth_k(g, 0.95 + i * 0.12, 1.35 + i * 0.12)

	for i in edge_segs.size():
		set_grow(edge_segs[i], smooth_k(g, 0.5 + i * 0.06, 0.85 + i * 0.06))

	face_mat.albedo_color.a = 0.16 * smooth_k(g, 0.8, 1.15)
	faces_mesh.visible = face_mat.albedo_color.a > 0.004

	for s in marks:
		set_grow(s, smooth_k(g, 0.95, 1.3))

	for i in cube_segs.size():
		set_grow(cube_segs[i], smooth_k(g, 1.4 + i * 0.045, 1.85 + i * 0.045))

	set_grow(diag_seg, smooth_k(g, 2.7, 3.25))

	var k_mk := ease_pop(smooth_k(g, 3.2, 3.5))
	marker.visible = k_mk > 0.02
	marker.scale = Vector3.ONE * k_mk
	olabel.position = mv(CUBE_CENTER) + Vector3(0, 0.55, 0)
	olabel.modulate.a = smooth_k(g, 3.5, 3.8)

	rad_mat.albedo_color.a = 0.95 * smooth_k(g, 3.9, 4.3)
	for i in rad_segs.size():
		set_grow(rad_segs[i], smooth_k(g, 3.95 + i * 0.08, 4.35 + i * 0.08))
		rad_labels[i].position = mv(CUBE_CENTER).lerp(mv(P[ORDER[i]]), 0.5)
		rad_labels[i].modulate.a = smooth_k(g, 4.35 + i * 0.06, 4.7 + i * 0.06)

	var k_s := ease_out(smooth_k(g, 4.0, 4.8))
	sphere_root.visible = k_s > 0.01
	sphere_root.scale = Vector3.ONE * maxf(k_s, 0.001)
	sphere_fill_mat.albedo_color.a = 0.10 * k_s
	ring_mat.albedo_color.a = k_s

	diag_mat.albedo_color.a = 1.0 - 0.35 * smooth_k(g, 4.4, 5.0)
	cube_mat.albedo_color.a = 0.85 * (1.0 - 0.3 * smooth_k(g, 5.0, 5.6))