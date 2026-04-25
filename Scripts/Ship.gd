extends RigidBody3D
class_name Ship

@onready var forward_arrow: Node3D = $forward_arrow
@onready var right_arrow: Node3D = $right_arrow
@onready var left_arrow: Node3D = $left_arrow
@onready var rotation_arrow: Node3D = $rotation_arrow

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

var side_to_side_speed := 0.0
var target_speed := 0.0
var yaw_deg := 0.0

var destroyed := false
var incapacitated := false
var sink_speed := 0.5

var accumulated_damage := 0.0
var damage_threshold := 1.0

var damage_sustained := 0.0
var crew_health := 1.0

var boarding_target: Ship
var boarded_ship: Ship
var boarding_ship: Ship

@export var boarding_area: Area3D
@export var arrow: PackedScene
@export var rigidbody: RigidBody3D = self
@export var loot: PackedScene
@export var floater: Node3D

@onready var canons_layout: Canons = $ship_pivot/Canons

@onready var ship_pivot: Node3D = $ship_pivot

@onready var gameManager: GameManager = get_node("/root/GameManager")

var attacker: Node3D
var in_combat: bool = false
var last_damage_time: int = 0
var out_of_combat_time: int = 20000 # 10 seconds without taking damage to be considered out of combat

@export_group("Signals")

signal gold_changed(amount: int, gained: bool)
signal crew_changed(amount: int, gained: bool)
signal supplies_changed(amount: int, gained: bool)
signal recieved_damage(amount: float, attacker: Node3D)
signal hit_points_changed(amount: float)
signal on_sink
signal boarding_target_changed(ship: Ship)
signal boarding_changed(ship: Ship)

signal boarded_changed(ship: Ship)

@export_group("World UI")
@onready var ship_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_ship
@onready var crew_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_crew
@onready var faction_texture: TextureRect = $world_bars/SubViewport/Control/faction_icon


func _ready():
	body_entered.connect(_on_body_entered)
	contact_monitor = true
	max_contacts_reported = 1
	
	set_faction_texture()

	connect("crew_changed", Callable(self , "_on_crew_changed"))
	connect("hit_points_changed", Callable(self , "_on_hit_points_changed"))
	# init values
	crew_healthbar.value = crew
	crew_healthbar.max_value = max_crew
	ship_healthbar.value = hit_points
	ship_healthbar.max_value = max_hit_points

func set_faction(_faction: FactionsData.Faction):
	faction = _faction
	set_faction_texture()

func _on_hit_points_changed(_amount: float):
	ship_healthbar.value = hit_points
	ship_healthbar.max_value = max_hit_points

func _on_crew_changed(_amount: int, _gained: bool):
	crew_healthbar.value = crew
	crew_healthbar.max_value = max_crew

func set_faction_texture():
	faction_texture.texture = FactionsData.get_faction_icon(faction)

func setup_guns():
	canons_layout.create_canons(int(float(guns) / 2.0), int(float(guns) / 2.0), int(float(guns) / 4.0))
# GET AND REMOVE STATS

func gain_gold(_gold: int):
	gold += _gold
	emit_signal("gold_changed", _gold, true)

func remove_gold(_gold: int):
	gold -= _gold
	emit_signal("gold_changed", _gold, false)

func gain_supplies(_supplies: int):
	supplies += _supplies
	emit_signal("supplies_changed", supplies, true)

func lose_supplies(_supplies: int):
	supplies -= _supplies
	emit_signal("supplies_changed", supplies, false)

func gain_crew(amount: int):
	gameManager.hud.ddd_label("%s CREW GAINED!" % str(amount), position)
	crew += amount
	crew = min(crew, max_crew)
	emit_signal("crew_changed", crew, true)

func kill_crew(amount: int):
	gameManager.hud.ddd_label("%s CREW LOST!" % str(amount), position)
	crew -= amount
	crew = max(crew, 0)
	emit_signal("crew_changed", crew, false)
	if crew <= 0:
		destroyed = true

# GET AND REMOVE STATS

func _process(_delta):
	if not destroyed:
		repair(_delta)

	ship_pivot.position = Vector3.ZERO
	# check if in combat
	if in_combat and Time.get_ticks_msec() - last_damage_time > out_of_combat_time:
		in_combat = false

func repair(_delta):
	if not in_combat and hit_points < max_hit_points:
		hit_points += _delta * 1.0 * (float(crew) / float(max_crew))
		emit_signal("hit_points_changed", hit_points)

func sink():
	spawn_loot()
	queue_free()
	emit_signal("on_sink")

