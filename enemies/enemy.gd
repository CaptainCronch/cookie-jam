extends CharacterBody2D
class_name Enemy

const BODY = preload("uid://bldwnwc8e611l")
const PUDDLE = preload("uid://du2lw4k1vgxy4")
const BLOOD_SPLATTER = preload("uid://dfeij4sr7verl")
const BODY_FIRE = preload("uid://pr3onfr8vwm7")
const SMOKE_CRISPED = preload("uid://cicnkqtaxkicp")
const ASH_PILE = preload("uid://ctkr8y3pe3cc8")

@export var default_speed := 300.0
@export var smooth_buffer := 100.0
@export var close_buffer := 50.0
@export var acceleration := 10.0
@export var away_multiplier := 2.0
@export var damage := 1
@export var interact_time := 0.5
@export var seek_time := 10.0
@export var max_health := 5
@export var health_change_boost := 50.0
@export var health_change_boost_time := 0.5
@export var knockback_force := 5000.0

@export var separate_area: Area2D
@export var separate_collider: CollisionShape2D
@export var aggro_area: Area2D
@export var sprite: Sprite2D
@export var animator: AnimationPlayer
@export var attack_audio: AudioStreamPlayer2D
@export var notice_audio: AudioStreamPlayer2D

var speed := default_speed
var direction := Vector2()
var desired_position := Vector2()
var distance := 0.0
var away := false
var idle := true
var in_separate_area: Array[Area2D]
var boost := Vector2()
var current_goal: Interactable
var targeted_unit: Unit
#var backup_goal: Interactable
var interact_timer := interact_time
var seek_timer := seek_time
var health := max_health:
	set(value):
		shader.set_shader_parameter("level", float(value)/float(max_health))
		var starting: float = shader.get_shader_parameter("speed_boost")
		if is_instance_valid(health_tween): health_tween.kill()
		health_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		health_tween.tween_property(shader, "shader_parameter/speed_boost", starting - health_change_boost, health_change_boost_time)
		health = value
var health_tween: Tween
var units_to_hit: Array[Unit] = []
var interacting := false
var dead := false
var fired := false

@onready var separate_shape: CircleShape2D = separate_collider.shape
@onready var shader: ShaderMaterial = sprite.material


func _ready() -> void:
	sprite.set_instance_shader_parameter("speed_boost", 100000.0)
	desired_position = global_position


func _process(delta: float) -> void:
	#boost = direction * -10000 if Input.is_action_pressed("shift") else Vector2()
	if interact_timer > 0.0: interact_timer -= delta
	
	if is_instance_valid(Global.baal) and not fired:
		desired_position = Global.baal.global_position
		return
	
	if not is_instance_valid(current_goal):
		seek_timer -= delta
		if seek_timer <= 0.0:
			find_closest("Buildings")
			seek_timer = seek_time


func _physics_process(delta: float) -> void:
	check_aggro()
	check_interaction()
	
	if fired: desired_position = global_position + Vector2(0, 100).rotated(desired_position.angle())
	
	distance = global_position.distance_to(desired_position)
	direction = global_position.direction_to(desired_position)
	idle = false
	
	if velocity.x < 0.0: 
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	
	if not interacting:
		if velocity.length() < speed/3.0:
			if not animator.current_animation == "idle": animator.play("idle")
		else:
			if not animator.current_animation == "run": animator.play("run")
	
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
		elif area.get_parent() is Unit: force = 10.0
		total_distance += global_position.distance_to(area.global_position) * force
	total_direction = total_direction.normalized()
	total_direction *= -1
	total_distance /= areas.size()
	#total_distance = (total_distance * -1) + total_distance
	#total_distance = 1 / total_distance
	var ratio := (clampf(inverse_lerp(0.0, separate_shape.radius * 2, total_distance), 0.0, 1.0) * -1.0) + 1.0 
	#print("total_distance: ", total_distance, " ratio: ", ratio)
	var total := total_direction * ratio * speed * away_multiplier
	#print("Separate: " + str(total.length()))
	return total


func check_aggro() -> void:
	var any_valid := false
	for unit in units_to_hit:
		if is_instance_valid(unit) and not targeted_unit == unit:
			any_valid = true
			if not is_instance_valid(targeted_unit): notice_audio.play()
			targeted_unit = unit
			desired_position = targeted_unit.global_position
			break
	if not any_valid:
		units_to_hit = []
		targeted_unit = null
		current_goal = null
		find_closest("Buildings")


func check_interaction() -> void:
	for area in separate_area.get_overlapping_areas():
		var parent := area.get_parent()
		if parent is Unit and parent == targeted_unit and interact_timer <= 0.0:
			(parent as Unit).hurt(self, damage)
			attack_audio.play()
			interact_timer = interact_time
			interacting = true
			animator.play("interact")
		elif area is Interactable:
			if area == current_goal and interact_timer <= 0.0:
				(area as Interactable).damage(self, damage)
				interact_timer = interact_time
				interacting = true
				animator.play("interact")
				#check_deposit()


func hurt(origin: Unit, strength := 1) -> void:
	if dead: return
	health -= strength
	boost = origin.global_position.direction_to(global_position) * knockback_force
	if health <= 0:
		die(origin)


func die(origin: Unit) -> void:
	dead = true
	var body := BODY.instantiate()
	body.global_position = global_position
	get_tree().current_scene.add_child(body)
	var puddle := PUDDLE.instantiate()
	puddle.global_position = global_position
	get_tree().current_scene.add_child(puddle)
	var splatter := BLOOD_SPLATTER.instantiate()
	splatter.global_position = global_position
	var angle := origin.global_position.direction_to(global_position).angle() if is_instance_valid(origin) else 0.0
	splatter.rotation = angle
	get_tree().current_scene.add_child(splatter)
	splatter.emitting = true
	queue_free()


func fire(origin: Baal) -> void:
	if fired: return
	fired = true
	
	boost = origin.global_position.direction_to(global_position) * knockback_force * 5
	speed *= 2
	desired_position = Vector2(randf_range(-10000, 10000), randf_range(-10000, 10000))
	
	var body_fire := BODY_FIRE.instantiate()
	add_child(body_fire)
	
	await get_tree().create_timer(5.0).timeout
	
	var smoke := SMOKE_CRISPED.instantiate()
	smoke.global_position = global_position
	smoke.emitting = true
	get_tree().current_scene.add_child(smoke)
	
	var ash := ASH_PILE.instantiate()
	ash.global_position = global_position
	get_tree().current_scene.add_child(ash)
	
	queue_free()


func set_goal(goal: Interactable) -> void:
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


func _on_resource_done() -> void:
	await get_tree().process_frame
	#if current_item == ITEM.NONE:
		#last_item = type
		#check_resource()
	pass


func _on_aggro_area_entered(area: Area2D) -> void:
	if area.get_parent() is Unit:
		units_to_hit.append(area.get_parent())


func _on_aggro_area_exited(area: Area2D) -> void:
	if area.get_parent() is Unit:
		units_to_hit.erase(area.get_parent())


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "interact": interacting = false
