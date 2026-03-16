extends Camera2D
class_name God

const ZOOM_IN = preload("uid://cpjgfi8uqeek7")
const ZOOM_OUT = preload("uid://c38grol123g2b")
#const CAMERA_PAN = preload("uid://ct6f01qoq3s6f")
#const GO_COMMAND_1 = preload("uid://cih07swafemnl")
#const GO_COMMAND_2 = preload("uid://dcep2yn10r3bp")
#const AWAY_COMMAND = preload("uid://dj75twlwyt7np")
const UNIT_SELECT = preload("uid://b5h6r68gsrnjg")
const UNIT_SELECT_ALL = preload("uid://dkvmsr6kat77y")
const UNIT_DESELECT = preload("uid://b0pcm8xx1dqew")

@export var move_sensitivity := 2000.0
@export var drag_sensitivity := 0.7
@export var drag_smooth := 10.0
@export var zoom_sensitivity := 0.1
@export var zoom_max := Vector2(2.0, 2.0)
@export var zoom_min := Vector2(0.05, 0.05)
@export var zoom_smooth := 5.0
@export var selector_radius := 64.0
@export var min_drag_sound := 1.0

@export var selector: Area2D
@export var towards_point: Node2D
@export var away_point: Node2D
@export var music: AudioStreamPlayer
@export var ambient: AudioStreamPlayer
@export var clouds: Clouds
@export var zoom_audio: AudioStreamPlayer
@export var pan_audio: AudioStreamPlayer
@export var unit_audio: AudioStreamPlayer
@export var go_audio_1: AudioStreamPlayer
@export var go_audio_2: AudioStreamPlayer
@export var away_audio: AudioStreamPlayer

var drag_desired := global_position
var zoom_desired := zoom
var selected_units: Array[Unit] = []
var selected_anything := false
var deselecting := false
var can_select := true
var last_selected: Interactable
var dragging := false
var go_cycle := false

@onready var selector_shape: CircleShape2D = selector.get_node("CollisionShape2D").shape
@onready var selector_visualizer: Polygon2D = selector.get_node("Polygon2D")
@onready var zoom_stream: AudioStreamPlaybackPolyphonic = zoom_audio.get_stream_playback()
@onready var unit_stream: AudioStreamPlaybackPolyphonic = unit_audio.get_stream_playback()


func _ready() -> void:
	Global.camera = self
	$Selector/Polygon2D.polygon = generate_circle_polygon(selector_radius, 32)
	$Selector/Polygon2D.uv = generate_circle_polygon(0.5, 32, Vector2(0.5, 0.5))
	await get_tree().process_frame
	if not OS.get_name() == "Web":
		pan_audio.play()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("mouse3"):
			var zoom_factor := maxf(inverse_lerp(zoom_min.length(), zoom_max.length(), zoom_desired.length()), 0.1)
			var amount: Vector2 = event.screen_relative * drag_sensitivity * (1/zoom_factor)
			drag_desired -= amount
			dragging = true
			#if amount.length() >= min_drag_sound: dragging = true
			#else: dragging = false


func _process(delta: float) -> void:
	selection()
	commanding()
	camera_move(delta)
	
	towards_point.global_position = get_global_mouse_position()
	away_point.global_position = get_global_mouse_position()
	
	#if Input.is_action_just_pressed("tab"): can_select = !can_select
	selector_shape.radius = selector_radius * (1/zoom.x) 
	selector_visualizer.scale = Vector2(1/zoom.x, 1/zoom.y)


func _physics_process(_delta: float) -> void:
	if not selector.monitoring: return
	for body in selector.get_overlapping_bodies():
		if body is Unit:
			if deselecting and selected_units.has(body):
				selected_units.erase(body)
				body.selected(false)
				unit_stream.play_stream(UNIT_DESELECT)
			if not deselecting and not selected_units.has(body):
				selected_units.append(body)
				body.freed.connect(_on_unit_freed)
				body.selected(true)
				unit_stream.play_stream(UNIT_SELECT)
			selected_anything = true


