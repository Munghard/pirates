extends Control
class_name HUD

@export var ship_panel_target: ShipPanel
@export var ship_panel_player: ShipPanel

@export var inventory_panel: Control

@export var time_panel: Control
@export var depth_panel: Control
@export var influence_panel: Control

@export var wind_control: Control


@export var button_dock: Button
@export var boarding_button: Button

@export var notification_label: Label
@export var fps_label: Label

@export var map: Map
@export var game_menu: Control

@export var equipment_panel: Control

var notification_queue: Array[String] = []
var showing_notifications = false

var label_stacks := {}


var buy_panel := preload("res://UI/buy_panel.tscn")
var prompt := preload("res://UI/prompt.tscn")

@onready var gameManager: GameManager = get_node("/root/GameManager")

func _ready():
	boarding_button.visible = false
	inventory_panel.visible = false
	game_menu.visible = false

func update_influence_panel():
	var player_faction = gameManager.player_ship.faction
	var influence = gameManager.territory.get_faction_influence(player_faction)
	var label_m: Label = influence_panel.get_node("MarginContainer/VBoxContainer/Label_m")
	var label_h: Label = influence_panel.get_node("MarginContainer/VBoxContainer/Label_h")
	label_m.text = "Influence: %.1f%%" % [influence * 100]
	label_h.text = FactionsData.FACTION_NAMES.get(player_faction)

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
	connect_ports()


func _on_time_changed(time: float):
	var label_time: Label = time_panel.get_node("MarginContainer/VBoxContainer/Label_time")
	var day = gameManager.world.time.day_count
	var _time = gameManager.world.time.get_time_string()
	label_time.text = " Day %d" % [day] + " \n " + _time

func _on_boarding_target_changed(ship: Ship):
	boarding_button.visible = ship != null and ship.can_be_boarded()

func toggle_map():
	map.visible = !map.visible

func toggle_equipment_panel():
	equipment_panel.visible = !equipment_panel.visible

func select_ship(ship: Ship):
	gameManager.select_ship(ship)
	gameManager.camerarig.secondary_target = gameManager.selected_ship
	ship_panel_target.set_ship(gameManager.selected_ship)
	ship_panel_target.update_ship_panel(gameManager.selected_ship)

func ddd_label(text: String, _position: Vector3, _color: Color = Color.WHITE):
	var key = _position.snapped(Vector3(0.5, 0.5, 0.5)) # group nearby positions

	if not label_stacks.has(key):
		label_stacks[key] = 0

	var count = label_stacks[key]
	label_stacks[key] += 1

	var label3d = Label3D.new()
	gameManager.world.add_child(label3d)

	var offset = Vector3(
		0,
		count * 2.5,
		0
	)

	label3d.text = text
	label3d.font_size = 160
	label3d.global_position = _position + offset
	label3d.billboard = true
	label3d.no_depth_test = true
	label3d.alpha_cut = true
	label3d.modulate = _color

	get_tree().create_tween().tween_property(
		label3d,
		"global_position",
		label3d.global_position + Vector3.UP * 10.0,
		5.0
	)

	await get_tree().create_timer(5.0).timeout

	label_stacks[key] -= 1
	if label_stacks[key] <= 0:
		label_stacks.erase(key)

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

var depth_check_timer := 0.0

func _process(_delta):
	var fps = Engine.get_frames_per_second()
	fps_label.text = "Fps:%s" % [fps]
	if gameManager.selected_ship:
		ship_panel_target.update_ship_panel(gameManager.selected_ship)
	
	ship_panel_player.update_ship_panel(gameManager.player_ship)
	depth_check_timer += _delta
	if depth_check_timer >= 1.0:
		depth_check_timer = 0.0
		update_depth_label()
	
func update_depth_label():
	var depth_label: Label = depth_panel.get_node("MarginContainer/VBoxContainer/Label_depth")
	var player_pos = gameManager.player_ship.global_position
	var depth = gameManager.world.terrain.get_height_world(player_pos.x, player_pos.z)
	depth_label.text = "%.1f m" % [abs(depth)]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#print("clicking at non ui");
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
			if gameManager.selected_ship != ship and gameManager.player_ship != ship:
				select_ship(ship)
				ship_panel_target.folded = false
			if ship == gameManager.player_ship:
				toggle_player_inventory_panel()

		else:
			select_ship(null)


func set_player_inventory_panel_visible(value: bool):
	inventory_panel.visible = value

func toggle_player_inventory_panel():
	set_player_inventory_panel_visible(!inventory_panel.visible)

# ================================================================================================================
# PORT
# ================================================================================================================
func connect_ports():
	gameManager.player_ship.dockable_port_changed.connect(show_dock_button)
	gameManager.player_ship.docked_changed.connect(set_dock_button_text)


func set_dock_button_text(port: Port):
	if port:
		button_dock.text = "Depart"
	else:
		button_dock.text = "Dock"

func show_dock_button(port: Port):
	button_dock.visible = port != null
	

func _on_button_dock_pressed() -> void:
	var ports = gameManager.world.ports
	for port: Port in ports:
		if port.player_ship:
			if port.docked:
				port.depart()
			else:
				port.dock()


func _on_button_2_pressed() -> void:
	gameManager.port.depart()

# ================================================================================================================
#  BOARDING
# ================================================================================================================

func _on_board_button_pressed() -> void:
	gameManager.player_ship.board_ship(gameManager.player_ship.boarding_target)

# ================================================================================================================
#  TIME
# ================================================================================================================

func _on_button_pass_time_pressed() -> void:
	var slider = time_panel.get_node("MarginContainer/VBoxContainer/HSlider") as HSlider
	gameManager.world.pass_time(slider.value)


func _on_button_equipment_pressed() -> void:
	toggle_equipment_panel()


func _on_button_cargo_pressed() -> void:
	toggle_player_inventory_panel()
