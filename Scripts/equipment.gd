extends Node

class_name Equipment

signal equipment_changed(side: String)

@export var bow: Array[InventoryItem] = [null, null, null]
@export var port: Array[InventoryItem] = [null, null, null, null]
@export var starboard: Array[InventoryItem] = [null, null, null, null]

func get_equipment_slot(side: String, slot_index: int) -> InventoryItem:
	match side:
		"bow":
			if slot_index >= 0 and slot_index < bow.size():
				return bow[slot_index]

		"port":
			if slot_index >= 0 and slot_index < port.size():
				return port[slot_index]

		"starboard":
			if slot_index >= 0 and slot_index < starboard.size():
				return starboard[slot_index]

	return null

func set_equipment_slot(side: String, slot_index: int, inventory_item: InventoryItem):
	match side:
		"bow":
			bow[slot_index] = inventory_item

		"port":
			port[slot_index] = inventory_item

		"starboard":
			starboard[slot_index] = inventory_item

	equipment_changed.emit(side)
	print("setting equipment slot: " + str(slot_index) + "with id: " + str(inventory_item));
