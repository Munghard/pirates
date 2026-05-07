@tool
extends Node3D
class_name Terrain

@export_group("Assets")
@export var rock: PackedScene
@export var palm: PackedScene
@export var terrain_material: Material

@export_group("Terrain Settings")
@export var noise: FastNoiseLite
@export var world_size: Vector2i = Vector2i(100, 100)
@export var height_power: float = 2.0
@export var tile_size: float = 5.0
@export var terrain_height: float = 50.0
@export var terrain_world_size: Vector2
@export var heightmap_size: Vector2i
var terrain_cell_size: Vector2
@export var regen := false:
	set(value):
		create_terrain()
		regen = false

@export_group("Vegetation")
@export var rock_density: float = 0.2
@export var tree_density: float = 0.2
@export var height_min: float = 1.0
@export var height_max: float = 8.0

var heightmap_texture: Texture2D
var mesh_instance


signal heightmap_created(texture: Texture2D)

func _ready():
	pass
	#create_terrain()

func create_terrain():
	setup_noise()
	create_terrain_mesh()
	create_collision()
	create_heightmap()


func create_collision():
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()

	collision.shape = mesh_instance.mesh.create_trimesh_shape()

	static_body.add_child(collision)
	add_child(static_body)
	static_body.position = mesh_instance.position

func setup_noise():
	if not noise:
		noise = FastNoiseLite.new()
		noise.seed = 42

func create_heightmap():
	heightmap_size = world_size * tile_size
	var heightmap_image = Image.create(heightmap_size.x, heightmap_size.y, false, Image.FORMAT_RF)

	for z in range(heightmap_size.x):
		for x in range(heightmap_size.y):
			var h = (get_height_world(x, z) + terrain_height * 0.5) / terrain_height
			heightmap_image.set_pixel(x, z, Color(h, h, h))
	heightmap_texture = ImageTexture.create_from_image(heightmap_image)
	emit_signal("heightmap_created", heightmap_texture)
	print("heightmap_texture created");

func create_terrain_mesh():
	for child in get_children():
		child.queue_free()
	
	terrain_world_size = Vector2(world_size.x * tile_size, world_size.y * tile_size)
	terrain_cell_size = Vector2(tile_size, tile_size)
	# 1. Setup Mesh
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	add_child(mesh_instance)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(world_size.y):
		for x in range(world_size.x):
			var h00 = get_height_world(x * tile_size, z * tile_size)
			var h10 = get_height_world((x + 1) * tile_size, z * tile_size)
			var h01 = get_height_world(x * tile_size, (z + 1) * tile_size)
			var h11 = get_height_world((x + 1) * tile_size, (z + 1) * tile_size)

			var v00 = Vector3(x * tile_size, h00, z * tile_size)
			var v10 = Vector3((x + 1) * tile_size, h10, z * tile_size)
			var v01 = Vector3(x * tile_size, h01, (z + 1) * tile_size)
			var v11 = Vector3((x + 1) * tile_size, h11, (z + 1) * tile_size)

			st.add_vertex(v00)
			st.add_vertex(v10)
			st.add_vertex(v11)
			st.add_vertex(v00)
			st.add_vertex(v11)
			st.add_vertex(v01)

	st.generate_normals()
	mesh_instance.mesh = st.commit()
	
	# Apply offset to Mesh
	mesh_instance.mesh.surface_set_material(0, terrain_material)
	
	# 2. Setup Trees (passing the same offset)
	generate_scatter_poisson(palm, tree_density)
	generate_scatter_poisson(rock, rock_density)

func get_downhill_direction(x: float, z: float) -> Vector3:
	var step := 1.0

	var hL = get_height_world(x - step, z)
	var hR = get_height_world(x + step, z)
	var hD = get_height_world(x, z - step)
	var hU = get_height_world(x, z + step)

	var dir = Vector3(
		hL - hR,
		0.0,
		hD - hU
	)

	return dir.normalized()

func get_normal_world(x: float, z: float) -> Vector3:
	var step := 1.0

	var hL = get_height_world(x - step, z)
	var hR = get_height_world(x + step, z)
	var hD = get_height_world(x, z - step)
	var hU = get_height_world(x, z + step)

	var dx = hL - hR
	var dz = hD - hU

	return Vector3(dx, 2.0, dz).normalized()
func get_slope_world(x: float, z: float) -> float:
	var step := 1.0

	var hL = get_height_world(x - step, z)
	var hR = get_height_world(x + step, z)
	var hD = get_height_world(x, z - step)
	var hU = get_height_world(x, z + step)

	var dx = hR - hL
	var dz = hU - hD

	return sqrt(dx * dx + dz * dz)

func get_height_world(x: float, z: float) -> float:
	if not noise:
		return 0.0
	var n = noise.get_noise_2d(x, z)

	n = (n + 1.0) / 2.0
	n = pow(n, height_power)

	return n * terrain_height - terrain_height / 2.0

func generate_scatter_poisson(asset_scene: PackedScene, density: float):
	var scatter_container = Node3D.new()
	scatter_container.name = "Scatter_assets"
	add_child(scatter_container)
	

	var max_attempts = int(world_size.x * world_size.y * density)
	
	for i in range(max_attempts):
		var rx = randf() * world_size.x
		var rz = randf() * world_size.y
		var x = rx * tile_size
		var z = rz * tile_size
		var h = get_height_world(x, z)

		if h >= height_min and h <= height_max:
			var asset = asset_scene.instantiate()
			scatter_container.add_child(asset)
			asset.global_position = Vector3(x, h, z)
			asset.rotate_y(randf() * TAU)
