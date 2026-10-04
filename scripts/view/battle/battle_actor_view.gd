class_name BattleActorView
extends RefCounted
## The on-screen body of one combatant: its sprite, home spot and every animation the
## battle can play on it. Owns no game rules; it only reflects a Combatant's state.

const PX := 1.0 / 16.0

# Sprites
const PARTY_SPRITE_SCALE := 1.05
const ENEMY_SPRITE_SCALE := 1.25
const ENEMY_ANIM_FRAMES := 2
const ENEMY_ANIM_FPS := 2.5
const ENEMY_SPRITE_OFFSET := Vector2(0, 12)
## Flying enemies hover and bob.
const FLYING_ENEMIES := ["bat"]
const HOVER_HEIGHT := 0.6
const HOVER_BOB_SPEED := 4.0
const HOVER_BOB_AMPLITUDE := 0.15
## Sprite height above the origin per unit of sprite scale (for cursors, tags, popups).
const SPRITE_HEIGHT := 1.9

# Turn stepping (party members step toward the enemies while acting)
const STEP_FORWARD := Vector3(-0.6, 0, 0)
const STEP_FORWARD_TIME := 0.15
const STEP_BACK_TIME := 0.2

# Attack motions
## Lunges stop this far short of the target.
const LUNGE_STOP_DISTANCE := 1.4
const LUNGE_TIME := 0.18
const RETURN_TIME := 0.2
const CAST_HOP_HEIGHT := 0.25
const CAST_HOP_TIME := 0.15

# Reactions
const HIT_FLASH_COLOR := Color(1.0, 0.35, 0.35)
const HIT_FLASH_TIME := 0.25
const HIT_JITTER_STEPS := 4
const HIT_JITTER_DISTANCE := 0.08
const HIT_JITTER_STEP_TIME := 0.03
const BROKEN_TINT := Color(0.65, 0.7, 1.0)

# Knock-out
const DOWN_ROTATION_DEG := 90.0
const DOWN_OFFSET := Vector3(0.3, 0.15, 0)
const DOWN_TINT := Color(0.6, 0.5, 0.6)
const PARTY_DOWN_TIME := 0.25
const DEATH_FADE_COLOR := Color(1.5, 0.4, 0.8, 0.0)
const DEATH_SQUASH_SCALE := Vector3(1.3, 0.1, 1.0)
const DEATH_FADE_TIME := 0.5

var combatant: Combatant
var sprite: SpriteBase3D
var home := Vector3.ZERO
var stepped_forward := false
var _anim_phase := 0.0


static func for_party(member: Combatant, slot: Vector3) -> BattleActorView:
	var view := BattleActorView.new()
	view.combatant = member
	var spr := CharacterSprite.new()
	spr.setup(member.sprite_id)
	spr.facing = CharacterSprite.Facing.LEFT
	spr.pixel_size = PX * PARTY_SPRITE_SCALE
	view.sprite = spr
	view.home = slot
	spr.position = slot
	return view


static func for_enemy(enemy: Combatant, slot: Vector3) -> BattleActorView:
	var view := BattleActorView.new()
	view.combatant = enemy
	var spr := Sprite3D.new()
	spr.texture = SpriteFactory.enemy_sheet(enemy.sprite_id)
	spr.hframes = ENEMY_ANIM_FRAMES
	spr.pixel_size = PX * ENEMY_SPRITE_SCALE * enemy.sprite_scale
	spr.offset = ENEMY_SPRITE_OFFSET
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.shaded = true
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if FLYING_ENEMIES.has(enemy.id):
		slot.y = HOVER_HEIGHT
	view.sprite = spr
	view.home = slot
	view._anim_phase = enemy.max_hp
	spr.position = slot
	return view


func position() -> Vector3:
	return sprite.global_position


## Top of the sprite, for cursors and labels.
func head_position() -> Vector3:
	var scale_factor := combatant.sprite_scale if combatant.is_enemy else 1.0
	return position() + Vector3(0, SPRITE_HEIGHT * scale_factor, 0)


