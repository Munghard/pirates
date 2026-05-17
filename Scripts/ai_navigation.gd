extends NavigationAgent3D

class_name AI_Navigation

var path: PackedVector3Array = []
var index := 0

@onready var gameManager: GameManager = get_node("/root/GameManager")

@export var arrive_distance := 5.0
var last_valid_target: Vector3 = Vector3.ZERO

func set_target(from: Vector3, to: Vector3):
	var navigation_map = gameManager.world.navigation_region.get_navigation_map()
	path = NavigationServer3D.map_get_path(
		navigation_map,
		from,
		to,
		true
	)
	if path.is_empty():
		print("NAV FAIL: no path from", from, "to", to)

	last_valid_target = to
	index = 0

func get_current_target() -> Vector3:
	if path.is_empty() or index >= path.size():
		return last_valid_target
	return path[index]

func update_progress(position: Vector3):
	if path.is_empty() or index >= path.size():
		return

	if position.distance_to(path[index]) < arrive_distance:
		index += 1


func _physics_process(_delta: float) -> void:
	update_progress(get_parent().global_position)
