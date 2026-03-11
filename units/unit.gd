extends CharacterBody2D
class_name Unit

const SMOKE_SPLATTER = preload("uid://u27o3bdt6maj")

signal freed(unit: Unit)

enum ITEM {NONE, WOOD, CLAY, BODY, ASH, GLASSY_CLAY}

@export var default_speed := 600.0
@export var carrying_speed := 500.0
@export var smooth_buffer := 100.0
@export var close_buffer := 50.0
@export var acceleration := 10.0
@export var away_multiplier := 2.0
@export var damage := 1
@export var interact_time := 0.8
@export var max_health := 10
@export var regen_time := 5.0
@export var health_change_boost := 50.0
@export var health_change_boost_time := 0.5
@export var knockback_force := 10000.0
@export var idle_speed := 20.0

@export var separate_area: Area2D
@export var separate_collider: CollisionShape2D
@export var aggro_area: Area2D
@export var sprite: Sprite2D
@export var item_sprites: Array[Sprite2D] = []
@export var resources: Node2D
@export var animator: AnimationPlayer

var speed := default_speed
var direction := Vector2()
var desired_position := Vector2()
var distance := 0.0
var away := false
var idle := true
var in_separate_area: Array[Area2D]
var boost := Vector2()
var current_goal: Interactable
var targeted_enemy: CharacterBody2D
var warned_enemy: CharacterBody2D
#var backup_goal: Interactable
var interact_timer := 0.0
var current_item := ITEM.NONE:
	set(value):
		for item_sprite in item_sprites:
			item_sprite.hide()
		if not value == 0:
			item_sprites[value - 1].show()
		if value == ITEM.NONE: speed = default_speed
		else: speed = carrying_speed
		current_item = value
var last_item := ITEM.WOOD
var health := max_health:
	set(value):
		shader.set_shader_parameter("level", float(value)/float(max_health))
		var starting: float = shader.get_shader_parameter("speed_boost")
		if is_instance_valid(health_tween): health_tween.kill()
		health_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		health_tween.tween_property(shader, "shader_parameter/speed_boost", starting - health_change_boost, health_change_boost_time)
		health = value
var regen_timer := regen_time
var health_tween: Tween
var enemies_to_hit: Array[CharacterBody2D] = []
var interacting := false
var dead := false

@onready var separate_shape: CircleShape2D = separate_collider.shape
@onready var shader: ShaderMaterial = sprite.material


func _ready() -> void:
	sprite.set_instance_shader_parameter("speed_boost", 100000.0)
	desired_position = global_position
	Global.units += 1
	Global.refresh_ui()


func _process(delta: float) -> void:
	#boost = direction * -10000 if Input.is_action_pressed("shift") else Vector2()
	if interact_timer > 0.0: interact_timer -= delta
	if health < max_health:
		regen_timer -= delta
		if regen_timer <= 0.0:
			health += 1
			regen_timer = regen_time


func _physics_process(delta: float) -> void:
	check_aggro()
	check_interaction()
	
	distance = global_position.distance_to(desired_position)
	direction = global_position.direction_to(desired_position)
	idle = false
	
	if velocity.x >  0.0: 
		sprite.flip_h = true
		resources.scale.x = -1.0
	else:
		sprite.flip_h = false
		resources.scale.x = 1.0
	
	if not interacting:
		if current_item == ITEM.NONE:
			if distance < close_buffer:
				if not animator.current_animation == "idle": animator.play("idle")
			else:
				if not animator.current_animation == "run": animator.play("run")
		else:
			if distance < close_buffer:
				if not animator.current_animation == "idle_carry": animator.play("idle_carry")
			else:
				if not animator.current_animation == "run_carry": animator.play("run_carry")
	
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
		#if area is Interactable: force = 1 / area.push_force
		if area.get_parent() is Enemy: force = 10.0
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
	var smallest_distance := INF
	var closest_enemy: CharacterBody2D = null
	for enemy in enemies_to_hit:
		if is_instance_valid(enemy):
			var dist := global_position.distance_squared_to(enemy.global_position)
			if dist < smallest_distance:
				smallest_distance = dist
				closest_enemy = enemy
	
	if is_instance_valid(closest_enemy):
		targeted_enemy = closest_enemy
		desired_position = targeted_enemy.global_position
		for area in aggro_area.get_overlapping_areas():
			var parent := area.get_parent()
			if parent is Unit:
				(parent as Unit).warn(closest_enemy)
	else:
		enemies_to_hit = []
		targeted_enemy = null
		if is_instance_valid(warned_enemy):
			desired_position = warned_enemy.global_position


