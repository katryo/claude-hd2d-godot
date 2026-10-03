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
	rng.seed = 77 if is_boss else _rng.randi()
	for z in range(-7, 8):
		for x in range(-12, 13):
			var mat := "grass" if (x + z * 3) % 7 != 0 else "grass_dark"
			if is_boss:
				var r := Vector2(x * 0.8, z).length()
				mat = "stone" if r < 5.0 else "cliff_top"
			elif abs(z - x * 0.15) < 1.0 and rng.randf() < 0.85:
				mat = "dirt"
			var h := 0.0
			if z <= -6:
				h = 2.0 if z == -6 else 3.0
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
					var below := 2.0 if z == -7 else 0.0
					if top - 1.0 < below - 0.001:
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
	for i in 26:
		var x := rng.randf_range(-13, 13)
		var z := rng.randf_range(-7.0, -5.6)
		var y := 3.0 if z < -6.0 else 2.0
		var tex := SpriteFactory.pine() if rng.randf() < 0.5 else SpriteFactory.tree(rng.randi_range(0, 2))
		var bb := WorldBuilder.make_billboard(tex, 0.03)
		bb.position = Vector3(x, y, z)
		bb.scale = Vector3.ONE * rng.randf_range(1.0, 1.4)
		add_child(bb)
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		var bb := WorldBuilder.make_billboard(SpriteFactory.tree(rng.randi_range(0, 1)), 0.03)
		bb.position = Vector3(side * rng.randf_range(7.0, 10.0), 0, rng.randf_range(-4.5, 1.0))
		bb.scale = Vector3.ONE * rng.randf_range(1.0, 1.25)
		add_child(bb)
	var tufts := []
	for i in 140:
		var p := Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-5.5, 7.0))
		if abs(p.x) < 5.5 and p.z > -3.0 and p.z < 3.0:
			continue
		tufts.append(Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(1.0, 1.8)), p))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var tuft_tex := SpriteFactory.grass_tuft(1)
	mm.mesh = WorldBuilder.billboard_mesh(tuft_tex)
	mm.instance_count = tufts.size()
	for i in tufts.size():
		mm.set_instance_transform(i, tufts[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = WorldBuilder.billboard_material(tuft_tex, 0.06)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	for i in 8:
		var fl := WorldBuilder.make_billboard(SpriteFactory.flowers(i % 4), 0.04)
		fl.position = Vector3(rng.randf_range(-9, 9), 0, rng.randf_range(2.5, 5.0))
		if abs(fl.position.x) < 4.5:
			fl.position.x += 5.0 * sign(fl.position.x + 0.01)
		add_child(fl)

	if is_boss:
		for x in [-6.0, 6.0, -8.5, 8.5]:
			var pillar := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.8, 3.2, 0.8)
			pillar.mesh = box
			pillar.material_override = TextureFactory.get_material("cliff_side")
			pillar.position = Vector3(x, 1.6, -3.2 if abs(x) < 7 else -1.0)
			add_child(pillar)
			var crystal := OmniLight3D.new()
			crystal.light_color = Color(0.5, 0.55, 1.0)
			crystal.light_energy = 2.0
			crystal.omni_range = 5.0
			crystal.position = pillar.position + Vector3(0, 2.0, 0.6)
			add_child(crystal)

	var motes := Visuals.make_motes(Vector3(10, 2.5, 5), 70)
	motes.position = Vector3(0, 1.5, 0)
	add_child(motes)

	camera = Camera3D.new()
	camera.fov = 30.0
	camera.position = Vector3(0.0, 7.0, 12.8)
	add_child(camera)
	camera.look_at(Vector3(0, 0.9, 0))
	_cam_base = camera.position
	var focus := camera.position.distance_to(Vector3(0, 0.9, 0))
	var attrs := Visuals.make_camera_attributes(focus)
	attrs.dof_blur_far_distance = focus + 3.0
	attrs.dof_blur_far_transition = 7.0
	attrs.dof_blur_near_distance = focus - 4.5
	attrs.dof_blur_near_transition = 2.5
	camera.attributes = attrs
	camera.current = true


func _spawn_actors() -> void:
	for i in party.size():
		var m := party[i]
		var spr := CharacterSprite.new()
		spr.setup(m.sprite_id)
		spr.facing = CharacterSprite.Facing.LEFT
		spr.pixel_size = PX * 1.05
		spr.position = PARTY_SLOTS[i]
		add_child(spr)
		actor_nodes[m] = spr
		home_positions[m] = spr.position
		if not m.is_alive():
			_set_down(m, true)
	var slots: Array = ENEMY_SLOTS[clampi(enemies.size(), 1, 3)]
	for i in enemies.size():
		var e := enemies[i]
		var spr := Sprite3D.new()
		spr.texture = SpriteFactory.enemy_sheet(e.sprite_id)
		spr.hframes = 2
		spr.pixel_size = PX * 1.25 * e.sprite_scale
		spr.offset = Vector2(0, 12)
		spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		spr.shaded = true
		spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		spr.position = Vector3(-3.8, 0, -0.4) if is_boss else slots[i]
		if e.id == "bat":
			spr.position.y = 0.6
		add_child(spr)
		actor_nodes[e] = spr
		home_positions[e] = spr.position

	_cursor = Label3D.new()
	_cursor.text = "▼"
	_cursor.font_size = 80
	_cursor.outline_size = 18
	_cursor.pixel_size = 0.006
	_cursor.modulate = Color(1.0, 0.85, 0.35)
	_cursor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cursor.no_depth_test = true
	_cursor.visible = false
	add_child(_cursor)

	_boost_aura = CPUParticles3D.new()
	_boost_aura.emitting = false
	_boost_aura.amount = 40
	_boost_aura.lifetime = 0.9
	_boost_aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_boost_aura.emission_sphere_radius = 0.5
	_boost_aura.direction = Vector3.UP
	_boost_aura.spread = 15
	_boost_aura.gravity = Vector3(0, 2.0, 0)
	_boost_aura.initial_velocity_min = 0.3
	_boost_aura.initial_velocity_max = 0.8
	_boost_aura.mesh = _spark_mesh(Color(1.0, 0.55, 0.15), 0.08)
	_boost_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_boost_aura)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
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
	await _wait(1.3)
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
				await _wait(0.9)
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
				m.gain_bp(1)
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
			all.append([c, c.spd + _rng.randi_range(0, 4) - (100 if c.is_broken() else 0)])
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
	tw.tween_property(node, "position", home_positions[actor] + Vector3(-0.6, 0, 0), 0.15)
	_set_boost(actor, 0)
	if autoplay:
		await _auto_turn(actor)
		tw = create_tween()
		tw.tween_property(node, "position", home_positions[actor], 0.2)
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
				await _wait(0.7)
				break
			"flee":
				_choosing_for = null
				ui.show_message("The party tries to run...")
				await _wait(0.7)
				if _rng.randf() < 0.75:
					ui.show_message("Got away safely!")
					await _wait(0.8)
					fled = true
					break
				ui.show_message("Couldn't escape!")
				await _wait(0.8)
				break
	_choosing_for = null
	_boost_aura.emitting = false
	ui.hide_message()
	ui.set_boost_preview(0)
	tw = create_tween()
	tw.tween_property(node, "position", home_positions[actor], 0.2)
	return fled


