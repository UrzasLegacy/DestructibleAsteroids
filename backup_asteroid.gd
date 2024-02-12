extends RigidBody2D

@onready var asteroid_polygon: Polygon2D = $Polygon2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var line: Line2D = $Line2D
@onready var label: Label = $Label

const MINIMUM_AREA_THRESHOLD: int = 1000
var show_debug_polygons := false

func _ready():
	Events.debug_polygons.connect(on_debug_polygons)
	var asteroid_array: PackedVector2Array = generate_rand_polygon()
	asteroid_polygon.polygon = asteroid_array
	line.points = asteroid_array
	collision_polygon.set_deferred("polygon",asteroid_array)
	print('midpoint: ', find_midpoint(asteroid_array))
	print('globalpos: ', position)

func find_midpoint(vertices):
	var sum = Vector2.ZERO
	for vertex in vertices:
		sum += vertex
	print('sum: ',sum)
	return sum / vertices.size()

func _physics_process(_delta: float):
	var area = polygon_area(asteroid_polygon.polygon)
	label.text = str(round(area))
	if area < 1000:
		queue_free.call_deferred()

func hit(projectile_position: Vector2):
	#print("vertex: %s\nrotation: %s" % [asteroid_polygon.polygon[0], rotation])

	var destruction_array: PackedVector2Array = generate_rand_polygon(4,6,30.0 * randf() + 20)

	var destruction_polygon = Polygon2D.new()
	add_child(destruction_polygon)
	destruction_polygon.polygon = destruction_array
	destruction_polygon.global_position = projectile_position
	destruction_polygon.modulate.a = 0.55
	destruction_polygon.visible = show_debug_polygons
	destruction_polygon.add_to_group("destruction_polygons")

	var local_destruction_polygon = localize_destruction_polygon(destruction_polygon.polygon, projectile_position - global_position)
	var destruction_polygon_local = Polygon2D.new()
	add_child(destruction_polygon_local)
	destruction_polygon_local.polygon = local_destruction_polygon
	destruction_polygon_local.global_position = global_position
	destruction_polygon_local.modulate.r = 0
	destruction_polygon_local.visible = show_debug_polygons
	destruction_polygon_local.add_to_group("destruction_polygons")

	var double_local_destruction_polygon = localize_destruction_polygon(local_destruction_polygon, Vector2.ZERO, true, -rotation)
	var double_destruction_polygon_local = Polygon2D.new()
	add_child(double_destruction_polygon_local)
	double_destruction_polygon_local.polygon = double_local_destruction_polygon
	double_destruction_polygon_local.global_position = global_position
	double_destruction_polygon_local.modulate.b = 0
	double_destruction_polygon_local.visible = show_debug_polygons
	double_destruction_polygon_local.add_to_group("destruction_polygons")

	var new_asteroids = Geometry2D.clip_polygons(asteroid_polygon.polygon,double_local_destruction_polygon)


	var local_asteroid_polygon = localize_destruction_polygon(asteroid_polygon.polygon,Vector2.ZERO,rotation,false)

	for i in new_asteroids.size():
		var new_asteroid: PackedVector2Array = new_asteroids[i]
		var area_check = polygon_area(new_asteroid)
		var enclosed_hole_check = Geometry2D.is_polygon_clockwise(new_asteroid)
		if i == 0: # update origin asteroid rather than respawning it
			if enclosed_hole_check or area_check < MINIMUM_AREA_THRESHOLD:
				queue_free.call_deferred()
				continue
			asteroid_polygon.polygon = new_asteroid
			line.points = new_asteroid
			collision_polygon.set_deferred("polygon",new_asteroid)
		elif not enclosed_hole_check and area_check > MINIMUM_AREA_THRESHOLD:
			Events.add_asteroid.emit(new_asteroid,global_position,rotation)
	#destruction_polygon.queue_free() # commented out for debugging purposes

func localize_destruction_polygon(poly: PackedVector2Array, pos: Vector2, rotate: bool = false, angle: float = 0):
	var new_vals = []
	for point in poly:
		if rotate:
			point = rotate_point(point,angle)
		#var rotated_point = rotate_point(point, angle)
		var localized_point = point + pos
		#var localized_point = point + pos
		new_vals.append(localized_point)
	return PackedVector2Array(new_vals)

func rotate_point(point: Vector2, angle: float):
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	var new_x = point.x * cos_angle - point.y * sin_angle
	var new_y = point.x * sin_angle + point.y * cos_angle
	return Vector2(new_x, new_y)

func rotate_vertices(vertices: PackedVector2Array, angle: float):
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	var new_vals = []
	for point in vertices:
		var new_x = point.x * cos_angle - point.y * sin_angle
		var new_y = point.x * sin_angle + point.y * cos_angle
		new_vals.append(Vector2(new_x,new_y))
	return PackedVector2Array(new_vals)

func translate_vertices(vertices: PackedVector2Array, offset: Vector2):
	var new_vals = []
	for point in vertices:
		var translated_point = point + offset
		new_vals.append(translated_point)
	return PackedVector2Array(new_vals)


func rotate_vertices_around_point(vertices, angle, origin):
	var rotated_vertices = []
	for vertex in vertices:
		# Translate vertex so that origin is at (0, 0)
		var translated_vertex = vertex - origin

		# Rotate translated vertex
		var x_prime = translated_vertex.x * cos(angle) - translated_vertex.y * sin(angle)
		var y_prime = translated_vertex.x * sin(angle) + translated_vertex.y * cos(angle)

		# Translate vertex back
		var rotated_vertex = Vector2(x_prime, y_prime) + origin
		rotated_vertices.append(rotated_vertex)
	return rotated_vertices

func polygon_area(vertices: PackedVector2Array):
	#vertices = Geometry2D.convex_hull(vertices)
	var num_vertices = len(vertices)
	var area = 0.0
	# Calculate the sum of (x_i * y_(i+1)) and (x_(i+1) * y_i) terms
	for i in range(num_vertices):
		var j = (i + 1) % num_vertices  # Wraps around to the first vertex
		area += (vertices[i][0] * vertices[j][1]) - (vertices[j][0] * vertices[i][1])
	return abs(area / 2.0)

func generate_rand_polygon(min_sides: int = 10, max_sides: int = 20, radius: float = 100.0):
	var num_sides = randi() % (max_sides - min_sides + 1) + min_sides
	var angle_step = 2.0 * PI / num_sides
	var vertices = []

	for i in range(num_sides):
		var angle = i * angle_step + randf() * angle_step * 0.3
		var distance = radius + randf() * radius * 0.2
		var vertex = Vector2(distance * cos(angle), distance * sin(angle))
		vertices.append(vertex)

	return vertices

func on_debug_polygons(boolean: bool):
	show_debug_polygons = boolean

func _on_mouse_entered() -> void:
	Events.debug_text.emit(asteroid_polygon.polygon)
