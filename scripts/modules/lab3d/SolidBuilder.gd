class_name SolidBuilder
extends Node3D
## 立体几何「真实网格 3D」场景构建器：由 JSON 描述生成 Node3D 网格树。
##
## 坐标约定：数学坐标 (x, y, z) 且 **z 轴竖直向上**（与国内教材一致），
## 内部映射到 Godot 的 y-up：mv(x,y,z) = (x, z, y)。
##
## 支持图元：坐标轴/网格、命名几何体（正方体/长方体/棱柱/棱锥/四面体/圆柱/圆锥/台/球）、
## 顶点、棱（圆柱线段）、面（半透明三角面）、向量箭头、圆、球、平面、直角标记、角弧、文字标注。
## 顶点可用名字互相引用（如 {"p1":"A","p2":"C1"}），便于"建系/连线"类作图。
## 载入时按注册顺序依次"生长"显现；可高亮/脉冲指定元素。
##
## 用法： builder.build(scene_dict, vars_dict)；随后每帧 set_reveal(t)。

const COL_AXIS_X := Color("ff6b6b")
const COL_AXIS_Y := Color("6bd07a")
const COL_AXIS_Z := Color("6b9bff")
const COL_LINE := Color("dfeaff")
const COL_TEXT := Color("e8f0ff")

## 每个元素 {nodes, kind, mats, g0, g1}
var _elems: Array = []
var _verts: Dictionary = {}          # 顶点名 -> Vector3(数学坐标)
var _ids: Dictionary = {}            # id -> Array[Node]
var _hl_meshes: Array = []           # 当前高亮的 MeshInstance3D
var _hl_mat: StandardMaterial3D
var _reveal := 1.0
var _t := 0.0
var _pulse_t := 0.0
var _pulse_dur := 0.0
var _pulse_ids: Array = []
var _scene: Dictionary = {}
var _vars: Dictionary = {}

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	if _pulse_dur > 0.0:
		_pulse_t += delta
		var k := 0.5 + 0.5 * sin(_t * 7.0)
		if _hl_mat != null:
			_hl_mat.emission_energy_multiplier = 0.9 + 1.4 * k
		if _pulse_t >= _pulse_dur:
			_pulse_dur = 0.0
			_hl_mat.emission_energy_multiplier = 1.6

# ================================================================ 构建

func build(scene: Dictionary, vars: Dictionary) -> void:
	_scene = scene if scene != null else {}
	_vars = vars if vars != null else {}
	clear()
	_hl_mat = _mk_hl_mat()

	_build_axes()
	_build_grid()
	_build_solids()
	_build_faces()
	_build_segments()
	_build_points()
	_build_vectors()
	_build_circles()
	_build_spheres()
	_build_planes()
	_build_right_angles()
	_build_arcs()
	_build_labels()

	_finish_timing()
	_apply_highlight()
	set_reveal(_reveal)

func clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_elems.clear()
	_verts.clear()
	_ids.clear()
	_hl_meshes.clear()
	_pulse_dur = 0.0

## 载入动画：0→1 依次显现各元素。
func set_reveal(g: float) -> void:
	_reveal = g
	for e in _elems:
		var k := 0.0
		var g0 := float(e["g0"])
		var g1 := float(e["g1"])
		if g <= g0:
			k = 0.0
		elif g >= g1:
			k = 1.0
		else:
			k = (g - g0) / maxf(g1 - g0, 0.001)
		_apply_elem(e, ease_out(k))

func _finish_timing() -> void:
	var n := _elems.size()
	if n == 0:
		return
	var stagger := minf(0.042, 0.74 / float(n))
	for i in n:
		var e: Dictionary = _elems[i]
		var g0 := 0.02 + float(i) * stagger
		e["g0"] = g0
		e["g1"] = minf(g0 + 0.26, 1.0)

func _apply_elem(e: Dictionary, k: float) -> void:
	var kind := str(e["kind"])
	var nodes: Array = e["nodes"]
	match kind:
		"seg":
			for nd in nodes:
				set_grow(nd, k)
		"pop":
			for nd in nodes:
				var nn := nd as Node3D
				nn.visible = k > 0.02
				nn.scale = Vector3.ONE * maxf(k, 0.001)
		"mesh":
			for nd in nodes:
				if nd is GeometryInstance3D:
					var gi := nd as GeometryInstance3D
					gi.transparency = clampf(1.0 - k, 0.0, 1.0)
					gi.visible = k > 0.01
				elif nd is Node3D:
					(nd as Node3D).visible = k > 0.01
		"label":
			for nd in nodes:
				var lb := nd as Label3D
				lb.modulate.a = k
				lb.outline_modulate.a = k
				lb.visible = k > 0.02