func _auto_turn(actor: Combatant) -> void:
	await _wait(0.2)
	var foes := _alive(enemies)
	_set_boost(actor, _rng.randi_range(0, min(actor.bp, Combatant.MAX_BOOST)))
	var usable := actor.skills.filter(func(s): return actor.sp >= BattleData.SKILLS[s].cost)
	if not usable.is_empty() and _rng.randf() < 0.5:
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
	_boost_aura.global_position = node.global_position + Vector3(0, 0.6, 0)
	_boost_aura.emitting = boost_level > 0
	_boost_aura.amount = 20 + boost_level * 25
	_boost_aura.scale_amount_max = 1.0 + boost_level * 0.5


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
		var dmg := _calc_damage(actor, target, "physical", 1.0, actor.weapon)
		await _apply_hit(actor, target, dmg, actor.weapon)
		await _wait(0.12)
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
					_burst(actor_nodes[t].global_position + Vector3(0, 0.7, 0), element)
					await _apply_hit(actor, t, dmg, element)
					await _wait(0.1)
		"heal":
			for t in targets:
				var amount := int((actor.mag * skill.power * 1.6 + 25) * mult)
				_burst(actor_nodes[t].global_position + Vector3(0, 0.7, 0), "heal")
				var healed: int = t.heal(amount)
				_popup(actor_nodes[t], str(healed), Color(0.5, 1.0, 0.55))
				await _wait(0.35)
		"buff_bp":
			for t in targets:
				t.gain_bp(1 + boost_level)
				_burst(actor_nodes[t].global_position + Vector3(0, 0.7, 0), "boost")
				_popup(actor_nodes[t], "+%d BP" % (1 + boost_level), UITheme.BP_COLOR)
			await _wait(0.5)
	ui.refresh()
	if skill.kind == "physical" and targets.size() == 1:
		await _return_home(actor)
	await _wait(0.3)
	ui.hide_message()


