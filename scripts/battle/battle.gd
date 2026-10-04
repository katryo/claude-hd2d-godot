class_name Battle
extends Node3D
## Turn-based battle with a Break & Boost system:
## * Every enemy has a shield. Hitting a weakness removes one point; at zero it BREAKS,
##   losing its next turn and taking double damage.
## * Party members bank Boost Points (BP) each round and spend up to 3 per action for
##   extra attack hits or stronger skills.

signal finished(result: String)

const PX := 1.0 / 16.0
const PARTY_SLOTS := [Vector3(2.6, 0, -1.9), Vector3(4.2, 0, -0.2), Vector3(2.9, 0, 1.5)]
const ENEMY_SLOTS := {
	1: [Vector3(-3.2, 0, 0.0)],
	2: [Vector3(-2.8, 0, -1.2), Vector3(-3.8, 0, 1.1)],
	3: [Vector3(-2.4, 0, -2.0), Vector3(-4.6, 0, -0.4), Vector3(-2.8, 0, 1.4)],
}

## Enemy groups larger than this reuse the largest ENEMY_SLOTS layout.
const MAX_ENEMY_LAYOUT := 3
const BOSS_SLOT := Vector3(-3.8, 0, -0.4)

# Stage: ground grid
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

# Stage: scenery
const SCENERY_PIXEL_SIZE := 0.03
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
const TUFT_PIXEL_SIZE := 0.06
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
const FLOWER_PIXEL_SIZE := 0.04
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
## Camera shake decays by 1 per second; this scales its displacement.
const CAMERA_SHAKE_SCALE := 0.6
const HIT_SHAKE := 0.08
const BREAK_SHAKE := 0.35

# Actors
const PARTY_SPRITE_SCALE := 1.05
const ENEMY_SPRITE_SCALE := 1.25
const ENEMY_ANIM_FRAMES := 2
const ENEMY_ANIM_FPS := 2.5
const ENEMY_SPRITE_OFFSET := Vector2(0, 12)
const BAT_HOVER_HEIGHT := 0.6
const BAT_BOB_SPEED := 4.0
const BAT_BOB_AMPLITUDE := 0.15
## Where a party member steps to while acting.
const PARTY_STEP_FORWARD := Vector3(-0.6, 0, 0)
const STEP_FORWARD_TIME := 0.15
const STEP_BACK_TIME := 0.2
const DOWN_ROTATION_DEG := 90.0
const DOWN_OFFSET := Vector3(0.3, 0.15, 0)
const DOWN_TINT := Color(0.6, 0.5, 0.6)
const BROKEN_TINT := Color(0.65, 0.7, 1.0)
const DEATH_FADE_COLOR := Color(1.5, 0.4, 0.8, 0.0)
const DEATH_SQUASH_SCALE := Vector3(1.3, 0.1, 1.0)
const DEATH_FADE_TIME := 0.5
const DEATH_BURST_OFFSET := Vector3(0, 0.5, 0)
const PARTY_DOWN_TIME := 0.25

# Label3D (cursor, popups, BREAK!)
const LABEL3D_PIXEL_SIZE := 0.006
const CURSOR_FONT_SIZE := 80
const CURSOR_OUTLINE_SIZE := 18
const CURSOR_COLOR := Color(1.0, 0.85, 0.35)
const CURSOR_ALL_OFFSET := Vector3(0, 2.4, 0)
## Cursor height above a target: BASE_HEIGHT * sprite scale + CLEARANCE.
const CURSOR_BASE_HEIGHT := 1.9
const CURSOR_CLEARANCE := 0.35
const CURSOR_BOB_SPEED := 6.0
const CURSOR_BOB_AMPLITUDE := 0.08
const POPUP_FONT_SIZE := 72
const POPUP_FONT_SIZE_BIG := 96
const POPUP_OUTLINE_SIZE := 20
const POPUP_OUTLINE_COLOR := Color(0.1, 0.05, 0.1)
const POPUP_RENDER_PRIORITY := 10
const POPUP_OUTLINE_RENDER_PRIORITY := 9
const POPUP_OFFSET := Vector3(0, 1.4, 0)
const POPUP_STAGGER_COLUMNS := 3
const POPUP_STAGGER_ROWS := 2
const POPUP_STAGGER_X := 0.45
const POPUP_STAGGER_Y := 0.35
const POPUP_STAGGER_Z := 0.3
const POPUP_RISE := 0.7
const POPUP_RISE_TIME := 0.8
const POPUP_FADE_TIME := 0.4
const POPUP_FADE_DELAY := 0.6
const HEAL_POPUP_COLOR := Color(0.5, 1.0, 0.55)
const WEAK_HIT_COLOR := Color(1.0, 0.92, 0.4)
const BREAK_FONT_SIZE := 140
const BREAK_OUTLINE_SIZE := 14
const BREAK_OUTLINE_COLOR := Color(0.35, 0.08, 0.0)
const BREAK_TEXT_COLOR := Color(1.0, 0.85, 0.3)
const BREAK_RENDER_PRIORITY := 11
const BREAK_TEXT_OFFSET := Vector3(0, 1.2, 0.5)
const BREAK_TEXT_START_SCALE := 0.3
const BREAK_TEXT_POP_SCALE := 1.1
const BREAK_TEXT_POP_TIME := 0.15
const BREAK_TEXT_HOLD_TIME := 0.5
const BREAK_TEXT_FADE_TIME := 0.3
const BREAK_PAUSE_TIME := 0.6

# Boost aura
const BOOST_AURA_START_AMOUNT := 40
const BOOST_AURA_BASE_AMOUNT := 20
const BOOST_AURA_AMOUNT_PER_LEVEL := 25
const BOOST_AURA_SCALE_PER_LEVEL := 0.5
const BOOST_AURA_LIFETIME := 0.9
const BOOST_AURA_RADIUS := 0.5
const BOOST_AURA_SPREAD := 15
const BOOST_AURA_GRAVITY := Vector3(0, 2.0, 0)
const BOOST_AURA_VELOCITY_MIN := 0.3
const BOOST_AURA_VELOCITY_MAX := 0.8
const BOOST_AURA_COLOR := Color(1.0, 0.55, 0.15)
const BOOST_AURA_SPARK_SIZE := 0.08
const BOOST_AURA_OFFSET := Vector3(0, 0.6, 0)

