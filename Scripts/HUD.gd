extends Control
class_name HUD

@export var ship_panel_target: ShipPanel
@export var ship_panel_player: ShipPanel

@export var inventory_panel: Control

@export var time_panel: Control

@export var wind_control: Control


@export var boarding_button: Button

@export var notification_label: Label
var notification_queue: Array[String] = []
var showing_notifications = false

var selected_ship: Ship

@onready var gameManager: GameManager = get_node("/root/GameManager")

func _ready():
	boarding_button.visible = false
	inventory_panel.visible = false

func init_hud() -> void:
	# update wind direction gauge
	gameManager.world.wind.connect("wind_changed", Callable(self , "_on_update_wind"))
	#init notification label as 0 alpha
	notification_label.modulate.a = 0
	ship_panel_target.update_ship_panel(null)
	gameManager.player_ship.connect("boarding_target_changed", Callable(self , "_on_boarding_target_changed"))
	gameManager.world.time.connect("time_changed", Callable(self , "_on_time_changed"))
	ship_panel_player.set_ship(gameManager.player_ship)
	ship_panel_target.set_ship(null)
	ship_panel_player.fold()
	ship_panel_target.fold()

	#create_minimap_terrain_texture()

func _on_time_changed(time: float):
	var label_time: Label = time_panel.get_node("MarginContainer/VBoxContainer/Label_time")
	label_time.text = gameManager.world.time.get_time_string()

func _on_boarding_target_changed(ship: Ship):
	boarding_button.visible = ship != null and ship.can_be_boarded()


func select_ship(ship: Ship):
	selected_ship = ship
	gameManager.camerarig.secondary_target = selected_ship
	ship_panel_target.set_ship(selected_ship)
	ship_panel_target.update_ship_panel(selected_ship)


func ddd_label(text: String, _position: Vector3, _color: Color = Color.WHITE):
	var label3d = Label3D.new()
	get_tree().current_scene.add_child(label3d)
	label3d.text = text
	label3d.font_size = 160
	# label3d.no_depth_test = true
	label3d.global_position = _position
	label3d.billboard = true
	label3d.no_depth_test = true
	label3d.alpha_cut = true
	label3d.modulate = _color

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
	wind_control.rotation = atan2(wind.direction.x, -wind.direction.z)


func _process(_delta):
	if selected_ship:
		ship_panel_target.update_ship_panel(selected_ship)

	
	ship_panel_player.update_ship_panel(gameManager.player_ship)
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("clicking at non ui");
		var mouse_pos = get_viewport().get_mouse_position()

		var from = gameManager.camera.project_ray_origin(mouse_pos)
		var to = from + gameManager.camera.project_ray_normal(mouse_pos) * 1000

		var space = gameManager.camera.get_world_3d().direct_space_state
		var result = space.intersect_ray(
			PhysicsRayQueryParameters3D.create(from, to)
		)

		if result:
			if result.collider is not Ship:
				select_ship(null)
				ship_panel_target.folded = true
				return
			var ship = result.collider
			if selected_ship != ship and gameManager.player_ship != ship:
				select_ship(ship)
				ship_panel_target.folded = false
			if ship == gameManager.player_ship:
				toggle_player_ship_panel()

		else:
			select_ship(null)


func toggle_player_ship_panel():
	inventory_panel.visible = !inventory_panel.visible

# ================================================================================================================
# PORT
# ================================================================================================================

func _on_button_2_pressed() -> void:
	gameManager.port.depart()

func _on_board_button_pressed() -> void:
	gameManager.player_ship.board_ship(gameManager.player_ship.boarding_target)

func _on_button_pass_time_pressed() -> void:
	gameManager.world.pass_time()
