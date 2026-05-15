extends Area3D

class_name Port

var port_name := "Port"
var allegiance: Allegiance
var inventory: Inventory
@export var port_ui: PackedScene


var crew_to_recruit := 0
var crew_to_hire := 0
var agro_range := 25
var gold := 500
var player_ship: PlayerShip
var docked := false
var departing := false
var ui: Control

@onready var dock_sound = preload("res://Audio/ship-bell-two-chimes.mp3")

@export var flag_mesh: MeshInstance3D

@export_group("Inventory")
var inventory_panel: Control
var restock_time_left := 0.0
var restock_interval := 600.0

signal docking_changed(ship: Ship)
signal in_docking_radius(value: bool)
signal gold_changed(amount: int)
signal port_faction_changed(new_faction: FactionsData.Faction)

@onready var cannon_layout_port: Cannons_port = $Cannons

@export_group("World UI")
@onready var world_bars: Node3D = $world_bars
@onready var ship_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_ship
@onready var crew_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_crew
@onready var recovery_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_recovery
@onready var restock_timer_label: Label = $world_bars/SubViewport/Control/VBoxContainer/Label_restock
@onready var faction_texture_rect: TextureRect = $world_bars/SubViewport/Control/faction_icon
@onready var star_container: Control = $world_bars/SubViewport/Control/star_container
@onready var header_label: Label = $world_bars/SubViewport/Control/VBoxContainer/Label_h


@onready var gameManager: GameManager = get_node("/root/GameManager")

func _ready():
	setup_nodes()
	#setup_inventory()
	#await get_tree().process_frame
	# just mocking the bars for now
	ship_healthbar.value = 100.0
	crew_healthbar.value = 100.0
	recovery_healthbar.value = 100.0

func setup_nodes():
	world_bars = $world_bars
	ship_healthbar = $world_bars/SubViewport/Control/VBoxContainer/pb_ship
	crew_healthbar = $world_bars/SubViewport/Control/VBoxContainer/pb_crew
	recovery_healthbar = $world_bars/SubViewport/Control/VBoxContainer/pb_recovery
	restock_timer_label = $world_bars/SubViewport/Control/VBoxContainer/Label_restock
	faction_texture_rect = $world_bars/SubViewport/Control/faction_icon
	star_container = $world_bars/SubViewport/Control/star_container
	header_label = $world_bars/SubViewport/Control/VBoxContainer/Label_h
	
func setup_identity(world, port_data: Port_Data):
	setup_nodes()
	port_name = port_data.port_name
	allegiance = Allegiance.new(port_data.nation, port_data.faction, faction_texture_rect)
	inventory = SaveManager.create_inventory_from_data(
			self ,
			port_data.port_name,
			world,
			port_data.inventory
		)
	var faction_data = FactionsData.get_faction_stats(allegiance.faction)
	gold = faction_data.gold
	gold_changed.connect(_on_gold_changed)
	
	header_label.text = port_name
	
	set_world_flag()
	restock()
	restock_time_left = restock_interval
	restock_loop()


func toggle_inventory():
	inventory_panel.visible = !inventory_panel.visible

func set_world_flag():
	#setup flag
	var mat = flag_mesh.get_active_material(0) as ShaderMaterial
	var flag_texture = FactionsData.get_flag(allegiance.nation, allegiance.faction)
	mat.set_shader_parameter("flag_texture", flag_texture)

func restock_loop():
	while is_inside_tree():
		await get_tree().process_frame
		
		restock_time_left -= get_process_delta_time()
		var t = int(restock_time_left)
		var minutes = t / 60.0
		var seconds = t % 60
		restock_timer_label.text = "%02d:%02d" % [minutes, seconds]
		if restock_time_left <= 0.0:
			restock()
			restock_time_left = restock_interval
		

func get_closest_enemy_ship():
	var ship_nodes: Array = get_tree().get_nodes_in_group("Ships")
	var ships: Array[Ship] = []
	for n in ship_nodes:
		if n is Ship:
			ships.append(n)
	
	var enemy_factions: Array[FactionsData.Faction] = FactionsData.get_enemy_factions(allegiance.faction)
	var enemy_ships := GameManager.get_ships_by_faction(ships, enemy_factions)
	var _closest_ship := GameManager.get_closest_ship(enemy_ships, self )
	return _closest_ship

