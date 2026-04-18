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

	var half_x = terrain.world_size.x * 0.5 * terrain.tile_size
	var half_z = terrain.world_size.y * 0.5 * terrain.tile_size

	for i in range(amount):
		var pos: Vector3
		var h: float
		# single attempt per object (no while loop)
		pos = Vector3(
			randf_range(-half_x, half_x),
			0,
			randf_range(-half_z, half_z)
		)
		h = terrain.get_height_world(pos.x, pos.z)

		if spawn_in_water:
			if h > water_level:
				print("skipped: ", h)
				continue # skip this spawn entirely
		else:
			if h < water_level:
				print("skipped: ", h)
				continue # skip this spawn entirely

		var instance := prefab.instantiate()
		add_child(instance)

		pos.y = h
		instance.position = pos
		var rot = Vector3(
			randf_range(rotation_range_min.x, rotation_range_max.x),
			randf_range(rotation_range_min.y, rotation_range_max.y),
			randf_range(rotation_range_min.z, rotation_range_max.z)
		)

		instance.rotation_degrees = rot

		if "water" in instance:
			instance.water = water
