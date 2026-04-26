extends Control
class_name HUD

@export var ship_panel_target: FoldableContainer
@export var ship_panel_player: FoldableContainer

@export var equipment_panel: Control

@export var time_panel: Control

@export var wind_control: Control

@export var minimap: Control
@export var minimap_scale_slider: VSlider
@export var blip_scene: PackedScene
var minimap_scale = 20.0

@export var boarding_button: Button

@export var notification_label: Label
var notification_queue: Array[String] = []
var showing_notifications = false

var canon_mc: MarginContainer
var canon_fc: FoldableContainer

var selected_ship: Ship

@onready var gameManager: GameManager = get_node("/root/GameManager")

func _ready():
	boarding_button.visible = false
	equipment_panel.visible = false

func init_hud() -> void:
	# update wind direction gauge
	gameManager.wind.connect("wind_changed", Callable(self , "_on_update_wind"))
	#init notification label as 0 alpha
	notification_label.modulate.a = 0
	update_ship_panel(null, ship_panel_target)
	gameManager.player_ship.connect("boarding_target_changed", Callable(self , "_on_boarding_target_changed"))
	gameManager.time.connect("time_changed", Callable(self , "_on_time_changed"))
	ship_panel_player.fold()
	ship_panel_target.fold()
	minimap_scale_slider.value = minimap_scale

func _on_time_changed(time: float):
	var label_time: Label = time_panel.get_node("MarginContainer/VBoxContainer/Label_time")
	label_time.text = gameManager.time.get_time_string()

func _on_boarding_target_changed(ship: Ship):
	boarding_button.visible = ship != null and ship.can_be_boarded()

# ================================================================================================================
# MINIMAP 
# ================================================================================================================
func update_minimap():
	for child in minimap.get_children():
		child.queue_free()
	
	add_blip_to_minimap(gameManager.player_ship.global_position, Color(1, 1, 1), 1.5)

	for ship: Ship in get_tree().get_nodes_in_group("Ships"):
		if ship == gameManager.player_ship:
			continue
		var color = FactionsData.get_faction_color(ship.faction)
		add_blip_to_minimap(ship.global_position, color, 1)
	
	for floater: Node3D in get_tree().get_nodes_in_group("Floaters"):
		var color = Color(1, 1, 1, 0.5)
		add_blip_to_minimap(floater.global_position, color, 0.5)
	
	for port: Node3D in get_tree().get_nodes_in_group("Ports"):
		var color = Color(0, 1, 0, 0.5)
		add_blip_to_minimap(port.global_position, color, 1.5)
		

func add_blip_to_minimap(_position: Vector3, color: Color, _scale: float):
	var _blip: TextureRect = blip_scene.instantiate()
	_blip.modulate = color
	_blip.scale = Vector2.ONE * _scale
	minimap.add_child(_blip)
	var pos = world_to_minimap(_position)
	pos = Vector2(pos.x * -1 + minimap.size.x, pos.y * -1 + minimap.size.y) # flip y-axis
	pos = pos - _blip.size / 2
	_blip.position = pos

func world_to_minimap(_position: Vector3) -> Vector2:
	var player_pos = gameManager.player_ship.global_position
	var relative_pos = _position - player_pos
	return Vector2(relative_pos.x, relative_pos.z) * minimap_scale + minimap.size / 2

# ================================================================================================================
# MINIMAP 
# ================================================================================================================


func select_ship(ship: Ship):
	selected_ship = ship
	gameManager.camerarig.secondary_target = selected_ship
	update_ship_panel(selected_ship, ship_panel_target)

func create_canon_ui(ship: Ship, _ship_panel: Control):
	if canon_fc:
		canon_fc.queue_free()
	if ship == null:
		return
	canon_fc = FoldableContainer.new()
	canon_mc = MarginContainer.new()
	var vb = VBoxContainer.new()
	canon_fc.add_child(canon_mc)
	_ship_panel.get_parent().add_child(canon_fc)
	canon_mc.add_child(vb)
	var lh = Label.new()
	lh.text = "Cannons"
	vb.add_child(lh)
	
	create_canon_pb("Port", vb, ship.canons_layout.canons_port)
	var port_button = Button.new()
	vb.add_child(port_button)
	port_button.text = "Fire port"
	port_button.pressed.connect(ship.shoot_port)
	create_canon_pb("Starboard", vb, ship.canons_layout.canons_starboard)
	create_canon_pb("Bow", vb, ship.canons_layout.canons_bow)

func create_canon_pb(side_name: String, vb: VBoxContainer, canons: Array[Canon]):
	var ls = Label.new()
	ls.text = side_name
	vb.add_child(ls)
	for canon in canons:
		var pb = ProgressBar.new()
		pb.max_value = canon.fire_rate
		pb.value = pb.max_value - canon.fire_timer
		vb.add_child(pb)
		if not canon.is_connected("_fire_timer_changed", Callable(self , "update_pb").bind(pb)):
			canon.connect("_fire_timer_changed", Callable(self , "update_pb").bind(pb))
	