var targeting_timer := 0.0
var targeting_interval := 5.0
var closest_ship: Ship

func handle_targeting(delta: float):
	targeting_timer -= delta
	if targeting_timer <= 0.0:
		targeting_timer = targeting_interval

		var new_target = get_closest_enemy_ship()

		if new_target:
			var in_range = global_position.distance_squared_to(new_target.global_position) < agro_range * agro_range

			if in_range:
				closest_ship = new_target
			else:
				closest_ship = null

		for c in cannon_layout_port.cannons:
			c.active = closest_ship != null
		if closest_ship:
			gameManager.hud.ddd_label(
				"Target acquired " + closest_ship.ship_name,
				global_position,
				Color.WHEAT
			)

	if closest_ship:
		_handle_shooting(closest_ship.global_position, delta)


func _handle_shooting(target: Vector3, delta: float):
	#print("port shooting");
	var dist = global_position.distance_to(target)

	var cannons = cannon_layout_port.cannons

	for i in range(cannons.size()):
		var cannon: Cannon = cannons[i]
		var dir_to_target = (target - cannon.global_position).normalized()
		var angle_to_target = rad_to_deg(atan2(dir_to_target.x, dir_to_target.z))
		var current = cannon.global_rotation_degrees.y
		var diff = wrapf(current - angle_to_target, -180, 180)
		var target_angle = current - diff
		var target_degrees = lerp(current, target_angle, delta)
		cannon.global_rotation_degrees.y = target_degrees

		var pitch = dist / 2.0
		cannon.pitch = clampf(pitch, -25.0, 25.0)
		
		if abs(diff) < 15.0 and inventory.has_item("cannon_balls", 1):
			cannon.shoot(1.0, self , gameManager.audioManager)

	
func has_gold(amount: int) -> bool:
	return gold >= amount


func gain_gold(_gold: int):
	gold += _gold
	emit_signal("gold_changed", _gold)

func remove_gold(_gold: int):
	gold -= _gold
	emit_signal("gold_changed", _gold)

func setup_inventory() -> Inventory:
	inventory = Inventory.new(self , gameManager, 16, port_name + " market")
	return inventory


func restock():
	gain_gold(randi_range(100, 500))
	crew_to_hire = randi_range(1, 20)
	crew_to_recruit = randi_range(1, 5)
	inventory.clear()
	var items := FactionsData.get_faction_inventory(allegiance.faction)
	for item in items:
		inventory.add_item(item)
	

func _input(event):
	if docked and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_A, KEY_S, KEY_D:
				depart()

func _process(delta):
	handle_targeting(delta)

	if departing and player_ship:
		if player_ship.global_position.distance_to(global_position) > 200.0:
			departing = false
			docked = false
			player_ship = null

	if docked and player_ship and not departing:
		if player_ship.hit_points < player_ship.max_hit_points:
			player_ship.hit_points += delta * 10.0
			player_ship.hit_points = min(player_ship.hit_points, player_ship.max_hit_points)


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerShip:
		player_ship = body as PlayerShip
		in_docking_radius.emit(true)
		body.set_dockable_port(self )
	elif body is LifeBoat:
		body.queue_free()

	# auto sell items that drop near a port
	# if body is Loot:
	# 	var loot = body as Loot
	# 	if not is_instance_valid(loot) or loot.dropped_by == self:
	# 		return
	# 	var beneficiary = loot.dropped_by
	# 	if beneficiary == null:
	# 		beneficiary = gameManager.player_ship
	# 	sell(loot.item, beneficiary)
	# 	inventory.add_item(loot.item)
	# 	loot.queue_free()

func _on_body_exited(body: Node3D) -> void:
	if body is PlayerShip:
		body.set_dockable_port(null)

		docked = false
		in_docking_radius.emit(false)
		player_ship = null
		

func get_valid_water_position() -> Vector3:
	var center: Vector3 = global_position
	var radius = 15.0
	for i in range(30): # safety limit
		var angle = randf() * TAU
		var distance = sqrt(randf()) * radius

		var offset = Vector3(cos(angle), 0, sin(angle)) * distance
		var pos = center + offset

		var height = gameManager.world.terrain.get_height_world(pos.x, pos.z)

		# water assumed at y = 0 (adjust if needed)
		if height <= 0.0:
			pos.y = 0.0
			return pos

	# fallback (failsafe)
	return center
	

