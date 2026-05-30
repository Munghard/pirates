extends Control

class_name Map
@onready var gameManager: GameManager = get_node("/root/GameManager")

@export_category("Nodes")
@onready var map_control: Control = $MarginContainer/HBoxContainer/Control
@onready var map: TextureRect = $MarginContainer/HBoxContainer/Control/TextureRect
@onready var map_terrain: TextureRect = $MarginContainer/HBoxContainer/Control/TextureRect2
@onready var territory_draw: Control = $MarginContainer/HBoxContainer/Control/Territory
@onready var heatmap_draw: Control = $MarginContainer/HBoxContainer/Control/Heatmap
@onready var markers: Control = $MarginContainer/HBoxContainer/Control/Markers
@onready var fog_of_war: Fog_Of_War = $MarginContainer/HBoxContainer/Control/Fog_of_war

@onready var heatmap_checkbox: CheckBox = $MarginContainer/HBoxContainer/VBoxContainer/CheckBox
@onready var fow_checkbox: CheckBox = $MarginContainer/HBoxContainer/VBoxContainer/CheckBox2
@onready var markers_checkbox: CheckBox = $MarginContainer/HBoxContainer/VBoxContainer/CheckBox3
@onready var territory_checkbox: CheckBox = $MarginContainer/HBoxContainer/VBoxContainer/CheckBox4
@onready var poi_checkbox: CheckBox = $MarginContainer/HBoxContainer/VBoxContainer/CheckBox5
@onready var ports_checkbox: CheckBox = $MarginContainer/HBoxContainer/VBoxContainer/CheckBox6


@export_category("Scenes")
@onready var marker_scene: PackedScene = preload("res://UI/map_marker.tscn")
@onready var blip_scene: PackedScene = preload("res://UI/blip.tscn")
@onready var blip_a_scene: PackedScene = preload("res://UI/blip_a.tscn")

var map_scale = 1.0
var player_blip: Control

var draw_ports := true
var draw_pois := true

func _ready():
	await get_tree().process_frame
	map_terrain.texture = create_map_terrain_texture()
	
	update_map(gameManager.player_ship.faction, blip_scene)
	
	var ports = gameManager.world.ports # this might not update after load
	
	for port in ports:
		port.port_faction_changed.connect(func(_faction): update_map(gameManager.player_ship.faction, blip_scene))
	
	gameManager.save_manager.loaded.connect(func():
		var _ports = gameManager.world.ports
		for port in _ports:
			port.port_faction_changed.connect(func(_faction): update_map(gameManager.player_ship.faction, blip_scene))
		update_map(gameManager.player_ship.faction, blip_scene))

	pivot_offset_ratio = Vector2(0.5, 0.5)
	territory_draw.gameManager = gameManager
	territory_draw.map = self
	#gameManager.territory.territories_changed.connect(update_territory_drawings)
	
	heatmap_draw.visible = false
	heatmap_checkbox.button_pressed = heatmap_draw.visible
	fow_checkbox.button_pressed = fog_of_war.visible
	markers_checkbox.button_pressed = markers.visible
	territory_checkbox.button_pressed = territory_draw.visible
	
	ports_checkbox.button_pressed = draw_ports
	poi_checkbox.button_pressed = draw_pois
	
	heatmap_checkbox.pressed.connect(func(): heatmap_draw.visible = heatmap_checkbox.button_pressed)
	fow_checkbox.pressed.connect(func(): fog_of_war.visible = fow_checkbox.button_pressed)
	markers_checkbox.pressed.connect(func(): markers.visible = markers_checkbox.button_pressed)
	territory_checkbox.pressed.connect(func(): territory_draw.visible = territory_checkbox.button_pressed)
	
	ports_checkbox.pressed.connect(func():
		draw_ports = ports_checkbox.button_pressed
		update_map(gameManager.player_ship.faction, blip_scene)
		)
	poi_checkbox.pressed.connect(func():
		draw_pois = poi_checkbox.button_pressed
		update_map(gameManager.player_ship.faction, blip_scene)
		)

