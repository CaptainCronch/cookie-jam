extends Interactable
class_name Body


func interact(origin: Unit, strength := 1) -> bool:
	if dead: return false
	if not origin.current_item == Unit.ITEM.NONE: return false
	health -= strength
	origin.give(item)
	if health <= 0:
		finished(origin)
	return true


func finished(_origin: Unit) -> void:
	#spawn_particles(WOOD_CHIPS, origin.global_position.direction_to(global_position).angle())
	dead = true
	remove_from_group("Resource")
	remove_from_group("Bodies")
	done.emit(item, self)
	queue_free()
