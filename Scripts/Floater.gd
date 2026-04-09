extends Node3D


@export var speed := 2.0
@export var magnitude := 0.1
@export var target: Node3D


func _process(_delta):
	if not target:
		return
	target.position.y = sin(Time.get_ticks_msec() / 1000.0 * speed) * magnitude
	target.rotate_x(deg_to_rad(sin(Time.get_ticks_msec() / 1000.0 * speed / 2.0) * magnitude / 2.0))
