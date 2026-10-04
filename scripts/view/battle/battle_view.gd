class_name BattleView
extends Node3D
## Visual side of a battle. Builds the stage and combatant sprites, and replays the
## BattleEvents produced by the logic layer as animations, popups and HUD updates.

const PARTY_SLOTS := [Vector3(2.6, 0, -1.9), Vector3(4.2, 0, -0.2), Vector3(2.9, 0, 1.5)]
const ENEMY_SLOTS := {
	1: [Vector3(-3.2, 0, 0.0)],
	2: [Vector3(-2.8, 0, -1.2), Vector3(-3.8, 0, 1.1)],
	3: [Vector3(-2.4, 0, -2.0), Vector3(-4.6, 0, -0.4), Vector3(-2.8, 0, 1.4)],
}
## Enemy groups larger than this reuse the largest ENEMY_SLOTS layout.
const MAX_ENEMY_LAYOUT := 3
const BOSS_SLOT := Vector3(-3.8, 0, -0.4)
const UI_CANVAS_LAYER := 2

# Event playback
## Bursts on a combatant spawn around its chest.
const BURST_OFFSET := Vector3(0, 0.7, 0)
const CAST_BURST_OFFSET := Vector3(0, 0.4, 0)
const CAST_BURST_STRENGTH := 0.5
const DEATH_BURST_OFFSET := Vector3(0, 0.5, 0)
## Visual element for attacks that have none of their own (monster skills).
const DEFAULT_SPELL_ELEMENT := "dark"
const HIT_SHAKE := 0.08
const BREAK_SHAKE := 0.35
const WEAK_HIT_COLOR := Color(1.0, 0.92, 0.4)
const HEAL_POPUP_COLOR := Color(0.5, 1.0, 0.55)
const HIT_INTERVAL := 0.12
const HEAL_INTERVAL := 0.35
const BREAK_PAUSE := 0.6
const ACTION_END_PAUSE := 0.3
## Reading time for narration-only actions (Defend, Flee).
const MESSAGE_READ_TIME := 0.75
# Sound pitch tweaks (pitch scale)
const SP_RESTORE_PITCH := 1.3
const REVIVE_PITCH := 0.8

var stage: BattleStage
var effects: BattleEffects
var cursor: TargetCursor
var ui: BattleUI
var banner: Banner
var _actors := {}
var _time := 0.0


func build(model: BattleModel) -> void:
	stage = BattleStage.new()
	add_child(stage)
	stage.build(model.is_boss)
	for i in model.party.size():
		var m := model.party[i]
		_add_actor(BattleActorView.for_party(m, PARTY_SLOTS[i]))
		if not m.is_alive():
			view_of(m).set_down(true)
	var slots: Array = ENEMY_SLOTS[clampi(model.enemies.size(), 1, MAX_ENEMY_LAYOUT)]
	for i in model.enemies.size():
		var slot: Vector3 = BOSS_SLOT if model.is_boss else slots[i]
		_add_actor(BattleActorView.for_enemy(model.enemies[i], slot))
	effects = BattleEffects.new()
	add_child(effects)
	cursor = TargetCursor.new()
	add_child(cursor)

	var layer := CanvasLayer.new()
	layer.layer = UI_CANVAS_LAYER
	add_child(layer)
	ui = BattleUI.new()
	layer.add_child(ui)
	ui.setup(model.party, model.enemies, stage.camera, func(c: Combatant) -> Vector3: return view_of(c).position())
	banner = Banner.new()
	layer.add_child(banner)


func view_of(c: Combatant) -> BattleActorView:
	return _actors[c]


func views_of(list: Array) -> Array[BattleActorView]:
	var out: Array[BattleActorView] = []
	for c in list:
		out.append(view_of(c))
	return out


func _add_actor(view: BattleActorView) -> void:
	_actors[view.combatant] = view
	add_child(view.sprite)


func _process(delta: float) -> void:
	_time += delta
	for view in _actors.values():
		view.animate(_time)


