extends RigidBody3D
class_name Ship

@onready var navigation_markers: Node3D = $Navigation_markers
@onready var forward_arrow: Node3D = $Navigation_markers/forward_arrow
@onready var backward_arrow: Node3D = $Navigation_markers/backward_arrow
@onready var right_arrow: Node3D = $Navigation_markers/right_arrow
@onready var left_arrow: Node3D = $Navigation_markers/left_arrow
@onready var rotation_arrow: Node3D = $Navigation_markers/rotation_arrow
@onready var rot_arrow: Sprite3D = $Navigation_markers/rotation_arrow/arrow

var ship_name := "Ship"
var faction: FactionsData.Faction = FactionsData.Faction.NAVY
var nation: FactionsData.Nation = FactionsData.Nation.ENGLAND
var inventory: Inventory
var level := 1
var max_crew := 20
var crew := max_crew
var max_hit_points := 100.0
var hit_points := max_hit_points
var top_speed := 5.0
var agility := 1.0
var attack := 1.0
var defense := 1.0
var gold := 0
var sunk := false
var morale := 100.0

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
var crew_health := 20.0

var boarding_target: Ship
var boarded_ship: Ship
var boarded_by: Ship

var controlled_ships: Array[Ship] = []

@export var boarding_area: Area3D
@export var arrow_scene: PackedScene
@export var rigidbody: RigidBody3D = self
@export var floater: Node3D
@export var loot: PackedScene

@onready var cannons_layout: Cannons = $ship_pivot/Cannons

@onready var ship_pivot: Node3D = $ship_pivot

@onready var gameManager: GameManager = get_node("/root/GameManager")

var attacker: Node3D
var in_combat: bool = false
var last_damage_time: int = 0
var out_of_combat_time: int = 20000 # 10 seconds without taking damage to be considered out of combat
var recovery_progress := 1.0

var dockable_port: Port
var docked: Port

@export_group("Signals")
signal docked_changed(port: Port)
signal dockable_port_changed(port: Port)

signal gold_changed(amount: int)
signal gold_gained(amount: int)
signal gold_lost(amount: int)

signal crew_changed(amount: int)
signal crew_gained(amount: int)
signal crew_lost(amount: int)

signal morale_changed(current: float)
signal morale_gained(current: float)
signal morale_lost(current: float)

signal hit_points_changed(amount: float)
signal recovery_changed(time: float)
signal recieved_damage(amount: float, attacker: Node3D)
signal on_sink
signal on_destroyed(destroyer: Node3D)
signal boarding_target_changed(ship: Ship)
signal boarding_changed(ship: Ship)

signal boarded_changed(ship: Ship)

@export_group("World UI")
@onready var world_bars: Node3D = $world_bars
@onready var ship_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_ship
@onready var crew_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_crew
@onready var recovery_healthbar: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_recovery
@onready var faction_texture: TextureRect = $world_bars/SubViewport/Control/faction_icon
@onready var star_container: Control = $world_bars/SubViewport/Control/star_container


func _ready():
	#body_entered.connect(_on_body_entered)
	contact_monitor = true
	max_contacts_reported = 1
	
	set_faction_texture()
	set_stars(level)

	connect("crew_changed", Callable(self , "_on_crew_changed"))
	connect("hit_points_changed", Callable(self , "_on_hit_points_changed"))
	connect("recovery_changed", Callable(self , "_on_recovery_changed"))
	# init values
	crew_healthbar.value = crew
	crew_healthbar.max_value = max_crew
	ship_healthbar.value = hit_points
	ship_healthbar.max_value = max_hit_points
	recovery_healthbar.value = 1.0
	recovery_healthbar.max_value = 1.0

func setup_inventory():
	inventory = Inventory.new(self , gameManager, 16, ship_name + " cargo")
	inventory.inventory_changed.connect(_on_inventory_changed)
	
	setup_cannons()

func _on_inventory_changed(_inventory: Inventory):
	setup_cannons()

func set_docked(port: Port): # port null means not docked
	docked = port
	docked_changed.emit(port)

func set_dockable_port(port: Port):
	dockable_port = port
	dockable_port_changed.emit(port)

