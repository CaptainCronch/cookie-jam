extends Interactable
class_name Bank

@export var alt: CompressedTexture2D


func _ready() -> void:
	if randi_range(0, 1) == 1: $Sprite2D.texture = alt


#func interact(origin: Unit, _strength := 1) -> void:
	#pass
