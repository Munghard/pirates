extends PanelContainer

@onready var cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/Button_cancel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/Button_confirm
@onready var max_button: Button = $MarginContainer/VBoxContainer/HBoxContainer3/Button_max
@onready var slider: Slider = $MarginContainer/VBoxContainer/HBoxContainer3/HSlider
@onready var label_amount: Label = $MarginContainer/VBoxContainer/HBoxContainer/Label_amount
@onready var label_cost: Label = $MarginContainer/VBoxContainer/Label_cost
@onready var label: Label = $MarginContainer/VBoxContainer/Label
@onready var icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/TextureRect

var cost: int = 0
var available_money: int = 0

signal cancel
signal confirm
signal slider_changed(amount: float)

func _ready():
	cancel_button.pressed.connect(_on_cancel_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	max_button.pressed.connect(_on_max_pressed)
	slider.value_changed.connect(_on_slider_changed)

func _on_cancel_pressed():
	cancel.emit()

func _on_confirm_pressed():
	confirm.emit()

func _on_max_pressed():
	slider.value = available_money / float(cost)

func _on_slider_changed(amount: float):
	var total_cost = amount * cost
	slider_changed.emit(amount)
	label_amount.text = str(amount)
	label_cost.text = "$" + str(total_cost)

	var color = Color.WHITE
	if available_money < total_cost:
		color = Color.RED
	label_cost.self_modulate = color
