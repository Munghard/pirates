extends Node
class_name InventoryItem

var unique_id: int
var id: String
var stack: int


func _init(_id: String, _count: int):
	unique_id = ResourceUID.create_id()
	id = _id
	stack = _count