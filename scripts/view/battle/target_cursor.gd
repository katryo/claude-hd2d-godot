class_name TargetCursor
extends Label3D
## Bouncing arrow over the targeted combatant (or "ALL" over a whole group).

const FONT_SIZE := 80
const OUTLINE_SIZE := 18
const PIXEL_SIZE := 0.006
const COLOR := Color(1.0, 0.85, 0.35)
const SINGLE_TEXT := "▼"
const ALL_TEXT := "▼ ALL ▼"
const CLEARANCE := 0.35
const ALL_OFFSET := Vector3(0, 2.4, 0)
const BOB_SPEED := 6.0
const BOB_AMPLITUDE := 0.08

var _targets: Array[BattleActorView] = []
var _index := 0
var _all := false
var _time := 0.0


func _ready() -> void:
	font_size = FONT_SIZE
	outline_size = OUTLINE_SIZE
	pixel_size = PIXEL_SIZE
	modulate = COLOR
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	visible = false


func point_at(target: BattleActorView) -> void:
	_targets = [target]
	_index = 0
	_all = false
	text = SINGLE_TEXT
	visible = true


func point_at_all(targets: Array[BattleActorView]) -> void:
	_targets = targets
	_all = true
	text = ALL_TEXT
	visible = true


func dismiss() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible or _targets.is_empty():
		return
	_time += delta
	if _all:
		var center := Vector3.ZERO
		for t in _targets:
			center += t.position()
		global_position = center / _targets.size() + ALL_OFFSET
	else:
		var bob := sin(_time * BOB_SPEED) * BOB_AMPLITUDE
		global_position = _targets[_index].head_position() + Vector3(0, CLEARANCE + bob, 0)
