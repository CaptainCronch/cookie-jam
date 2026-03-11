extends Line2D

@export var offset_range := 64.0

var start: Vector2
var target: Vector2


func _ready() -> void:
	var bumps := randi_range(1, 3)
	add_point(start)
	if bumps == 2 or bumps == 3:
		add_point(start.lerp(target + get_offset(), 0.333))
	var middle_offset := get_offset() if bumps == 1 or bumps == 3 else Vector2.ZERO
	add_point(start.lerp(target + middle_offset, 0.5))
	if bumps == 2 or bumps == 3:
		add_point(start.lerp(target + get_offset(), 0.666))
	add_point(target)


func get_offset() -> Vector2:
	return Vector2(randfn(0.0, offset_range), randfn(0.0, offset_range))