func dock():
	if not player_ship:
		print("cant dock, playership null")
		return
	gameManager.audioManager.play_sound(dock_sound, 0.0, -10.0)
	docked = true
	departing = false
	
	player_ship.target_speed = 0
	player_ship.side_to_side_speed = 0
	docking_changed.emit(player_ship)
	player_ship.set_docked(self )

	if allegiance.faction != player_ship.faction:
		capture_port()

	entered_port()

func capture_port():
	allegiance.faction = player_ship.faction
	set_faction_icon(allegiance.faction)
	allegiance.nation = player_ship.nation
	set_flag(allegiance.nation, allegiance.faction)
	set_world_flag()
	port_faction_changed.emit(allegiance.faction)
	faction_texture_rect.texture = FactionsData.get_faction_icon(allegiance.faction)
	gameManager.hud.new_notification("Captured %s" % port_name)

func depart():
	if ui:
		ui.queue_free()
	player_ship.gameManager.hud.set_player_inventory_panel_visible(false)
	docked = false
	docking_changed.emit(null)
	left_port()

	if player_ship:
		player_ship.set_docked(null)
		departing = true
		#player_ship.target_speed = player_ship.top_speed


func sell(item: InventoryItem, seller: Node3D):
	if not item or not seller:
		return
	var item_def = Item_Database.get_item_definition(item.id)
	var value = item_def.value
	if seller is Ship:
		seller.gain_gold(value)
	else:
		print("Seller isnt a ship, probably a port");

func _on_gold_changed(_gold: int):
	if ui:
		var label_gold: Label = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Label_gold")
		label_gold.text = "Gold: %s" % gold

func left_port():
	pass
	
func set_faction_icon(_faction: FactionsData.Faction):
	if not ui:
		return
	var _faction_texture = FactionsData.get_faction_icon(_faction)
	faction_texture_rect.texture = _faction_texture

func set_flag(_nation: FactionsData.Nation, _faction: FactionsData.Faction):
	if not ui:
		return
	var flag_texture_rect: TextureRect = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Allegiance_ui/texture_flag")
	var flag_texture = FactionsData.get_flag(_nation, _faction)
	flag_texture_rect.texture = flag_texture


func entered_port():
	update_port_ui()


func update_port_ui():
	# delete existing ui if any
	if ui:
		ui.queue_free()
	# instantiate port ui
	ui = port_ui.instantiate()
	# add to hud
	player_ship.gameManager.hud.add_child(ui)
	player_ship.gameManager.hud.set_player_inventory_panel_visible(true)
	# connect depart button
	ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/DepartButton").pressed.connect(func(): depart())
	ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Button_market").pressed.connect(func(): toggle_inventory())
	var label_header: Label = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/PanelContainer2/Label_h")
	var label_gold: Label = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Label_gold")
	var label_faction: Label = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Label_f")
	
	set_flag(allegiance.nation, allegiance.faction)
	set_faction_icon(allegiance.faction)
	
	label_header.text = "%s"%port_name
	label_gold.text = "Gold: %s"%gold
	label_faction.text = "%s\n%s" % [FactionsData.NATION_NAMES.get(allegiance.nation), FactionsData.FACTION_NAMES.get(allegiance.faction)]
	
	inventory_panel = ui.get_node("HBoxContainer/Inventory_panel")
	if not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)
	inventory_panel.update_inventory_ui(inventory, buy_item, func(_index): pass )

	var ps = player_ship

	var root = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer")
	
	var services_label := Label.new()
	services_label.text = "Services"
	services_label.theme_type_variation = "HeaderLarge"

	root.add_child(services_label)
	# create upgrades
	if crew_to_hire > 0:
		create_upgrade_ui(root, "CREW", "Hire crew: " + str(crew_to_hire) + " left", 100, func():
			crew_to_hire -= 1
			ps.gain_crew(1)
		)
		
	if crew_to_recruit > 0:
		create_upgrade_ui(root, "CREW", "Recruit crew: " + str(crew_to_recruit) + " left", 0, func():
			crew_to_recruit -= 1
			ps.gain_crew(1)
		)
	create_upgrade_ui(root, "SHIP", "Upgrade sails", 200, func(): ps.top_speed += 1.0)
	create_upgrade_ui(root, "SHIP", "Upgrade rudder", 200, func(): ps.agility += 1.0)
	create_upgrade_ui(root, "SHIP", "Upgrade hull", 200, func(): ps.hitpoints += 10.0)
	
	create_upgrade_ui(root, "COMBAT", "Upgrade guns", 500, func(): ps.upgrade_guns())
	create_upgrade_ui(root, "COMBAT", "Upgrade attack", 500, func(): ps.attack += 1.0)
	create_upgrade_ui(root, "COMBAT", "Upgrade defense", 500, func(): ps.defense += 1.0)