# UI
const UI_CANVAS_LAYER := 2
const BANNER_TIME := 1.6

# Turn flow
const BP_PER_ROUND := 1
## Random 0..N added to speed when sorting the turn order.
const TURN_ORDER_JITTER := 4
const BROKEN_TURN_PENALTY := 100
const FLEE_CHANCE := 0.75
const AUTO_SKILL_CHANCE := 0.5
const ENEMY_SKILL_CHANCE := 0.3
const BOSS_SKILL_CHANCE := 0.45

# Timing (seconds)
const INTRO_MESSAGE_TIME := 1.3
const BROKEN_MESSAGE_TIME := 0.9
const DEFEND_MESSAGE_TIME := 0.7
const FLEE_ATTEMPT_TIME := 0.7
const FLEE_RESULT_TIME := 0.8
const AUTO_THINK_TIME := 0.2
const ATTACK_HIT_INTERVAL := 0.12
const SKILL_HIT_INTERVAL := 0.1
const HEAL_INTERVAL := 0.35
const BUFF_WAIT_TIME := 0.5
const SKILL_END_TIME := 0.3
const ITEM_END_TIME := 0.7
const ENEMY_TURN_END_TIME := 0.35
const VICTORY_BANNER_WAIT := 1.2
const LEVEL_UP_TIME := 1.0
const VICTORY_END_TIME := 1.0
const DEFEAT_WAIT := 2.8
const LUNGE_TIME := 0.18
const RETURN_HOME_TIME := 0.2
const CAST_HOP_TIME := 0.15

# Damage & healing
const BASIC_ATTACK_POWER := 1.0
const MAGIC_ARMOR_FACTOR := 0.6
const DAMAGE_POWER_SCALE := 2.2
## Damage never drops below this fraction of stat * power (before variance).
const MIN_DAMAGE_FACTOR := 0.4
const DAMAGE_VARIANCE_MIN := 0.9
const DAMAGE_VARIANCE_MAX := 1.1
const WEAKNESS_MULT := 1.3
const BREAK_DAMAGE_MULT := 2.0
const DEFEND_DAMAGE_MULT := 0.5
const MIN_DAMAGE := 1
const HEAL_MAG_SCALE := 1.6
const HEAL_BASE := 25
const ITEM_BOOST_PER_LEVEL := 0.5
## HP that fallen members are revived with after a won or fled battle.
const POST_BATTLE_REVIVE_HP := 1

# Movement & effects
## Lunges stop this far short of the target.
const LUNGE_STOP_DISTANCE := 1.4
const CAST_HOP_HEIGHT := 0.25
const CAST_BURST_OFFSET := Vector3(0, 0.4, 0)
const CAST_BURST_STRENGTH := 0.5
const HIT_FLASH_COLOR := Color(1.0, 0.35, 0.35)
const HIT_FLASH_TIME := 0.25
const HIT_JITTER_STEPS := 4
const HIT_JITTER_DISTANCE := 0.08
const HIT_JITTER_STEP_TIME := 0.03
## Bursts on a combatant spawn around its chest.
const BURST_OFFSET := Vector3(0, 0.7, 0)
const BURST_EXPLOSIVENESS := 0.9
const BURST_PARTICLES := 28
const BURST_MIN_PARTICLES := 4
const BURST_PARTICLE_LIFETIME := 0.7
const BURST_SPARK_SIZE := 0.11
const BURST_SPREAD := 180.0
const BURST_VELOCITY_MIN := 1.5
const BURST_VELOCITY_MAX := 3.5
const BURST_GRAVITY := -3.0
const HEAL_BURST_GRAVITY := 1.5
const BURST_DAMPING_MIN := 2.0
const BURST_DAMPING_MAX := 4.0
const BURST_RAMP_START := Color(1, 1, 1, 1)
const BURST_RAMP_END := Color(1, 1, 1, 0)
const BURST_LIGHT_ENERGY := 3.0
const BURST_LIGHT_RANGE := 4.0
const BURST_LIGHT_OFFSET := Vector3(0, 0.3, 0.6)
const BURST_LIGHT_FADE_TIME := 0.5
const BURST_CLEANUP_TIME := 1.5
const SPARK_EMISSION_ENERGY := 3.0

var enemy_ids: Array = []
var is_boss := false
## Lets the party act on its own (used by the --autobattle dev flag for smoke tests).
var autoplay := false

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var actor_nodes := {}
var home_positions := {}
var camera: Camera3D
var ui: BattleUI
var banner: Banner
var boost_level := 0
var boosted := {}
var round_number := 0
var _choosing_for: Combatant = null
var _boost_aura: CPUParticles3D
var _cursor: Label3D
var _cursor_targets: Array = []
var _cursor_index := 0
var _cursor_all := false
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _cam_base := Vector3.ZERO
var _shake := 0.0
var _popup_count := 0

signal _target_chosen(result: Variant)


func setup(ids: Array, boss: bool) -> void:
	enemy_ids = ids
	is_boss = boss


func _ready() -> void:
	_rng.randomize()
	party = Game.party
	for id in enemy_ids:
		enemies.append(BattleData.make_enemy(id))
	for m in party:
		m.defending = false
		m.break_turns = 0
	_build_stage()
	_spawn_actors()
	_build_ui()
	_run.call_deferred()


# --------------------------------------------------------------------------
# Stage
# --------------------------------------------------------------------------

