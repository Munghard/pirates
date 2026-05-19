extends TextureRect

class_name Fog_Of_War

const UNKNOWN = 0
const EXPLORED = 1

var fog_grid = []

var world_origin: Vector2 = Vector2.ZERO

var grid_size: Vector2i = Vector2i(100, 100)
@export var fog_cell_size: float = 1.0

signal grid_changed(_fog_grid: Array)
signal image_changed(_img: Image)

func _ready():
	grid_changed.connect(update_image)
	image_changed.connect(update_ui)
	
	create_grid()


func test_open():
	reveal_area(Vector2(250, 250), 50)

func update_ui(img: Image):
	var texture2D: Texture2D = ImageTexture.create_from_image(img)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture = texture2D

func update_image(_fog_grid: Array):
	var img = Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_RGBA8)
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell = fog_grid[x][y]
			var col = Color.BLACK
			if cell == UNKNOWN:
				col = Color.BLACK
				col.a = 0.5
			elif cell == EXPLORED:
				col = Color.TRANSPARENT
			img.set_pixel(grid_size.x - 1 - x, grid_size.y - 1 - y, col)
	image_changed.emit(img)

func create_grid():
	fog_grid.resize(grid_size.x)

	for x in range(grid_size.x):
		fog_grid[x] = []
		fog_grid[x].resize(grid_size.y)

		for y in range(grid_size.y):
			fog_grid[x][y] = UNKNOWN
	grid_changed.emit(fog_grid)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var p = Vector2i((world_pos - world_origin) / fog_cell_size)
	return Vector2i(p.x, p.y)

func reveal_area(world_pos: Vector2, world_radius: int):
	var center = world_to_grid(world_pos)
	#var grid_radius = int(world_radius / fog_cell_size)
	for x in range(center.x - world_radius, center.x + world_radius + 1):
		for y in range(center.y - world_radius, center.y + world_radius + 1):
			if x < 0 or y < 0 or x >= grid_size.x or y >= grid_size.y:
				continue

			var dist = Vector2(x, y).distance_to(center)

			if dist <= world_radius:
				fog_grid[x][y] = EXPLORED
	
	grid_changed.emit(fog_grid)
