extends Area2D
class_name Interactable

signal give(type: TYPE)
signal done(type: TYPE)

enum TYPE {NONE, TREE, MINE, BODY, ENEMY, CITY, MIXER}

@export var max_health := 10

var health := max_health


func _ready() -> void:
	input_event.connect(_on_input_event)


func interact(_strength := 1) -> void:
	give.emit(TYPE.NONE)


func finished() -> void:
	done.emit(TYPE.NONE)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			if not Input.is_action_pressed("space"):
				Global.camera.select_interactable(self)
