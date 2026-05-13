extends Node3D

class_name Loot

var item: InventoryItem
var dropped_by: Node3D
var recieved := false
var water: Water
var lifetime: float = 300.0

@export var loot_icon: TextureRect
@export var label_timer: Label

func _ready():
	$floater.water = water

func _process(delta):
	var t = int(lifetime)
	var minutes = t / 60.0
	var seconds = t % 60
	label_timer.text = "%02d:%02d" % [minutes, seconds]
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func setup_loot(_item: InventoryItem, _dropped_by: Node3D):
	item = _item if _item != null else roll_item()
	dropped_by = _dropped_by

	var item_def = Item_Database.get_item_definition(item.id)
	if item_def == null:
		return

	loot_icon.texture = item_def.icon


func _on_body_entered(body: Node) -> void:
	if body is not Ship:
		return
	var ship := body as Ship
	if ship and not recieved:
		if item == null:
			setup_loot(roll_item(), null)
		if ship.inventory.add_item(item):
			recieved = true
			queue_free()

func roll_item() -> InventoryItem:
	var _rolled_item_def = Item_Database.item_database[
			randi_range(0, Item_Database.item_database.size() - 1)
	]

	var _item = InventoryItem.new(
		_rolled_item_def.id,
		randi_range(1, _rolled_item_def.max_stack)
	)
	return _item