func set_stars(amount: int):
	for child in star_container.get_children():
		child.queue_free()
	var star_ui = preload("res://UI/star.tscn")
	for i in range(amount):
		var star = star_ui.instantiate()
		star_container.add_child(star)

func set_faction(_faction: FactionsData.Faction):
	faction = _faction
	set_faction_texture()

func _on_recovery_changed(_progress: float):
	if not recovery_healthbar:
		return
	recovery_healthbar.value = _progress

func _on_hit_points_changed(_hp: float):
	if not ship_healthbar:
		return
	ship_healthbar.value = hit_points
	ship_healthbar.max_value = max_hit_points

func _on_crew_changed(_crew: int):
	if not crew_healthbar:
		return
	crew_healthbar.value = crew
	crew_healthbar.max_value = max_crew

func set_faction_texture():
	faction_texture.texture = FactionsData.get_faction_icon(faction)

var previous_cannons = 0

func setup_cannons():
	var total = inventory.item_amount(2)

	if total == previous_cannons:
		return

	previous_cannons = total

	# weights
	var bow_weight = 0.15
	var side_weight = 0.35
	#var stern_weight = 0.15

	var bow = roundi(total * bow_weight)
	var port = roundi(total * side_weight)
	var starboard = roundi(total * side_weight)

	# give remaining to stern
	#var stern = total - bow - port - starboard

	cannons_layout.create_canons(
		port,
		starboard,
	#	stern,
		bow,
		trajectories
	)

# GET AND REMOVE STATS
func gain_morale(_amount: float):
	morale = clampf(morale + _amount, 0.0, 100.0)
	emit_signal("morale_changed", morale)
	emit_signal("morale_gained", _amount)

func lose_morale(_amount: float):
	morale = clampf(morale - _amount, 0.0, 100.0)
	emit_signal("morale_changed", morale)
	emit_signal("morale_lost", _amount)

func has_gold(_gold: int) -> bool:
	return gold >= _gold
	
func gain_gold(_gold: int):
	gold += _gold
	emit_signal("gold_changed", gold)
	emit_signal("gold_gained", _gold)

func remove_gold(_gold: int):
	gold -= _gold
	emit_signal("gold_changed", gold)
	emit_signal("gold_lost", _gold)

func gain_crew(amount: int):
	if crew >= max_crew:
		return
	#gameManager.hud.ddd_label("%s CREW GAINED!" % str(amount), position)
	crew += amount
	crew = min(crew, max_crew)
	emit_signal("crew_gained", amount)
	emit_signal("crew_changed", crew)

func kill_crew(amount: int):
	if crew <= 0:
		return
	#gameManager.hud.ddd_label("%s CREW LOST!" % str(amount), position)
	crew -= amount
	crew = max(crew, 0)
	emit_signal("crew_lost", amount)
	emit_signal("crew_changed", crew)
	#if crew <= 0:
		#destroy_ship(attacker)


func destroy_ship(destroyer: Node3D):
	if destroyed:
		return
	on_destroyed.emit(destroyer)
	destroyed = true
	navigation_markers.queue_free()
	world_bars.queue_free()

# ================================================================================================================
# CREW RATIONS
# ================================================================================================================

var ration_interval := 30000 # 30 seconds
var last_ration := 0.0

func ration_drain():
	last_ration = Time.get_ticks_msec()
	if inventory.has_item(0, 1):
		inventory.consume_item(0, 1)
	else:
		kill_crew(1)

# ================================================================================================================
# MORALE
# ================================================================================================================

var morale_interval := 10000 # 30 seconds
var last_morale := 0.0

func morale_drain():
	last_morale = Time.get_ticks_msec()
	if inventory.has_item(1, 1):
		inventory.consume_item(1, 1)
	else:
		lose_morale(1.0)


# GET AND REMOVE STATS
func _process(_delta):
	ship_pivot.position = Vector3.ZERO
	var elapsed_since_damage := Time.get_ticks_msec() - last_damage_time
	var elapsed_since_ration := Time.get_ticks_msec() - last_ration
	var elapsed_since_morale := Time.get_ticks_msec() - last_morale

	if not docked:
		if elapsed_since_ration > ration_interval:
			ration_drain()
		
		if elapsed_since_morale > morale_interval:
			morale_drain()
	else:
		gain_morale(_delta)


	if destroyed:
		return
	if not destroyed and crew > 0:
		recovery_progress = clamp(elapsed_since_damage / float(out_of_combat_time), 0.0, 1.0)
		repair(_delta)

	# check if in combat
	emit_signal("recovery_changed", recovery_progress)
	if in_combat and elapsed_since_damage > out_of_combat_time:
		in_combat = false

