extends Node3D

class_name GameManager
@export_group("Settings")
@export var _seed = 3

@export_group("Nodes")
var world: World
var player_ship: PlayerShip
var hud: HUD
var camera: Camera3D
var camerarig: Camera
var audioManager: AudioManager
var debugMenu: DebugMenu
var save_manager: SaveManager
var territory: Territory
var territory_draw: Control
var sub_viewport_container: SubViewportContainer

var wiki: Wiki

var selected_ship: Ship
var hovered_ship: Ship

var spectator: Spectator
var spectator_mode := false

var world_item: PackedScene = preload("res://Scenes/loot.tscn")
var game_seed := 0

var stash: Inventory

func _enter_tree() -> void:
	# set world seed
	seed(GameState.game_seed)

func _ready() -> void:
	world = $SubViewportContainer/SubViewport/World
	player_ship = $SubViewportContainer/SubViewport/World/PlayerShip
	hud = $MarginContainer/HUD
	debugMenu = $MarginContainer/DebugMenu
	camera = $SubViewportContainer/SubViewport/camera_rig/Camera3D
	camerarig = $SubViewportContainer/SubViewport/camera_rig
	audioManager = $SubViewportContainer/SubViewport/AudioManager
	save_manager = $SaveManager
	territory = $Territory
	territory_draw = hud.map.territory_draw
	spectator = $Spectator
	sub_viewport_container = $SubViewportContainer
	wiki = Wiki.new()
	stash = Inventory.new(self , world, 32, "Stash")

	assert(world != null, "world is null in gamemanager start")
	assert(player_ship != null, "player_ship is null in gamemanager start")
	assert(hud != null, "hud is null in gamemanager start")
	assert(debugMenu != null, "debugMenu is null in gamemanager start")
	assert(camera != null, "camera is null in gamemanager start")
	assert(camerarig != null, "camerarig is null in gamemanager start")
	assert(audioManager != null, "audioManager is null in gamemanager start")
	assert(save_manager != null, "save_manager is null in gamemanager start")
	assert(territory != null, "territory is null in gamemanager start")
	assert(territory_draw != null, "territory_draw is null in gamemanager start")
	assert(spectator != null, "spectator is null in gamemanager start")
	assert(sub_viewport_container != null, "sub_viewport_container is null in gamemanager start")
	assert(wiki != null, "wiki is null in gamemanager start")
	assert(stash != null, "stash is null in gamemanager start")
	
	player_ship.ship_name = GameState.player_name


	# load before initializing hud etc.
	await get_tree().process_frame
	await get_tree().process_frame
	save_manager.load_game(self )

	hud.init_hud()
	debugMenu.init_debugMenu()
	hud.toggle_map()
	
	start_auto_save_game()
	
	# autoload last game
	
	self.process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	
	hud.wiki_ui.create_tree(wiki)

func _process(_delta: float) -> void:
	update_hover()

func update_hover():
	var mouse_pos = get_viewport().get_mouse_position()

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space = camera.get_world_3d().direct_space_state
	var result = space.intersect_ray(
		PhysicsRayQueryParameters3D.create(from, to)
	)

	var new_hover: Ship = null

	if result and result.collider is Ship:
		new_hover = result.collider

	# nothing changed
	if new_hover == hovered_ship:
		return

	# clear old hover
	if hovered_ship and is_instance_valid(hovered_ship) and hovered_ship != player_ship:
		if hovered_ship != selected_ship:
			if hovered_ship.world_bars:
				hovered_ship.world_bars.visible = false

	# set new hover
	hovered_ship = new_hover

	# apply new hover
	if hovered_ship and is_instance_valid(hovered_ship) and hovered_ship != player_ship:
		if hovered_ship != selected_ship:
			if hovered_ship.world_bars:
				hovered_ship.world_bars.visible = true

func check_win_condition():
	var player_faction = player_ship.faction
	var influence = territory.get_faction_influence(player_faction)
	if influence == 1.0:
		game_finished()

func game_finished():
	print("GAME COMPLETED, MASTER OF THE SEAS")


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