func update_pb(value: float, pb):
	if pb:
		pb.value = pb.max_value - value

func ddd_label(text: String, _position: Vector3):
	var label3d = Label3D.new()
	get_tree().current_scene.add_child(label3d)
	label3d.text = text
	label3d.font_size = 160
	# label3d.no_depth_test = true
	label3d.global_position = _position
	label3d.billboard = true
	label3d.no_depth_test = true
	label3d.alpha_cut = true

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

func update_ship_panel(ship: Ship, _ship_panel: FoldableContainer):
	var ship_label_h := _ship_panel.get_node("MarginContainer/VBoxContainer/Label_h")
	var ship_label_f: Label = _ship_panel.get_node("MarginContainer/VBoxContainer/Label_f")
	var ship_label := _ship_panel.get_node("MarginContainer/VBoxContainer/Label")
	var ship_pb: ProgressBar = _ship_panel.get_node("MarginContainer/VBoxContainer/pb_health")
	var ship_crew_pb: ProgressBar = _ship_panel.get_node("MarginContainer/VBoxContainer/pb_crew")
	var canons_button: Button = _ship_panel.get_node("MarginContainer/VBoxContainer/canons_button")

	var callable = Callable(create_canon_ui).bind(ship, _ship_panel)
	if not canons_button.pressed.is_connected(callable):
		canons_button.pressed.connect(callable)

	if ship == null:
		return
	
	var ship_name = ""
	
	ship_name = ship.ship_name
	ship_label_h.text = "%s" % ship_name
	ship_label_f.text = "%s" % FactionsData.FACTION_NAMES[ship.faction]
	
	var color = FactionsData.get_faction_color(ship.faction)
	ship_label_f.self_modulate = color

	var ai_text = ""
	if ship is EnemyShip:
		ai_text = "State: %s" % (ship as EnemyShip).AIStateNames[(ship as EnemyShip).ai_state]
		if (ship.ai_state == EnemyShip.AIState.COMBAT):
			ai_text += "\nSubState: %s" % (ship as EnemyShip).CombatStateNames[(ship as EnemyShip).combat_state]
		ai_text += "\nIn combat: %.s" % [str(ship.in_combat)]
		if ship.attacker: ai_text += "\nTarget: %.s" % [str(ship.attacker.ship_name)]
	
	var ship_text = ""
	if ship:
		ship_text += "\nCrew: %s/%s" % [ship.crew, ship.max_crew]
		ship_text += "\nHp: %.2f/%.2f" % [ship.hit_points, ship.max_hit_points]
		# debug info
		# ship_text += "\nTarg.Spd: %.2f/%.2f" % [ship.target_speed, ship.top_speed]
		# ship_text += "\nAct.Spd: %.2f" % [ship.actual_speed]
		# ship_text += "\nHeading: %.2f" % [rad_to_deg(ship.rotation.y)]
		ship_text += "\nAgility: %.2f" % [ship.agility]
		ship_text += "\nAttack: %.2f" % [ship.attack]
		ship_text += "\nDefense: %.2f" % [ship.defense]
		ship_text += "\nGold: %.2f" % [ship.gold]
		ship_text += "\nSupplies: %.2f" % [ship.supplies]
		ship_text += "\nGuns: %.2f" % [ship.guns]
	
		
		ship_crew_pb.max_value = ship.max_crew
		ship_crew_pb.value = ship.crew
		
		ship_pb.max_value = ship.max_hit_points
		ship_pb.value = ship.hit_points

	ship_label.text = ai_text + ship_text
	

func _process(_delta):
	if selected_ship:
		update_ship_panel(selected_ship, ship_panel_target)

	
	update_ship_panel(gameManager.player_ship, ship_panel_player)
	
	if Time.get_ticks_msec() % 1000 < 50: # update minimap every second
		update_minimap()


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
				open_player_ship_panel()

		else:
			select_ship(null)


func open_player_ship_panel():
	equipment_panel.visible = !equipment_panel.visible

# ================================================================================================================
# PORT
# ================================================================================================================

func _on_button_2_pressed() -> void:
	gameManager.port.depart()

# ================================================================================================================
# MINIMAP
# ================================================================================================================


func _on_v_slider_value_changed(value: float) -> void:
	minimap_scale = value / 100.0
	update_minimap()


func _on_board_button_pressed() -> void:
	if gameManager.player_ship.boarded_ship:
		gameManager.player_ship.unboard_ship()
	elif gameManager.player_ship.boarding_target.can_be_boarded():
		gameManager.player_ship.board_ship()
	
	if gameManager.player_ship.boarded_ship != null:
		boarding_button.text = "Unboard ship"
	else:
		boarding_button.text = "Board ship"


func _on_button_pass_time_pressed() -> void:
	gameManager.pass_time()
