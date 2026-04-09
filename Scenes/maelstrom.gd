extends Area3D

var bodies: Array[Node3D] = []
var pull_strength: float = 100.0 # max units per second the pull can move

func _on_body_entered(body: Node3D) -> void:
	var rb: RigidBody3D = body
	if rb:
		bodies.append(rb)
	print(bodies)

func _on_body_exited(body: Node3D) -> void:
	var rb: RigidBody3D = body
	if rb and bodies.has(rb):
		bodies.erase(rb)
	print(bodies)

func _process(delta):
	for body in bodies:
		if not body:
			continue
		var direction = (global_position - body.global_position)
		var distance = direction.length()
		if distance <= 5.0:
			var ship = body as Ship
			if ship:
				ship.damage(delta * 1.0, ship.global_position)
			continue
		
		var pull = direction.normalized() * pull_strength
		# apply as velocity change
		if body is RigidBody3D:
			var current_speed_toward_center = body.linear_velocity.dot(direction.normalized())
			# only pull if current velocity isn't enough to escape
			if current_speed_toward_center < pull_strength:
				body.linear_velocity += pull * delta
