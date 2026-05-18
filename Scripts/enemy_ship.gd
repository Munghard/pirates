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

var water: Water

var active := true # active status for process

@export_group("Navigation")
@onready var ai_navigation: AI_Navigation = $navigation
var repath_timer := 0.0
var repath_interval := 10.0

var requesting_waypoint := false
var active_range := 100.0 # range from player
var remove_range := 150.0 # range from player


@export_group("Perception")
var avoidance_distance := 5.0
var perception_radius := 25.0
var last_perception_time := 0.0
var perception_interval := 5.0
var flee_timer := 0.0
var flee_duration := 10.0
var agro_dist := 50.0
var pursue_dist := 100.0
var height_buffer = 2.0

var patrol_point: Vector3

@export_group("Debug")
var line_agro: ImmediateMesh
var line_route: ImmediateMesh
var line_avoidance: ImmediateMesh

signal state_changed(_ai_State: AIState)
enum AIState {IDLE, ENROUTE, COMBAT, CAPTURED, SUNK, PATROL}

signal combat_state_changed(_combat_State: CombatState)
enum CombatState {AGRO, PURSUE, FLEE}

var AIStateNames = {
	AIState.IDLE: "IDLE",
	AIState.ENROUTE: "ENROUTE",
	AIState.COMBAT: "COMBAT",
	AIState.CAPTURED: "CAPTURED",
	AIState.SUNK: "SUNK",
	AIState.PATROL: "PATROL",
}
var CombatStateNames = {
	CombatState.AGRO: "AGRO",
	CombatState.PURSUE: "PURSUE",
	CombatState.FLEE: "FLEE",
}

func _enter_tree() -> void:
	floater.water = water

func _ready() -> void:
	#create debug line
	line_agro = ImmediateMesh.new()
	line_route = ImmediateMesh.new()
	line_avoidance = ImmediateMesh.new()
	
	hit_points = max_hit_points
	
	connect("recieved_damage", Callable(self , "_on_damage_recieved"))
	connect("on_sink", Callable(self , "_on_ship_sunk"))
	connect("boarded_changed", Callable(self , "_on_boarded_changed"))
	
	set_state(AIState.ENROUTE)

	navigation_markers.visible = false
	world_bars.visible = false

	setup_identity(FactionsData.roll_nation(), FactionsData.roll_faction(FactionsData.roll_nation()))

	super._ready()

func setup_identity(_nation: FactionsData.Nation, _faction: FactionsData.Faction):
	ship_name = FactionsData.get_unique_ship_name()
	portrait = FactionsData.get_unique_portrait()
	level = randi_range(1, 5)
	nation = _nation
	faction = _faction

	var faction_stats = FactionsData.get_faction_stats(faction)

	max_hit_points = faction_stats.max_hit_points
	attack = 1 # faction_stats.attack
	defense = 1 # faction_stats.defense
	top_speed = faction_stats.speed
	gold = faction_stats.gold
	crew = faction_stats.max_crew
	max_crew = faction_stats.max_crew

	set_faction_texture()
	set_stars(level)
	ship_pivot.set_flag()
	
	setup_inventory()
	setup_cannons()
	setup_ship_model(faction)

func setup_inventory():
	inventory = Inventory.new(self , gameManager, 16, ship_name + " cargo")
	inventory.inventory_changed.connect(_on_inventory_changed)
	await get_tree().process_frame
		
	var items := FactionsData.get_faction_inventory(faction)
	for item in items:
		inventory.add_item(item)
	

func _on_damage_recieved(_damage: float, _attacker: Node3D):
	attacker = _attacker

	if _attacker == null:
		return

	if _attacker is Ship:
		ai_navigation.set_target(global_position, attacker.global_position)

		var ship = _attacker as Ship

		if ai_state == AIState.CAPTURED:
			return

		if ship and FactionsData.is_enemy(faction, ship.faction):
			set_state(AIState.COMBAT)
			set_combat_state(decide_combat_action(ship))

	if hit_points <= 0:
		set_state(AIState.SUNK)


func decide_combat_action(ship: Ship) -> CombatState:
	if get_combat_readiness() > ship.get_combat_readiness():
		return CombatState.PURSUE
	else:
		return CombatState.FLEE


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

func get_avoidance_direction() -> Vector3:
	var forward = - transform.basis.z
	var right = transform.basis.x

	var check_distance := avoidance_distance
	var water_level = gameManager.world.water.water_level_world_space

	# forward check
	var f_point = global_position + forward * check_distance
	var f_height = gameManager.world.terrain.get_height_world(f_point.x, f_point.z)

	if f_height > water_level:
		# obstacle ahead → decide left or right
		var left_point = global_position + (forward - right).normalized() * check_distance
		var right_point = global_position + (forward + right).normalized() * check_distance

		var left_h = gameManager.world.terrain.get_height_world(left_point.x, left_point.z)
		var right_h = gameManager.world.terrain.get_height_world(right_point.x, right_point.z)

		if left_h < right_h:
			return (forward - right).normalized()
		else:
			return (forward + right).normalized()

	return forward

