extends Area2D

const SPEED := 500

var shapes: Array
@onready var radial_impulse: RadialImpulse2D = $RadialImpulse

@onready var direction: Vector2 = Vector2.RIGHT

func _ready():
	radial_impulse.impulse_applied.connect(on_impulse_applied)

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func generate_rand_polygon(min_sides = 4, max_sides = 8, radius = 5.0):
	var num_sides = randi() % (max_sides - min_sides + 1) + min_sides
	var angle_step = 2.0 * PI / num_sides
	var vertices = []

	for i in range(num_sides):
		var angle = i * angle_step + randf() * angle_step * 0.3 # Add slight randomness

		# Vary radius slightly for an irregular shape
		var distance = radius + randf() * radius * 0.2

		var vertex = Vector2(distance * cos(angle), distance * sin(angle))
		vertices.append(vertex)

	return vertices


func on_impulse_applied():
	print('beep')
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("asteroids"):
		body.hit(position,direction)
		queue_free()

		#radial_impulse.apply_impulse()
