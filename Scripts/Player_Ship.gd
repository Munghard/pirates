extends Ship

class_name PlayerShip


func _ready() -> void:
	super._ready()
	ship_name = "Player"
	faction = FactionsData.Faction.PIRATE
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

	connect("recieved_gold", Callable(self , "_on_recieved_gold"))
	connect("recieved_damage", Callable(self , "_on_recieved_damage"))
	
	active_starboard(true)
	active_port(true)
	set_faction_texture()

func _on_recieved_damage(_amount: float, _attacker: Node3D):
	gameManager.camerarig.secondary_target = _attacker


func _on_recieved_gold(amount: int):
	gameManager.hud.new_notification("Recieved: %2.f gold" % amount)

func sink():
	# dont call super, were overriding behaviour
	gameManager.hud.new_notification("You sunk my battleship...")
	await get_tree().create_timer(5.0).timeout
	
	get_tree().reload_current_scene()

func upgrade_guns():
	guns += 1

func _process(_delta: float) -> void:
	super._process(_delta)
	# Continuous steering logic
	if Input.is_key_pressed(KEY_A):
		yaw_deg += _delta * agility * 10.0
	if Input.is_key_pressed(KEY_D):
		yaw_deg -= _delta * agility * 10.0

func _input(event: InputEvent) -> void:
	# One-time actions (like shooting or incremental speed changes) 
	# stay here to prevent "machine-gun" firing or instant max speed
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			target_speed = clamp(target_speed + 1.0, 0, top_speed)
		if event.keycode == KEY_S:
			target_speed = clamp(target_speed - 1.0, 0, top_speed)
		if event.keycode == KEY_LEFT:
			shoot_starboard()
		if event.keycode == KEY_RIGHT:
			shoot_port()
		if event.keycode == KEY_UP:
			starboard_pitch(5)
			port_pitch(5)
		if event.keycode == KEY_DOWN:
			starboard_pitch(-5)
			port_pitch(-5)
		if event.keycode == KEY_Q:
			yaw_deg = yaw_deg + 90.0
		if event.keycode == KEY_E:
			yaw_deg = yaw_deg - 90.0