func set_zoom(value: float):
	map_scale += value
	scale = Vector2.ONE * clamp(map_scale + value, 0.1, 5.0)
	# camera.position.

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				set_zoom(0.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				set_zoom(-0.1)

func create_map_terrain_texture():
	var src: Texture2D = gameManager.world.terrain.heightmap_texture
	var img: Image = src.get_image()

	var _size = img.get_size()
	var out := Image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)

	for x in range(_size.x):
		for y in range(_size.y):
			var h = img.get_pixel(x, y).r
			h = smoothstep(0.3, 0.7, h)
				# threshold (tweak this)

			var thresh = 0.5
			var outline_size = 0.1
			if h > thresh - outline_size and h <= thresh:
				out.set_pixel(x, y, Color(0.5, 0.5, 0.5, 1.0)) # outline
			elif h > thresh:
				out.set_pixel(x, y, Color(1, 1, 1, 1.0)) # fill
			else:
				out.set_pixel(x, y, Color(1, 1, 1, 0))

	return ImageTexture.create_from_image(out)

var is_dragging = false
var last_mouse_position

func _process(_delta):
	if not visible:
		return

	if gameManager.player_ship and player_blip:
		update_blip_position(gameManager.player_ship, player_blip)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_viewport().get_mouse_position()
		var offset = mouse_pos - last_mouse_position

		position += offset

		last_mouse_position = mouse_pos
	else:
		last_mouse_position = get_viewport().get_mouse_position()


func update_map(_player_faction, _blip_scene):
	for child in markers.get_children():
		child.queue_free()
	
	player_blip = add_blip_to_map(gameManager.player_ship, Color.WHITE, 2.0, blip_a_scene)
	if draw_pois:
		for lh: Node3D in get_tree().get_nodes_in_group("Lighthouses"):
			var mine_icon = preload("res://Textures/spyglass.png")
			add_marker_to_map(lh, mine_icon, "Lighthouse", Color.WHITE, marker_scene)
		
		for mine: Mine in get_tree().get_nodes_in_group("Mines"):
			var mine_icon = preload("res://Textures/stone-crafting.png")
			add_marker_to_map(mine, mine_icon, "Mine", Color.WHITE, marker_scene)
	
	if draw_ports:
		for port: Port in gameManager.world.ports:
			if not port.allegiance:
				continue
			var enemy = FactionsData.is_enemy(_player_faction, port.allegiance.faction)
			var color = Color.GRAY
			if enemy:
				color = Color.RED
			else:
				color = Color.GREEN
			if port.allegiance.faction == FactionsData.Faction.NONE:
				color = Color.GRAY
			color = FactionsData.get_faction_color(port.allegiance.faction)
			add_marker_to_map(port, FactionsData.get_faction_icon(port.allegiance.faction), port.port_name, color, marker_scene)


func toggle_map():
	visible = !visible

func world_to_map(world_pos: Vector3) -> Vector2:
	var center_pos = territory_draw.size / 2

	var relative = Vector2(
		world_pos.x - center_pos.x,
		world_pos.z - center_pos.y
	)

	return territory_draw.size * 0.5 + -relative

func add_marker_to_map(node: Node3D, icon: Texture2D, marker_name: String, color: Color, _marker_scene: PackedScene) -> Control:
	var pos = node.global_position
	
	var marker: Control = _marker_scene.instantiate()
	markers.add_child(marker)
	marker.position = world_to_map(pos)

	var icon_texturerect: TextureRect = marker.get_node("VBoxContainer/faction_icon")
	var label: Label = marker.get_node("VBoxContainer/Label")
	var blip: TextureRect = marker.get_node("VBoxContainer/blip")

	#icon_texturerect.modulate = color
	blip.modulate = color
	icon_texturerect.texture = icon
	label.text = marker_name

	return marker

func add_blip_to_map(node: Node3D, color: Color, _scale: float, _blip_scene: PackedScene) -> Control:
	var pos = node.global_position
	var rot = - node.global_rotation.y
	var blip: TextureRect = _blip_scene.instantiate()
	blip.modulate = color
	markers.add_child(blip)

	blip.position = world_to_map(pos)

	blip.scale = Vector2.ONE * _scale
	blip.rotation = rot

	return blip

func update_blip_position(node: Node3D, blip: Control):
	var pos = node.global_position
	var rot = - node.global_rotation.y

	blip.position = world_to_map(pos)
	blip.rotation = rot


func _on_button_map_pressed() -> void:
	toggle_map()
