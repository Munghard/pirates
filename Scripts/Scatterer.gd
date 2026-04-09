extends Node3D

# Inspector variables
@export var prefab: PackedScene
@export var amount: int = 10
@export var bounds: Vector3 = Vector3(10, 0, 10) # X/Z bounds, Y ignored

func _ready():
    if not prefab:
        push_warning("No prefab assigned!")
        return
    
    for i in range(amount):
        var instance = prefab.instantiate()
        # Random position within bounds
        var pos = Vector3(
            randf_range(-bounds.x / 2, bounds.x / 2),
            0,
            randf_range(-bounds.z / 2, bounds.z / 2)
        )
        instance.position = pos
        add_child(instance)