func _use_item(actor: Combatant, item_id: String, target: Combatant) -> void:
	var item: Dictionary = BattleData.ITEMS[item_id]
	Game.use_item(item_id)
	ui.show_message("%s uses %s." % [actor.display_name, item.name])
	await _cast_pose(actor_nodes[actor], "heal")
	var mult: float = 1.0 + boost_level * 0.5
	_burst(actor_nodes[target].global_position + Vector3(0, 0.7, 0), "heal")
	if item.revive:
		target.hp = 0
		_set_down(target, false)
	if item.hp > 0:
		var healed := target.heal(int(item.hp * mult))
		_popup(actor_nodes[target], str(healed), Color(0.5, 1.0, 0.55))
	if item.sp > 0:
		var restored := target.restore_sp(int(item.sp * mult))
		_popup(actor_nodes[target], "%d SP" % restored, UITheme.SP_COLOR)
	ui.refresh()
	await _wait(0.7)
	ui.hide_message()


func _calc_damage(actor: Combatant, target: Combatant, kind: String, power: float, element: String) -> Dictionary:
	var stat := actor.atk if kind == "physical" else actor.mag
	var armor := target.def * (1.0 if kind == "physical" else 0.6)
	var base := stat * power * 2.2 - armor
	base = max(base, stat * power * 0.4)
	base *= _rng.randf_range(0.9, 1.1)
	var weak := target.weaknesses.has(element)
	if weak:
		base *= 1.3
	if target.is_broken():
		base *= 2.0
	if target.defending:
		base *= 0.5
	return {"amount": max(1, int(base)), "weak": weak}


func _apply_hit(_actor: Combatant, target: Combatant, dmg: Dictionary, element: String) -> void:
	var node: Node3D = actor_nodes[target]
	var dealt := target.take_damage(dmg.amount)
	var color := Color(1.0, 0.92, 0.4) if dmg.weak else Color.WHITE
	_popup(node, str(dealt), color, dmg.weak)
	_flash(node)
	_shake = 0.08
	var broke := target.hit_shield(element)
	ui.refresh()
	if broke:
		await _break_effect(target)
	if not target.is_alive():
		await _defeat_actor(target)