func repair(_delta):
	if not in_combat and hit_points < max_hit_points:
		hit_points += _delta * 1.0 * (float(crew) / float(max_crew))
		emit_signal("hit_points_changed", hit_points)

func sink():
	spawn_loot()
	queue_free()
	emit_signal("on_sink")

func world_edge_push():
	var world_size := gameManager.world.terrain.world_size * gameManager.world.terrain.tile_size
	var pos := Vector2(global_position.x, global_position.z)
	# check if outside bounds
	if pos.x < 0 or pos.x > world_size.x or pos.y < 0 or pos.y > world_size.y:
		var center := gameManager.world.terrain.terrain_world_size / 2.0
		var dir_to_center := (center - pos).normalized()
		
		# get target yaw (Y rotation)
		yaw_deg = rad_to_deg(atan2(dir_to_center.x, dir_to_center.y))
		
var previous_speed
var previous_h_speed

func _physics_process(_delta: float) -> void:
	if not global_basis.x.is_finite() or not global_basis.y.is_finite() or not global_basis.z.is_finite():
		return
	world_edge_push()

	if destroyed:
		if floater:
			floater.queue_free()
		freeze = true
		# apply_central_force(Vector3.DOWN * sink_speed * mass)
		position += -basis.y * sink_speed * _delta
		# apply_torque(Vector3.UP * 5.0 * mass)
		rotation.y += _delta # radians per second
		if ship_pivot.global_position.y <= -5.0 and not sunk:
			sink()
		return

	rotation.x = lerp_angle(rotation.x, 0, _delta)
	rotation.z = lerp_angle(rotation.z, 0, _delta)

	if previous_speed != target_speed:
		queue_free_children(forward_arrow)
		queue_free_children(backward_arrow)

		if target_speed > 0:
			update_arrow(forward_arrow, round(target_speed))
		elif target_speed < 0:
			update_arrow(backward_arrow, round(abs(target_speed)))
	if previous_h_speed != side_to_side_speed:
		queue_free_children(left_arrow)
		queue_free_children(right_arrow)

		if side_to_side_speed > 0:
			update_arrow(left_arrow, round(side_to_side_speed))
		elif side_to_side_speed < 0:
			update_arrow(right_arrow, round(abs(side_to_side_speed)))

	rotation_arrow.global_rotation_degrees = Vector3(0.0, yaw_deg, 0.0)
	#forward_arrow.scale.z = target_speed
	previous_speed = target_speed
	previous_h_speed = side_to_side_speed
	
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
	var t = clamp(abs(rotation_diff) / PI, 0.0, 1.0)
	rot_arrow.modulate.a = t

	# Apply a turning force based on how far we need to turn
	# rotation = Vector3(0, new_yaw, 0)
	var speed_factor = max(abs(capable_speed), 1.0)
	apply_torque(Vector3.UP * rotation_diff * agility / speed_factor * 10.0)

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
		var a = arrow_scene.instantiate() as Sprite3D
		container.add_child(a)
		a.position = Vector3(0, 0, i * 2.0)
		
		a.modulate.a = 1.0 / (i + 1)

func spawn_loot():
	var valid_items: Array = []

	# collect only real items
	for item in inventory.items:
		if item != null:
			valid_items.append(item)

	# spawn loot from valid items
	for item in valid_items:
		var l: Loot = loot.instantiate()
		gameManager.world.add_child(l)

		var radius = 5.0
		var angle = randf() * TAU
		var distance = sqrt(randf()) * radius

		var offset = Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)

		l.global_position = global_position + offset
		l.global_position.y = 0

		l.setup_loot(item, self )

	# clear inventory AFTER
	inventory.clear()