func new_game(new_seed: int, player_name: String):
	save_manager.delete_save()

	GameState.game_seed = new_seed
	GameState.player_name = player_name
	pause_game(false)

	get_tree().reload_current_scene()


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
			if player_ship.docked:
				hud.open_stash(hud.inventory_panel.visible)
		if event.keycode == KEY_M:
			hud.toggle_map()
		if event.keycode == KEY_CAPSLOCK:
			hud.toggle_equipment_panel()
		if event.keycode == KEY_F5:
			save_manager.save_game(self )
		if event.keycode == KEY_F6:
			save_manager.load_game(self )
		if event.keycode == KEY_F4:
			camerarig.debug_mode = !camerarig.debug_mode
			hud.new_notification("Camera debug mode: %s" % [camerarig.debug_mode])
		if event.keycode == KEY_ESCAPE:
			hud.game_menu.visible = !hud.game_menu.visible
			pause_game(hud.game_menu.visible)
		if event.keycode == KEY_H:
			spectator_mode = !spectator_mode
			set_spectator_mode(spectator_mode)


func set_spectator_mode(mode: bool):
	if mode:
		player_ship.process_mode = Node.PROCESS_MODE_DISABLED
		spectator.process_mode = Node.PROCESS_MODE_ALWAYS
		camera.clear_current()
		spectator.make_current()
		sub_viewport_container.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hud.visible = false
	else:
		spectator.process_mode = Node.PROCESS_MODE_DISABLED
		player_ship.process_mode = Node.PROCESS_MODE_ALWAYS
		spectator.clear_current()
		camera.make_current()
		sub_viewport_container.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.visible = true


func pause_game(pause: bool):
	get_tree().paused = pause

func respawn_player():
	var player_ship_scene = preload("res://Scenes/player_ship.tscn")
	var old_player_ship = player_ship
	var new_player_ship = player_ship_scene.instantiate()
	world.add_child(new_player_ship)
	player_ship = new_player_ship
	move_player_to_closest_port_of_faction(old_player_ship.faction, old_player_ship)
	old_player_ship.queue_free()
	
	hud.ship_panel_player.set_ship(player_ship)
	

func move_player_to_closest_port_of_faction(_faction: FactionsData.Faction, player: PlayerShip):
	var ports = world.ports
	var friendly_ports = get_ports_by_faction(ports, [_faction])
	var port = get_closest_port(friendly_ports, player)
	
	move_player_to_port(port)

func move_player_to_random_port():
	var ports = world.ports
	var port: Port = ports.pick_random()
	move_player_to_port(port)

func move_player_to_port(port: Port):
	var water_pos = port.get_valid_water_position()
	var dir = (water_pos - port.global_position).normalized()
	var angle_rad = atan2(dir.x, dir.z)
	var angle_deg = rad_to_deg(angle_rad)
	player_ship.global_position = water_pos
	player_ship.rotation.y = angle_rad
	player_ship.desired_heading = angle_deg


func spawn_ship(_position: Vector3, nation: FactionsData.Nation, faction: FactionsData.Faction) -> EnemyShip:
	var enemy_ship_scene = preload("res://Scenes/enemy_ship.tscn")
	var enemy_ship: EnemyShip = enemy_ship_scene.instantiate() as EnemyShip
	add_child(enemy_ship)
	enemy_ship.global_position = _position
	enemy_ship.setup_identity(nation, faction)
	return enemy_ship

func spawn_ships_around_player(count: int, radius: float) -> Array[Ship]:
	var enemy_ship = preload("res://Scenes/enemy_ship.tscn")
	
	var ships: Array[Ship] = []
	for i in range(count):
		var ship: Ship = enemy_ship.instantiate() as Ship
		add_child(ship)
		
		var pos = get_position_around_point(player_ship.global_position, radius)
		
		ship.global_position = pos
		ships.append(ship)
	
	return ships

func get_position_around_point(pos: Vector3, radius: float) -> Vector3:
	var angle = randf() * TAU
	var _offset = Vector3(cos(angle), 0, sin(angle)) * radius
	
	return pos + _offset


static func get_ships_by_faction(ships: Array[Ship], target_factions: Array[FactionsData.Faction]) -> Array[Ship]:
	var result: Array[Ship] = []

	for ship in ships:
		if target_factions.has(ship.faction):
			result.append(ship)

	return result

static func get_ports_by_faction(ports: Array[Port], target_factions: Array[FactionsData.Faction]) -> Array[Port]:
	var result: Array[Port] = []

	for port in ports:
		if target_factions.has(port.allegiance.faction):
			result.append(port)

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
