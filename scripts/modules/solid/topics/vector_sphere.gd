extends TopicBase

const TOPIC_TITLE := "空间向量法 · 求三棱锥的外接球"

var ORDER := ["A", "B", "C", "P"]
var P := {
	"A": Vector3(0, 0, 0),
	"B": Vector3(4, 0, 0),
	"C": Vector3(1, 3, 0),
	"P": Vector3(4, 2, 4),
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
var CENTER_M := Vector3(2, 1, 2)
var RADIUS_M := 3.0
var HM := Vector3(2, 1, 0)
var HR := sqrt(5.0)
var CENTROID_M := Vector3(2.25, 1.25, 1.0)

var STEPS := [
	{"dur": 7.0, "dist": 15.0, "yaw": 0.85, "pitch": 0.30, "focus": Vector3(2, 1.5, 2)},
	{"dur": 7.0, "dist": 9.5, "yaw": 0.70, "pitch": 0.36, "focus": Vector3(2, 1.5, 2)},
	{"dur": 7.5, "dist": 10.5, "yaw": 1.20, "pitch": 0.26, "focus": Vector3(2, 1.5, 2)},
	{"dur": 9.5, "dist": 11.5, "yaw": 0.55, "pitch": 0.34, "focus": Vector3(2, 1.5, 2)},
	{"dur": 10.5, "dist": 12.0, "yaw": 0.15, "pitch": 0.30, "focus": Vector3(2, 1.5, 2)},
	{"dur": 7.5, "dist": 9.0, "yaw": 0.75, "pitch": 0.42, "focus": Vector3(2, 1.5, 2)},
	{"dur": 12.0, "dist": 14.0, "yaw": 0.90, "pitch": 0.32, "focus": Vector3(2, 1.5, 2)},
	{"dur": 13.0, "dist": 15.5, "yaw": 1.15, "pitch": 0.26, "focus": Vector3(2, 1.5, 2)},
]

var TITLES := [
	"问题与思路",
	"① 建系 · 描点 · 连线",
	"② 写出四个顶点的坐标",
	"③ 设球心，列距离等式",
	"④ 解方程组（两两相减）",
	"⑤ 得到球心与半径",
	"⑥ 作出外接球与辅助线",
	"⑦ 方法小结",
]

var TEXTS := [
	"""[font_size=26][b]空间向量法求三棱锥的外接球[/b][/font_size]

[color=#cfe2ff][b]问题[/b][/color]
已知三棱锥 P-ABC 的四个顶点坐标，求它的外接球的
球心、半径以及球面方程。

[color=#cfe2ff][b]思路（坐标法 / 空间向量法）[/b][/color]
① 建立空间直角坐标系，写出四个顶点坐标
② 设球心 O(x, y, z)，由 |OA|=|OB|=|OC|=|OP| 列方程
③ 方程两两相减消去二次项，解出 (x, y, z)
④ 求半径 R = |OA|，写出球面方程，作图验证

[color=#7f93b5]按住鼠标左键拖动可旋转视角，滚轮缩放。[/color]""",

	"""[font_size=26][b]① 建系 · 描点 · 连线[/b][/font_size]

以 A 为原点，AB 所在直线为 x 轴，底面 ABC 所在
平面为 xOy 平面，过 A 且垂直于底面的直线为 z 轴，
建立空间直角坐标系（如图中三轴所示）。

依次描出四个顶点 A、B、C、P，
顺次连接 AB、AC、AP、BC、BP、CP，
得到三棱锥 P-ABC。""",

	"""[font_size=26][b]② 四个顶点的坐标[/b][/font_size]

[color=#ff9d9d][b]A(0, 0, 0)[/b][/color]　原点
[color=#9dff9d][b]B(4, 0, 0)[/b][/color]　在 x 轴上
[color=#9dc8ff][b]C(1, 3, 0)[/b][/color]　在底面内
[color=#ffd977][b]P(4, 2, 4)[/b][/color]　高为 4

底面 △ABC 位于 z = 0 平面上，
点 P 到底面的距离（即棱锥的高）为 4。""",

	"""[font_size=26][b]③ 设球心，列距离等式[/b][/font_size]

设球心为 O(x, y, z)，半径为 R。
球心到四个顶点的距离相等：

[center][b][color=#ffd479]OA = OB = OC = OP = R[/color][/b][/center]

两边平方，得到方程组：

x² + y² + z² = (x-4)² + y² + z²
x² + y² + z² = (x-1)² + (y-3)² + z²
x² + y² + z² = (x-4)² + (y-2)² + (z-4)²""",

	"""[font_size=26][b]④ 解方程组（两两相减）[/b][/font_size]

[b]①[/b] 展开：-8x + 16 = 0
　　[color=#ffd479]x = 2[/color]

[b]②[/b] 展开：-2x - 6y + 10 = 0，即 2x + 6y = 10
　　把 x = 2 代入，得 6y = 6，[color=#ffd479]y = 1[/color]

[b]③[/b] 展开：-8x - 4y - 8z + 36 = 0，即 2x + y + 2z = 9
　　把 x = 2，y = 1 代入，5 + 2z = 9，[color=#ffd479]z = 2[/color]""",

	"""[font_size=26][b]⑤ 球心与半径[/b][/font_size]

球心　[font_size=32][b][color=#ffd479]O(2, 1, 2)[/color][/b][/font_size]

半径　R = |OA|
　　　= √(2² + 1² + 2²)
　　　= √9
　　　= [b][color=#ffd479]3[/color][/b]

球心 O 到 A、B、C、P 四点的距离都等于 3，
因此 O 就是该三棱锥外接球的球心。""",

	"""[font_size=26][b]⑥ 作出外接球[/b][/font_size]

球面方程：
[center][b][color=#7fd8ff](x - 2)² + (y - 1)² + (z - 2)² = 9[/color][/b][/center]

辅助线：连接球心与四个顶点
OA = OB = OC = OP = R = 3

底面 △ABC 的外心为 H(2, 1, 0)，则
OH ⊥ 底面，H 是球心在底面上的射影，OH = 2。""",

	"""[font_size=26][b]⑦ 方法小结[/b][/font_size]

1. 建系，写出四个顶点坐标
2. 设球心 O(x, y, z)，由 OA = OB = OC = OP 列方程
3. 方程两两相减消去二次项，解出 x、y、z
4. 由 R = |OA| 求半径，写出球面方程

[font_size=24][color=#ffd479]结论：球心 O(2, 1, 2)，半径 R = 3，
球面 (x-2)² + (y-1)² + (z-2)² = 9。[/color][/font_size]""",
]

var edge_mat: StandardMaterial3D
var face_mat: StandardMaterial3D
var ring_mat: StandardMaterial3D
var sphere_fill_mat: StandardMaterial3D
var aux_mat: StandardMaterial3D
var aux_mat2: StandardMaterial3D

var vertex_nodes := {}
var name_labels := {}
var coord_labels := {}
var edge_segs := []
var faces_mesh: MeshInstance3D
var marker: Node3D
var qmark_label: Label3D
var olabel: Label3D
var dist_segs := []
var radius_labels := []
var sphere_root: Node3D
var hpoint: Node3D
var hlabel: Label3D
var perp_seg: Node3D
var circ_ring: MeshInstance3D


func build() -> void:
	build_axes(5.7)
	build_grid(-1, 5, -1, 5)
	build_tetra()
	build_marker()
	build_sphere()
	build_base_aux()


func build_tetra() -> void:
	face_mat = mk_mat(Color("5f9bff"), 0.17)
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
		var nl := mk_label(k, mv(P[k]) + Vector3(0, 0.38, 0), 76, PCOL[k], 13)
		nl.modulate.a = 0.0
		name_labels[k] = nl
		var coord := "%s(%d, %d, %d)" % [k, int(P[k].x), int(P[k].y), int(P[k].z)]
		var cl := mk_label(coord, mv(P[k]) + Vector3(0, -0.46, 0), 42, Color(1, 1, 1, 0.96), 10)
		cl.modulate.a = 0.0
		coord_labels[k] = cl

	for e in EDGES:
		edge_segs.append(mk_seg(self, mv(P[e[0]]), mv(P[e[1]]), 0.032, edge_mat, true))

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


func build_marker() -> void:
	aux_mat = fade_mat(Color("7fd8ff"), 0.9)

	marker = Node3D.new()
	marker.visible = false
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.15
	sm.height = 0.3
	sm.radial_segments = 28
	sm.rings = 14
	sm.material = mk_mat(Color("ffd479"), 1.0, true)
	mi.mesh = sm
	marker.add_child(mi)
	marker.position = mv(CENTROID_M)
	add_child(marker)

	qmark_label = mk_label("?", mv(CENTROID_M) + Vector3(0, 0.36, 0), 100, Color("ffe9a8"), 16)
	qmark_label.modulate.a = 0.0
	olabel = mk_label("O(2, 1, 2)", mv(CENTER_M) + Vector3(0, 0.44, 0), 58, Color("ffd479"), 12)
	olabel.modulate.a = 0.0

	for k in ORDER:
		dist_segs.append(mk_seg(self, mv(CENTROID_M), mv(P[k]), 0.018, aux_mat, true))
		var lb := mk_label("3", mv(CENTROID_M).lerp(mv(P[k]), 0.5), 54, Color("7fd8ff"), 11)
		lb.modulate.a = 0.0
		radius_labels.append(lb)


func build_sphere() -> void:
	ring_mat = fade_mat(Color("8fe4ff"), 1.0)
	sphere_fill_mat = fade_mat(Color("57c8ff"), 0.10)
	sphere_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	sphere_root = Node3D.new()
	sphere_root.position = mv(CENTER_M)
	sphere_root.visible = false
	add_child(sphere_root)

	var fill := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = RADIUS_M
	sm.height = RADIUS_M * 2.0
	sm.radial_segments = 56
	sm.rings = 28
	sm.material = sphere_fill_mat
	fill.mesh = sm
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sphere_root.add_child(fill)

	for h in [-2.3, -1.5, -0.75, 0.0, 0.75, 1.5, 2.3]:
		var r := sqrt(RADIUS_M * RADIUS_M - h * h)
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
		tm.inner_radius = RADIUS_M - 0.022
		tm.outer_radius = RADIUS_M + 0.022
		tm.rings = 72
		tm.ring_segments = 8
		tm.material = ring_mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.basis = Basis(Vector3.UP, deg_to_rad(ang)) * Basis(Vector3.RIGHT, PI * 0.5)
		sphere_root.add_child(tor)


func build_base_aux() -> void:
	aux_mat2 = fade_mat(Color("ff9ad5"), 0.95)

	perp_seg = mk_seg(self, mv(HM), mv(CENTER_M), 0.02, aux_mat2, true)

	hpoint = Node3D.new()
	hpoint.visible = false
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.1
	sm.height = 0.2
	sm.radial_segments = 20
	sm.rings = 10
	sm.material = mk_mat(Color("ff9ad5"), 1.0, true)
	mi.mesh = sm
	hpoint.add_child(mi)
	hpoint.position = mv(HM)
	add_child(hpoint)

	hlabel = mk_label("H(2, 1, 0)", mv(HM) + Vector3(0, -0.42, 0), 46, Color("ff9ad5"), 10)
	hlabel.modulate.a = 0.0

	circ_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = HR - 0.022
	tm.outer_radius = HR + 0.022
	tm.rings = 72
	tm.ring_segments = 8
	tm.material = aux_mat2
	circ_ring.mesh = tm
	circ_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	circ_ring.position = mv(HM)
	circ_ring.visible = false
	add_child(circ_ring)


func apply(g: float) -> void:
	var k_ax := smooth_k(g, 0.0, 0.62)
	for am in axis_mats:
		(am as StandardMaterial3D).albedo_color.a = k_ax
	for lb in axis_labels:
		lb.modulate.a = k_ax
	axis_root.visible = k_ax > 0.01
	grid_mat.albedo_color.a = 0.55 * smooth_k(g, 0.3, 1.0)

	for i in ORDER.size():
		var k := ease_pop(smooth_k(g, 1.0 + i * 0.10, 1.36 + i * 0.10))
		var vn: MeshInstance3D = vertex_nodes[ORDER[i]]
		vn.visible = k > 0.02
		vn.scale = Vector3.ONE * k
		name_labels[ORDER[i]].modulate.a = k
		coord_labels[ORDER[i]].modulate.a = smooth_k(g, 2.0 + i * 0.15, 2.42 + i * 0.15)

	for i in edge_segs.size():
		set_grow(edge_segs[i], smooth_k(g, 1.28 + i * 0.07, 1.62 + i * 0.07))

	face_mat.albedo_color.a = 0.17 * smooth_k(g, 1.6, 1.95)
	faces_mesh.visible = face_mat.albedo_color.a > 0.004

	var k_mk := ease_pop(smooth_k(g, 3.02, 3.38))
	marker.visible = k_mk > 0.02
	marker.scale = Vector3.ONE * k_mk
	var k_mv := ease_out(smooth_k(g, 5.0, 5.55))
	marker.position = mv(CENTROID_M).lerp(mv(CENTER_M), k_mv)
	qmark_label.position = marker.position + Vector3(0, 0.38, 0)
	qmark_label.modulate.a = k_mk * (1.0 - k_mv)
	olabel.position = marker.position + Vector3(0, 0.46, 0)
	olabel.modulate.a = k_mv

	aux_mat.albedo_color.a = 0.9 * smooth_k(g, 3.1, 3.5)
	for i in dist_segs.size():
		var seg: Node3D = dist_segs[i]
		seg.set_meta("p1", marker.position)
		seg.set_meta("p2", mv(P[ORDER[i]]))
		set_grow(seg, smooth_k(g, 3.14 + i * 0.1, 3.5 + i * 0.1))
		radius_labels[i].position = marker.position.lerp(mv(P[ORDER[i]]), 0.5)
		radius_labels[i].modulate.a = smooth_k(g, 6.35 + i * 0.05, 6.7 + i * 0.05)

	var k_s := ease_out(smooth_k(g, 6.0, 6.75))
	sphere_root.visible = k_s > 0.01
	sphere_root.scale = Vector3.ONE * maxf(k_s, 0.001)
	sphere_fill_mat.albedo_color.a = 0.11 * k_s
	ring_mat.albedo_color.a = k_s

	var k_h := smooth_k(g, 6.3, 6.75)
	set_grow(perp_seg, k_h)
	hpoint.visible = k_h > 0.02
	hpoint.scale = Vector3.ONE * ease_pop(k_h)
	hlabel.modulate.a = k_h
	circ_ring.visible = k_h > 0.01
	circ_ring.scale = Vector3.ONE * maxf(ease_out(k_h), 0.001)
	aux_mat2.albedo_color.a = 0.95 * k_h