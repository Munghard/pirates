extends Node
class_name Item_Database

static var item_database: Array[Item_Definition]

func _ready():
	create_items()

func create_items():
	# ID, VALUE, NAME, MAX_STACK, TEXTURE
	item_database.append(Item_Definition.new(0, 5, "Rations", 50, preload("res://Textures/barrel.png")))
	item_database.append(Item_Definition.new(1, 10, "Rum", 50, preload("res://Textures/brandy-bottle.png")))
	item_database.append(Item_Definition.new(2, 20, "Cannons", 50, preload("res://Textures/cannon.png")))
	item_database.append(Item_Definition.new(3, 5, "Cannon balls", 50, preload("res://Textures/ball-pyramid.png")))
	item_database.append(Item_Definition.new(4, 1, "Ropes", 50, preload("res://Textures/rope-coil.png")))
	item_database.append(Item_Definition.new(5, 5, "Navigation equipment", 50, preload("res://Textures/sextant.png")))
	item_database.append(Item_Definition.new(6, 2, "Documents", 50, preload("res://Textures/tied-scroll.png")))
	item_database.append(Item_Definition.new(7, 2, "Shackles", 50, preload("res://Textures/handcuffs.png")))
	item_database.append(Item_Definition.new(8, 5, "Firearms", 50, preload("res://Textures/blunderbuss.png")))
	item_database.append(Item_Definition.new(9, 5, "Fishing gear", 50, preload("res://Textures/fishing-net.png")))
	item_database.append(Item_Definition.new(10, 1, "Gold", 500, preload("res://Textures/coins.png")))
	
	print("Items created in database: ", item_database.size());


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
