extends Node3D

# Inspector variables
@export var prefab: PackedScene
@export var amount: int = 10
@export var rotation_range_min: Vector3 = Vector3(0, 0, 0)
@export var rotation_range_max: Vector3 = Vector3(0, 0, 0)
@export var water: Water

@export var terrain: Terrain

@export var water_level: float = 5.0
@export var spawn_in_water: bool = true

func _ready():
	scatter()

func scatter():
	if not prefab:
		push_warning("No prefab assigned!")
		return

	var terrain_size = terrain.world_size * terrain.tile_size

	for i in range(amount):
		var placed := false

		for attempt in range(10): # retry limit
			var pos = Vector3(
				randf_range(0, terrain_size.x),
				0,
				randf_range(0, terrain_size.y)
			)

			var h = terrain.get_height_world(pos.x, pos.z)

			var valid := false

			if spawn_in_water:
				valid = h <= water.water_level_world_space - 5.0
			else:
				valid = h >= water.water_level_world_space - 5.0

			if not valid:
				continue

			#print("found suitable height %s"%h);
			var instance := prefab.instantiate()
			add_child(instance)

			pos.y = h
			instance.position = pos

			instance.rotation_degrees = Vector3(
				randf_range(rotation_range_min.x, rotation_range_max.x),
				randf_range(rotation_range_min.y, rotation_range_max.y),
				randf_range(rotation_range_min.z, rotation_range_max.z)
			)

			if "water" in instance:
				instance.water = water

			placed = true
			break

		if not placed:
			pass
			#print("Failed to place object ", i)
func _process(_delta):
	var half_x = terrain.world_size.x * 0.5 * terrain.tile_size
	var half_z = terrain.world_size.y * 0.5 * terrain.tile_size
	var offset2 = terrain.world_size / 2.0 * terrain.tile_size
	var offset = Vector3(offset2.x, 0, offset2.y)
	DebugDraw3D.draw_box_ab(Vector3(-half_x, 0, -half_z) + offset, Vector3(half_x, 0, half_z) + offset, Vector3(0, 1, 0))