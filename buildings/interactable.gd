extends Area2D
class_name Interactable

const SELF_DESTRUCT_AUDIO_POSITIONAL := preload("uid://cl3nvgh1e7s7v")
const BUILDING_HIT := preload("uid://hncw520gobm4")
const BUILDING_FINISH := preload("uid://klhgoetryh7o")

#signal give(type: TYPE)
#signal deposited()
signal done(type: Unit.ITEM, who: Interactable)

@export var max_health := 10
@export var item: Unit.ITEM = Unit.ITEM.NONE
@export var is_resource := false
@export var push_force := 2.0
@export var animator: AnimationPlayer
@export var hit_audio: AudioStreamPlayer2D

var can_be_selected := true
var dead := false

@onready var health := max_health


func _ready() -> void:
	input_event.connect(_on_input_event)


func _process(_delta: float) -> void:
	can_be_selected = true


func interact(_origin: Unit, _strength := 1) -> bool:
	return true


func deposit(origin: Unit, type: Unit.ITEM, strength := 1) -> void:
	match type:
		Unit.ITEM.NONE:
			return
		Unit.ITEM.WOOD:
			Global.wood += strength
			Global.refresh_ui()
		Unit.ITEM.CLAY:
			Global.clay += strength
			Global.refresh_ui()
		Unit.ITEM.BODY:
			Global.souls += 1
			Global.refresh_ui()
		Unit.ITEM.ASH:
			Global.ash += strength
			Global.refresh_ui()
		Unit.ITEM.GLASSY_CLAY:
			Global.glassy_clay += strength
			Global.refresh_ui()
	origin.current_item = Unit.ITEM.NONE


func damage(origin: Enemy, strength := 1) -> void:
	if dead: return
	health -= strength
	hit_audio.play()
	if health <= 0:
		die(origin)


func finished(_origin: Unit) -> void:
	pass


func die(_origin: Enemy) -> void:
	dead = true
	var audio: AudioStreamPlayer2D = SELF_DESTRUCT_AUDIO_POSITIONAL.instantiate()
	audio.stream = BUILDING_FINISH
	audio.bus = "SFX"
	audio.global_position = global_position
	get_tree().current_scene.add_child(audio)
	queue_free()


func spawn_particles(scene: PackedScene, radians: float, where := global_position) -> void:
	var new: CPUParticles2D = scene.instantiate()
	new.global_position = where
	new.rotation = radians
	get_tree().current_scene.add_child(new)
	new.emitting = true


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and event.pressed:
			if not Input.is_action_pressed("space") and can_be_selected:
				Global.camera.select_interactable(self)
				can_be_selected = false
