extends Ship

class_name PlayerShip

func _ready() -> void:
	ship_name = "Player"
	top_speed = 5
	agility = 2
	attack = 2
	defense = 2

	connect("recieved_gold", Callable(self , "_on_recieved_gold"))

func _on_recieved_gold(amount: int):
	gameManager.hud.new_notification("Recieved: %2.f" % amount)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			target_speed += 1.0
			target_speed = clamp(target_speed, 0, top_speed)
		if event.keycode == KEY_S:
			target_speed -= 1.0
			target_speed = clamp(target_speed, 0, top_speed)
		if event.keycode == KEY_A:
			yaw += agility
		if event.keycode == KEY_D:
			yaw -= agility
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