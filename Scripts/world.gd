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

var ports: Array[Port] = []
var ports_container: Node3D

@export_group("Spawn data")
@export var ports_amount: int
@export var min_distance_between_ports: float = 100.0
@export var nominal_ship_count: int = 20

@export_group("Sun")
@export var sun_gradient: Gradient

@export_group("Assets")
@export var port_scene: PackedScene

var wind_offset: Vector2 = Vector2.ZERO
signal ports_spawned(ports: Array[Port])

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

	ports_container = Node3D.new()
	ports_container.name = "Ports"
	add_child(ports_container)

	time.connect("time_changed", Callable(self , "_on_time_changed"))

	wind.randomize_wind()
	wind.connect("wind_changed", Callable(self , "_on_wind_changed"))
	
	print("CONNECTING ports_spawned to place_player")
	ports_spawned.connect(place_player)
	print("CONNECTING heightmap_created to spawn_ports and scatter_scatterers")
	terrain.heightmap_created.connect(spawn_ports)
	terrain.heightmap_created.connect(scatter_scatterers)

	terrain.create_terrain()

	ship_spawner()

func ship_spawner():
	var radius := 75.0
	while true:
		await get_tree().create_timer(10.0).timeout
		var all_ships = get_tree().get_nodes_in_group("Ships")
		if all_ships.size() < nominal_ship_count:
				var nation = FactionsData.roll_nation()
				#var faction = FactionsData.roll_faction(nation)
				var _position = gameManager.get_position_around_point(gameManager.player_ship.global_position, radius)
				var _pos2d = Vector2(_position.x, _position.z)
				var faction = gameManager.territory.get_territory_at(_pos2d)
				gameManager.spawn_ship(_position, nation, faction)
		

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

func pass_time(_time: float):
	time.pass_time(_time)
	wind.randomize_wind()

func _on_time_changed(_time: float):
	var normalized_time = time.get_time_normalized()
	var angle = 360.0 * normalized_time
	moon.rotation_degrees.x = angle - 90.0
	sun.rotation_degrees.x = angle + 90.0
	var t = normalized_time # 0–1
	sun.light_energy = max(0.0, sin(t * PI)) * 1.5
	sun.light_color = sun_gradient.sample(normalized_time)
	moon.light_energy = max(0.0, 1.0 - max(0.0, sin(t * PI)))


func place_player(_ports: Array[Port]):
	print("Placing player");
	if _ports.is_empty():
		print("NO PORTS RECEIVED")
		return
	var friendly_ports = []
	for p: Port in _ports:
		if p.allegiance.faction == gameManager.player_ship.faction:
			friendly_ports.append(p)
	var port = friendly_ports[randi_range(0, friendly_ports.size() - 1)]
	var water_pos = port.get_valid_water_position()
	var dir = (water_pos - port.global_position).normalized()
	var angle_rad = atan2(dir.x, dir.z)
	var angle_deg = rad_to_deg(angle_rad)
	gameManager.player_ship.global_position = water_pos
	gameManager.player_ship.rotation.y = angle_rad
	gameManager.player_ship.yaw_deg = angle_deg


func spawn_ports_from_data(data: Array[Port_Data]):
	ports = []
	for child in ports_container.get_children():
		child.queue_free()
	
	print("Setting up inventory for loaded ports ")
	for port_data in data:
		var port = port_scene.instantiate() as Port
		ports_container.add_child(port)
		port.global_position = port_data.global_position
		port.setup_identity(self , port_data)
		ports.append(port)
		
		port.inventory = SaveManager.create_inventory_from_data(
			port,
			port_data.port_name,
			gameManager.world,
			port_data.inventory
		)
	
	print("Ports loaded: ", ports.size())
	emit_signal("ports_spawned", ports)

func spawn_ports(_heightmap: Texture2D):
	ports = []
	var sea_level := 1.0
	var tolerance := 0.5
	
	_spawned_positions.clear()

	# Increase sample density to find more accurate beach points
	var suitable_points := get_suitable_points_within_tolerance(sea_level, tolerance)

	var spawned_count = 0

	
	while spawned_count < ports_amount and not suitable_points.is_empty():
		var random_index = randi() % suitable_points.size()
		var candidate_pos := suitable_points[random_index]
		suitable_points.remove_at(random_index)

		# Optional: Check if this point is too close to an existing port
		if is_pos_too_crowded(candidate_pos):
			continue

		var port := port_scene.instantiate() as Port

		_spawned_positions.append(candidate_pos)
		# add to world
		var pos = candidate_pos
		ports_container.add_child(port)
		var down_dir = terrain.get_downhill_direction(pos.x, pos.z)
		
		port.global_position = pos
		
		port.look_at(pos + down_dir, Vector3.UP)

		var nation := FactionsData.roll_nation()
		var faction := FactionsData.roll_faction(nation)
		
		# guarantee atleast one pirate port for player spawn
		if spawned_count == 1:
			nation = FactionsData.Nation.ENGLAND
			faction = FactionsData.Faction.PIRATE
		
		var port_name = FactionsData.get_unique_port_name()
		print("Setting up inventory for spawned port ", port_name)
		var inventory = port.setup_inventory()
		var inventory_saved = SaveManager.save_inventory(inventory)
		port.setup_identity(self , Port_Data.new(faction, nation, port_name, pos, inventory_saved))
		
		spawned_count += 1
		ports.append(port)
	
	await get_tree().process_frame

	print("EMITTING ports_spawned: ", ports.size())
	emit_signal("ports_spawned", ports)
	

func get_suitable_points_within_tolerance(sea_level: float, tolerance: float) -> Array[Vector3]:
	var margin = 50.0
	var total_world_size = terrain.world_size * terrain.tile_size
	var step_size = 5.0
	var points: Array[Vector3] = []

	var origin = terrain.global_position

	for x in range(int(margin), int(total_world_size.x - margin), int(step_size)):
		for z in range(int(margin), int(total_world_size.y - margin), int(step_size)):
			var wx = origin.x + x
			var wz = origin.z + z

			var h = terrain.get_height_world(wx, wz)

			if abs(h - sea_level) > tolerance:
				continue
			
			var normal = terrain.get_normal_world(wx, wz)
			
			if normal.dot(Vector3.UP) < 0.85:
				continue

			points.append(Vector3(wx, h, wz))

	return points

func is_pos_too_crowded(pos: Vector3) -> bool:
	# Check against our local list of positions we just picked
	for spawned_pos in _spawned_positions:
		if spawned_pos.distance_to(pos) < min_distance_between_ports:
			return true
	return false
