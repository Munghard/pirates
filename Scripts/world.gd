extends Node3D


func _ready():
	GM.player_ship = $PlayerShip
	GM.hud = $MarginContainer/HUD
	GM.camera = $camrig/Camera3D
	GM.camerarig = $camrig
	GM.water = $water
	GM.wind_particle = $wind_particle

	assert(GM.wind != null, "wind is null in gamemanager start")
	assert(GM.player_ship != null, "player_ship is null in gamemanager start")
	assert(GM.hud != null, "hud is null in gamemanager start")
	assert(GM.wind_particle != null, "wind_particle is null in gamemanager start")
	assert(GM.water != null, "water is null in gamemanager start")
	assert(GM.camera != null, "camera is null in gamemanager start")
	assert(GM.camerarig != null, "camerarig is null in gamemanager start")
