extends Control
class_name DebugMenu

@onready var gameManager: GameManager = get_node("/root/GameManager")
@export var vbox: VBoxContainer
@export var wind_label: Label
@export var console: LineEdit


func init_debugMenu():
	console.text_submitted.connect(evaluate_console)
	gameManager.world.wind.wind_changed.connect(_on_update_wind)

	create_debug_button("Give Gold", func():
		gameManager.player_ship.gain_gold(10000)
	)

	create_debug_button("Give Supplies", func():
		gameManager.player_ship.gain_supplies(10000)
	)

	create_debug_button("Heal Ship", func():
		var ship = gameManager.player_ship
		ship.hit_points = ship.max_hit_points
		ship.hit_points_changed.emit(ship.hit_points)

		ship.crew = ship.max_crew
		ship.crew_changed.emit(ship.crew)
	)
	create_debug_button("Add item to inventory", func():
		gameManager.player_ship.inventory.add_item(
			InventoryItem.new(
				Item_Database.item_database[
					randi_range(0, Item_Database.item_database.size() - 1)
				].id,
				 10
				)
			)
	)
	# turn off initally
	visible = false


func evaluate_console(text: String):
	var parts = text.split(" ")
	match parts[0]:
		"give":
			if parts.size() >= 2:
				var item_id = parts[1]

				var amount = 1
				if parts.size() >= 3:
					amount = int(parts[2])
				else:
					amount = Item_Database.get_item_definition(item_id).max_stack

				gameManager.player_ship.inventory.add_item(
					InventoryItem.new(item_id, amount)
				)
	print(text)
	console.clear()

func _on_update_wind(wind: Wind):
	wind_label.text = "Speed: %.2f\nDegrees: %.2f\nEnabled: %s\nNext change: %.2f" % [wind.strength, rad_to_deg(atan2(wind.direction.x, wind.direction.z)), str(wind.timer_enable), wind.next_change - wind.timer]

func create_debug_button(text: String, action: Callable) -> void:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = text
	row.add_child(label)

	var button := Button.new()
	button.text = "Execute"
	button.pressed.connect(action)
	row.add_child(button)
	
	vbox.add_child(row)

func _on_button_toggle_wind_pressed() -> void:
	gameManager.wind.set_enable_wind(!gameManager.wind.timer_enable)
