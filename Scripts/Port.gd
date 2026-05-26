extends Area3D

class_name Port

var port_name := "Port"
var allegiance: Allegiance
var inventory: Inventory
@export var port_ui: PackedScene

var level := 1

var max_crew := 0
var crew := 0
var crew_to_recruit := 0

var agro_range := 50.0
var gold := 0
var player_ship: PlayerShip
var docked := false
var departing := false
var shooting_range := 25.0

var market_opened := false
var can_capture := false

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
@onready var status_label: Label = $world_bars/SubViewport/Control/Label_status

@export_group("Patrol")
@onready var patrol_trigger: Area3D = $patrol_trigger
var spawned_patrol_ships = 0
var max_patrol_ships := 3

@export_group("Health")
@export var max_hit_points := .0
var hit_points := max_hit_points
var in_combat: bool = false
var last_damage_time: int = 0
var out_of_combat_time: int = 20000 # milli seconds without taking damage to be considered out of combat
var recovery_progress := 1.0
var damage_sustained := 0.0
var crew_health := 20.0

var accumulated_damage := 0.0
var damage_threshold := 20.0
var alive := true

var defense := 1.0

var attacker: Node3D

signal recovery_changed(time: float)
signal hit_points_changed(amount: float)
signal recieved_damage(amount: float, attacker: Node3D)
signal destroyed(attacker: Node3D)
signal crew_changed(amount: int)

@onready var gameManager: GameManager = get_node("/root/GameManager")

func _ready():
	patrol_trigger.entered_patrol_area.connect(_entered_patrol_area)
	setup_nodes()
	#setup_inventory() # handled elsewhere

	
	crew_healthbar.value = crew
	crew_healthbar.max_value = max_crew
	ship_healthbar.value = hit_points
	ship_healthbar.max_value = max_hit_points
	recovery_healthbar.value = 1.0
	recovery_healthbar.max_value = 1.0
	
	connect("crew_changed", Callable(self , "_on_crew_changed"))
	connect("hit_points_changed", Callable(self , "_on_hit_points_changed"))
	connect("recovery_changed", Callable(self , "_on_recovery_changed"))


func setup_nodes():
	world_bars = $world_bars
	ship_healthbar = $world_bars/SubViewport/Control/VBoxContainer/pb_ship
	crew_healthbar = $world_bars/SubViewport/Control/VBoxContainer/pb_crew
	recovery_healthbar = $world_bars/SubViewport/Control/VBoxContainer/pb_recovery
	restock_timer_label = $world_bars/SubViewport/Control/VBoxContainer/Label_restock
	faction_texture_rect = $world_bars/SubViewport/Control/faction_icon
	star_container = $world_bars/SubViewport/Control/star_container
	header_label = $world_bars/SubViewport/Control/VBoxContainer/Label_h
	cannon_layout_port = $Cannons

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

	
	max_crew = port_data.max_crew
	crew = port_data.crew
	max_hit_points = port_data.max_hit_points
	hit_points = port_data.hit_points
	
	hit_points_changed.emit(hit_points)
	crew_changed.emit(crew)
	
	header_label.text = port_name
	
	set_world_flag()

	cannon_layout_port.cannons_unlocked = port_data.cannons_unlocked
	cannon_layout_port.create_canons(true)
	print("Port %s setup with %s cannons unlocked" % [port_name, cannon_layout_port.cannons_unlocked])

	market_opened = port_data.market_opened

	restock()
	
	restock_time_left = port_data.restock_time_left
	
	restock_loop()

	can_capture = allegiance.faction == FactionsData.Faction.NONE

func repair(_delta):
	if not in_combat and hit_points < max_hit_points:
		gain_hitpoints(_delta * 1.0 * (float(crew) / float(max_crew)))

func gain_hitpoints(hp: float):
	hit_points = clamp(hit_points + hp, 0, max_hit_points)
	emit_signal("hit_points_changed", hit_points)


func _on_hit_points_changed(_hp: float):
	if not ship_healthbar:
		return
	ship_healthbar.max_value = max_hit_points
	ship_healthbar.value = hit_points

func _on_recovery_changed(_progress: float):
	if not recovery_healthbar:
		return
	recovery_healthbar.value = _progress

func _on_crew_changed(_crew: int):
	if not crew_healthbar:
		return
	crew_healthbar.max_value = max_crew
	crew_healthbar.value = crew


