class_name WorldBuilder
extends RefCounted
## Turns MapData's ASCII layout into a lit 3D diorama: block terrain with textured cliff
## faces, a pixel-art river, timber houses, billboarded foliage and collision.

const PX := 1.0 / 16.0
const WALL_HEIGHT := 2.2
const ROOF_RISE := 1.3
const ROOF_OVERHANG := 0.35
const WATER_LEVEL := -0.14
## The ground plane around the map sits below the river so it never covers the water.
const SKIRT_LEVEL := -0.4
const ROOFS := ["roof_red", "roof_blue", "roof_green", "roof_brown"]

static var _billboard_shader: Shader = preload("res://shaders/billboard_sway.gdshader")
static var _water_shader: Shader = preload("res://shaders/water.gdshader")
static var _billboard_materials := {}

var rng := RandomNumberGenerator.new()
var root: Node3D
var lamps: Array[OmniLight3D] = []
var chests := {}
var signs := {}
var _surfaces := {}


func build(parent: Node3D) -> void:
	rng.seed = 20240917
	root = Node3D.new()
	root.name = "World"
	parent.add_child(root)
	_build_terrain()
	_build_water()
	_build_skirt()
	_build_collision()
	_build_houses()
	_build_props()
	_build_foliage()
	_build_outer_forest()


# --------------------------------------------------------------------------
# Billboards
# --------------------------------------------------------------------------

static func billboard_material(tex: Texture2D, sway: float = 0.0, emission: float = 0.0) -> ShaderMaterial:
	var key := "%d_%.3f_%.2f" % [tex.get_rid().get_id(), sway, emission]
	if _billboard_materials.has(key):
		return _billboard_materials[key]
	var mat := ShaderMaterial.new()
	mat.shader = _billboard_shader
	mat.set_shader_parameter("sprite_texture", tex)
	mat.set_shader_parameter("sway_strength", sway)
	mat.set_shader_parameter("emission_strength", emission)
	_billboard_materials[key] = mat
	return mat


static func billboard_mesh(tex: Texture2D) -> QuadMesh:
	var quad := QuadMesh.new()
	var size := Vector2(tex.get_width(), tex.get_height()) * PX
	quad.size = size
	quad.center_offset = Vector3(0, size.y * 0.5, 0)
	return quad


static func make_billboard(tex: Texture2D, sway: float = 0.0, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = billboard_mesh(tex)
	mi.material_override = billboard_material(tex, sway, emission)
	return mi


func _add_billboard(tex: Texture2D, pos: Vector3, scale: float = 1.0, sway: float = 0.0,
		emission: float = 0.0, shadows: bool = true) -> MeshInstance3D:
	var mi := make_billboard(tex, sway, emission)
	mi.position = pos
	mi.scale = Vector3.ONE * scale
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return mi


# --------------------------------------------------------------------------
# Terrain
# --------------------------------------------------------------------------

func _st(material_name: String) -> SurfaceTool:
	if not _surfaces.has(material_name):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_surfaces[material_name] = st
	return _surfaces[material_name]


## Adds a quad, fixing the winding so the face points along `normal`.
static func add_quad(st: SurfaceTool, verts: Array, uvs: Array, normal: Vector3) -> void:
	var a: Vector3 = verts[0]
	var b: Vector3 = verts[1]
	var c: Vector3 = verts[2]
	var order := [0, 1, 2, 0, 2, 3]
	# Godot treats clockwise triangles as front faces.
	if (b - a).cross(c - a).dot(normal) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for i in order:
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])


func _top_material(c: String, x: int, y: int) -> String:
	match c:
		"^", "#": return "cliff_top"
		",": return "tall_grass"
		"=", "d", "@": return "dirt"
		"s", "L", "W", "h": return "stone"
		"b": return "wood"
	var n := sin(x * 0.35 + 1.3) + cos(y * 0.42) + sin((x + y) * 0.17)
	return "grass_dark" if n > 1.1 else "grass"


