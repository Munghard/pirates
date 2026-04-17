extends Node3D

# Inspector variables
@export var prefab: PackedScene
@export var amount: int = 10
@export var bounds: Vector3 = Vector3(10, 0, 10) # X/Z bounds, Y ignored
@export var rotation_range_min: Vector3 = Vector3(0, 0, 0)
@export var rotation_range_max: Vector3 = Vector3(0, 0, 0)
@export var water: Water

func _ready():
	if not prefab:
		push_warning("No prefab assigned!")
		return
	
	for i in range(amount):
		var instance := prefab.instantiate()
		add_child(instance)
		# Random position within bounds
		var pos = Vector3(randf_range(-bounds.x / 2, bounds.x / 2), 0, randf_range(-bounds.z / 2, bounds.z / 2))
		var rot = Vector3(randf_range(rotation_range_min.x, rotation_range_max.x), randf_range(rotation_range_min.y, rotation_range_max.y), randf_range(rotation_range_min.z, rotation_range_max.z))
		instance.position = pos
		instance.rotation_degrees = rot
		if "water" in instance:
			instance.water = water
