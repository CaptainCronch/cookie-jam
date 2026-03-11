extends Interactable
class_name WoodTree

const WOOD_CHIPS = preload("uid://l3h6oextc6qc")


func _ready() -> void:
	super()
	$Sprite2D.scale = Vector2(randfn(1.0, 0.1), 1.0)
	$Sprite2D.flip_h = randi_range(0, 1) == 1


func interact(origin: Unit, strength := 1) -> bool:
	if dead: return false
	if not origin.current_item == Unit.ITEM.NONE: return false
	if animator.is_playing(): animator.stop()
	animator.play("interact")
	health -= strength
	origin.give(item)
	if health <= 0:
		finished(origin)
	return true


func finished(origin: Unit) -> void:
	if animator.is_playing(): animator.stop()
	animator.play("finish")
	dead = true
	remove_from_group("Resource")
	remove_from_group("Trees")
	spawn_particles(WOOD_CHIPS, origin.global_position.direction_to(global_position).angle())
	done.emit(item, self)
