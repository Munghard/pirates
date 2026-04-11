extends Node3D

class_name GameManager

var player_ship: PlayerShip
var hud: HUD
var camera: Camera3D
var camerarig: Node3D
var water: Water
var wind_particle: GPUParticles3D

var wind: Wind

func _ready() -> void:
	wind = Wind.new()
	add_child(wind)
	wind.randomize_direction()
	wind.connect("wind_changed", Callable(self , "_on_wind_changed"))

	
func _on_wind_changed(direction: Vector3):
	if not wind_particle:
		return
	var mat: ParticleProcessMaterial = wind_particle.process_material
	
	mat.initial_velocity_min = 0
	mat.initial_velocity_max = direction.length()
	wind_particle.rotation = Vector3.ZERO
	mat.direction = direction.normalized()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			wind.randomize_direction()
