extends RigidBody3D

class_name LifeBoat

@onready var prompt_scene: PackedScene = preload("res://UI/prompt.tscn")
@export var lifeboat_ui: PackedScene
var crew := 5
var gold_per_crew := 20
var recruit_chance := 0.8
var kill_chance := 0.8
var lbu
var entered: bool = false

var speed = 5.0

var closest_port: Port = null

func _ready() -> void:
	#ports are probably not in yet
	await get_tree().process_frame
	var ports: Array[Port] = []
	for p in get_tree().get_nodes_in_group("Ports"):
		ports.append(p as Port)

	closest_port = GameManager.get_closest_port(ports, self )
	#print(closest_port.port_name);

func _physics_process(delta: float) -> void:
	if not closest_port:
		return

	var dir = (closest_port.global_position - global_position).normalized()
	var target_angle = atan2(dir.x, dir.z)

	global_rotation.y = rotate_toward(
		global_rotation.y,
		target_angle,
		delta
	)
	apply_central_force(global_basis.z * speed)

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
	if randf() < kill_chance:
		if randf() > 0.5:
			var _gold = crew * gold_per_crew
			player_ship.gain_gold(_gold)
			message += "Crew was slaughtered and you gained gold: " + str(_gold)
		else:
			var item_def = Item_Database.get_random_item_def()
			var item = InventoryItem.new(item_def.id, randi_range(1, item_def.max_stack))
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
	if randf() < recruit_chance:
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
