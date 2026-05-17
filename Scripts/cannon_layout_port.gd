extends Node3D

class_name Cannons_port

@export var port: Port
@export var cannon_scene: PackedScene

@export var length: float
@export var width: float

var cannons: Array[Cannon] = []
var cannons_unlocked := 0
@export var cannon_points: Array[Node3D] = []


func _ready():
	create_canons(true)

func add_cannon():
	cannons_unlocked += 1
	create_canons(true)

func create_canons(active: bool):
	#print("creating cannons in port");
	for child in get_children():
		child.queue_free()
	cannons.clear()

	for i in range(cannons_unlocked):
		var point = cannon_points[i]
		if not point:
			print("Error: Not enough cannon points defined for port cannons!")
			continue
		
		var cannon = cannon_scene.instantiate() as Cannon
		add_child(cannon)

		cannon.transform = point.transform

		cannon.active = active
		cannons.append(cannon)
