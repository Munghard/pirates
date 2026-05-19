extends Control

@onready var gameManager: GameManager = get_node("/root/GameManager")

@export var spinbox: SpinBox
@export var line_edit: LineEdit

func new_game():
	gameManager.new_game(int(spinbox.value), line_edit.text)

func delete_savefile():
	gameManager.save_manager.delete_save()


func _on_button_delete_save_pressed() -> void:
	delete_savefile()

func _on_button_new_game_pressed() -> void:
	new_game()
