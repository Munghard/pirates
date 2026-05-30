extends Node

class_name Territory

var territories: Array[Territory_Data] = []
signal territories_changed(_territories: Array[Territory_Data])
signal ownership_changed()
var grouped := {}
var territory_radius = 128.0
var cell_size = 2
var ownership = {}
var faction_cells := {}
@onready var gameManager: GameManager = get_node("/root/GameManager")

func _ready():
	await get_tree().process_frame
	
	var ports = gameManager.world.ports
	
	for port in ports:
		port.port_faction_changed.connect(func(_faction): create_grid_territories(ports))
	
	create_grid_territories(ports)
	gameManager.save_manager.loaded.connect(func():
		var _ports = gameManager.world.ports
		for port in ports:
			port.port_faction_changed.connect(func(_faction): create_grid_territories(ports))
		create_grid_territories(_ports)
		print("Recreated territories after load")
		)
	
	ownership_changed.connect(func(): gameManager.hud.update_influence_panel())

func create_grid_territories(ports: Array[Port]):
	ownership.clear()
	faction_cells.clear()
	var counter := 0
	const CELLS_PER_FRAME := 200

	for x in range(0, gameManager.world.terrain.terrain_world_size.x, cell_size):
		for y in range(0, gameManager.world.terrain.terrain_world_size.y, cell_size):
			var pos = Vector2(x, y)

			var faction = get_strongest_faction(pos, ports)

			var cell = Vector2i(x / cell_size, y / cell_size)

			ownership[cell] = faction
			
			if not faction_cells.has(faction):
				faction_cells[faction] = []

			faction_cells[faction].append(cell)
			counter += 1
			if counter >= CELLS_PER_FRAME:
				counter = 0
				await get_tree().process_frame

	ownership_changed.emit()
	gameManager.check_win_condition()

func get_random_point_in_territory(faction: FactionsData.Faction) -> Vector2:
	var cells = faction_cells.get(faction, [])

	if faction == FactionsData.Faction.NONE:
		cells = []

		for faction_array in faction_cells.values():
			cells.append_array(faction_array)

	if cells.is_empty():
		return Vector2.ZERO

	return cells.pick_random()

func create_territories_old_method():
	var ports = gameManager.world.ports

	# first split into arrays of same faction
	for port in ports:
		var faction = port.allegiance.faction
		
		if not grouped.has(faction):
			grouped[faction] = []
		
		grouped[faction].append(port)
	
	for faction in grouped.keys():
		var faction_ports: Array = grouped[faction]
		
		var points := PackedVector2Array()
		
		for port in faction_ports:
			var pos2 = Vector2(port.global_position.x, port.global_position.z)
			
			var circle_points := make_circle_points(pos2, territory_radius, 6)
			points.append_array(circle_points) # or whatever defines territory shape

		var hull = Geometry2D.convex_hull(points)
		
		var territory := Territory_Data.new(hull, faction)
		add_territory(territory)

func make_circle_points(center: Vector2, radius: float, steps: int = 12) -> PackedVector2Array:
	var points := PackedVector2Array()
	
	for i in range(steps):
		var angle = TAU * float(i) / float(steps)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	return points

func create_test_territory():
	var points := PackedVector2Array([
		Vector2(10.0, 10.0),
		Vector2(50.0, 10.0),
		Vector2(50.0, 50.0),
		Vector2(10.0, 50.0),
	])
	var faction := FactionsData.Faction.PIRATE
	var test_territory := Territory_Data.new(points, faction)
	add_territory(test_territory)


func add_territory(_terriory: Territory_Data):
	territories.append(_terriory)
	territories_changed.emit(territories)

func get_territory_at(pos: Vector2) -> FactionsData.Faction:
	var cell = Vector2i(
		floor(pos.x / cell_size),
		floor(pos.y / cell_size)
	)
	return ownership.get(cell, FactionsData.Faction.NONE)

func get_territories_at(pos: Vector2) -> Array[FactionsData.Faction]:
	var factions: Array[FactionsData.Faction] = []
	for territory in territories:
		if Geometry2D.is_point_in_polygon(pos, territory.points):
			factions.append(territory.faction)
	return factions

func get_strongest_faction(pos: Vector2, ports: Array[Port]) -> FactionsData.Faction:
	var best_faction = FactionsData.Faction.NONE
	var best_score = - INF

	for port in ports:
		if port == null:
			continue
		var port_pos = Vector2(
			port.global_position.x,
			port.global_position.z
		)

		var dist = pos.distance_to(port_pos)

		var influence = max(0.0, territory_radius - dist)

		if influence > best_score:
			best_score = influence
			best_faction = port.allegiance.faction

	return best_faction

func get_closest_port(pos: Vector2, ports: Array[Port]) -> Port:
	var best_port = null
	var best_dist = INF

	for port in ports:
		var p = Vector2(port.global_position.x, port.global_position.z)
		var d = pos.distance_squared_to(p)

		if d < best_dist:
			best_dist = d
			best_port = port

	return best_port

func get_faction_influence(faction: FactionsData.Faction) -> float:
	var total_cells = 0
	var _faction_cells = 0

	for cell in ownership.keys():
		total_cells += 1
		if ownership[cell] == faction:
			_faction_cells += 1

	if total_cells == 0:
		return 0.0

	return float(_faction_cells) / float(total_cells)
