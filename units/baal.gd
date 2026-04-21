extends CharacterBody2D
class_name Baal

@export var default_speed := 1200.0
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
@export var player: AnimationPlayer
@export var fire_blast_audio: AudioStreamPlayer2D

var speed := default_speed
var direction := Vector2()
var last_direction := 1.0
var shooting := false


func _process(_delta: float) -> void:
	direction = Input.get_vector("a", "d", "w", "s")
	if direction.x != 0.0: last_direction = direction.x
	shooting = Input.is_action_pressed("mouse1")
	
	if direction.length_squared() == 0.0 and not player.current_animation == "idle":
		player.play("idle")
	elif direction.length_squared() > 0.0 and not player.current_animation == "walk":
		player.play("walk")


func _physics_process(delta: float) -> void:
	check_fire()
	#check_stomp()
	
	fire_blast_right.emitting = false
	fire_blast_left.emitting = false
	fire_collider_right.disabled = true
	fire_collider_left.disabled = true
	if last_direction > 0.0:
		sprite.scale.x = 1.0
		fire_blast_right.emitting = shooting
		fire_collider_right.disabled = !shooting
		fire_blast_audio.position = fire_blast_right.position
	else:
		sprite.scale.x = -1.0
		fire_blast_left.emitting = shooting
		fire_collider_left.disabled = !shooting
		fire_blast_audio.position = fire_blast_left.position
	
	fire_blast_audio.volume_db = 6.0 if shooting else -100.0
	
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
		if parent is Enemy or parent is Victim or parent is Unit:
			parent.fire(self)
		elif (area is Interactable or area is Stump) and not area is Body:
			if area is Body: return
			area.fire()


func check_stomp() -> void:
	for area in step_area.get_overlapping_areas():
		var parent := area.get_parent()
		if parent is Enemy or parent is Victim:
			parent.die(null)
		elif parent is Unit:
			parent.hurt(null, 0, global_position.direction_to(parent.global_position))
		elif area is Interactable and not area is Body:
			if area.is_resource: area.finished(null)
			else: area.die(null)


func stomp_shake() -> void:
	Global.camera.add_trauma(0.3)


func _on_step_area_entered(area: Area2D) -> void:
	var parent := area.get_parent()
	if (parent is Enemy or parent is Victim):
		parent.die(null)
	elif parent is Unit:
		parent.hurt(null, 0, global_position.direction_to(parent.global_position))
	elif area is Interactable:
		if area.is_resource:
			area.finished(null)
		area.die(null)
