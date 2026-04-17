extends RigidBody3D
class_name Ship

@onready var forward_arrow: Node3D = $forward_arrow

var ship_name := "Ship"
var faction: FactionsData.Faction = FactionsData.Faction.NAVY
var max_crew := 20
var crew := max_crew
var max_hit_points := 100.0
var hit_points := max_hit_points
var top_speed := 5.0
var agility := 1.0
var attack := 1.0
var defense := 1.0
var gold := 0
var supplies := 100
var guns := 1

var actual_speed := 0.0

var target_speed := 0.0
var yaw_deg := 0.0

var destroyed := false
var incapacitated := false
var sink_speed := 0.5

var accumulated_damage := 0.0
var damage_threshold := 1.0

var damage_sustained := 0.0
var crew_health := 1.0


@export var rigidbody: RigidBody3D = self
@export var loot: PackedScene
@export var floater: Node3D

@export var canons_port: Array[Canon]
@export var canons_starboard: Array[Canon]

@onready var ship_pivot: Node3D = $ship_pivot

@onready var gameManager: GameManager = get_node("/root/GameManager")

var attacker: Node3D
var in_combat: bool = false
var last_damage_time: int = 0
var out_of_combat_time: int = 20000 # 10 seconds without taking damage to be considered out of combat

signal recieved_gold(amount: int)
signal recieved_damage(amount: float, attacker: Node3D)
signal on_sink

@onready var ship_healthbar: Node3D = $world_bars/ship_healthbar
@onready var crew_healthbar: Node3D = $world_bars/crew_healthbar
@onready var faction_texture: Sprite3D = $world_bars/faction


func _ready():
	body_entered.connect(_on_body_entered)
	contact_monitor = true
	max_contacts_reported = 1
	canons_port = ship_pivot.canons_port
	canons_starboard = ship_pivot.canons_starboard
	set_faction_texture()

func set_faction_texture():
	faction_texture.texture = FactionsData.get_faction_icon(faction)

func gain_crew(amount: int):
	gameManager.hud.ddd_label("%s CREW GAINED!" % str(amount), position)
	crew += amount
	crew = min(crew, max_crew)

func kill_crew(amount: int):
	gameManager.hud.ddd_label("%s CREW LOST!" % str(amount), position)
	crew -= amount
	crew = max(crew, 0)
	crew_healthbar.scale.x = float(crew) / float(max_crew)
	if crew <= 0:
		destroyed = true

func _process(_delta):
	if not destroyed:
		repair(_delta)

	ship_healthbar.scale.x = hit_points / max_hit_points
	ship_pivot.position = Vector3.ZERO
	# check if in combat
	if in_combat and Time.get_ticks_msec() - last_damage_time > out_of_combat_time:
		in_combat = false

func repair(_delta):
	if not in_combat and hit_points < max_hit_points:
		hit_points += _delta * 1.0 * (float(crew) / float(max_crew))

func sink():
	spawn_loot()
	queue_free()
	emit_signal("on_sink")

func _physics_process(_delta: float) -> void:
	if destroyed:
		if floater:
			floater.queue_free()
		freeze = true
		# apply_central_force(Vector3.DOWN * sink_speed * mass)
		position += -basis.y * sink_speed * _delta
		# apply_torque(Vector3.UP * 5.0 * mass)
		rotation.y += _delta # radians per second
		if ship_pivot.global_position.y <= -5.0:
			sink()
		return

	rotation.x = lerp_angle(rotation.x, 0, _delta)
	rotation.z = lerp_angle(rotation.z, 0, _delta)
	forward_arrow.scale.z = target_speed
	# position.y = gameManager.water.get_height_at(position)

	var forward = global_basis.z
	var wind_along_forward = gameManager.wind.direction.dot(forward)

	# incapacitated check
	var capable_speed = target_speed
	if incapacitated:
		capable_speed = 0.0

	actual_speed = capable_speed * (1.0 + wind_along_forward)

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
	var split = 5.0
	for i in split:
		var l: Loot = loot.instantiate()
		get_tree().current_scene.add_child(l)
		var offset = Vector3(randf_range(-1.0, 1.0) * 5.0, 0, randf_range(-1.0, 1.0) * 5.0)
		l.global_position = global_position + offset
		l.global_position.y = 0
		l.set_gold(gold / split)


func give_loot(_gold: int):
	gold += _gold
	emit_signal("recieved_gold", _gold)


func damage(_damage: float, _position: Vector3, _attacker: Node3D):
	# gameManager.hud.selected_ship = self
	accumulated_damage += _damage
	if accumulated_damage >= damage_threshold:
		var s = "%.1f" % accumulated_damage
		gameManager.hud.ddd_label(s, _position)
		accumulated_damage = 0

	attacker = _attacker
	hit_points = clamp(hit_points - (_damage / defense), 0, max_hit_points)
	emit_signal("recieved_damage", (_damage / defense), _attacker)
	in_combat = true
	last_damage_time = Time.get_ticks_msec()

	if hit_points <= 0 and not incapacitated:
		incapacitated = true
		gameManager.hud.ddd_label("INCAPACITATED!", position)
	
	if incapacitated:
		damage_sustained += _damage
		while damage_sustained >= crew_health:
			damage_sustained -= crew_health
			kill_crew(1)
		

func port_pitch(value: float):
	for canon in canons_port:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func starboard_pitch(value: float):
	for canon in canons_starboard:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func set_canon_pitch(value: float):
	for canon in canons_starboard:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)
	for canon in canons_port:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func shoot_port():
	shoot(canons_port)

func shoot_starboard():
	shoot(canons_starboard)

func shoot(canons: Array[Canon]):
	if supplies <= 0:
		return
	var guns_fired = 0
	for canon in canons:
		if guns_fired >= guns:
			break
		await get_tree().create_timer(randf() / 10.0).timeout
		if canon.shoot(attack, self ):
			supplies -= 1
			guns_fired += 1

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
