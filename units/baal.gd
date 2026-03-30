extends CharacterBody2D
class_name Baal

@export var default_speed := 1000.0
@export var acceleration := 5.0

@export var sprite: Sprite2D
@export var animator: AnimationPlayer
@export var attack_audio: AudioStreamPlayer2D
@export var stomp_audio: AudioStreamPlayer2D
@export var fire_blast_left: CPUParticles2D
@export var fire_blast_right: CPUParticles2D
@export var fire_area: Area2D
@export var fire_collider_left: CollisionShape2D
@export var fire_collider_right: CollisionShape2D
@export var step_area: Area2D

var speed := default_speed
var direction := Vector2()
var last_direction := 1.0
var shooting := false


func _process(_delta: float) -> void:
	direction = Input.get_vector("a", "d", "w", "s")
	if direction.x != 0.0: last_direction = direction.x
	shooting = Input.is_action_pressed("mouse1")


func _physics_process(delta: float) -> void:
	check_fire()
	check_stomp()
	
	fire_blast_right.emitting = false
	fire_blast_left.emitting = false
	fire_collider_right.disabled = true
	fire_collider_left.disabled = true
	if last_direction > 0.0: 
		sprite.flip_h = true
		fire_blast_right.emitting = shooting
		fire_collider_right.disabled = !shooting
	else:
		sprite.flip_h = false
		fire_blast_left.emitting = shooting
		fire_collider_left.disabled = !shooting
	
	#if distance < close_buffer:
		#if not animator.current_animation == "idle": animator.play("idle")
	#else:
		#if not animator.current_animation == "run": animator.play("run")
	
	var desired_velocity = direction * speed
	velocity = Global.decay_towards_vec2(velocity, desired_velocity, acceleration, delta)
	#velocity = ((direction * speed * distance_factor) + separate()).limit_length(speed)
	move_and_slide()


func check_fire() -> void:
	for area in fire_area.get_overlapping_areas():
		var parent := area.get_parent()
		if (parent is Enemy or parent is Victim):
			pass
		elif parent is Unit:
			pass
		elif area is Interactable:
			pass


func check_stomp() -> void:
	for area in step_area.get_overlapping_areas():
		var parent := area.get_parent()
		if (parent is Enemy or parent is Victim):
			pass
		elif parent is Unit:
			pass
		elif area is Interactable:
			area.die()
