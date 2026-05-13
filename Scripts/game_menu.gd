extends Control

@onready var gameManager: GameManager = get_node("/root/GameManager")

func new_game():
	gameManager.new_game()

func delete_savefile():
	gameManager.save_manager.delete_save()


func _on_button_delete_save_pressed() -> void:
	delete_savefile()

func _on_button_new_game_pressed() -> void:
	new_game()
