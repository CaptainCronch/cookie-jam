extends CharacterBody2D
class_name Unit

enum ITEM {NONE, WOOD, CLAY, BODY, ASH, GLASSY_CLAY}

@export var default_speed := 500.0
@export var carrying_speed := 400.0
@export var smooth_buffer := 100.0
@export var close_buffer := 20.0
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
#var backup_goal: Interactable
var interact_timer := interact_time
var current_item := ITEM.NONE:
	set(value):
		for sprite in item_sprites:
			sprite.hide()
		if not value == 0:
			item_sprites[value - 1].show()
		if value == ITEM.NONE: speed = default_speed
		else: speed = carrying_speed
		current_item = value
var last_item := ITEM.WOOD
var last_resource: Interactable
var times_called := 0

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
		var force := 1.0
		if area is Interactable: force = 1 / area.push_force
		total_distance += global_position.distance_to(area.global_position) * force
	total_direction = total_direction.normalized()
	total_direction *= -1
	total_distance /= areas.size()
	#total_distance = (total_distance * -1) + total_distance
	#total_distance = 1 / total_distance
	var ratio := (clampf(inverse_lerp(0.0, separate_shape.radius * 2, total_distance), 0.0, 1.0) * -1.0) + 1.0 
	#print("total_distance: ", total_distance, " ratio: ", ratio)
	var total := total_direction * ratio * speed #* away_multiplier
	#print("Separate: " + str(total.length()))
	return total


func check_interaction() -> void:
	for area in separate_area.get_overlapping_areas():
		if area is Interactable:
			if area is Bank and not current_item == ITEM.NONE and not current_item == ITEM.BODY:
				last_item = current_item
				(area as Bank).deposit(self, current_item)
				check_resource()
			elif area is Pit and current_item == ITEM.BODY:
				last_item = current_item
				(area as Pit).deposit(self, current_item)
				check_resource()
			elif area == current_goal and interact_timer <= 0.0 and current_item == ITEM.NONE:
				(area as Interactable).interact(self, damage)
				interact_timer = interact_time
				check_deposit()


func move_to(pos: Vector2) -> void:
	desired_position = pos
	current_goal = null
	#backup_goal = null
	#away = false


func move_away_from(pos: Vector2, power := speed * away_multiplier) -> void:
	desired_position = global_position
	boost = pos.direction_to(global_position) * power
	current_goal = null
	#backup_goal = null
	#away = true


func set_goal(goal: Interactable) -> void:
	##times_called += 1
	#var time := float(randi_range(0, 10))
	#if time > 0.0:
		#await get_tree().create_timer(time / 100.0).timeout # have some units wait before setting their goal because it's slowing everything
		#if not is_instance_valid(goal): return
		#current_goal = goal
		#desired_position = current_goal.global_position
	#else:
	if not is_instance_valid(goal): return
	if not goal.done.is_connected(_on_resource_done): goal.done.connect(_on_resource_done)
	current_goal = goal
	desired_position = current_goal.global_position


#func swap_goal() -> void:
	#var hold := current_goal
	#current_goal = backup_goal
	#backup_goal = hold
	#if is_instance_valid(current_goal):
		#desired_position = current_goal.global_position
	#else:
		#desired_position = global_position


func give(type: ITEM) -> void:
	current_item = type


func take() -> void:
	current_item = ITEM.NONE


func selected(yes: bool) -> void:
	$Polygon2D.visible = yes


func find_closest(group: String) -> void:
	var distances: Array[float] = []
	var smallest_distance := INF
	var places := get_tree().get_nodes_in_group(group)
	if places.size() == 0:
		#backup_goal = null
		return
	for place in places:
		var dist := (place as Interactable).global_position.distance_squared_to(global_position)
		distances.append(dist)
		if dist < smallest_distance:
			smallest_distance = dist
	set_goal(places[distances.find(smallest_distance)])
	#desired_position = current_goal.global_position


func check_deposit() -> void: # find closest dropoff spot and make it the backup goal
	if current_item == ITEM.BODY:
		find_closest("Pit") # go to demon pit only
	else: 
		find_closest("Banks")


func check_resource() -> void: # find closest resource of the type last held to go harvest
	match(last_item):
		ITEM.NONE:
			return
		ITEM.WOOD:
			find_closest("Trees")
		ITEM.CLAY:
			find_closest("Mines")
		ITEM.BODY:
			find_closest("Bodies")
		ITEM.ASH:
			find_closest("Dead Cities")
		#ITEM.GLASSY_CLAY: i'm still gonna figure out how exactly glassy clay production works
			#if randi_range(0, 1) == 0:
				#find_closest("Mines")
			#else:
				#find_closest("Dead Cities")
	last_item = ITEM.NONE


func _on_resource_done(type: ITEM) -> void:
	await get_tree().process_frame
	if current_item == ITEM.NONE:
		last_item = type
		check_resource()
	pass


#func _on_item_get(type: Interactable.TYPE) -> void: # set held item based on resource building type
	#match type:
		#Interactable.TYPE.TREE: current_item = ITEM.WOOD
		#Interactable.TYPE.MINE: current_item = ITEM.CLAY
		#Interactable.TYPE.BODY: current_item = ITEM.BODY
		#Interactable.TYPE.CITY: current_item = ITEM.ASH
		#Interactable.TYPE.MIXER: current_item = ITEM.GLASSY_CLAY
	#check_deposit()
	#swap_goal()


#func _on_separate_area_entered(area: Area2D) -> void:
	#if not in_separate_area.has(area):
		#in_separate_area.append(area)
		#print(in_separate_area.size())
#
#
#func _on_separate_area_exited(area: Area2D) -> void:
	#in_separate_area.erase(area)
	#print(in_separate_area.size())
