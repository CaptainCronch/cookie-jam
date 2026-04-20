extends Bank
class_name Pit

const UNIT := preload("uid://c772u1gct8vp4")
const BAAL = preload("uid://ca2bip7uewjlj")
const FINALE_SONG_INTRO = preload("uid://bsybjpol2pk3h")
const FINALE_SONG = preload("uid://danacw52wvu0s")

@export var level_sprites: Array[CompressedTexture2D]
@export var idol: Sprite2D
@export var music: AudioStreamPlayer
@export var wind: AudioStreamPlayer
@export var stinger: AudioStreamPlayer
@export var deposit_audio: AudioStreamPlayer2D
@export var deposit_flesh_audio: AudioStreamPlayer2D
@export var level_up_audio: AudioStreamPlayer

var level := 0
var lifetime_souls := 0
var unit: Unit = null

@onready var level_requirements := [10, 20, 50, 100, 150, 200] if not Global.CHEATS else [1, 2, 3, 4, 5, 6]


func _ready() -> void:
	Global.fog.update(global_position)
	Global.earned_soul.connect(_on_earned_soul)
	call_deferred("spawn")


func deposit(origin: Unit, type: Unit.ITEM, strength := 1) -> void:
	match type:
		Unit.ITEM.NONE:
			return
		Unit.ITEM.WOOD:
			Global.wood += strength
			Global.refresh_ui()
			animate()
			deposit_audio.play()
		Unit.ITEM.CLAY:
			Global.clay += strength
			Global.refresh_ui()
			animate()
			deposit_audio.play()
		Unit.ITEM.BODY:
			for i in (1 if not Global.CHEATS else 5): # instantly upgrade to max if cheats on
				Global.souls += 1
				Global.refresh_ui()
				deposit_flesh_audio.play()
		Unit.ITEM.ASH:
			Global.ash += strength
			Global.refresh_ui()
			animate()
			deposit_audio.play()
		Unit.ITEM.GLASSY_CLAY:
			Global.glassy_clay += strength
			Global.refresh_ui()
			animate()
			deposit_audio.play()
	origin.current_item = Unit.ITEM.NONE


func animate() -> void:
	if not animator.current_animation == "interact_level_up" and not animator.current_animation == "interact_flesh":
		animator.stop()
		animator.play("interact")


func spawn() -> void:
	if not is_instance_valid(unit):
		if Global.units < Global.max_units:
			var new := UNIT.instantiate()
			new.global_position = global_position + Vector2(0, 256)
			get_tree().current_scene.add_child(new)
			unit = new


func level_up() -> void:
	$Shadow.show()
	idol.texture = level_sprites[min(level, 4)]
	level += 1
	match level:
		1:
			Global.ui.unlocked_buildings[2] = true
			level_up_audio.play()
		2:
			Global.ui.unlocked_buildings[3] = true
			level_up_audio.play()
		3:
			Global.ui.unlocked_buildings[4] = true
			level_up_audio.play()
		4:
			Global.ui.unlocked_buildings[5] = true
			level_up_audio.play()
		5:
			#Global.ui.victory_text.show()
			music.stop()
			wind.stop()
			stinger.play()
			var creature := BAAL.instantiate()
			creature.global_position = global_position
			Global.baal = creature
			get_tree().current_scene.add_child(creature)
			Global.baal_spawned.emit()
		#6:
			#Global.ui.victory_text.get_child(0).text = "Will you quit already"


func die(_var) -> void:
	pass


func fire() -> void:
	pass


func _on_timer_timeout() -> void:
	spawn()


func _on_earned_soul() -> void:
	lifetime_souls += 1
	if lifetime_souls >= level_requirements[level]:
		animator.stop()
		animator.play("interact_level_up")
		level_up()
	else:
		if not animator.current_animation == "interact_level_up":
			animator.stop()
			animator.play("interact_flesh")


func _on_stinger_finished() -> void:
	music.stream = FINALE_SONG_INTRO
	music.play()
	wind.play()


func _on_music_finished() -> void:
	music.stream = FINALE_SONG
	music.play()
