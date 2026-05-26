extends TextureButton
class_name Slot

signal right_click
signal left_click
signal middle_click
signal hover(pos)
signal unhover

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				emit_signal("left_click")
			MOUSE_BUTTON_RIGHT:
				emit_signal("right_click")
			MOUSE_BUTTON_MIDDLE:
				emit_signal("middle_click")


func _on_mouse_entered() -> void:
	#var pos = get_viewport().get_mouse_position()
	var pos = global_position + size / 2
	emit_signal("hover", pos)


func _on_mouse_exited() -> void:
	emit_signal("unhover")
