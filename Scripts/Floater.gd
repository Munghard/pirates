#@tool
extends Node3D

@export var target: Node3D
@export var water: Water

@onready var gameManager: GameManager = get_node("/root/GameManager")

func _ready():
	if water == null:
		if gameManager and gameManager.world:
			water = gameManager.world.water

func _physics_process(_delta):
	if water == null:
		await get_tree().process_frame
		if gameManager and gameManager.world:
			water = gameManager.world.water
		return
	var pos = target.global_position
	var wave_data = water.get_wave_data(pos)

	# lerping once its correct
	# target.position.y = lerp(target.position.y, wave_data.height, 5.0 * _delta)
	
	var up = wave_data.normal
	var forward = target.global_transform.basis.z.normalized()

	# rebuild rotation from normal
	var right = - forward.cross(up).normalized()
	forward = - up.cross(right).normalized()

	if target is RigidBody3D:
		var target_rb = target as RigidBody3D
		
		target_rb.angular_damp = 5.0
		target_rb.linear_damp = 4.0
		var current_up = target.global_transform.basis.y.normalized()
		var angular_vel = target_rb.angular_velocity
		var torque = current_up.cross(up) * 10.0
		torque -= angular_vel * 4.0

		target_rb.apply_torque(torque)
		var height_diff = wave_data.height - target.global_position.y
		var velocity_y = target_rb.linear_velocity.y

		var spring_strength = 50.0
		var damping = 5.0

		var force = height_diff * spring_strength - velocity_y * damping
		target_rb.apply_central_force(Vector3.UP * force)
	else:
		target.global_position.y = wave_data.height
		target.global_transform.basis = Basis(right, up, forward)
		target.rotation_degrees.y = 0
