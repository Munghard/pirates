extends Node3D

@export_group("Nodes")
@export var water: Water
@export var wind: Wind
@export var terrain: Terrain
var container

@export_group("Spawn data")
@export var ports: int
@export var min_distance_between_ports: float = 100.0

@export_group("Assets")
@export var port_scene: PackedScene

# Keep a local list for immediate distance checking
var _spawned_positions: Array[Vector3] = []

func _enter_tree():
	container = Node3D.new()
	container.name = "Ports"
	add_child(container)
	terrain.heightmap_created.connect(_on_heightmap_created)

func _on_heightmap_created(heightmap: Texture2D):
	spawn_ports(heightmap)
	

func spawn_ports(_heightmap: Texture2D):
	var target_height := 0.0
	var tolerance := 0.5
	
	_spawned_positions.clear()

	# Increase sample density to find more accurate beach points
	var suitable_points := get_suitable_points_within_tolerance(target_height, tolerance)

	var spawned_count = 0
	while spawned_count < ports and not suitable_points.is_empty():
		var random_index = randi() % suitable_points.size()
		var candidate_pos = suitable_points[random_index]
		suitable_points.remove_at(random_index)

		# Optional: Check if this point is too close to an existing port
		if is_pos_too_crowded(candidate_pos):
			continue

		var port := port_scene.instantiate() as Node3D

		_spawned_positions.append(candidate_pos)
		add_to_world.call_deferred(port, candidate_pos)
		spawned_count += 1

func add_to_world(node: Node3D, pos: Vector3):
	container.add_child(node)
	node.global_position = pos

	var down_dir = terrain.get_downhill_direction(pos.x, pos.z)
	node.look_at(pos + down_dir, Vector3.UP)


func get_suitable_points_within_tolerance(target_height: float, tolerance: float) -> Array:
	var total_world_size = terrain.world_size * terrain.tile_size
	# Increase resolution (e.g., sample every 5-10 meters instead of a 10x10 grid)
	var step_size = 5.0
	var suitable_points = []

	for x in range(0, int(total_world_size.x), int(step_size)):
		for z in range(0, int(total_world_size.y), int(step_size)):
			var h = terrain.get_height_world(x, z)
			
			if abs(h - target_height) <= tolerance:
				suitable_points.append(Vector3(x, h, z))
				
	return suitable_points

func is_pos_too_crowded(pos: Vector3) -> bool:
	# Check against our local list of positions we just picked
	for spawned_pos in _spawned_positions:
		if spawned_pos.distance_to(pos) < min_distance_between_ports:
			return true
	return false
