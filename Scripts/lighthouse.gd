extends Node3D

@export var reveal_radius: int = 15
@onready var light: SpotLight3D = $SpotLight3D
var visited = false

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _process(delta):
	light.rotation.y += TAU * delta * 0.1

func _on_body_entered(body: Node3D):
	var player = body as PlayerShip
	if player and not visited:
		visited = true
		player.gameManager.hud.ddd_label("Visited lighthouse\nArea revealed.", global_position, Color.GREEN)
		player.gameManager.hud.map.fog_of_war.reveal_area(Vector2(global_position.x, global_position.z), reveal_radius)

func _on_body_exited(body: Node3D):
	var player = body as PlayerShip
	if player:
		player.gameManager.hud.ddd_label("Left lighthouse", global_position, Color.RED)
		player = null