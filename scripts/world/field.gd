class_name Field
extends Node3D
## The explorable overworld: builds the diorama, spawns the cast and runs exploration
## (talking, chests, shops, random encounters).

signal battle_requested(enemy_ids: Array, is_boss: bool)

# HUD / status window
const UI_LAYER := 2
const HUD_GOLD_POSITION := Vector2(24, 18)
## Offset from the bottom-left corner.
const HINT_POSITION := Vector2(24, -34)
const STATUS_HALF_WIDTH := 380
const STATUS_HALF_HEIGHT := 230
const STATUS_SEPARATION := 10
const STATUS_ROW_SEPARATION := 26
const STATUS_NAME_MIN_SIZE := Vector2(90, 0)

# Camera bounds (world units inset from the map edges)
const CAMERA_MARGIN_X := 9.0
const CAMERA_MARGIN_TOP := 4.0
const CAMERA_MARGIN_BOTTOM := 3.0

# Ambient motes around the player
const MOTES_EXTENTS := Vector3(12, 2.5, 9)
const MOTES_OFFSET := Vector3(0, 1.5, -2)

# Street lamp flicker: two summed sine waves
const LAMP_FLICKER_FREQ_A := 9.0
## Per-lamp phase step so neighbouring lamps don't flicker in sync.
const LAMP_FLICKER_PHASE_A := 1.7
const LAMP_FLICKER_AMP_A := 0.08
const LAMP_FLICKER_FREQ_B := 23.0
const LAMP_FLICKER_AMP_B := 0.05

# Boss on the overworld
const BOSS_COLLIDER_RADIUS := 1.1
const BOSS_COLLIDER_HEIGHT := 2.0
const BOSS_COLLIDER_OFFSET := Vector3(0, 1, 0)
const BOSS_SPRITE_FRAMES := 2
const BOSS_PIXEL_SIZE := 1.0 / 16.0 * 2.2
const BOSS_SPRITE_OFFSET := Vector2(0, 12)
const BOSS_ANIM_FPS := 2.0
const BOSS_GLOW_COLOR := Color(0.5, 0.6, 1.0)
const BOSS_GLOW_ENERGY := 1.5
const BOSS_GLOW_RANGE := 5.0
const BOSS_GLOW_OFFSET := Vector3(0, 1.0, 1.2)
const VICTORY_BANNER_HOLD := 2.5

# Interaction
const INTERACT_REACH := 1.6
## The boss is large, so it can be reached from further away.
const BOSS_EXTRA_REACH := 1.0
## Beyond this distance the player must be facing the target...
const INTERACT_FACING_MIN_DIST := 0.3
## ...with at least this dot product between facing and direction to target.
const INTERACT_FACING_DOT := 0.45
const CHEST_OPEN_FRAME := 1
const DEFAULT_CHEST_LOOT := {"item": "potion", "count": 1}

# Inn
## Starts as transparent black and fades in over the screen while resting.
const REST_FADE_COLOR := Color(0, 0, 0, 0)
const REST_FADE_TIME := 0.6
const REST_HOLD_TIME := 0.7
## Where the party wakes up after losing a battle.
const INN_RESPAWN_CELL := Vector2i(8, 26)

# Shop: [item id, price in gold]
const STOCK := [["potion", 20], ["ether", 40], ["feather", 80]]

# Random encounters (distance walked in tall grass)
const INITIAL_ENCOUNTER_THRESHOLD := 10.0
const ENCOUNTER_THRESHOLD_MIN := 7.0
const ENCOUNTER_THRESHOLD_MAX := 15.0

var builder := WorldBuilder.new()
var player: Player
var camera: FollowCamera
var npcs: Array[NPC] = []
var boss: StaticBody3D
var boss_sprite: Sprite3D
var ui: CanvasLayer
var dialogue: DialogueBox
var banner: Banner
var status_panel: PanelContainer
var hud_gold: Label

