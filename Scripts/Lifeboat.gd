extends RigidBody3D

@onready var prompt_scene: PackedScene = preload("res://UI/prompt.tscn")
@export var lifeboat_ui: PackedScene
var crew := 5
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
		lbu.connect("leave", Callable(self , "_on_leave_pressed").bind(player_ship))


func _on_kill_pressed(player_ship: PlayerShip):
	var message := ""
	if randf() < chance:
		if randf() > 0.5:
			var _gold = crew * gold_per_crew
			player_ship.gain_gold(_gold)
			message += "Crew was slaughtered and you gained gold: " + str(_gold)
		else:
			var item_def = Item_Database.get_random_item_def()
			var item = InventoryItem.new(item_def.id, randi_range(0, item_def.max_stack))
			player_ship.gameManager.spawn_item_in_world(item, global_position)
			message += "Crew was slaughtered and you recovered an item: " + item_def.item_name
	else:
		var _crew = randi_range(0, crew)
		player_ship.kill_crew(_crew)
		message += "Fought the crew and lost " + str(_crew) + " crew"
	
	var prompt: Prompt = prompt_scene.instantiate()
	prompt.setup("Skirmish results", message, load("res://Textures/pirate-flag.png"), false)
	player_ship.gameManager.hud.add_child(prompt)
	prompt.confirm.connect(func():
		prompt.queue_free()
		#queue_free the lifeboat
		queue_free()
	)


func _on_recruit_pressed(player_ship: PlayerShip):
	var message := ""
	if randf() < chance:
		player_ship.gain_crew(crew)
		message += "Successfully recruited " + str(crew) + " crew"
	else:
		var _crew = randi_range(0, crew)
		message += "Failed at recruiting\nThe crew attacked and you lost " + str(_crew) + " crew"
		player_ship.kill_crew(_crew)

	var prompt: Prompt = prompt_scene.instantiate()
	prompt.setup("Skirmish results", message, load("res://Textures/pirate-flag.png"), false)
	player_ship.gameManager.hud.add_child(prompt)
	prompt.confirm.connect(func():
		prompt.queue_free()
		#queue_free the lifeboat
		queue_free()
	)

func _on_leave_pressed(_player_ship: PlayerShip):
	pass
