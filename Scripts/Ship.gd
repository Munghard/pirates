extends Node3D
class_name Ship

@onready var gameManager: GameManager = get_node("/root/World")
@onready var forward_arrow: Node3D = $forward_arrow


var ship_name := "Ship"
var max_hit_points := 100.0
var hit_points := max_hit_points
var top_speed := 5.0
var agility := 1.0
var attack := 1.0
var defense := 1.0
var gold := 0

var actual_speed := 0.0

var target_speed := 0.0
var yaw := 0.0

var destroyed := false
var sink_speed := 0.5

var accumulated_damage := 0.0
var damage_threshold := 1.0

@export var loot: PackedScene

@export var canons_port: Array[Canon]
@export var canons_starboard: Array[Canon]

signal recieved_gold(amount: int)

func _process(delta: float) -> void:
	if destroyed:
		position += -basis.y * sink_speed * delta
		rotation.y += delta # radians per second
		if global_position.y <= -5.0:
			var l: Loot = loot.instantiate()
			get_tree().current_scene.add_child(l)
			l.global_position = global_position
			l.global_position.y = 0
			l.set_gold(gold)
			queue_free()
		return

	forward_arrow.scale.z = target_speed
	position.y = gameManager.water.get_height_at(position)

	var forward = basis.z
	var wind_along_forward = gameManager.wind.direction.dot(-forward)

	actual_speed = target_speed + wind_along_forward

	position += forward * actual_speed * delta
	var new_yaw = lerp_angle(rotation.y, deg_to_rad(yaw), delta)
	rotation = Vector3(0, new_yaw, 0)

func give_loot(_gold: int):
	gold += _gold
	emit_signal("recieved_gold", _gold)
	print("Recieved: ", gold);


func damage(_damage: float, _position: Vector3):
	gameManager.hud.hovered_ship = self
	accumulated_damage += _damage
	if accumulated_damage >= damage_threshold:
		var s = "%.1f" % accumulated_damage
		ddd_label(s, _position)
		accumulated_damage = 0

	hit_points = clamp(hit_points - (_damage / defense), 0, max_hit_points)
	if hit_points <= 0:
		destroyed = true
		ddd_label("SUNK!", position)

func ddd_label(text: String, _position: Vector3):
	var label3d = Label3D.new()
	get_tree().current_scene.add_child(label3d)
	label3d.text = text
	label3d.font_size = 160
	label3d.no_depth_test = true
	label3d.global_position = _position
	label3d.billboard = true
	get_tree().create_tween().tween_property(label3d, "global_position", label3d.global_position + Vector3.UP * 10.0, 5.0)

	await get_tree().create_timer(5.0).timeout
	label3d.queue_free()

func port_pitch(value: float):
	for canon in canons_port:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value

func starboard_pitch(value: float):
	for canon in canons_starboard:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value

func shoot_port():
	for canon in canons_port:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.shoot(attack)

func shoot_starboard():
	for canon in canons_starboard:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.shoot(attack)
