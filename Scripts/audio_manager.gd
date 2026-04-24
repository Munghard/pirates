extends Node3D
class_name AudioManager

func play_sound_at(pos: Vector3, stream: AudioStream, pitch_range := 0.0, volume_db := 0.0):
	var player := AudioStreamPlayer3D.new()
	add_child(player)

	player.pitch_scale = 1.0 + randf_range(-pitch_range, pitch_range)
	player.global_position = pos
	player.stream = stream
	player.volume_db = volume_db
	player.play()

	player.finished.connect(Callable(func(): player.queue_free()))