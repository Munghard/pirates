extends Node

class_name Port_Data

func _init(_faction: FactionsData.Faction, _nation: FactionsData.Nation, _port_name: String, _hit_points: float, _max_hitpoints: float, _max_crew: int, _crew: int, _global_position: Vector3, _inventory: Array, _cannons_unlocked: int, _market_opened: bool):
	faction = _faction
	nation = _nation
	port_name = _port_name
	hit_points = _hit_points
	max_hit_points = _max_hitpoints
	max_crew = _max_crew
	crew = _crew
	global_position = _global_position
	inventory = _inventory
	cannons_unlocked = _cannons_unlocked
	market_opened = _market_opened

var port_name: String
var faction: FactionsData.Faction
var nation: FactionsData.Nation
var max_hit_points: float
var hit_points: float
var max_crew: int
var crew: int
var global_position: Vector3
var inventory: Array
var cannons_unlocked: int
var market_opened: bool


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
	var _cannons_unlocked: int = data.get("cannons_unlocked", 0)
	var p = Port_Data.new(
		_faction,
		_nation,
		data.get("name", ""),
		data.get("max_hit_points", 100.0),
		data.get("hit_points", 100.0),
		data.get("max_crew", 100),
		data.get("crew", 100),
		_position,
		data.get("inventory", []),
		_cannons_unlocked,
		data.get("market_opened", false)
	)
	return p
