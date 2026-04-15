@tool
extends Node3D
class_name Terrain

@export var hex: PackedScene
@export var palm: PackedScene
@export var world_size: Vector3i
@export var tile_size: float
@export var noise_threshold: float = 0.5
@export var noise_palm_threshold: float = 0.2
@export var hex_ratio: float = 0.866
@export var terrain_height: float = 20.0
@export var center_falloff: Vector2 = Vector2(0.0, 1.0)
var noise: FastNoiseLite

@export var regen := false:
	set(value):
		if value:
			generate()
			regen = false

func _ready():
	generate()

func generate():
	for c in get_children():
		c.queue_free()
	noise = FastNoiseLite.new();
	var _tile_size = tile_size * 0.866
	var grid_x = world_size.x / _tile_size
	var grid_z = world_size.z / (_tile_size * hex_ratio)
	for x in range(grid_x):
		for y in range(world_size.y):
			for z in range(grid_z):
				var n = (tileable_noise(x, z) + 1.0) * 0.5

				var x_offset = x * _tile_size + (z % 2) * (_tile_size * 0.5)
				var z_offset = z * _tile_size * hex_ratio

				var center = Vector2(world_size.x, world_size.z) * 0.5
				var world_pos = Vector2(x * _tile_size, z * _tile_size * hex_ratio)
				var dist = world_pos.distance_to(center)

				var max_dist = center.length()
				var t = dist / max_dist

				var falloff = smoothstep(center_falloff.x, center_falloff.y, t)

				var land_value = n - (1.0 - falloff)

				if land_value < noise_threshold:
					continue

				var h := hex.instantiate()
				add_child(h)

				var height = land_value * terrain_height

				var pos = Vector3(x_offset, y * _tile_size + height - terrain_height / 2.0, z_offset)
				h.position = pos
				
				if land_value > noise_palm_threshold and randf() > 0.5:
					var p := palm.instantiate()
					h.add_child(p)
					

func tileable_noise(x, y):
	var size_x = world_size.x
	var size_y = world_size.z

	var nx = float(x) / size_x
	var ny = float(y) / size_y

	var v = noise.get_noise_2d(x, y) * (1 - nx) * (1 - ny) + noise.get_noise_2d(x - size_x, y) * nx * (1 - ny) + noise.get_noise_2d(x, y - size_y) * (1 - nx) * ny + noise.get_noise_2d(x - size_x, y - size_y) * nx * ny

	return v