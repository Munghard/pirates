extends Control

@onready var grid: GridContainer = $MarginContainer/HBoxContainer/Control/GridContainer
@onready var slot_scene: PackedScene = preload("res://UI/slot.tscn")

@onready var gameManager: GameManager = get_node("/root/GameManager")


func update_inventory_ui(inventory: Inventory):
	#clear
	for child in grid.get_children():
		child.queue_free()
	#populate
	for i in range(inventory.items.size()):
		var item = inventory.items[i]

		var new_slot = slot_scene.instantiate() as TextureButton
		grid.add_child(new_slot)

		var icon = new_slot.get_node("MarginContainer/TextureRect")
		var label_name = new_slot.get_node("MarginContainer2/Label_name") as Label
		var label_stack = new_slot.get_node("MarginContainer2/Label_stack") as Label

		if item != null:
			var item_def = Item_Database.get_item_definition(item.id)
			if item_def:
				icon.texture = item_def.icon
				label_name.text = item_def.item_name
				label_stack.text = "%s/%s" % [item.stack, item_def.max_stack]
		else:
			label_name.text = ""
			label_stack.text = ""
			icon.texture = null

		new_slot.pressed.connect(inventory.drop_item.bind(i))
		

func _on_close_button_pressed() -> void:
	visible = false
