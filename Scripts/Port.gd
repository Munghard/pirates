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
		player_ship.linear_velocity = player_ship.global_basis.z * 20

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
	
	# create upgrades
	create_upgrade_ui(ui, "TESTI", "Testicle", 500, func(): print("TESTING!"))
	create_upgrade_ui(ui, "CREW", "Hire crew", 100, func(): hire_crew())
	create_upgrade_ui(ui, "GUNS", "Upgrade guns", 500, func(): upgrade_guns())


func create_upgrade_ui(_ui: Control, category: String, upgrade_name: String, upgrade_cost: int, function: Callable):
	var new_upgrade_vbox = VBoxContainer.new()
	var new_upgrade_hbox = HBoxContainer.new()
	var new_category_label = Label.new()
	var new_upgrade_label = Label.new()
	var new_upgrade_price_label = Label.new()
	var new_upgrade_button = Button.new()
	new_upgrade_button.text = "Buy"
	new_upgrade_button.pressed.connect(func():
		if not player_ship:
			return
		if player_ship.gold >= upgrade_cost:
			player_ship.gold -= upgrade_cost
			function.call()
		else:
			print("Not enough gold for upgrade: ", upgrade_name)
	)
	new_upgrade_label.text = upgrade_name
	new_upgrade_price_label.text = str(upgrade_cost) + "g"
	new_category_label.text = category
	new_category_label.theme_type_variation = "HeaderSmall"
	new_upgrade_vbox.add_child(new_category_label)
	new_upgrade_hbox.add_child(new_upgrade_label)
	new_upgrade_hbox.add_child(new_upgrade_price_label)
	new_upgrade_hbox.add_child(new_upgrade_button)
	new_upgrade_vbox.add_child(new_upgrade_hbox)
	_ui.get_node("MarginContainer/VBoxContainer").add_child(new_upgrade_vbox)

func hire_crew():
	if not player_ship:
		return
	if player_ship.crew >= player_ship.max_crew:
		return
	var crew_cost := 100
	if player_ship.gold >= crew_cost:
		player_ship.gold -= crew_cost
		player_ship.gain_crew(1)

func upgrade_guns():
	if not player_ship:
		return
	var upgrade_cost := 500
	if player_ship.gold >= upgrade_cost:
		player_ship.gold -= upgrade_cost
		player_ship.upgrade_guns()
