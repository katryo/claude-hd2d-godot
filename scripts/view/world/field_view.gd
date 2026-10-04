class_name FieldView
extends Node3D
## Visual side of the overworld: the diorama, lighting, follow camera, ambient effects
## and the exploration UI (HUD, status window, dialogue box, banners).

const UI_LAYER := 2
const CHEST_OPEN_FRAME := 1

# Camera bounds (world units inset from the map edges)
const CAMERA_MARGIN_X := 9.0
const CAMERA_MARGIN_TOP := 4.0
const CAMERA_MARGIN_BOTTOM := 3.0

# Ambient motes around the player
const MOTES_EXTENTS := Vector3(12, 2.5, 9)
const MOTES_OFFSET := Vector3(0, 1.5, -2)

var builder := WorldBuilder.new()
var camera: FollowCamera
var ui: CanvasLayer
var hud: FieldHUD
var status_panel: StatusPanel
var dialogue: DialogueBox
var banner: Banner
var fade: ScreenFade


func build() -> void:
	builder.build(self)
	add_child(LampFlicker.new(builder.lamps))
	add_child(Visuals.make_sun("field"))
	add_child(Visuals.make_environment("field"))
	camera = FollowCamera.new()
	camera.attributes = Visuals.make_camera_attributes(camera.distance)
	camera.bounds = Rect2(CAMERA_MARGIN_X, CAMERA_MARGIN_TOP,
		MapData.width() - CAMERA_MARGIN_X * 2, MapData.depth() - CAMERA_MARGIN_TOP - CAMERA_MARGIN_BOTTOM)
	add_child(camera)
	_build_ui()


## Points the camera at the player and attaches the floating motes to them.
func follow(target: Node3D) -> void:
	camera.target = target
	camera.current = true
	camera.snap()
	var motes := Visuals.make_motes(MOTES_EXTENTS)
	motes.position = MOTES_OFFSET
	target.add_child(motes)


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = UI_LAYER
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	ui.add_child(root)
	hud = FieldHUD.new()
	root.add_child(hud)
	status_panel = StatusPanel.new()
	root.add_child(status_panel)
	dialogue = DialogueBox.new()
	root.add_child(dialogue)
	banner = Banner.new()
	root.add_child(banner)
	fade = ScreenFade.new()
	root.add_child(fade)


func set_ui_visible(on: bool) -> void:
	ui.visible = on


func set_chest_open(cell: Vector2i) -> void:
	if builder.chests.has(cell):
		builder.chests[cell].frame = CHEST_OPEN_FRAME


func chest_cells() -> Array:
	return builder.chests.keys()


func reactivate_camera() -> void:
	camera.current = true
	camera.snap()
