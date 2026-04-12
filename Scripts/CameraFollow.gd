extends Node3D

@export var target: Node3D
@onready var camera := $Camera3D

func _process(_delta: float) -> void:
	global_position = lerp(global_position, target.global_position, _delta * 5.0)

func set_zoom(value: float):
	camera.size = clamp(camera.size + value, 1, 50)
	# camera.position.z = clamp(camera.position.z + value, -200.0, -1.0)

func add_pitch(value: float):
	rotation.x = clamp(rotation.x + deg_to_rad(value), 0, 90)

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
				set_pitch(60)
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				set_zoom(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				set_zoom(-1)
