extends Ship

class_name PlayerShip

var equipment: Equipment

@onready var fanfare = preload("res://Audio/fanfare.mp3")

func _ready() -> void:
	ship_name = "Player"
	faction = FactionsData.Faction.PIRATE
	var faction_stats = FactionsData.get_faction_stats(faction)
	equipment = Equipment.new()
	add_child(equipment)
	
	max_hit_points = faction_stats.max_hit_points
	hit_points = max_hit_points
	attack = 1 # faction_stats.attack
	defense = 1 # faction_stats.defense
	top_speed = faction_stats.speed
	
	gold = faction_stats.gold
	crew = faction_stats.max_crew
	max_crew = faction_stats.max_crew

	#connect("crew_changed", Callable(self , "_on_crew_changed"))
	connect("gold_changed", Callable(self , "_on_gold_changed"))
	connect("gold_gained", Callable(self , "_on_gold_gained"))
	connect("gold_lost", Callable(self , "_on_gold_lost"))
	
	connect("crew_lost", Callable(self , "_on_crew_lost"))

	connect("recieved_damage", Callable(self , "_on_recieved_damage"))
	connect("destroyed_ship", Callable(self , "_on_destroyed_ship"))
	
	#active_starboard(true)
	#active_port(true)
	set_faction_texture()
	
	setup_inventory()
	
	equipment.equipment_changed.connect(func(_side): setup_cannons())
	setup_cannons()

	setup_ship_model(faction)

	super._ready()
	
func setup_inventory():
	inventory = Inventory.new(self , gameManager, 16, "Player cargo")
	
	await get_tree().process_frame
	# ensure HUD exists before connecting
	connect_inventory_listeners(inventory)
	
	add_player_loadout()

func add_player_loadout():
	inventory.add_item(InventoryItem.new(2, 2))
	inventory.add_item(InventoryItem.new(15, 2))
	inventory.add_item(InventoryItem.new(16, 2))
	inventory.add_item(InventoryItem.new(0, 30))
	inventory.add_item(InventoryItem.new(1, 30))
	inventory.add_item(InventoryItem.new(3, 50))
	inventory.add_item(InventoryItem.new(12, 1))
	inventory.add_item(InventoryItem.new(9, 10))
	inventory.add_item(InventoryItem.new(13, 5))
	inventory.add_item(InventoryItem.new(18, 1))

func connect_inventory_listeners(_inventory: Inventory):
	if not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)
		inventory.inventory_notification.connect(_inventory_changed)
		docked_changed.connect(func(_dock): _on_inventory_changed(_inventory))
		_on_inventory_changed(_inventory)

func _on_inventory_changed(_inventory: Inventory):
	#super._on_inventory_changed(_inventory) # setup cannons runs in here
	# spyglass effect
	var pan_multiplier = 1.0
	if _inventory.has_item(12, 1):
		pan_multiplier = 2.0
	gameManager.camerarig.pan_multiplier = pan_multiplier

	# fishing operation effect
	for child in get_children():
		if child is FishingOperation:
			child.queue_free()
	if _inventory.has_item(18, 1):
		var fo = FishingOperation.new(gameManager)
		add_child(fo)

	# item click behaviour
	if docked:
		gameManager.hud.inventory_panel.update_inventory_ui(
			_inventory,
			sell_item,
			func(_index): pass ,
		)
	else:
		gameManager.hud.inventory_panel.update_inventory_ui(
			_inventory,
			use_item,
			_inventory.drop_item_at_index
		)

func setup_cannons():
	await get_tree().process_frame

	var bow = []
	var port = []
	var starboard = []

	for item in equipment.bow:
		if item != null:
			var cannon_level = Cannon.get_cannon_level(item.id)
			bow.append({"level": cannon_level})
	for item in equipment.port:
		if item != null:
			var cannon_level = Cannon.get_cannon_level(item.id)
			port.append({"level": cannon_level})
	for item in equipment.starboard:
		if item != null:
			var cannon_level = Cannon.get_cannon_level(item.id)
			starboard.append({"level": cannon_level})
	#print("setup cannons %s %s %s" % [port, starboard, bow])

	cannons_layout.create_canons(
		port,
		starboard,
		bow,
		trajectories
	)


var item_use: Item_Use

