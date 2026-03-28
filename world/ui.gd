extends CanvasLayer
class_name UI

enum BUILDINGS {NONE = -1, PORTAL_SPAWNER = 0, VISION = 1, BANK = 2, PORTAL = 3, MINE = 4, ARBORETUM = 5}

const BUILDING_SCENES: Array[PackedScene] = [
	preload("uid://dstq5xmmf1su8"), # portal_spawner.tscn
	preload("uid://b64nxffbem5uy"), # vision.tscn
	preload("uid://cjyybc2wyh54a"), # bank.tscn
	preload("uid://eikxsl3mu278"),  # portal.tscn
	null,                           # mine!
	preload("uid://dnvxrfb6nrces"), # arboretum.tscn
]
const BUILDING_COSTS: Array[Dictionary] = [
	{"wood": 10, "clay": 0, "souls": 0, "ash": 0, "glassy_clay": 0},
	{"wood": 20, "clay": 0, "souls": 0, "ash": 0, "glassy_clay": 0},
	{"wood": 30, "clay": 10, "souls": 0, "ash": 0, "glassy_clay": 0},
	{"wood": 10, "clay": 20, "souls": 5, "ash": 0, "glassy_clay": 0},
	{"wood": 50, "clay": 10, "souls": 0, "ash": 10, "glassy_clay": 0},
	{"wood": 10, "clay": 50, "souls": 0, "ash": 10, "glassy_clay": 0},
]

@export var unit_label: Label
@export var wood_label: Label
@export var clay_label: Label
@export var souls_label: Label
@export var ash_label: Label
@export var glassy_clay_label: Label
@export var build_menu: RadialMenuAdvanced
@export var camera: God
@export var build_preview: Sprite2D
@export var mine_check: Area2D
@export var info_box: PanelContainer
@export var info_label: Label
@export var victory_text: MarginContainer
@export var controls: MarginContainer
@export var controls_label: Label
@export var negatory: AudioStreamPlayer

var can_cancel_build := false
var current_building: BUILDINGS = BUILDINGS.NONE
var baal: Baal

@onready var unlocked_buildings := [true, true, false, false, false, false] if not Global.CHEATS else [true, true, true, true, true, true]


func _ready() -> void:
	Global.ui = self
	Global.baal_spawned.connect(_on_baal_spawned)


func _process(_delta: float) -> void:
	if is_instance_valid(baal): return
	mine_check.global_position = camera.get_global_mouse_position()
	build_preview.global_position = camera.get_global_mouse_position()
	#build_menu.scale = Vector2(1/camera.zoom.x, 1/camera.zoom.y)
	#(build_menu.material as ShaderMaterial).set_shader_parameter("speed_factor", camera.zoom.x)
	if Input.is_action_just_pressed("mouse1") and Input.is_action_pressed("control"):
		#build_preview.hide()
		var children := build_menu.get_children()
		for i in children.size():
			if i == 0: continue
			if unlocked_buildings[i - 1]:
				children[i].modulate = Color.WHITE
			else:
				children[i].modulate = Color(0.5, 0.5, 0.5, 0.5)
		build_menu.show()
		info_box.show()
		controls.hide()
		build_menu.enabled = true
		build_menu.position = get_viewport().get_mouse_position() - build_menu.size/2 #camera.get_global_transform_with_canvas().origin + camera.get_local_mouse_position()
	if Input.is_action_just_released("mouse1") or Input.is_action_just_released("control") and can_cancel_build:
		#build_preview.hide()
		build_menu.hide()
		info_box.hide()
		controls.show()
		build_menu.enabled = false
	if Input.is_action_just_pressed("mouse1") and not current_building == BUILDINGS.NONE and not build_menu.enabled:
		if current_building == BUILDINGS.MINE:
			for thing in mine_check.get_overlapping_areas():
				if thing is ClayDeposit:
					if thing.dead:
						if check_cost(current_building) and unlocked_buildings[current_building]:
							thing.revive()
						else:
							negatory.play()
			build_preview.hide()
			current_building = BUILDINGS.NONE
			return
		build()


func build() -> void:
	#print(str(current_building))
	if check_cost(current_building) and unlocked_buildings[current_building]:
		var scene := BUILDING_SCENES[current_building].instantiate()
		scene.global_position = camera.get_global_mouse_position()
		get_tree().current_scene.add_child(scene)
	else:
		negatory.play()
	build_preview.hide()
	current_building = BUILDINGS.NONE


func check_cost(building: BUILDINGS) -> bool:
	if Global.CHEATS: return true
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
	if index > -1 and unlocked_buildings[index]:
		build_preview.show()
		build_preview.texture = slot.texture
		if index == 1: build_preview.scale = Vector2(2.0, 2.0)
		else: build_preview.scale = Vector2(1.0, 1.0)
		current_building = index as BUILDINGS
	else:
		build_preview.hide()
		current_building = BUILDINGS.NONE
		negatory.play()


func _on_click_check_mouse_entered() -> void: can_cancel_build = true


func _on_click_check_mouse_exited() -> void: can_cancel_build = false


func _on_build_menu_selection_changed(new_selection: int) -> void:
	match new_selection:
		-1:
			info_label.text = "Cancel selection."
		0:
			info_label.text = "Minor Gateway. Spawns demons. Requires 10 wood."
		1:
			info_label.text = "Vision Beacon. Grants sight over an area. Requires 20 wood."
		2:
			info_label.text = "Collector. Allows collection anywhere. Requires 30 wood and 10 clay."
		3:
			info_label.text = "Major Gateway. Increases demon limit. Requires 10 wood, 20 clay, and 5 souls."
		4:
			info_label.text = "Mine. Place over depleted clay deposit. Requires 50 wood, 10 clay, and 10 ash."
		5:
			info_label.text = "Arboretum. Grows trees. Requires 10 wood, 50 clay, and 10 ash."


func _on_baal_spawned() -> void:
	build_menu.hide()
	info_box.hide()
	controls.show()
	controls_label.text = "Scroll wheel - Zoom\nWASD / Arrow keys - Move\nLeft click - Incinerate"
	build_menu.enabled = false
	build_preview.hide()
	baal = Global.baal
