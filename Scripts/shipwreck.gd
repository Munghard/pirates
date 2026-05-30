extends Node3D


@onready var prompt_scene: PackedScene = preload("res://UI/prompt.tscn")


var crew_kill_percentage := 5
var loot_find_chance := 0.8
var prompt: Prompt
var entered: bool = false
var interacted: bool = false

@export var loot_table: Array[String] = []

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is PlayerShip and not entered and not interacted:
		entered = true
		var player_ship: PlayerShip = body
		
		prompt = prompt_scene.instantiate()
		prompt.label_h.text = "Shipwreck"
		prompt.label_message.text = "The crew discovers the wreck of a ship washed ashore along the beach,\n its broken hull half-buried in sand and scattered debris.\n Some of the cargo may still be intact within the wreckage,\n though the structure looks unstable and dangerous to explore.\n You could send the crew to search for valuables,\n or dismantle the wreck for useful materials."
		
		player_ship.gameManager.hud.add_child(prompt)
		
		var option_1_button = Button.new()
		prompt.button_confirm.get_parent().add_child(option_1_button)
		option_1_button.text = "Search"
		option_1_button.pressed.connect(_option_1.bind(player_ship))
		
		var option_2_button = Button.new()
		prompt.button_confirm.get_parent().add_child(option_2_button)
		option_2_button.text = "Dismantle"
		option_2_button.pressed.connect(_option_2.bind(player_ship))
		prompt.connect("cancel", Callable(self , "close_prompt").bind(player_ship))
		
		prompt.button_confirm.visible = false


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is PlayerShip and entered:
		entered = false
		if prompt:
			prompt.queue_free()


func _option_1(player_ship: PlayerShip):
	prompt.queue_free()

	var message := ""

	if randf() < loot_find_chance:
		var item_def = Item_Database.get_item_definition(loot_table.pick_random())
		var item = InventoryItem.new(item_def.id, randi_range(1, item_def.max_stack))
		player_ship.gameManager.spawn_item_in_world(item, global_position)
		message += "Ship was searched and you recovered an item: " + item_def.item_name
	else:
		var _crew = player_ship.crew * crew_kill_percentage / 100.0
		player_ship.kill_crew(_crew)
		message += "Wraiths spawned and attacked the crew. " + str(_crew) + " crew members died in the battle."
	
	var result_prompt: Prompt = prompt_scene.instantiate()
	result_prompt.setup("Action results", message, load("res://Textures/pirate-flag.png"), false)
	player_ship.gameManager.hud.add_child(result_prompt)
	result_prompt.confirm.connect(func():
		result_prompt.queue_free()
		#queue_free the lifeboat
		interacted = true
	)


func _option_2(player_ship: PlayerShip):
	prompt.queue_free()
	
	var message := ""

	var item_def = Item_Database.get_item_definition("wood")
	for i in range(5):
		var item = InventoryItem.new(item_def.id, item_def.max_stack)
		player_ship.gameManager.spawn_item_in_world(item, player_ship.gameManager.get_position_around_point(global_position, 5))

	message += "You dismantle the ship and recover materials."

	var result_prompt: Prompt = prompt_scene.instantiate()
	result_prompt.setup("Action results", message, load("res://Textures/barrel.png"), false)
	player_ship.gameManager.hud.add_child(result_prompt)
	result_prompt.confirm.connect(func():
		result_prompt.queue_free()
		#queue_free the lifeboat
		interacted = true
	)

func close_prompt(_player_ship: PlayerShip):
	if prompt:
		prompt.queue_free()