func damage(_damage: float, _multiplier: float, _position: Vector3, _attacker: Node3D):
	# gameManager.hud.selected_ship = self
	attacker = _attacker
	in_combat = true
	last_damage_time = Time.get_ticks_msec()
	
	var multiplied_damage = _damage * _multiplier
	
	var color = Color.WHITE
	if _multiplier < 0.5:
		color = Color.GRAY
	elif _multiplier > 1.0:
		color = Color.YELLOW
	
	accumulated_damage += multiplied_damage

	if accumulated_damage >= damage_threshold:
		var s = "%.1f" % accumulated_damage
		gameManager.hud.ddd_label(s, _position, color)
		accumulated_damage = 0

	hit_points = clamp(hit_points - (multiplied_damage / defense), 0, max_hit_points)
	emit_signal("recieved_damage", (multiplied_damage / defense), _attacker)
	emit_signal("hit_points_changed", hit_points)

	if hit_points <= 0.0 and alive:
		alive = false
		emit_signal("destroyed", _attacker)

	
	if (hit_points <= 0 or crew <= 0) and not can_capture:
		surrender()

	damage_sustained += multiplied_damage
	while damage_sustained >= crew_health:
		damage_sustained -= crew_health
		kill_crew(1)

func set_faction(_faction: FactionsData.Faction):
	allegiance.set_faction(_faction)
	set_flag(allegiance.nation, allegiance.faction)
	set_world_flag()
	set_faction_icon(allegiance.faction)

func surrender():
	can_capture = true
	set_faction(FactionsData.Faction.NONE)
	gameManager.hud.ddd_label("The port has surrendered!\nYou can now capture it.", global_position, Color.GREEN)

func kill_crew(amount: int):
	if crew <= 0:
		return
	
	crew -= amount
	crew = max(crew, 0)
	emit_signal("crew_changed", crew)
	if crew <= 0:
		surrender()

func _entered_patrol_area(ship: Ship):
	if FactionsData.is_enemy(ship.faction, allegiance.faction):
		spawn_patrol_ships()


func spawn_patrol_ships():
	if spawned_patrol_ships >= max_patrol_ships:
		return
	for i in range(max_patrol_ships):
		spawned_patrol_ships += 1
		var pos := gameManager.get_position_around_point(global_position, 50.0)
		var ship := gameManager.spawn_ship(pos, allegiance.nation, allegiance.faction)
		ship.set_state(EnemyShip.AIState.PATROL)
		#ship.attacker = target
		ship.patrol_point = global_position
		ship.on_sink.connect(func():
			spawned_patrol_ships -= 1
		)
		await get_tree().create_timer(5.0).timeout

func toggle_inventory():
	inventory_panel.visible = !inventory_panel.visible


func set_world_flag():
	#setup flag
	var mat = flag_mesh.get_active_material(0) as ShaderMaterial
	var flag_texture = FactionsData.get_flag(allegiance.nation, allegiance.faction)
	mat.set_shader_parameter("flag_texture", flag_texture)
	var color = FactionsData.get_nation_color(allegiance.nation)
	mat.set_shader_parameter("flag_color", color)

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

		var pitch = dist / 3.2
		cannon.pitch = clampf(pitch, -25.0, 25.0)
		
		if abs(diff) < shooting_range:
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
	spawned_patrol_ships = 0
	gold = 0
	gain_gold(randi_range(100, 500))
	crew = max_crew
	crew_to_recruit = randi_range(1, 20)
	if market_opened:
		restock_inventory()


func restock_inventory():
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
	handle_capture(delta)
	
	var elapsed_since_damage := Time.get_ticks_msec() - last_damage_time
	

	if departing and player_ship:
		if player_ship.global_position.distance_to(global_position) > 200.0:
			departing = false
			docked = false
			player_ship = null

	if docked and player_ship and not departing:
		if player_ship.hit_points < player_ship.max_hit_points:
			player_ship.hit_points += delta * 10.0
			player_ship.hit_points = min(player_ship.hit_points, player_ship.max_hit_points)

	if crew > 0 and allegiance.faction != FactionsData.Faction.NONE:
		recovery_progress = clamp(elapsed_since_damage / float(out_of_combat_time), 0.0, 1.0)
		repair(delta)
	
	if hit_points > 0.0 and crew > 0 and get_combat_readiness() > 0.0:
		handle_targeting(delta)
		

	# check if in combat
	emit_signal("recovery_changed", recovery_progress)
	if in_combat and elapsed_since_damage > out_of_combat_time:
		in_combat = false

