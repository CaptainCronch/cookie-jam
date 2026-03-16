extends Interactable
class_name City

const CITY_FINISH = preload("uid://qmjdo43f4poh")
const ENEMY = preload("uid://np7lmt4qtbuk")
const VICTIM = preload("uid://bgi6kgxyt0l8h")
const ARSON = preload("uid://bi5ij45ygio8m")

@export var harvest_sound: AudioStreamPlayer2D
@export var spawn_sound: AudioStreamPlayer2D


func interact(origin: Unit, strength := 1) -> bool:
	if dead: return false
	if not origin.current_item == Unit.ITEM.NONE: return false
	animator.stop()
	animator.play("interact")
	if randi_range(0, 3) == 3:
		if randi_range(0, 1) == 1:
			spawn_enemy()
		else:
			spawn_victim()
		spawn_sound.play()
	else:
		harvest_sound.play()
	health -= strength
	origin.give(item)
	if health <= 0:
		finished(origin)
	return true


func finished(_origin: Unit) -> void:
	# spawn log here? nah
	# spawn particles
	# play sound here
	remove_from_group("Cities")
	animator.play("finished")
	spawn_particles(ARSON, rotation)
	dead = true
	done.emit(item, self)
	var audio: AudioStreamPlayer2D = SELF_DESTRUCT_AUDIO_POSITIONAL.instantiate()
	audio.stream = CITY_FINISH
	audio.bus = "SFX"
	audio.global_position = global_position
	get_tree().current_scene.add_child(audio)


func spawn_enemy() -> void:
	var enemy := ENEMY.instantiate()
	enemy.global_position = global_position + Vector2(randf_range(-256, 256), randf_range(-256, 256))
	get_tree().current_scene.add_child(enemy)


func spawn_victim() -> void:
	var victim := VICTIM.instantiate()
	victim.global_position = global_position + Vector2(randf_range(-256, 256), randf_range(-256, 256))
	get_tree().current_scene.add_child(victim)
