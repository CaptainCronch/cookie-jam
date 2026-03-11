extends Interactable
class_name Vision

const SMOKE_PLACE := preload("uid://b5l13itqbkklo")
const LEYLINE := preload("uid://dx4j6inx5xshv")

@export var marker: Marker2D

var leylines: Array[Line2D] = []


func _ready() -> void:
	Global.updated_fog.connect(_on_updated_fog)
	Global.fog.update(global_position)
	Global.updated_fog.emit()
	var smoke := SMOKE_PLACE.instantiate()
	smoke.global_position = global_position
	get_tree().current_scene.add_child(smoke)
	smoke.emitting = true


func _on_updated_fog() -> void:
	for line in leylines:
		line.free()
	leylines = []
	for vision in get_tree().get_nodes_in_group("Vision"):
		if vision.is_in_group("Pit"): continue
		if vision == self: continue
		var leyline := LEYLINE.instantiate()
		leyline.start = marker.global_position
		leyline.target = vision.marker.global_position
		leyline.global_position = Vector2.ZERO
		get_tree().current_scene.add_child(leyline)
		leylines.append(leyline)
