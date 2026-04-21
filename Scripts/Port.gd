extends Area3D

class_name Port

@export var port_ui: PackedScene
var player_ship: PlayerShip
var docked := false
var ui: Control

func _process(delta):
	if docked and player_ship:
		var current = player_ship.global_basis
		var target = global_basis
		player_ship.global_basis = current.slerp(target, delta)
		player_ship.yaw_deg = global_rotation_degrees.y
		if player_ship.hit_points < player_ship.max_hit_points:
			player_ship.hit_points += delta * 10.0
			player_ship.hit_points = min(player_ship.hit_points, player_ship.max_hit_points)


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerShip:
		dock(body)


func dock(body: PlayerShip):
	player_ship = body
	player_ship.target_speed = 0
	docked = true
	entered_port()


func _on_body_exited(body: Node3D) -> void:
	if body is PlayerShip:
		docked = false
		player_ship = null


func depart():
	if ui:
		ui.queue_free()
	docked = false

	if player_ship:
		player_ship.linear_velocity = player_ship.global_basis.z * player_ship.mass * 200.0

	player_ship = null
	

func entered_port():
	# delete existing ui if any
	if ui:
		ui.queue_free()
	# instantiate port ui
	ui = port_ui.instantiate()
	# add to hud
	player_ship.gameManager.hud.add_child(ui)
	# connect depart button
	ui.get_node("MarginContainer/VBoxContainer/DepartButton").pressed.connect(func(): depart())
	var ps = player_ship

	# create upgrades
	create_upgrade_ui(ui, "SHIP", "Upgrade sails", 200, func(): ps.top_speed += 1.0)
	create_upgrade_ui(ui, "SHIP", "Upgrade rudder", 200, func(): ps.agility += 1.0)
	create_upgrade_ui(ui, "CREW", "Hire crew", 100, func(): ps.gain_crew(1))
	create_upgrade_ui(ui, "CREW", "Recruit crew", 0, func(): ps.gain_crew(1))
	create_upgrade_ui(ui, "COMBAT", "Upgrade guns", 500, func(): ps.upgrade_guns())
	create_upgrade_ui(ui, "COMBAT", "Upgrade attack", 500, func(): ps.attack += 1.0)
	create_upgrade_ui(ui, "COMBAT", "Upgrade defense", 500, func(): ps.defense += 1.0)


func create_upgrade_ui(_ui: Control, category: String, upgrade_name: String, upgrade_cost: int, function: Callable):
	var root = _ui.get_node("MarginContainer/VBoxContainer")

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