#var ships_in_docking_radius :Array[Ship]
var player_ship_in_docking_radius: PlayerShip

var ships_in_area: Array[Ship] = []

func is_contested() -> bool:
	if ships_in_area.is_empty():
		return false

	var base_faction = ships_in_area[0].faction

	for ship in ships_in_area:
		if not is_instance_valid(ship):
			continue

		if ship.faction != base_faction:
			return true

	return false

var capture_timer := 0.0
var capture_time_required := 10.0

func handle_capture(delta: float):
	if not can_capture:
		status_label.text = ""
		return

	if ships_in_area.is_empty():
		capture_timer = 0.0
		status_label.text = ""
		return

	if is_contested():
		status_label.text = "Contested"
		capture_timer = 0.0
		return

	var dominant = get_dominant_faction()

	if dominant == FactionsData.Faction.NONE:
		capture_timer = 0.0
		return

	if dominant == allegiance.faction:
		capture_timer = 0.0
		return

	capture_timer += delta
	status_label.text = "Capturing by %s %.1f / %.1f" % [FactionsData.FACTION_NAMES.get(dominant), capture_timer, capture_time_required]

	if capture_timer >= capture_time_required:
		capture_port(dominant, allegiance.nation)
		capture_timer = 0.0

func get_dominant_faction() -> FactionsData.Faction:
	if ships_in_area.is_empty():
		return FactionsData.Faction.NONE

	var counts := {}

	for ship in ships_in_area:
		if not is_instance_valid(ship):
			continue

		var f = ship.faction
		counts[f] = counts.get(f, 0) + 1

	var dominant_faction := FactionsData.Faction.NONE
	var highest_count := 0

	for f in counts.keys():
		if counts[f] > highest_count:
			highest_count = counts[f]
			dominant_faction = f

	return dominant_faction

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerShip:
		player_ship = body as PlayerShip
		player_ship_in_docking_radius = player_ship
		in_docking_radius.emit(true)
		if can_capture or allegiance.faction == player_ship.faction:
			body.set_dockable_port(self )
	if body is Ship:
		var ship = body as Ship
		ships_in_area.append(ship)
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

		player_ship_in_docking_radius = null
		docked = false
		in_docking_radius.emit(false)
		player_ship = null
	if body is Ship:
		var ship = body as Ship
		ships_in_area.erase(ship)
		

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

	entered_port()

func capture_port(faction: FactionsData.Faction, nation: FactionsData.Nation):
	can_capture = false
	allegiance.set_faction(faction)
	set_faction_icon(faction)
	allegiance.nation = nation
	set_flag(nation, faction)
	set_world_flag()
	port_faction_changed.emit(faction)
	faction_texture_rect.texture = FactionsData.get_faction_icon(faction)
	gameManager.hud.ddd_label("Captured %s" % port_name, global_position)
	gameManager.territory.create_grid_territories(gameManager.world.ports)
	# reset cannons on capture
	cannon_layout_port.cannons_unlocked = 0
	cannon_layout_port.create_canons(true)
	if faction == gameManager.player_ship.faction:
		gameManager.audioManager.play_sound(preload("res://Audio/fanfare.mp3"), 0.0, -10.0)

func depart():
	if ui:
		ui.queue_free()
	player_ship.gameManager.hud.set_player_inventory_panel_visible(false)
	player_ship.gameManager.hud.open_stash(false)
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
	flag_texture_rect.modulate = FactionsData.get_nation_color(_nation)


func entered_port():
	update_port_ui()


func open_market():
	inventory = setup_inventory()
	restock_inventory()
	market_opened = true
	if ui:
		var market_button: Button = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Button_market")
		market_button.visible = true

func sell_materials():
	if not player_ship:
		return

	while true:
		var index = player_ship.inventory.get_item_index_of_type(Item_Definition.Type.MATERIAL)
		if index == -1:
			break

		var item = player_ship.inventory.items[index]
		if item == null:
			continue

		var item_def = Item_Database.get_item_definition(item.id)
		if item_def == null:
			continue

		player_ship.gain_gold(item_def.value * item.stack)
		player_ship.inventory.remove_item_at(index)