var busy := false
var _encounter_meter := 0.0
var _encounter_threshold := INITIAL_ENCOUNTER_THRESHOLD
var _time := 0.0
var _lamp_base := []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	builder.build(self)
	for lamp in builder.lamps:
		_lamp_base.append(lamp.light_energy)

	add_child(Visuals.make_sun("field"))
	add_child(Visuals.make_environment("field"))

	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.position = MapData.cell_center(MapData.find("@"))
	player.sprite.facing = CharacterSprite.Facing.UP
	player.moved.connect(_on_player_moved)

	camera = FollowCamera.new()
	camera.target = player
	camera.attributes = Visuals.make_camera_attributes(camera.distance)
	camera.bounds = Rect2(CAMERA_MARGIN_X, CAMERA_MARGIN_TOP,
		MapData.width() - CAMERA_MARGIN_X * 2, MapData.depth() - CAMERA_MARGIN_TOP - CAMERA_MARGIN_BOTTOM)
	add_child(camera)
	camera.current = true
	camera.snap()

	var motes := Visuals.make_motes(MOTES_EXTENTS)
	motes.position = MOTES_OFFSET
	player.add_child(motes)

	for data in MapData.NPCS:
		var npc := NPC.new()
		npc.setup(data)
		npc.position = MapData.cell_center(data.cell)
		add_child(npc)
		npcs.append(npc)

	if not Game.has_flag("boss_defeated"):
		_spawn_boss()
	for cell in builder.chests:
		if Game.has_flag(_chest_flag(cell)):
			builder.chests[cell].frame = CHEST_OPEN_FRAME

	_build_ui()
	_new_encounter_threshold()


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = UI_LAYER
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	ui.add_child(root)

	hud_gold = UITheme.label("", UITheme.FONT_MEDIUM, UITheme.GOLD)
	hud_gold.position = HUD_GOLD_POSITION
	root.add_child(hud_gold)
	var hint := UITheme.label("WASD/Arrows: Move   Shift: Run   Z/Enter: Talk   Tab: Status", UITheme.FONT_XSMALL, UITheme.DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = HINT_POSITION
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	root.add_child(hint)

	status_panel = PanelContainer.new()
	status_panel.anchor_left = 0.5
	status_panel.anchor_right = 0.5
	status_panel.anchor_top = 0.5
	status_panel.anchor_bottom = 0.5
	status_panel.offset_left = -STATUS_HALF_WIDTH
	status_panel.offset_right = STATUS_HALF_WIDTH
	status_panel.offset_top = -STATUS_HALF_HEIGHT
	status_panel.offset_bottom = STATUS_HALF_HEIGHT
	status_panel.visible = false
	root.add_child(status_panel)

	dialogue = DialogueBox.new()
	root.add_child(dialogue)
	banner = Banner.new()
	root.add_child(banner)


func _spawn_boss() -> void:
	var cell := MapData.find("K")
	boss = StaticBody3D.new()
	boss.position = MapData.cell_center(cell)
	var shape := CylinderShape3D.new()
	shape.radius = BOSS_COLLIDER_RADIUS
	shape.height = BOSS_COLLIDER_HEIGHT
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = BOSS_COLLIDER_OFFSET
	boss.add_child(cs)
	boss_sprite = Sprite3D.new()
	boss_sprite.texture = SpriteFactory.enemy_sheet("king_slime")
	boss_sprite.hframes = BOSS_SPRITE_FRAMES
	boss_sprite.pixel_size = BOSS_PIXEL_SIZE
	boss_sprite.offset = BOSS_SPRITE_OFFSET
	boss_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	boss_sprite.shaded = true
	boss_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	boss_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	boss.add_child(boss_sprite)
	var glow := OmniLight3D.new()
	glow.light_color = BOSS_GLOW_COLOR
	glow.light_energy = BOSS_GLOW_ENERGY
	glow.omni_range = BOSS_GLOW_RANGE
	glow.position = BOSS_GLOW_OFFSET
	boss.add_child(glow)
	add_child(boss)


func set_controls(enabled: bool) -> void:
	player.controls_enabled = enabled and not busy
	ui.visible = enabled or busy


func show_location_banner() -> void:
	banner.show_text("Lumen Hollow", "~ a quiet village at the meadow's edge ~")


# --------------------------------------------------------------------------
# Frame update
# --------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	for i in builder.lamps.size():
		var flicker := sin(_time * LAMP_FLICKER_FREQ_A + i * LAMP_FLICKER_PHASE_A) * LAMP_FLICKER_AMP_A \
			+ sin(_time * LAMP_FLICKER_FREQ_B + i) * LAMP_FLICKER_AMP_B
		builder.lamps[i].light_energy = _lamp_base[i] * (1.0 + flicker)
	if boss_sprite:
		boss_sprite.frame = int(_time * BOSS_ANIM_FPS) % BOSS_SPRITE_FRAMES
	hud_gold.text = "%d G" % Game.gold
	var target = _find_interactable()
	for npc in npcs:
		npc.show_bubble(is_same(npc, target) and player.controls_enabled)


func _unhandled_input(event: InputEvent) -> void:
	if status_panel.visible:
		if event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
			get_viewport().set_input_as_handled()
			status_panel.visible = false
			busy = false
			player.controls_enabled = true
		return
	if busy or not player.controls_enabled:
		return
	if event.is_action_pressed("accept"):
		var target = _find_interactable()
		if target != null:
			get_viewport().set_input_as_handled()
			_interact(target)
	elif event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_open_status()


# --------------------------------------------------------------------------
# Interaction
# --------------------------------------------------------------------------

func _find_interactable() -> Variant:
	var best: Variant = null
	var best_dist := INTERACT_REACH
	var facing := player.facing_vector3()
	var candidates := []
	for npc in npcs:
		candidates.append([npc, npc.global_position])
	if boss:
		candidates.append([boss, boss.global_position])
	for cell in builder.chests:
		candidates.append([cell, MapData.cell_center(cell)])
	for s in MapData.SIGNS:
		candidates.append([s, MapData.cell_center(s.cell)])
	for c in candidates:
		var d: Vector3 = c[1] - player.global_position
		d.y = 0
		var reach := best_dist + (BOSS_EXTRA_REACH if is_same(c[0], boss) else 0.0)
		var dist := d.length()
		if dist > reach:
			continue
		if dist > INTERACT_FACING_MIN_DIST and facing.dot(d.normalized()) < INTERACT_FACING_DOT:
			continue
		if dist < reach:
			best = c[0]
			best_dist = min(dist, best_dist)
	return best


func _interact(target: Variant) -> void:
	busy = true
	player.controls_enabled = false
	player.sprite.walking = false
	if target is NPC:
		await _talk_to(target)
	elif boss != null and is_same(target, boss):
		await _confront_boss()
	elif target is Vector2i:
		await _open_chest(target)
	elif target is Dictionary:
		await dialogue.say("", target.text)
	if not get_meta("in_battle", false):
		busy = false
		player.controls_enabled = true


func _talk_to(npc: NPC) -> void:
	npc.talking = true
	npc.face_towards(player.global_position)
	player.sprite.face_vector(Vector2(npc.global_position.x - player.global_position.x,
		npc.global_position.z - player.global_position.z))
	var n := npc.display_name
	match npc.npc_id:
		"elder":
			if Game.has_flag("boss_defeated"):
				await dialogue.say(n, [
					"You did it! The shrine's light shines over the meadow once more.",
					"Lumen Hollow owes you everything, young ones. Stay as long as you like.",
				])
			else:
				Game.set_flag("quest_started")
				await dialogue.say(n, [
					"Aren, Lyra, Kit... thank the stars you're here.",
					"A monstrous [color=#7aa0ff]King Slime[/color] has oozed into the Old Shrine north of the meadow.",
					"Its gloom is drawing monsters into the tall grass. Travelers can't even reach the bridge!",
					"Its hide is weak to [color=#e0e0e0]blades[/color], [color=#ff7a3d]fire[/color] and [color=#fff4c2]holy light[/color].",
					"Strike its weaknesses to [color=#ffd36b]Break[/color] its guard, then [color=#ffa040]Boost[/color] your attacks while it reels.",
					"Rest at Rosa's inn and stock up at Tobin's before you go.",
				])
		"innkeeper":
			var choice := await dialogue.say(n, [
				"Welcome to the Sleeping Fox! Heroes stay free of charge, of course.",
				"Would you like to rest?",
			], ["Rest", "Not now"])
			if choice == 0:
				await _rest()
				await dialogue.say(n, ["Good morning! You look ready for anything."])
		"merchant":
			await _shop(n)
		"child":
			await dialogue.say(n, [
				"Did you know? Every turn in battle you store up [color=#ffa040]Boost Points[/color]!",
				"Press [color=#ffd36b]E[/color] before choosing an action to spend them. Attack more times, or make skills way stronger!",
				"Press [color=#ffd36b]Q[/color] to take some back. I'm gonna be a hero too someday!",
			])
		"guard":
			if Game.has_flag("boss_defeated"):
				await dialogue.say(n, ["The meadow's calmer already. Fine work, all of you."])
			else:
				await dialogue.say(n, [
					"Halt! ...Oh, it's you three. The meadow's crawling with monsters.",
					"Each monster carries a [color=#c8d0e0]shield[/color]. Hit it with something it's weak to and the shield cracks.",
					"Bring it to zero and it [color=#ffd36b]BREAKS[/color]: it loses its next turn and takes double damage.",
					"Weaknesses you discover show up above the monster. Mix your weapons and spells!",
				])
		"fisher":
			await dialogue.say(n, [
				"Shh... the river fish are skittish today.",
				"Monsters only bother folk walking through the [color=#9ad66a]tall grass[/color]. Stick to the path if you're weary.",
				"Hold [color=#ffd36b]Shift[/color] to hurry along, young'un.",
			])
		_:
			await dialogue.say(n, ["..."])
	npc.talking = false


func _rest() -> void:
	var fade := ColorRect.new()
	fade.color = REST_FADE_COLOR
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, REST_FADE_TIME)
	await tw.finished
	Game.heal_party()
	await get_tree().create_timer(REST_HOLD_TIME).timeout
	tw = create_tween()
	tw.tween_property(fade, "color:a", 0.0, REST_FADE_TIME)
	await tw.finished
	fade.queue_free()


