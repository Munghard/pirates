class_name Wind
extends Node3D

signal wind_changed(wind: Wind)

var direction: Vector3 = Vector3.FORWARD
var target_direction: Vector3 = Vector3.FORWARD

var strength: float = 0.0
var target_strength: float = 0.0

var max_wind_speed: float = 5.0

var timer := 0.0
var next_change := 0.0
var timer_enable := true


func _ready():
	randomize_wind()


func _process(delta):
	# smooth direction (unit vector)
	direction = direction.lerp(target_direction, delta * 0.5).normalized()

	# smooth strength
	strength = lerp(strength, target_strength, delta * 0.5)

	if timer_enable:
		timer += delta
		if timer >= next_change:
			randomize_wind()
			timer = 0.0
			next_change = randf_range(5.0, 100.0)


func get_wind_vector() -> Vector3:
	return direction * strength


func set_direction(dir: Vector3):
	target_direction = dir.normalized()
	target_strength = randf_range(0.0, max_wind_speed)
	emit_signal("wind_changed", self )


func randomize_wind():
	var dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	set_direction(dir)