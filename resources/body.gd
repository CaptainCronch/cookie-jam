extends Interactable
class_name Body

const BODY_HARVEST = preload("uid://ddta7povto4wc")


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
	var audio: AudioStreamPlayer2D = SELF_DESTRUCT_AUDIO_POSITIONAL.instantiate()
	audio.stream = BODY_HARVEST
	audio.bus = "SFX"
	audio.global_position = global_position
	get_tree().current_scene.add_child(audio)
	queue_free()
