extends Interactable
class_name Portal

const SMOKE_PLACE = preload("uid://b5l13itqbkklo")


func _ready() -> void:
	Global.max_units += 1 + Global.bonus_units
	Global.bonus_units += 1
	Global.refresh_ui()
	var smoke := SMOKE_PLACE.instantiate()
	smoke.global_position = global_position
	get_tree().current_scene.add_child(smoke)
	smoke.emitting = true


func damage(origin: Enemy, strength := 1) -> void:
	if dead: return
	health -= strength
	animator.stop()
	animator.play("hurt")
	hit_audio.play()
	if health <= 0:
		die(origin)


func die(_origin: Enemy) -> void:
	dead = true
	Global.bonus_units -= 1
	Global.max_units -= 1 + Global.bonus_units
	Global.refresh_ui()
	var smoke := SMOKE_PLACE.instantiate()
	smoke.global_position = global_position
	get_tree().current_scene.add_child(smoke)
	smoke.emitting = true
	var audio: AudioStreamPlayer2D = SELF_DESTRUCT_AUDIO_POSITIONAL.instantiate()
	audio.stream = BUILDING_FINISH
	audio.bus = "SFX"
	audio.global_position = global_position
	get_tree().current_scene.add_child(audio)
	queue_free()
