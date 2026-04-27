extends Area3D

var bodies: Array[Node3D] = []
@export var pull_strength: float = 100.0 # max units per second the pull can move
@export var spin_strength: float = 100.0

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		var rb: RigidBody3D = body
		if rb:
			bodies.append(rb)

func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		var rb: RigidBody3D = body
		if rb and bodies.has(rb):
			bodies.erase(rb)

func _process(delta):
	rotate_y(spin_strength * delta)
	for body in bodies:
		if not body:
			continue
		var direction = (global_position - body.global_position)
		direction.y = -1.0
		var distance = direction.length()
		if distance <= 5.0:
			var ship = body as Ship
			if ship:
				ship.damage(delta * 1.0, 1.0, ship.global_position, self )
			continue
		
		var pull = direction.normalized() * pull_strength
		# apply as velocity change
		if body is RigidBody3D:
			var current_speed_toward_center = body.linear_velocity.dot(direction.normalized())
			# only pull if current velocity isn't enough to escape
			if current_speed_toward_center < pull_strength:
				body.apply_central_force(pull * delta * body.mass)
