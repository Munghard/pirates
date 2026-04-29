extends RigidBody3D

@export var lifeboat_ui: PackedScene
var crew := 5
var supplies := 20
var gold_per_crew := 20
var chance := 0.2
var lbu
var entered: bool = false

func _on_body_entered(body: Node) -> void:
	if body is PlayerShip and not entered:
		entered = true
		var player_ship: PlayerShip = body
		# do the ui panel with the choice of kill the crew or take them aboard
		lbu = lifeboat_ui.instantiate()
		lbu.crew = crew
		player_ship.gameManager.hud.add_child(lbu)
		lbu.connect("recruit", Callable(self , "_on_recruit_pressed").bind(player_ship))
		lbu.connect("kill", Callable(self , "_on_kill_pressed").bind(player_ship))


func _on_kill_pressed(player_ship: PlayerShip):
	if randf() > 0.5:
		player_ship.gain_gold(crew * gold_per_crew)
	else:
		player_ship.gain_supplies(supplies)
	#queue_free the lifeboat
	queue_free()


func _on_recruit_pressed(player_ship: PlayerShip):
	if randf() < chance:
		player_ship.gain_crew(crew)
	else:
		player_ship.kill_crew(int(float(crew) / 2.0))
	#queue_free the lifeboat
	queue_free()
