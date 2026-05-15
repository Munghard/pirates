extends Node

class_name Port_Data

func _init(_faction: FactionsData.Faction, _nation: FactionsData.Nation, _port_name: String, _global_position: Vector3, _inventory: Array):
	faction = _faction
	nation = _nation
	port_name = _port_name
	global_position = _global_position
	inventory = _inventory

var port_name: String
var faction: FactionsData.Faction
var nation: FactionsData.Nation
var global_position: Vector3
var inventory: Array


static func from_dict_array(data_array: Array) -> Array[Port_Data]:
	var ports: Array[Port_Data] = []
	for data in data_array:
		ports.append(from_dict_(data))
	return ports

static func from_dict_(data: Dictionary) -> Port_Data:
	var _faction: FactionsData.Faction = data.get("faction", FactionsData.Faction.NONE)
	var _nation: FactionsData.Nation = data.get("nation", FactionsData.Nation.ENGLAND)
	var pos_data = data.get("position", {"x": 0, "y": 0, "z": 0})

	var _position = Vector3(
		pos_data.get("x", 0),
		pos_data.get("y", 0),
		pos_data.get("z", 0)
	)
	var p = Port_Data.new(
		_faction,
		_nation,
		data.get("name", ""),
		_position,
		data.get("inventory", [])
	)
	return p
