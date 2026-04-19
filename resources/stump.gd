extends Area2D
class_name Stump

const BONFIRE = preload("uid://doqpob1bdob4o")
const SMOKE_BURNED = preload("uid://ddx5nye86fjaq")
const ASH_PILE = preload("uid://ctkr8y3pe3cc8")

@export var stump_sprite: Sprite2D
@export var log_sprite: Sprite2D

var fired := false


func fire() -> void:
	if fired: return
	fired = true
	spawn_particles(BONFIRE, rotation, Vector2(), true)
	await get_tree().create_timer(2.0).timeout
	spawn_particles(SMOKE_BURNED, rotation)
	var ash: Node2D = ASH_PILE.instantiate()
	ash.global_position = global_position
	get_tree().current_scene.add_child(ash)
	queue_free()


func spawn_particles(scene: PackedScene, radians: float, where := global_position, child := false) -> void:
	var new: CPUParticles2D = scene.instantiate()
	new.global_position = where
	new.rotation = radians
	if child:
		add_child(new)
	else:
		get_tree().current_scene.add_child(new)
	new.emitting = true
