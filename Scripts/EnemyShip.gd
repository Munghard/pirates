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
@export_group("Perception")
var perception_radius := 50.0
var perception_timer := 0.0
var perception_interval := 5.0
var flee_timer := 0.0
var flee_duration := 10.0
var agro_dist := 100.0
var pursue_dist := 200.0


@export_group("Debug")
var line_agro: ImmediateMesh
var line_route: ImmediateMesh

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
	#create debug line
	line_agro = ImmediateMesh.new()
	line_route = ImmediateMesh.new()
	# later have ship names per faction, for now just random
	ship_name = FactionsData.get_random_name()

	faction = roll_faction()

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

func roll_faction():
	var _faction = FactionsData.Faction.NAVY
	if randf() > 0.5:
		_faction = FactionsData.Faction.MERCHANT
		if randf() > 0.5:
			_faction = FactionsData.Faction.PIRATE
			if randf() > 0.5:
				_faction = FactionsData.Faction.SLAVER
				if randf() > 0.5:
					_faction = FactionsData.Faction.CARTOGRAPHER
					if randf() > 0.5:
						_faction = FactionsData.Faction.BOUNTYHUNTER
	return _faction

func _on_damage_recieved(_damage: float, _attacker: Node3D):
	attacker = _attacker
	target_point = attacker.global_position
	if _attacker is Ship:
		var ship = _attacker as Ship
		if ship and FactionsData.is_enemy(faction, ship.faction):
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
	if attacker != null:
		draw_line_to_target_point(line_agro, attacker.global_position, Color.RED)
	draw_line_to_target_point(line_route, target_point, Color.GREEN)
	
	if ai_state == AIState.COMBAT:
		if is_instance_valid(attacker):
			var to_attacker = attacker.global_position - global_position
			var dist_to_attacker = to_attacker.length()
			_update_combat_transitions(dist_to_attacker, delta)
			
			match combat_state:
				CombatState.PURSUE, CombatState.AGRO:
					target_point = attacker.global_position
				CombatState.FLEE:
					# Move away from attacker
					target_point = global_position - (to_attacker.normalized() * 50.0)
					flee_timer = flee_duration
		else:
			set_state(AIState.ENROUTE)

	if ai_state != AIState.IDLE:
		# 1. Calculate the direction and the angle needed to look at the target
		var dir = (target_point - global_position).normalized()
		# In Godot, -Z is forward. atan2(x, z) gives the angle from the Z axis.
		var look_at_angle = rad_to_deg(atan2(dir.x, dir.z))

		match ai_state:
			AIState.ENROUTE:
				en_route_behaviour(delta)
				yaw_deg = look_at_angle # Face the waypoint

			AIState.COMBAT:
				target_arrow.visible = true
				match combat_state:
					CombatState.PURSUE, CombatState.FLEE:
						target_speed = top_speed
						yaw_deg = look_at_angle # Face the target/flee point
					
					CombatState.AGRO:
						target_speed = 0.0
						# BROADSIDE: Rotate 90 degrees offset from the target 
						# so the side (port/starboard) faces the enemy
						yaw_deg = look_at_angle + 90.0
						_handle_shooting(target_point)


func _update_combat_transitions(dist: float, delta: float):
	if combat_state == CombatState.FLEE:
		# this was added, not tested
		flee_timer -= delta
		if flee_timer <= 0:
			set_state(AIState.ENROUTE)
		return # Stay in flee if we chose it

	if dist < agro_dist:
		set_combat_state(CombatState.AGRO)
	elif dist > pursue_dist:
		set_state(AIState.ENROUTE)
	elif dist > agro_dist + 5.0: # Increased buffer
		set_combat_state(CombatState.PURSUE)

func _handle_shooting(target: Vector3):
	var dist = global_position.distance_to(target)
	var dir_to_target = (target - global_position).normalized()
	var angle_to_target = rad_to_deg(atan2(dir_to_target.x, dir_to_target.z))

	# Calculate difference between current ship rotation and target angle
	# We check if the PORT side (rotation + 90) is facing the target
	var diff = wrapf(yaw_deg - 90.0 - angle_to_target, -180, 180)

	if abs(diff) < 15.0:
		set_canon_pitch(dist / 2.0) # Ensure your Ship class handles pitch units correctly
		shoot_port()
		