func _physics_process(_delta: float) -> void:
	# deactivate process
	var dist_sq = global_position.distance_squared_to(gameManager.player_ship.global_position)
	active = dist_sq < active_range * active_range
	if dist_sq > remove_range * remove_range:
		queue_free()
		return
	if not active:
		return
	
	super._physics_process(_delta)

func _process(delta):
	# deactivate process
	if not active or destroyed:
		return
	
	super._process(delta)

	repath_timer -= delta
	var nav_target = ai_navigation.get_current_target()

	var debug_draw_path = true
	if debug_draw_path:
		if attacker != null:
			draw_line_to_target_point(line_agro, attacker.global_position, Color.RED)
		draw_line_to_target_point(line_route, nav_target, Color.GREEN)
	
	var time = Time.get_ticks_msec() / 1000.0


	if ai_state == AIState.COMBAT:
		if is_instance_valid(attacker):
			var to_attacker = attacker.global_position - global_position
			var dist_to_attacker = to_attacker.length()
			_update_combat_transitions(dist_to_attacker, delta)
			
			match combat_state:
				CombatState.PURSUE, CombatState.AGRO:
					ai_navigation.set_target(global_position, attacker.global_position)
				CombatState.FLEE:
					# Move away from attacker
					var flee_point = global_position - (to_attacker.normalized() * 50.0)
					if repath_timer <= 0.0:
						ai_navigation.set_target(global_position, flee_point)
						repath_timer = repath_interval
					flee_timer = flee_duration
		else:
			set_state(AIState.ENROUTE)

	if ai_state != AIState.IDLE:
		# 1. Calculate the direction and the angle needed to look at the target
		var target_dir = (nav_target - global_position).normalized()
		var final_dir = target_dir

		# only apply avoidance when moving
		# var is_moving_state = false
		# match ai_state:
		# 	AIState.ENROUTE:
		# 		is_moving_state = true
		# 	AIState.CAPTURED:
		# 		is_moving_state = false
		# 	AIState.PATROL:
		# 		is_moving_state = false
		# 	AIState.COMBAT:
		# 		if combat_state == CombatState.PURSUE or combat_state == CombatState.FLEE:
		# 			is_moving_state = true
		# if is_moving_state:
		# 	var avoid_dir = get_avoidance_direction()
		# 	if debug_draw_path:
		# 		draw_line_to_target_point(line_avoidance, global_position + (avoid_dir * 5.0), Color.PURPLE)
		# 	if avoid_dir != Vector3.ZERO:
		# 		final_dir = (target_dir + avoid_dir * 2.0).normalized()

		var look_at_angle = rad_to_deg(atan2(final_dir.x, final_dir.z))
		if time > last_perception_time + perception_interval:
			last_perception_time = time
			perception()
		match ai_state:
			AIState.PATROL:
				patrol_behaviour(delta)
				yaw_deg = look_at_angle # Face the waypoint

			AIState.ENROUTE:
				en_route_behaviour(delta)
				yaw_deg = look_at_angle # Face the waypoint
			
			AIState.CAPTURED:
				yaw_deg = look_at_angle # Face the waypoint
				if repath_timer <= 0.0:
					ai_navigation.set_target(global_position, gameManager.player_ship.global_position)
					repath_timer = repath_interval
				var forward = global_basis.z
				var dot = forward.dot(target_dir)
				var distance_squared = global_position.distance_squared_to(nav_target)
				var move_threshold = 20.0
				if distance_squared > move_threshold * move_threshold:
					target_speed = top_speed
				else:
					target_speed = boarded_by.target_speed * max(dot, 0.0)

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
						yaw_deg = look_at_angle - 90.0
						_handle_shooting(attacker.global_position)

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

	if abs(diff) < 15.0 and inventory.has_item_type(Item_Definition.Type.CANNON, 1):
		set_canon_pitch(dist / 2.0) # Ensure your Ship class handles pitch units correctly
		shoot_port()
	
var patrol_retargeting := false

func patrol_behaviour(delta: float):
	repath_timer -= delta

	target_speed = 1.0

	var nav_target = ai_navigation.get_current_target()
	
	if patrol_retargeting:
		return
	
	# if no path or arrived → pick new destination
	if global_position.distance_to(nav_target) < 50.0:
		patrol_retargeting = true
		var new_target = gameManager.get_position_around_point(patrol_point, 20.0)

		ai_navigation.set_target(global_position, new_target)

		repath_timer = repath_interval

		#print("New patrol point: ", new_target)

