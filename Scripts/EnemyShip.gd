extends Ship

class_name EnemyShip

@export var lifeboat: PackedScene

@export var pirate_ship: PackedScene
@export var navy_ship: PackedScene
@export var merchant_ship: PackedScene

@export var target_arrow: Node3D

var change_route := 10.0
var route_timer := change_route
var ai_state: AIState = AIState.IDLE
var combat_state: CombatState = CombatState.PURSUE
var target_point: Vector3

var water: Water

var agro_dist := 100.0
var pursue_dist := 200.0

signal state_changed(_ai_State: AIState)
enum AIState {IDLE, ENROUTE, COMBAT}

signal combat_state_changed(_combat_State: CombatState)
enum CombatState {AGRO, PURSUE, FLEE}

var AIStateNames = {
	AIState.IDLE: "IDLE",
	AIState.ENROUTE: "ENROUTE",
	AIState.COMBAT: "COMBAT",
}
var CombatStateNames = {
	CombatState.AGRO: "AGRO",
	CombatState.PURSUE: "PURSUE",
	CombatState.FLEE: "FLEE",
}

func _enter_tree() -> void:
	floater.water = water

func _ready() -> void:
	super._ready()
	
	# later have ship names per faction, for now just random
	ship_name = FactionsData.get_random_name()

	faction = FactionsData.Faction.NAVY
	if randf() > 0.5:
		faction = FactionsData.Faction.MERCHANT
	if randf() > 0.5:
		faction = FactionsData.Faction.PIRATE
	if randf() > 0.5:
		faction = FactionsData.Faction.SLAVER

	var faction_stats = FactionsData.get_faction_stats(faction)

	max_hit_points = faction_stats.max_hit_points
	attack = faction_stats.attack
	defense = faction_stats.defense
	top_speed = faction_stats.speed
	guns = faction_stats.guns
	gold = faction_stats.gold
	supplies = faction_stats.supplies
	crew = faction_stats.max_crew
	max_crew = faction_stats.max_crew

	set_faction_texture()
	
	hit_points = max_hit_points

	connect("recieved_damage", Callable(self , "_on_damage_recieved"))
	connect("on_sink", Callable(self , "_on_ship_sunk"))
	
	set_state(AIState.ENROUTE)


func _on_damage_recieved(_damage: float, _attacker: Node3D):
	attacker = _attacker
	if _attacker is Ship:
		var ship = _attacker as Ship
		if ship:
			#compare ship stats and decide what to do
			set_state(AIState.COMBAT)
			if defense > ship.attack and attack > ship.defense:
				set_combat_state(CombatState.PURSUE)
			else:
				set_combat_state(CombatState.FLEE)


func set_state(_ai_State: AIState):
	ai_state = _ai_State
	emit_signal("state_changed", _ai_State)

func set_combat_state(_combat_State: CombatState):
	combat_state = _combat_State
	emit_signal("combat_state_changed", _combat_State)

func set_full_speed():
	target_speed = top_speed

func set_random_dir_and_speed():
	target_speed = randf_range(0, top_speed)
	yaw_deg = randf_range(0.0, 359.0)

func _process(delta):
	super._process(delta)
	var dist_to_attacker := 0.0
	var dir_to_attacker := Vector3.ZERO
	if attacker and ai_state == AIState.COMBAT:
		var to_attacker = attacker.global_position - global_position
		dist_to_attacker = to_attacker.length()
		dir_to_attacker = to_attacker.normalized()
		if combat_state != CombatState.FLEE:
			if dist_to_attacker < agro_dist:
				set_combat_state(CombatState.AGRO)
			elif dist_to_attacker > pursue_dist:
				set_state(AIState.ENROUTE)
			elif dist_to_attacker > agro_dist + 2.0: # small buffer
				set_combat_state(CombatState.PURSUE)

	elif not attacker and ai_state == AIState.COMBAT:
		set_state(AIState.ENROUTE)
	target_arrow.visible = false
	# execute state behaviour
	match ai_state:
		AIState.IDLE:
			#do nothing
			pass
		AIState.ENROUTE:
			en_route_behaviour(delta)
		AIState.COMBAT:
			if attacker:
				var deg_to_target = rad_to_deg(atan2(dir_to_attacker.z, -dir_to_attacker.x))
				target_arrow.visible = true
				target_arrow.global_rotation = Vector3.UP * deg_to_rad(yaw_deg + -90)
				match combat_state:
					CombatState.PURSUE:
						yaw_deg = deg_to_target + 90
						target_speed = top_speed
					CombatState.AGRO:
						# add 90 to angle to be perpendicular for shooting
						target_speed = 0.0
						yaw_deg = deg_to_target
						var diff = angle_difference(rotation.y, deg_to_rad(yaw_deg))
						if abs(diff) < deg_to_rad(10.0):
							set_canon_pitch((dist_to_attacker / 2.0))
							# print((dist_to_attacker / 1.0));
							shoot_port()
					CombatState.FLEE:
						yaw_deg = deg_to_target + 180
						target_speed = top_speed
			else:
				set_state(AIState.ENROUTE)


func en_route_behaviour(delta: float):
	route_timer += delta
	if route_timer >= change_route or (global_position - target_point).length() < 5.0:
		target_speed = 1.0
		change_route = randf_range(5.0, 20.0)
		route_timer = 0
		target_point = get_new_waypoint()
		set_rotation_to_target_point(target_point)


func get_new_waypoint() -> Vector3:
	return Vector3(randf_range(-50.0, 50.0), 0, randf_range(-50.0, 50.0))

func set_rotation_to_target_point(_target_point: Vector3):
	var direction_to_target_point = (_target_point - global_position).normalized()
	yaw_deg = rad_to_deg(atan2(direction_to_target_point.z, direction_to_target_point.x))

func _on_ship_sunk():
	spawn_lifeboat()

func spawn_lifeboat():
	var l = lifeboat.instantiate()
	get_tree().current_scene.add_child(l)
	l.global_position = global_position
	l.global_position.y = 0
	l.supplies = supplies
