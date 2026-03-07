extends Camera2D
class_name God

@export var drag_sensitivity := 0.5
@export var drag_smooth := 10.0
@export var zoom_sensitivity := 0.05
@export var zoom_max := Vector2(1.0, 1.0)
@export var zoom_min := Vector2(0.01, 0.01)
@export var zoom_smooth := 5.0
@export var selector_radius := 50.0

@export var selector: Area2D
@export var towards_point: Node2D
@export var away_point: Node2D

var drag_desired := global_position
var zoom_desired := zoom
var selected_units: Array[Unit] = []
var selected_anything := false
var deselecting := false
var can_select := true
var last_selected: Interactable

@onready var selector_shape: CircleShape2D = selector.get_node("CollisionShape2D").shape
@onready var selector_visualizer: Polygon2D = selector.get_node("Polygon2D")


func _ready() -> void: Global.camera = self


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("mouse3"):
			var zoom_factor := maxf(inverse_lerp(zoom_min.length(), zoom_max.length(), zoom_desired.length()), 0.1)
			drag_desired -= event.screen_relative * drag_sensitivity * (1/zoom_factor)


func _process(delta: float) -> void:
	selection()
	commanding()
	camera_move(delta)
	
	if Input.is_action_just_pressed("tab"): can_select = !can_select
	away_point.global_position = get_global_mouse_position()
	selector_shape.radius = selector_radius * (1/zoom.x) 
	selector_visualizer.scale = Vector2(1/zoom.x, 1/zoom.y)


func _physics_process(_delta: float) -> void:
	if not selector.monitoring: return
	for body in selector.get_overlapping_bodies():
		if body is Unit:
			if deselecting and selected_units.has(body):
				selected_units.erase(body)
				body.selected(false)
			if not deselecting and not selected_units.has(body):
				selected_units.append(body)
				body.freed.connect(_on_unit_freed)
				body.selected(true)
			selected_anything = true


func selection() -> void:
	selector.position = get_local_mouse_position()
	
	if not can_select: return
	
	if Input.is_action_pressed("a"):
		for unit in get_tree().get_nodes_in_group("Units"):
			if unit is Unit and not selected_units.has(unit):
				selected_anything = true
				selected_units.append(unit)
				if not unit.freed.is_connected(_on_unit_freed):
					unit.freed.connect(_on_unit_freed)
				unit.selected(true)
	
	if Input.is_action_just_released("space") and not selected_anything:
		for unit in selected_units:
			#if is_instance_valid(unit):
			unit.selected(false) 
		selected_units = []
	elif not Input.is_action_pressed("space"): 
		selected_anything = false
		deselecting = false
		selector.get_node("Polygon2D").visible = false
		selector.monitoring = false
		return
	selector.monitoring = Input.is_action_pressed("mouse1") or Input.is_action_pressed("mouse2")
	selector.get_node("Polygon2D").visible = true
	#if Input.is_action_just_pressed("mouse1"): selected_anything = false
	#elif Input.is_action_just_released("mouse1") and not selected_anything:
		#for unit in selected_units: unit.selected(false)
		#selected_units = []
		##print(selected_units) 
	deselecting = Input.is_action_pressed("mouse2")


func commanding() -> void:
	if Input.is_action_pressed("space") or Input.is_action_pressed("control"):
		away_point.visible = false
		towards_point.visible = false
		return
	
	if Input.is_action_pressed("mouse1") and Input.is_action_pressed("shift"):
		for unit in selected_units: 
			#if is_instance_valid(unit):
			unit.move_away_from(get_global_mouse_position())
		away_point.visible = true
		towards_point.visible = false
	elif Input.is_action_pressed("mouse1"):
		for unit in selected_units:
			#if is_instance_valid(unit):
			unit.move_to(get_global_mouse_position())
		towards_point.visible = true
		away_point.visible = false
		towards_point.global_position = get_global_mouse_position()
	#if (Input.is_action_just_released("mouse1") and Input.is_action_pressed("shift")) or (Input.is_action_pressed("mouse1") and Input.is_action_just_released("shift")) or (Input.is_action_just_released("mouse1") and Input.is_action_just_released("shift")):
	else:
		#for unit in selected_units: unit.stop_moving_away()
		away_point.visible = false
		towards_point.visible = false

   
func camera_move(delta: float) -> void:
	var zoom_dir := 0
	if Input.is_action_just_released("wheel_up"): zoom_dir += 1
	elif Input.is_action_just_released("wheel_down"): zoom_dir -= 1
	
	#var old_mouse_pos := get_global_mouse _position()
	zoom_desired = (zoom_desired + (Vector2.ONE * zoom_sensitivity * zoom_dir)).clamp(zoom_min, zoom_max)
	zoom = Global.decay_towards_vec2(zoom, zoom_desired, zoom_smooth, delta)
	#global_position += old_mouse_pos - get_global_mouse_position()
	
	#if not zoom_dir == 0:
		#drag_desired += old_mouse_pos - get_global_mouse_position()
	#global_position += old_mouse_pos - get_global_mouse_position()
	global_position = Global.decay_towards_vec2(global_position, drag_desired, drag_smooth, delta)


func select_interactable(object: Interactable) -> void:
	var units_to_remove: Array[Unit] = []
	for unit in selected_units:
		#if not is_instance_valid(unit): continue
		if unit.current_item == object.item: continue
		if not unit.current_item == Unit.ITEM.NONE and not object.is_in_group("Banks"): continue
		units_to_remove.append(unit)
	for unit in units_to_remove:
		unit.set_goal(object)
		selected_units.erase(unit)
		unit.selected(false)


func _on_unit_freed(unit: Unit) -> void:
	selected_units.erase(unit)
	#var units_to_remove: Array[Unit] = []
	#for unit in selected_units:
		#if not is_instance_valid(unit):
			#units_to_remove.append(unit)
	#for unit in units_to_remove:
		#selected_units.erase(unit)


#func _on_selector_body_entered(body: Node2D) -> void:
	#if body is Unit:
		#if deselecting:
			#selected_units.erase(body)
			#body.selected(false)
			#print(selected_units)
		#else:
			#selected_units.append(body)
			#body.selected(true)
			#print(selected_units)
		#selected_anything = true