func en_route_behaviour(delta: float):
	route_timer += delta

	if route_timer >= change_route or (global_position - target_point).length() < 5.0:
		target_speed = 1.0
		change_route = randf_range(100.0, 500.0)
		route_timer = 0
		target_point = await get_new_waypoint(delta)
		set_rotation_to_target_point(target_point)

var target_point_height: float

func perception():
	var ships: Array = get_tree().get_nodes_in_group("Ships")
	var ships_in_perception_radius = []
	for ship: Ship in ships:
		if (ship.global_position - global_position).length() < perception_radius:
			ships_in_perception_radius.append(ship)
	match faction:
		FactionsData.Faction.NAVY:
			var ships_in_faction = GameManager.get_ships_by_faction(ships_in_perception_radius, [FactionsData.Faction.PIRATE])
			var closest_ship_in_target_faction = GameManager.get_closest_ship(ships_in_faction, self )
			attacker = closest_ship_in_target_faction
			set_combat_state(CombatState.PURSUE)
			gameManager.hud.ddd_label("Spotted enemy ship", global_position)
			
		FactionsData.Faction.PIRATE:
			# check in radius for merchants and slavers
			var ships_in_faction = GameManager.get_ships_by_faction(ships_in_perception_radius, [FactionsData.Faction.MERCHANT, FactionsData.Faction.SLAVER, FactionsData.Faction.CARTOGRAPHER])
			var closest_ship_in_target_faction = GameManager.get_closest_ship(ships_in_faction, self )
			attacker = closest_ship_in_target_faction
			set_combat_state(CombatState.PURSUE)
			gameManager.hud.ddd_label("Spotted enemy ship", global_position)
			
		FactionsData.Faction.BOUNTYHUNTER:
			# check in radius for pirates
			var ships_in_faction = GameManager.get_ships_by_faction(ships_in_perception_radius, [FactionsData.Faction.MERCHANT, FactionsData.Faction.SLAVER])
			var closest_ship_in_target_faction = GameManager.get_closest_ship(ships_in_faction, self )
			attacker = closest_ship_in_target_faction
			set_combat_state(CombatState.PURSUE)
			gameManager.hud.ddd_label("Spotted enemy ship", global_position)
		_:
			#do nothing
			pass

func get_new_waypoint(_delta: float) -> Vector3:
	while target_point_height > gameManager.water.water_level_world_space or not is_path_clear(global_position, target_point):
		await get_tree().create_timer(0.1).timeout
		target_point = Vector3(randf_range(0, gameManager.terrain.world_size.x * gameManager.terrain.tile_size), 0, randf_range(0, gameManager.terrain.world_size.y * gameManager.terrain.tile_size))
		target_point_height = gameManager.terrain.get_height_world(target_point.x, target_point.z)
	gameManager.hud.ddd_label("New waypoint acquired", global_position)
	return target_point

func is_path_clear(from: Vector3, to: Vector3) -> bool:
	var space = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(from + (to.normalized() * 2.0), to)
	query.collide_with_areas = false
	
	var result = space.intersect_ray(query)
	
	return result.is_empty()

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


func draw_line_to_target_point(_line: ImmediateMesh, _target_point: Vector3, color: Color):
	_line.clear_surfaces()
	_line.surface_begin(Mesh.PRIMITIVE_LINES)
	_line.surface_set_color(color)
	_line.surface_add_vertex(global_position)
	_line.surface_add_vertex(_target_point)
	_line.surface_end()
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var line_instance = MeshInstance3D.new()
	line_instance.mesh = _line
	line_instance.material_override = material

	get_tree().current_scene.add_child(line_instance)
	await get_tree().create_timer(0.1).timeout
	line_instance.queue_free()
