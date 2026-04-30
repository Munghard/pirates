extends Node
class_name Item_Definition

var id: int
var value: int
var item_name: String
var max_stack: int
var icon: Texture2D

func _init(_id: int, _value: int, _item_name: String, _count: int, _icon: Texture2D):
	id = _id
	value = _value
	item_name = _item_name
	max_stack = _count
	icon = _icon
