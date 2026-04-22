extends Node

class_name GameTime

signal day_started(day_count)
signal time_changed(time)

@export var day_length_seconds := 600.0 # real seconds for full 24h
@export var start_time := 12.0 # start at noon

var time_of_day := 0.0 # 0–24
var day_count := 0

func _ready():
	time_of_day = start_time

func _process(delta):
	var hours_per_second = 24.0 / day_length_seconds
	time_of_day += delta * hours_per_second
	
	if time_of_day >= 24.0:
		time_of_day -= 24.0
		day_count += 1
		emit_signal("day_started", day_count)
	
	emit_signal("time_changed", time_of_day)


func pass_time(amount: float): # hours
	time_of_day += amount

func get_time_string() -> String:
	var hours = int(time_of_day)
	var minutes = int((time_of_day - hours) * 60.0)
	return "%02d:%02d" % [hours, minutes]

func get_time_normalized() -> float:
	return time_of_day / 24.0 # 0–1

func is_daytime() -> bool:
	return time_of_day >= 6.0 and time_of_day < 18.0

func is_night() -> bool:
	return !is_daytime()