func use_item(item_index: int):
	var item = inventory.items[item_index]
	if not item:
		return
	var item_def = Item_Database.get_item_definition(item.id)
	
	# only one use operation at a time
	if item_use:
		gameManager.hud.ddd_label("Already using an item", global_position, Color.RED)
		return
	item_use = Item_Use.new()
	add_child(item_use)
	print("Trying to use " + item_def.item_name);
	item_use.use_item(
		item_def.id,
		self ,
		func finished():
			item_use.queue_free(),
		func consume(_consume):
			if _consume:
				inventory.consume_item_at(item_index, 1)
	)
	

func sell_item(item_index: int):
	var item = inventory.items[item_index]
	if not item:
		return
	var item_def = Item_Database.get_item_definition(item.id)

	var faction_items = FactionsData.get_faction_inventory(docked.allegiance.faction)
	var faction_has_item = false
	for _item in faction_items:
		if item.id == _item.id:
			faction_has_item = true
			break


	var bp = gameManager.hud.buy_panel.instantiate()
	gameManager.hud.add_child(bp)
	bp.label.text = "Sell %s" % [item_def.item_name]
	bp.icon.texture = item_def.icon
	bp.cost = item_def.value
	if faction_has_item:
		bp.available_money = 999999
	else:
		bp.available_money = docked.gold

	#bp.available_money = docked.inventory.item_amount(10)

	var slider: Slider = bp.slider
	slider.max_value = item.stack
	slider.value = 1

	bp.cancel.connect(func():
		bp.queue_free()
	)

	bp.confirm.connect(func():
		var sell_amount = bp.slider.value # or bp.slider.value
		var cost = sell_amount * item_def.value
		var item_to_sell = InventoryItem.new(item.id, sell_amount)
		
		var can_buy = faction_has_item or docked.gold >= cost
		#if docked.inventory.item_amount(10) >= cost:
		if can_buy:
			if not faction_has_item:
				docked.remove_gold(cost)
			gain_gold(cost)
			
			if docked.inventory.has_space():
				docked.inventory.add_item(item_to_sell)
			else:
				inventory.drop_item(item_to_sell)

			inventory.remove_from_stack(item.unique_id, sell_amount)
			print("player sold item in index: " + str(item_index))
		else:
			print(docked.name + " doesn't have enough money for item in index: " + str(item_index))
		
		bp.queue_free()
	)

func _inventory_changed(_message: String):
	gameManager.hud.ddd_label(_message, global_position, Color.GREEN)

func _on_destroyed_ship(ship: Ship):
	if FactionsData.is_enemy(ship.faction, faction):
		gameManager.audioManager.play_sound(fanfare, 0.0, -20.0)

func _on_recieved_damage(_amount: float, _attacker: Node3D):
	gameManager.camerarig.secondary_target = _attacker

func _on_crew_gained(amount: int):
	var text = "Gained"
	gameManager.hud.new_notification("%s: %d crew" % [text, amount])

func _on_crew_lost(amount: int):
	var text = "Lost"
	gameManager.hud.new_notification("%s: %d crew" % [text, amount])
	if crew <= 0:
		destroy_ship(self )

func _on_gold_gained(amount: int):
	var text = "Gained"
	gameManager.hud.new_notification("%s: %d gold" % [text, amount])

func _on_gold_lost(amount: int):
	var text = "Lost"
	gameManager.hud.new_notification("%s: %d gold" % [text, amount])

func sink():
	# dont call super, were overriding behaviour
	#gameManager.hud.new_notification("The sea swallows you whole...")
	gameManager.hud.new_notification("The ocean keeps what it takes...")
	await get_tree().create_timer(5.0).timeout
	
	gameManager.new_game()
	

func upgrade_guns():
	print("not implemented")
	pass

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
			target_speed = clamp(target_speed + 1.0, -1.0, top_speed)
		if event.keycode == KEY_S:
			target_speed = clamp(target_speed - 1.0, -1.0, top_speed)
		if event.keycode == KEY_G:
			toggle_cannons_trajectory()
		if event.keycode == KEY_END:
			shoot_bow()
		if event.keycode == KEY_LEFT:
			shoot_port()
		if event.keycode == KEY_RIGHT:
			shoot_starboard()
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
		if dockable_port != null and event.keycode == KEY_SPACE:
			dockable_port.dock()


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
