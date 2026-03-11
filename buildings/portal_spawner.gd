extends Interactable
class_name PortalSpawner

const UNIT = preload("uid://c772u1gct8vp4")
const SMOKE_PLACE = preload("uid://b5l13itqbkklo")

var unit: Unit = null


func _ready() -> void:
	call_deferred("spawn")
	var smoke := SMOKE_PLACE.instantiate()
	smoke.global_position = global_position
	get_tree().current_scene.add_child(smoke)
	smoke.emitting = true


func spawn() -> void:
	if not is_instance_valid(unit):
		if Global.units < Global.max_units:
			var new := UNIT.instantiate()
			new.global_position = global_position + Vector2(0, 64)
			get_tree().current_scene.add_child(new)
			unit = new


func _on_timer_timeout() -> void:
	spawn()
