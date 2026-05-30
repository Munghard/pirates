extends Control

@export var heatmap: Heatmap
var cell_size := 10.0

func _ready() -> void:
	heatmap.on_changed.connect(func(_hm): queue_redraw())

func _draw() -> void:
	for x in range(heatmap.width):
		for y in range(heatmap.height):
			var index = x + y * heatmap.width
			var cell = heatmap.grid[index]
			var pos = Vector2(x, y) * cell_size
			var rect = Rect2((heatmap.width * cell_size / 2) - pos.x, (heatmap.height * cell_size / 2) - pos.y, cell_size, cell_size)
			var color = lerp(Color.GREEN, Color.RED, cell.noise)
			draw_rect(rect, color)
