extends Interactable
class_name WoodTree

const WOOD_CHIPS := preload("uid://l3h6oextc6qc")
const STUMP := preload("uid://iqth75a24dm")

@export var harvest_audio: AudioStreamPlayer2D
@export var spawn_audio: AudioStreamPlayer2D

var spawned := false


func _ready() -> void:
	super()
	$Sprite2D.scale = Vector2(randfn(1.0, 0.1), 1.0)
	$Sprite2D.scale.x *= -1.0 if randi_range(0, 1) == 1 else 1.0
	animator.play("interact")
	if spawned: spawn_audio.play()


func interact(origin: Unit, strength := 1) -> bool:
	if dead: return false
	if not origin.current_item == Unit.ITEM.NONE: return false
	animator.stop()
	animator.play("interact")
	health -= strength
	origin.give(item)
	harvest_audio.play()
	if health <= 0:
		finished(origin)
	return true


func finished(origin: Unit) -> void:
	#animator.stop()
	#animator.play("finish")
	dead = true
	#remove_from_group("Resource")
	#remove_from_group("Trees")
	var stump := STUMP.instantiate()
	stump.global_position = global_position
	stump.stump_sprite.scale = scale
	stump.log_sprite.scale = scale
	get_tree().current_scene.add_child(stump)
	var dir := origin.global_position.direction_to(global_position).angle() if is_instance_valid(origin) else 0.0
	spawn_particles(WOOD_CHIPS, dir)
	done.emit(item, self)
	queue_free()
