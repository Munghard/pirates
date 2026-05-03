extends Area3D

class_name Port

var port_name := "Port"
var allegiance: Allegiance
var inventory: Inventory
@export var port_ui: PackedScene

var gold := 500
var player_ship: PlayerShip
var docked := false
var departing := false
var ui: Control
var inventory_panel
signal docking_changed(ship: Ship)
signal in_docking_radius(value: bool)
signal gold_changed(amount: int, gained: bool)

@export_group("World UI")
@onready var world_bars: Node3D = $world_bars
@onready var ship_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_ship
@onready var crew_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_crew
@onready var recovery_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_recovery
@onready var faction_texture: TextureRect = $world_bars/SubViewport/Control/faction_icon
@onready var star_container: Control = $world_bars/SubViewport/Control/star_container


@onready var gameManager: GameManager = get_node("/root/GameManager")

func _ready():
	port_name = FactionsData.PORT_NAMES[randi_range(0, FactionsData.PORT_NAMES.size() - 1)]
	var faction := FactionsData.roll_faction()
	var nation := FactionsData.roll_nation()
	allegiance = Allegiance.new(nation, faction, faction_texture)
	setup_inventory()
	
	# just mocking the bars for now
	ship_healthbar.value = 100.0
	crew_healthbar.value = 100.0
	recovery_healthbar.value = 100.0

func has_gold(amount: int) -> bool:
	return gold >= amount


func gain_gold(_gold: int):
	gold += _gold
	emit_signal("gold_changed", _gold, true)

func remove_gold(_gold: int):
	gold -= _gold
	emit_signal("gold_changed", _gold, false)

func setup_inventory():
	inventory = Inventory.new(self , gameManager, 16, port_name + " market")
	await get_tree().process_frame
	restock()


func restock():
	var items := FactionsData.get_faction_inventory(allegiance.faction)
	for item in items:
		inventory.add_item(item)
	

func _input(event):
	if docked and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_A, KEY_S, KEY_D:
				depart()

func _process(delta):
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
	docked = true
	departing = false
	
	player_ship.target_speed = 0
	player_ship.side_to_side_speed = 0
	docking_changed.emit(player_ship)
	player_ship.set_docked(self )
	entered_port()

func depart():
	if ui:
		ui.queue_free()
	player_ship.gameManager.hud.set_player_inventory_panel_visible(false)
	docked = false
	docking_changed.emit(null)

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

func entered_port():
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
	var label_header: Label = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Label_h")
	var label_gold: Label = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Label_gold")
	var label_faction: Label = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Label_f")
	
	label_header.text = "%s"%port_name
	label_gold.text = "Gold: %s"%gold
	label_faction.text = "%s\n%s" % [FactionsData.NATION_NAMES.get(allegiance.nation), FactionsData.FACTION_NAMES.get(allegiance.faction)]
	
	gold_changed.connect(func(_gold, _gained): label_gold.text = "Gold: %s"%gold)

	inventory_panel = ui.get_node("HBoxContainer/Inventory_panel")
	if not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)
	inventory_panel.update_inventory_ui(inventory, buy_item)

	var ps = player_ship

	# create upgrades
	create_upgrade_ui(ui, "SUPPLIES", "Buy supplies", 100, func(): ps.gain_supplies(100))
	create_upgrade_ui(ui, "SHIP", "Upgrade sails", 200, func(): ps.top_speed += 1.0)
	create_upgrade_ui(ui, "SHIP", "Upgrade rudder", 200, func(): ps.agility += 1.0)
	create_upgrade_ui(ui, "CREW", "Hire crew", 100, func(): ps.gain_crew(1))
	create_upgrade_ui(ui, "CREW", "Recruit crew", 0, func(): ps.gain_crew(1))
	create_upgrade_ui(ui, "COMBAT", "Upgrade guns", 500, func(): ps.upgrade_guns())
	create_upgrade_ui(ui, "COMBAT", "Upgrade attack", 500, func(): ps.attack += 1.0)
	create_upgrade_ui(ui, "COMBAT", "Upgrade defense", 500, func(): ps.defense += 1.0)

func _on_inventory_changed(_inventory: Inventory):
	if inventory_panel:
		inventory_panel.update_inventory_ui(
			_inventory,
			buy_item
		)

func buy_item(item_index: int):
	var _player_ship = gameManager.player_ship
	
	var item = inventory.items[item_index]
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

			inventory.consume_item(item_to_buy.id, item_to_buy.stack)
			print("player bought item in index: " + str(item_index))
		else:
			print("player doesn't have enough money for item in index: " + str(item_index))
		
		bp.queue_free()
	)

func create_upgrade_ui(_ui: Control, category: String, upgrade_name: String, upgrade_cost: int, function: Callable):
	var root = _ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer")

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

	var new_upgrade_label = Label.new()
	new_upgrade_label.text = upgrade_name

	var new_upgrade_price_label = Label.new()
	new_upgrade_price_label.text = str(upgrade_cost) + "g"

	var new_upgrade_button = Button.new()
	new_upgrade_button.text = "Buy"
	new_upgrade_button.pressed.connect(func():
		if not player_ship:
			return
		if player_ship.gold >= upgrade_cost:
			player_ship.gold -= upgrade_cost
			function.call()
			player_ship.gameManager.hud.new_notification("Acquired %s" % upgrade_name)
		else:
			print("Not enough gold for upgrade: ", upgrade_name)
	)

	new_upgrade_hbox.add_child(new_upgrade_label)
	new_upgrade_hbox.add_child(new_upgrade_price_label)
	new_upgrade_hbox.add_child(new_upgrade_button)

	category_vbox.add_child(new_upgrade_hbox)
