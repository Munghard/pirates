extends Node

class_name SaveManager

const SAVE_PATH := "user://savegame.json"
signal loaded

func _write(data: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))


func _read() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var result = JSON.parse_string(content)

	return result if typeof(result) == TYPE_DICTIONARY else {}

func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Savefile deleted")
	
func load_game(gameManager: GameManager):
	var data = _read()
	if data.is_empty():
		return

	var player_data = data.get("player", {})

	var player_ship = gameManager.player_ship


	player_ship.inventory = load_inventory(
		player_ship,
		gameManager.world,
		player_data.get("inventory", [])
	)
	player_ship.connect_inventory_listeners(player_ship.inventory)

	player_ship.equipment = load_equipment(player_data.get("equipment", {}))
	player_ship.equipment.equipment_changed.connect(func(_side): player_ship.setup_cannons())
	player_ship.gameManager.hud.equipment_panel.init_equipment_panel(player_ship)
	
	player_ship.setup_cannons()
	
	player_ship.gameManager.hud.equipment_panel.init_equipment_panel(player_ship)

	gameManager.player_ship = player_ship

	load_ship_stats(gameManager.player_ship, player_data)

	var ports_data := Port_Data.from_dict_array(data.get("ports", []))
	gameManager.world.spawn_ports_from_data(ports_data)
	
	load_player_transform(gameManager.player_ship, player_data)
	
	gameManager.territory_draw.rebuild_visual_cache()

	var time_data = data.get("time", {})
	gameManager.world.time.time_of_day = time_data.get("time_of_day", 0.0)
	gameManager.world.time.day_count = time_data.get("day", 0)

	print("loaded game")
	loaded.emit()

func load_inventory(player_ship: PlayerShip, _world, data: Array) -> Inventory:
	var inventory := Inventory.new(player_ship, _world, 16, "Player")

	inventory.items.clear()
	for item_data in data:
		var item = _load_item(item_data)
		inventory.items.append(item)

	return inventory

static func create_inventory_from_data(_owner: Node3D, owner_name: String, _world, data: Array) -> Inventory:
	var inventory := Inventory.new(_owner, _world, 16, owner_name)

	inventory.items.clear()
	for item_data in data:
		var item = _load_item(item_data)
		inventory.items.append(item)

	return inventory

func load_equipment(data: Dictionary) -> Equipment:
	var equipment := Equipment.new()

	equipment.bow = _load_item_list(data.get("bow", []))
	equipment.port = _load_item_list(data.get("port", []))
	equipment.starboard = _load_item_list(data.get("starboard", []))

	return equipment

func _load_item_list(data: Array) -> Array[InventoryItem]:
	var items: Array[InventoryItem] = []

	for item_data in data:
		items.append(_load_item(item_data))

	return items

static func _load_item(data: Dictionary) -> InventoryItem:
	if data.is_empty():
		return null

	var item = InventoryItem.new(data.get("id", ""), data.get("amount", 0))
	item.unique_id = data.get("unique_id", "")

	return item

func load_player_transform(player_ship: PlayerShip, data: Dictionary):
	var t = data.get("transform", {})
	var pos = t.get("position", {})
	player_ship.global_position = Vector3(
		pos.get("x", 0),
		pos.get("y", 0),
		pos.get("z", 0)
	)

	var rot = data.get("rotation", {})
	player_ship.global_rotation = Vector3(
		rot.get("x", 0),
		rot.get("y", 0),
		rot.get("z", 0)
	)

	player_ship.yaw_deg = data.get("yaw_deg", 0)

func load_ship_stats(player_ship: PlayerShip, data: Dictionary):
	var t = data.get("stats", {})

	player_ship.ship_name = t.get("ship_name", "")
	player_ship.faction = t.get("faction", "")
	player_ship.nation = t.get("nation", "")

	player_ship.level = t.get("level", 1)

	player_ship.top_speed = t.get("topspeed", 0.0)

	player_ship.max_crew = t.get("crew_max", 0)
	player_ship.crew = t.get("crew", 0)

	player_ship.agility = t.get("agility", 0)
	player_ship.attack = t.get("attack", 0)

	player_ship.gold = t.get("gold", 0)

	player_ship.morale = t.get("morale", 0)

	player_ship.max_hit_points = t.get("hp_max", 0)
	player_ship.hit_points = t.get("hp_current", 0)

	player_ship.emit_signal("hit_points_changed", player_ship.hit_points)
	player_ship.emit_signal("crew_changed", player_ship.crew)
	player_ship.emit_signal("gold_changed", player_ship.gold)
	player_ship.emit_signal("morale_changed", player_ship.morale)


## ================================================================================================================
## SAVE 
## ================================================================================================================

func save_game(gameManager: GameManager):
	var data = {
		"player": {
			"inventory": save_inventory(gameManager.player_ship.inventory),
			"equipment": save_equipment(gameManager.player_ship.equipment),
			"transform": save_player_transform(gameManager.player_ship),
			"stats": save_ship_stats(gameManager.player_ship)
		},
		"ports": save_ports(gameManager.world.ports),
		"time": {
			"time_of_day": gameManager.world.time.time_of_day,
			"day": gameManager.world.time.day_count
		}
	}

	_write(data)
	print("saved game")

func save_player_transform(player_ship: PlayerShip) -> Dictionary:
	return {
		"position": {
			"x": player_ship.global_position.x,
			"y": player_ship.global_position.y,
			"z": player_ship.global_position.z
		},
		"rotation": {
			"x": player_ship.global_rotation.x,
			"y": player_ship.global_rotation.y,
			"z": player_ship.global_rotation.z
		},
		"yaw_deg": player_ship.yaw_deg
	}
static func save_inventory(inventory: Inventory) -> Array:
	var items = []

	for item in inventory.items:
		items.append(_save_item(item))

	return items

func save_ship_stats(ship: Ship) -> Dictionary:
	var data = {}

	data["ship_name"] = ship.ship_name
	data["faction"] = ship.faction
	data["nation"] = ship.nation
	data["level"] = ship.level
	data["topspeed"] = ship.top_speed
	data["crew_max"] = ship.max_crew
	data["crew"] = ship.crew
	data["agility"] = ship.agility
	data["attack"] = ship.attack
	data["gold"] = ship.gold
	data["morale"] = ship.morale
	data["hp_max"] = ship.max_hit_points
	data["hp_current"] = ship.hit_points

	return data

func save_equipment(equipment: Equipment) -> Dictionary:
	var data = {}

	data["bow"] = _save_item_list(equipment.bow)
	data["port"] = _save_item_list(equipment.port)
	data["starboard"] = _save_item_list(equipment.starboard)

	return data

func _save_item_list(items: Array) -> Array:
	var result = []

	for item in items:
		result.append(_save_item(item))

	return result

static func _save_item(item: InventoryItem) -> Dictionary:
	if item == null:
		return {}

	return {
		"unique_id": item.unique_id,
		"id": item.id,
		"amount": item.stack
	}

func save_ports(ports: Array[Port]) -> Array:
	var result = []

	for port in ports:
		result.append({
			"name": port.port_name,
			"faction": port.allegiance.faction,
			"nation": port.allegiance.nation,
			"position": {
				"x": port.global_position.x,
				"y": port.global_position.y,
				"z": port.global_position.z
			},
			"inventory": save_inventory(port.inventory)
		})

	return result
