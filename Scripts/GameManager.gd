extends Node3D

class_name GameManager

var player_ship: PlayerShip
var hud: HUD
var camera: Camera3D
var camerarig: Camera
var water: Water
var wind_effect: MeshInstance3D
var wind: Wind
var terrain: Terrain
var time: GameTime
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var clouds: MeshInstance3D
var audioManager: AudioManager
var debugMenu: DebugMenu

@export var sun_gradient: Gradient

func _ready() -> void:
	player_ship = $PlayerShip
	hud = $MarginContainer/HUD
	debugMenu = $MarginContainer/DebugMenu
	camera = $camrig/Camera3D
	camerarig = $camrig
	water = $World/Water
	wind = $World/Wind
	terrain = $World/Terrain
	wind_effect = $World/wind_effect
	clouds = $World/Clouds
	time = $World/Time
	sun = $World/Sun
	moon = $World/Moon
	audioManager = $AudioManager


	assert(wind != null, "wind is null in gamemanager start")
	assert(player_ship != null, "player_ship is null in gamemanager start")
	assert(hud != null, "hud is null in gamemanager start")
	assert(debugMenu != null, "debugMenu is null in gamemanager start")
	assert(wind_effect != null, "wind_effect is null in gamemanager start")
	assert(water != null, "water is null in gamemanager start")
	assert(camera != null, "camera is null in gamemanager start")
	assert(camerarig != null, "camerarig is null in gamemanager start")
	assert(terrain != null, "terrain is null in gamemanager start")
	assert(time != null, "time is null in gamemanager start")
	assert(sun != null, "sun is null in gamemanager start")
	assert(moon != null, "moon is null in gamemanager start")
	assert(clouds != null, "clouds is null in gamemanager start")
	assert(audioManager != null, "audioManager is null in gamemanager start")

	time.connect("time_changed", Callable(self , "_on_time_changed"))

	wind.randomize_wind()
	wind.connect("wind_changed", Callable(self , "_on_wind_changed"))

	hud.init_hud()
	debugMenu.init_debugMenu()

# put all this time and wind shit into world instead of gamemanager

func toggle_debug_menu():
	debugMenu.visible = !debugMenu.visible

func _on_time_changed(_time: float):
	var normalized_time = time.get_time_normalized()
	var angle = 360.0 * normalized_time
	moon.rotation_degrees.x = angle - 90.0
	sun.rotation_degrees.x = angle + 90.0
	var t = normalized_time # 0–1
	sun.light_energy = max(0.0, sin(t * PI)) * 2.0
	sun.light_color = sun_gradient.sample(normalized_time)
	moon.light_energy = max(0.0, 1.0 - max(0.0, sin(t * PI)))

var offset: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	var cloud_pos = camerarig.global_position
	var cloud_height = 20.0
	cloud_pos.y = cloud_height

	wind_effect.global_position = cloud_pos
	clouds.global_position = cloud_pos
	var wind_strength = wind.strength

	offset += Vector2(wind.direction.x, wind.direction.z) * wind_strength * delta * 0.01
	var wind_2d := Vector2(wind.direction.x, wind.direction.z)
	if wind_2d.length() > 0.0001:
		wind_2d = wind_2d.normalized()
	else:
		wind_2d = Vector2.RIGHT
	var c_mat := clouds.get_active_material(0) as ShaderMaterial
	c_mat.set_shader_parameter("offset", wind)
	
	var w_mat := wind_effect.get_active_material(0) as ShaderMaterial
	w_mat.set_shader_parameter("offset", offset)
	w_mat.set_shader_parameter("wind_dir", wind_2d)

func pass_time():
	time.pass_time(1.0)
	wind.randomize_wind()

func _on_wind_changed(_wind: Wind):
	if not wind_effect:
		return
	#GPU
	

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			var rotated = wind.target_direction.rotated(Vector3.UP, deg_to_rad(90))
			wind.set_direction(rotated)
		if event.keycode == KEY_F1:
			spawn_ships_around_player(1)
		if event.keycode == KEY_F2:
			toggle_debug_menu()

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
