extends Node3D

@onready var light: SpotLight3D = $SpotLight3D

func _process(delta):
	light.rotation.y += TAU * delta * 0.1