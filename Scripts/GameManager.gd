extends Node3D

class_name GameManager

@export_group("Nodes")
var world: World
var player_ship: PlayerShip
var hud: HUD
var camera: Camera3D
var camerarig: Camera
var audioManager: AudioManager
var debugMenu: DebugMenu
var save_manager: SaveManager

var selected_ship: Ship

var world_item: PackedScene = preload("res://Scenes/loot.tscn")

func _enter_tree() -> void:
	# set world seed
	seed(1)

func _ready() -> void:
	print(randi())

	world = $SubViewportContainer/SubViewport/World
	player_ship = $SubViewportContainer/SubViewport/World/PlayerShip
	hud = $MarginContainer/HUD
	debugMenu = $MarginContainer/DebugMenu
	camera = $SubViewportContainer/SubViewport/camera_rig/Camera3D
	camerarig = $SubViewportContainer/SubViewport/camera_rig
	audioManager = $SubViewportContainer/SubViewport/AudioManager
	save_manager = $SaveManager

	assert(world != null, "world is null in gamemanager start")
	assert(player_ship != null, "player_ship is null in gamemanager start")
	assert(hud != null, "hud is null in gamemanager start")
	assert(debugMenu != null, "debugMenu is null in gamemanager start")
	assert(camera != null, "camera is null in gamemanager start")
	assert(camerarig != null, "camerarig is null in gamemanager start")
	assert(audioManager != null, "audioManager is null in gamemanager start")
	assert(save_manager != null, "save_manager is null in gamemanager start")
	
	hud.init_hud()
	debugMenu.init_debugMenu()
	hud.toggle_map()
	
	start_auto_save_game()
	
	# autoload last game
	
	await get_tree().process_frame
	save_manager.load_game(self )

func start_auto_save_game():
	while true:
		await get_tree().create_timer(180.0).timeout
		save_manager.save_game(self )
		

func spawn_item_in_world(item: InventoryItem, _position: Vector3):
	var w_item = world_item.instantiate() as Loot
	world.add_child(w_item)
	w_item.setup_loot(item, self )
	w_item.global_position = _position
	w_item.global_rotation_degrees.y = randf() * 360.0

func select_ship(ship: Ship):
	if selected_ship and selected_ship.is_inside_tree():
		if selected_ship.navigation_markers: selected_ship.navigation_markers.visible = false
		if selected_ship.world_bars: selected_ship.world_bars.visible = false
	selected_ship = ship
	if selected_ship and selected_ship.is_inside_tree():
		if selected_ship.navigation_markers: selected_ship.navigation_markers.visible = true
		if selected_ship.world_bars: selected_ship.world_bars.visible = true

func toggle_debug_menu():
	debugMenu.visible = !debugMenu.visible


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			var rotated = world.wind.target_direction.rotated(Vector3.UP, deg_to_rad(90))
			world.wind.set_direction(rotated)
		if event.keycode == KEY_F1:
			spawn_ships_around_player(1, 10.0)
		if event.keycode == KEY_F2:
			toggle_debug_menu()
		if event.keycode == KEY_F3:
			move_player_to_random_port()
		if event.keycode == KEY_TAB:
			hud.toggle_player_inventory_panel()
		if event.keycode == KEY_M:
			hud.toggle_map()
		if event.keycode == KEY_CAPSLOCK:
			hud.toggle_equipment_panel()
		if event.keycode == KEY_F5:
			save_manager.save_game(self )
		if event.keycode == KEY_F6:
			save_manager.load_game(self )

func move_player_to_random_port():
	var ports = get_tree().get_nodes_in_group("Ports")
	var port: Port = ports[randi_range(0, ports.size() - 1)]
	var water_pos = port.get_valid_water_position()
	var dir = (water_pos - port.global_position).normalized()
	var angle_rad = atan2(dir.x, dir.z)
	var angle_deg = rad_to_deg(angle_rad)
	player_ship.global_position = water_pos
	player_ship.rotation.y = angle_rad
	player_ship.yaw_deg = angle_deg

func spawn_ships_around_player(count: int, radius: float) -> Array[Ship]:
	var enemy_ship = preload("res://Scenes/enemy_ship.tscn")
	
	var ships: Array[Ship] = []
	for i in range(count):
		var ship: Ship = enemy_ship.instantiate() as Ship
		add_child(ship)
		
		var angle = randf() * TAU
		var _offset = Vector3(cos(angle), 0, sin(angle)) * radius
		
		ship.global_position = player_ship.global_position + _offset
		ships.append(ship)
	
	return ships
		

static func get_ships_by_faction(ships: Array[Ship], target_factions: Array[FactionsData.Faction]) -> Array[Ship]:
	var result: Array[Ship] = []

	for ship in ships:
		if target_factions.has(ship.faction):
			result.append(ship)

	return result

static func get_closest_ship(ships: Array[Ship], _ship: Node3D) -> Ship:
	var closest_ship: Ship = null
	var closest_dist := INF

	for ship in ships:
		var dist = _ship.global_position.distance_to(ship.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_ship = ship

	return closest_ship

static func get_closest_port(ports: Array[Port], node: Node3D) -> Port:
	var closest_port: Port
	var closest_dist := INF

	for port in ports:
		var dist := node.global_position.distance_squared_to(port.global_position)

		if dist < closest_dist:
			closest_dist = dist
			closest_port = port

	return closest_port
#IDEAS
#figure out how to do terrain in a good way that can be plugged into water sim and shader
# minimap showing other ships and ports
# different ports, pirate port, navy port, merchant port, with different services

# BAD IDEAS
# TRY TO MAKE IT TURN BASED AND MOVEMENT USING CLICK, CREATE A VISUAL HEX GRID
