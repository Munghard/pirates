extends Node3D

class_name GameManager

@onready var player_ship: PlayerShip = $PlayerShip
@onready var hud: HUD = $MarginContainer/HUD
@onready var camera: Camera3D = $camrig/Camera3D
@onready var camerarig: Node3D = $camrig
@onready var water: Water = $water

var wind: Wind

func _init() -> void:
	wind = Wind.new()
	add_child(wind)

func _ready() -> void:
	wind.randomize_direction()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			wind.randomize_direction()
