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

@onready var gameManager: GameManager = get_node("/root/World")
var hovered_ship: Ship

func _ready() -> void:
	gameManager.wind.connect("wind_changed", Callable(self , "_on_update_wind"))
	#set pivot for wind direction gauge

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

func _on_update_wind(dir: Vector3):
	wind_label.text = "Speed: %.2f\nDegrees: %.2f\nEnabled: %s\nNext change: %.2f" % [dir.length(), rad_to_deg(atan2(dir.z, dir.x)), str(gameManager.wind.timer_enable), gameManager.wind.next_change - gameManager.wind.timer]
	create_tween().tween_property(wind_control, "rotation_degrees", rad_to_deg(atan2(dir.z, dir.x) + PI / 2), 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT) # ease in, out, or both

func update_label(ship: Ship):
	ship_label_h.text = "%s" % ship.ship_name
	ship_label.text = "Hp: %.2f/%.2f\nTarg.Spd: %.2f/%.2f\nAct.Spd: %.2f\nHeading: %.2f\nAgility: %.2f\nAttack: %.2f\nDefense: %.2f\nGold: %.2f" % [ship.hit_points, ship.max_hit_points, ship.target_speed, ship.top_speed, ship.actual_speed, rad_to_deg(ship.rotation.y), ship.agility, ship.attack, ship.defense, ship.gold]
	ship_pb.max_value = ship.max_hit_points
	ship_pb.value = ship.hit_points

func _process(_delta):
	if not gameManager:
		return
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
		if hovered_ship != ship:
			hovered_ship = ship
			update_label(hovered_ship)
	if hovered_ship:
		update_label(hovered_ship)


func _on_button_pressed() -> void:
	gameManager.wind.set_direction(Vector3.ZERO)
	gameManager.wind.set_enable_wind(!gameManager.wind.timer_enable)
