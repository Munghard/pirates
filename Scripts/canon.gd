extends Node3D
class_name Canon

@export var cannon_ball: PackedScene
@export var canon: Node3D
@export var particle: GPUParticles3D
var force := 25.0
var damage := 5.0
var pitch := 0.0

var line: Node3D

var fire_rate = 5.0
var fire_timer = 0.0

func shoot(attack: float):
	if not fire_timer <= 0.0:
		return
	fire_timer = fire_rate

	var dir: Vector3 = canon.global_basis.z
	var b: RigidBody3D = cannon_ball.instantiate()
	b.damage = damage * attack
	get_tree().current_scene.add_child(b)
	b.global_position = canon.global_position + dir * 2.0
	var shoot_dir = (dir + (Vector3.UP * deg_to_rad(pitch))).normalized()
	b.apply_impulse(shoot_dir * force)
	particle.restart()

func _process(delta):
	fire_timer -= delta
	canon.get_node("mesh").rotation = Vector3(deg_to_rad(-pitch - 90), 0, 0)
	create_line()

func create_line():
	var mesh_instance
	if not line:
		line = Node3D.new()
		add_child(line)

		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "mesh"
		mesh_instance.mesh = ImmediateMesh.new()
		line.add_child(mesh_instance)
		var material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(1, 1, 1, 0.8) # 50% transparent
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		mesh_instance.material_override = material

	mesh_instance = line.get_node("mesh")
	var mesh: ImmediateMesh = mesh_instance.mesh
	mesh.clear_surfaces()

	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var dir = canon.basis.z # or whatever direction you want
	var velocity = (dir + (Vector3.UP * deg_to_rad(pitch))).normalized() * force

	var pos = global_position
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

	var step = 0.1
	var steps = 30

	var prev = pos

	for i in range(steps):
		velocity.y -= gravity * step
		pos += velocity * step

		mesh.surface_add_vertex(prev - global_position)
		mesh.surface_add_vertex(pos - global_position)

		prev = pos

	mesh.surface_end()
