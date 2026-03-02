extends Camera2D

@export var drag_sensitivity := 0.5
@export var drag_smooth := 10.0
@export var zoom_sensitivity := 0.05
@export var zoom_max := Vector2(1.0, 1.0)
@export var zoom_min := Vector2(0.2, 0.2)
@export var zoom_smooth := 5.0

@export var selector: Area2D

var drag_desired := global_position
var zoom_desired := zoom
var selected_units: Array[Unit] = []
var selected_anything := false
var deselecting := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("mouse3"):
			var zoom_factor := maxf(inverse_lerp(zoom_min.length(), zoom_max.length(), zoom_desired.length()), 0.1)
			drag_desired -= event.screen_relative * drag_sensitivity * (1/zoom_factor)


func _process(delta: float) -> void:
	selection()
	commanding()
	camera_move(delta)


func selection() -> void:
	selector.position = get_local_mouse_position() 
	if not Input.is_action_pressed("space"):
		deselecting = false
		selector.get_node("Polygon2D").visible = false
		return
	selector.monitoring = Input.is_action_pressed("mouse1") or Input.is_action_pressed("mouse2")
	selector.get_node("Polygon2D").visible = true
	if Input.is_action_just_pressed("mouse1"): selected_anything = false
	elif Input.is_action_just_released("mouse1") and not selected_anything:
		for unit in selected_units: unit.selected(false)
		selected_units = []
	deselecting = Input.is_action_pressed("mouse2")


func commanding() -> void:
	if Input.is_action_pressed("space") or Input.is_action_pressed("shift") or Input.is_action_pressed("control"):
		return
	
	if Input.is_action_pressed("mouse2"):
		for unit in selected_units: unit.move_away_from(get_global_mouse_position())
	elif Input.is_action_pressed("mouse1"):
		for unit in selected_units: unit.move_to(get_global_mouse_position())
	if Input.is_action_just_released("mouse2"): 
		for unit in selected_units: unit.stop_moving_away()

   
func camera_move(delta: float) -> void:
	var zoom_dir := 0
	if Input.is_action_just_released("wheel_up"): zoom_dir += 1
	elif Input.is_action_just_released("wheel_down"): zoom_dir -= 1
	
	zoom_desired = (zoom_desired + (Vector2.ONE * zoom_sensitivity * zoom_dir)).clamp(zoom_min, zoom_max)
	zoom = Global.decay_towards_vec2(zoom, zoom_desired, zoom_smooth, delta)
	
	global_position = Global.decay_towards_vec2(global_position, drag_desired, drag_smooth, delta)


func _on_selector_body_entered(body: Node2D) -> void:
	if body is Unit:
		if deselecting:
			selected_units.erase(body)
			body.selected(false)
		else: 
			selected_units.append(body)
			body.selected(true)
		selected_anything = true
