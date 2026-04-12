extends Control
class_name HUD

@export var ship_label_h: Label
@export var ship_label: Label
@export var ship_pb: ProgressBar
@export var wind_label: Label
@export var wind_control: Control

@export var notification_label: Label
var notification_queue: Array[String] = []
var showing_notifications = false

var canon_mc: MarginContainer

var selected_ship: Ship

@onready var gameManager: GameManager = get_node("/root/GameManager")

func init_hud() -> void:
	# update wind direction gauge
	gameManager.wind.connect("wind_changed", Callable(self , "_on_update_wind"))
	#init notification label as 0 alpha
	notification_label.modulate.a = 0

func select_ship(ship: Ship):
	selected_ship = ship
	create_canon_ui(ship)

func create_canon_ui(ship: Ship):
	if canon_mc:
		canon_mc.queue_free()
	canon_mc = MarginContainer.new()
	var vb = VBoxContainer.new()
	add_child(canon_mc)
	canon_mc.add_child(vb)
	var lh = Label.new()
	lh.text = "Cannons"
	vb.add_child(lh)
	var lp = Label.new()
	lp.text = "Port"
	vb.add_child(lp)
	for canon in ship.canons_port:
		var pb = ProgressBar.new()
		pb.max_value = canon.fire_rate
		pb.value = pb.max_value - canon.fire_timer
		vb.add_child(pb)
		canon.connect("_fire_timer_changed", Callable(self , "update_pb").bind(pb))

	var ls = Label.new()
	ls.text = "Starboard"
	vb.add_child(ls)
	for canon in ship.canons_starboard:
		var pb = ProgressBar.new()
		pb.max_value = canon.fire_rate
		pb.value = pb.max_value - canon.fire_timer
		vb.add_child(pb)
		canon.connect("_fire_timer_changed", Callable(self , "update_pb").bind(pb))
	
func update_pb(value: float, pb):
	if pb:
		pb.value = pb.max_value - value

func ddd_label(text: String, _position: Vector3):
	var label3d = Label3D.new()
	get_tree().current_scene.add_child(label3d)
	label3d.text = text
	label3d.font_size = 160
	label3d.no_depth_test = true
	label3d.global_position = _position
	label3d.billboard = true
	get_tree().create_tween().tween_property(label3d, "global_position", label3d.global_position + Vector3.UP * 10.0, 5.0)

	await get_tree().create_timer(5.0).timeout
	label3d.queue_free()

func new_notification(text: String):
	notification_queue.append(text)
	if not showing_notifications:
		showing_notifications = true
		_show_notifications()

func _show_notifications() -> void:
	while notification_queue.size() > 0:
		var value = notification_queue.pop_front()
		notification_label.text = value
		notification_label.modulate.a = 1
		await get_tree().create_timer(3.0).timeout
		notification_label.modulate.a = 0
		await get_tree().create_timer(0.5).timeout # optional fade-out time
	showing_notifications = false

func _on_update_wind(wind: Wind):
	wind_label.text = "Speed: %.2f\nDegrees: %.2f\nEnabled: %s\nNext change: %.2f" % [wind.strength, rad_to_deg(atan2(wind.direction.z, wind.direction.x)), str(wind.timer_enable), wind.next_change - wind.timer]
	create_tween().tween_property(wind_control, "rotation_degrees", rad_to_deg(atan2(wind.direction.z, wind.direction.x) + PI / 2), 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT) # ease in, out, or both

func update_label(ship: Ship):
	ship_label_h.text = "%s" % ship.ship_name
	var ai_text = ""
	if ship is EnemyShip:
		ai_text = "State: %s\n" % (ship as EnemyShip).AIStateNames[(ship as EnemyShip).ai_state]
		ai_text += "SubState: %s\n" % (ship as EnemyShip).CombatStateNames[(ship as EnemyShip).combat_state]
	var ship_text = "Hp: %.2f/%.2f\nTarg.Spd: %.2f/%.2f\nAct.Spd: %.2f\nHeading: %.2f\nAgility: %.2f\nAttack: %.2f\nDefense: %.2f\nGold: %.2f\nYaw: %.2f\nY pos: %.2f" % [ship.hit_points, ship.max_hit_points, ship.target_speed, ship.top_speed, ship.actual_speed, rad_to_deg(ship.rotation.y), ship.agility, ship.attack, ship.defense, ship.gold, ship.yaw_deg, ship.global_position.y]
	ship_label.text = ai_text + ship_text
	ship_pb.max_value = ship.max_hit_points
	ship_pb.value = ship.hit_points

func _process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_viewport().get_mouse_position()

		var from = gameManager.camera.project_ray_origin(mouse_pos)
		var to = from + gameManager.camera.project_ray_normal(mouse_pos) * 1000

		var space = gameManager.camera.get_world_3d().direct_space_state
		var result = space.intersect_ray(
			PhysicsRayQueryParameters3D.create(from, to)
		)

		if result:
			if result.collider is not Ship:
				return
			var ship = result.collider
			if selected_ship != ship:
				select_ship(ship)
				update_label(selected_ship)
	if selected_ship:
		update_label(selected_ship)


func _on_button_pressed() -> void:
	gameManager.wind.set_direction(Vector3.ZERO)
	gameManager.wind.set_enable_wind(!gameManager.wind.timer_enable)
