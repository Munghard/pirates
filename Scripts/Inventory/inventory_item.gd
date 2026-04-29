extends Node
class_name InventoryItem

var item_name: String
var stack: int


func _init(_item_name: String, _count: int):
	item_name = _item_name
	stack = _count