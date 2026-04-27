extends Control
class_name HUD

@export var ship_panel_target: ShipPanel
@export var ship_panel_player: ShipPanel

@export var equipment_panel: Control

@export var time_panel: Control

@export var wind_control: Control

@export var minimap: Control
@export var minimap_terrain_texture: TextureRect
@export var minimap_scale_slider: VSlider
@export var blip_scene: PackedScene
var minimap_scale = 20.0

@export var boarding_button: Button

@export var notification_label: Label
var notification_queue: Array[String] = []
var showing_notifications = false

var selected_ship: Ship

@onready var gameManager: GameManager = get_node("/root/GameManager")

func _ready():
	boarding_button.visible = false
	equipment_panel.visible = false

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
	minimap_scale_slider.value = minimap_scale


	#create_minimap_terrain_texture()

func _on_time_changed(time: float):
	var label_time: Label = time_panel.get_node("MarginContainer/VBoxContainer/Label_time")
	label_time.text = gameManager.world.time.get_time_string()

func _on_boarding_target_changed(ship: Ship):
	boarding_button.visible = ship != null and ship.can_be_boarded()

# ================================================================================================================
# MINIMAP 
# ================================================================================================================
func create_minimap_terrain_texture():
	var src: Texture2D = gameManager.world.terrain.heightmap
	var img: Image = src.get_image()

	var _size = img.get_size()
	var out := Image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)

	for x in range(_size.x):
		for y in range(_size.y):
			var h = img.get_pixel(x, y).r
			h = smoothstep(0.3, 0.7, h)
				# threshold (tweak this)
			if h > 0.3:
				out.set_pixel(x, y, Color(0.5, 1, 0.5, 0.3))
			else:
				out.set_pixel(x, y, Color(1, 1, 1, 0))

	minimap_terrain_texture.texture = ImageTexture.create_from_image(out)

func set_terrain_texture_transforms():
	if not minimap_terrain_texture.texture:
		return
	var terrain = gameManager.world.terrain
	var world_size = Vector2(
		terrain.world_size.x * terrain.tile_size,
		terrain.world_size.y * terrain.tile_size
	)

	var player_pos = gameManager.player_ship.global_position

	var player_uv = Vector2(
		player_pos.x / world_size.x,
		player_pos.z / world_size.y
	)
	var tex_size := minimap_terrain_texture.texture.get_size()
	var ui_size := minimap.size # should be 128x128
	var base_scale := ui_size / tex_size
	var _scale = base_scale * minimap_scale
	

	minimap_terrain_texture.pivot_offset = Vector2.ZERO # minimap_terrain_texture.size * 0.5
	minimap_terrain_texture.scale = _scale
	
	var scaled_tex_size = tex_size * scale

	minimap_terrain_texture.position = minimap.size * 0.5 - (player_uv * scaled_tex_size)

func update_minimap():
	for child in minimap.get_children():
		child.queue_free()
	
	add_blip_to_minimap(gameManager.player_ship.global_position, Color(1, 1, 1), 1.5)
	
	set_terrain_texture_transforms()

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

func add_blip_to_minimap(pos: Vector3, color: Color, _scale: float):
	var blip: TextureRect = blip_scene.instantiate()
	blip.modulate = color
	minimap.add_child(blip)

	var center_pos = gameManager.camerarig.global_position

	var relative = Vector2(
		pos.x - center_pos.x,
		pos.z - center_pos.z
	)

	# scale world → minimap space
	var p = relative * minimap_scale

	blip.scale = Vector2.ONE * _scale
	blip.position = minimap.size * 0.5 + -p - blip.size * 0.5

# ================================================================================================================
# MINIMAP 
# ================================================================================================================


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
	gameManager.player_ship.board_ship(gameManager.player_ship.boarding_target)

func _on_button_pass_time_pressed() -> void:
	gameManager.world.pass_time()
