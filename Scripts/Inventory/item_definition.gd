extends Node
class_name Item_Definition

var item_name: String
var max_stack: int
var icon: Texture2D

func _init(_item_name: String, _count: int, _icon: Texture2D):
	item_name = _item_name
	max_stack = _count
	icon = _icon
