extends PanelContainer

class_name Prompt

signal confirm
signal cancel

@export var label_h: Label
@export var label_message: Label
@export var button_cancel: Button
@export var button_confirm: Button
@export var icon: TextureRect

func _on_button_confirm_pressed() -> void:
	confirm.emit()

func _on_button_cancel_pressed() -> void:
	cancel.emit()

func setup(header: String, message: String, icon_texture: Texture, cancelable: bool):
	label_h.text = header
	label_message.text = message
	button_cancel.visible = cancelable
	icon.texture = icon_texture