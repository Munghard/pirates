extends Node
class_name Item_Definition

var id: String
var value: int
var item_name: String
var description: String
var max_stack: int
var icon: Texture2D
var type: Type

enum Type {GOODS, EQUIPMENT, CONSUMABLE, PASSIVE, CANNON}

const TYPENAMES = {
	Type.GOODS: "GOODS",
	Type.EQUIPMENT: "EQUIPMENT",
	Type.CONSUMABLE: "CONSUMABLE",
	Type.PASSIVE: "PASSIVE",
	Type.CANNON: "CANNON",
}

#_id: int = 0 , old prop, i generate ids now from index
func _init(_id: String, _type: int, _value: int, _max_stack: int, _item_name: String, _description: String, _icon: Texture2D):
	id = _id
	type = _type as Type
	value = _value
	max_stack = _max_stack
	item_name = _item_name
	description = _description
	icon = _icon
