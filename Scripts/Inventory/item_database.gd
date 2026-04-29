extends Node
class_name Item_Database

static var item_database: Array[Item_Definition]

func _ready():
	create_items()

func create_items():
	item_database.append(Item_Definition.new("Rations", 50, preload("res://Textures/barrel.png")))
	item_database.append(Item_Definition.new("Rum", 50, preload("res://Textures/brandy-bottle.png")))
	item_database.append(Item_Definition.new("Cannons", 50, preload("res://Textures/cannon.png")))
	item_database.append(Item_Definition.new("Cannon balls", 50, preload("res://Textures/ball-pyramid.png")))
	item_database.append(Item_Definition.new("Ropes", 50, preload("res://Textures/rope-coil.png")))
	item_database.append(Item_Definition.new("Navigation equipment", 50, preload("res://Textures/sextant.png")))
	item_database.append(Item_Definition.new("Documents", 50, preload("res://Textures/tied-scroll.png")))
	item_database.append(Item_Definition.new("Shackles", 50, preload("res://Textures/handcuffs.png")))
	item_database.append(Item_Definition.new("Firearms", 50, preload("res://Textures/blunderbuss.png")))
	
	print("Items created in database: ", item_database.size());


static func get_item_definition(_item_name: String) -> Item_Definition:
	for item in item_database:
		if item.item_name == _item_name:
			return item
	print("Item not found in database")
	return null