func _shop(n: String) -> void:
	var first := true
	while true:
		var choices := []
		for entry in STOCK:
			choices.append("%s  (%d G)" % [BattleData.ITEMS[entry[0]].name, entry[1]])
		choices.append("Leave")
		var greeting := "Welcome! Have a look - finest curatives this side of the river." if first \
			else "Anything else? You have %d G." % Game.gold
		first = false
		var choice := await dialogue.say(n, [greeting], choices)
		if choice < 0 or choice >= STOCK.size():
			await dialogue.say(n, ["Safe travels!"])
			return
		var item_id: String = STOCK[choice][0]
		var price: int = STOCK[choice][1]
		if Game.gold < price:
			await dialogue.say(n, ["Ah... you're a little short on coin, friend."])
		else:
			Game.add_gold(-price)
			Game.add_item(item_id)
			await dialogue.say(n, ["One %s. Thank you kindly! (Owned: %d)" % [
				BattleData.ITEMS[item_id].name, Game.inventory[item_id]]])


func _chest_flag(cell: Vector2i) -> String:
	return "chest_%d_%d" % [cell.x, cell.y]


func _open_chest(cell: Vector2i) -> void:
	var flag := _chest_flag(cell)
	if Game.has_flag(flag):
		await dialogue.say("", ["The chest is empty."])
		return
	Game.set_flag(flag)
	builder.chests[cell].frame = CHEST_OPEN_FRAME
	var loot: Dictionary = MapData.CHESTS.get(cell, DEFAULT_CHEST_LOOT)
	Game.add_item(loot.item, loot.count)
	await dialogue.say("", ["Found [color=#ffd36b]%s x%d[/color]!" % [BattleData.ITEMS[loot.item].name, loot.count]])


