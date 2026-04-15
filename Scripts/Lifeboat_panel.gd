extends PanelContainer

@export var label: Label
var crew := 0

signal recruit_pressed
signal kill_pressed

func _ready():
	label.text = "A lifeboat with %s crew members is nearby. Do you want to recruit them or kill them for gold?" % str(crew)

func _on_button_recruit_pressed() -> void:
	emit_signal("recruit_pressed")
	

func _on_button_kill_pressed() -> void:
	emit_signal("kill_pressed")
