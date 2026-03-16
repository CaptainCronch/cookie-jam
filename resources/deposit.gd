extends Interactable
class_name ClayDeposit

const CLAY_DROPS = preload("uid://cypx0xe27be6w")

@export var harvest_audio: AudioStreamPlayer2D
@export var finish_audio: AudioStreamPlayer2D
@export var spawn_audio: AudioStreamPlayer2D


func interact(origin: Unit, strength := 1) -> bool:
	if dead: return false
	if not origin.current_item == Unit.ITEM.NONE: return false
	if animator.is_playing(): animator.stop()
	animator.play("interact")
	health -= strength
	origin.give(item)
	harvest_audio.play()
	if health <= 0:
		finished(origin)
	return true


func finished(_origin: Unit) -> void:
	# spawn log here? nah
	# spawn particles
	# play sound here
	dead = true
	finish_audio.play()
	remove_from_group("Resource")
	remove_from_group("Deposits")
	spawn_particles(CLAY_DROPS, rotation)
	done.emit(item, self)
	if animator.is_playing(): animator.stop()
	animator.play("finish")
	#$Sprite2D.hide()
	#$Sprite2D2.show()
	#$Sprite2D3.hide()


func revive() -> void:
	if animator.is_playing(): animator.stop()
	animator.play("RESET")
	$Sprite2D.hide()
	$Sprite2D2.hide()
	$Sprite2D3.show()
	dead = false
	add_to_group("Resource")
	add_to_group("Deposits")
	spawn_audio.play()
	health = 120
