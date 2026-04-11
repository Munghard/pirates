extends Node3D


@export var speed := 2.0
@export var magnitude := 0.1
@export var target: Node3D

func _process(_delta):
	if not target:
		return
	var pos = target.global_position - GM.water.global_position
	var wave_data = GM.water.get_wave_data(pos)
	target.global_position.y = wave_data.height + GM.water.global_position.y
	# lerping once its correct
	# target.position.y = lerp(target.position.y, wave_data.height, 5.0 * _delta)
	
	var up = wave_data.normal
	var forward = target.global_transform.basis.z.normalized()

	# rebuild rotation from normal
	var right = forward.cross(up).normalized()
	forward = up.cross(right).normalized()

	target.global_transform.basis = Basis(right, up, forward)