func selection() -> void:
	selector.position = get_local_mouse_position()
	
	if not can_select: return
	
	if Input.is_action_pressed("a") and Input.is_action_pressed("shift"):
		if get_tree().get_nodes_in_group("Units").size() - selected_units.size() > 0:
			unit_stream.play_stream(UNIT_SELECT_ALL)
		
		for unit in get_tree().get_nodes_in_group("Units"):
			if unit is Unit and not selected_units.has(unit):
				selected_anything = true
				selected_units.append(unit)
				if not unit.freed.is_connected(_on_unit_freed):
					unit.freed.connect(_on_unit_freed)
				unit.selected(true)
	
	#if Input.is_action_just_released("space") and not selected_anything:
	if Input.is_action_just_pressed("space"):
		if selected_units.size() > 0: unit_stream.play_stream(UNIT_DESELECT)
		for unit in selected_units:
			unit.selected(false)
		selected_units = []
	elif not Input.is_action_pressed("space"): 
		#selected_anything = false
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
		if not away_audio.playing: away_audio.play()
	elif Input.is_action_pressed("mouse1"):
		for unit in selected_units:
			#if is_instance_valid(unit):
			unit.move_to(get_global_mouse_position())
		towards_point.visible = true
		away_point.visible = false
		if not go_audio_1.playing and not go_audio_2.playing:
			if not go_cycle: go_audio_1.play()
			else: go_audio_2.play()
			go_cycle = !go_cycle
	#if (Input.is_action_just_released("mouse1") and Input.is_action_pressed("shift")) or (Input.is_action_pressed("mouse1") and Input.is_action_just_released("shift")) or (Input.is_action_just_released("mouse1") and Input.is_action_just_released("shift")):
	else:
		#for unit in selected_units: unit.stop_moving_away()
		away_point.visible = false
		towards_point.visible = false

   
func camera_move(delta: float) -> void:
	var mouse_delta := get_global_mouse_position() - global_position
	
	#Input.get_vector("a", "d", "w", "s")
	var move_dir := Vector2()
	if Input.is_action_pressed("a") and not Input.is_action_pressed("shift"): move_dir.x -= 1.0
	if Input.is_action_pressed("d"): move_dir.x += 1.0
	if Input.is_action_pressed("w"): move_dir.y -= 1.0
	if Input.is_action_pressed("s"): move_dir.y += 1.0
	
	if Input.is_action_just_released("mouse3"): dragging = false
	
	#if not pan_audio.playing: pan_audio.play()
	pan_audio.stream_paused = not (absf(move_dir.length_squared()) > 0.0 or dragging)
	
	drag_desired += move_dir.normalized() * move_sensitivity * delta
	
	var zoom_dir := 0
	if Input.is_action_just_released("wheel_up"):
		zoom_dir += 2
		zoom_stream.play_stream(ZOOM_IN)
	elif Input.is_action_just_released("wheel_down"):
		zoom_dir -= 1
		zoom_stream.play_stream(ZOOM_OUT)
	
	#var old_mouse_pos := get_global_mouse _position()
	zoom_desired = (zoom_desired + (Vector2.ONE * zoom_sensitivity * zoom_dir * zoom.x)).clamp(zoom_min, zoom_max)
	zoom = Global.decay_towards_vec2(zoom, zoom_desired, zoom_smooth, delta)
	#global_position += old_mouse_pos - get_global_mouse_position()
	
	if zoom_desired.x < zoom_max.x and zoom_desired.x > zoom_min.x:
		var bonus := 2.0 if zoom_dir < 0.0 else 1.0
		drag_desired += mouse_delta * zoom_sensitivity * signi(zoom_dir) * bonus
	
	#if not zoom_dir == 0:
		#drag_desired += old_mouse_pos - get_global_mouse_position()
	#global_position += old_mouse_pos - get_global_mouse_position()
	global_position = Global.decay_towards_vec2(global_position, drag_desired, drag_smooth, delta)
	
	music.volume_linear = clamp(inverse_lerp(0.1, 0.5, zoom.x), 0.0, 1.0)
	var sfx_volume: float = linear_to_db(clamp(inverse_lerp(zoom_min.x, 0.5, zoom.x), 0.0, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_volume)
	ambient.volume_linear = clamp((inverse_lerp(zoom_min.x, 0.2, zoom.x) * -1.0 ) + 0.8, 0.0, 1.0)
	clouds.change_clouds(clamp((inverse_lerp(zoom_min.x, 0.06, zoom.x) * -1.0) + 1.0, 0.0, 1.0))


func select_interactable(object: Interactable) -> void:
	if object is ClayDeposit and object.dead: return
	var units_to_remove: Array[Unit] = []
	for unit in selected_units:
		#if not is_instance_valid(unit): continue
		if not unit.current_item == Unit.ITEM.NONE and not (object.is_in_group("Banks") or object.is_in_group("Pit")): continue
		if unit.current_item == object.item: continue
		units_to_remove.append(unit)
	for unit in units_to_remove:
		unit.set_goal(object)
		selected_units.erase(unit)
		unit.selected(false)
	if units_to_remove.size() > 0: unit_stream.play_stream(UNIT_DESELECT)


func generate_circle_polygon(radius: float, num_sides: int, bonus := Vector2()) -> PackedVector2Array:
	var angle_delta: float = (PI * 2) / num_sides
	var vector: Vector2 = Vector2(radius, 0)
	var points: PackedVector2Array

	for _i in num_sides:
		points.append(vector + bonus)
		vector = vector.rotated(angle_delta)

	return points


func _on_unit_freed(unit: Unit) -> void: selected_units.erase(unit)
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
