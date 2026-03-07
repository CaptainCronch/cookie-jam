extends CanvasLayer
class_name UI

enum BUILDINGS {NONE = -1, BANK = 0, VISION = 1, MINE = 2}

const BUILDING_SCENES: Array[PackedScene] = [
	preload("uid://cjyybc2wyh54a"), # bank.tscn
	preload("uid://b64nxffbem5uy"), # vision.tscn
	
]
const BUILDING_COSTS: Array[Dictionary] = [
	{"wood": 5, "clay": 0, "souls": 0, "ash": 0, "glassy_clay": 0},
	{"wood": 0, "clay": 0, "souls": 0, "ash": 0, "glassy_clay": 0},
	{"wood": 60, "clay": 40, "souls": 0, "ash": 0, "glassy_clay": 0},
]

@export var wood_label: Label
@export var clay_label: Label
@export var souls_label: Label
@export var ash_label: Label
@export var glassy_clay_label: Label
@export var build_menu: RadialMenuAdvanced
@export var camera: God
@export var build_preview: Sprite2D

var can_cancel_build := false
var current_building: BUILDINGS = BUILDINGS.NONE
var unlocked_buildings: Array[bool] = [true, true, false, false, false, false, false, false]


func _ready() -> void:
	Global.ui = self


func _process(_delta: float) -> void:
	build_preview.global_position = camera.get_global_mouse_position()
	#build_menu.scale = Vector2(1/camera.zoom.x, 1/camera.zoom.y)
	#(build_menu.material as ShaderMaterial).set_shader_parameter("speed_factor", camera.zoom.x)
	if Input.is_action_just_pressed("mouse1") and Input.is_action_pressed("control"):
		#build_preview.hide()
		build_menu.show()
		build_menu.enabled = true
		build_menu.position = get_viewport().get_mouse_position() - build_menu.size/2 #camera.get_global_transform_with_canvas().origin + camera.get_local_mouse_position()
	if Input.is_action_just_released("mouse1") or Input.is_action_just_released("control") and can_cancel_build:
		#build_preview.hide()
		build_menu.hide()
		build_menu.enabled = false
	if Input.is_action_just_pressed("mouse1") and not current_building == BUILDINGS.NONE and not build_menu.enabled:
		build()


func build() -> void:
	#print(str(current_building))
	if check_cost(current_building) and unlocked_buildings[current_building]:
		var scene := BUILDING_SCENES[current_building].instantiate()
		scene.global_position = camera.get_global_mouse_position()
		get_tree().current_scene.add_child(scene)
	build_preview.hide()
	current_building = BUILDINGS.NONE


func check_cost(building: BUILDINGS) -> bool:
	var costs := BUILDING_COSTS[building]
	if costs.wood > Global.wood or costs.clay > Global.clay or costs.souls > Global.souls or costs.ash > Global.ash or costs.glassy_clay > Global.glassy_clay:
		return false
	Global.wood -= costs.wood
	Global.clay -= costs.clay
	Global.souls -= costs.souls
	Global.ash -= costs.ash
	Global.glassy_clay -= costs.glassy_clay
	Global.refresh_ui()
	return true


func _on_build_menu_slot_selected(slot: Control, index: int) -> void:
	can_cancel_build = false
	build_menu.hide()
	build_menu.enabled = false
	if index > -1:
		build_preview.show()
		build_preview.texture = slot.texture
		current_building = index as BUILDINGS
	else:
		build_preview.hide()
		current_building = BUILDINGS.NONE


func _on_click_check_mouse_entered() -> void: can_cancel_build = true


func _on_click_check_mouse_exited() -> void: can_cancel_build = false
