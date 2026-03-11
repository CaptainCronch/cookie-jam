extends Interactable
class_name Bank

const SMOKE_PLACE := preload("uid://b5l13itqbkklo")

@export var alt: CompressedTexture2D
@export var alt2: CompressedTexture2D


func _ready() -> void:
	var rand := randi_range(0, 2)
	if rand == 1: $Sprite2D.texture = alt
	elif rand == 2:$Sprite2D.texture = alt2
	if Global.timer.is_stopped():
		Global.timer.start(Global.WAVE_TIME)
	
	var smoke := SMOKE_PLACE.instantiate()
	smoke.global_position = global_position
	get_tree().current_scene.add_child(smoke)
	smoke.emitting = true


func deposit(origin: Unit, type: Unit.ITEM, strength := 1) -> void:
	super(origin, type, strength)
	animator.stop()
	animator.play("interact")


func die(_origin: Enemy) -> void:
	var smoke := SMOKE_PLACE.instantiate()
	smoke.global_position = global_position
	get_tree().current_scene.add_child(smoke)
	smoke.emitting = true
	queue_free()


#func interact(origin: Unit, _strength := 1) -> void:
	#pass
