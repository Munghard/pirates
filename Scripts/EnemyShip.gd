extends Ship

@export var pirate_ship: PackedScene
@export var navy_ship: PackedScene
@export var merchant_ship: PackedScene
@export var floater: Node3D

func _ready() -> void:
	var s
	ship_name = "Navy"
	max_hit_points = 150
	s = navy_ship.instantiate()
	defense = randi_range(1, 4)
	gold = randi_range(0, 200)
	if randf() > 0.5:
		ship_name = "Merchant"
		defense = randi_range(1, 2)
		max_hit_points = 50
		s = merchant_ship.instantiate()
		gold = randi_range(0, 1000)
		if randf() > 0.5:
			gold = randi_range(0, 100)
			ship_name = "Pirate"
			defense = randi_range(1, 3)
			max_hit_points = 100
			s = pirate_ship.instantiate()

	add_child(s)
	
	floater.target = s
	
	top_speed = randf_range(0.0, 3.0)
	target_speed = randf_range(0, top_speed)
	attack = randi_range(0, 5)
	
	yaw = randf_range(0.0, 359.0)

	hit_points = max_hit_points