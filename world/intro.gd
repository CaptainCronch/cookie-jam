extends Control

const MAIN := preload("uid://ceo1vya1vw0r8")
const IMAGES: Array[CompressedTexture2D] = [
	preload("uid://c3uhme4m5gkms"), 
	preload("uid://cb3oxufp6baxh"), 
	preload("uid://1nabrcfq56uk"), 
	preload("uid://b5uskbgm04qpr"), 
	preload("uid://cdkwll84sqisg"),
]

@export var slide: TextureRect

var index := 0


func _ready() -> void:
	slide.texture = IMAGES[index]


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("any"):
		index += 1
		if index >= IMAGES.size() - 1:
			get_tree().change_scene_to_packed(MAIN)
			return
		slide.texture = IMAGES[index]
