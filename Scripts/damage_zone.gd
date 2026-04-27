extends Area3D

class_name DamageZone

@export var damage_multiplier := 1.0


func get_ship() -> Ship:
	var node = get_parent()
	while node:
		if node is Ship:
			return node
		node = node.get_parent()
	return null

func _on_body_entered(body: Node3D) -> void:
	if body is CannonBall:
		var cb = body as CannonBall
		var ship = get_ship()
		if ship:
			ship.damage(cb.damage, damage_multiplier, cb.global_position, cb.shooter)
