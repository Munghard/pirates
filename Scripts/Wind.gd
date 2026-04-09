extends Node3D
class_name Wind

var direction: Vector3
var max_wind_speed: float = 5.0

var next_change := 0.0
var timer := 0.0

var target_direction
var timer_enable := true

signal wind_changed(dir: Vector3)


func _ready() -> void:
	randomize_direction()


func _process(delta):
	direction = direction.lerp(target_direction, delta / 100.0)

	if not timer_enable:
		return

	timer += delta
	if timer >= next_change:
		randomize_direction()
		timer = 0.0
		next_change = randf_range(5.0, 100.0)

func set_direction(_direction: Vector3):
	# direction = _direction * randf_range(0, max_wind_speed)
	target_direction = _direction * randf_range(0, max_wind_speed)
	emit_signal("wind_changed", target_direction)

func randomize_direction():
	var dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	set_direction(dir)

func set_enable_wind(value: bool):
	timer_enable = value
	if value:
		randomize_direction()
	emit_signal("wind_changed", target_direction)