func _set_down(c: Combatant, down: bool) -> void:
	var node: Node3D = actor_nodes[c]
	if down:
		node.rotation_degrees.z = 90.0 if not c.is_enemy else 0.0
		node.position = home_positions[c] + Vector3(0.3, 0.15, 0)
		(node as SpriteBase3D).modulate = Color(0.6, 0.5, 0.6)
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
		tw.tween_property(node, "modulate", Color(1.5, 0.4, 0.8, 0.0), 0.5)
		tw.tween_property(node, "scale", Vector3(1.3, 0.1, 1.0), 0.5)
		_burst(node.global_position + Vector3(0, 0.5, 0), "death")
		await tw.finished
		node.visible = false
	else:
		_set_down(c, true)
		await _wait(0.25)


func _update_broken_tint(c: Combatant) -> void:
	if not c.is_enemy or not c.is_alive():
		return
	var node := actor_nodes[c] as SpriteBase3D
	node.modulate = Color(0.65, 0.7, 1.0) if c.is_broken() else Color.WHITE


# --------------------------------------------------------------------------
# Enemy turns
# --------------------------------------------------------------------------

func _enemy_turn(actor: Combatant) -> void:
	var targets := _alive(party)
	if targets.is_empty():
		return
	var use_skill := not actor.skills.is_empty() and _rng.randf() < (0.45 if is_boss else 0.3)
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
			_burst(actor_nodes[t].global_position + Vector3(0, 0.7, 0), "dark")
			await _apply_hit(actor, t, dmg, "")
			await _wait(0.1)
		if skill.kind == "physical":
			await _return_home(actor)
	else:
		var target: Combatant = targets[_rng.randi_range(0, targets.size() - 1)]
		ui.show_message("%s attacks %s!" % [actor.display_name, target.display_name])
		await _lunge(actor_nodes[actor], actor_nodes[target].global_position)
		var dmg := _calc_damage(actor, target, "physical", 1.0, "")
		await _apply_hit(actor, target, dmg, "")
		await _return_home(actor)
	await _wait(0.35)
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
	banner.show_text("VICTORY", "%d EXP   %d G" % [xp, gold], 1.6)
	await _wait(1.2)
	for m in party:
		var gained := m.add_exp(xp if m.is_alive() else xp / 2)
		if gained > 0:
			ui.show_message("%s reached level %d!" % [m.display_name, m.level])
			_burst(actor_nodes[m].global_position + Vector3(0, 0.7, 0), "boost")
			await _wait(1.0)
	ui.refresh()
	await _wait(1.0)
	await _finish("win")


func _defeat() -> void:
	banner.show_text("DEFEAT", "The party has fallen...", 1.6)
	await _wait(2.8)
	await _finish("lose")


func _finish(result: String) -> void:
	print("[battle] finished: %s after %d rounds" % [result, round_number])
	for m in party:
		m.defending = false
		m.break_turns = 0
		if result != "lose" and not m.is_alive():
			m.hp = 1
	finished.emit(result)


# --------------------------------------------------------------------------
# Effects
# --------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	for e in enemies:
		var node := actor_nodes.get(e) as Sprite3D
		if node and e.is_alive():
			node.frame = int(_time * 2.5 + e.max_hp) % 2
			if e.id == "bat":
				node.position.y = home_positions[e].y + sin(_time * 4.0 + e.max_hp) * 0.15
	if _cursor.visible:
		if _cursor_all:
			_cursor.text = "▼ ALL ▼"
			var center := Vector3.ZERO
			for t in _cursor_targets:
				center += actor_nodes[t].global_position
			center /= _cursor_targets.size()
			_cursor.global_position = center + Vector3(0, 2.4, 0)
		else:
			_cursor.text = "▼"
			var t: Combatant = _cursor_targets[_cursor_index]
			var h := 1.9 * (t.sprite_scale if t.is_enemy else 1.0) + 0.35
			_cursor.global_position = actor_nodes[t].global_position + Vector3(0, h + sin(_time * 6.0) * 0.08, 0)
	if _shake > 0.0:
		_shake = max(_shake - delta, 0.0)
		camera.position = _cam_base + Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), 0) * _shake * 0.6
	else:
		camera.position = _cam_base


