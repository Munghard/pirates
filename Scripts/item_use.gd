extends Node

class_name Item_Use

func use_item(id: int, ship: Ship, finished: Callable):
	match id:
		9:
			start_fishing(ship, finished)
		13:
			start_ship_repair(ship, 10.0, finished)
		_:
			finished.call(false)
			print("Item doesnt have a defined use")

func start_ship_repair(ship: Ship, repair_amount: float, finished: Callable):
	var tick = 5
	var tick_interval = 5.0
	var hp_missing = ship.max_hit_points - ship.hit_points
	var repaired = min(repair_amount, hp_missing)
	for t in tick:
		if is_instance_valid(ship):
			ship.gameManager.hud.ddd_label("Repaired hull: %s" % [repaired], ship.global_position, Color.GREEN)
			ship.gain_hitpoints(repaired)
			await get_tree().create_timer(tick_interval).timeout
		else:
			break
	finished.call(true)
		

func start_fishing(ship: Ship, finished: Callable):
	ship.gameManager.hud.ddd_label("Started fishing", ship.global_position, Color.WHITE)
	var pos = ship.global_position
	await get_tree().create_timer(5.0).timeout
	var roll = randf()
	if roll > 0.5:
		var amount = randi_range(1, 5)
		ship.gameManager.hud.ddd_label("Got %s fish!" % [amount], ship.global_position, Color.GREEN)
		ship.gameManager.spawn_item_in_world(InventoryItem.new(0, amount), pos)
	else:
		ship.gameManager.hud.ddd_label("Got nothing...", ship.global_position, Color.GRAY)
	
	finished.call(true)
