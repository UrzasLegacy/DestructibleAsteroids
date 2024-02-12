class_name Asteroid extends RigidBody2D

@onready var asteroid_polygon: Polygon2D = $Polygon2D
@onready var polygon_2d_2: Polygon2D = $Polygon2D2
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var line: Line2D = $Line2D
@onready var marker: Polygon2D = $Marker
@onready var label_area: Label = %LabelArea
@onready var label_mass_kg: Label = %LabelMassKG

const MINIMUM_AREA_THRESHOLD: int = 3000


@onready var area: float
@onready var s1: Sprite2D = $Sprite2D
@onready var s2: Sprite2D = $Sprite2D2
@onready var s3: Sprite2D = $Sprite2D3

var show_debug_polygons := false
var starting_area := 0.0
var starting_mass: float = mass
var center_point: Vector2
var shatter_chance := 1

@export var asteroid_min_sides: int = 10
@export var asteroid_max_sides: int = 20
@export var asteroid_radius: float = 100.0

func _ready():
	Events.debug_polygons.connect(on_debug_polygons)

	var asteroid_array: PackedVector2Array = generate_rand_polygon(asteroid_min_sides, asteroid_max_sides, asteroid_radius)
	center_point = find_midpoint(asteroid_array)
	center_of_mass = center_point
	marker.position = center_point
	label_area.position = center_point
	label_mass_kg.position = center_point + Vector2(0,20)
	polygon_2d_2.polygon = asteroid_array
	asteroid_polygon.polygon = asteroid_array
	area = polygon_area(asteroid_polygon.polygon)
	starting_area = polygon_area(asteroid_polygon.polygon)
	line.points = asteroid_array
	collision_polygon.set_deferred("polygon",asteroid_array)



func _physics_process(_delta: float):
	area = polygon_area(asteroid_polygon.polygon)
	if not is_equal_approx(area,starting_area):
		set_deferred('mass',max(starting_mass * (area / starting_area), 2))
	label_area.text = str(round(area)) + " px"
	label_mass_kg.text = str(round(mass)) + " kg"
	#if area < MINIMUM_AREA_THRESHOLD:
		#queue_free.call_deferred()

func hit(impact_position: Vector2, impact_direction: Vector2):
	var asteroid_position = global_position
	var asteroid_rotation = global_rotation
	var impact_asteroid_offset = impact_position - asteroid_position
	var transformed_impact_position = transform.basis_xform_inv(impact_asteroid_offset)

	var destructor_vertex_array: PackedVector2Array
	destructor_vertex_array = generate_rand_polygon(3,8,30.0 * randf() + 10)
	destructor_vertex_array = translate_vertices(destructor_vertex_array, transformed_impact_position)
	if randf() < shatter_chance:
		var shatter_vertex_array = generate_random_line_polygon(transformed_impact_position,rotate_direction(impact_direction,-rotation))
		destructor_vertex_array = Geometry2D.merge_polygons(destructor_vertex_array,shatter_vertex_array)[0]

	#add_debug_poly(destructor_vertex_array)

	var new_asteroids = Geometry2D.clip_polygons(asteroid_polygon.polygon, destructor_vertex_array)

	for i in new_asteroids.size():
		var new_asteroid: PackedVector2Array = new_asteroids[i]
		var area_check = polygon_area(new_asteroid) < MINIMUM_AREA_THRESHOLD
		var enclosed_hole_check = Geometry2D.is_polygon_clockwise(new_asteroid)
		if i == 0: # update origin asteroid rather than respawning it
			if enclosed_hole_check or area_check:
				Events.asteroid_died.emit(asteroid_polygon.polygon,global_position)
				queue_free.call_deferred()
				print('beep')
				continue
			highlight_poly(asteroid_polygon.polygon, destructor_vertex_array)
			asteroid_polygon.polygon = new_asteroid
			center_point = find_midpoint(new_asteroid)
			center_of_mass = center_point
			label_area.position = center_point
			label_mass_kg.position = center_point + Vector2(0,20)
			marker.position = center_point
			line.points = new_asteroid
			collision_polygon.set_deferred("polygon",new_asteroid)
		else:
			if enclosed_hole_check or area_check:
				continue
			Events.add_asteroid.emit(new_asteroid,global_position,rotation)


func highlight_poly(poly: PackedVector2Array,highlight_poly: PackedVector2Array):
	var highlight_array = Geometry2D.intersect_polygons(poly, highlight_poly)
	for highlight: PackedVector2Array in highlight_array:
		if Geometry2D.is_polygon_clockwise(highlight):
			continue
		var polygon_shape = Polygon2D.new()
		add_child(polygon_shape)
		polygon_shape.polygon = highlight
		polygon_shape.color = Color("RED")
		var tween = get_tree().create_tween()
		tween.tween_property(polygon_shape,"modulate:a", 0.0, 0.2)
		tween.tween_callback(polygon_shape.queue_free)


func add_debug_poly(vertices: PackedVector2Array):
	var poly = Polygon2D.new()
	add_child(poly)
	poly.polygon = vertices
	poly.modulate.a = 0.3

func rotate_direction(vector: Vector2, angle: float):
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	var new_x = vector.x * cos_angle - vector.y * sin_angle
	var new_y = vector.x * sin_angle + vector.y * cos_angle
	return Vector2(new_x,new_y)

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