func _build_terrain() -> void:
	var w := MapData.width()
	var d := MapData.depth()
	for y in d:
		for x in w:
			var c := MapData.cell(x, y)
			var h := MapData.height_of(c)
			if c != "~":
				var mat := _top_material(c, x, y)
				var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
				if mat in ["grass", "grass_dark", "tall_grass", "cliff_top", "dirt"]:
					# Rotate/flip UVs per tile to hide repetition.
					var r := rng.randi_range(0, 3)
					for i in r:
						uvs.push_front(uvs.pop_back())
				add_quad(_st(mat), [
					Vector3(x, h, y), Vector3(x + 1, h, y), Vector3(x + 1, h, y + 1), Vector3(x, h, y + 1)
				], uvs, Vector3.UP)
			_build_sides(x, y, c, h)
	var mesh := ArrayMesh.new()
	for mat_name in _surfaces:
		var st: SurfaceTool = _surfaces[mat_name]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, TextureFactory.get_material(mat_name))
	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = mesh
	root.add_child(mi)


func _build_sides(x: int, y: int, c: String, h: float) -> void:
	var dirs := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for dir in dirs:
		var nx: int = x + dir.x
		var ny: int = y + dir.y
		var hn := SKIRT_LEVEL
		if nx >= 0 and ny >= 0 and nx < MapData.width() and ny < MapData.depth():
			hn = MapData.height_of(MapData.cell(nx, ny))
		if hn >= h:
			continue
		var normal := Vector3(dir.x, 0, dir.y)
		# Edge endpoints on the face shared with the neighbour.
		var p0: Vector3
		var p1: Vector3
		if dir.y == -1:
			p0 = Vector3(x, 0, y)
			p1 = Vector3(x + 1, 0, y)
		elif dir.y == 1:
			p0 = Vector3(x, 0, y + 1)
			p1 = Vector3(x + 1, 0, y + 1)
		elif dir.x == -1:
			p0 = Vector3(x, 0, y)
			p1 = Vector3(x, 0, y + 1)
		else:
			p0 = Vector3(x + 1, 0, y)
			p1 = Vector3(x + 1, 0, y + 1)
		var is_cliff := c == "^" or c == "#"
		var top := h
		var first := true
		while top > hn + 0.001:
			var bottom: float = max(top - 1.0, hn)
			var mat: String
			if c == "b":
				mat = "wood"
			elif is_cliff:
				mat = "cliff_side_top" if first else "cliff_side"
			else:
				mat = "ground_side"
			var v1 := top - bottom
			add_quad(_st(mat), [
				p0 + Vector3(0, top, 0), p1 + Vector3(0, top, 0),
				p1 + Vector3(0, bottom, 0), p0 + Vector3(0, bottom, 0)
			], [Vector2(0, 0), Vector2(1, 0), Vector2(1, v1), Vector2(0, v1)], normal)
			top = bottom
			first = false


func _build_water() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 0
	for y in MapData.depth():
		for x in MapData.width():
			var c := MapData.cell(x, y)
			if c != "~" and c != "b":
				continue
			add_quad(st, [
				Vector3(x, WATER_LEVEL, y), Vector3(x + 1, WATER_LEVEL, y),
				Vector3(x + 1, WATER_LEVEL, y + 1), Vector3(x, WATER_LEVEL, y + 1)
			], [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)], Vector3.UP)
			count += 1
	if count == 0:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _water_shader
	var mi := MeshInstance3D.new()
	mi.name = "River"
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


## A large ground plane around the map so the edges of the diorama never show the void.
func _build_skirt() -> void:
	var size := 140.0
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var mat := TextureFactory.get_material("grass_dark").duplicate() as StandardMaterial3D
	mat.uv1_scale = Vector3(size, size, 1)
	var mi := MeshInstance3D.new()
	mi.name = "Skirt"
	mi.mesh = plane
	mi.material_override = mat
	mi.position = Vector3(MapData.width() * 0.5, SKIRT_LEVEL, MapData.depth() * 0.5)
	root.add_child(mi)


# --------------------------------------------------------------------------
# Collision
# --------------------------------------------------------------------------

