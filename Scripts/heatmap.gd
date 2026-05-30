extends Node

class_name Heatmap

class Cell:
	var noise: float = 0.0
	var resupply: float = 0.0

var width := 100
var height := 100
var cell_size := 10.0
var grid: Array[Cell] = []

signal on_changed(_grid: Array[Cell])

func _ready():
	grid.resize(width * height)
	for i in range(grid.size()):
		grid[i] = Cell.new()
	on_changed.emit(grid)

func set_grid_from_data(data: Array[Cell]):
	grid.resize(width * height)
	grid = data
	on_changed.emit(grid)

func add_noise_at(world_pos: Vector3, noise: float, radius: float):
	var center = world_to_grid(world_pos)

	var r_cells = int(ceil(radius / cell_size))

	for x in range(center.x - r_cells, center.x + r_cells + 1):
		for y in range(center.y - r_cells, center.y + r_cells + 1):
			if not is_valid(x, y):
				continue

			var dx = x - center.x
			var dy = y - center.y
			var dist = sqrt(dx * dx + dy * dy)

			if dist > r_cells:
				continue

			var falloff = 1.0 - (dist / r_cells)

			var cell = get_cell(x, y)
			cell.noise += noise * falloff

	on_changed.emit(grid)

func get_noise_at_world_position(world_pos: Vector3) -> float:
	var grid_pos := world_to_grid(world_pos)
	var index = _get_index(grid_pos.x, grid_pos.y)
	return grid[index].noise

func is_valid(x: int, z: int) -> bool:
	return x >= 0 and z >= 0 and x < width and z < height

func get_cell(x: int, z: int) -> Cell:
	if not is_valid(x, z):
		return null
	return grid[_get_index(x, z)]

func world_to_grid(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		floor(world_pos.x / cell_size),
		floor(world_pos.z / cell_size)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	return Vector3(
		grid_pos.x * cell_size,
		0.0,
		grid_pos.y * cell_size
	)

func _get_index(x: int, z: int) -> int:
	return x + z * width

func _process(delta: float) -> void:
	for cell in grid:
		cell.noise = max(cell.noise - delta * 0.001, 0.0)
		cell.resupply = max(cell.noise - delta * 0.01, 0.0)
	on_changed.emit(grid)
