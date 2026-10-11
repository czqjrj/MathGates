class_name TopicBase
extends Node3D

var ui_font: Font
var labels := []
var grid_mat: StandardMaterial3D
var axis_root: Node3D
var axis_mats := []
var axis_labels := []


func mv(v: Vector3) -> Vector3:
	return Vector3(v.x, v.z, v.y)


func mk_mat(color: Color, alpha := 1.0, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.roughness = 0.55
	m.metallic = 0.0
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func fade_mat(color: Color, alpha: float, unshaded := true) -> StandardMaterial3D:
	var m := mk_mat(color, alpha, unshaded)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func basis_from(a: Vector3, b: Vector3) -> Basis:
	var d := b - a
	var l := d.length()
	if l < 0.00001:
		return Basis.IDENTITY
	var dir := d / l
	var dv := Vector3.UP.dot(dir)
	if absf(dv) > 0.9999:
		return Basis.IDENTITY if dv > 0.0 else Basis(Vector3.RIGHT, PI)
	return Basis(Quaternion(Vector3.UP, dir))


func mk_seg(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, dynamic := false) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = maxf(a.distance_to(b), 0.0001)
	cm.radial_segments = 12
	cm.rings = 1
	cm.material = mat
	mi.mesh = cm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	root.set_meta("p1", a)
	root.set_meta("p2", b)
	root.set_meta("dynamic", dynamic)
	root.basis = basis_from(a, b)
	root.position = (a + b) * 0.5
	root.visible = false
	parent.add_child(root)
	return root


func set_grow(seg: Node3D, k: float) -> void:
	k = clampf(k, 0.0, 1.0)
	if k <= 0.004:
		seg.visible = false
		return
	seg.visible = true
	var p1: Vector3 = seg.get_meta("p1")
	var p2: Vector3 = seg.get_meta("p2")
	if seg.get_meta("dynamic"):
		seg.basis = basis_from(p1, p2)
	seg.scale = Vector3(1, k, 1)
	seg.position = p1.lerp(p2, k * 0.5)


func mk_label(text: String, pos: Vector3, size: int, color: Color, outline := 10) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = ui_font
	l.font_size = size
	l.modulate = color
	l.pixel_size = 0.005
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = outline
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.position = pos
	add_child(l)
	labels.append(l)
	return l


func mk_ball(pos: Vector3, radius: float, mat: Material) -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	sm.material = mat
	mi.mesh = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	n.position = pos
	n.visible = false
	add_child(n)
	return n


func reveal_segs(segs: Array, k: float) -> void:
	var shown := clampf(k, 0.0, 1.0) * segs.size()
	for i in segs.size():
		set_grow(segs[i], clampf(shown - float(i), 0.0, 1.0))


func build_axes(axis_len: float) -> void:
	axis_root = Node3D.new()
	add_child(axis_root)
	var defs := [
		[Vector3(1, 0, 0), Color("ff6b6b"), "x"],
		[Vector3(0, 1, 0), Color("6bd07a"), "y"],
		[Vector3(0, 0, 1), Color("6b9bff"), "z"],
	]
	for d in defs:
		var dir_m: Vector3 = d[0]
		var col: Color = d[1]
		var am := fade_mat(col, 1.0)
		axis_mats.append(am)
		var seg := mk_seg(axis_root, mv(dir_m * -0.8), mv(dir_m * axis_len), 0.022, am)
		seg.visible = true
		var tip := mv(dir_m * axis_len)
		var head := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.085
		cm.height = 0.34
		cm.radial_segments = 16
		cm.rings = 1
		cm.material = am
		head.mesh = cm
		head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		head.basis = basis_from(tip - mv(dir_m) * 0.34, tip)
		head.position = tip - mv(dir_m) * 0.17
		axis_root.add_child(head)
		axis_labels.append(mk_label(d[2], tip + mv(dir_m) * 0.44, 78, col, 12))


func build_grid(x0: int, x1: int, y0: int, y1: int) -> void:
	grid_mat = fade_mat(Color("8fb4e8"), 0.45)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, grid_mat)
	for i in range(x0, x1 + 1):
		im.surface_add_vertex(mv(Vector3(i, y0, 0)))
		im.surface_add_vertex(mv(Vector3(i, y1, 0)))
	for j in range(y0, y1 + 1):
		im.surface_add_vertex(mv(Vector3(x0, j, 0)))
		im.surface_add_vertex(mv(Vector3(x1, j, 0)))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func smooth_k(x: float, a: float, b: float) -> float:
	return clampf((x - a) / (b - a), 0.0, 1.0)


func ease_pop(x: float) -> float:
	if x <= 0.0:
		return 0.0
	if x >= 1.0:
		return 1.0
	var c := 1.70158
	var u := x - 1.0
	return 1.0 + (c + 1.0) * u * u * u + c * u * u


func ease_out(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)


func build() -> void:
	pass


func apply(_g: float) -> void:
	pass