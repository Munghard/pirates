extends PanelContainer

@export var label: Label
var crew := 0

signal recruit
signal kill

func _ready():
	label.text = "A lifeboat with %s crew members is nearby. Do you want to recruit them or kill them for gold?" % str(crew)

func _on_button_recruit_pressed() -> void:
	emit_signal("recruit")
	queue_free()
	

func _on_button_kill_pressed() -> void:
	emit_signal("kill")
	queue_free()