func _confront_boss() -> void:
	var choice := await dialogue.say("King Slime", [
		"BLORP... Tiny morsels wander into MY shrine?",
		"This sacred light tastes delicious. I shall gobble up your village next!",
	], ["Fight!", "Retreat for now"])
	if choice == 0:
		_start_battle(["king_slime"], true)


func _open_status() -> void:
	busy = true
	player.controls_enabled = false
	player.sprite.walking = false
	for child in status_panel.get_children():
		child.queue_free()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", STATUS_SEPARATION)
	status_panel.add_child(vb)
	vb.add_child(UITheme.label("Party", UITheme.FONT_HEADING, UITheme.GOLD))
	for m in Game.party:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", STATUS_ROW_SEPARATION)
		var name_l := UITheme.label(m.display_name, UITheme.FONT_LARGE)
		name_l.custom_minimum_size = STATUS_NAME_MIN_SIZE
		row.add_child(name_l)
		row.add_child(UITheme.label("Lv %d" % m.level, UITheme.FONT_BODY, UITheme.GOLD))
		row.add_child(UITheme.label("HP %d/%d" % [m.hp, m.max_hp], UITheme.FONT_BODY, UITheme.HP_COLOR))
		row.add_child(UITheme.label("SP %d/%d" % [m.sp, m.max_sp], UITheme.FONT_BODY, UITheme.SP_COLOR))
		row.add_child(UITheme.label("ATK %d  MAG %d  DEF %d  SPD %d" % [m.atk, m.mag, m.def, m.spd], UITheme.FONT_SMALL, UITheme.DIM))
		vb.add_child(row)
	vb.add_child(HSeparator.new())
	vb.add_child(UITheme.label("Items", UITheme.FONT_HEADING, UITheme.GOLD))
	for id in Game.inventory:
		if Game.inventory[id] > 0:
			vb.add_child(UITheme.label("%s  x%d   - %s" % [BattleData.ITEMS[id].name, Game.inventory[id],
				BattleData.ITEMS[id].desc], UITheme.FONT_MEDIUM))
	vb.add_child(HSeparator.new())
	vb.add_child(UITheme.label("Gold: %d G" % Game.gold, UITheme.FONT_BODY, UITheme.GOLD))
	var objective := "Defeat the King Slime in the Old Shrine (north)." if not Game.has_flag("boss_defeated") \
		else "Peace has returned to Lumen Hollow."
	vb.add_child(UITheme.label("Goal: " + objective, UITheme.FONT_MEDIUM, UITheme.TEXT))
	status_panel.visible = true


