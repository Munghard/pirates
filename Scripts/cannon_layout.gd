extends Node3D

class_name Cannons
@export var ship: Ship
@export var cannon_scene: PackedScene

@export var ship_length: float
@export var ship_width: float

var cannons_port: Array[Cannon] = []
var cannons_starboard: Array[Cannon] = []
var cannons_bow: Array[Cannon] = []


func create_canons(port: Array, starboard: Array, bow: Array, active: bool):
	for child in get_children():
		child.queue_free()
	cannons_port.clear()
	cannons_starboard.clear()
	cannons_bow.clear()
	for i in range(starboard.size()):
		var canon = cannon_scene.instantiate() as Cannon
		add_child(canon)
		canon.damage_multiplier = starboard[i]["level"]
		canon.rotation_degrees.y = -90
		var spacing = ship_length / (starboard.size() + 1)

		var x = ship_width / -2.0
		var z = (ship_length / 2.0) - (spacing * (i + 1))
		var y = 0.5

		canon.position = Vector3(x, y, z)
		cannons_starboard.append(canon)
		canon.active = active
	for i in range(port.size()):
		var canon = cannon_scene.instantiate() as Cannon
		add_child(canon)
		canon.damage_multiplier = port[i]["level"]
		canon.rotation_degrees.y = 90

		var spacing = ship_length / (port.size() + 1)

		var x = ship_width / 2.0
		var z = (ship_length / 2.0) - (spacing * (i + 1))
		var y = 0.5
		canon.position = Vector3(x, y, z)
		cannons_port.append(canon)
		canon.active = active
	
	for i in range(bow.size()):
		var canon = cannon_scene.instantiate() as Cannon
		add_child(canon)
		canon.damage_multiplier = bow[i]["level"]

		var z = ship_length
		var spacing = ship_width / (bow.size() + 1)
		var x = (ship_width / 2.0) - (spacing * (i + 1))
		var y = 0.5
		canon.position = Vector3(x, y, z)
		cannons_bow.append(canon)
		canon.active = active