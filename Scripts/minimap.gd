# ================================================================================================================
# MINIMAP 
# ================================================================================================================
extends HBoxContainer

@onready var gameManager: GameManager = get_node("/root/GameManager")
@export var minimap: Control
@export var minimap_terrain_texture: TextureRect
@export var minimap_scale_slider: VSlider
@export var blip_scene: PackedScene = preload("res://UI/blip.tscn")
@export var blip_a_scene: PackedScene = preload("res://UI/blip_a.tscn")
var minimap_scale = 50.0

func _ready() -> void:
	await get_tree().process_frame
	minimap_scale_slider.value = minimap_scale

func _process(_delta):
	if Time.get_ticks_msec() % 1000 < 50: # update minimap every second
		update_minimap()

func create_minimap_terrain_texture():
	var src: Texture2D = gameManager.world.terrain.heightmap_texture
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
	
	add_blip_to_minimap(gameManager.player_ship, Color(1, 1, 1), 2.5, blip_a_scene)
	
	set_terrain_texture_transforms()

	for ship: Ship in get_tree().get_nodes_in_group("Ships"):
		if ship == gameManager.player_ship:
			continue
		var enemy = FactionsData.is_enemy(gameManager.player_ship.faction, ship.faction)
		var color = Color.GREEN
		if enemy:
			color = Color.RED
		#var color = FactionsData.get_faction_color(ship.faction)
		add_blip_to_minimap(ship, color, 1.25, blip_a_scene)
		
	for port: Node3D in get_tree().get_nodes_in_group("Ports"):
		var enemy = FactionsData.is_enemy(gameManager.player_ship.faction, port.allegiance.faction)
		var color = Color.GREEN
		if enemy:
			color = Color.RED
		#var color = FactionsData.get_faction_color(port.allegiance.faction)
		add_blip_to_minimap(port, color, 1.25, blip_scene)
	
	for floater: Node3D in get_tree().get_nodes_in_group("Floaters"):
		var color = Color(1, 1, 1, 0.5)
		add_blip_to_minimap(floater, color, 0.5, blip_scene)

func add_blip_to_minimap(node: Node3D, color: Color, _scale: float, _blip_scene: PackedScene):
	var pos = node.global_position
	var rot = - node.global_rotation.y
	var blip: TextureRect = _blip_scene.instantiate()
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
	blip.rotation = rot


func _on_v_slider_value_changed(value: float) -> void:
	minimap_scale = value / 100.0
	update_minimap()
