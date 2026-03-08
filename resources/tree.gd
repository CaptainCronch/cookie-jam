extends Interactable
class_name WoodTree


func interact(origin: Unit, strength := 1) -> void:
	if not origin.current_item == Unit.ITEM.NONE: return
	health -= strength
	origin.give(item)
	if health <= 0:
		finished(origin)


func finished(_origin: Unit) -> void:
	# spawn log here? nah
	# spawn particles
	# play sound here
	done.emit(item, self)
	queue_free()
