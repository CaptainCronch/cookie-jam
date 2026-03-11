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


func die(_origin: Enemy) -> void:
	Global.bonus_units -= 1
	Global.max_units -= 1 + Global.bonus_units
	Global.refresh_ui()
	var smoke := SMOKE_PLACE.instantiate()
	smoke.global_position = global_position
	get_tree().current_scene.add_child(smoke)
	smoke.emitting = true
	queue_free()