var previous_speed
var previous_h_speed
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

	if previous_speed != target_speed:
		update_arrow(forward_arrow, floor(target_speed))
	if side_to_side_speed != previous_h_speed:
		if side_to_side_speed > 0:
			update_arrow(left_arrow, floor(side_to_side_speed))
			queue_free_children(right_arrow)
		elif side_to_side_speed < 0:
			update_arrow(right_arrow, abs(side_to_side_speed))
			queue_free_children(left_arrow)
		elif side_to_side_speed == 0:
			queue_free_children(right_arrow)
			queue_free_children(left_arrow)

	rotation_arrow.global_rotation_degrees = Vector3(0.0, yaw_deg, 0.0)
	#forward_arrow.scale.z = target_speed
	previous_speed = target_speed

	var forward = global_basis.z
	var right = global_basis.x
	#var wind_along_forward = gameManager.wind.direction.dot(forward)

	# incapacitated check
	var capable_speed = target_speed
	if incapacitated:
		capable_speed = 0.0

	actual_speed = capable_speed # + (wind_along_forward) # overriding wind effect (1.0 + wind_along_forward)
	side_to_side_speed = clamp(side_to_side_speed, -top_speed, top_speed)
	apply_central_force((right * side_to_side_speed) + (forward * actual_speed) * 5.0)
	# position += forward * actual_speed * delta
	# var new_yaw = lerp_angle(rotation.y, deg_to_rad(yaw_deg), delta)
	# rotation = Vector3(0, new_yaw, 0)
	
	var current_rotation = global_transform.basis.get_euler().y
	var target_rotation_rad = deg_to_rad(yaw_deg)
	var rotation_diff = angle_difference(current_rotation, target_rotation_rad)

	# Apply a turning force based on how far we need to turn
	# rotation = Vector3(0, new_yaw, 0)
	apply_torque(Vector3.UP * rotation_diff * agility / (target_speed + 1.0) * 10.0)

	#clamp to top speed
	var speed = linear_velocity.length()
	if speed > top_speed:
		linear_velocity = linear_velocity / speed * top_speed;
	
	#clamp torque
	var angular_speed = angular_velocity.length()
	if angular_speed > top_speed:
		angular_velocity = angular_velocity / angular_speed * agility;

func queue_free_children(node: Node3D):
	for child in node.get_children():
		child.queue_free()


func update_arrow(container: Node3D, count: int):
	queue_free_children(container)

	for i in range(count):
		var a = arrow.instantiate()
		container.add_child(a)
		a.position = Vector3(0, 0, i * 2.0)


func spawn_loot():
	var split = 5.0
	for i in split:
		var l: Loot = loot.instantiate()
		get_tree().current_scene.add_child(l)
		var offset = Vector3(randf_range(-1.0, 1.0) * 5.0, 0, randf_range(-1.0, 1.0) * 5.0)
		l.global_position = global_position + offset
		l.global_position.y = 0
		l.set_gold(gold / split)


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
	emit_signal("hit_points_changed", hit_points)
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
	for canon in canons_layout.canons_port:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func starboard_pitch(value: float):
	for canon in canons_layout.canons_starboard:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func bow_pitch(value: float):
	for canon in canons_layout.canons_bow:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func set_canon_pitch(value: float):
	for canon in canons_layout.canons_starboard:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)
	for canon in canons_layout.canons_port:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)
	for canon in canons_layout.canons_bow:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func shoot_port():
	shoot(canons_layout.canons_port)

func shoot_starboard():
	shoot(canons_layout.canons_starboard)

func shoot_bow():
	shoot(canons_layout.canons_bow)

func shoot(canons: Array[Canon]):
	if supplies <= 0:
		return
	for canon in canons:
		await get_tree().create_timer(randf() / 5.0).timeout
		if canon.shoot(attack, self , gameManager.audioManager):
			supplies -= 1
			

func active_starboard(value: bool):
	for canon in canons_layout.canons_starboard:
		canon.active = value

func active_port(value: bool):
	for canon in canons_layout.canons_port:
		canon.active = value


# Is getting boarded
func set_boarded(_boarding_ship: Ship):
	boarding_ship = _boarding_ship
	set_faction(_boarding_ship.faction)
	boarded_changed.emit(boarding_ship)

# Is getting unboarded
func set_unboarded():
	boarding_ship = null
	boarded_changed.emit(null)

# Is boarding
func board_ship():
	if not boarding_target:
		return
	if not boarding_target.can_be_boarded():
		return
	boarding_target.set_boarded(self )
	boarded_ship = boarding_target
	emit_signal("boarding_changed", boarding_target)

# Is unboarding
func unboard_ship():
	if not boarded_ship:
		return
	print("unboarding: ", boarded_ship);
	boarded_ship.set_unboarded()
	boarded_ship = null
	emit_signal("boarding_changed", null)

# set boarding target
func set_boarding_target(ship: Ship):
	boarding_target = ship
	emit_signal("boarding_target_changed", ship)
	print("boarding target set: ", ship);

# boarding condition
func can_be_boarded() -> bool:
	return true # incapacitated

# Collision damage
func _on_body_entered(body: Node) -> void:
	if body is not Ship:
		return
	var ship := body as Ship
	if ship:
		ship.damage(attack * hit_points / 10.0, global_position, self )
