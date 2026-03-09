extends Node

signal earned_soul

const WAVE_TIME := 30.0

var camera: God
var ui: UI
var fog: Fog

var max_units := 5
var bonus_units := 0
var units := 0
var wood := 0
var clay := 0
var souls := 0:
	set(value):
		if value > souls: earned_soul.emit()
		souls = value
var ash := 0
var glassy_clay := 0
var wave := 1

@onready var timer := Timer.new()


func _ready():
	#get_window().mode = Window.MODE_FULLSCREEN
	add_child(timer)
	timer.timeout.connect(spawn_wave)
	timer.start(WAVE_TIME * 4)


func _process(_delta):
	if Input.is_action_just_pressed("debug_key"):
		if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = 0
		elif DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			Engine.max_fps = 60

	if Input.is_action_just_pressed("escape"):
		get_tree().quit() # temporary for testing

	if Input.is_action_just_pressed("fullscreen"):
		if get_window().mode != Window.MODE_FULLSCREEN:
			get_window().mode = Window.MODE_FULLSCREEN
		else:
			get_window().mode = Window.MODE_WINDOWED


func refresh_ui() -> void:
	ui.unit_label.text = str(units) + "/" + str(max_units)
	ui.wood_label.text = str(wood)
	ui.clay_label.text = str(clay)
	ui.souls_label.text = str(souls)
	ui.ash_label.text = str(ash)
	ui.glassy_clay_label.text = str(glassy_clay)


func spawn_wave() -> void:
	var cities := get_tree().get_nodes_in_group("Cities")
	if cities.size() == 0: return
	for i in wave:
		cities[randi_range(0, cities.size() - 1)].spawn_enemy()
	wave += 1
	timer.start(WAVE_TIME)


func mouse_switch(pos := Vector2(0, 0)) -> void :
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_window().warp_mouse(pos)
	elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func decay_towards(value : float, target : float,
			decay_power : float, delta : float = get_process_delta_time(),
			round_threshold : float = 0.0) -> float :

	var new_value := (value - target) * pow(2, -delta * decay_power) + target

	if absf(new_value - target) < round_threshold:
		return target
	else:
		return new_value


func decay_towards_vec2(value : Vector2, target : Vector2,
			decay_power : float, delta : float = get_process_delta_time(),
			round_threshold : float = 0.0) -> Vector2 :

	var new_value := (value - target) * pow(2, -delta * decay_power) + target

	if (new_value - target).length() < round_threshold:
		return target
	else:
		return new_value


func decay_angle_towards(value : float, target : float,
			decay_power : float, delta : float = get_process_delta_time(),
			round_threshold : float = 0.0) -> float :

	var new_value := angle_difference(target, value) * pow(2, -delta * decay_power) + target

	if absf(angle_difference(target, new_value)) < round_threshold:
		return target
	else:
		return new_value


func line(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	get_tree().get_root().add_child(mesh_instance)
	if persist_ms:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance


func cube(box : BoxShape3D, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	immediate_mesh.surface_add_vertex(Vector3.RIGHT * box.size.x / -2)
	immediate_mesh.surface_add_vertex(Vector3.RIGHT * box.size.x / 2)
	immediate_mesh.surface_add_vertex(Vector3.FORWARD * box.size.z / -2)
	immediate_mesh.surface_add_vertex(Vector3.FORWARD * box.size.z / 2)
	immediate_mesh.surface_add_vertex(Vector3.UP * box.size.y / -2)
	immediate_mesh.surface_add_vertex(Vector3.UP * box.size.y / 2)
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	get_tree().get_root().add_child(mesh_instance)
	if persist_ms:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
