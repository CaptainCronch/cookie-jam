extends Interactable
class_name Bank

@export var alt: CompressedTexture2D
@export var alt2: CompressedTexture2D


func _ready() -> void:
	var rand := randi_range(0, 2)
	if rand == 1: $Sprite2D.texture = alt
	elif rand == 2:$Sprite2D.texture = alt2


#func interact(origin: Unit, _strength := 1) -> void:
	#pass
