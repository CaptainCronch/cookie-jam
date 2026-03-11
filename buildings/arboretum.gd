extends Interactable
class_name Arboretum

const TREE := preload("uid://bc0n2usldvntm")
const SMOKE_PLACE = preload("uid://b5l13itqbkklo")

@export var max_range := 512.0
@export var min_range := 128.0
@export var tree_limit := 10

@export var timer: Timer

var trees: Array[WoodTree] = []


func _ready() -> void:
	super()
	var smoke := SMOKE_PLACE.instantiate()
	smoke.global_position = global_position
	get_tree().current_scene.add_child(smoke)
	smoke.emitting = true


func _on_timer_timeout() -> void:
	if trees.size() >= tree_limit: return
	
	var tree: WoodTree = TREE.instantiate()
	var distance := randf_range(min_range, max_range)
	var direction := Vector2.RIGHT.rotated(randf_range(0, TAU))
	tree.global_position = global_position + (direction * distance)
	get_tree().current_scene.add_child(tree)
	trees.append(tree)
	tree.done.connect(_on_tree_done)


func _on_tree_done(_item: Unit.ITEM, which: Interactable) -> void:
	trees.erase(which)
