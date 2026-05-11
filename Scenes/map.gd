extends Control

@onready var gameManager: GameManager = get_node("/root/GameManager")

@onready var map: TextureRect = $Control/TextureRect
@onready var map_terrain: TextureRect = $Control/TextureRect2

@onready var blip_scene: PackedScene = preload("res://UI/blip.tscn")
@onready var blip_a_scene: PackedScene = preload("res://UI/blip_a.tscn")

var player_blip: Control

func _ready():
	await get_tree().process_frame
	map_terrain.texture = create_map_terrain_texture()
	
	update_map(gameManager.player_ship.faction, blip_scene)
	player_blip = add_blip_to_map(gameManager.player_ship, "Player", Color.WHITE, 2.0, blip_a_scene)

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

func _process(_delta):
	if gameManager.player_ship and player_blip:
		update_blip_position(gameManager.player_ship, player_blip)


func update_map(_player_faction, _blip_scene):
	for child in map.get_children():
		child.queue_free()
	for port: Port in get_tree().get_nodes_in_group("Ports"):
		var enemy = FactionsData.is_enemy(_player_faction, port.allegiance.faction)
		var color = Color.GREEN
		if enemy:
			color = Color.RED
		#var color = FactionsData.get_faction_color(port.allegiance.faction)
		add_blip_to_map(port, port.port_name, color, 1.25, _blip_scene)

func toggle_map():
	map.visible = !map.visible


func add_blip_to_map(node: Node3D, blip_name: String, color: Color, _scale: float, _blip_scene: PackedScene) -> Control:
	var pos = node.global_position
	var rot = - node.global_rotation.y
	var blip: TextureRect = _blip_scene.instantiate()
	blip.modulate = color
	map.add_child(blip)

	var center_pos = map.size / 2

	var relative = Vector2(
		pos.x - center_pos.x,
		pos.z - center_pos.y
	)

	# scale world → minimap space
	var p = relative
	var relative_pos = map.size * 0.5 + -p - blip.size * 0.5

	blip.scale = Vector2.ONE * _scale
	blip.position = relative_pos
	blip.rotation = rot

	var label = Label.new()
	map.add_child(label)
	label.text = blip_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = relative_pos - Vector2(0, 25)


	return blip

func update_blip_position(node: Node3D, blip: Control):
	var pos = node.global_position
	var rot = - node.global_rotation.y
	var center_pos = map.size / 2

	var relative = Vector2(
		pos.x - center_pos.x,
		pos.z - center_pos.y
	)

	var p = relative

	blip.position = map.size * 0.5 + -p - blip.size * 0.5
	blip.rotation = rot

func _on_button_map_pressed() -> void:
	toggle_map()
