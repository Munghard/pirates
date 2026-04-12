extends Node3D

@export var ship: Ship

@export var canons_port: Array[Canon]
@export var canons_starboard: Array[Canon]

@export var ship_model: Node3D

var sails: Array[Node3D] = []

func _ready():
	sails.append(ship_model.get_node("BackSail"))
	sails.append(ship_model.get_node("Front Sail"))
	sails.append(ship_model.get_node("MidleSail"))

func _process(delta):
	var wind_dir = ship.gameManager.wind.direction

	# Convert wind into ship local space
	var local_wind = ship.global_transform.basis.inverse() * wind_dir
	var target_rot_y = atan2(-local_wind.x, -local_wind.z)

	for sail in sails:
		var rot = sail.rotation
		rot.y = lerp_angle(rot.y, target_rot_y, 3.0 * delta)
		sail.rotation = rot
