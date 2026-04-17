class_name FactionStats

var attack: float
var defense: float
var speed: float
var guns: int
var max_hit_points: float
var gold: int
var supplies: int
var max_crew: int


func _init(_attack: float, _defense: float, max_speed: float, _guns: int, max_hp: float, _gold: int, _supplies: int, _max_crew: int):
	attack = _attack
	defense = _defense
	speed = max_speed
	guns = _guns
	max_hit_points = max_hp
	gold = _gold
	supplies = _supplies
	max_crew = _max_crew
