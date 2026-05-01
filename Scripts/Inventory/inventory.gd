extends Node

class_name Inventory

var world_owner: Node3D
var inventory_name
var size

var world_item: PackedScene = preload("res://Scenes/loot.tscn")

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

func clear():
	items.clear()

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
	var ship = world_owner as Ship
	var world = ship.gameManager.world
	world.add_child(w_item)
	w_item.setup_loot(items[index], world_owner)
	w_item.global_position = world_owner.global_position + (-world_owner.basis.z * 5.0)
	w_item.global_rotation_degrees.y = randf() * 360.0
	remove_item_at(index)

func get_partial_stack_index(id: int) -> int:
	for i in range(items.size()):
		var item = items[i]
		if item == null:
			continue
		var item_def = Item_Database.get_item_definition(id)
		if item.id == id and item.stack < item_def.max_stack:
			return i
	return -1

func add_item(item: InventoryItem) -> bool:
	var item_def = Item_Database.get_item_definition(item.id)
	var remaining = item.stack

	# 1. Try to fill existing stacks first
	while remaining > 0:
		var partial_index = get_partial_stack_index(item.id)
		if partial_index == -1:
			break

		var stack = items[partial_index]
		var space = item_def.max_stack - stack.stack
		var to_add = min(space, remaining)

		stack.stack += to_add
		remaining -= to_add

	# 2. Put leftovers into empty slots
	while remaining > 0:
		if not has_space():
			new_notification("No space in " + inventory_name)
			return false

		var empty_index = find_empty_slot()
		if empty_index == -1:
			return false

		var to_add = min(item_def.max_stack, remaining)

		var new_item = InventoryItem.new(item.id, to_add)
		
		items[empty_index] = new_item

		remaining -= to_add

	# 3. Notify once at the end
	inventory_changed.emit(self )
	new_notification("Added %s %s to %s" % [item.stack, item_def.item_name, inventory_name])

	return true

func remove_item(item: InventoryItem):
	var index = items.find(item)
	if index != -1:
		remove_item_at(index)

func remove_item_at(index: int):
	var item = items[index]
	if item == null:
		return
	var item_def = Item_Database.get_item_definition(item.id)
	new_notification("Removed %s %s from %s " % [item.stack, item_def.item_name, inventory_name])
	items[index] = null
	inventory_changed.emit(self )
