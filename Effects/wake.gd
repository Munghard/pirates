extends Node3D

@onready var ship: Ship = get_parent() as Ship
@export var width: float = 2.0
@export var max_points := 20
var water: Water
var trail_points: Array[Vector3] = []
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@export var material: Material
@export var y_offset: float = 0.2


var last_point: Vector3

func _ready() -> void:
	await get_tree().process_frame
	water = ship.gameManager.world.water

func _process(_delta):
	update_trail()
	build_mesh()

func update_trail():
	var pos = global_position
	
	if trail_points.is_empty() or pos.distance_to(last_point) > 2.0:
		trail_points.push_front(pos)
		last_point = pos
	
	if trail_points.size() > max_points:
		trail_points.pop_back()

	for i in range(trail_points.size()):
		var p = trail_points[i]
		p.y = water.get_wave_data(p).height + y_offset
		trail_points[i] = p

func build_mesh():
	if trail_points.size() < 2:
		return

	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()

	# --- build vertices ---
	for i in range(trail_points.size()):
		var forward: Vector3
		
		if i < trail_points.size() - 1:
			forward = (trail_points[i] - trail_points[i + 1]).normalized()
		else:
			forward = (trail_points[i - 1] - trail_points[i]).normalized()
		
		var right = forward.cross(Vector3.UP).normalized()
		
		var t = float(i) / trail_points.size()
		var w = width * (1.0 + t)

		var left_point = trail_points[i] - right * w
		var right_point = trail_points[i] + right * w
		
		vertices.append(mesh_instance.to_local(left_point))
		vertices.append(mesh_instance.to_local(right_point))

		uvs.append(Vector2(0, t))
		uvs.append(Vector2(1, t))

		var alpha = 1.0 - t
		colors.append(Color(1, 1, 1, alpha))
		colors.append(Color(1, 1, 1, alpha))

		normals.append(Vector3.UP)
		normals.append(Vector3.UP)

	# --- build indices ---
	for i in range(trail_points.size() - 1):
		var idx = i * 2
		
		indices.append(idx)
		indices.append(idx + 1)
		indices.append(idx + 2)
		
		indices.append(idx + 1)
		indices.append(idx + 3)
		indices.append(idx + 2)

	# --- build mesh ---
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	

	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	mesh_instance.mesh = mesh
	mesh_instance.mesh.surface_set_material(0, material)
