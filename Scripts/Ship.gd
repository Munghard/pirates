extends RigidBody3D
class_name Ship

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
var yaw_deg := 0.0

var destroyed := false
var sink_speed := 0.5

var accumulated_damage := 0.0
var damage_threshold := 1.0

@export var loot: PackedScene

@export var canons_port: Array[Canon]
@export var canons_starboard: Array[Canon]

@onready var ship_pivot = $ship_pivot

var attacker: Node3D

signal recieved_gold(amount: int)
signal recieved_damage(amount: float, attacker: Node3D)

@onready var healthbar: Node3D = $healthbar


func _ready():
	body_entered.connect(_on_body_entered)
	contact_monitor = true
	max_contacts_reported = 1
	canons_port = ship_pivot.canons_port
	canons_starboard = ship_pivot.canons_starboard

func _process(_delta):
	if not destroyed:
		repair(_delta)
	healthbar.scale.x = hit_points / max_hit_points

func repair(_delta):
	if hit_points < max_hit_points:
		hit_points += _delta * 0.1

func sink():
	spawn_loot()
	queue_free()

func _physics_process(_delta: float) -> void:
	if destroyed:
		apply_central_force(Vector3.UP * -sink_speed * mass)
		# position += -basis.y * sink_speed * delta
		apply_torque(Vector3.UP * 5.0 * mass)
		# rotation.y += delta # radians per second
		if global_position.y <= -5.0:
			sink()
		return

	rotation.x = lerp_angle(rotation.x, 0, _delta)
	rotation.z = lerp_angle(rotation.z, 0, _delta)
	forward_arrow.scale.z = target_speed
	# position.y = GM.water.get_height_at(position)

	var forward = global_basis.z
	var wind_along_forward = GM.wind.direction.dot(-forward)

	actual_speed = target_speed * (1.0 + wind_along_forward)

	apply_central_force(forward * actual_speed * mass * 5.0)
	# position += forward * actual_speed * delta
	# var new_yaw = lerp_angle(rotation.y, deg_to_rad(yaw_deg), delta)
	# rotation = Vector3(0, new_yaw, 0)
	
	var current_rotation = global_transform.basis.get_euler().y
	var target_rotation_rad = deg_to_rad(yaw_deg)
	var rotation_diff = angle_difference(current_rotation, target_rotation_rad)

	# Apply a turning force based on how far we need to turn
	# rotation = Vector3(0, new_yaw, 0)
	apply_torque(Vector3.UP * rotation_diff * agility * mass / (target_speed + 1.0) * 10.0)

	#clamp to top speed
	var speed = linear_velocity.length()
	if speed > top_speed:
		linear_velocity = linear_velocity / speed * top_speed;
	
	#clamp torque
	var angular_speed = angular_velocity.length()
	if angular_speed > top_speed:
		angular_velocity = angular_velocity / angular_speed * agility;
	
	
func spawn_loot():
	var l: Loot = loot.instantiate()
	get_tree().current_scene.add_child(l)
	l.global_position = global_position
	l.global_position.y = 0
	l.set_gold(gold)


func give_loot(_gold: int):
	gold += _gold
	emit_signal("recieved_gold", _gold)
	print("Recieved: ", gold);


func damage(_damage: float, _position: Vector3, _attacker: Node3D):
	# GM.hud.selected_ship = self
	accumulated_damage += _damage
	if accumulated_damage >= damage_threshold:
		var s = "%.1f" % accumulated_damage
		GM.hud.ddd_label(s, _position)
		accumulated_damage = 0

	attacker = _attacker
	hit_points = clamp(hit_points - (_damage / defense), 0, max_hit_points)
	emit_signal("recieved_damage", (_damage / defense), _attacker)

	if hit_points <= 0 and not destroyed:
		destroyed = true
		GM.hud.ddd_label("SUNK!", position)


func port_pitch(value: float):
	for canon in canons_port:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, 0, 25.0)

func starboard_pitch(value: float):
	for canon in canons_starboard:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, 0, 25.0)

func set_canon_pitch(value: float):
	for canon in canons_starboard:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, 0, 25.0)
	for canon in canons_port:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, 0, 25.0)

func shoot_port():
	for canon in canons_port:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.shoot(attack, self )

func shoot_starboard():
	for canon in canons_starboard:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.shoot(attack, self )

func active_starboard(value: bool):
	for canon in canons_starboard:
		canon.active = value

func active_port(value: bool):
	for canon in canons_port:
		canon.active = value

func _on_body_entered(body: Node) -> void:
	if body is not Ship:
		return
	var ship := body as Ship
	if ship:
		ship.damage(attack * hit_points / 10.0, global_position, self )
