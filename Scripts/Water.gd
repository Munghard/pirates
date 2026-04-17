@tool
extends MeshInstance3D

class_name Water

# --- Exports ---
@export var target: Node3D
@export var terrain: Terrain # Assumes your Terrain class has 'get_height_world'

@export_group("Wave Settings")
@export var freq: float = 16.0
@export var amp: float = 1.0
@export var wave_height_scale: float = 1.0

@export_group("Environment")
@export var wind_direction: Vector3 = Vector3.RIGHT
@export var water_level: float = 0.0
@export var max_depth: float = 30.0
@export var terrain_height_scale: float = 50.0


# --- Internal Variables ---
var time: float = 0.0
@onready var gameManager: GameManager = get_node_or_null("/root/GameManager")

func _enter_tree():
	terrain.heightmap_created.connect(_on_heightmap_created)

func _ready():
	# This is usually a viewport texture or a generated ImageTexture
	var mat = get_active_material(0)
	mat.set_shader_parameter("terrain_size", terrain.world_size) # Match your world_size
	mat.set_shader_parameter("max_depth", max_depth)
	mat.set_shader_parameter("water_level", water_level)
	mat.set_shader_parameter("terrain_tile_size", terrain.tile_size)

func _on_heightmap_created(texture: Texture2D):
	# You need to pass your terrain's actual heightmap texture here
	var mat = get_active_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("heightmap", texture)
	else:
		print("Warning: Material is not a ShaderMaterial, cannot set heightmap uniform.")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		time += _delta
	else:
		# In editor, use a generic timer if you want it to animate
		time = Time.get_ticks_msec() / 1000.0

	# 1. Update Wind from GameManager
	if gameManager and "wind" in gameManager:
		wind_direction = gameManager.wind.direction
		amp = gameManager.wind.strength

	# 2. Follow Target (Snap to XZ plane)
	if target:
		position = target.position
		position.y = 0

	# 3. Update Shader Uniforms
	var mat = get_active_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("time", time)
		mat.set_shader_parameter("freq", freq)
		mat.set_shader_parameter("amp", amp)
		mat.set_shader_parameter("wave_height_scale", wave_height_scale)
		mat.set_shader_parameter("wind_dir", Vector2(wind_direction.x, wind_direction.z))
		mat.set_shader_parameter("water_level", water_level)
		mat.set_shader_parameter("max_depth", max_depth)
		mat.set_shader_parameter("terrain_size", terrain.world_size)

func get_wave_data(world_pos: Vector3) -> Dictionary:
	# --- 1. Replicate Shader Terrain Sampling ---
	# We need the height in the same "units" as the shader.
	# If get_height_world returns world-space Y, use it directly.
	var terrain_h = terrain.get_height_world(world_pos.x, world_pos.z)

	# Mirror: depth = max(0.0, water_level - terrain_h)
	var current_depth = max(0.0, water_level - terrain_h)

	# Mirror: depth01 = clamp(depth / abs(max_depth), 0.0, 1.0)
	# This is what "dampens" the waves at the shore.
	var depth01 = clamp(current_depth / abs(max_depth), 0.0, 1.0)

	# --- 2. Directions ---
	var wind = wind_direction.normalized()
	var wind2 = Vector2(wind.x, wind.z)
	var perp = Vector2(-wind2.y, wind2.x)

	var pos_xz = Vector2(world_pos.x, world_pos.z)
	var along = pos_xz.dot(wind2)
	var across = pos_xz.dot(perp)

	# --- 3. Wave Math ---
	var t = time
	var f = freq

	var w1 = sin(along * f * 0.2 + t) * 0.5
	var w2 = sin(across * f * 0.1 + t * 2.0) * 0.3
	var w3 = sin((along * 0.35 + across * 0.1) * f + t * 1.2) * 0.2

	var wave_sum = w1 + w2 + w3

	# Mirror: wave = sign(wave) * pow(abs(wave), 1.3)
	var wave_shaped = sign(wave_sum) * pow(abs(wave_sum), 1.3)

	# Apply depth01 HERE to dampen height near shore
	var final_amp = amp * depth01 * wave_height_scale
	var height = wave_shaped * final_amp

	# --- 4. Derivatives (Slope) ---
	# These must also be dampened, or objects will tilt aggressively in still water
	var dw1 = cos(along * f * 0.2 + t) * (f * 0.2) * 0.5
	var dw2 = cos(across * f * 0.1 + t * 2.0) * (f * 0.1) * 0.3

	var phase3 = (along * 0.35 + across * 0.1) * f + t * 1.2
	var dw3 = cos(phase3) * 0.2

	var d1 = wind2 * dw1
	var d2 = perp * dw2
	var d3 = (wind2 * 0.35 * f + perp * 0.1 * f) * dw3

	var slope = d1 + d2 + d3

	# Mirror: vec3 normal = normalize(vec3(-slope.x * depth01, 1.0, -slope.y * depth01))
	var normal = Vector3(-slope.x * depth01, 1.0, -slope.y * depth01).normalized()

	return {
		"height": height,
		"normal": normal,
		"depth_factor": depth01
	}
