class_name ShipStats

var attack: float
var defense: float
var speed: float
var max_hit_points: float
var gold: int
var max_crew: int


func _init(_attack: float, _defense: float, max_speed: float, max_hp: float, _gold: int, _max_crew: int):
	attack = _attack
	defense = _defense
	speed = max_speed
	max_hit_points = max_hp
	gold = _gold
	max_crew = _max_crew
