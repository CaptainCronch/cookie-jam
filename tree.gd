extends Interactable
class_name WoodTree


func interact(strength := 1) -> void:
	health -= strength
	give.emit(TYPE.TREE)
	if health <= 0:
		finished()


func finished() -> void:
	done.emit(TYPE.TREE)
	# spawn log here
	# spawn particles
	# play sound here
	queue_free()
