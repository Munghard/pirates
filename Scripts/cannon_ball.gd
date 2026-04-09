extends RigidBody3D
var damage = 5.0
var shooter: Node3D

func _on_body_entered(body: Node) -> void:
	if body is not Ship:
		return
	var ship := body as Ship
	if ship:
		ship.damage(damage, global_position, shooter)