# ================================================================ 材质/图元工具

func mv(v: Vector3) -> Vector3:
	return Vector3(v.x, v.z, v.y)

func _line_mat(color: Color, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 0.55
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.5
	return m

func _face_mat(color: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.5
	m.metallic = 0.0
	return m

func _dot_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 0.7
	return m

func _mk_hl_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#ffd479")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = Color("#ffb347")
	m.emission_energy_multiplier = 1.6
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

## 棱：以圆柱近似线段，带 p1/p2 元数据用于生长动画。
func mk_seg(a: Vector3, b: Vector3, radius: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = maxf(a.distance_to(b), 0.0001)
	cm.radial_segments = 10
	cm.rings = 1
	cm.material = mat
	mi.mesh = cm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	root.set_meta("p1", a)
	root.set_meta("p2", b)
	root.set_meta("dynamic", true)
	root.basis = basis_from(a, b)
	root.position = (a + b) * 0.5
	root.visible = false
	add_child(root)
	return root

func set_grow(seg: Node, k: float) -> void:
	var s := seg as Node3D
	k = clampf(k, 0.0, 1.0)
	if k <= 0.004:
		s.visible = false
		return
	s.visible = true
	var p1: Vector3 = s.get_meta("p1")
	var p2: Vector3 = s.get_meta("p2")
	if bool(s.get_meta("dynamic")):
		s.basis = basis_from(p1, p2)
	s.scale = Vector3(1, k, 1)
	s.position = p1.lerp(p2, k * 0.5)

func mk_ball(pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 20
	sm.rings = 10
	sm.material = mat
	mi.mesh = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	add_child(mi)
	return mi

func mk_label(text: String, pos: Vector3, size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = UI.font()
	l.font_size = size
	l.modulate = Color(color.r, color.g, color.b, 1.0)
	l.pixel_size = 0.0042
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.position = pos
	add_child(l)
	return l

func _mk_face_mesh(pts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, pts.size() - 1):
		var tri := [pts[0], pts[i], pts[i + 1]]
		var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
		for v in tri:
			st.set_normal(n)
			st.add_vertex(v)
	return st.commit()

func _face_node(pts_math: Array, mat: Material) -> MeshInstance3D:
	var pts: Array = []
	for p in pts_math:
		pts.append(mv(p))
	var mi := MeshInstance3D.new()
	mi.mesh = _mk_face_mesh(pts)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func _register(kind: String, nodes: Array) -> Dictionary:
	var e := {"nodes": nodes, "kind": kind, "g0": 0.0, "g1": 1.0}
	_elems.append(e)
	return e

func _reg_id(id: String, nodes: Array) -> void:
	if id == "":
		return
	if not _ids.has(id):
		_ids[id] = []
	for n in nodes:
		(_ids[id] as Array).append(n)

# ================================================================ 坐标轴 / 网格

func _c(v: Variant, dflt: Color) -> Color:
	if v == null:
		return dflt
	if v is Color:
		return v
	return Color(str(v))

func _v(name: Variant, vars: Dictionary) -> Vector3:
	# 支持 "A" 形式的顶点名，或 [x,y,z] 数值/表达式。
	if name is String and _verts.has(name):
		return _verts[name]
	return NumExpr.vec3(name, vars, Vector3.ZERO)

func _build_axes() -> void:
	if not bool(_scene.get("axes", false)):
		return
	var L := NumExpr.num(_scene.get("axis_len", _scene.get("range", 5.0)), _vars, 5.0)
	var defs := [
		[Vector3(1, 0, 0), COL_AXIS_X, "x"],
		[Vector3(0, 1, 0), COL_AXIS_Y, "y"],
		[Vector3(0, 0, 1), COL_AXIS_Z, "z"],
	]
	for d in defs:
		var dir_m: Vector3 = d[0]
		var col: Color = d[1]
		var mat := _line_mat(col)
		var seg := mk_seg(mv(dir_m * -0.0), mv(dir_m * L), 0.02, mat)
		_register("seg", [seg])
		# 箭头
		var tip := mv(dir_m * L)
		var head := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.07
		cm.height = 0.28
		cm.radial_segments = 14
		cm.rings = 1
		cm.material = mat
		head.mesh = cm
		head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		head.basis = basis_from(tip - mv(dir_m) * 0.28, tip)
		head.position = tip - mv(dir_m) * 0.14
		add_child(head)
		_register("mesh", [head])
		var lb := mk_label(str(d[2]), tip + mv(dir_m) * 0.34, 60, col)
		_register("label", [lb])

func _build_grid() -> void:
	if not bool(_scene.get("grid", false)):
		return
	var R := int(round(NumExpr.num(_scene.get("grid_range", _scene.get("range", 3.0)), _vars, 3.0)))
	var col := _c(_scene.get("grid_color"), Color(0.56, 0.7, 0.9, 0.28))
	var mat := _line_mat(Color(col.r, col.g, col.b, 1.0), col.a)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	for i in range(-R, R + 1):
		im.surface_add_vertex(mv(Vector3(i, -R, 0)))
		im.surface_add_vertex(mv(Vector3(i, R, 0)))
		im.surface_add_vertex(mv(Vector3(-R, i, 0)))
		im.surface_add_vertex(mv(Vector3(R, i, 0)))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_register("mesh", [mi])

# ================================================================ 命名几何体

func _build_solids() -> void:
	for s in _as_array(_scene.get("solids", [])):
		if not (s is Dictionary):
			continue
		_build_solid(s)

func _build_solid(s: Dictionary) -> void:
	var kind := str(s.get("kind", "cube"))
	var name := str(s.get("name", kind))
	var col := _c(s.get("color"), Color("#5f9bff"))
	var alpha := float(s.get("alpha", 0.16))
	var labeled := bool(s.get("labels", true))
	var show_edges := bool(s.get("edges", true))
	var centered := bool(s.get("center", false))
	var at := NumExpr.vec3(s.get("at", [0, 0, 0]), _vars, Vector3.ZERO)
	var face_mat := _face_mat(col, alpha)
	var edge_mat := _line_mat(col.lightened(0.35))

	var V: Dictionary = {}     # 名 -> 数学坐标
	var F: Array = []          # 面 -> Array[名]
	var E: Array = []          # 棱 -> [名,名]

	match kind:
		"cube", "cuboid":
			var a := NumExpr.num(s.get("a", s.get("size", 2.0)), _vars, 2.0)
			var b := NumExpr.num(s.get("b", s.get("size", 2.0)), _vars, 2.0)
			var h := NumExpr.num(s.get("h", s.get("c", s.get("size", 2.0))), _vars, 2.0)
			var off := Vector3(a * 0.5, b * 0.5, h * 0.5) if centered else Vector3.ZERO
			V = {
				"A": Vector3(0, 0, 0) - off, "B": Vector3(a, 0, 0) - off,
				"C": Vector3(a, b, 0) - off, "D": Vector3(0, b, 0) - off,
				"A1": Vector3(0, 0, h) - off, "B1": Vector3(a, 0, h) - off,
				"C1": Vector3(a, b, h) - off, "D1": Vector3(0, b, h) - off,
			}
			F = [["A", "B", "C", "D"], ["A1", "B1", "C1", "D1"],
				["A", "B", "B1", "A1"], ["B", "C", "C1", "B1"],
				["C", "D", "D1", "C1"], ["D", "A", "A1", "D1"]]
			E = [["A", "B"], ["B", "C"], ["C", "D"], ["D", "A"],
				["A1", "B1"], ["B1", "C1"], ["C1", "D1"], ["D1", "A1"],
				["A", "A1"], ["B", "B1"], ["C", "C1"], ["D", "D1"]]
		"prism":
			var n := int(NumExpr.num(s.get("n", 4), _vars, 4.0))
			var r := NumExpr.num(s.get("r", 1.6), _vars, 1.6)
			var h2 := NumExpr.num(s.get("h", 2.6), _vars, 2.6)
			var rot := NumExpr.num(s.get("rot", 45.0), _vars, 45.0)
			var names := _poly_names(n)
			for i in n:
				var ang := deg_to_rad(rot + 360.0 * float(i) / float(n))
				V[names[i]] = Vector3(r * cos(ang), r * sin(ang), 0)
				V[names[i] + "1"] = Vector3(r * cos(ang), r * sin(ang), h2)
			F.append(_poly_names(n))
			var top: Array = []
			for i in n:
				top.append(names[i] + "1")
			F.append(top)
			for i in n:
				var j := (i + 1) % n
				F.append([names[i], names[j], names[j] + "1", names[i] + "1"])
				E.append([names[i], names[j]])
				E.append([names[i] + "1", names[j] + "1"])
				E.append([names[i], names[i] + "1"])
		"pyramid":
			var n2 := int(NumExpr.num(s.get("n", 4), _vars, 4.0))
			var r2 := NumExpr.num(s.get("r", 1.8), _vars, 1.8)
			var h3 := NumExpr.num(s.get("h", 3.0), _vars, 3.0)
			var rot2 := NumExpr.num(s.get("rot", 45.0), _vars, 45.0)
			var apex := str(s.get("apex", "P"))
			var nm := _poly_names(n2)
			for i in n2:
				var ang2 := deg_to_rad(rot2 + 360.0 * float(i) / float(n2))
				V[nm[i]] = Vector3(r2 * cos(ang2), r2 * sin(ang2), 0)
			V[apex] = Vector3(NumExpr.num(s.get("apx", 0.0), _vars, 0.0), NumExpr.num(s.get("apy", 0.0), _vars, 0.0), h3)
			F.append(nm.duplicate())
			for i in n2:
				var j2 := (i + 1) % n2
				F.append([nm[i], nm[j2], apex])
				E.append([nm[i], nm[j2]])
				E.append([nm[i], apex])
		"tetra":
			var a4 := NumExpr.num(s.get("a", 2.6), _vars, 2.6)
			var rr := a4 / sqrt(3.0)
			V = {
				"A": Vector3(rr * cos(deg_to_rad(-90)), rr * sin(deg_to_rad(-90)), 0),
				"B": Vector3(rr * cos(deg_to_rad(30)), rr * sin(deg_to_rad(30)), 0),
				"C": Vector3(rr * cos(deg_to_rad(150)), rr * sin(deg_to_rad(150)), 0),
				"P": Vector3(0, 0, a4 * sqrt(2.0 / 3.0)),
			}
			F = [["A", "B", "C"], ["A", "B", "P"], ["B", "C", "P"], ["C", "A", "P"]]
			E = [["A", "B"], ["B", "C"], ["C", "A"], ["A", "P"], ["B", "P"], ["C", "P"]]
		"cylinder":
			var rc := NumExpr.num(s.get("r", 1.2), _vars, 1.2)
			var hc := NumExpr.num(s.get("h", 3.0), _vars, 3.0)
			_mk_cylinder(at, rc, hc, face_mat, edge_mat, show_edges)
			V = {"O": Vector3.ZERO, "O1": Vector3(0, 0, hc)}
		"cone":
			var rx := NumExpr.num(s.get("r", 1.4), _vars, 1.4)
			var hx := NumExpr.num(s.get("h", 3.0), _vars, 3.0)
			_mk_cone(at, rx, hx, face_mat, edge_mat, show_edges)
			V = {"O": Vector3.ZERO, "P": Vector3(0, 0, hx)}
		"frustum":
			var r1 := NumExpr.num(s.get("r1", 1.6), _vars, 1.6)
			var r2 := NumExpr.num(s.get("r2", 0.8), _vars, 0.8)
			var hf := NumExpr.num(s.get("h", 2.6), _vars, 2.6)
			if bool(s.get("round", false)):
				_mk_frustum_round(at, r1, r2, hf, face_mat, edge_mat, show_edges)
			else:
				var nf := int(NumExpr.num(s.get("n", 4), _vars, 4.0))
				var rotf := NumExpr.num(s.get("rot", 45.0), _vars, 45.0)
				var nmf := _poly_names(nf)
				for i in nf:
					var angf := deg_to_rad(rotf + 360.0 * float(i) / float(nf))
					V[nmf[i]] = Vector3(r1 * cos(angf), r1 * sin(angf), 0)
					V[nmf[i] + "1"] = Vector3(r2 * cos(angf), r2 * sin(angf), hf)
				F.append(nmf.duplicate())
				var t2: Array = []
				for i in nf:
					t2.append(nmf[i] + "1")
				F.append(t2)
				for i in nf:
					var jf := (i + 1) % nf
					F.append([nmf[i], nmf[jf], nmf[jf] + "1", nmf[i] + "1"])
					E.append([nmf[i], nmf[jf]])
					E.append([nmf[i] + "1", nmf[jf] + "1"])
					E.append([nmf[i], nmf[i] + "1"])
		"sphere":
			var rs := NumExpr.num(s.get("r", 1.6), _vars, 1.6)
			_mk_sphere_solid(at, rs, face_mat, show_edges)
			V = {"O": Vector3.ZERO}
		_:
			pass

	# 整体平移（多体并排展示用）
	if at != Vector3.ZERO:
		for k in V.keys():
			V[k] = V[k] + at

	# 注册顶点名
	for k in V.keys():
		if not _verts.has(k):
			_verts[k] = V[k]

	# 面
	for f in F:
		var pts: Array = []
		for nm2 in f:
			if V.has(nm2):
				pts.append(V[nm2])
		if pts.size() >= 3:
			var node := _face_node(pts, face_mat)
			_register("mesh", [node])
			_reg_id(name, [node])

	# 棱
	for ed in E:
		if not (V.has(ed[0]) and V.has(ed[1])):
			continue
		var seg := mk_seg(mv(V[ed[0]]), mv(V[ed[1]]), 0.022, edge_mat)
		_register("seg", [seg])
		_reg_id(name + "." + str(ed[0]) + str(ed[1]), [seg])
		_reg_id(name, [seg])

	# 顶点与标注
	if labeled and not V.is_empty():
		for k2 in V.keys():
			if k2.begins_with("__"):
				continue
			var ball := mk_ball(mv(V[k2]), 0.075, _dot_mat(col.lightened(0.5)))
			_register("pop", [ball])
			_reg_id(name + "." + str(k2), [ball])
			_reg_id(name, [ball])
			var lb := mk_label(_pretty_label(k2), mv(V[k2]) + Vector3(0, 0.26, 0), 46, Color(col.lightened(0.4)))
			lb.modulate.a = 0.0
			_register("label", [lb])
			_reg_id(name + "." + str(k2), [lb])

func _pretty_label(k: String) -> String:
	if k.length() >= 2 and k.ends_with("1"):
		return k.substr(0, k.length() - 1) + "₁"
	return k

func _poly_names(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(String.chr(65 + (i % 26)))
	return out

func _mk_cylinder(base: Vector3, r: float, h: float, fmat: Material, emat: Material, edges: bool) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 40
	cm.rings = 1
	cm.material = fmat
	mi.mesh = cm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = mv(base + Vector3(0, 0, h * 0.5))
	add_child(mi)
	_register("mesh", [mi])
	if edges:
		for ang in [0.0, 90.0]:
			var p0 := base + Vector3(r * cos(deg_to_rad(ang)), r * sin(deg_to_rad(ang)), 0)
			var p1 := p0 + Vector3(0, 0, h)
			var s := mk_seg(mv(p0), mv(p1), 0.012, emat)
			_register("seg", [s])

func _mk_cone(base: Vector3, r: float, h: float, fmat: Material, emat: Material, edges: bool) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 40
	cm.rings = 1
	cm.material = fmat
	mi.mesh = cm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = mv(base + Vector3(0, 0, h * 0.5))
	add_child(mi)
	_register("mesh", [mi])
	if edges:
		for ang2 in [0.0, 120.0, 240.0]:
			var p0 := base + Vector3(r * cos(deg_to_rad(ang2)), r * sin(deg_to_rad(ang2)), 0)
			var s := mk_seg(mv(p0), mv(base + Vector3(0, 0, h)), 0.012, emat)
			_register("seg", [s])

func _mk_frustum_round(center: Vector3, r1: float, r2: float, h: float, fmat: Material, emat: Material, edges: bool) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r2
	cm.bottom_radius = r1
	cm.height = h
	cm.radial_segments = 40
	cm.rings = 1
	cm.material = fmat
	mi.mesh = cm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = mv(center + Vector3(0, 0, h * 0.5))
	add_child(mi)
	_register("mesh", [mi])
	if edges:
		for ang in [0.0, 120.0, 240.0]:
			var p0 := center + Vector3(r1 * cos(deg_to_rad(ang)), r1 * sin(deg_to_rad(ang)), 0)
			var p1 := center + Vector3(r2 * cos(deg_to_rad(ang)), r2 * sin(deg_to_rad(ang)), h)
			var s := mk_seg(mv(p0), mv(p1), 0.012, emat)
			_register("seg", [s])

func _mk_sphere_solid(center: Vector3, r: float, fmat: Material, wire: bool) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 40
	sm.rings = 20
	sm.material = fmat
	mi.mesh = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = mv(center)
	add_child(mi)
	_register("mesh", [mi])
	if wire:
		_build_sphere_wire(center, r)

func _build_sphere_wire(center: Vector3, r: float) -> void:
	var root := Node3D.new()
	root.position = mv(center)
	add_child(root)
	var mat := _line_mat(Color("8fe4ff"))
	for h in [-0.6, -0.3, 0.0, 0.3, 0.6]:
		var hh: float = float(h) * r
		var rr := sqrt(maxf(r * r - hh * hh, 1e-6))
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = maxf(rr - 0.012, 0.01)
		tm.outer_radius = rr + 0.012
		tm.rings = 64
		tm.ring_segments = 6
		tm.material = mat
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.position = Vector3(0, hh, 0)
		root.add_child(tor)
	_register("mesh", [root])

# ================================================================ 显式图元

func _as_array(v: Variant) -> Array:
	return v if v is Array else []

func _build_faces() -> void:
	for f in _as_array(_scene.get("faces", [])):
		if not (f is Dictionary):
			continue
		var pts: Array = []
		for p in _as_array(f.get("points", [])):
			pts.append(_v(p, _vars))
		if pts.size() < 3:
			continue
		var col := _c(f.get("color"), Color("#5f9bff"))
		var node := _face_node(pts, _face_mat(col, float(f.get("alpha", 0.18))))
		_register("mesh", [node])
		_reg_id(str(f.get("id", "")), [node])

func _build_segments() -> void:
	for sg in _as_array(_scene.get("segments", [])):
		if not (sg is Dictionary):
			continue
		var a := _v(sg.get("p1", sg.get("from", [0, 0, 0])), _vars)
		var b := _v(sg.get("p2", sg.get("to", [0, 0, 1])), _vars)
		var col := _c(sg.get("color"), COL_LINE)
		var w := float(sg.get("width", 0.024))
		if bool(sg.get("thin", false)):
			w = 0.012
		var mat := _line_mat(col, float(sg.get("alpha", 1.0)))
		var seg := mk_seg(mv(a), mv(b), w, mat)
		_register("seg", [seg])
		_reg_id(str(sg.get("id", "")), [seg])
		if sg.has("label"):
			var lb := mk_label(str(sg["label"]), mv(a.lerp(b, 0.5)) + Vector3(0, 0.22, 0), 42, col)
			_register("label", [lb])

func _build_points() -> void:
	for p in _as_array(_scene.get("points", [])):
		if not (p is Dictionary):
			continue
		var pos := _v(p.get("p", p.get("at", [0, 0, 0])), _vars)
		var col := _c(p.get("color"), Color("#ffd479"))
		var ball := mk_ball(mv(pos), float(p.get("size", 0.085)), _dot_mat(col))
		_register("pop", [ball])
		_reg_id(str(p.get("id", "")), [ball])
		if p.has("label"):
			var lb := mk_label(str(p["label"]), mv(pos) + Vector3(0, 0.26, 0), 46, col)
			lb.modulate.a = 0.0
			_register("label", [lb])

func _build_vectors() -> void:
	for vv in _as_array(_scene.get("vectors", [])):
		if not (vv is Dictionary):
			continue
		var a := _v(vv.get("from", vv.get("p1", [0, 0, 0])), _vars)
		var b := _v(vv.get("to", vv.get("p2", [1, 0, 0])), _vars)
		var col := _c(vv.get("color"), Color("#5ee6ff"))
		var mat := _line_mat(col)
		var dir := b - a
		var l := dir.length()
		if l < 1e-4:
			continue
		var d := dir / l
		var head_len := minf(0.34, l * 0.4)
		var body_end := b - d * head_len
		var seg := mk_seg(mv(a), mv(body_end), float(vv.get("width", 0.028)), mat)
		_register("seg", [seg])
		var head := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.085
		cm.height = head_len
		cm.radial_segments = 16
		cm.rings = 1
		cm.material = mat
		head.mesh = cm
		head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		head.basis = basis_from(mv(body_end), mv(b))
		head.position = mv(a.lerp(b, 0.5)) if false else mv(b - d * head_len * 0.5)
		add_child(head)
		_register("mesh", [head])
		_reg_id(str(vv.get("id", "")), [seg, head])
		if vv.has("label"):
			var lb := mk_label(str(vv["label"]), mv(b) + Vector3(0.12, 0.24, 0), 46, col)
			lb.modulate.a = 0.0
			_register("label", [lb])

func _build_circles() -> void:
	for ci in _as_array(_scene.get("circles", [])):
		if not (ci is Dictionary):
			continue
		var center := _v(ci.get("c", ci.get("center", [0, 0, 0])), _vars)
		var r := NumExpr.num(ci.get("r", 1.0), _vars, 1.0)
		var col := _c(ci.get("color"), Color("8fe4ff"))
		var normal := NumExpr.vec3(ci.get("normal", [0, 0, 1]), _vars, Vector3.UP)
		if normal.length() < 1e-5:
			normal = Vector3.UP
		normal = normal.normalized()
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = maxf(r - 0.014, 0.01)
		tm.outer_radius = r + 0.014
		tm.rings = 72
		tm.ring_segments = 6
		tm.material = _line_mat(col)
		tor.mesh = tm
		tor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tor.position = mv(center)
		# 圆环默认在 xz 平面（法向 y），需转到目标法向。
		var nb := Vector3(normal.x, normal.z, normal.y)
		tor.basis = Basis(Quaternion(Vector3.UP, nb))
		add_child(tor)
		_register("mesh", [tor])
		_reg_id(str(ci.get("id", "")), [tor])
		if ci.has("label"):
			var lb := mk_label(str(ci["label"]), mv(center) + Vector3(0, r + 0.3, 0), 42, col)
			lb.modulate.a = 0.0
			_register("label", [lb])

func _build_spheres() -> void:
	for sp in _as_array(_scene.get("spheres", [])):
		if not (sp is Dictionary):
			continue
		var center := _v(sp.get("c", sp.get("center", [0, 0, 0])), _vars)
		var r := NumExpr.num(sp.get("r", 1.0), _vars, 1.0)
		var col := _c(sp.get("color"), Color("57c8ff"))
		var alpha := float(sp.get("alpha", 0.12))
		_mk_sphere_solid(center, r, _face_mat(col, alpha), bool(sp.get("wire", true)))
		_reg_id(str(sp.get("id", "")), [])
		if sp.has("label"):
			var lb := mk_label(str(sp["label"]), mv(center) + Vector3(0, r + 0.34, 0), 42, col)
			lb.modulate.a = 0.0
			_register("label", [lb])

func _build_planes() -> void:
	for pl in _as_array(_scene.get("planes", [])):
		if not (pl is Dictionary):
			continue
		var at := _v(pl.get("at", [0, 0, 0]), _vars)
		var normal := NumExpr.vec3(pl.get("normal", [0, 0, 1]), _vars, Vector3.UP)
		if normal.length() < 1e-5:
			normal = Vector3.UP
		normal = normal.normalized()
		var s := NumExpr.num(pl.get("size", 3.0), _vars, 3.0) * 0.5
		var col := _c(pl.get("color"), Color("#7fd8ff"))
		# 由法向构造平面内正交基
		var up := Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var u := up.cross(normal).normalized()
		var w := normal.cross(u).normalized()
		var pts := [
			at - u * s - w * s, at + u * s - w * s,
			at + u * s + w * s, at - u * s + w * s,
		]
		var node := _face_node(pts, _face_mat(col, float(pl.get("alpha", 0.14))))
		_register("mesh", [node])
		_reg_id(str(pl.get("id", "")), [node])
		if pl.has("label"):
			var lb := mk_label(str(pl["label"]), mv(at + normal * 0.1) + Vector3(0, 0.3, 0), 42, col)
			lb.modulate.a = 0.0
			_register("label", [lb])

func _build_right_angles() -> void:
	for ra in _as_array(_scene.get("right_angles", [])):
		if not (ra is Dictionary):
			continue
		var at := _v(ra.get("at", [0, 0, 0]), _vars)
		var va := _v(ra.get("a", [1, 0, 0]), _vars) - at
		var vb := _v(ra.get("b", [0, 0, 1]), _vars) - at
		if va.length() < 1e-5 or vb.length() < 1e-5:
			continue
		va = va.normalized()
		vb = vb.normalized()
		var sz := NumExpr.num(ra.get("size", 0.4), _vars, 0.4)
		var col := _c(ra.get("color"), Color("ffd479"))
		var p0 := at + va * sz
		var p1 := at + (va + vb) * sz
		var p2 := at + vb * sz
		for pair in [[p0, p1], [p1, p2]]:
			var seg := mk_seg(mv(pair[0]), mv(pair[1]), 0.012, _line_mat(col))
			_register("seg", [seg])

func _build_arcs() -> void:
	for ar in _as_array(_scene.get("arcs", [])):
		if not (ar is Dictionary):
			continue
		var at := _v(ar.get("at", [0, 0, 0]), _vars)
		var va := _v(ar.get("a", [1, 0, 0]), _vars) - at
		var vb := _v(ar.get("b", [0, 1, 0]), _vars) - at
		if va.length() < 1e-5 or vb.length() < 1e-5:
			continue
		var r := NumExpr.num(ar.get("r", 0.7), _vars, 0.7)
		var col := _c(ar.get("color"), Color("5ee6ff"))
		var mat := _line_mat(col)
		var n := 24
		var prev := at + va.normalized() * r
		for i in range(1, n + 1):
			var t := float(i) / float(n)
			var dir := va.normalized().slerp(vb.normalized(), t)
			var cur := at + dir * r
			var seg := mk_seg(mv(prev), mv(cur), 0.01, mat)
			_register("seg", [seg])
			prev = cur
		if ar.has("label"):
			var mid := va.normalized().slerp(vb.normalized(), 0.5)
			var lb := mk_label(str(ar["label"]), mv(at + mid * (r + 0.35)), 40, col)
			lb.modulate.a = 0.0
			_register("label", [lb])

func _build_labels() -> void:
	for lb in _as_array(_scene.get("labels", [])):
		if not (lb is Dictionary):
			continue
		var pos := _v(lb.get("p", lb.get("at", [0, 0, 0])), _vars)
		var col := _c(lb.get("color"), COL_TEXT)
		var l := mk_label(str(lb.get("text", "")), mv(pos), int(lb.get("size", 46)), col)
		_register("label", [l])

# ================================================================ 高亮

func _collect_meshes(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		out.append(node)
	if node is GeometryInstance3D and not (node is MeshInstance3D):
		out.append(node)
	for c in node.get_children():
		_collect_meshes(c, out)

func set_highlight(ids: Array) -> void:
	clear_highlight()
	for id in ids:
		if _ids.has(str(id)):
			for n in (_ids[str(id)] as Array):
				_collect_meshes(n, _hl_meshes)
	for mi in _hl_meshes:
		if mi is MeshInstance3D:
			(mi as MeshInstance3D).material_override = _hl_mat

func clear_highlight() -> void:
	for mi in _hl_meshes:
		if is_instance_valid(mi) and mi is MeshInstance3D:
			(mi as MeshInstance3D).material_override = null
	_hl_meshes.clear()

func _apply_highlight() -> void:
	var ids: Array = _as_array(_scene.get("highlight", []))
	if not ids.is_empty():
		set_highlight(ids)

func pulse(ids: Array, dur: float) -> void:
	if _hl_mat == null:
		return
	set_highlight(ids if not ids.is_empty() else _as_array(_scene.get("highlight", [])))
	_pulse_t = 0.0
	_pulse_dur = dur

## 世界包围盒（用于相机自动取景）。
func bounds() -> AABB:
	var box := AABB()
	var init := false
	for c in get_children():
		var b := _node_aabb(c)
		if b.size == Vector3.ZERO:
			continue
		if not init:
			box = b
			init = true
		else:
			box = box.merge(b)
	return box

func _node_aabb(node: Node) -> AABB:
	if node is MeshInstance3D:
		var gi := node as MeshInstance3D
		if gi.mesh != null:
			return gi.global_transform * gi.mesh.get_aabb()
	return AABB()

static func ease_out(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)
