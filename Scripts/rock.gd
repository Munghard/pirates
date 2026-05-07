extends MeshInstance3D

func _ready() -> void:
	var children = get_children()
	if children.is_empty():
		return

	var keep = children.pick_random()

	for child in children:
		if child != keep:
			child.queue_free()