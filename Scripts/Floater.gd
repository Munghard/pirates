@tool
extends Node3D

@export var target: Node3D
@export var water: Water


func _process(_delta):
	if not target or not water:
		water = get_node("/root/GameManager").water
		return
	var pos = target.global_position
	var wave_data = water.get_wave_data(pos)
	target.global_position.y = wave_data.height
	# lerping once its correct
	# target.position.y = lerp(target.position.y, wave_data.height, 5.0 * _delta)
	
	var up = wave_data.normal
	var forward = target.global_transform.basis.z.normalized()

	# rebuild rotation from normal
	var right = - forward.cross(up).normalized()
	forward = - up.cross(right).normalized()

	target.global_transform.basis = Basis(right, up, forward)
	target.rotation_degrees.y = 0
