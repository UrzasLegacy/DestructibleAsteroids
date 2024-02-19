extends Node2D

var asteroid_scene = preload("res://scenes/asteroid.tscn")

func _ready():
	var rand_range = 2000
	for i in rand_range:
		spawn_asteroid()


func spawn_asteroid():
	var asteroid: Asteroid = asteroid_scene.instantiate()
	if randi_range(1,10) < 0:
		asteroid.asteroid_radius = [50,60].pick_random()
	else:
		asteroid.asteroid_radius = randf_range(1,6) * 10
	asteroid.position = Vector2(randi_range(-7000,7000),randi_range(-4000,4000))
	add_child(asteroid)