func _is_blocked(x: int, y: int) -> bool:
	var c := MapData.cell(x, y)
	if MapData.SOLID.contains(c) or c == "C":
		return true
	for s in MapData.SIGNS:
		if s.cell == Vector2i(x, y):
			return true
	return false


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "WorldCollision"
	root.add_child(body)
	# Merge horizontal runs of blocked cells into single boxes.
	for y in MapData.depth():
		var x := 0
		while x < MapData.width():
			if not _is_blocked(x, y):
				x += 1
				continue
			var start := x
			while x < MapData.width() and _is_blocked(x, y):
				x += 1
			var shape := BoxShape3D.new()
			shape.size = Vector3(x - start, 4.0, 1.0)
			var cs := CollisionShape3D.new()
			cs.shape = shape
			cs.position = Vector3(start + (x - start) * 0.5, 1.0, y + 0.5)
			body.add_child(cs)
	# Outer bounds, just in case.
	var w := float(MapData.width())
	var d := float(MapData.depth())
	for b in [[Vector3(w * 0.5, 1, -0.5), Vector3(w, 4, 1)], [Vector3(w * 0.5, 1, d + 0.5), Vector3(w, 4, 1)],
			[Vector3(-0.5, 1, d * 0.5), Vector3(1, 4, d)], [Vector3(w + 0.5, 1, d * 0.5), Vector3(1, 4, d)]]:
		var shape := BoxShape3D.new()
		shape.size = b[1]
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.position = b[0]
		body.add_child(cs)


# --------------------------------------------------------------------------
# Houses
# --------------------------------------------------------------------------

func _find_houses() -> Array:
	var seen := {}
	var houses := []
	for y in MapData.depth():
		for x in MapData.width():
			if MapData.cell(x, y) != "h" or seen.has(Vector2i(x, y)):
				continue
			var x1 := x
			while MapData.cell(x1 + 1, y) == "h":
				x1 += 1
			var y1 := y
			while MapData.cell(x, y1 + 1) == "h":
				y1 += 1
			for yy in range(y, y1 + 1):
				for xx in range(x, x1 + 1):
					seen[Vector2i(xx, yy)] = true
			var door_x := -1
			for xx in range(x, x1 + 1):
				if MapData.cell(xx, y1 + 1) == "d":
					door_x = xx
			houses.append({"x0": x, "y0": y, "x1": x1, "y1": y1, "door": door_x})
	return houses


func _build_houses() -> void:
	var houses := _find_houses()
	for i in houses.size():
		_build_house(houses[i], ROOFS[i % ROOFS.size()], i)


