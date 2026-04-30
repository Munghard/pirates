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


func _ready() -> void:
	world = $World
	player_ship = $PlayerShip
	hud = $MarginContainer/HUD
	debugMenu = $MarginContainer/DebugMenu
	camera = $camrig/Camera3D
	camerarig = $camrig
	audioManager = $AudioManager

	assert(world != null, "world is null in gamemanager start")
	assert(player_ship != null, "player_ship is null in gamemanager start")
	assert(hud != null, "hud is null in gamemanager start")
	assert(debugMenu != null, "debugMenu is null in gamemanager start")
	assert(camera != null, "camera is null in gamemanager start")
	assert(camerarig != null, "camerarig is null in gamemanager start")
	assert(audioManager != null, "audioManager is null in gamemanager start")
	
	hud.init_hud()
	debugMenu.init_debugMenu()


func toggle_debug_menu():
	debugMenu.visible = !debugMenu.visible


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			var rotated = world.wind.target_direction.rotated(Vector3.UP, deg_to_rad(90))
			world.wind.set_direction(rotated)
		if event.keycode == KEY_F1:
			spawn_ships_around_player(1)
		if event.keycode == KEY_F2:
			toggle_debug_menu()
		if event.keycode == KEY_TAB:
			hud.toggle_player_inventory_panel()
		if event.keycode == KEY_G:
			player_ship.toggle_cannons_trajectory()

func spawn_ships_around_player(count: int):
	var enemy_ship = preload("res://Scenes/enemy_ship.tscn")
	var radius := 10.0

	for i in range(count):
		var ship: Ship = enemy_ship.instantiate()
		add_child(ship)
		
		var angle = randf() * TAU
		var _offset = Vector3(cos(angle), 0, sin(angle)) * radius
		
		ship.global_position = player_ship.global_position + _offset
		

static func get_ships_by_faction(ships: Array, target_factions: Array[FactionsData.Faction]) -> Array:
	var result = []
	for ship in ships:
		if target_factions.has(ship.faction):
			result.append(ship)
	return result

static func get_closest_ship(ships: Array, _ship: Node3D) -> Ship:
	var closest_ship: Ship = null
	var closest_dist := INF

	for ship: Ship in ships:
		var dist = _ship.global_position.distance_to(ship.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_ship = ship

	return closest_ship

#IDEAS
#figure out how to do terrain in a good way that can be plugged into water sim and shader
# minimap showing other ships and ports
# different ports, pirate port, navy port, merchant port, with different services

# BAD IDEAS
# TRY TO MAKE IT TURN BASED AND MOVEMENT USING CLICK, CREATE A VISUAL HEX GRID
