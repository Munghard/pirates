@tool
extends MeshInstance3D

class_name Water

@export var target: Node3D

@export var freq = 16.0
@export var amp = 1.0
@export var wave_height_scale = 1.0

var time := 0.0

var world_size := Vector2(100, 100)
@export var wind_direction: Vector3

@onready var gameManager: GameManager = get_node("/root/GameManager")


func _process(_delta):
	time += _delta
	if gameManager and "wind" in gameManager:
		wind_direction = gameManager.wind.direction
		# wind_direction = Vector3.RIGHT

		amp = gameManager.wind.strength
	# print(amp);

	if target:
		position = target.position
		position.y = 0
	var mat = get_active_material(0)
	
	if mat is ShaderMaterial:
		mat.set_shader_parameter("time", time)
		mat.set_shader_parameter("freq", freq)
		mat.set_shader_parameter("amp", amp)
		mat.set_shader_parameter("wave_height_scale", wave_height_scale)
		mat.set_shader_parameter("wind_dir", Vector2(wind_direction.x, wind_direction.z))
		
		
func get_wave_data(world_pos: Vector3) -> Dictionary:
	var wind2 = Vector2(wind_direction.x, wind_direction.z)

	var along = Vector2(world_pos.x, world_pos.z).dot(wind2)
	var across = Vector2(world_pos.x, world_pos.z).dot(Vector2(-wind2.y, wind2.x))


	# 1. Apply weights to match shader
	var w1 = sin(along * freq * 0.2 + time) * 0.5
	var w2 = sin(across * freq * 0.1 + time * 2.0) * 0.3 # Changed time to 2.0
	var w3 = sin((along * 0.35 + across * 0.1) * freq + time * 1.2) * 0.2 # Match shader freq logic
	var wave = w1 + w2 + w3
	wave = sign(wave) * pow(abs(wave), 1.3)

	# --- derivatives (THIS IS THE IMPORTANT PART) ---


	var combined_sum = w1 + w2 + w3 # The raw sum before power
	var final_wave = sign(combined_sum) * pow(abs(combined_sum), 1.3)

	# 2. Base derivatives (with weights)
	var dw1 = cos(along * freq * 0.2 + time) * (freq * 0.2) * 0.5
	var dw2 = cos(across * freq * 0.1 + time * 2.0) * (freq * 0.1) * 0.3
	var dw3_base = cos((along * 0.35 + across * 0.1) * freq + time * 1.2)

	var d1 = wind2 * dw1
	var d2 = Vector2(-wind2.y, wind2.x) * dw2
	var d3 = (wind2 * 0.35 * freq + Vector2(-wind2.y, wind2.x) * 0.1 * freq) * dw3_base * 0.2

	var raw_slope = d1 + d2 + d3

	# 3. APPLY CHAIN RULE for the pow(x, 1.3)
	# Derivative of sign(u)*abs(u)^1.3 is 1.3 * abs(u)^0.3
	var power_derivative = 1.3 * pow(abs(combined_sum), 0.3)
	var slope = raw_slope * power_derivative

	# 4. Final Scale
	var _height = final_wave * amp * wave_height_scale
	# Slope must also be scaled by the same factor
	var final_slope = slope * amp * wave_height_scale

	var normal = Vector3(-final_slope.x, 1.0, -final_slope.y).normalized()
	return {
		"height": wave * amp * wave_height_scale,
		"normal": normal
	}
