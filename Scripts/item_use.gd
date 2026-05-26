extends Node

class_name Item_Use

func use_item(id: String, ship: Ship, finished: Callable, consume: Callable):
	match id:
		"fishing_gear":
			start_fishing(ship, finished, consume)
		"repair_kit":
			start_ship_repair(ship, 10.0, finished, consume)
		"diving_suit":
			start_dive(ship, finished, consume)
		"harpoon":
			start_harpooning(ship, finished, consume)
		_:
			finished.call()
			print("Item doesnt have a defined use")

func start_harpooning(ship: Ship, finished: Callable, consume: Callable):
	var selecting_location = true
	var marker_scene = preload("res://Scenes/marker.tscn")
	var selected_position: Vector3
	var target_marker: Node3D
	target_marker = marker_scene.instantiate()
	add_child(target_marker)
	target_marker.global_position = ship.global_position
	
	await get_tree().create_timer(1.0).timeout
	

	while selecting_location:
		var camera = get_viewport().get_camera_3d()

		var mouse_screen_pos = get_viewport().get_mouse_position()

		var ray_origin = camera.project_ray_origin(mouse_screen_pos)
		var ray_direction = camera.project_ray_normal(mouse_screen_pos)

		var plane = Plane(Vector3.UP, 0.0)

		var mouse_pos = plane.intersects_ray(ray_origin, ray_direction)

		target_marker.global_position = mouse_pos

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			selected_position = mouse_pos
			selecting_location = false
		
		#cancel
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			selecting_location = false
			consume.call(false)
			finished.call()
			return

		await get_tree().process_frame

	#wait for animation duration ie. 1-2 seconds to make it a bit harder
	var harpoon_scene = preload("res://Scenes/Harpoon.tscn")
	var harpoon: Node3D = harpoon_scene.instantiate()
	add_child(harpoon)
	var start_pos = ship.global_position + Vector3.UP
	harpoon.global_position = start_pos
	harpoon.look_at(selected_position)
	
	var distance = start_pos.distance_to(selected_position)
	var duration = distance / 20.0
	var elapsed := 0.0
	while elapsed < duration:
		elapsed += get_process_delta_time()

		var t = elapsed / duration
		t = clamp(t, 0.0, 1.0)
		harpoon.global_position = lerp(start_pos, selected_position, t)
		await get_tree().process_frame
	#await get_tree().create_timer(duration).timeout
	
	#delete marker
	target_marker.queue_free()

	## do the thing with the location
	#detect raycast if clicked whale.gd
	var space_state = ship.get_world_3d().direct_space_state
	var sphere = SphereShape3D.new()
	sphere.radius = 2.0
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis(), selected_position)

	var results = space_state.intersect_shape(query)

	# if true, disable whale movement, could also maybe slow down ships idk
	for res in results:
		var collider = res["collider"]
		var whale = collider as Whale
		if whale:
			#print("hit whale");
			ship.gameManager.hud.ddd_label("Harpooned!", whale.global_position, Color.GREEN)
			whale.damage(20.0, 1.0, whale.global_position, ship)
			whale.speed = 0.0
	
	consume.call(true)
	finished.call()

func start_ship_repair(ship: Ship, repair_amount: float, finished: Callable, consume: Callable):
	consume.call(true)
	var tick = 5
	var tick_interval = 5.0
	var hp_missing = ship.max_hit_points - ship.hit_points
	var repaired = min(repair_amount, hp_missing)
	for t in tick:
		if is_instance_valid(ship):
			ship.gameManager.hud.ddd_label("Repaired hull: %s" % [repaired], ship.global_position, Color.GREEN)
			ship.gain_hitpoints(repaired)
			await get_tree().create_timer(tick_interval).timeout
		else:
			break
	finished.call()
		

func start_dive(ship: PlayerShip, finished: Callable, consume: Callable):
	consume.call(true)
	ship.gameManager.hud.ddd_label("Started diving operation", ship.global_position, Color.WHITE)
	var pos = ship.global_position
	await get_tree().create_timer(5.0).timeout
	var roll = randf()
	if roll > 0.5:
		var item = Item_Database.get_random_item_def()
		var amount = randi_range(1, 3)
		ship.gameManager.hud.ddd_label("Found treasure! %s" % [item.item_name], ship.global_position, Color.GREEN)
		ship.gameManager.spawn_item_in_world(InventoryItem.new(item.id, amount), pos)
	else:
		ship.gameManager.hud.ddd_label("Found nothing...", ship.global_position, Color.GRAY)
	
	finished.call()

func start_fishing(ship: Ship, finished: Callable, consume: Callable):
	consume.call(true)
	ship.gameManager.hud.ddd_label("Started fishing", ship.global_position, Color.WHITE)
	var pos = ship.global_position
	await get_tree().create_timer(5.0).timeout
	var roll = randf()
	if roll > 0.5:
		var amount = randi_range(1, 5)
		ship.gameManager.hud.ddd_label("Got %s fish!" % [amount], ship.global_position, Color.GREEN)
		ship.gameManager.spawn_item_in_world(InventoryItem.new("rations", amount), pos)
	else:
		ship.gameManager.hud.ddd_label("Got nothing...", ship.global_position, Color.GRAY)
	
	finished.call()
