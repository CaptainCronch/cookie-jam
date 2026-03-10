extends Sprite2D
class_name Clouds

@onready var shader: ShaderMaterial = material


func _ready() -> void:
	shader.set_shader_parameter("alpha", 1.0)


func change_clouds(value: float) -> void:
	shader.set_shader_parameter("alpha", value)
