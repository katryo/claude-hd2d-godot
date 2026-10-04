class_name BattleStage
extends Node3D
## The battle diorama: lighting, ground tiles, cliffs, scenery and the camera (with
## depth of field and screen shake). Purely visual.

# Ground grid
const BOSS_STAGE_SEED := 77
const STAGE_Z_MIN := -7
const STAGE_Z_END := 8
const STAGE_X_MIN := -12
const STAGE_X_END := 13
## Dark grass tiles appear where (x + z * STRIDE) % PERIOD == 0.
const GRASS_PATTERN_Z_STRIDE := 3
const GRASS_PATTERN_PERIOD := 7
## Boss arena is an ellipse squashed along x.
const BOSS_ARENA_X_SQUASH := 0.8
const BOSS_ARENA_RADIUS := 5.0
const PATH_SLOPE := 0.15
const PATH_HALF_WIDTH := 1.0
const PATH_DIRT_CHANCE := 0.85
## Rows at or behind this z are raised cliffs.
const CLIFF_FRONT_Z := -6
const CLIFF_LOW_HEIGHT := 2.0
const CLIFF_HIGH_HEIGHT := 3.0
const CLIFF_FACE_EPSILON := 0.001
const UNIT_QUAD_UVS := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]

# Scenery
const TREE_SWAY := 0.03
const BG_TREE_COUNT := 26
const BG_TREE_X_EXTENT := 13
const BG_TREE_Z_MIN := -7.0
const BG_TREE_Z_MAX := -5.6
const BG_TREE_SCALE_MIN := 1.0
const BG_TREE_SCALE_MAX := 1.4
const PINE_CHANCE := 0.5
const BG_TREE_VARIANT_MAX := 2
const SIDE_TREE_COUNT := 6
const SIDE_TREE_VARIANT_MAX := 1
const SIDE_TREE_X_MIN := 7.0
const SIDE_TREE_X_MAX := 10.0
const SIDE_TREE_Z_MIN := -4.5
const SIDE_TREE_Z_MAX := 1.0
const SIDE_TREE_SCALE_MIN := 1.0
const SIDE_TREE_SCALE_MAX := 1.25
const TUFT_COUNT := 140
const TUFT_VARIANT := 1
const TUFT_SWAY := 0.06
const TUFT_X_EXTENT := 12
const TUFT_Z_MIN := -5.5
const TUFT_Z_MAX := 7.0
const TUFT_SCALE_MIN := 1.0
const TUFT_SCALE_MAX := 1.8
## Tufts are kept out of this box around the fighters.
const ARENA_CLEAR_HALF_WIDTH := 5.5
const ARENA_CLEAR_HALF_DEPTH := 3.0
const FLOWER_COUNT := 8
const FLOWER_VARIANTS := 4
const FLOWER_SWAY := 0.04
const FLOWER_X_EXTENT := 9
const FLOWER_Z_MIN := 2.5
const FLOWER_Z_MAX := 5.0
## Flowers closer to the centre than this are pushed outward by FLOWER_PUSH_OUT.
const FLOWER_CLEAR_HALF_WIDTH := 4.5
const FLOWER_PUSH_OUT := 5.0
## Nudges x == 0 to the positive side so sign() never returns 0.
const FLOWER_SIGN_BIAS := 0.01
const BOSS_PILLAR_XS := [-6.0, 6.0, -8.5, 8.5]
const BOSS_PILLAR_SIZE := Vector3(0.8, 3.2, 0.8)
const BOSS_PILLAR_Y := 1.6
## Pillars with |x| below this stand further back.
const BOSS_PILLAR_INNER_MAX_X := 7
const BOSS_PILLAR_INNER_Z := -3.2
const BOSS_PILLAR_OUTER_Z := -1.0
const CRYSTAL_LIGHT_COLOR := Color(0.5, 0.55, 1.0)
const CRYSTAL_LIGHT_ENERGY := 2.0
const CRYSTAL_LIGHT_RANGE := 5.0
const CRYSTAL_LIGHT_OFFSET := Vector3(0, 2.0, 0.6)
const MOTES_EXTENTS := Vector3(10, 2.5, 5)
const MOTES_COUNT := 70
const MOTES_POSITION := Vector3(0, 1.5, 0)

