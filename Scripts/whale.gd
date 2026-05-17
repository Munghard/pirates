extends RigidBody3D

class_name Whale

var target_position: Vector3
var position_interval := 5.0
var last_position_change := 0.0
var speed := 3.0

@export var max_hit_points := 20.0
var hit_points := max_hit_points

var accumulated_damage := 0.0
var damage_threshold := 20.0
var alive := true
var sunk := false
var active := true

var active_distance = 50.0
var level := 1

@onready var ai_navigation: AI_Navigation = $navigation

signal hit_points_changed(amount: float)
signal recieved_damage(amount: float, attacker: Node3D)

@onready var floater = $floater
@onready var gameManager: GameManager = get_node("/root/GameManager")

@onready var world_bars: Node3D = $world_bars
@onready var pb: ProgressBar = $world_bars/SubViewport/Control/VBoxContainer/pb_hp
@onready var star_container: HBoxContainer = $world_bars/SubViewport/Control/star_container

func _ready() -> void:
	connect("hit_points_changed", Callable(self , "_on_hit_points_changed"))
	level = randi_range(1, 3)
	max_hit_points *= level
	hit_points = max_hit_points
	pb.value = hit_points
	pb.max_value = max_hit_points
	set_stars(level)

func set_stars(amount: int):
	for child in star_container.get_children():
		child.queue_free()
	var star_ui = preload("res://UI/star.tscn")
	for i in range(amount):
		var star = star_ui.instantiate()
		star_container.add_child(star)

func _on_hit_points_changed(_amount: float):
	pb.value = hit_points
	pb.max_value = max_hit_points

func damage(_damage: float, _multiplier: float, _position: Vector3, _attacker: Node3D):
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

	hit_points = clamp(hit_points - multiplied_damage, 0, max_hit_points)
	
	emit_signal("recieved_damage", multiplied_damage, _attacker)
	emit_signal("hit_points_changed", hit_points)

	if hit_points <= 0.0 and alive:
		alive = false


func death():
	for i in range(level):
		gameManager.spawn_item_in_world(InventoryItem.new("rations", randi_range(1, 50)), global_position + Vector3(randf(), 0, randf()))
	queue_free()

var sink_speed := 0.5


func _physics_process(delta: float) -> void:
	if not active:
		return

	if not alive:
		if floater:
			floater.queue_free()
		freeze = true
		position += -basis.y * sink_speed * delta
		# apply_torque(Vector3.UP * 5.0 * mass)
		rotation.y += delta # radians per second
		if global_position.y <= -5.0 and not sunk:
			death()
	
	var nav_target = ai_navigation.get_current_target()


	linear_velocity = global_basis.z * speed

	var dir = (nav_target - global_position).normalized()
	var angle = atan2(dir.x, dir.z)

	rotation.y = lerp_angle(rotation.y, angle, delta)

var distance_check_interval := 5.0
var last_distance_check := 0.0

func _process(_delta):
	var time = Time.get_ticks_msec() / 1000.0

	# distance to player check
	if last_distance_check + distance_check_interval < time:
		last_distance_check = time
		var distance_squared = global_position.distance_squared_to(gameManager.player_ship.global_position)
		active = distance_squared < active_distance * active_distance

		world_bars.visible = distance_squared < (active_distance * active_distance) * 0.5
	
	if not active:
		return

	if last_position_change + position_interval < time:
		last_position_change = time
		target_position = get_new_waypoint()
		ai_navigation.set_target(global_position, target_position)


func get_new_waypoint() -> Vector3:
	var max_attempts := 20
	var height_buffer = 2.0

	for i in max_attempts:
		var point = get_target_point_in_radius(100.0)
		var height = gameManager.world.terrain.get_height_world(point.x, point.z)

		if height <= gameManager.world.water.water_level_world_space - height_buffer and is_path_clear(global_position, point):
			#gameManager.hud.ddd_label("New waypoint acquired", global_position)
			return point

	# fallback (VERY important)
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
