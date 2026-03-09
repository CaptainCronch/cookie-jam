extends Interactable
class_name City

const ENEMY = preload("uid://np7lmt4qtbuk")
const VICTIM = preload("uid://bgi6kgxyt0l8h")


func interact(origin: Unit, strength := 1) -> void:
	if not origin.current_item == Unit.ITEM.NONE: return
	if randi_range(0, 4) == 4:
		if randi_range(0, 1) == 1:
			spawn_enemy()
		else:
			spawn_victim()
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


func spawn_enemy() -> void:
	var enemy := ENEMY.instantiate()
	enemy.global_position = global_position + Vector2(randf_range(-256, 256), randf_range(-256, 256))
	get_tree().current_scene.add_child(enemy)


func spawn_victim() -> void:
	var victim := VICTIM.instantiate()
	victim.global_position = global_position + Vector2(randf_range(-256, 256), randf_range(-256, 256))
	get_tree().current_scene.add_child(victim)
