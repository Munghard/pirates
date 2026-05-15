extends Control

@onready var gameManager: GameManager = get_node("/root/GameManager")
var map: Map
@export var territory: Territory

var cached_cells = []
var dirty = true
var cell_size

func _ready():
	await get_tree().process_frame
	territory.ownership_changed.connect(rebuild_visual_cache)
	gameManager.save_manager.loaded.connect(func(): rebuild_visual_cache())
	rebuild_visual_cache()


func _draw() -> void:
	for data in cached_cells:
		draw_cell(data)

func rebuild_visual_cache():
	cached_cells.clear()
	var ownership = territory.ownership
	cell_size = territory.cell_size
	for cell in ownership.keys():
		var faction = ownership[cell]
		var border = is_border_cell(ownership, cell, faction)
		var offset = cell_size

		cached_cells.append({
			"cell": map.world_to_map(Vector3(cell.x + offset, 0, cell.y + offset)),
			"faction": faction,
			"border": border,
			"color": FactionsData.get_faction_color(faction)
		})
	queue_redraw()

func draw_cell(data):
	var border = data.border
	var color = data.color
	var a_color = color
	a_color.a = 0.3
	var col = a_color
	if border:
		col = color
	draw_rect(
		Rect2(Vector2(data.cell),
		Vector2.ONE * cell_size),
		col,
		true
	)

func is_border_cell(ownership, cell: Vector2i, faction) -> bool:
	var dirs = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN
	]

	for dir in dirs:
		var neighbor = cell + (dir * cell_size)

		if ownership.get(neighbor, null) != faction:
			return true

	return false

func draw_territories_uncached_slow():
	for cell in cached_cells:
		var faction = gameManager.territory.ownership[cell]
		var border = is_border_cell(gameManager.territory.ownership, cell, faction)
		var color := FactionsData.get_faction_color(faction)
		var a_color = color
		a_color.a = 0.3


		var offset = Vector2i.ONE * (cell_size + cell_size)

		var map_pos = map.world_to_map(
			Vector3(
				cell.x + offset.x,
				0,
				cell.y + offset.y)
			)
		var col = a_color
		if border:
			col = color
		draw_rect(
			Rect2(Vector2(map_pos),
			Vector2.ONE * cell_size),
			col,
			true
		)


func draw_territory_polygon(_territory: PackedVector2Array, _color: Color):
	var map_converted: PackedVector2Array
	for p in _territory:
		map_converted.append(map.world_to_map(Vector3(p.x, 0, p.y)))
	
	var a_color = _color
	a_color.a = 0.3
	draw_colored_polygon(map_converted, a_color)
	draw_polyline(map_converted, _color, 2.0)
	
	for p in _territory:
		draw_circle(map.world_to_map(Vector3(p.x, 0, p.y)), 3.0, _color * 1.1)
		draw_arc(map.world_to_map(Vector3(p.x, 0, p.y)), 6.0, 0.0, 360.0, 12, _color * 1.2, 2.0)
