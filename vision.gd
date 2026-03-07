extends Interactable
class_name Vision


func _ready() -> void:
	Global.fog.update(global_position)