func refresh_status() -> void:
	for view in _actors.values():
		view.update_status_tint()
	ui.refresh()


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Shows a line in the message box for `seconds`, then hides it.
func announce(text: String, seconds: float) -> void:
	ui.show_message(text)
	await wait(seconds)
	ui.hide_message()


# --------------------------------------------------------------------------
# Event playback
# --------------------------------------------------------------------------

## Animates a list of events from one action, in order.
func play(events: Array[BattleEvent]) -> void:
	var narration_only := events.all(func(e): return e.type == BattleEvent.Type.MESSAGE)
	for e in events:
		await _play_event(e)
		if narration_only:
			await wait(MESSAGE_READ_TIME)
		ui.refresh()
	ui.hide_message()


func _play_event(e: BattleEvent) -> void:
	match e.type:
		BattleEvent.Type.MESSAGE:
			ui.show_message(e.text)
		BattleEvent.Type.ACTION_START:
			var actor := view_of(e.actor)
			if e.motion == BattleEvent.Motion.LUNGE and e.target:
				Audio.play_sfx(&"swing")
				await actor.lunge_toward(view_of(e.target).position())
			elif e.motion == BattleEvent.Motion.CAST:
				Audio.play_sfx(&"spell", SfxLibrary.spell_pitch_scale(e.element))
				effects.burst(actor.position() + CAST_BURST_OFFSET, _spell_element(e.element), CAST_BURST_STRENGTH)
				await actor.cast_hop()
		BattleEvent.Type.ACTION_END:
			if e.motion == BattleEvent.Motion.LUNGE:
				await view_of(e.actor).return_to_rest()
			await wait(ACTION_END_PAUSE)
		BattleEvent.Type.HIT:
			var target := view_of(e.target)
			if e.from_skill:
				effects.burst(target.position() + BURST_OFFSET, _spell_element(e.element))
			Audio.play_sfx(&"weak_hit" if e.weak else &"hit")
			effects.popup(target.position(), str(e.amount), WEAK_HIT_COLOR if e.weak else Color.WHITE, e.weak)
			target.flash_hit()
			stage.shake(HIT_SHAKE)
			await wait(HIT_INTERVAL)
		BattleEvent.Type.SHIELD_BREAK:
			var target := view_of(e.target)
			Audio.play_sfx(&"break")
			stage.shake(BREAK_SHAKE)
			effects.break_callout(target.position())
			effects.burst(target.position() + BURST_OFFSET, "break")
			target.update_status_tint()
			await wait(BREAK_PAUSE)
		BattleEvent.Type.DEFEATED:
			var target := view_of(e.target)
			Audio.play_sfx(&"enemy_down" if e.target.is_enemy else &"party_down")
			if e.target.is_enemy:
				effects.burst(target.position() + DEATH_BURST_OFFSET, "death")
			await target.play_defeat()
		BattleEvent.Type.HEAL:
			var target := view_of(e.target)
			Audio.play_sfx(&"heal")
			effects.burst(target.position() + BURST_OFFSET, "heal")
			effects.popup(target.position(), str(e.amount), HEAL_POPUP_COLOR)
			await wait(HEAL_INTERVAL)
		BattleEvent.Type.SP_RESTORE:
			Audio.play_sfx(&"heal", SP_RESTORE_PITCH)
			effects.popup(view_of(e.target).position(), "%d SP" % e.amount, UITheme.SP_COLOR)
		BattleEvent.Type.BP_GAIN:
			var target := view_of(e.target)
			Audio.play_sfx(&"boost")
			effects.burst(target.position() + BURST_OFFSET, "boost")
			effects.popup(target.position(), "+%d BP" % e.amount, UITheme.BP_COLOR)
		BattleEvent.Type.REVIVE:
			Audio.play_sfx(&"heal", REVIVE_PITCH)
			view_of(e.target).set_down(false)


func _spell_element(element: String) -> String:
	return element if element != "" else DEFAULT_SPELL_ELEMENT


func celebrate(c: Combatant) -> void:
	Audio.play_sfx(&"level_up")
	effects.burst(view_of(c).position() + BURST_OFFSET, "boost")
