extends RigidBody3D

@export var lifeboat_ui: PackedScene
var crew := 5
var gold_per_crew := 20
var chance := 0.2
var lbu

func _on_body_entered(body: Node) -> void:
	if body is PlayerShip:
		var player_ship: PlayerShip = body
		# do the ui panel with the choice of kill the crew or take them aboard
		lbu = lifeboat_ui.instantiate()
		lbu.crew = crew
		player_ship.gameManager.hud.add_child(lbu)
		lbu.connect("recruit_pressed", Callable(self , "_on_recruit_pressed").bind(player_ship))
		lbu.connect("kill_pressed", Callable(self , "_on_kill_pressed").bind(player_ship))


func _on_kill_pressed(player_ship: PlayerShip):
	player_ship.gold += crew * gold_per_crew
	#queue_free the lifeboat
	queue_free()
	lbu.queue_free()


func _on_recruit_pressed(player_ship: PlayerShip):
	if randf() < chance:
		player_ship.crew += crew
	else:
		player_ship.crew -= int(float(crew) / 2.0)
	#queue_free the lifeboat
	queue_free()
	lbu.queue_free()
