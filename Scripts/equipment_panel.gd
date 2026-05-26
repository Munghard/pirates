extends PanelContainer

@export var bow_slots: Array[OptionButton]
@export var port_slots: Array[OptionButton]
@export var starboard_slots: Array[OptionButton]

@onready var game_manager: GameManager = get_node("/root/GameManager")
@export var option_button_flag: OptionButton

func _ready():
	# Wait for the scene tree to ensure game_manager and player_ship are ready
	await get_tree().process_frame
	visible = false

	game_manager.player_ship.inventory.inventory_changed.connect(check_inventory_for_flags)
	check_inventory_for_flags(game_manager.player_ship.inventory)

func init_equipment_panel(player_ship: PlayerShip):
	setup_slots(player_ship)
	if not player_ship.equipment.equipment_changed.is_connected(_on_equipment_changed):
		player_ship.equipment.equipment_changed.connect(_on_equipment_changed)
	if not player_ship.inventory.inventory_changed.is_connected(func(_inventory): _on_equipment_changed("side")):
		player_ship.inventory.inventory_changed.connect(func(_inventory): _on_equipment_changed("side"))

	var selected_index = option_button_flag.get_item_index(player_ship.faction)
	option_button_flag.selected = selected_index

	if not option_button_flag.item_selected.is_connected(set_player_faction.bind(player_ship)):
		option_button_flag.item_selected.connect(set_player_faction.bind(player_ship))

func set_player_faction(index, player_ship: PlayerShip):
	var faction = option_button_flag.get_item_id(index)
	player_ship.change_faction(faction)

func check_inventory_for_flags(inventory: Inventory):
	var _factions: Array[FactionsData.Faction] = []
	
	if inventory.has_item("flag_pirate", 1):
		_factions.append(FactionsData.Faction.PIRATE)
	if inventory.has_item("flag_navy", 1):
		_factions.append(FactionsData.Faction.NAVY)
	if inventory.has_item("flag_merchant", 1):
		_factions.append(FactionsData.Faction.MERCHANT)
	if inventory.has_item("flag_slaver", 1):
		_factions.append(FactionsData.Faction.SLAVER)
	if inventory.has_item("flag_cartographer", 1):
		_factions.append(FactionsData.Faction.CARTOGRAPHER)
	if inventory.has_item("flag_bountyhunter", 1):
		_factions.append(FactionsData.Faction.BOUNTYHUNTER)
	if inventory.has_item("flag_viking", 1):
		_factions.append(FactionsData.Faction.VIKING)
	if inventory.has_item("flag_fisherman", 1):
		_factions.append(FactionsData.Faction.FISHERMAN)
		
	update_faction_select_list(_factions)

func update_faction_select_list(_factions: Array[FactionsData.Faction]):
	option_button_flag.clear()
	for faction in _factions:
		option_button_flag.add_item(FactionsData.FACTION_NAMES[faction], faction)


func setup_slots(player_ship: PlayerShip):
	_setup_side(bow_slots, "bow", player_ship)
	_setup_side(port_slots, "port", player_ship)
	_setup_side(starboard_slots, "starboard", player_ship)

func _on_equipment_changed(_side: String):
	# Refresh the UI when the underlying data changes
	setup_slots(game_manager.player_ship)

func _setup_side(slots: Array[OptionButton], side: String, player_ship: PlayerShip):
	for i in range(slots.size()):
		var drop_down = slots[i]
		drop_down.set_block_signals(true)
		drop_down.clear()
		
		# 1. Always add "None"
		drop_down.add_item("None")
		drop_down.set_item_metadata(0, null)

		# 2. Get the item currently in this specific slot
		var equipped_item = player_ship.equipment.get_equipment_slot(side, i)
		
		# 3. If there IS something equipped, add it to the list FIRST 
		# (so we can actually select it)
		if equipped_item:
			var item_def = Item_Database.get_item_definition(equipped_item.id)
			var idx = drop_down.item_count
			drop_down.add_item(item_def.item_name)
			drop_down.set_item_metadata(idx, equipped_item)
			drop_down.select(idx) # Visualizes it as currently selected
		else:
			drop_down.select(0) # Default to "None"

		# 4. Now add everything else available in the inventory
		for item in player_ship.inventory.items:
			if item:
				var item_def = Item_Database.get_item_definition(item.id)
				if item_def.type == 4:
					var idx = drop_down.item_count
					drop_down.add_item(item_def.item_name)
					drop_down.set_item_metadata(idx, item)

		_connect_dropdown(drop_down, side, i, player_ship)
		drop_down.set_block_signals(false)

func _select_item_by_metadata(drop_down: OptionButton, target_item: InventoryItem):
	for i in range(drop_down.item_count):
		var meta = drop_down.get_item_metadata(i)
		if meta and meta.unique_id == target_item.unique_id:
			drop_down.select(i)
			return
	# If the equipped item isn't in the list (e.g. it was removed from inventory), 
	# you might need to handle that edge case here.

func _connect_dropdown(drop_down: OptionButton, side: String, slot_index: int, player_ship: PlayerShip):
	var callable = _on_selected.bind(drop_down, side, slot_index, player_ship)
	# Disconnect previous to avoid double-firing if setup_slots is called multiple times
	for connection in drop_down.item_selected.get_connections():
		drop_down.item_selected.disconnect(connection.callable)
	drop_down.item_selected.connect(callable)

func _on_selected(index: int, drop_down: OptionButton, side: String, slot_index: int, player_ship: PlayerShip):
	var current_equipped = player_ship.equipment.get_equipment_slot(side, slot_index)

	# CASE: Selecting "None" (Index 0)
	if index == 0:
		if current_equipped != null:
			# Put the item back in inventory
			player_ship.inventory.add_item(current_equipped)
			# Clear the ship slot
			player_ship.equipment.set_equipment_slot(side, slot_index, null)
			
			# FORCED REFRESH: If your signal doesn't auto-update the UI, call it here:
			setup_slots(player_ship)
		return

	# CASE: Selecting a New Item
	var new_item: InventoryItem = drop_down.get_item_metadata(index)

	# Safety check: Is this item already equipped here?
	if current_equipped and current_equipped.unique_id == new_item.unique_id:
		return

	# Swap logic: Return old item to inventory
	if current_equipped:
		player_ship.inventory.add_item(current_equipped)

	# Equip new item
	player_ship.inventory.remove_item(new_item)
	player_ship.equipment.set_equipment_slot(side, slot_index, new_item)

	# Refresh to update ALL dropdowns (since inventory count changed)
	setup_slots(player_ship)
