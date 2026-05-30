extends Node3D

# Inspector variables
@export var prefab: PackedScene
@export var amount: int = 10
@export var rotation_range_min: Vector3 = Vector3(0, 0, 0)
@export var rotation_range_max: Vector3 = Vector3(0, 0, 0)
@export var water: Water

@export var min_spawn_height: float = 5.0
@export var max_spawn_height: float = 50.0
@export var spawn_in_water: bool = true

@export var use_latitude_longitude: bool = false
#North 1, South 0
@export_range(0.0, 1.0, 0.01) var latitude_bias := 0.5
#East 1, West 0
@export_range(0.0, 1.0, 0.01) var longitude_bias := 0.5


func _ready():
	pass
	#scatter()

func scatter(terrain: Terrain):
	if not prefab:
		push_warning("No prefab assigned!")
		return

	var terrain_size = terrain.world_size * terrain.tile_size

	for i in range(amount):
		var placed := false
		var min_x = 0.0
		var max_x = terrain_size.x
		var min_z = 0.0
		var max_z = terrain_size.y

		for attempt in range(10): # retry limit
			var pos: Vector3
			if use_latitude_longitude:
				# X axis (west/east)
				# X axis (west/east)
				if longitude_bias < 0.5:
					max_x = terrain_size.x * 0.5
				elif longitude_bias > 0.5:
					min_x = terrain_size.x * 0.5
				# else: 0.5 = full width

				# Z axis (south/north)
				if latitude_bias < 0.5:
					max_z = terrain_size.y * 0.5
				elif latitude_bias > 0.5:
					min_z = terrain_size.y * 0.5
				# else: 0.5 = full height

				pos = Vector3(
					randf_range(min_x, max_x),
					0.0,
					randf_range(min_z, max_z)
				)
			else:
				pos = Vector3(
					randf_range(0.0, terrain_size.x),
					0.0,
					randf_range(0.0, terrain_size.y)
				)

			var h = terrain.get_height_world(pos.x, pos.z)

			var valid := false

			if spawn_in_water:
				valid = h <= water.water_level_world_space - 5.0
			else:
				valid = h >= min_spawn_height and h < max_spawn_height

			if not valid:
				continue

			#print("found suitable height %s"%h);
			var instance: Node3D = prefab.instantiate()
			add_child(instance)

			pos.y = h
			
			instance.global_position = pos

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
