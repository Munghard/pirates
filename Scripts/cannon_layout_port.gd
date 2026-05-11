extends Node3D

class_name Cannons_port

@export var port: Port
@export var cannon_scene: PackedScene

@export var length: float
@export var width: float

var cannons: Array[Cannon] = []
@export var cannon_points: Array[Node3D] = []

func _ready():
	create_canons(true)

func create_canons(active: bool):
	#print("creating cannons in port");
	for child in get_children():
		child.queue_free()
	cannons.clear()

	for i in range(cannon_points.size()):
		var canon = cannon_scene.instantiate() as Cannon
		add_child(canon)

		canon.global_rotation = cannon_points[i].global_rotation
		canon.position = cannon_points[i].global_position

		cannons.append(canon)
		canon.active = active
