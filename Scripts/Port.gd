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
	if ui:
		ui.queue_free()
	ui = port_ui.instantiate()
	player_ship.gameManager.hud.add_child(ui)
	ui.connect("hire_crew_pressed", Callable(self , "hire_crew"))
	ui.connect("depart_pressed", Callable(self , "depart"))


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