# Camera
const CAMERA_FOV := 30.0
const CAMERA_POSITION := Vector3(0.0, 7.0, 12.8)
const CAMERA_LOOK_TARGET := Vector3(0, 0.9, 0)
const DOF_FAR_OFFSET := 3.0
const DOF_FAR_TRANSITION := 7.0
const DOF_NEAR_OFFSET := 4.5
const DOF_NEAR_TRANSITION := 2.5
## Shake decays by 1 per second; this scales its displacement.
const CAMERA_SHAKE_SCALE := 0.6

var camera: Camera3D
var _shake := 0.0
var _shake_rng := RandomNumberGenerator.new()


func build(is_boss: bool) -> void:
	var mood := "boss" if is_boss else "battle"
	add_child(Visuals.make_sun(mood))
	add_child(Visuals.make_environment(mood))
	var rng := RandomNumberGenerator.new()
	if is_boss:
		rng.seed = BOSS_STAGE_SEED
	else:
		rng.randomize()
	_build_ground(rng, is_boss)
	_build_scenery(rng)
	if is_boss:
		_build_boss_arena()
	var motes := Visuals.make_motes(MOTES_EXTENTS, MOTES_COUNT)
	motes.position = MOTES_POSITION
	add_child(motes)
	_build_camera()


## Kicks the camera; stronger shakes override weaker ones in progress.
func shake(amount: float) -> void:
	_shake = max(_shake, amount)


func _process(delta: float) -> void:
	if not camera:
		return
	if _shake > 0.0:
		_shake = max(_shake - delta, 0.0)
		var jitter := Vector3(_shake_rng.randf_range(-1, 1), _shake_rng.randf_range(-1, 1), 0)
		camera.position = CAMERA_POSITION + jitter * _shake * CAMERA_SHAKE_SCALE
	else:
		camera.position = CAMERA_POSITION


func _build_ground(rng: RandomNumberGenerator, is_boss: bool) -> void:
	var st_by_mat := {}
	var surface := func(mat: String) -> SurfaceTool:
		if not st_by_mat.has(mat):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st_by_mat[mat] = st
		return st_by_mat[mat]
	for z in range(STAGE_Z_MIN, STAGE_Z_END):
		for x in range(STAGE_X_MIN, STAGE_X_END):
			var mat := "grass" if (x + z * GRASS_PATTERN_Z_STRIDE) % GRASS_PATTERN_PERIOD != 0 else "grass_dark"
			if is_boss:
				var r := Vector2(x * BOSS_ARENA_X_SQUASH, z).length()
				mat = "stone" if r < BOSS_ARENA_RADIUS else "cliff_top"
			elif abs(z - x * PATH_SLOPE) < PATH_HALF_WIDTH and rng.randf() < PATH_DIRT_CHANCE:
				mat = "dirt"
			var h := 0.0
			if z <= CLIFF_FRONT_Z:
				h = CLIFF_LOW_HEIGHT if z == CLIFF_FRONT_Z else CLIFF_HIGH_HEIGHT
				mat = "cliff_top"
			WorldBuilder.add_quad(surface.call(mat), [Vector3(x, h, z), Vector3(x + 1, h, z),
				Vector3(x + 1, h, z + 1), Vector3(x, h, z + 1)], UNIT_QUAD_UVS, Vector3.UP)
			# Cliff faces toward the camera, one unit-tall segment at a time.
			var below := CLIFF_LOW_HEIGHT if z == STAGE_Z_MIN else 0.0
			for seg in int(h):
				var top := h - seg
				if top - 1.0 < below - CLIFF_FACE_EPSILON:
					continue
				var front_z := z + 1.0
				var face_mat := "cliff_side_top" if seg == 0 else "cliff_side"
				WorldBuilder.add_quad(surface.call(face_mat), [Vector3(x, top, front_z), Vector3(x + 1, top, front_z),
					Vector3(x + 1, top - 1.0, front_z), Vector3(x, top - 1.0, front_z)], UNIT_QUAD_UVS, Vector3.BACK)
	var mesh := ArrayMesh.new()
	for mat_name in st_by_mat:
		st_by_mat[mat_name].commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, TextureFactory.get_material(mat_name))
	var ground := MeshInstance3D.new()
	ground.mesh = mesh
	add_child(ground)


