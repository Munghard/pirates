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
@export var blip_player_scene: PackedScene = preload("res://UI/blip_player.tscn")
var minimap_scale = 50.0

func _ready() -> void:
	await get_tree().process_frame
	minimap_scale_slider.value = minimap_scale
	#minimap_terrain_texture.texture = create_minimap_terrain_texture()

var timer := 0.0

# func _draw() -> void:
# 	var center = size / 2.0
# 	var dir3 = gameManager.player_ship.basis.z
# 	var direction = Vector2(dir3.x, dir3.z).normalized()
# 	var length = 500.0
# 	var to = center + (-direction * length)

# 	var col = Color.WHITE
# 	col.a = 0.5
# 	draw_dashed_line(center, to, col, 6.0, 10.0)

func _process(delta):
	timer += delta
	if timer >= 1.0:
		timer = 0.0
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
			if h > 0.5:
				out.set_pixel(x, y, Color(0.5, 1, 0.5, 0.3))
			else:
				out.set_pixel(x, y, Color(1, 1, 1, 0))

	return ImageTexture.create_from_image(out)

func set_terrain_texture_transforms():
	if not minimap_terrain_texture.texture:
		return

	var terrain = gameManager.world.terrain

	var world_size := Vector2(
		terrain.world_size.x * terrain.tile_size,
		terrain.world_size.y * terrain.tile_size
	)

	var tex_size := minimap_terrain_texture.texture.get_size()

	# pixels per world unit
	var terrain_scale := world_size / tex_size

	var final_scale: Vector2 = Vector2.ONE * minimap_scale / terrain_scale

	minimap_terrain_texture.scale = final_scale

	var player_pos = gameManager.player_ship.global_position

	var player_world = Vector2(
		player_pos.x,
		player_pos.z
	)

	var texture_offset = Vector2(
		player_world.x * final_scale.x,
		player_world.y * final_scale.y
	)
	var scaled_tex_size = tex_size * final_scale
	minimap_terrain_texture.position = minimap.size * 0.5 - texture_offset - scaled_tex_size * 0.5

func update_minimap():
	for child in minimap.get_children():
		child.queue_free()
	
	add_blip_to_minimap(gameManager.player_ship, Color(1, 1, 1), 2.5, blip_player_scene)
	
	#set_terrain_texture_transforms()

	for ship: Ship in get_tree().get_nodes_in_group("Ships"):
		if ship == gameManager.player_ship:
			continue
		var enemy = false
		if ship.faction != FactionsData.Faction.NONE:
			enemy = FactionsData.is_enemy(gameManager.player_ship.faction, ship.faction)
		var color = Color.GRAY
		if enemy:
			color = Color.RED
		else:
			color = Color.GREEN
		#var color = FactionsData.get_faction_color(ship.faction)
		add_blip_to_minimap(ship, color, 1.25, blip_a_scene)
	
	for mine: Mine in get_tree().get_nodes_in_group("Mines"):
		add_blip_to_minimap(mine, Color.WHITE, 0.75, blip_scene)

	for lh: Node3D in get_tree().get_nodes_in_group("Lighthouses"):
		add_blip_to_minimap(lh, Color.WHITE, 0.75, blip_scene)

	for port: Port in gameManager.world.ports:
		var enemy = false
		if port.allegiance and port.allegiance.faction != FactionsData.Faction.NONE:
			enemy = FactionsData.is_enemy(gameManager.player_ship.faction, port.allegiance.faction)
		var color = Color.GRAY
		if enemy:
			color = Color.RED
		else:
			color = Color.GREEN
		#var color = FactionsData.get_faction_color(port.allegiance.faction)
		add_blip_to_minimap(port, color, 1.25, blip_scene)
	
	for floater: Node3D in get_tree().get_nodes_in_group("Floaters"):
		var color = Color(1, 1, 1, 0.5)
		add_blip_to_minimap(floater, color, 0.5, blip_scene)

func add_blip_to_minimap(node: Node3D, color: Color, _scale: float, _blip_scene: PackedScene) -> Control:
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
	return blip

func _on_v_slider_value_changed(value: float) -> void:
	minimap_scale = value / 100.0
	update_minimap()