func _build_house(house: Dictionary, roof_kind: String, index: int) -> void:
	var x0 := float(house.x0)
	var z0 := float(house.y0)
	var x1 := float(house.x1 + 1)
	var z1 := float(house.y1 + 1)
	var h := WALL_HEIGHT
	var walls := SurfaceTool.new()
	walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof := SurfaceTool.new()
	roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wlen := x1 - x0
	var dlen := z1 - z0
	# South (front) and north walls.
	add_quad(walls, [Vector3(x0, h, z1), Vector3(x1, h, z1), Vector3(x1, 0, z1), Vector3(x0, 0, z1)],
		[Vector2(0, 0), Vector2(wlen, 0), Vector2(wlen, h), Vector2(0, h)], Vector3.BACK)
	add_quad(walls, [Vector3(x1, h, z0), Vector3(x0, h, z0), Vector3(x0, 0, z0), Vector3(x1, 0, z0)],
		[Vector2(0, 0), Vector2(wlen, 0), Vector2(wlen, h), Vector2(0, h)], Vector3.FORWARD)
	# East / west walls with gables.
	var zc := (z0 + z1) * 0.5
	for side in [[x0, Vector3.LEFT], [x1, Vector3.RIGHT]]:
		var sx: float = side[0]
		var n: Vector3 = side[1]
		add_quad(walls, [Vector3(sx, h, z0), Vector3(sx, h, z1), Vector3(sx, 0, z1), Vector3(sx, 0, z0)],
			[Vector2(0, 0), Vector2(dlen, 0), Vector2(dlen, h), Vector2(0, h)], n)
		# Gable triangle (degenerate quad).
		add_quad(walls, [Vector3(sx, h, z0), Vector3(sx, h + ROOF_RISE, zc), Vector3(sx, h + ROOF_RISE, zc),
			Vector3(sx, h, z1)], [Vector2(0, ROOF_RISE), Vector2(dlen * 0.5, 0), Vector2(dlen * 0.5, 0),
			Vector2(dlen, ROOF_RISE)], n)
	# Roof slopes (ridge runs east-west).
	var o := ROOF_OVERHANG
	var slope_len := Vector2(dlen * 0.5 + o, ROOF_RISE + o * ROOF_RISE / (dlen * 0.5)).length()
	var eave_drop := o * ROOF_RISE / (dlen * 0.5)
	var ridge_y := h + ROOF_RISE
	var front_n := Vector3(0, dlen * 0.5, ROOF_RISE).normalized()
	var back_n := Vector3(0, dlen * 0.5, -ROOF_RISE).normalized()
	add_quad(roof, [Vector3(x0 - o, ridge_y, zc), Vector3(x1 + o, ridge_y, zc),
		Vector3(x1 + o, h - eave_drop, z1 + o), Vector3(x0 - o, h - eave_drop, z1 + o)],
		[Vector2(0, 0), Vector2(wlen + 2 * o, 0), Vector2(wlen + 2 * o, slope_len), Vector2(0, slope_len)], front_n)
	add_quad(roof, [Vector3(x1 + o, ridge_y, zc), Vector3(x0 - o, ridge_y, zc),
		Vector3(x0 - o, h - eave_drop, z0 - o), Vector3(x1 + o, h - eave_drop, z0 - o)],
		[Vector2(0, 0), Vector2(wlen + 2 * o, 0), Vector2(wlen + 2 * o, slope_len), Vector2(0, slope_len)], back_n)
	# Eave underside so the overhang has thickness when seen from below.
	add_quad(roof, [Vector3(x0 - o, h - eave_drop, z1 + o), Vector3(x1 + o, h - eave_drop, z1 + o),
		Vector3(x1 + o, h - eave_drop - 0.12, z1 + o), Vector3(x0 - o, h - eave_drop - 0.12, z1 + o)],
		[Vector2(0, 0), Vector2(wlen, 0), Vector2(wlen, 0.12), Vector2(0, 0.12)], Vector3.BACK)

	var wall_mesh := walls.commit()
	wall_mesh.surface_set_material(0, TextureFactory.get_material("house_wall"))
	var wmi := MeshInstance3D.new()
	wmi.mesh = wall_mesh
	root.add_child(wmi)
	var roof_mesh := roof.commit()
	var roof_mat := TextureFactory.get_material(roof_kind).duplicate() as StandardMaterial3D
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	roof_mesh.surface_set_material(0, roof_mat)
	var rmi := MeshInstance3D.new()
	rmi.mesh = roof_mesh
	root.add_child(rmi)

	# Door and glowing windows on the front.
	var door_x: int = house.door
	if door_x >= 0:
		_add_wall_decal(SpriteFactory.door(), Vector3(door_x + 0.5, 0, z1 + 0.02), false)
	for wx in range(house.x0, house.x1 + 1):
		if wx == door_x or wx == house.x0 or wx == house.x1:
			continue
		_add_wall_decal(SpriteFactory.window(), Vector3(wx + 0.5, 0.85, z1 + 0.02), true)
	# Chimney with smoke on every other house.
	if index % 2 == 0:
		var chimney := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.45, 1.1, 0.45)
		chimney.mesh = box
		chimney.material_override = TextureFactory.get_material("cliff_side")
		var cx := x1 - 1.0
		var cz := z0 + dlen * 0.3
		chimney.position = Vector3(cx, h + ROOF_RISE * 0.55 + 0.35, cz)
		root.add_child(chimney)
		root.add_child(_make_smoke(chimney.position + Vector3(0, 0.6, 0)))


func _add_wall_decal(tex: Texture2D, base: Vector3, emissive: bool) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(tex.get_width(), tex.get_height()) * PX
	quad.center_offset = Vector3(0, quad.size.y * 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.roughness = 0.9
	if emissive:
		mat.emission_enabled = true
		mat.emission_texture = tex
		mat.emission = Color(1.0, 0.75, 0.4)
		mat.emission_energy_multiplier = 0.9
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.position = base
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


func _make_smoke(pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = 14
	p.lifetime = 3.5
	p.local_coords = false
	var quad := QuadMesh.new()
	quad.size = Vector2(0.35, 0.35)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = SpriteFactory.particle_dot()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	p.mesh = quad
	p.direction = Vector3(0.3, 1, 0)
	p.spread = 12.0
	p.gravity = Vector3(0.15, 0.25, 0)
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.5
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.5))
	curve.add_point(Vector2(1, 1.8))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.9, 0.9, 0.95, 0.55))
	grad.set_color(1, Color(0.8, 0.8, 0.9, 0.0))
	p.color_ramp = grad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


# --------------------------------------------------------------------------
# Props
# --------------------------------------------------------------------------