## Where the actor stands between motions (home, or one step forward while acting).
func rest_position() -> Vector3:
	return home + (STEP_FORWARD if stepped_forward else Vector3.ZERO)


## Idle animation for enemies (frame flip and hovering).
func animate(time: float) -> void:
	if not combatant.is_enemy or not combatant.is_alive():
		return
	(sprite as Sprite3D).frame = int(time * ENEMY_ANIM_FPS + _anim_phase) % ENEMY_ANIM_FRAMES
	if FLYING_ENEMIES.has(combatant.id):
		sprite.position.y = home.y + sin(time * HOVER_BOB_SPEED + _anim_phase) * HOVER_BOB_AMPLITUDE


func step_forward() -> void:
	if combatant.is_enemy:
		return
	stepped_forward = true
	_tween_to(rest_position(), STEP_FORWARD_TIME)


func step_back() -> void:
	if not stepped_forward:
		return
	stepped_forward = false
	_tween_to(rest_position(), STEP_BACK_TIME)


func lunge_toward(target_pos: Vector3) -> void:
	var start := sprite.position
	var dir := target_pos - start
	dir.y = 0
	var dest: Vector3 = start + dir.normalized() * max(dir.length() - LUNGE_STOP_DISTANCE, 0.0)
	var tw := _tween_to(dest, LUNGE_TIME, Tween.EASE_OUT)
	await tw.finished


func return_to_rest() -> void:
	var tw := _tween_to(rest_position(), RETURN_TIME, Tween.EASE_IN_OUT)
	await tw.finished


func cast_hop() -> void:
	var tw := sprite.create_tween()
	tw.tween_property(sprite, "position:y", sprite.position.y + CAST_HOP_HEIGHT, CAST_HOP_TIME)
	tw.tween_property(sprite, "position:y", sprite.position.y, CAST_HOP_TIME)
	await tw.finished


func flash_hit() -> void:
	var base := sprite.modulate
	sprite.modulate = HIT_FLASH_COLOR
	sprite.create_tween().tween_property(sprite, "modulate", base, HIT_FLASH_TIME)
	var start := sprite.position
	var jitter := sprite.create_tween()
	for i in HIT_JITTER_STEPS:
		var side := 1 if i % 2 == 0 else -1
		jitter.tween_property(sprite, "position", start + Vector3(HIT_JITTER_DISTANCE * side, 0, 0), HIT_JITTER_STEP_TIME)
	jitter.tween_property(sprite, "position", start, HIT_JITTER_STEP_TIME)


## Tints enemies while broken.
func update_status_tint() -> void:
	if combatant.is_enemy and combatant.is_alive():
		sprite.modulate = BROKEN_TINT if combatant.is_broken() else Color.WHITE


## Lays a party member down (or stands them back up when revived).
func set_down(down: bool) -> void:
	stepped_forward = false
	if down:
		sprite.rotation_degrees.z = DOWN_ROTATION_DEG if not combatant.is_enemy else 0.0
		sprite.position = home + DOWN_OFFSET
		sprite.modulate = DOWN_TINT
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	else:
		sprite.rotation_degrees.z = 0.0
		sprite.position = home
		sprite.modulate = Color.WHITE
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


## Knock-out animation: enemies fade and squash away, party members fall over.
func play_defeat() -> void:
	if combatant.is_enemy:
		var tw := sprite.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sprite, "modulate", DEATH_FADE_COLOR, DEATH_FADE_TIME)
		tw.tween_property(sprite, "scale", DEATH_SQUASH_SCALE, DEATH_FADE_TIME)
		await tw.finished
		sprite.visible = false
	else:
		set_down(true)
		await sprite.get_tree().create_timer(PARTY_DOWN_TIME).timeout


func _tween_to(pos: Vector3, time: float, ease_type: Tween.EaseType = Tween.EASE_IN_OUT) -> Tween:
	var tw := sprite.create_tween()
	tw.tween_property(sprite, "position", pos, time).set_trans(Tween.TRANS_QUAD).set_ease(ease_type)
	return tw
