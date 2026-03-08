extends Interactable
class_name ClayDeposit

var dead := false


func interact(origin: Unit, strength := 1) -> void:
	if dead: return
	if not origin.current_item == Unit.ITEM.NONE: return
	health -= strength
	origin.give(item)
	if health <= 0:
		finished(origin)


func finished(_origin: Unit) -> void:
	# spawn log here? nah
	# spawn particles
	# play sound here
	dead = true
	remove_from_group("Deposits")
	done.emit(item)
	$Sprite2D.hide()
	$Sprite2D2.show()


func revive() -> void:
	$Sprite2D2.hide()
	$Sprite2D3.show()
	dead = false
	add_to_group("Deposits")
	health = INF
