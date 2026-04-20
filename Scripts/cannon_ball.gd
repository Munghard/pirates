extends RigidBody3D

var damage = 5.0
var shooter: Node3D
@export var particle: PackedScene


func _on_body_entered(body: Node) -> void:
	if body is not Ship:
		return
	var ship := body as Ship
	if ship:
		var p = particle.instantiate()
		get_tree().current_scene.add_child(p)
		p.global_position = global_position

		ship.damage(damage, global_position, shooter)
