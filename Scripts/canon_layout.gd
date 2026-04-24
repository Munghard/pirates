extends Node3D

class_name Canons
@export var ship: Ship


@export var canon_scene: PackedScene

@export var ship_length: float
@export var ship_width: float

var canons_port: Array[Canon] = []
var canons_starboard: Array[Canon] = []
var canons_bow: Array[Canon] = []


func create_canons(port: int, starboard: int, bow: int):
	for child in get_children():
		child.queue_free()
	canons_port.clear()
	canons_starboard.clear()
	canons_bow.clear()
	for i in range(port):
		var canon = canon_scene.instantiate() as Canon
		add_child(canon)
		canon.rotation_degrees.y = -90
		var spacing = ship_length / (starboard + 1)

		var x = ship_width / -2.0
		var z = (ship_length / 2.0) - (spacing * (i + 1))
		var y = 0.5

		canon.position = Vector3(x, y, z)
		canons_port.append(canon)
		canon.active = true
	for i in range(starboard):
		var canon = canon_scene.instantiate() as Canon
		add_child(canon)
		canon.rotation_degrees.y = 90

		var spacing = ship_length / (starboard + 1)

		var x = ship_width / 2.0
		var z = (ship_length / 2.0) - (spacing * (i + 1))
		var y = 0.5
		canon.position = Vector3(x, y, z)
		canons_starboard.append(canon)
		canon.active = true
	
	for i in range(bow):
		var canon = canon_scene.instantiate() as Canon
		add_child(canon)
		
		var z = ship_length
		var spacing = ship_width / (bow + 1)
		var x = (ship_width / 2.0) - (spacing * (i + 1))
		var y = 0.5
		canon.position = Vector3(x, y, z)
		canons_bow.append(canon)
		canon.active = true
