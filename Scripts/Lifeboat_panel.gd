extends PanelContainer

@export var label: Label
var crew := 0
signal recruit
signal kill
signal leave

func _ready():
	label.text = "A lifeboat with %s crew members is nearby. Do you want to try to recruit them or kill them for a chance of gold or supplies?" % str(crew)

func _on_button_recruit_pressed() -> void:
	emit_signal("recruit")
	queue_free()
	

func _on_button_kill_pressed() -> void:
	emit_signal("kill")
	queue_free()


func _on_button_1_pressed() -> void:
	emit_signal("leave")
	queue_free()