func _build_props() -> void:
	var wood := TextureFactory.get_material("house_beam")
	var well_done := false
	for y in MapData.depth():
		for x in MapData.width():
			var c := MapData.cell(x, y)
			var center := Vector3(x + 0.5, 0, y + 0.5)
			match c:
				"L":
					_add_billboard(SpriteFactory.lamp_post(), center, 1.0, 0.0, 2.5)
					var light := OmniLight3D.new()
					light.position = center + Vector3(0, 1.65, 0.15)
					light.light_color = Color(1.0, 0.68, 0.35)
					light.light_energy = 1.8
					light.omni_range = 6.0
					light.omni_attenuation = 1.4
					root.add_child(light)
					lamps.append(light)
				"F":
					_add_box(wood, Vector3(0.14, 0.75, 0.14), center + Vector3(0, 0.375, 0))
					_add_box(wood, Vector3(1.0, 0.1, 0.06), center + Vector3(0, 0.55, 0))
					_add_box(wood, Vector3(1.0, 0.1, 0.06), center + Vector3(0, 0.28, 0))
				"W":
					if not well_done:
						well_done = true
						_build_well(Vector3(x + 1.0, 0, y + 1.0))
				"r":
					_add_billboard(SpriteFactory.rock(), center + Vector3(0, 0, 0.1), 1.6)
				"o":
					_add_billboard(SpriteFactory.bush(), center, 1.3, 0.02)
				"C":
					var chest := Sprite3D.new()
					chest.texture = SpriteFactory.chest()
					chest.hframes = 2
					chest.pixel_size = PX
					chest.offset = Vector2(0, 8)
					chest.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
					chest.shaded = true
					chest.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
					chest.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					chest.position = center
					root.add_child(chest)
					chests[Vector2i(x, y)] = chest
	# Bridge rails.
	for y in MapData.depth():
		for x in MapData.width():
			if MapData.cell(x, y) == "b" and MapData.cell(x - 1, y) != "b":
				_add_box(wood, Vector3(0.1, 0.1, 1.0), Vector3(x + 0.05, 0.5, y + 0.5))
				_add_box(wood, Vector3(0.12, 0.6, 0.12), Vector3(x + 0.05, 0.3, y + 0.1))
			if MapData.cell(x, y) == "b" and MapData.cell(x + 1, y) != "b":
				_add_box(wood, Vector3(0.1, 0.1, 1.0), Vector3(x + 0.95, 0.5, y + 0.5))
				_add_box(wood, Vector3(0.12, 0.6, 0.12), Vector3(x + 0.95, 0.3, y + 0.1))
	for s in MapData.SIGNS:
		var cell: Vector2i = s.cell
		signs[cell] = _add_billboard(SpriteFactory.signpost(), MapData.cell_center(cell), 1.0)


func _add_box(mat: Material, size: Vector3, pos: Vector3) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	root.add_child(mi)
	return mi


func _build_well(center: Vector3) -> void:
	var stone := TextureFactory.get_material("cliff_side").duplicate() as StandardMaterial3D
	stone.uv1_scale = Vector3(4, 1, 1)
	var ring := CylinderMesh.new()
	ring.top_radius = 0.8
	ring.bottom_radius = 0.85
	ring.height = 0.8
	ring.radial_segments = 16
	var mi := MeshInstance3D.new()
	mi.mesh = ring
	mi.material_override = stone
	mi.position = center + Vector3(0, 0.4, 0)
	root.add_child(mi)
	var water := CylinderMesh.new()
	water.top_radius = 0.66
	water.bottom_radius = 0.66
	water.height = 0.02
	var wmat := ShaderMaterial.new()
	wmat.shader = _water_shader
	var wmi := MeshInstance3D.new()
	wmi.mesh = water
	wmi.material_override = wmat
	wmi.position = center + Vector3(0, 0.75, 0)
	root.add_child(wmi)
	var wood := TextureFactory.get_material("house_beam")
	_add_box(wood, Vector3(0.12, 1.6, 0.12), center + Vector3(-0.7, 0.8, 0))
	_add_box(wood, Vector3(0.12, 1.6, 0.12), center + Vector3(0.7, 0.8, 0))
	_add_box(wood, Vector3(1.6, 0.1, 0.1), center + Vector3(0, 1.5, 0))
	var roof := PrismMesh.new()
	roof.size = Vector3(1.9, 0.55, 1.2)
	var rmi := MeshInstance3D.new()
	rmi.mesh = roof
	rmi.material_override = TextureFactory.get_material("roof_brown")
	rmi.position = center + Vector3(0, 1.85, 0)
	root.add_child(rmi)


