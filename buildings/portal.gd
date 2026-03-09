extends Interactable
class_name Portal


func _ready() -> void:
	Global.max_units += 1 + Global.bonus_units
	Global.bonus_units += 1
	Global.refresh_ui()
