extends Node3D
class_name Camera

@onready var gameManager: GameManager = get_node("/root/GameManager")
@export var secondary_target: Node3D
@onready var camera := $Camera3D
var target_position: Vector3


var return_delay := 2.0
var return_timer := 0.0
var is_dragging := false
var max_distance := 25.0
var pan_multiplier := 1.0

var max_camera_size := 50.0

var debug_camera_sizes = [25.0, 37.5, 50.0, 100.0, 200.0]
var camera_sizes = [25.0, 37.5, 50.0]

var current_size_index := 0

var zoom := 0.0
var debug_mode = false

var movement_offset_smoothed: Vector3
func _ready():
	zoom = camera.size

func get_max_distance() -> float:
	if debug_mode:
		return INF
	return max_distance * pan_multiplier

func _process(delta: float) -> void:
	var move := Vector3.ZERO
	var movement_offset = Vector3.ZERO
	var target = gameManager.player_ship
	var player_ship = gameManager.player_ship

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
		elif not debug_mode:
			if secondary_target:
				target_position = target.global_position.lerp(secondary_target.global_position, 0.5)
			else:
				target_position = target.global_position

	
				var forward_mag = player_ship.target_speed * 3.0
				var side_mag = player_ship.side_to_side_speed * 6.0

				forward_mag = clamp(forward_mag, -8.0, 8.0)
				side_mag = clamp(side_mag, -5.0, 5.0)

				var forward_dir = player_ship.basis.z
				var side_dir = player_ship.basis.x

				movement_offset = forward_dir * forward_mag + side_dir * side_mag

	movement_offset_smoothed = lerp(movement_offset_smoothed, movement_offset, delta)
	var desired_position = target_position + movement_offset_smoothed
	
	global_position = global_position.lerp(desired_position, delta * 5.0)

	#var distance_to_target := global_position.distance_to(target_position)
	#var auto_zoom = distance_to_target * 0.5
	camera.size = lerp(camera.size, zoom, delta * 5.0) # + auto_zoom

func set_zoom(value: int):
	if debug_mode:
		current_size_index = clamp(current_size_index + value, 0, debug_camera_sizes.size() - 1)
		zoom = debug_camera_sizes[current_size_index]
	else:
		current_size_index = clamp(current_size_index + value, 0, camera_sizes.size() - 1)
		zoom = camera_sizes[current_size_index]

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
