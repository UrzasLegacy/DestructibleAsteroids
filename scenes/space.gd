extends Node2D

var asteroid_scene: PackedScene = preload("res://scenes/asteroid.tscn")
@onready var debug_text: Label = $CanvasLayer/DebugText

var alternator = false

func _ready():
	Events.add_asteroid.connect(on_add_asteroid)
	Events.debug_text.connect(on_debug_text)
	Events.asteroid_died.connect(on_asteroid_died)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed('debug1'):
		for poly in get_tree().get_nodes_in_group("destruction_polygons"):
			poly.visible = true
		Events.debug_polygons.emit(true)

	if event.is_action_pressed('debug2'):
		for poly in get_tree().get_nodes_in_group("destruction_polygons"):
			poly.visible = false
		Events.debug_polygons.emit(false)

func on_asteroid_died(polygon,pos,rot):
	var polygon_shape = Polygon2D.new()
	add_child(polygon_shape)
	polygon_shape.polygon = polygon
	polygon_shape.color = Color("RED")
	polygon_shape.global_position = pos
	polygon_shape.rotation = rot
	var tween = get_tree().create_tween()
	tween.tween_property(polygon_shape,"modulate:a", 0.0, 0.2)
	tween.tween_callback(polygon_shape.queue_free)


func on_add_asteroid(polygon,pos,rot,lin_vel,ang_vel):
	var add_asteroid = asteroid_scene.instantiate() as RigidBody2D
	add_child(add_asteroid)
	var center_point = find_midpoint(polygon)
	add_asteroid.linear_velocity = lin_vel
	add_asteroid.angular_velocity = ang_vel
	add_asteroid.center_of_mass = center_point
	add_asteroid.marker.position = center_point
	add_asteroid.label_area.position = center_point
	add_asteroid.label_mass_kg.position = center_point + Vector2(0,20)
	add_asteroid.asteroid_polygon.polygon = polygon
	add_asteroid.line.points = polygon
	add_asteroid.global_position = pos
	add_asteroid.rotation = rot
	add_asteroid.collision_polygon.set_deferred("polygon",polygon)


func on_debug_text(array):
	var out_txt = "Debug:\n"
	for tuple in array:
		out_txt += str(tuple) + "\n"
	debug_text.text = out_txt

func find_midpoint(vertices):
	vertices = Geometry2D.convex_hull(vertices)
	var sum = Vector2.ZERO
	for vertex in vertices:
		sum += vertex
	return sum / vertices.size()
