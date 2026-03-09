extends Bank
class_name Pit

const UNIT := preload("uid://c772u1gct8vp4")
const LEVEL_REQUIREMENTS := [10, 20, 50, 100, 150, 200]

@export var level_sprites: Array[CompressedTexture2D]
@export var idol: Sprite2D
@export var music: AudioStreamPlayer
@export var wind: AudioStreamPlayer
@export var stinger: AudioStreamPlayer

var level := 0
var lifetime_souls := 0
var unit: Unit = null


func _ready() -> void:
	Global.fog.update(global_position)
	Global.earned_soul.connect(_on_earned_soul)
	call_deferred("spawn")


func spawn() -> void:
	if not is_instance_valid(unit):
		if Global.units < Global.max_units:
			var new := UNIT.instantiate()
			new.global_position = global_position + Vector2(0, 256)
			get_tree().current_scene.add_child(new)
			unit = new


func level_up() -> void:
	$Shadow.show()
	idol.texture = level_sprites[level]
	level += 1
	match level:
		1:
			Global.ui.unlocked_buildings[2] = true
		2:
			Global.ui.unlocked_buildings[3] = true
		3:
			Global.ui.unlocked_buildings[4] = true
		4:
			Global.ui.unlocked_buildings[5] = true
		5:
			Global.ui.victory_text.show()
			music.stop()
			wind.stop()
			stinger.play()
		6:
			Global.ui.victory_text.get_child(0).text = "Will you quit already"


func _on_timer_timeout() -> void:
	spawn()


func _on_earned_soul() -> void:
	lifetime_souls += 1
	if lifetime_souls >= LEVEL_REQUIREMENTS[level]:
		level_up()


func _on_stinger_finished() -> void:
	music.play()
	wind.play()
