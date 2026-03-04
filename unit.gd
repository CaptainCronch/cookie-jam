extends CharacterBody2D
class_name Unit

enum ITEM {NONE, WOOD, CLAY, BODY, ASH, GLASSY_CLAY}

@export var default_speed := 500.0
@export var carrying_speed := 400.0
@export var smooth_buffer := 100.0
@export var close_buffer := 20.0
@export var separate_strength := default_speed * 2
@export var acceleration := 10.0
@export var away_multiplier := 2.0
@export var damage := 1
@export var interact_time := 1.0

@export var separate_area: Area2D
@export var separate_collider: CollisionShape2D
@export var item_sprites: Array[Sprite2D] = []

var speed := default_speed
var direction := Vector2()
var desired_position := Vector2()
var distance := 0.0
var away := false
var idle := true
var in_separate_area: Array[Area2D]
var boost := Vector2()
var current_goal: Interactable
var backup_goal: Interactable
var interact_timer := interact_time
var current_item := ITEM.NONE:
	set(value):
		for sprite in item_sprites: sprite.hide()
		item_sprites[value - 1].show()
		if value == ITEM.NONE: speed = default_speed
		else: speed = carrying_speed

@onready var separate_shape: CircleShape2D = separate_collider.shape


func _ready() -> void:
	desired_position = global_position


func _process(delta: float) -> void:
	#boost = direction * -10000 if Input.is_action_pressed("shift") else Vector2()
	if interact_timer > 0.0: interact_timer -= delta


func _physics_process(delta: float) -> void:
	check_interaction()
	
	distance = global_position.distance_to(desired_position)
	direction = global_position.direction_to(desired_position)
	idle = false
	
	var distance_factor = 0.0
	if away:
		distance_factor = 1.0
		direction = desired_position.direction_to(global_position)
	elif distance > close_buffer:
		distance_factor = minf(inverse_lerp(0.0, smooth_buffer, distance), 1.0)
	else:
		idle = true
	
	#separate()
	#if not idle: print("normal: " + str((direction * speed * distance_factor).length()))
	var desired_velocity = ((direction * speed * distance_factor) + separate()).limit_length(speed)
	velocity = Global.decay_towards_vec2(velocity, desired_velocity + boost, acceleration, delta)
	#velocity = ((direction * speed * distance_factor) + separate()).limit_length(speed)
	move_and_slide()
	
	boost = Vector2()


func separate() -> Vector2:
	if idle: return Vector2()
	var areas := separate_area.get_overlapping_areas()
	if areas.size() == 0: return Vector2()
	var total_direction := Vector2()
	var total_distance := 0.0

	for area in areas:
		total_direction += global_position.direction_to(area.global_position)
		total_distance += global_position.distance_to(area.global_position)
	total_direction = total_direction.normalized()
	total_direction *= -1
	total_distance /= areas.size()
	#total_distance = (total_distance * -1) + total_distance
	#total_distance = 1 / total_distance
	var ratio := (clampf(inverse_lerp(0.0, separate_shape.radius * 2, total_distance), 0.0, 1.0) * -1.0) + 1.0 
	#print("total_distance: ", total_distance, " ratio: ", ratio)
	var total := total_direction * ratio * separate_strength 
	#print("Separate: " + str(total.length()))
	return total


func check_interaction() -> void:
	for area in separate_area.get_overlapping_areas():
		if area is Interactable:
			if area == current_goal and interact_timer <= 0.0:
				area.give.connect(_on_item_get)
				(area as Interactable).interact(damage)
				interact_timer = interact_time


func move_to(pos: Vector2) -> void:
	desired_position = pos
	current_goal = null
	backup_goal = null
	#away = false


func move_away_from(pos: Vector2, power := speed * away_multiplier) -> void:
	desired_position = global_position
	boost = pos.direction_to(global_position) * power
	current_goal = null
	backup_goal = null
	#away = true


func set_goal(goal: Node2D, backup: Node2D = null) -> void:
	current_goal = goal
	backup_goal = backup
	desired_position = current_goal.global_position


func swap_goal() -> void:
	var hold := current_goal
	current_goal = backup_goal
	backup_goal = hold
	if is_instance_valid(current_goal):
		desired_position = current_goal.global_position


#func stop_moving_away() -> void:
	#desired_position = global_position + (direction * smooth_buffer)
	#away = false


func selected(yes: bool) -> void:
	$Polygon2D.visible = yes


func check_deposit() -> void: # find closest dropoff spot and make it the backup goal
	if current_item == ITEM.BODY:
		pass # go to demon pit
	else:
		var distances: Array[float] = []
		var smallest_distance := 1000000.0
		var banks := get_tree().get_nodes_in_group("Banks")
		for bank in banks: # demon pit counts as bank too so you have one to start with
			var dist := (bank as Interactable).global_position.distance_squared_to(global_position)
			distances.append(dist)
			if dist < smallest_distance:
				smallest_distance = dist
		#backup_goal = banks[distances.find(smallest_distance)]
		# add buildings / demon pit so this line works please


func _on_item_get(type: Interactable.TYPE) -> void: # set held item based on resource building type
	match type:
		Interactable.TYPE.TREE: current_item = ITEM.WOOD
		Interactable.TYPE.MINE: current_item = ITEM.CLAY
		Interactable.TYPE.BODY: current_item = ITEM.BODY
		Interactable.TYPE.CITY: current_item = ITEM.ASH
		Interactable.TYPE.MIXER: current_item = ITEM.GLASSY_CLAY
	check_deposit()
	swap_goal()


#func _on_separate_area_entered(area: Area2D) -> void:
	#if not in_separate_area.has(area):
		#in_separate_area.append(area)
		#print(in_separate_area.size())
#
#
#func _on_separate_area_exited(area: Area2D) -> void:
	#in_separate_area.erase(area)
	#print(in_separate_area.size())
