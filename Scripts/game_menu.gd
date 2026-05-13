extends Control

@onready var gameManager: GameManager = get_node("/root/GameManager")

func new_game():
	gameManager.new_game()

func delete_savefile():
	gameManager.save_manager.delete_save()