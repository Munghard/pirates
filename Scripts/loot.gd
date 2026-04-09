extends Node3D

class_name Loot

var gold := 0
var recieved := false

func set_gold(_gold: int):
	gold = randi_range(0, _gold)

func _ready():
	if gold == 0:
		gold = randi_range(0, 50)


func _on_body_entered(body: Node) -> void:
	if body is not Ship:
		return
	var ship := body as Ship
	if ship and not recieved:
		recieved = true
		ship.give_loot(gold)
		queue_free()