func en_route_behaviour(delta: float):
	var nav_target = ai_navigation.get_current_target()
	route_timer += delta

	if requesting_waypoint:
		return

	if route_timer >= change_route or (global_position - nav_target).length() < 10.0:
		requesting_waypoint = true
		route_timer = 0
		change_route = randf_range(100.0, 500.0)

		_request_waypoint()
	
	set_rotation_to_target_point(nav_target)

	var forward = - transform.basis.z
	var dir = (nav_target - global_position).normalized()
	var dot = dir.dot(forward)
	var mp = dot * 0.5 + 0.5
	target_speed = top_speed * max(mp, 0.0)

var pending_waypoint: Vector3

func _request_waypoint() -> void:
	var nav_target = ai_navigation.get_current_target()
	var wp = get_new_waypoint()

	# Ignore tiny changes
	if wp.distance_to(nav_target) < 10.0:
		return

	pending_waypoint = wp
	gameManager.hud.ddd_label("New waypoint acquired", global_position)

	ai_navigation.set_target(global_position, pending_waypoint)

	requesting_waypoint = false
	patrol_retargeting = false

var target_point_height: float

func perception():
	var ships: Array = get_tree().get_nodes_in_group("Ships")
	var ships_in_perception_radius: Array[Ship] = []
	for ship: Ship in ships:
		if (ship.global_position - global_position).length() < perception_radius:
			ships_in_perception_radius.append(ship)

	var enemy_factions := FactionsData.get_enemy_factions(faction)
	var enemy_ships_in_perception_radius := GameManager.get_ships_by_faction(ships_in_perception_radius, enemy_factions)
	var closest_ship_in_enemy_faction := GameManager.get_closest_ship(enemy_ships_in_perception_radius, self )
	if closest_ship_in_enemy_faction:
		attacker = closest_ship_in_enemy_faction
		set_state(AIState.COMBAT)
		set_combat_state(decide_combat_action(attacker))
		var action_string = ""
		if combat_state == CombatState.FLEE:
			action_string = "fleeing"
		elif combat_state == CombatState.PURSUE:
			action_string = "pursuing"
		gameManager.hud.ddd_label("Spotted enemy ship, " + action_string, global_position)
	

func get_new_waypoint() -> Vector3:
	var max_attempts := 20

	for i in max_attempts:
		#var point = get_target_point_in_radius(100.0)
		var p2 = gameManager.territory.get_random_point_in_territory(faction)
		var point = Vector3(p2.x, 0, p2.y)
		var height = gameManager.world.terrain.get_height_world(point.x, point.z)

		if height <= gameManager.world.water.water_level_world_space - height_buffer and is_path_clear(global_position, point):
			return point

	# fallback (VERY important) but not sure why its important
	return global_position


func get_target_point_in_radius(radius: float) -> Vector3:
	# random point in circle
	var angle = randf() * TAU
	var dist = randf() * radius
	var offset = Vector3(cos(angle), 0, sin(angle)) * dist

	var point = global_position + offset

	# clamp to world bounds
	var max_x = gameManager.world.terrain.world_size.x * gameManager.world.terrain.tile_size
	var max_z = gameManager.world.terrain.world_size.y * gameManager.world.terrain.tile_size

	point.x = clamp(point.x, 0.0, max_x)
	point.z = clamp(point.z, 0.0, max_z)

	return point

func is_path_clear(from: Vector3, to: Vector3) -> bool:
	var space = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(from + (to.normalized() * 2.0), to)
	query.collide_with_areas = false
	
	var result = space.intersect_ray(query)
	
	return result.is_empty()

func set_rotation_to_target_point(_target_point: Vector3):
	var direction_to_target_point = (_target_point - global_position).normalized()
	yaw_deg = rad_to_deg(atan2(direction_to_target_point.x, direction_to_target_point.z))

func _on_ship_sunk():
	spawn_lifeboat()

func spawn_lifeboat():
	var l = lifeboat.instantiate()
	gameManager.world.add_child(l)
	l.global_position = global_position
	l.global_position.y = 0
	l.crew = crew


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

	gameManager.world.add_child(line_instance)
	await get_tree().create_timer(0.1).timeout
	line_instance.queue_free()

func _on_boarded_changed(ship: Ship):
	if ship != null:
		set_state(AIState.CAPTURED)
	else:
		set_state(AIState.ENROUTE)
	print("boarded changed: ", ship != null);

func _on_boarding_area_body_entered(body: Node3D) -> void:
	var ship
	if body is Ship and body != self:
		ship = body as Ship
		boarding_target = ship

func _on_boarding_area_body_exited(body: Node3D) -> void:
	var ship
	if body is Ship:
		ship = body as Ship
		if boarding_target == ship:
			boarding_target = null
