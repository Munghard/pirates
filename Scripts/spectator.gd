extends Camera3D

class_name Spectator

@export var move_speed := 10.0
@export var mouse_sensitivity := 0.002

var rotation_x := 0.0
var rotation_y := 0.0

	
func _process(delta):
	var direction := Vector3.ZERO

	# Movement input
	if Input.is_key_pressed(KEY_W):
		direction -= transform.basis.z

	if Input.is_key_pressed(KEY_S):
		direction += transform.basis.z

	if Input.is_key_pressed(KEY_A):
		direction -= transform.basis.x

	if Input.is_key_pressed(KEY_D):
		direction += transform.basis.x

	if Input.is_key_pressed(KEY_SPACE):
		direction += Vector3.UP

	if Input.is_key_pressed(KEY_CTRL):
		direction += Vector3.DOWN

	if Input.is_key_pressed(KEY_SHIFT):
		move_speed = 100.0
	else:
		move_speed = 10.0
	# Normalize so diagonal movement isn't faster
	if direction != Vector3.ZERO:
		direction = direction.normalized()

	global_position += direction * move_speed * delta

func _input(event):
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity

		rotation_x = clamp(rotation_x, deg_to_rad(-89), deg_to_rad(89))

		rotation = Vector3(rotation_x, rotation_y, 0)