func _lunge(node: Node3D, toward: Vector3) -> void:
	var start := node.position
	var dir := (toward - start)
	dir.y = 0
	var dest: Vector3 = start + dir.normalized() * max(dir.length() - 1.4, 0.0)
	var tw := create_tween()
	tw.tween_property(node, "position", dest, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished


func _return_home(actor: Combatant) -> void:
	var node: Node3D = actor_nodes[actor]
	var home: Vector3 = home_positions[actor]
	if not actor.is_enemy:
		home += Vector3(-0.6, 0, 0)
	var tw := create_tween()
	tw.tween_property(node, "position", home, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func _cast_pose(node: Node3D, element: String) -> void:
	var tw := create_tween()
	tw.tween_property(node, "position:y", node.position.y + 0.25, 0.15)
	tw.tween_property(node, "position:y", node.position.y, 0.15)
	_burst(node.global_position + Vector3(0, 0.4, 0), element, 0.5)
	await tw.finished


func _flash(node: Node3D) -> void:
	var spr := node as SpriteBase3D
	var base := spr.modulate
	spr.modulate = Color(1.0, 0.35, 0.35)
	var tw := create_tween()
	tw.tween_property(spr, "modulate", base, 0.25)
	var start := node.position
	var shake := create_tween()
	for i in 4:
		shake.tween_property(node, "position", start + Vector3(0.08 * (1 if i % 2 == 0 else -1), 0, 0), 0.03)
	shake.tween_property(node, "position", start, 0.03)


func _popup(node: Node3D, text: String, color: Color, big: bool = false) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 96 if big else 72
	l.outline_size = 20
	l.outline_modulate = Color(0.1, 0.05, 0.1)
	l.pixel_size = 0.006
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 10
	l.outline_render_priority = 9
	add_child(l)
	# Stagger consecutive popups so multi-hit numbers don't overlap.
	_popup_count += 1
	var stagger := Vector3((_popup_count % 3 - 1) * 0.45, (_popup_count % 2) * 0.35, 0.3)
	l.global_position = node.global_position + Vector3(0, 1.4, 0) + stagger
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 0.7, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


func _break_effect(target: Combatant) -> void:
	var node: Node3D = actor_nodes[target]
	_shake = 0.35
	var l := Label3D.new()
	l.text = "BREAK!"
	l.font_size = 140
	l.outline_size = 14
	l.outline_modulate = Color(0.35, 0.08, 0.0)
	l.pixel_size = 0.006
	l.modulate = Color(1.0, 0.85, 0.3)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 11
	add_child(l)
	l.global_position = node.global_position + Vector3(0, 1.2, 0.5)
	l.scale = Vector3.ONE * 0.3
	_burst(node.global_position + Vector3(0, 0.7, 0), "break")
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.1, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)
	_update_broken_tint(target)
	await _wait(0.6)


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
	mat.emission_energy_multiplier = 3.0
	quad.material = mat
	return quad


func _burst(pos: Vector3, element: String, strength: float = 1.0) -> void:
	var color: Color = BURST_COLORS.get(element, Color.WHITE)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = int(28 * strength) + 4
	p.lifetime = 0.7
	p.mesh = _spark_mesh(color, 0.11)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 1.5 * strength
	p.initial_velocity_max = 3.5 * strength
	p.gravity = Vector3(0, -3.0 if element != "heal" else 1.5, 0)
	p.damping_min = 2.0
	p.damping_max = 4.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = grad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.global_position = pos
	p.emitting = true
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 3.0 * strength
	light.omni_range = 4.0
	add_child(light)
	light.global_position = pos + Vector3(0, 0.3, 0.6)
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.5)
	tw.tween_callback(light.queue_free)
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)