# --------------------------------------------------------------------------
# Foliage
# --------------------------------------------------------------------------

func _build_foliage() -> void:
	var tufts := {0: [], 1: [], 2: [], 3: []}
	var flower_sets := {0: [], 1: [], 2: [], 3: []}
	for y in MapData.depth():
		for x in MapData.width():
			var c := MapData.cell(x, y)
			var base := Vector3(x + 0.5, 0, y + 0.5)
			match c:
				"T":
					var variant := 2 if rng.randf() < 0.18 else rng.randi_range(0, 1)
					var jitter := Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.1, 0.1))
					_add_billboard(SpriteFactory.tree(variant), base + jitter, rng.randf_range(0.95, 1.2), 0.035)
				"P":
					var jitter := Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.1, 0.1))
					_add_billboard(SpriteFactory.pine(), base + jitter, rng.randf_range(0.95, 1.25), 0.02)
				"^":
					if _is_edge(x, y) and rng.randf() < 0.35:
						var jitter := Vector3(rng.randf_range(-0.2, 0.2), 3.0, rng.randf_range(-0.2, 0.2))
						_add_billboard(SpriteFactory.pine(), base + jitter, rng.randf_range(0.8, 1.15), 0.02)
					elif rng.randf() < 0.25:
						tufts[rng.randi_range(0, 1)].append(_tuft_xform(base + Vector3(0, 3.0, 0), 1.0))
				"#":
					if rng.randf() < 0.5:
						tufts[rng.randi_range(0, 1)].append(_tuft_xform(base + Vector3(0, 2.0, 0), 1.0))
				",":
					for i in 4:
						tufts[rng.randi_range(2, 3)].append(_tuft_xform(base, rng.randf_range(1.1, 1.5)))
				".", "@":
					if rng.randf() < 0.3:
						tufts[rng.randi_range(0, 1)].append(_tuft_xform(base, rng.randf_range(0.7, 1.0)))
					if rng.randf() < 0.04:
						flower_sets[rng.randi_range(0, 3)].append(_tuft_xform(base, 1.0))
				"f":
					for i in 2:
						flower_sets[rng.randi_range(0, 3)].append(_tuft_xform(base, 1.0))
	for v in tufts:
		_add_multimesh(SpriteFactory.grass_tuft(v), tufts[v], 0.06)
	for v in flower_sets:
		_add_multimesh(SpriteFactory.flowers(v), flower_sets[v], 0.04)


func _is_edge(x: int, y: int) -> bool:
	for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		if MapData.cell(x + d.x, y + d.y) != "^":
			return true
	return false


func _tuft_xform(base: Vector3, s: float) -> Transform3D:
	var offset := Vector3(rng.randf_range(-0.42, 0.42), 0, rng.randf_range(-0.42, 0.42))
	return Transform3D(Basis.from_scale(Vector3.ONE * s), base + offset)


func _add_multimesh(tex: Texture2D, xforms: Array, sway: float) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = billboard_mesh(tex)
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = billboard_material(tex, sway)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


## Dense trees outside the playable area so the diorama feels like part of a larger world.
func _build_outer_forest() -> void:
	var w := float(MapData.width())
	var d := float(MapData.depth())
	var tree_x := []
	var pine_x := []
	for i in 420:
		var p := Vector3(rng.randf_range(-16, w + 16), SKIRT_LEVEL, rng.randf_range(-14, d + 12))
		if p.x > -1.0 and p.x < w + 1.0 and p.z > -1.0 and p.z < d + 1.0:
			continue
		# Keep the strip right in front of the camera fairly open.
		if p.z > d + 1.0 and p.z < d + 3.0 and rng.randf() < 0.7:
			continue
		var s := rng.randf_range(0.9, 1.4)
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * s), p)
		if p.z < 0.0 or rng.randf() < 0.4:
			pine_x.append(xf)
		else:
			tree_x.append(xf)
	_add_multimesh_shadowed(SpriteFactory.pine(), pine_x, 0.02)
	_add_multimesh_shadowed(SpriteFactory.tree(0), tree_x, 0.03)


func _add_multimesh_shadowed(tex: Texture2D, xforms: Array, sway: float) -> void:
	_add_multimesh(tex, xforms, sway)
	var last := root.get_child(root.get_child_count() - 1) as MultiMeshInstance3D
	last.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
