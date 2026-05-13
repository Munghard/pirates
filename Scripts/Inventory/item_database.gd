extends Node
class_name Item_Database

static var item_database: Array[Item_Definition]

func _ready():
	create_items()

func create_items():
	# ID, TYPE, VALUE, MAX_STACK, NAME, DESCRIPTION, ICON TEXTURE
	item_database.append(Item_Definition.new(0, 3, 5, 50, "Rations", "Consumed daily to feed the crew. Running out leads to starvation and death.", preload("res://Textures/canned-fish.png")))

	item_database.append(Item_Definition.new(1, 3, 10, 50, "Rum", "Consumed by the crew to maintain morale and discipline.", preload("res://Textures/brandy-bottle.png")))

	item_database.append(Item_Definition.new(2, 4, 500, 1, "6 Pounder", "Light naval weapon mounted on the ship. Level 1", preload("res://Textures/cannon.png")))

	item_database.append(Item_Definition.new(3, 3, 5, 50, "Cannon balls", "Ammunition used by cannons.", preload("res://Textures/ball-pyramid.png")))

	item_database.append(Item_Definition.new(4, 3, 1, 50, "Ropes", "Essential repair material used to maintain the ship.", preload("res://Textures/rope-coil.png")))

	item_database.append(Item_Definition.new(5, 1, 5, 50, "Navigation equipment", "Specialized maritime tools valued by traders and navigators.", preload("res://Textures/sextant.png")))

	item_database.append(Item_Definition.new(6, 0, 2, 50, "Documents", "Letters, permits, and records valuable for trade and diplomacy.", preload("res://Textures/tied-scroll.png")))

	item_database.append(Item_Definition.new(7, 0, 2, 50, "Shackles", "Iron restraints commonly used for prisoners and slaves.", preload("res://Textures/handcuffs.png")))

	item_database.append(Item_Definition.new(8, 0, 5, 50, "Firearms", "Muskets and pistols sought after across the seas.", preload("res://Textures/blunderbuss.png")))

	item_database.append(Item_Definition.new(9, 2, 5, 50, "Fishing gear", "Used to catch fish and gather additional rations while at sea.", preload("res://Textures/fishing-net.png")))

	item_database.append(Item_Definition.new(10, 0, 1, 500, "Gold", "Universal currency used for trade, repairs, and recruitment.", preload("res://Textures/coins.png")))

	item_database.append(Item_Definition.new(11, 0, 10, 10, "Maps", "Charts and sea maps that can reveal valuable routes and locations.", preload("res://Textures/tied-scroll.png")))

	item_database.append(Item_Definition.new(12, 1, 200, 1, "Spyglass", "Optical tool that greatly increases viewing distance at sea.", preload("res://Textures/spyglass.png")))
	
	item_database.append(Item_Definition.new(13, 2, 100, 5, "Repair kit", "Repair kit that allows quickly fixing the ship. Repairs 50.0hp over 25 seconds", preload("res://Textures/barrel.png")))
	
	item_database.append(Item_Definition.new(14, 2, 100, 5, "Diving suit", "Can be used to perform a dive and potentially recover treasure.", preload("res://Textures/diving-helmet.png")))

	item_database.append(Item_Definition.new(15, 4, 750, 1, "12 Pounder", "Medium light naval weapon mounted on the ship. Level 2", preload("res://Textures/cannon.png")))
	
	item_database.append(Item_Definition.new(16, 4, 1000, 1, "24 Pounder", "Medium naval weapon mounted on the ship. Level 3", preload("res://Textures/cannon.png")))
	
	item_database.append(Item_Definition.new(17, 4, 1500, 1, "32 Pounder", "Heavy naval weapon mounted on the ship. Level 4", preload("res://Textures/cannon.png")))
	
	item_database.append(Item_Definition.new(18, 3, 1500, 1, "Fishing rig", "Passively catches fish over time to replenish rations.", preload("res://Textures/fishing.png")))
	# generate ids for items automatically, this is a problem if im looking up items from previously known id
	# for i in range(item_database.size()):
	# 	var item = item_database[i] as Item_Definition
	# 	item.id = i
	
	print("Items created in database: ", item_database.size());

static func get_item_type_color(type: Item_Definition.Type) -> Color:
	match type:
		Item_Definition.Type.GOODS:
			return Color.ORANGE
		Item_Definition.Type.EQUIPMENT:
			return Color.CORNFLOWER_BLUE
		Item_Definition.Type.CONSUMABLE:
			return Color.GREEN
		Item_Definition.Type.PASSIVE:
			return Color.CYAN
		Item_Definition.Type.CANNON:
			return Color.RED
		_:
			return Color.WHITE
	

static func get_random_item_def() -> Item_Definition:
	var item = item_database.pick_random()
	return item

static func get_item_definition(_id: int) -> Item_Definition:
	for item in item_database:
		if item.id == _id:
			return item
	print("Item not found in database")
	return null

static func get_item_definition_from_name(_item_name: String) -> Item_Definition:
	for item in item_database:
		if item.item_name == _item_name:
			return item
	print("Item not found in database")
	return null