func polygon_area(vertices: PackedVector2Array):
	#vertices = Geometry2D.convex_hull(vertices)
	var num_vertices = len(vertices)
	var poly_area = 0.0
	# Calculate the sum of (x_i * y_(i+1)) and (x_(i+1) * y_i) terms
	for i in range(num_vertices):
		var j = (i + 1) % num_vertices  # Wraps around to the first vertex
		poly_area += (vertices[i][0] * vertices[j][1]) - (vertices[j][0] * vertices[i][1])
	return abs(poly_area / 2.0)

func generate_rand_polygon(min_sides: int = 10, max_sides: int = 20, radius: float = 100.0):
	var num_sides = randi() % (max_sides - min_sides + 1) + min_sides
	var angle_step = 2.0 * PI / num_sides
	var vertices = []

	for i in range(num_sides):
		var angle = i * angle_step + randf() * angle_step * 0.8
		var distance = radius + randf() * radius * 0.2
		var vertex = Vector2(distance * cos(angle), distance * sin(angle))
		vertices.append(vertex)

	return vertices

func generate_shatter_polygon(vertices: PackedVector2Array) -> Dictionary:
	var centroid = find_midpoint(vertices)
	for vertex in vertices:
		centroid += vertex
	centroid /= vertices.size()

	var angle = randf() * 2.0 * PI
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	var far_point = Vector2(centroid.x + 1000.0 * cos_angle, centroid.y + 1000.0 * sin_angle)
	var opposite_far_point = Vector2(centroid.x - 1000.0 * cos_angle, centroid.y - 1000.0 * sin_angle)

	return {"start_point": opposite_far_point, "end_point": far_point, "centroid": centroid}



func generate_random_line_polygon(start_pos: Vector2, direction: Vector2, direction_variance: float = 1, segment_length_range: Vector2i = Vector2i(50,400), num_points: int = 5, just_the_line: bool = false):
	var line_path = PackedVector2Array()
	var pos: Vector2 = start_pos
	direction_variance = clamp(direction_variance, 0.0,1)
	segment_length_range = segment_length_range.clamp(Vector2i(10,10),Vector2i(400,400))

	line_path.append(start_pos - direction * 10)
	for i in range(num_points - 1):
		pos = pos + rotate_direction(direction, randf_range(-direction_variance,direction_variance)) * randi_range(segment_length_range.x,segment_length_range.y)
		line_path.append(pos)
	if just_the_line:
		return line_path
	return create_polygon_from_line(line_path,10)



func create_polygon_from_line(points: PackedVector2Array, thickness: float = 10.0):
	var half_thickness = thickness / 2
	var left_points = []
	var right_points = []

	for i in range(points.size() - 1):
		# Calculate segment vector
		var segment = Vector2(points[i+1].x - points[i].x, points[i+1].y - points[i].y)
		var perp_vector = Vector2(-segment.y,segment.x).normalized()

		if i == 0:  # First segment
			var start_left = offset_point(points[i], perp_vector, half_thickness)
			var start_right = offset_point(points[i], perp_vector, -half_thickness)
			left_points.append(start_left)
			right_points.append(start_right)

		# Calculate offsets for both sides
		var end_left = offset_point(points[i+1], perp_vector, half_thickness)
		var end_right = offset_point(points[i+1], perp_vector, -half_thickness)

		left_points.append(end_left)
		right_points.append(end_right)

	var polygon_points = []

	polygon_points.append_array(left_points)
	right_points.reverse()
	polygon_points.append_array(right_points)
	polygon_points.append(left_points[0])
	return polygon_points

func offset_point(point: Vector2, vector: Vector2, distance: float):
	return Vector2(point.x + vector.x * distance, point.y + vector.y * distance)


func create_transformation_matrix(angle: float, offset: Vector2) -> Array:
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	# Creating the transformation matrix
	return [
		[cos_angle, -sin_angle, offset.x],
		[sin_angle, cos_angle, offset.y],
		[0, 0, 1]
	]

func transform_vertices(vertices: PackedVector2Array, angle: float, offset: Vector2) -> PackedVector2Array:
	var matrix = create_transformation_matrix(angle, offset)
	var new_vals = []
	for point in vertices:
		# Convert point to homogeneous coordinates
		var point_h = [point.x, point.y, 1]
		# Matrix multiplication
		var transformed_point_h = [
			matrix[0][0] * point_h[0] + matrix[0][1] * point_h[1] + matrix[0][2] * point_h[2],
			matrix[1][0] * point_h[0] + matrix[1][1] * point_h[1] + matrix[1][2] * point_h[2],
			1 # The homogeneous coordinate, can be ignored for the final point
		]
		# Convert back to Cartesian coordinates and append to new values
		new_vals.append(Vector2(transformed_point_h[0], transformed_point_h[1]))
	return PackedVector2Array(new_vals)


func find_midpoint(vertices):
	vertices = Geometry2D.convex_hull(vertices)
	var sum = Vector2.ZERO
	for vertex in vertices:
		sum += vertex
	return sum / vertices.size()


func on_debug_polygons(boolean: bool):
	show_debug_polygons = boolean

func _on_mouse_entered() -> void:
	Events.debug_text.emit(asteroid_polygon.polygon)