func update_port_ui():
	# delete existing ui if any
	if ui:
		ui.queue_free()
	# instantiate port ui
	ui = port_ui.instantiate()
	# add to hud
	player_ship.gameManager.hud.add_child(ui)
	player_ship.gameManager.hud.set_player_inventory_panel_visible(true)
	player_ship.gameManager.hud.open_stash(true)
	# connect depart button
	ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/DepartButton").pressed.connect(func(): depart())
	
	var market_button: Button = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Button_market")
	
	var sell_materials_button: Button = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Button_sell_materials")
	
	market_button.pressed.connect(func(): toggle_inventory())
	
	sell_materials_button.pressed.connect(func(): sell_materials())
	
	if market_opened:
		market_button.visible = true
	else:
		market_button.visible = false
	
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
	inventory_panel.update_inventory_ui(
		inventory,
		buy_item,
		func(_index): pass ,
		func(_index): pass
		)

	inventory_panel.visible = market_opened

	var ps = player_ship

	var root = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer")
	var label_stats: Label = ui.get_node("HBoxContainer/Port_panel/MarginContainer/HBoxContainer/VBoxContainer/Label_stats")
	
	label_stats.text = "Port stats:\nLevel: %s\nCrew: %s/%s\nHitpoints: %.1f/%.1f\nCannons: %s" % [level, crew, max_crew, hit_points, max_hit_points, cannon_layout_port.cannons_unlocked]

	var services = VBoxContainer.new()

	var services_label := Label.new()
	services_label.text = "Services"
	services_label.theme_type_variation = "HeaderLarge"


	if allegiance.faction == player_ship.real_faction:
		root.add_child(services)
	else:
		var label = Label.new()
		label.text = "You are not allied with this port\nand cannot use its services."
		root.add_child(label)

	services.add_child(services_label)
	# create upgrades
	
	if cannon_layout_port.cannons_unlocked < 4:
		create_upgrade_ui(services, "PORT", "Install cannon", 200, func(): cannon_layout_port.add_cannon())
	if not market_opened:
		create_upgrade_ui(services, "PORT", "Open market", 500, func(): open_market())
	
	
	if crew > 0:
		create_upgrade_ui(services, "CREW", "Hire crew", 100, func():
			crew -= 1
			ps.gain_crew(1)
		)
		create_label_ui(services, "CREW", str(crew) + " left")
	if crew_to_recruit > 0:
		create_upgrade_ui(services, "CREW", "Recruit crew", 0, func():
			var crew_missing = ps.max_crew - ps.crew
			var amount = min(crew_missing, crew_to_recruit)

			ps.gain_crew(amount)
			crew_to_recruit -= amount
		)
		create_label_ui(services, "CREW", str(crew_to_recruit) + " left")
	
	if ps.top_speed < Constants.MAX_SPEED: create_upgrade_ui(services, "SHIP", "Upgrade sails %.1f + 1.0" % [ps.top_speed], 2000, func(): ps.top_speed += 1.0)
	if ps.agility < Constants.MAX_AGILITY: create_upgrade_ui(services, "SHIP", "Upgrade rudder %.1f + 1.0" % [ps.agility], 2000, func(): ps.agility += 1.0)
	if ps.max_hit_points < Constants.MAX_HP: create_upgrade_ui(services, "SHIP", "Upgrade hull %.1f + 1.0" % [ps.max_hit_points], 2000, func(): ps.max_hit_points += 10.0)
	
	#create_upgrade_ui(services, "COMBAT", "Upgrade guns", 500, func(): ps.upgrade_guns())
	#create_upgrade_ui(services, "COMBAT", "Upgrade attack", 500, func(): ps.attack += 1.0)
	#create_upgrade_ui(services, "COMBAT", "Upgrade defense", 500, func(): ps.defense += 1.0)

func _on_inventory_changed(_inventory: Inventory):
	if inventory_panel:
		inventory_panel.update_inventory_ui(
			_inventory,
			buy_item,
			func(_index): pass ,
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

func get_combat_readiness() -> float:
	# Simple heuristic: average of health and crew percentage
	var health_percent = hit_points / max_hit_points
	var crew_percent = float(crew) / float(max_crew)
	var has_cannons = cannon_layout_port.cannons_unlocked > 0
	if not has_cannons:
		return 0.0 # Not combat ready without cannons or cannonballs
	return (health_percent + crew_percent) / 2.0


func create_label_ui(root: Control, category: String, content):
	var category_vbox: VBoxContainer = root.get_node_or_null(category)
	var label = Label.new()
	label.text = content
	category_vbox.add_child(label)

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

	var can_buy = player_ship.gold >= upgrade_cost
	#new_upgrade_button.visible = can_buy
	new_upgrade_button.disabled = not can_buy
	
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