## Background trees on the cliffs and foreground grass that melts into bokeh.
func _build_scenery(rng: RandomNumberGenerator) -> void:
	for i in BG_TREE_COUNT:
		var x := rng.randf_range(-BG_TREE_X_EXTENT, BG_TREE_X_EXTENT)
		var z := rng.randf_range(BG_TREE_Z_MIN, BG_TREE_Z_MAX)
		var y := CLIFF_HIGH_HEIGHT if z < CLIFF_FRONT_Z else CLIFF_LOW_HEIGHT
		var tex := SpriteFactory.pine() if rng.randf() < PINE_CHANCE \
			else SpriteFactory.tree(rng.randi_range(0, BG_TREE_VARIANT_MAX))
		_add_billboard(tex, Vector3(x, y, z), rng.randf_range(BG_TREE_SCALE_MIN, BG_TREE_SCALE_MAX), TREE_SWAY)
	for i in SIDE_TREE_COUNT:
		var side := -1.0 if i % 2 == 0 else 1.0
		var tex := SpriteFactory.tree(rng.randi_range(0, SIDE_TREE_VARIANT_MAX))
		var pos := Vector3(side * rng.randf_range(SIDE_TREE_X_MIN, SIDE_TREE_X_MAX), 0,
			rng.randf_range(SIDE_TREE_Z_MIN, SIDE_TREE_Z_MAX))
		_add_billboard(tex, pos, rng.randf_range(SIDE_TREE_SCALE_MIN, SIDE_TREE_SCALE_MAX), TREE_SWAY)
	var tufts := []
	for i in TUFT_COUNT:
		var p := Vector3(rng.randf_range(-TUFT_X_EXTENT, TUFT_X_EXTENT), 0, rng.randf_range(TUFT_Z_MIN, TUFT_Z_MAX))
		if abs(p.x) < ARENA_CLEAR_HALF_WIDTH and abs(p.z) < ARENA_CLEAR_HALF_DEPTH:
			continue
		tufts.append(Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(TUFT_SCALE_MIN, TUFT_SCALE_MAX)), p))
	var tuft_tex := SpriteFactory.grass_tuft(TUFT_VARIANT)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = WorldBuilder.billboard_mesh(tuft_tex)
	mm.instance_count = tufts.size()
	for i in tufts.size():
		mm.set_instance_transform(i, tufts[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = WorldBuilder.billboard_material(tuft_tex, TUFT_SWAY)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	for i in FLOWER_COUNT:
		var pos := Vector3(rng.randf_range(-FLOWER_X_EXTENT, FLOWER_X_EXTENT), 0, rng.randf_range(FLOWER_Z_MIN, FLOWER_Z_MAX))
		if abs(pos.x) < FLOWER_CLEAR_HALF_WIDTH:
			pos.x += FLOWER_PUSH_OUT * sign(pos.x + FLOWER_SIGN_BIAS)
		_add_billboard(SpriteFactory.flowers(i % FLOWER_VARIANTS), pos, 1.0, FLOWER_SWAY)


func _build_boss_arena() -> void:
	for x in BOSS_PILLAR_XS:
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = BOSS_PILLAR_SIZE
		pillar.mesh = box
		pillar.material_override = TextureFactory.get_material("cliff_side")
		var z := BOSS_PILLAR_INNER_Z if abs(x) < BOSS_PILLAR_INNER_MAX_X else BOSS_PILLAR_OUTER_Z
		pillar.position = Vector3(x, BOSS_PILLAR_Y, z)
		add_child(pillar)
		var crystal := OmniLight3D.new()
		crystal.light_color = CRYSTAL_LIGHT_COLOR
		crystal.light_energy = CRYSTAL_LIGHT_ENERGY
		crystal.omni_range = CRYSTAL_LIGHT_RANGE
		crystal.position = pillar.position + CRYSTAL_LIGHT_OFFSET
		add_child(crystal)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = CAMERA_FOV
	camera.position = CAMERA_POSITION
	add_child(camera)
	camera.look_at(CAMERA_LOOK_TARGET)
	var focus := CAMERA_POSITION.distance_to(CAMERA_LOOK_TARGET)
	var attrs := Visuals.make_camera_attributes(focus)
	attrs.dof_blur_far_distance = focus + DOF_FAR_OFFSET
	attrs.dof_blur_far_transition = DOF_FAR_TRANSITION
	attrs.dof_blur_near_distance = focus - DOF_NEAR_OFFSET
	attrs.dof_blur_near_transition = DOF_NEAR_TRANSITION
	camera.attributes = attrs
	camera.current = true


func _add_billboard(tex: Texture2D, pos: Vector3, scale_factor: float, sway: float) -> void:
	var bb := WorldBuilder.make_billboard(tex, sway)
	bb.position = pos
	bb.scale = Vector3.ONE * scale_factor
	add_child(bb)
