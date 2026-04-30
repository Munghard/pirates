extends Node
class_name InventoryItem

var id: int
var stack: int


func _init(_id: int, _count: int):
	id = _id
	stack = _count