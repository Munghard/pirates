@tool
extends MeshInstance3D

class_name Water

@export var target: Node3D
@export var textureSize := 256
@export var noise_frequency := 2.0 # Higher frequency for better detail
var img: Image
var world_size := Vector2(100, 100)


func _ready():
	# Only generate if we are in game or it's missing
	generate_noise_texture()

func generate_noise_texture():
	img = Image.create(textureSize, textureSize, false, Image.FORMAT_RF)
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	noise.frequency = 0.05 # Adjust this for "choppy" vs "rolling" waves
	
	for x in textureSize:
		for y in textureSize:
			# We use x and y directly to let the shader's 'scale' handle the sizing
			var n = (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			img.set_pixel(x, y, Color(n, 0, 0))

	var tex = ImageTexture.create_from_image(img)
	var mat = get_active_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("wave_noise", tex)

func get_height_at(world_pos: Vector3) -> float:
	var x = int((world_pos.x / world_size.x) * img.get_width())
	var y = int((world_pos.z / world_size.y) * img.get_height())

	x = clamp(x, 0, img.get_width() - 1)
	y = clamp(y, 0, img.get_height() - 1)

	return img.get_pixel(x, y).r

func _process(_delta):
	position = target.position
	position.y = 0
	var gameManager = get_node_or_null("/root/World")
	var mat = get_active_material(0)
	
	if mat is ShaderMaterial:
		if Engine.is_editor_hint():
			# Default value for editor so it's not static
			mat.set_shader_parameter("wind_direction", Vector3(0.1, 0, 0.1))
		
		if gameManager and "wind" in gameManager:
			var wind_dir = gameManager.wind.direction
			mat.set_shader_parameter("wind_direction", wind_dir)
			# The stronger the wind, the higher the waves
			mat.set_shader_parameter("wave_height", wind_dir.length() * 0.0)
