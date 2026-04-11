@tool
extends MeshInstance3D

class_name Water

@export var target: Node3D

@export var freq = 16.0
@export var amp = 1.0
@export var wave_height_scale = 1.0

var time := 0.0

var world_size := Vector2(100, 100)


func _ready():
	pass

func _process(_delta):
	time += _delta
	var wind_dir = Vector3.RIGHT
	if GM and "wind" in GM:
		wind_dir = GM.wind.direction

	position = target.position
	position.y = 0
	var mat = get_active_material(0)
	
	if mat is ShaderMaterial:
		mat.set_shader_parameter("time", time)
		mat.set_shader_parameter("freq", freq)
		mat.set_shader_parameter("amp", amp)
		mat.set_shader_parameter("wave_height_scale", wave_height_scale)
		mat.set_shader_parameter("wind_dir", wind_dir)
		
		
func get_wave_height(world_pos: Vector3) -> float:
	var dir = GM.wind.direction.normalized()

	var p = Vector2(world_pos.x, world_pos.z).dot(Vector2(dir.x, dir.z))

	# time speed scales with freq a bit (optional but feels better)
	var t = time

	var w1 = sin(p * 0.2 * freq + t) * 0.5
	var w2 = sin((world_pos.x + world_pos.z) * 0.15 * freq + time * 2.0) * 0.3
	var w3 = sin(world_pos.x * 0.35 * freq + time * 1.2) * 0.2

	var wave = w1 + w2 + w3

	wave = sign(wave) * pow(abs(wave), 1.3)

	# amplitude scales final result
	return wave * amp * wave_height_scale
	
func get_wave_data(pos: Vector3) -> Dictionary:
	var dir = GM.wind.direction.normalized()
	var wind2 = Vector2(dir.x, dir.z)

	var p = Vector2(pos.x, pos.z).dot(wind2)

	var t = time
	var f = freq

	# waves
	var w1 = sin(p * 0.2 * f + t) * 0.5
	var w2 = sin((pos.x + pos.z) * 0.15 * f + t * 2.0) * 0.3
	var w3 = sin(pos.x * 0.35 * f + t * 1.2) * 0.2

	var wave = w1 + w2 + w3
	wave = sign(wave) * pow(abs(wave), 1.3)

	# --- derivatives (THIS IS THE IMPORTANT PART) ---

	var dw1 = cos(p * 0.2 * f + t) * 0.2 * f * 0.5
	var d1 = wind2 * dw1

	var dw2 = cos((pos.x + pos.z) * 0.15 * f + t * 2.0) * 0.15 * f * 0.3
	var d2 = Vector2(dw2, dw2)

	var dw3 = cos(pos.x * 0.35 * f + t * 1.2) * 0.35 * f * 0.2
	var d3 = Vector2(dw3, 0.0)

	var slope = d1 + d2 + d3

	# build normal
	var normal = Vector3(-slope.x, 1.0, -slope.y).normalized()

	return {
		"height": wave * amp * wave_height_scale,
		"normal": normal
	}