func _on_inventory_changed(_inventory: Inventory):
	if inventory_panel:
		inventory_panel.update_inventory_ui(
			_inventory,
			buy_item,
			func(_index): pass ,
		)

func buy_item(item_index: int):
	var _player_ship = gameManager.player_ship
	
	var item = inventory.items[item_index]
	if not item:
		return
	var item_def = Item_Database.get_item_definition(item.id)

	var bp = gameManager.hud.buy_panel.instantiate()
	gameManager.hud.add_child(bp)
	bp.label.text = "Buy %s" % [item_def.item_name]
	bp.icon.texture = item_def.icon
	bp.cost = item_def.value
	bp.available_money = _player_ship.gold

	var slider: Slider = bp.slider
	slider.max_value = item.stack
	slider.value = 1

	bp.cancel.connect(func():
		bp.queue_free()
	)

	bp.confirm.connect(func():
		var faction_items = FactionsData.get_faction_inventory(allegiance.faction)
		var _faction_has_item = false
		for _item in faction_items:
			if item.id == _item.id:
				_faction_has_item = true
				break

		var buy_amount = bp.slider.value # or bp.slider.value
		var cost = buy_amount * item_def.value
		var item_to_buy = InventoryItem.new(item.id, buy_amount)

		if _player_ship.has_gold(cost):
			_player_ship.remove_gold(cost)
			gain_gold(cost)

			if _player_ship.inventory.has_space():
				_player_ship.inventory.add_item(item_to_buy)
			else:
				inventory.drop_item(item_to_buy)
			#if not faction_has_item: ## dont consume item if its a faction item
			inventory.remove_from_stack(item.unique_id, buy_amount)
			print("player bought item in index: " + str(item_index))
		else:
			print("player doesn't have enough money for item in index: " + str(item_index))
		
		bp.queue_free()
	)

func create_upgrade_ui(root: Control, category: String, upgrade_name: String, upgrade_cost: int, function: Callable):
	# Try to find existing category container
	var category_vbox: VBoxContainer = root.get_node_or_null(category)

	if not category_vbox:
		# Create category container once
		category_vbox = VBoxContainer.new()
		category_vbox.name = category

		var category_label = Label.new()
		category_label.text = category
		category_label.theme_type_variation = "HeaderSmall"

		category_vbox.add_child(category_label)
		root.add_child(category_vbox)

	# Create upgrade row
	var new_upgrade_hbox = HBoxContainer.new()
	
	var spacer1 = Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL


	var new_upgrade_label = Label.new()
	new_upgrade_label.text = upgrade_name

	var new_upgrade_price_label = Label.new()
	new_upgrade_price_label.text = str(upgrade_cost) + "g"

	var new_upgrade_button = Button.new()
	new_upgrade_button.text = "Buy"
	new_upgrade_button.pressed.connect(func():
		var prompt = gameManager.hud.prompt.instantiate()
		gameManager.hud.add_child(prompt)
		prompt.label_h.text = "Confirm"
		prompt.label_message.text = "%s: %s$" % [upgrade_name, upgrade_cost]
		prompt.icon.visible = false
		
		prompt.confirm.connect(func():
			if not player_ship:
				return
			if player_ship.gold >= upgrade_cost:
				player_ship.gold -= upgrade_cost
				function.call()
				player_ship.gameManager.hud.new_notification("Acquired %s" % upgrade_name)
			else:
				print("Not enough gold for upgrade: ", upgrade_name)
			update_port_ui()
			prompt.queue_free()
		)

		prompt.cancel.connect(func():
			prompt.queue_free()
		)

		
	)

	new_upgrade_hbox.add_child(new_upgrade_label)
	new_upgrade_hbox.add_child(spacer1)
	new_upgrade_hbox.add_child(new_upgrade_price_label)
	new_upgrade_hbox.add_child(new_upgrade_button)

	category_vbox.add_child(new_upgrade_hbox)
