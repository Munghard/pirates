@tool
extends Node3D
class_name Terrain

@export_group("Assets")
@export var palm: PackedScene
@export var terrain_material: Material

@export_group("Terrain Settings")
@export var world_size: Vector2i = Vector2i(32, 32)
@export var tile_size: float = 1.0
@export var terrain_height: float = 10.0
@export var noise_frequency: float = 0.05

@export_group("Vegetation")
@export var tree_density: float = 0.2
@export var height_min: float = 1.0
@export var height_max: float = 8.0

var mesh_instance

@export var regen := false:
	set(value):
		create_terrain_mesh()
		regen = false

var noise: FastNoiseLite

func _ready():
	create_terrain()

func create_terrain():
	create_terrain_mesh()
	create_collision()

func create_collision():
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()

	collision.shape = mesh_instance.mesh.create_trimesh_shape()

	static_body.add_child(collision)
	add_child(static_body)
	static_body.position = mesh_instance.position

func setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = noise_frequency

func create_terrain_mesh():
	setup_noise()
	
	for child in get_children():
		child.queue_free()
	
	# Calculate the offset to center the terrain
	var offset = Vector3(0, -terrain_height / 2.0, 0)
	
	# 1. Setup Mesh
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	add_child(mesh_instance)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(world_size.y):
		for x in range(world_size.x):
			var h00 = get_height(x, z)
			var h10 = get_height(x + 1, z)
			var h01 = get_height(x, z + 1)
			var h11 = get_height(x + 1, z + 1)

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
	mesh_instance.position = offset
	mesh_instance.mesh.surface_set_material(0, terrain_material)
	
	# 2. Setup Trees (passing the same offset)
	generate_trees_poisson(offset)

func get_height_world(x: float, z: float) -> float:
	var n = noise.get_noise_2d(
		x * noise_frequency,
		z * noise_frequency
	)
	return n * terrain_height

func get_height(x: float, z: float) -> float:
	var n = (noise.get_noise_2d(x, z) + 1.0) / 2.0
	return n * terrain_height

func generate_trees_poisson(offset: Vector3):
	if not palm: return
	
	var tree_container = Node3D.new()
	tree_container.name = "Trees"
	add_child(tree_container)
	
	# Apply the EXACT same offset to the container
	tree_container.position = offset

	var max_attempts = int(world_size.x * world_size.y * tree_density)
	
	for i in range(max_attempts):
		var rx = randf() * world_size.x
		var rz = randf() * world_size.y
		var h = get_height(rx, rz)

		if h >= height_min and h <= height_max:
			var tree = palm.instantiate()
			tree_container.add_child(tree)
			# Position is now relative to the container, so it matches the mesh perfectly
			tree.position = Vector3(rx * tile_size, h, rz * tile_size)
			tree.rotate_y(randf() * TAU)