func damage(_damage: float, _multiplier: float, _position: Vector3, _attacker: Node3D):
	# gameManager.hud.selected_ship = self
	attacker = _attacker
	in_combat = true
	last_damage_time = Time.get_ticks_msec()
	
	var multiplied_damage = _damage * _multiplier
	
	var color = Color.WHITE
	if _multiplier < 0.5:
		color = Color.GRAY
	elif _multiplier > 1.0:
		color = Color.YELLOW
	
	accumulated_damage += multiplied_damage

	if accumulated_damage >= damage_threshold:
		var s = "%.1f" % accumulated_damage
		gameManager.hud.ddd_label(s, _position, color)
		accumulated_damage = 0

	hit_points = clamp(hit_points - (multiplied_damage / defense), 0, max_hit_points)
	emit_signal("recieved_damage", (multiplied_damage / defense), _attacker)
	emit_signal("hit_points_changed", hit_points)

	if crew <= 0 and not incapacitated:
		incapacitated = true
		gameManager.hud.ddd_label("INCAPACITATED!", position, Color.CYAN)
	
	if hit_points <= 0:
		destroy_ship(_attacker)
		#destroyed = true

	damage_sustained += multiplied_damage
	while damage_sustained >= crew_health:
		damage_sustained -= crew_health
		kill_crew(1)

func port_pitch(value: float):
	for canon in cannons_layout.cannons_port:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func starboard_pitch(value: float):
	for canon in cannons_layout.cannons_starboard:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func bow_pitch(value: float):
	for canon in cannons_layout.cannons_bow:
		await get_tree().create_timer(randf() / 10.0).timeout
		canon.pitch += value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func set_canon_pitch(value: float):
	for canon in cannons_layout.cannons_starboard:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)
	for canon in cannons_layout.cannons_port:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)
	for canon in cannons_layout.cannons_bow:
		canon.pitch = value
		canon.pitch = clampf(canon.pitch, -25.0, 25.0)

func shoot_port():
	shoot(cannons_layout.cannons_port)

func shoot_starboard():
	shoot(cannons_layout.cannons_starboard)

func shoot_bow():
	shoot(cannons_layout.cannons_bow)

func shoot(canons: Array[Cannon]):
	# id 3 is cannonball
	if not inventory.has_item(3, 1):
		gameManager.hud.ddd_label("No cannon balls", global_position, Color.RED)
		return
	for canon in canons:
		if is_inside_tree():
			await get_tree().create_timer(randf() / 5.0).timeout
		if canon.shoot(attack, self , gameManager.audioManager):
			inventory.consume_item(3, 1)

var trajectories := false

func toggle_cannons_trajectory():
	trajectories = !trajectories
	active_port(trajectories)
	active_starboard(trajectories)
	active_bow(trajectories)

func active_starboard(value: bool):
	for canon in cannons_layout.cannons_starboard:
		canon.active = value

func active_port(value: bool):
	for canon in cannons_layout.cannons_port:
		canon.active = value

func active_bow(value: bool):
	for canon in cannons_layout.cannons_bow:
		canon.active = value


# Is getting boarded
func set_boarded(by: Ship):
	boarded_by = by
	set_faction(by.faction)
	boarded_changed.emit(by)

# Is getting unboarded
func set_unboarded():
	boarded_by = null
	boarded_changed.emit(null)

# Is boarding
func board_ship(ship: Ship):
	if not ship:
		return
	if not ship.can_be_boarded():
		return
	ship.set_boarded(self )
	boarded_ship = ship
	controlled_ships.append(ship)
	emit_signal("boarding_changed", ship)

# Is unboarding
func unboard_ship(ship: Ship):
	print("unboarding: ", ship);
	if not ship:
		return
	ship.set_unboarded()
	controlled_ships.erase(ship)
	ship = null
	emit_signal("boarding_changed", null)

# set boarding target
func set_boarding_target(ship: Ship):
	boarding_target = ship
	emit_signal("boarding_target_changed", ship)
	print("boarding target set: ", ship);

# boarding condition
func can_be_boarded() -> bool:
	return incapacitated and boarded_by == null

# Collision damage
func _on_body_entered(body: Node) -> void:
	var _multiplier = 1.0
	if body is not Ship:
		return
	var ship := body as Ship
	if ship:
		ship.damage(attack * hit_points / 10.0, _multiplier, global_position, self )