func _build_stage() -> void:
	var mood := "boss" if is_boss else "battle"
	add_child(Visuals.make_sun(mood))
	add_child(Visuals.make_environment(mood))

	var st_by_mat := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = BOSS_STAGE_SEED if is_boss else _rng.randi()
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
			if not st_by_mat.has(mat):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				st_by_mat[mat] = st
			WorldBuilder.add_quad(st_by_mat[mat], [Vector3(x, h, z), Vector3(x + 1, h, z),
				Vector3(x + 1, h, z + 1), Vector3(x, h, z + 1)],
				[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)], Vector3.UP)
			if h > 0.0:
				# Cliff face toward the camera.
				for seg in int(h):
					var top := h - seg
					var m2 := "cliff_side_top" if seg == 0 else "cliff_side"
					if not st_by_mat.has(m2):
						var st2 := SurfaceTool.new()
						st2.begin(Mesh.PRIMITIVE_TRIANGLES)
						st_by_mat[m2] = st2
					var front_z := z + 1.0
					var below := CLIFF_LOW_HEIGHT if z == STAGE_Z_MIN else 0.0
					if top - 1.0 < below - CLIFF_FACE_EPSILON:
						continue
					WorldBuilder.add_quad(st_by_mat[m2], [Vector3(x, top, front_z), Vector3(x + 1, top, front_z),
						Vector3(x + 1, top - 1.0, front_z), Vector3(x, top - 1.0, front_z)],
						[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)], Vector3.BACK)
	var mesh := ArrayMesh.new()
	for mat_name in st_by_mat:
		st_by_mat[mat_name].commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, TextureFactory.get_material(mat_name))
	var ground := MeshInstance3D.new()
	ground.mesh = mesh
	add_child(ground)

	# Background trees on the cliffs and foreground grass that melts into bokeh.
	for i in BG_TREE_COUNT:
		var x := rng.randf_range(-BG_TREE_X_EXTENT, BG_TREE_X_EXTENT)
		var z := rng.randf_range(BG_TREE_Z_MIN, BG_TREE_Z_MAX)
		var y := CLIFF_HIGH_HEIGHT if z < CLIFF_FRONT_Z else CLIFF_LOW_HEIGHT
		var tex := SpriteFactory.pine() if rng.randf() < PINE_CHANCE else SpriteFactory.tree(rng.randi_range(0, BG_TREE_VARIANT_MAX))
		var bb := WorldBuilder.make_billboard(tex, SCENERY_PIXEL_SIZE)
		bb.position = Vector3(x, y, z)
		bb.scale = Vector3.ONE * rng.randf_range(BG_TREE_SCALE_MIN, BG_TREE_SCALE_MAX)
		add_child(bb)
	for i in SIDE_TREE_COUNT:
		var side := -1.0 if i % 2 == 0 else 1.0
		var bb := WorldBuilder.make_billboard(SpriteFactory.tree(rng.randi_range(0, SIDE_TREE_VARIANT_MAX)), SCENERY_PIXEL_SIZE)
		bb.position = Vector3(side * rng.randf_range(SIDE_TREE_X_MIN, SIDE_TREE_X_MAX), 0, rng.randf_range(SIDE_TREE_Z_MIN, SIDE_TREE_Z_MAX))
		bb.scale = Vector3.ONE * rng.randf_range(SIDE_TREE_SCALE_MIN, SIDE_TREE_SCALE_MAX)
		add_child(bb)
	var tufts := []
	for i in TUFT_COUNT:
		var p := Vector3(rng.randf_range(-TUFT_X_EXTENT, TUFT_X_EXTENT), 0, rng.randf_range(TUFT_Z_MIN, TUFT_Z_MAX))
		if abs(p.x) < ARENA_CLEAR_HALF_WIDTH and p.z > -ARENA_CLEAR_HALF_DEPTH and p.z < ARENA_CLEAR_HALF_DEPTH:
			continue
		tufts.append(Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(TUFT_SCALE_MIN, TUFT_SCALE_MAX)), p))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var tuft_tex := SpriteFactory.grass_tuft(TUFT_VARIANT)
	mm.mesh = WorldBuilder.billboard_mesh(tuft_tex)
	mm.instance_count = tufts.size()
	for i in tufts.size():
		mm.set_instance_transform(i, tufts[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = WorldBuilder.billboard_material(tuft_tex, TUFT_PIXEL_SIZE)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	for i in FLOWER_COUNT:
		var fl := WorldBuilder.make_billboard(SpriteFactory.flowers(i % FLOWER_VARIANTS), FLOWER_PIXEL_SIZE)
		fl.position = Vector3(rng.randf_range(-FLOWER_X_EXTENT, FLOWER_X_EXTENT), 0, rng.randf_range(FLOWER_Z_MIN, FLOWER_Z_MAX))
		if abs(fl.position.x) < FLOWER_CLEAR_HALF_WIDTH:
			fl.position.x += FLOWER_PUSH_OUT * sign(fl.position.x + FLOWER_SIGN_BIAS)
		add_child(fl)

	if is_boss:
		for x in BOSS_PILLAR_XS:
			var pillar := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = BOSS_PILLAR_SIZE
			pillar.mesh = box
			pillar.material_override = TextureFactory.get_material("cliff_side")
			pillar.position = Vector3(x, BOSS_PILLAR_Y, BOSS_PILLAR_INNER_Z if abs(x) < BOSS_PILLAR_INNER_MAX_X else BOSS_PILLAR_OUTER_Z)
			add_child(pillar)
			var crystal := OmniLight3D.new()
			crystal.light_color = CRYSTAL_LIGHT_COLOR
			crystal.light_energy = CRYSTAL_LIGHT_ENERGY
			crystal.omni_range = CRYSTAL_LIGHT_RANGE
			crystal.position = pillar.position + CRYSTAL_LIGHT_OFFSET
			add_child(crystal)

	var motes := Visuals.make_motes(MOTES_EXTENTS, MOTES_COUNT)
	motes.position = MOTES_POSITION
	add_child(motes)

	camera = Camera3D.new()
	camera.fov = CAMERA_FOV
	camera.position = CAMERA_POSITION
	add_child(camera)
	camera.look_at(CAMERA_LOOK_TARGET)
	_cam_base = camera.position
	var focus := camera.position.distance_to(CAMERA_LOOK_TARGET)
	var attrs := Visuals.make_camera_attributes(focus)
	attrs.dof_blur_far_distance = focus + DOF_FAR_OFFSET
	attrs.dof_blur_far_transition = DOF_FAR_TRANSITION
	attrs.dof_blur_near_distance = focus - DOF_NEAR_OFFSET
	attrs.dof_blur_near_transition = DOF_NEAR_TRANSITION
	camera.attributes = attrs
	camera.current = true


func _spawn_actors() -> void:
	for i in party.size():
		var m := party[i]
		var spr := CharacterSprite.new()
		spr.setup(m.sprite_id)
		spr.facing = CharacterSprite.Facing.LEFT
		spr.pixel_size = PX * PARTY_SPRITE_SCALE
		spr.position = PARTY_SLOTS[i]
		add_child(spr)
		actor_nodes[m] = spr
		home_positions[m] = spr.position
		if not m.is_alive():
			_set_down(m, true)
	var slots: Array = ENEMY_SLOTS[clampi(enemies.size(), 1, MAX_ENEMY_LAYOUT)]
	for i in enemies.size():
		var e := enemies[i]
		var spr := Sprite3D.new()
		spr.texture = SpriteFactory.enemy_sheet(e.sprite_id)
		spr.hframes = ENEMY_ANIM_FRAMES
		spr.pixel_size = PX * ENEMY_SPRITE_SCALE * e.sprite_scale
		spr.offset = ENEMY_SPRITE_OFFSET
		spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		spr.shaded = true
		spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		spr.position = BOSS_SLOT if is_boss else slots[i]
		if e.id == "bat":
			spr.position.y = BAT_HOVER_HEIGHT
		add_child(spr)
		actor_nodes[e] = spr
		home_positions[e] = spr.position

	_cursor = Label3D.new()
	_cursor.text = "▼"
	_cursor.font_size = CURSOR_FONT_SIZE
	_cursor.outline_size = CURSOR_OUTLINE_SIZE
	_cursor.pixel_size = LABEL3D_PIXEL_SIZE
	_cursor.modulate = CURSOR_COLOR
	_cursor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cursor.no_depth_test = true
	_cursor.visible = false
	add_child(_cursor)

	_boost_aura = CPUParticles3D.new()
	_boost_aura.emitting = false
	_boost_aura.amount = BOOST_AURA_START_AMOUNT
	_boost_aura.lifetime = BOOST_AURA_LIFETIME
	_boost_aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_boost_aura.emission_sphere_radius = BOOST_AURA_RADIUS
	_boost_aura.direction = Vector3.UP
	_boost_aura.spread = BOOST_AURA_SPREAD
	_boost_aura.gravity = BOOST_AURA_GRAVITY
	_boost_aura.initial_velocity_min = BOOST_AURA_VELOCITY_MIN
	_boost_aura.initial_velocity_max = BOOST_AURA_VELOCITY_MAX
	_boost_aura.mesh = _spark_mesh(BOOST_AURA_COLOR, BOOST_AURA_SPARK_SIZE)
	_boost_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_boost_aura)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = UI_CANVAS_LAYER
	add_child(layer)
	ui = BattleUI.new()
	layer.add_child(ui)
	ui.setup(party, enemies, camera, actor_nodes)
	banner = Banner.new()
	layer.add_child(banner)


# --------------------------------------------------------------------------
# Main loop
# --------------------------------------------------------------------------

func _run() -> void:
	var names := []
	for e in enemies:
		names.append(e.display_name)
	ui.show_message(("%s blocks the way!" if is_boss else "%s appeared!") % " & ".join(names))
	await _wait(INTRO_MESSAGE_TIME)
	ui.hide_message()
	while true:
		round_number += 1
		var order := _turn_order()
		ui.set_turn_order(order)
		for i in order.size():
			var actor: Combatant = order[i]
			if _battle_over():
				break
			if not actor.is_alive():
				ui.mark_turn_done(i)
				continue
			if actor.is_broken():
				ui.show_message("%s is broken and cannot act!" % actor.display_name)
				await _wait(BROKEN_MESSAGE_TIME)
				ui.hide_message()
				ui.mark_turn_done(i)
				continue
			ui.set_active(actor)
			var fled := false
			if actor.is_enemy:
				await _enemy_turn(actor)
				if is_boss and actor.hp < actor.max_hp / 2 and not _battle_over() and not actor.is_broken():
					# Enraged bosses act twice.
					await _enemy_turn(actor)
			else:
				fled = await _player_turn(actor)
			ui.mark_turn_done(i)
			ui.set_active(null)
			if fled:
				await _finish("flee")
				return
		if _battle_over():
			break
		for c in party + enemies:
			c.end_of_round()
			_update_broken_tint(c)
		for m in party:
			if m.is_alive() and not boosted.has(m):
				m.gain_bp(BP_PER_ROUND)
		boosted.clear()
		ui.refresh()
	if _enemies_dead():
		await _victory()
	else:
		await _defeat()


func _turn_order() -> Array:
	var all := []
	for c in party + enemies:
		if c.is_alive():
			all.append([c, c.spd + _rng.randi_range(0, TURN_ORDER_JITTER) - (BROKEN_TURN_PENALTY if c.is_broken() else 0)])
	all.sort_custom(func(a, b): return a[1] > b[1])
	var order := []
	for entry in all:
		order.append(entry[0])
	return order


func _battle_over() -> bool:
	return _enemies_dead() or not Game.party_alive()


func _enemies_dead() -> bool:
	for e in enemies:
		if e.is_alive():
			return false
	return true


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


# --------------------------------------------------------------------------
# Player turns
# --------------------------------------------------------------------------

## Returns true if the party fled.
func _player_turn(actor: Combatant) -> bool:
	actor.defending = false
	var node: Node3D = actor_nodes[actor]
	var tw := create_tween()
	tw.tween_property(node, "position", home_positions[actor] + PARTY_STEP_FORWARD, STEP_FORWARD_TIME)
	_set_boost(actor, 0)
	if autoplay:
		await _auto_turn(actor)
		tw = create_tween()
		tw.tween_property(node, "position", home_positions[actor], STEP_BACK_TIME)
		return false
	_choosing_for = actor
	var fled := false
	while true:
		var cmd := await ui.choose_command(actor, not is_boss)
		match cmd:
			"attack":
				var target = await _pick_target(_alive(enemies))
				if target == null:
					continue
				_commit_boost(actor)
				await _do_attack(actor, target)
				break
			"skill":
				var skill_id := await ui.choose_skill(actor)
				if skill_id == "":
					continue
				var skill: Dictionary = BattleData.SKILLS[skill_id]
				var targets := await _targets_for(skill.target)
				if targets.is_empty():
					continue
				_commit_boost(actor)
				await _use_skill(actor, skill_id, targets)
				break
			"item":
				var item_id := await ui.choose_item()
				if item_id == "":
					continue
				var item: Dictionary = BattleData.ITEMS[item_id]
				var pool := _dead(party) if item.revive else _alive(party)
				if pool.is_empty():
					continue
				var target = await _pick_target(pool)
				if target == null:
					continue
				_commit_boost(actor)
				await _use_item(actor, item_id, target)
				break
			"defend":
				_set_boost(actor, 0)
				_commit_boost(actor)
				actor.defending = true
				ui.show_message("%s braces for impact." % actor.display_name)
				await _wait(DEFEND_MESSAGE_TIME)
				break
			"flee":
				_choosing_for = null
				ui.show_message("The party tries to run...")
				await _wait(FLEE_ATTEMPT_TIME)
				if _rng.randf() < FLEE_CHANCE:
					ui.show_message("Got away safely!")
					await _wait(FLEE_RESULT_TIME)
					fled = true
					break
				ui.show_message("Couldn't escape!")
				await _wait(FLEE_RESULT_TIME)
				break
	_choosing_for = null
	_boost_aura.emitting = false
	ui.hide_message()
	ui.set_boost_preview(0)
	tw = create_tween()
	tw.tween_property(node, "position", home_positions[actor], STEP_BACK_TIME)
	return fled


func _auto_turn(actor: Combatant) -> void:
	await _wait(AUTO_THINK_TIME)
	var foes := _alive(enemies)
	_set_boost(actor, _rng.randi_range(0, min(actor.bp, Combatant.MAX_BOOST)))
	var usable := actor.skills.filter(func(s): return actor.sp >= BattleData.SKILLS[s].cost)
	if not usable.is_empty() and _rng.randf() < AUTO_SKILL_CHANCE:
		var skill_id: String = usable[_rng.randi_range(0, usable.size() - 1)]
		var targets := []
		match BattleData.SKILLS[skill_id].target:
			"enemy": targets = [foes[_rng.randi_range(0, foes.size() - 1)]]
			"all_enemies": targets = foes
			"ally":
				var allies := _alive(party)
				allies.sort_custom(func(a, b): return a.hp < b.hp)
				targets = [allies[0]]
			"all_allies": targets = _alive(party)
		_commit_boost(actor)
		await _use_skill(actor, skill_id, targets)
	else:
		_commit_boost(actor)
		await _do_attack(actor, foes[_rng.randi_range(0, foes.size() - 1)])
	_boost_aura.emitting = false
	ui.hide_message()


func _targets_for(kind: String) -> Array:
	match kind:
		"enemy":
			var t = await _pick_target(_alive(enemies))
			return [] if t == null else [t]
		"all_enemies":
			return await _pick_all(_alive(enemies))
		"ally":
			var t = await _pick_target(_alive(party))
			return [] if t == null else [t]
		"all_allies":
			return await _pick_all(_alive(party))
	return []


func _alive(list: Array) -> Array:
	return list.filter(func(c): return c.is_alive())


func _dead(list: Array) -> Array:
	return list.filter(func(c): return not c.is_alive())


func _set_boost(actor: Combatant, level: int) -> void:
	boost_level = clampi(level, 0, min(actor.bp, Combatant.MAX_BOOST))
	ui.set_boost_preview(boost_level)
	var node: Node3D = actor_nodes[actor]
	_boost_aura.global_position = node.global_position + BOOST_AURA_OFFSET
	_boost_aura.emitting = boost_level > 0
	_boost_aura.amount = BOOST_AURA_BASE_AMOUNT + boost_level * BOOST_AURA_AMOUNT_PER_LEVEL
	_boost_aura.scale_amount_max = 1.0 + boost_level * BOOST_AURA_SCALE_PER_LEVEL


func _commit_boost(actor: Combatant) -> void:
	_choosing_for = null
	if boost_level > 0:
		actor.bp -= boost_level
		boosted[actor] = true
		ui.show_message("BOOST x%d!" % boost_level)
	# BP is already deducted, so stop previewing the spend.
	ui.set_boost_preview(0)


func _unhandled_input(event: InputEvent) -> void:
	if _choosing_for != null:
		if event.is_action_pressed("boost_up"):
			get_viewport().set_input_as_handled()
			_set_boost(_choosing_for, boost_level + 1)
		elif event.is_action_pressed("boost_down"):
			get_viewport().set_input_as_handled()
			_set_boost(_choosing_for, boost_level - 1)
	if not _cursor.visible:
		return
	if event.is_action_pressed("accept"):
		get_viewport().set_input_as_handled()
		_cursor.visible = false
		_target_chosen.emit(_cursor_targets if _cursor_all else _cursor_targets[_cursor_index])
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_cursor.visible = false
		_target_chosen.emit(null)
	elif not _cursor_all:
		var delta := 0
		if event.is_action_pressed("move_down", true) or event.is_action_pressed("move_right", true):
			delta = 1
		elif event.is_action_pressed("move_up", true) or event.is_action_pressed("move_left", true):
			delta = -1
		if delta != 0:
			get_viewport().set_input_as_handled()
			_cursor_index = posmod(_cursor_index + delta, _cursor_targets.size())
			_show_target_help()


func _pick_target(candidates: Array) -> Variant:
	if candidates.is_empty():
		return null
	# Sort top-to-bottom on screen so up/down feel natural.
	candidates.sort_custom(func(a, b): return home_positions[a].z < home_positions[b].z)
	_cursor_targets = candidates
	_cursor_all = false
	_cursor_index = clampi(_cursor_index, 0, candidates.size() - 1)
	_cursor.visible = true
	_show_target_help()
	var result = await _target_chosen
	ui.show_help("")
	return result


func _pick_all(candidates: Array) -> Array:
	if candidates.is_empty():
		return []
	_cursor_targets = candidates
	_cursor_all = true
	_cursor.visible = true
	ui.show_help("Targets all. Confirm with Z/Enter.")
	var result = await _target_chosen
	ui.show_help("")
	return [] if result == null else result


func _show_target_help() -> void:
	var t: Combatant = _cursor_targets[_cursor_index]
	if t.is_enemy:
		ui.show_help("%s   Shield %d" % [t.display_name, t.shield])
	else:
		ui.show_help("%s   HP %d/%d   SP %d/%d" % [t.display_name, t.hp, t.max_hp, t.sp, t.max_sp])


# --------------------------------------------------------------------------
# Actions
# --------------------------------------------------------------------------

func _do_attack(actor: Combatant, target: Combatant) -> void:
	var hits := 1 + boost_level
	var node: Node3D = actor_nodes[actor]
	await _lunge(node, actor_nodes[target].global_position)
	for i in hits:
		if not target.is_alive():
			break
		var dmg := _calc_damage(actor, target, "physical", BASIC_ATTACK_POWER, actor.weapon)
		await _apply_hit(actor, target, dmg, actor.weapon)
		await _wait(ATTACK_HIT_INTERVAL)
	await _return_home(actor)


func _use_skill(actor: Combatant, skill_id: String, targets: Array) -> void:
	var skill: Dictionary = BattleData.SKILLS[skill_id]
	actor.spend_sp(skill.cost)
	ui.refresh()
	ui.show_message(skill.name + ("  (Boost x%d)" % boost_level if boost_level > 0 else ""))
	var node: Node3D = actor_nodes[actor]
	var mult: float = BattleData.BOOST_POWER[boost_level]
	var element: String = skill.element
	if skill.kind == "physical" and targets.size() == 1:
		await _lunge(node, actor_nodes[targets[0]].global_position)
	else:
		await _cast_pose(node, element)
	match skill.kind:
		"physical", "magic":
			for t in targets:
				for h in int(skill.hits):
					if not t.is_alive():
						break
					var dmg := _calc_damage(actor, t, skill.kind, skill.power * mult, element)
					_burst(actor_nodes[t].global_position + BURST_OFFSET, element)
					await _apply_hit(actor, t, dmg, element)
					await _wait(SKILL_HIT_INTERVAL)
		"heal":
			for t in targets:
				var amount := int((actor.mag * skill.power * HEAL_MAG_SCALE + HEAL_BASE) * mult)
				_burst(actor_nodes[t].global_position + BURST_OFFSET, "heal")
				var healed: int = t.heal(amount)
				_popup(actor_nodes[t], str(healed), HEAL_POPUP_COLOR)
				await _wait(HEAL_INTERVAL)
		"buff_bp":
			for t in targets:
				t.gain_bp(1 + boost_level)
				_burst(actor_nodes[t].global_position + BURST_OFFSET, "boost")
				_popup(actor_nodes[t], "+%d BP" % (1 + boost_level), UITheme.BP_COLOR)
			await _wait(BUFF_WAIT_TIME)
	ui.refresh()
	if skill.kind == "physical" and targets.size() == 1:
		await _return_home(actor)
	await _wait(SKILL_END_TIME)
	ui.hide_message()


func _use_item(actor: Combatant, item_id: String, target: Combatant) -> void:
	var item: Dictionary = BattleData.ITEMS[item_id]
	Game.use_item(item_id)
	ui.show_message("%s uses %s." % [actor.display_name, item.name])
	await _cast_pose(actor_nodes[actor], "heal")
	var mult: float = 1.0 + boost_level * ITEM_BOOST_PER_LEVEL
	_burst(actor_nodes[target].global_position + BURST_OFFSET, "heal")
	if item.revive:
		target.hp = 0
		_set_down(target, false)
	if item.hp > 0:
		var healed := target.heal(int(item.hp * mult))
		_popup(actor_nodes[target], str(healed), HEAL_POPUP_COLOR)
	if item.sp > 0:
		var restored := target.restore_sp(int(item.sp * mult))
		_popup(actor_nodes[target], "%d SP" % restored, UITheme.SP_COLOR)
	ui.refresh()
	await _wait(ITEM_END_TIME)
	ui.hide_message()


func _calc_damage(actor: Combatant, target: Combatant, kind: String, power: float, element: String) -> Dictionary:
	var stat := actor.atk if kind == "physical" else actor.mag
	var armor := target.def * (1.0 if kind == "physical" else MAGIC_ARMOR_FACTOR)
	var base := stat * power * DAMAGE_POWER_SCALE - armor
	base = max(base, stat * power * MIN_DAMAGE_FACTOR)
	base *= _rng.randf_range(DAMAGE_VARIANCE_MIN, DAMAGE_VARIANCE_MAX)
	var weak := target.weaknesses.has(element)
	if weak:
		base *= WEAKNESS_MULT
	if target.is_broken():
		base *= BREAK_DAMAGE_MULT
	if target.defending:
		base *= DEFEND_DAMAGE_MULT
	return {"amount": max(MIN_DAMAGE, int(base)), "weak": weak}


func _apply_hit(_actor: Combatant, target: Combatant, dmg: Dictionary, element: String) -> void:
	var node: Node3D = actor_nodes[target]
	var dealt := target.take_damage(dmg.amount)
	var color := WEAK_HIT_COLOR if dmg.weak else Color.WHITE
	_popup(node, str(dealt), color, dmg.weak)
	_flash(node)
	_shake = HIT_SHAKE
	var broke := target.hit_shield(element)
	ui.refresh()
	if broke:
		await _break_effect(target)
	if not target.is_alive():
		await _defeat_actor(target)


func _set_down(c: Combatant, down: bool) -> void:
	var node: Node3D = actor_nodes[c]
	if down:
		node.rotation_degrees.z = DOWN_ROTATION_DEG if not c.is_enemy else 0.0
		node.position = home_positions[c] + DOWN_OFFSET
		(node as SpriteBase3D).modulate = DOWN_TINT
		(node as SpriteBase3D).billboard = BaseMaterial3D.BILLBOARD_DISABLED
	else:
		node.rotation_degrees.z = 0.0
		node.position = home_positions[c]
		(node as SpriteBase3D).modulate = Color.WHITE
		(node as SpriteBase3D).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


func _defeat_actor(c: Combatant) -> void:
	var node := actor_nodes[c] as SpriteBase3D
	if c.is_enemy:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(node, "modulate", DEATH_FADE_COLOR, DEATH_FADE_TIME)
		tw.tween_property(node, "scale", DEATH_SQUASH_SCALE, DEATH_FADE_TIME)
		_burst(node.global_position + DEATH_BURST_OFFSET, "death")
		await tw.finished
		node.visible = false
	else:
		_set_down(c, true)
		await _wait(PARTY_DOWN_TIME)


func _update_broken_tint(c: Combatant) -> void:
	if not c.is_enemy or not c.is_alive():
		return
	var node := actor_nodes[c] as SpriteBase3D
	node.modulate = BROKEN_TINT if c.is_broken() else Color.WHITE


# --------------------------------------------------------------------------
# Enemy turns
# --------------------------------------------------------------------------

func _enemy_turn(actor: Combatant) -> void:
	var targets := _alive(party)
	if targets.is_empty():
		return
	var use_skill := not actor.skills.is_empty() and _rng.randf() < (BOSS_SKILL_CHANCE if is_boss else ENEMY_SKILL_CHANCE)
	if use_skill:
		var skill_id: String = actor.skills[_rng.randi_range(0, actor.skills.size() - 1)]
		var skill: Dictionary = BattleData.SKILLS[skill_id]
		ui.show_message("%s uses %s!" % [actor.display_name, skill.name])
		var chosen := targets if skill.target == "all_enemies" else [targets[_rng.randi_range(0, targets.size() - 1)]]
		var node: Node3D = actor_nodes[actor]
		if skill.kind == "physical":
			await _lunge(node, actor_nodes[chosen[0]].global_position)
		else:
			await _cast_pose(node, "dark")
		for t in chosen:
			var dmg := _calc_damage(actor, t, skill.kind, skill.power, "")
			_burst(actor_nodes[t].global_position + BURST_OFFSET, "dark")
			await _apply_hit(actor, t, dmg, "")
			await _wait(SKILL_HIT_INTERVAL)
		if skill.kind == "physical":
			await _return_home(actor)
	else:
		var target: Combatant = targets[_rng.randi_range(0, targets.size() - 1)]
		ui.show_message("%s attacks %s!" % [actor.display_name, target.display_name])
		await _lunge(actor_nodes[actor], actor_nodes[target].global_position)
		var dmg := _calc_damage(actor, target, "physical", BASIC_ATTACK_POWER, "")
		await _apply_hit(actor, target, dmg, "")
		await _return_home(actor)
	await _wait(ENEMY_TURN_END_TIME)
	ui.hide_message()


# --------------------------------------------------------------------------
# Results
# --------------------------------------------------------------------------

func _victory() -> void:
	var xp := 0
	var gold := 0
	for e in enemies:
		xp += e.exp_reward
		gold += e.gold_reward
	Game.add_gold(gold)
	banner.show_text("VICTORY", "%d EXP   %d G" % [xp, gold], BANNER_TIME)
	await _wait(VICTORY_BANNER_WAIT)
	for m in party:
		var gained := m.add_exp(xp if m.is_alive() else xp / 2)
		if gained > 0:
			ui.show_message("%s reached level %d!" % [m.display_name, m.level])
			_burst(actor_nodes[m].global_position + BURST_OFFSET, "boost")
			await _wait(LEVEL_UP_TIME)
	ui.refresh()
	await _wait(VICTORY_END_TIME)
	await _finish("win")


func _defeat() -> void:
	banner.show_text("DEFEAT", "The party has fallen...", BANNER_TIME)
	await _wait(DEFEAT_WAIT)
	await _finish("lose")


func _finish(result: String) -> void:
	print("[battle] finished: %s after %d rounds" % [result, round_number])
	for m in party:
		m.defending = false
		m.break_turns = 0
		if result != "lose" and not m.is_alive():
			m.hp = POST_BATTLE_REVIVE_HP
	finished.emit(result)


# --------------------------------------------------------------------------
# Effects
# --------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	for e in enemies:
		var node := actor_nodes.get(e) as Sprite3D
		if node and e.is_alive():
			node.frame = int(_time * ENEMY_ANIM_FPS + e.max_hp) % ENEMY_ANIM_FRAMES
			if e.id == "bat":
				node.position.y = home_positions[e].y + sin(_time * BAT_BOB_SPEED + e.max_hp) * BAT_BOB_AMPLITUDE
	if _cursor.visible:
		if _cursor_all:
			_cursor.text = "▼ ALL ▼"
			var center := Vector3.ZERO
			for t in _cursor_targets:
				center += actor_nodes[t].global_position
			center /= _cursor_targets.size()
			_cursor.global_position = center + CURSOR_ALL_OFFSET
		else:
			_cursor.text = "▼"
			var t: Combatant = _cursor_targets[_cursor_index]
			var h := CURSOR_BASE_HEIGHT * (t.sprite_scale if t.is_enemy else 1.0) + CURSOR_CLEARANCE
			_cursor.global_position = actor_nodes[t].global_position + Vector3(0, h + sin(_time * CURSOR_BOB_SPEED) * CURSOR_BOB_AMPLITUDE, 0)
	if _shake > 0.0:
		_shake = max(_shake - delta, 0.0)
		camera.position = _cam_base + Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), 0) * _shake * CAMERA_SHAKE_SCALE
	else:
		camera.position = _cam_base


