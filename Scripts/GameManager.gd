extends Node3D

class_name GameManager

var player_ship: PlayerShip
var hud: HUD
var camera: Camera3D
var camerarig: Camera
var water: Water
var wind_particle: CPUParticles3D
var wind: Wind
var terrain: Terrain
var port: Port

func _ready() -> void:
	player_ship = $PlayerShip
	hud = $MarginContainer/HUD
	camera = $camrig/Camera3D
	camerarig = $camrig
	water = $World/Water
	wind = $World/Wind
	terrain = $World/Terrain
	wind_particle = $World/wind_particle_cpu
	port = $World/Port/port
	
	wind.randomize_wind()
	wind.connect("wind_changed", Callable(self , "_on_wind_changed"))

	assert(wind != null, "wind is null in gamemanager start")
	assert(player_ship != null, "player_ship is null in gamemanager start")
	assert(hud != null, "hud is null in gamemanager start")
	assert(wind_particle != null, "wind_particle is null in gamemanager start")
	assert(water != null, "water is null in gamemanager start")
	assert(camera != null, "camera is null in gamemanager start")
	assert(camerarig != null, "camerarig is null in gamemanager start")
	assert(terrain != null, "terrain is null in gamemanager start")
	assert(port != null, "port is null in gamemanager start")

	hud.init_hud()

func _process(_delta: float) -> void:
	wind_particle.rotation = Vector3(0, atan2(wind.direction.x, wind.direction.z), 0)
	wind_particle.position = player_ship.position

func _on_wind_changed(_wind: Wind):
	if not wind_particle:
		return
	# var mat: ParticleProcessMaterial = wind_particle.process_material
	
	# mat.initial_velocity_min = _wind.strength * 1.0
	# mat.initial_velocity_max = _wind.strength * 4.0
	wind_particle.initial_velocity_min = _wind.strength * 1.0
	wind_particle.initial_velocity_max = _wind.strength * 4.0
	wind_particle.rotation = Vector3(0, atan2(_wind.direction.x, _wind.direction.z), 0)
	#mat.direction = _wind.direction

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			wind.randomize_wind()


#IDEAS
#figure out how to do terrain in a good way that can be plugged into water sim and shader
# minimap showing other ships and ports
# different ports, pirate port, navy port, merchant port, with different services

# BAD IDEAS
# TRY TO MAKE IT TURN BASED AND MOVEMENT USING CLICK, CREATE A VISUAL HEX GRID
