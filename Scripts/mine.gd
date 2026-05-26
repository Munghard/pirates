extends Node3D
class_name Mine

@export var item_ids := ["wood", "ore", "fiber"]
@export var item_id := "wood"
@export var duration := 10.0
var elapsed := 0.0
var progress := 0.0

@export var pb: ProgressBar

var player_ship: PlayerShip = null
var mining := false

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

	item_id = item_ids.pick_random()
	pb.value = progress * 100
	
func _on_body_entered(body: Node3D):
	var player = body as PlayerShip
	if player:
		player_ship = player
		if not mining:
			start_mining()
			player_ship.gameManager.hud.ddd_label("Started mining", player_ship.global_position, Color.GREEN)

func _on_body_exited(body: Node3D):
	var player = body as PlayerShip
	if player and player == player_ship:
		player_ship.gameManager.hud.ddd_label("Stopped mining", player_ship.global_position, Color.RED)
		player_ship = null
		mining = false

func start_mining():
	mining = true

func _process(delta):
	if not mining or player_ship == null:
		return

	elapsed += delta
	progress = elapsed / duration

	pb.value = progress * 100 # assuming ProgressBar is 0–100

	if elapsed >= duration:
		elapsed = 0.0

		var mined_item = InventoryItem.new(item_id, 1 * player_ship.mining_efficiency)
		player_ship.inventory.add_item(mined_item)
