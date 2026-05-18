extends Node3D
class_name Chunk_Manager

var active_chunks = {}
var chunk_size = 32
var render_distance = 2
var tile_size = 1

@export_group("Nodes")
@export var terrain: Terrain
@export_group("Data")
@export var scatter_data: Array[Scatter_Data]

@onready var gameManager: GameManager = get_node("/root/GameManager")

var camera_position: Vector3

var current_player_chunk := Vector2i(999999, 999999)

func _process(_delta: float) -> void:
	if not terrain.terrain_ready:
		return
	var chunk = world_to_chunk(gameManager.player_ship.global_position)

	if chunk != current_player_chunk:
		current_player_chunk = chunk
		update_chunks(gameManager.player_ship.global_position)

	#print(active_chunks.size());

func create_chunk(coord: Vector2i) -> WorldChunk:
	var chunk = WorldChunk.new()
	chunk.chunk_coord = coord
	add_child(chunk)

	generate_chunk_scatter(chunk)

	return chunk

func world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(
		floor(pos.x / (chunk_size * tile_size)),
		floor(pos.z / (chunk_size * tile_size))
	)

func update_chunks(player_pos: Vector3):
	var center = world_to_chunk(player_pos)
	var needed = {}

	for x in range(center.x - render_distance, center.x + render_distance + 1):
		for y in range(center.y - render_distance, center.y + render_distance + 1):
			var coord = Vector2i(x, y)
			needed[coord] = true

			if not active_chunks.has(coord):
				active_chunks[coord] = create_chunk(coord)

	# unload old chunks
	for coord in active_chunks.keys():
		if not needed.has(coord):
			active_chunks[coord].queue_free()
			active_chunks.erase(coord)

func generate_chunk_scatter(chunk: WorldChunk):
	for scatter in scatter_data:
		var mmi = MultiMeshInstance3D.new()
		var mm = MultiMesh.new()

		mm.mesh = scatter.mesh
		mm.transform_format = MultiMesh.TRANSFORM_3D

		var points = []

		for i in range(scatter.amount): # fixed per chunk for now
			var local_x = randf() * chunk_size
			var local_z = randf() * chunk_size

			var world_x = (chunk.chunk_coord.x * chunk_size + local_x) * tile_size
			var world_z = (chunk.chunk_coord.y * chunk_size + local_z) * tile_size

			var h = terrain.get_height_world(world_x, world_z)

			if h < scatter.height_min or h > scatter.height_max:
				continue

			points.append(Vector3(world_x, h, world_z))

		mm.instance_count = points.size()

		for i in points.size():
			var t = Transform3D()
			t.origin = points[i]

			var rot = Basis()

			# fixed rotation offsets
			rot = rot.rotated(Vector3.RIGHT, scatter.rotation.x)
			rot = rot.rotated(Vector3.UP, scatter.rotation.y)
			rot = rot.rotated(Vector3.FORWARD, scatter.rotation.z)

			# random Y rotation
			rot = rot.rotated(Vector3.UP, randf() * TAU)

			t.basis = rot
			
			t.basis = t.basis.scaled(Vector3(scatter.scale, scatter.scale, scatter.scale))

			mm.set_instance_transform(i, t)

		mmi.multimesh = mm
		chunk.add_child(mmi)
