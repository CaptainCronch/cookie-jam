extends Node2D

@export var grassy_area := 20000.0
@export var amount := 20000
@export var sprites: Array[CompressedTexture2D]


func _ready() -> void:
	for i in amount:
		var sprite := Sprite2D.new()
		sprite.global_position = Vector2(randf_range(-grassy_area, grassy_area), randf_range(-grassy_area, grassy_area))
		sprite.texture = sprites[randi_range(0, sprites.size() - 1)]
		var scale_bonus := randfn(0.0, 0.1)
		sprite.scale += Vector2(scale_bonus, scale_bonus)
		sprite.scale *= 2
		sprite.offset.y = -5
		add_child(sprite)
