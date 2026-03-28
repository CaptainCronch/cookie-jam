extends CharacterBody2D
class_name Baal

@export var default_speed := 1000.0
@export var acceleration := 5.0
@export var idle_speed := 50.0

@export var separate_area: Area2D
@export var separate_collider: CollisionShape2D
@export var aggro_area: Area2D
@export var sprite: Sprite2D
@export var animator: AnimationPlayer
@export var attack_audio: AudioStreamPlayer2D
@export var fire_blast: CPUParticles2D
@export var left: Marker2D
@export var right: Marker2D

var speed := default_speed
var direction := Vector2()
var last_direction := 1.0


#func _ready() -> void:
	#Global.baal = self


func _process(_delta: float) -> void:
	direction = Input.get_vector("a", "d", "w", "s")
	if direction.x != 0.0: last_direction = direction.x
	
	fire_blast.emitting = Input.is_action_pressed("mouse1")


func _physics_process(delta: float) -> void:
	if last_direction > 0.0: 
		sprite.flip_h = true
		fire_blast.position = right.position
		fire_blast.direction = Vector2(1, 1)
	else:
		sprite.flip_h = false
		fire_blast.position = left.position
		fire_blast.direction = Vector2(-1, 1)
	
	#if distance < close_buffer:
		#if not animator.current_animation == "idle": animator.play("idle")
	#else:
		#if not animator.current_animation == "run": animator.play("run")
	
	var desired_velocity = direction * speed
	velocity = Global.decay_towards_vec2(velocity, desired_velocity, acceleration, delta)
	#velocity = ((direction * speed * distance_factor) + separate()).limit_length(speed)
	move_and_slide()


func check_interaction() -> void:
	for area in separate_area.get_overlapping_areas():
		var parent := area.get_parent()
		if (parent is Enemy or parent is Victim):
			pass
		elif parent is Unit:
			pass
