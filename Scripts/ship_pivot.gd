extends Node3D

@export var ship: Ship

@export var ship_model: Node3D

var sails: Array[Node3D] = []
@export var flag_mesh: MeshInstance3D

func set_flag():
	#setup flag
	var mat = flag_mesh.get_active_material(0) as ShaderMaterial
	var flag_texture = FactionsData.get_flag(ship.nation, ship.faction)
	mat.set_shader_parameter("flag_texture", flag_texture)

func _ready():
	sails.append(ship_model.get_node("BackSail"))
	sails.append(ship_model.get_node("Front Sail"))
	sails.append(ship_model.get_node("MidleSail"))


func _process(delta):
	var wind_dir = ship.gameManager.world.wind.direction

	# Convert wind into ship local space
	var local_wind = ship.global_transform.basis.inverse() * wind_dir
	var target_rot_y = atan2(local_wind.x, local_wind.z)

	for sail in sails:
		var rot = sail.rotation
		rot.y = lerp_angle(rot.y, target_rot_y, 3.0 * delta)
		sail.rotation = rot
