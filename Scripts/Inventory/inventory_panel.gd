extends Control

@onready var grid: GridContainer = $MarginContainer/HBoxContainer/Control/GridContainer
@onready var slot_scene: PackedScene = preload("res://UI/slot.tscn")
@onready var tooltip_scene: PackedScene = preload("res://UI/item_tooltip.tscn")
@onready var gameManager: GameManager = get_node("/root/GameManager")
@onready var label: Label = $MarginContainer/HBoxContainer/Control/PanelContainer/Label
@onready var button_compact: Button = $MarginContainer/HBoxContainer/Control/HBoxContainer/Button_compact
@onready var button_sort: Button = $MarginContainer/HBoxContainer/Control/HBoxContainer/Button_sort


func update_inventory_ui(inventory: Inventory, left_click: Callable, right_click: Callable, _middle_click: Callable):
	if not button_compact.pressed.is_connected(inventory.compact):
		button_compact.pressed.connect(inventory.compact)
	if not button_sort.pressed.is_connected(inventory.sort):
		button_sort.pressed.connect(inventory.sort)
		
	label.text = inventory.inventory_name
	#clear
	for child in grid.get_children():
		child.queue_free()
	#populate
	for i in range(inventory.items.size()):
		var item = inventory.items[i]

		var new_slot = slot_scene.instantiate() as Slot
		grid.add_child(new_slot)

		var icon = new_slot.get_node("MarginContainer/TextureRect")
		var label_name = new_slot.get_node("MarginContainer2/Label_name") as Label
		var label_stack = new_slot.get_node("MarginContainer2/Label_stack") as Label
		var color_tr = new_slot.get_node("Color") as TextureRect

		if item != null:
			var item_def = Item_Database.get_item_definition(item.id)
			if item_def:
				icon.texture = item_def.icon
				label_name.text = item_def.item_name
				label_stack.text = "%s/%s" % [item.stack, item_def.max_stack]
				color_tr.modulate = Item_Database.get_item_type_color(item_def.type)

				#connect signals from ui
				new_slot.left_click.connect(left_click.bind(i))
				new_slot.right_click.connect(right_click.bind(i))
				new_slot.middle_click.connect(_middle_click.bind(i))
				new_slot.hover.connect(hover.bind(item.id))
				new_slot.unhover.connect(unhover)
		else:
			color_tr.modulate = Color.TRANSPARENT
			label_name.text = ""
			label_stack.text = ""
			icon.texture = null


var tooltip: TextureRect

func unhover():
	if tooltip:
		tooltip.queue_free()

func hover(pos: Vector2, _id: String):
	var viewport_size = get_viewport().get_visible_rect().size
	var item_def = Item_Database.get_item_definition(_id)

	if tooltip:
		tooltip.queue_free()
	tooltip = tooltip_scene.instantiate() as TextureRect
	gameManager.hud.add_child(tooltip)

	var offset = Vector2(0, 0)

	# Horizontal side
	if pos.x > viewport_size.x * 0.5:
		offset.x = - tooltip.size.x

	# Vertical side
	if pos.y > viewport_size.y * 0.5:
		offset.y = - tooltip.size.y

	tooltip.global_position = pos + offset

	var color_tr = tooltip.get_node("Color") as TextureRect
	var icon_tr = tooltip.get_node("Icon") as TextureRect
	color_tr.modulate = Item_Database.get_item_type_color(item_def.type)
	var label_name = tooltip.get_node("MarginContainer/VBoxContainer/Label_name") as Label
	var label_desc = tooltip.get_node("MarginContainer/VBoxContainer/Label_desc") as Label
	var label_stack = tooltip.get_node("MarginContainer/VBoxContainer/Label_stack") as Label

	label_name.text = item_def.item_name
	icon_tr.texture = item_def.icon
	var desc_text = ""
	desc_text += "Type: %s" % [Item_Definition.TYPENAMES.get(item_def.type)]
	desc_text += "\nValue: %s" % [item_def.value]
	desc_text += "\nDescription: %s" % [item_def.description]
	label_desc.text = desc_text
	label_stack.text = "Max stack: " + str(item_def.max_stack)

func _on_close_button_pressed() -> void:
	visible = false
