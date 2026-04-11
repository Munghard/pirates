extends Ship

class_name PlayerShip

func _ready() -> void:
	super._ready()
	ship_name = "Player"
	top_speed = 5
	agility = 2
	attack = 2
	defense = 2

	connect("recieved_gold", Callable(self , "_on_recieved_gold"))
	
	active_starboard(true)
	active_port(true)
	#hud not ready yet
	await get_tree().create_timer(1.0).timeout
	GM.hud.selected_ship = self

func _on_recieved_gold(amount: int):
	GM.hud.new_notification("Recieved: %2.f" % amount)

func sink():
	# dont call super, were overriding behaviour
	get_tree().reload_current_scene()

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