func _lunge(node: Node3D, toward: Vector3) -> void:
	var start := node.position
	var dir := (toward - start)
	dir.y = 0
	var dest: Vector3 = start + dir.normalized() * max(dir.length() - LUNGE_STOP_DISTANCE, 0.0)
	var tw := create_tween()
	tw.tween_property(node, "position", dest, LUNGE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished


func _return_home(actor: Combatant) -> void:
	var node: Node3D = actor_nodes[actor]
	var home: Vector3 = home_positions[actor]
	if not actor.is_enemy:
		home += PARTY_STEP_FORWARD
	var tw := create_tween()
	tw.tween_property(node, "position", home, RETURN_HOME_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func _cast_pose(node: Node3D, element: String) -> void:
	var tw := create_tween()
	tw.tween_property(node, "position:y", node.position.y + CAST_HOP_HEIGHT, CAST_HOP_TIME)
	tw.tween_property(node, "position:y", node.position.y, CAST_HOP_TIME)
	_burst(node.global_position + CAST_BURST_OFFSET, element, CAST_BURST_STRENGTH)
	await tw.finished


func _flash(node: Node3D) -> void:
	var spr := node as SpriteBase3D
	var base := spr.modulate
	spr.modulate = HIT_FLASH_COLOR
	var tw := create_tween()
	tw.tween_property(spr, "modulate", base, HIT_FLASH_TIME)
	var start := node.position
	var shake := create_tween()
	for i in HIT_JITTER_STEPS:
		shake.tween_property(node, "position", start + Vector3(HIT_JITTER_DISTANCE * (1 if i % 2 == 0 else -1), 0, 0), HIT_JITTER_STEP_TIME)
	shake.tween_property(node, "position", start, HIT_JITTER_STEP_TIME)


func _popup(node: Node3D, text: String, color: Color, big: bool = false) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = POPUP_FONT_SIZE_BIG if big else POPUP_FONT_SIZE
	l.outline_size = POPUP_OUTLINE_SIZE
	l.outline_modulate = POPUP_OUTLINE_COLOR
	l.pixel_size = LABEL3D_PIXEL_SIZE
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = POPUP_RENDER_PRIORITY
	l.outline_render_priority = POPUP_OUTLINE_RENDER_PRIORITY
	add_child(l)
	# Stagger consecutive popups so multi-hit numbers don't overlap.
	_popup_count += 1
	var stagger := Vector3((_popup_count % POPUP_STAGGER_COLUMNS - 1) * POPUP_STAGGER_X, (_popup_count % POPUP_STAGGER_ROWS) * POPUP_STAGGER_Y, POPUP_STAGGER_Z)
	l.global_position = node.global_position + POPUP_OFFSET + stagger
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + POPUP_RISE, POPUP_RISE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, POPUP_FADE_TIME).set_delay(POPUP_FADE_DELAY)
	tw.tween_property(l, "outline_modulate:a", 0.0, POPUP_FADE_TIME).set_delay(POPUP_FADE_DELAY)
	tw.chain().tween_callback(l.queue_free)


func _break_effect(target: Combatant) -> void:
	var node: Node3D = actor_nodes[target]
	_shake = BREAK_SHAKE
	var l := Label3D.new()
	l.text = "BREAK!"
	l.font_size = BREAK_FONT_SIZE
	l.outline_size = BREAK_OUTLINE_SIZE
	l.outline_modulate = BREAK_OUTLINE_COLOR
	l.pixel_size = LABEL3D_PIXEL_SIZE
	l.modulate = BREAK_TEXT_COLOR
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = BREAK_RENDER_PRIORITY
	add_child(l)
	l.global_position = node.global_position + BREAK_TEXT_OFFSET
	l.scale = Vector3.ONE * BREAK_TEXT_START_SCALE
	_burst(node.global_position + BURST_OFFSET, "break")
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * BREAK_TEXT_POP_SCALE, BREAK_TEXT_POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(BREAK_TEXT_HOLD_TIME)
	tw.tween_property(l, "modulate:a", 0.0, BREAK_TEXT_FADE_TIME)
	tw.tween_callback(l.queue_free)
	_update_broken_tint(target)
	await _wait(BREAK_PAUSE_TIME)


const BURST_COLORS := {
	"sword": Color(0.9, 0.95, 1.0), "bow": Color(0.7, 1.0, 0.5), "staff": Color(0.9, 0.75, 0.5),
	"fire": Color(1.0, 0.45, 0.15), "ice": Color(0.5, 0.85, 1.0), "thunder": Color(1.0, 0.95, 0.3),
	"light": Color(1.0, 0.95, 0.7), "heal": Color(0.45, 1.0, 0.55), "boost": Color(1.0, 0.6, 0.2),
	"dark": Color(0.7, 0.35, 1.0), "break": Color(1.0, 0.7, 0.3), "death": Color(0.9, 0.6, 1.0),
	"": Color(1, 1, 1),
}


func _spark_mesh(color: Color, size: float) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = SpriteFactory.particle_dot()
	mat.albedo_color = color
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = SPARK_EMISSION_ENERGY
	quad.material = mat
	return quad


func _burst(pos: Vector3, element: String, strength: float = 1.0) -> void:
	var color: Color = BURST_COLORS.get(element, Color.WHITE)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = BURST_EXPLOSIVENESS
	p.amount = int(BURST_PARTICLES * strength) + BURST_MIN_PARTICLES
	p.lifetime = BURST_PARTICLE_LIFETIME
	p.mesh = _spark_mesh(color, BURST_SPARK_SIZE)
	p.direction = Vector3.UP
	p.spread = BURST_SPREAD
	p.initial_velocity_min = BURST_VELOCITY_MIN * strength
	p.initial_velocity_max = BURST_VELOCITY_MAX * strength
	p.gravity = Vector3(0, BURST_GRAVITY if element != "heal" else HEAL_BURST_GRAVITY, 0)
	p.damping_min = BURST_DAMPING_MIN
	p.damping_max = BURST_DAMPING_MAX
	var grad := Gradient.new()
	grad.set_color(0, BURST_RAMP_START)
	grad.set_color(1, BURST_RAMP_END)
	p.color_ramp = grad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.global_position = pos
	p.emitting = true
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = BURST_LIGHT_ENERGY * strength
	light.omni_range = BURST_LIGHT_RANGE
	add_child(light)
	light.global_position = pos + BURST_LIGHT_OFFSET
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, BURST_LIGHT_FADE_TIME)
	tw.tween_callback(light.queue_free)
	get_tree().create_timer(BURST_CLEANUP_TIME).timeout.connect(p.queue_free)
