extends Node3D

class_name GameManager

var player_ship: PlayerShip
var hud: HUD
var camera: Camera3D
var camerarig: Camera
var water: Water
var wind_particle: GPUParticles3D
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
	wind_particle = $wind_particle
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

func _on_wind_changed(_wind: Wind):
	if not wind_particle:
		return
	var mat: ParticleProcessMaterial = wind_particle.process_material
	
	mat.initial_velocity_min = 0
	mat.initial_velocity_max = _wind.strength
	wind_particle.rotation = Vector3.ZERO
	mat.direction = _wind.direction

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			wind.randomize_wind()


# TRY TO MAKE IT TURN BASED AND MOVEMENT USING CLICK, CREATE A VISUAL HEX GRID