extends Node

class_name Item_Use

func use_item(id: int, ship: Ship, finished: Callable):
	match id:
		9:
			start_fishing(ship, finished)
		_:
			print("Item doesnt have a defined use")


func start_fishing(ship: Ship, finished: Callable):
	ship.gameManager.hud.ddd_label("Started fishing", ship.global_position, Color.WHITE)
	await get_tree().create_timer(5.0).timeout
	var roll = randf()
	if roll > 0.5:
		var amount = randi_range(1, 5)
		ship.gameManager.hud.ddd_label("Got %s fish!" % [amount], ship.global_position, Color.GREEN)
		var pos = ship.global_position
		ship.gameManager.spawn_item_in_world(InventoryItem.new(0, amount), pos)
	else:
		ship.gameManager.hud.ddd_label("Got nothing...", ship.global_position, Color.GRAY)
	
	finished.call()
	queue_free()
