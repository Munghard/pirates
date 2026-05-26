extends Node

class_name Inventory

var world_owner: Node3D
var inventory_name
var size
var world_item: PackedScene = preload("res://Scenes/loot.tscn")
var world: Node3D
var items: Array[InventoryItem]

signal inventory_changed(inventory: Inventory)
signal inventory_notification(message: String)

func _init(_world_owner: Node3D, _world: Node3D, _size: int, _inventory_name: String) -> void:
	world_owner = _world_owner
	inventory_name = _inventory_name
	size = _size
	items.resize(size)
	inventory_changed.emit(self )
	world_owner.add_child(self )
	world = _world

func move_item(index: int, to_inventory: Inventory):
	var item = items[index]
	if to_inventory.add_item(item):
		remove_item_at(index)

func sort():
	var new_items: Array[InventoryItem] = []

	for item in items:
		if item != null:
			new_items.append(item)

	new_items.sort_custom(func(a, b):
		var a_item_def = Item_Database.get_item_definition(a.id)
		var b_item_def = Item_Database.get_item_definition(b.id)
		return a_item_def.type < b_item_def.type
	)
	new_items.resize(size)

	items = new_items
	inventory_changed.emit(self )

func compact():
	var filtered: Array[InventoryItem] = []

	for item in items:
		if item != null:
			filtered.append(item)

	filtered.resize(size)
	items = filtered
	inventory_changed.emit(self )
	

func has_item(id: String, amount: int) -> bool:
	var total := 0
	
	for item in items:
		if item != null and item.id == id:
			total += item.stack
			if total >= amount:
				return true
	
	return false

func has_item_type(type: Item_Definition.Type, amount: int) -> bool:
	var total := 0
	
	for item in items:
		if item != null:
			var item_def = Item_Database.get_item_definition(item.id)
			if item_def.type == type:
				total += item.stack
				if total >= amount:
					return true
	
	return false

func find_item_index(id: String) -> int:
	for i in range(items.size()):
		var item = items[i]
		if item != null and item.id == id:
			return i
	return -1

func get_item_from_unique_id(unique_id: int) -> InventoryItem:
	for i in range(items.size()):
		var item: InventoryItem = items[i]
		if item != null and item.unique_id == unique_id:
			return item
	return null

func get_item_index_from_unique_id(unique_id: int) -> int:
	for i in range(items.size()):
		var item: InventoryItem = items[i]
		if item != null and item.unique_id == unique_id:
			return i
	return -1

func item_amount(id: String) -> int:
	var total := 0
	
	for item in items:
		if item != null and item.id == id:
			total += item.stack
	return total

func item_amount_of_type(type: Item_Definition.Type) -> int:
	var total := 0
	
	for item in items:
		if item != null:
			var item_def = Item_Database.get_item_definition(item.id)
			if item_def.type == type:
				total += item.stack
	return total

func consume_item_at(index: int, amount: int) -> bool:
	var remaining := amount
	var item = items[index]

	if item == null:
		return false

	var take = min(item.stack, remaining)
	item.stack -= take
	remaining -= take

	if item.stack == 0:
		remove_item_at(index)
		inventory_changed.emit(self )

	if remaining <= 0:
		inventory_changed.emit(self )

	return true


func consume_item(id: String, amount: int) -> bool:
	if not has_item(id, amount):
		return false

	var remaining := amount

	for i in range(items.size()):
		var item = items[i]
		if item == null or item.id != id:
			continue
		
		var item_def = Item_Database.get_item_definition(id)
		var take = min(item.stack, remaining)
		item.stack -= take
		remaining -= take
		#var item_name = Item_Database.get_item_definition(id).item_name
		#inventory_notification.emit("-%s %s" % [take, item_name])

		if item.stack == 0:
			remove_item_at(i)
			inventory_changed.emit(self )


		new_notification("- %s %s" % [amount, item_def.item_name])
		if remaining <= 0:
			inventory_changed.emit(self )
			return true

	return false


func new_notification(message: String):
	#print(message);
	inventory_notification.emit(message)

func clear():
	items.clear()
	items.resize(size)

func has_space() -> bool:
	return find_empty_slot() != -1

func find_empty_slot() -> int:
	for index in range(items.size()):
		var item = items[index]
		if item == null:
			return index
	return -1

func drop_item_at_index(index: int):
	var item = items[index]
	drop_item(item)
	remove_item_at(index)

func drop_item(item: InventoryItem):
	var w_item = world_item.instantiate() as Loot
	world.add_child(w_item)
	w_item.setup_loot(item, world_owner)
	w_item.global_position = world_owner.global_position + (-world_owner.basis.z * 5.0)
	w_item.global_rotation_degrees.y = randf() * 360.0

func get_partial_stack_index(id: String) -> int:
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
	if not item_def:
		new_notification("Item doesnt exist in db " + str(item.id))
		return false
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
	new_notification("+ %s %s" % [item.stack, item_def.item_name])

	return true


func remove_from_stack(unique_id: int, amount: int) -> bool:
	if unique_id == -1:
		return false
	for i in range(items.size()):
		var item = items[i]
		if item != null and item.unique_id == unique_id:
			var item_def = Item_Database.get_item_definition(item.id)
			if item.stack >= amount:
				item.stack -= amount
				if item.stack <= 0:
					items[i] = null
				inventory_changed.emit(self )
				new_notification("- %s %s" % [amount, item_def.item_name])
				return true
	return false

func remove_item_stack(unique_id: int):
	for i in range(items.size()):
		var item = items[i]

		if item != null and item.unique_id == unique_id:
			items[i] = null
			inventory_changed.emit(self )
			return


func remove_item(item: InventoryItem):
	if item == null:
		return
	for i in range(items.size()):
		if items[i] != null and items[i].unique_id == item.unique_id:
			remove_item_at(i)
			return

func remove_item_at(index: int):
	var item = items[index]
	if item == null:
		return
	var item_def = Item_Database.get_item_definition(item.id)
	new_notification("Removed %s %s" % [item.stack, item_def.item_name])
	items[index] = null
	inventory_changed.emit(self )

func get_item_index_of_type(type: Item_Definition.Type):
	for i in range(items.size()):
		var item = items[i]
		if item != null:
			var item_def = Item_Database.get_item_definition(item.id)
			if not item_def:
				continue
			if item_def.type == type:
				return i
	return -1
