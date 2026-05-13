extends Node3D

class_name FishingOperation

var gameManager: GameManager

func _init(_gameManager: GameManager) -> void:
	gameManager = _gameManager

var interval = 10.0
var elapsed = 0.0

func _process(delta):
	elapsed += delta
	if elapsed >= interval:
		elapsed = 0.0
		gameManager.spawn_item_in_world(InventoryItem.new("rations", randi_range(1, 2)), global_position)
