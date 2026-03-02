extends CharacterBody2D
class_name Unit

@export var default_speed := 500.0
@export var smooth_buffer := 100.0
@export var close_buffer := 20.0

var speed := default_speed
var direction := Vector2()
var desired_position := Vector2()
var distance := 0.0
var away := false
var idle := true


func _ready() -> void:
	desired_position = global_position


func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	distance = global_position.distance_to(desired_position)
	direction = global_position.direction_to(desired_position)
	velocity = Vector2()
	
	var distance_factor = 0.0
	if away:
		distance_factor = 1.0
		direction = desired_position.direction_to(global_position)
	elif distance > close_buffer:
		distance_factor = minf(inverse_lerp(0.0, smooth_buffer, distance), 1.0)
	
	velocity = direction * speed * distance_factor
	move_and_slide()


func move_to(pos: Vector2) -> void: desired_position = pos


func move_away_from(pos: Vector2) -> void:
	desired_position = pos
	away = true


func stop_moving_away() -> void:
	desired_position = global_position + (direction * smooth_buffer)
	away = false


func selected(yes: bool) -> void:
	$Polygon2D.visible = yes 