func check_interaction() -> void:
	for area in separate_area.get_overlapping_areas():
		var parent := area.get_parent()
		if (parent is Enemy or parent is Victim) and parent == targeted_enemy and interact_timer <= 0.0:
			parent.hurt(self, damage)
			interact_timer = interact_time
			interacting = true
			animator.play("interact")
		elif area is Interactable and interact_timer <= 0.0:
			if area is Bank and not current_item == ITEM.NONE and not current_item == ITEM.BODY:
				last_item = current_item
				(area as Bank).deposit(self, current_item)
				interact_timer = interact_time
				check_resource()
				interacting = true
				animator.play("interact")
			elif area is Pit and current_item == ITEM.BODY:
				last_item = current_item
				(area as Pit).deposit(self, current_item)
				interact_timer = interact_time
				check_resource()
				interacting = true
				animator.play("interact")
			elif area == current_goal and current_item == ITEM.NONE and area.is_resource:
				if (area as Interactable).interact(self, damage) == true:
					interact_timer = interact_time
					check_deposit()
					interacting = true
					animator.play("interact")
				else:
					check_resource()


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
	#times_called += 1
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


func hurt(origin: Enemy, strength := 1) -> void:
	health -= strength
	regen_timer = regen_time
	boost = origin.global_position.direction_to(global_position) * knockback_force
	
	if health <= 0:
		die(origin)


func warn(enemy: CharacterBody2D):
	if not is_instance_valid(targeted_enemy) and is_instance_valid(enemy) and not enemy == warned_enemy:
		warned_enemy = enemy
		for area in aggro_area.get_overlapping_areas():
				var parent := area.get_parent()
				if parent is Unit:
					(parent as Unit).warn(enemy)


func die(origin: Enemy) -> void:
	if dead: return
	dead = true
	var splatter := SMOKE_SPLATTER.instantiate()
	splatter.global_position = global_position
	splatter.rotation = origin.global_position.direction_to(global_position).angle()
	get_tree().current_scene.add_child(splatter)
	splatter.emitting = true
	Global.units -= 1
	Global.refresh_ui()
	freed.emit(self)
	queue_free()


func give(type: ITEM) -> void:
	current_item = type


func take() -> void:
	current_item = ITEM.NONE


func selected(yes: bool) -> void:
	$Selected.visible = yes


func find_closest(group: String) -> void:
	var distances: Array[float] = []
	var smallest_distance := INF
	var places := get_tree().get_nodes_in_group(group)
	if places.size() == 0: return
	
	for place in places:
		var can_see := false
		for vision in get_tree().get_nodes_in_group("Vision"):
			if place.global_position.distance_squared_to(vision.global_position) < 9000000.0:
				can_see = true
				#break
		var dist := (place as Interactable).global_position.distance_squared_to(global_position)
		distances.append(dist)
		if not can_see: continue
		if dist < smallest_distance:
			smallest_distance = dist
	if smallest_distance == INF:
		desired_position = global_position
		return
	set_goal(places[distances.find(smallest_distance)])


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
			find_closest("Deposits")
		ITEM.BODY:
			find_closest("Bodies")
		ITEM.ASH:
			find_closest("Cities")
		#ITEM.GLASSY_CLAY: i'm still gonna figure out how exactly glassy clay production works
			#if randi_range(0, 1) == 0:
				#find_closest("Mines")
			#else:
				#find_closest("Dead Cities")
	last_item = ITEM.NONE


func _on_resource_done(type: ITEM, _which: Interactable) -> void:
	await get_tree().process_frame
	if current_item == ITEM.NONE:
		last_item = type
		check_resource()


func _on_aggro_area_entered(area: Area2D) -> void:
	if area.get_parent() is Enemy or area.get_parent() is Victim:
		enemies_to_hit.append(area.get_parent())


func _on_aggro_area_exited(area: Area2D) -> void:
	if area.get_parent() is Enemy or area.get_parent() is Victim:
		enemies_to_hit.erase(area.get_parent())


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "interact": interacting = false
