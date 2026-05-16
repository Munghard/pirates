extends Control

@onready var gameManager: GameManager = get_node("/root/GameManager")

@export var strip: Control
@export var pixels_per_rotation := 720.0

func _process(_delta):
	var player_ship = gameManager.player_ship
	if not player_ship:
		return

	var yaw = player_ship.rotation.y

	# convert radians -> 0..1
	var t = wrapf(yaw / TAU, 0.0, 1.0)

	strip.position.x = (-t * pixels_per_rotation)
