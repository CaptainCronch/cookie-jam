extends CharacterBody2D
class_name Unit

@export var default_speed := 1000.0
@export var smooth_buffer := 100.0
@export var close_buffer := 20.0
@export var separate_strength := 2000.0
@export var acceleration := 10.0

@export var separate_area: Area2D
@export var separate_collider: CollisionShape2D

var speed := default_speed
var direction := Vector2()
var desired_position := Vector2()
var distance := 0.0
var away := false
var idle := true
var in_separate_area: Array[Area2D]
var boost := Vector2()

@onready var separate_shape: CircleShape2D = separate_collider.shape

func _ready() -> void:
	desired_position = global_position


func _process(_delta: float) -> void:
	#boost = direction * -10000 if Input.is_action_pressed("shift") else Vector2()
	pass


func _physics_process(delta: float) -> void:
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


func move_to(pos: Vector2) -> void:
	desired_position = pos
	#away = false


func move_away_from(pos: Vector2, power := speed) -> void:
	desired_position = global_position
	boost = pos.direction_to(global_position) * power
	#away = true


#func stop_moving_away() -> void:
	#desired_position = global_position + (direction * smooth_buffer)
	#away = false


func selected(yes: bool) -> void:
	$Polygon2D.visible = yes 


#func _on_separate_area_entered(area: Area2D) -> void:
	#if not in_separate_area.has(area):
		#in_separate_area.append(area)
		#print(in_separate_area.size())
#
#
#func _on_separate_area_exited(area: Area2D) -> void:
	#in_separate_area.erase(area)
	#print(in_separate_area.size())
