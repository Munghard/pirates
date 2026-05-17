extends Control

class_name Map
@onready var gameManager: GameManager = get_node("/root/GameManager")

@onready var map_control: Control = $MarginContainer/Control
@onready var map: TextureRect = $MarginContainer/Control/TextureRect
@onready var map_terrain: TextureRect = $MarginContainer/Control/TextureRect2
@onready var territory_draw: Control = $MarginContainer/Control/Territory

@onready var marker_scene: PackedScene = preload("res://UI/map_marker.tscn")
@onready var blip_scene: PackedScene = preload("res://UI/blip.tscn")
@onready var blip_a_scene: PackedScene = preload("res://UI/blip_a.tscn")

var map_scale = 1.0
var player_blip: Control

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

	player_blip = add_blip_to_map(gameManager.player_ship, Color.WHITE, 2.0, blip_a_scene)
	pivot_offset_ratio = Vector2(0.5, 0.5)
	territory_draw.gameManager = gameManager
	territory_draw.map = self
	#gameManager.territory.territories_changed.connect(update_territory_drawings)


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
	for child in territory_draw.get_children():
		child.queue_free()
	
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
	var icon_texturerect: TextureRect = marker.get_node("VBoxContainer/faction_icon")
	var label: Label = marker.get_node("VBoxContainer/Label")
	var blip: TextureRect = marker.get_node("VBoxContainer/blip")

	#icon_texturerect.modulate = color
	blip.modulate = color
	icon_texturerect.texture = icon
	label.text = marker_name

	territory_draw.add_child(marker)

	marker.position = world_to_map(pos) - Vector2(32, 24)
	
	return marker

func add_blip_to_map(node: Node3D, color: Color, _scale: float, _blip_scene: PackedScene) -> Control:
	var pos = node.global_position
	var rot = - node.global_rotation.y
	var blip: TextureRect = _blip_scene.instantiate()
	blip.modulate = color
	territory_draw.add_child(blip)

	blip.position = world_to_map(pos) - Vector2(16, 16)

	blip.scale = Vector2.ONE * _scale
	blip.rotation = rot


	return blip

func update_blip_position(node: Node3D, blip: Control):
	var pos = node.global_position
	var rot = - node.global_rotation.y

	blip.position = world_to_map(pos) - Vector2(16, 16)
	blip.rotation = rot


func _on_button_map_pressed() -> void:
	toggle_map()
