extends Node3D

class_name World

@export_group("Nodes")
@onready var gameManager: GameManager = get_node("/root/GameManager")
@onready var water: Water = $Water
@onready var wind: Wind = $Wind
@onready var terrain: Terrain = $Terrain
@onready var birds_effect: Node3D = $birds_effect
@onready var wind_effect: MeshInstance3D = $wind_effect
@onready var time: GameTime = $Time
@onready var sun: DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $Moon
@onready var clouds: MeshInstance3D = $Clouds

@export var scatterers: Node3D

@export_group("Spawn data")
@export var ports_amount: int
@export var min_distance_between_ports: float = 100.0

@export_group("Sun")
@export var sun_gradient: Gradient

@export_group("Assets")
@export var port_scene: PackedScene

var wind_offset: Vector2 = Vector2.ZERO
signal ports_spawned(ports: Array[Node3D])

# Keep a local list for immediate distance checking
var _spawned_positions: Array[Vector3] = []

func _ready():
	water = $Water
	wind = $Wind
	terrain = $Terrain
	wind_effect = $wind_effect
	clouds = $Clouds
	time = $Time
	sun = $Sun
	moon = $Moon

	assert(wind != null, "wind is null in world start")
	assert(wind_effect != null, "wind_effect is null in world start")
	assert(water != null, "water is null in world start")
	assert(terrain != null, "terrain is null in world start")
	assert(time != null, "time is null in world start")
	assert(sun != null, "sun is null in world start")
	assert(moon != null, "moon is null in world start")
	assert(clouds != null, "clouds is null in world start")

	time.connect("time_changed", Callable(self , "_on_time_changed"))

	wind.randomize_wind()
	wind.connect("wind_changed", Callable(self , "_on_wind_changed"))
	
	print("CONNECTING ports_spawned to place_player")
	ports_spawned.connect(place_player)
	print("CONNECTING heightmap_created to spawn_ports and scatter_scatterers")
	terrain.heightmap_created.connect(spawn_ports)
	terrain.heightmap_created.connect(scatter_scatterers)

	terrain.create_terrain()


func scatter_scatterers(_heightmap):
	print("Scattering scatterers");
	for scatterer in scatterers.get_children():
		if scatterer.has_method("scatter"):
			scatterer.scatter(terrain)


func _process(delta):
	var birds_pos = gameManager.camerarig.global_position
	var birds_height = 20.0
	birds_pos.y = birds_height
	birds_effect.global_position = birds_pos

	var cloud_pos = gameManager.camerarig.global_position
	var cloud_height = 20.0
	cloud_pos.y = cloud_height

	wind_effect.global_position = cloud_pos
	clouds.global_position = cloud_pos
	var wind_strength = wind.strength

	wind_offset += Vector2(wind.direction.x, wind.direction.z) * wind_strength * delta * 0.01
	var wind_2d := Vector2(wind.direction.x, wind.direction.z)
	if wind_2d.length() > 0.0001:
		wind_2d = wind_2d.normalized()
	else:
		wind_2d = Vector2.RIGHT
	var c_mat := clouds.get_active_material(0) as ShaderMaterial
	
	c_mat.set_shader_parameter("wind_offset", wind_offset)
	
	var w_mat := wind_effect.get_active_material(0) as ShaderMaterial
	w_mat.set_shader_parameter("wind_offset", wind_offset)
	w_mat.set_shader_parameter("wind_dir", wind_2d)

func pass_time():
	time.pass_time(1.0)
	wind.randomize_wind()

func _on_time_changed(_time: float):
	var normalized_time = time.get_time_normalized()
	var angle = 360.0 * normalized_time
	moon.rotation_degrees.x = angle - 90.0
	sun.rotation_degrees.x = angle + 90.0
	var t = normalized_time # 0–1
	sun.light_energy = max(0.0, sin(t * PI)) * 2.0
	sun.light_color = sun_gradient.sample(normalized_time)
	moon.light_energy = max(0.0, 1.0 - max(0.0, sin(t * PI)))


func place_player(ports: Array[Node3D]):
	print("Placing player");
	if ports.is_empty():
		print("NO PORTS RECEIVED")
		return
	var port = ports[randi_range(0, ports.size() - 1)]
	var rolled_port_pos = port.global_position
	gameManager.player_ship.global_position = rolled_port_pos

func spawn_ports(_heightmap: Texture2D):
	var container = Node3D.new()
	container.name = "Ports"
	add_child(container)

	var target_height := 0.0
	var tolerance := 0.5
	
	_spawned_positions.clear()

	# Increase sample density to find more accurate beach points
	var suitable_points := get_suitable_points_within_tolerance(target_height, tolerance)

	var spawned_count = 0

	var spawned_ports: Array[Node3D] = []
	while spawned_count < ports_amount and not suitable_points.is_empty():
		var random_index = randi() % suitable_points.size()
		var candidate_pos = suitable_points[random_index]
		suitable_points.remove_at(random_index)

		# Optional: Check if this point is too close to an existing port
		if is_pos_too_crowded(candidate_pos):
			continue

		var port := port_scene.instantiate() as Node3D

		_spawned_positions.append(candidate_pos)
		add_to_world(container, port, candidate_pos)
		#add_to_world.call_deferred(port, candidate_pos)
		spawned_count += 1
		spawned_ports.append(port)
	
	await get_tree().process_frame

	print("EMITTING ports_spawned: ", spawned_ports.size())
	emit_signal("ports_spawned", spawned_ports)
	

func add_to_world(container: Node3D, node: Node3D, pos: Vector3):
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