# --------------------------------------------------------------------------
# Encounters
# --------------------------------------------------------------------------

func _new_encounter_threshold() -> void:
	_encounter_meter = 0.0
	_encounter_threshold = _rng.randf_range(ENCOUNTER_THRESHOLD_MIN, ENCOUNTER_THRESHOLD_MAX)


func _on_player_moved(distance: float) -> void:
	if busy:
		return
	var cell := MapData.world_to_cell(player.global_position)
	if MapData.cell(cell.x, cell.y) != ",":
		return
	_encounter_meter += distance
	if _encounter_meter >= _encounter_threshold:
		var group: Array = BattleData.ENCOUNTERS[_rng.randi_range(0, BattleData.ENCOUNTERS.size() - 1)]
		_start_battle(group.duplicate(), false)


func _start_battle(enemy_ids: Array, is_boss: bool) -> void:
	busy = true
	set_meta("in_battle", true)
	player.controls_enabled = false
	player.sprite.walking = false
	battle_requested.emit(enemy_ids, is_boss)


## Called by Main after returning from a battle.
func on_battle_finished(result: String, was_boss: bool) -> void:
	set_meta("in_battle", false)
	busy = false
	_new_encounter_threshold()
	camera.current = true
	camera.snap()
	if result == "lose":
		Game.heal_party()
		player.global_position = MapData.cell_center(INN_RESPAWN_CELL)
		player.sprite.facing = CharacterSprite.Facing.DOWN
		camera.snap()
		busy = true
		await dialogue.say("Innkeeper Rosa", [
			"Oh my! The guard carried you all back here, battered and bruised.",
			"You've rested up now. Please be careful out there!",
		])
		busy = false
	elif result == "win" and was_boss:
		Game.set_flag("boss_defeated")
		if boss:
			boss.queue_free()
			boss = null
			boss_sprite = null
		busy = true
		await banner.show_text("The Shrine is Cleansed", "Peace returns to Lumen Hollow", VICTORY_BANNER_HOLD)
		await dialogue.say("", [
			"With the King Slime defeated, warm light spills from the Old Shrine across the meadow.",
			"Thank you for playing! Feel free to keep exploring and battling in the tall grass.",
		])
		busy = false
	player.controls_enabled = true
