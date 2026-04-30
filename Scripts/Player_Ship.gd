extends Ship

class_name PlayerShip


func _ready() -> void:
	super._ready()
	ship_name = "Player"
	faction = FactionsData.Faction.PIRATE
	var faction_stats = FactionsData.get_faction_stats(faction)
	
	max_hit_points = faction_stats.max_hit_points
	hit_points = max_hit_points
	attack = faction_stats.attack
	defense = faction_stats.defense
	top_speed = faction_stats.speed
	
	guns = faction_stats.guns
	gold = faction_stats.gold
	supplies = faction_stats.supplies
	crew = faction_stats.max_crew
	max_crew = faction_stats.max_crew

	#connect("crew_changed", Callable(self , "_on_crew_changed"))
	connect("supplies_changed", Callable(self , "_on_supplies_changed"))
	connect("gold_changed", Callable(self , "_on_gold_changed"))
	connect("recieved_damage", Callable(self , "_on_recieved_damage"))
	
	#active_starboard(true)
	#active_port(true)
	set_faction_texture()
	
	setup_guns()

	setup_inventory()


func setup_inventory():
	inventory = Inventory.new(self , 16, "Player cargo")
	
	# ensure HUD exists before connecting
	await get_tree().process_frame

	inventory.inventory_changed.connect(gameManager.hud.inventory_panel.update_inventory_ui)
	inventory.inventory_notification.connect(_inventory_changed)

	inventory.add_item(InventoryItem.new(0, 30))
	inventory.add_item(InventoryItem.new(1, 10))

func _inventory_changed(_message: String):
	gameManager.hud.new_notification(_message)

func _on_recieved_damage(_amount: float, _attacker: Node3D):
	gameManager.camerarig.secondary_target = _attacker

func _on_crew_changed(amount: int, gained: bool):
	var text = "Gained" if gained else "Lost"
	gameManager.hud.new_notification("%s: %d crew" % [text, amount])

func _on_supplies_changed(amount: int, gained: bool):
	var text = "Gained" if gained else "Lost"
	gameManager.hud.new_notification("%s: %d supplies" % [text, amount])

func _on_gold_changed(amount: int, gained: bool):
	var text = "Gained" if gained else "Lost"
	gameManager.hud.new_notification("%s: %d gold" % [text, amount])

func sink():
	# dont call super, were overriding behaviour
	gameManager.hud.new_notification("You sunk my battleship...")
	await get_tree().create_timer(5.0).timeout
	
	get_tree().reload_current_scene()

func upgrade_guns():
	guns += 1
	setup_guns()

func emergency_brake():
	side_to_side_speed = 0.0
	target_speed = 0.0
	yaw_deg = rotation_degrees.y

func _process(_delta: float) -> void:
	super._process(_delta)
	# Continuous steering logic
	pass

	
func _input(event: InputEvent) -> void:
	# One-time actions (like shooting or incremental speed changes) 
	# stay here to prevent "machine-gun" firing or instant max speed
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_A:
			side_to_side_speed += 1.0
		if event.keycode == KEY_D:
			side_to_side_speed -= 1.0
		if event.keycode == KEY_W:
			target_speed = clamp(target_speed + 1.0, 0, top_speed)
		if event.keycode == KEY_S:
			target_speed = clamp(target_speed - 1.0, 0, top_speed)
		if event.keycode == KEY_END:
			shoot_bow()
		if event.keycode == KEY_LEFT:
			shoot_starboard()
		if event.keycode == KEY_RIGHT:
			shoot_port()
		if event.keycode == KEY_UP:
			starboard_pitch(5)
			port_pitch(5)
			bow_pitch(5)
		if event.keycode == KEY_DOWN:
			starboard_pitch(-5)
			port_pitch(-5)
			bow_pitch(-5)
		if event.keycode == KEY_Q:
			yaw_deg = yaw_deg + 22.5
		if event.keycode == KEY_E:
			yaw_deg = yaw_deg - 22.5
		if event.keycode == KEY_X:
			emergency_brake()


func _on_boarding_area_body_entered(body: Node3D) -> void:
	var ship
	if body is Ship and body != self:
		ship = body as Ship
		set_boarding_target(ship)


func _on_boarding_area_body_exited(body: Node3D) -> void:
	var ship
	if body is Ship:
		ship = body as Ship
		if boarding_target == ship:
			set_boarding_target(null)
