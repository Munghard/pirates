extends Node3D
class_name Camera

@export var target: Node3D
@export var secondary_target: Node3D
@onready var camera := $Camera3D
var target_position

var return_delay := 2.0
var return_timer := 0.0
var is_dragging := false
var max_distance := 25.0
var pan_multiplier := 1.0

var max_camera_size := 200.0

func get_max_distance() -> float:
	return max_distance * pan_multiplier

func _process(delta: float) -> void:
	var move := Vector3.ZERO

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		is_dragging = true
		return_timer = 0.0
		
		var mouse_delta = Input.get_last_mouse_velocity()
		move = Vector3(mouse_delta.x, 0, mouse_delta.y) * delta * 0.05
		
		target_position += move

		var offset = target_position - target.global_position
		offset = offset.limit_length(get_max_distance())
		target_position = target.global_position + offset
	else:
		if is_dragging:
			is_dragging = false
			return_timer = return_delay
		
		if return_timer > 0.0:
			return_timer -= delta
		else:
			if secondary_target:
				target_position = target.global_position.lerp(secondary_target.global_position, 0.5)
			else:
				target_position = target.global_position

	global_position = global_position.lerp(target_position, delta * 5.0)

func set_zoom(value: float):
	camera.size = clamp(camera.size + value, 1, max_camera_size)
	# camera.position.z = clamp(camera.position.z + value, -200.0, -1.0)

func add_pitch(value: float):
	rotation.x = clamp(rotation.x + deg_to_rad(value), 0, deg_to_rad(90))

func set_pitch(value: float):
	rotation.x = clamp(deg_to_rad(value), 0, 90)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_PAGEDOWN:
				add_pitch(-5)
			KEY_PAGEUP:
				add_pitch(5)
			KEY_HOME:
				set_pitch(55)
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				set_zoom(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				set_zoom(-1)
