extends Area3D

signal entered_patrol_area(ship: Ship)

func _on_body_entered(body: Node3D) -> void:
	if body is Ship:
		var ship = body as Ship
		emit_signal("entered_patrol_area", ship)
