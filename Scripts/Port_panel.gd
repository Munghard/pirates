extends PanelContainer

signal hire_crew_pressed
signal depart_pressed
signal upgrade_guns_pressed


func _on_button_hire_crew_pressed() -> void:
	emit_signal("hire_crew_pressed")

func _on_button_depart_pressed() -> void:
	emit_signal("depart_pressed")

func _on_button_guns_pressed() -> void:
	emit_signal("upgrade_guns_pressed")
