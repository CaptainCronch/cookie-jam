extends CanvasLayer
class_name UI

@export var wood_label: Label
@export var clay_label: Label
@export var souls_label: Label
@export var ash_label: Label
@export var glassy_clay_label: Label


func _ready() -> void:
	Global.ui = self
