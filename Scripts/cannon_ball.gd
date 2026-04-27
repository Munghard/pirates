extends RigidBody3D
class_name CannonBall

var damage = 5.0
var shooter: Node3D
var audio_hit = preload("res://Audio/cannonball_hit.mp3")
var audioManager: AudioManager
@export var particle: PackedScene


func _on_body_entered(body: Node) -> void:
	if body is not Ship:
		return
	var ship := body as Ship
	if ship:
		var p = particle.instantiate()
		get_tree().current_scene.add_child(p)
		p.global_position = global_position

		#ship.damage(damage, global_position, shooter)
		#apply damage handled in damagezones
		
		audioManager.play_sound_at(global_position, audio_hit, 0.2)
