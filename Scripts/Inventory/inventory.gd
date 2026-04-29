extends Node

class_name Inventory

var world_owner: Node3D
var inventory_name
var size

var world_item: PackedScene = preload("res://Scenes/barrels.tscn")

var items: Array[InventoryItem]

signal inventory_changed(inventory: Inventory)
signal inventory_notification(message: String)

func _init(_world_owner: Node3D, _size: int, _inventory_name: String) -> void:
	world_owner = _world_owner
	inventory_name = _inventory_name
	size = _size
	items.resize(size)
	inventory_changed.emit(self )
	world_owner.add_child(self )

func new_notification(message: String):
	print(message);
	inventory_notification.emit(message)

func has_space() -> bool:
	return find_empty_slot() != -1

func find_empty_slot() -> int:
	for index in range(items.size()):
		var item = items[index]
		if item == null:
			return index
	return -1

func drop_item(index: int):
	var w_item = world_item.instantiate() as Loot
	get_tree().current_scene.add_child(w_item)
	w_item.global_position = world_owner.global_position + (-world_owner.basis.z * 5.0)
	w_item.global_rotation_degrees.y = randf() * 360.0
	remove_item_at(index)
	

func add_item(item: InventoryItem) -> bool:
	if not has_space():
		new_notification("No space in " + inventory_name)
		return false
	
	var empty_index = find_empty_slot()
	if empty_index != -1:
		items[empty_index] = item
		inventory_changed.emit(self )
		new_notification("Added %s to %s " % [item.item_name, inventory_name])
		return true
	else:
		new_notification("Couldnt find empty slot in " + inventory_name)
		return false

func remove_item(item: InventoryItem):
	var index = items.find(item)
	if index != -1:
		remove_item_at(index)

func remove_item_at(index: int):
	var item = items[index]
	if item == null:
		return
	new_notification("Removed %s from %s " % [item.item_name, inventory_name])
	items[index] = null
	inventory_changed.emit(self )
