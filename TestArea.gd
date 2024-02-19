extends Node2D

@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var sprite: Sprite2D = $Polygon2D/Sprite2D
@onready var label: Label = $Polygon2D/Label

@onready var polygon_2d_2: Polygon2D = $Polygon2D2
@onready var sprite_2: Sprite2D = $Polygon2D2/Sprite2D
@onready var label_2: Label = $Polygon2D2/Label

@onready var polygon_2d_3: Polygon2D = $Polygon2D3
@onready var sprite_3: Sprite2D = $Polygon2D3/Sprite2D
@onready var label_3: Label = $Polygon2D3/Label

@onready var polygon_2d_4: Polygon2D = $Polygon2D4
@onready var sprite_4: Sprite2D = $Polygon2D4/Sprite2D
@onready var label_4: Label = $Polygon2D4/Label


func _ready():
	var poly = generate_rand_polygon()
	var destructor_poly = generate_rand_polygon(4,5,45)
	var poly1 = translate_vertices(destructor_poly, Vector2(-100,0))
	destructor_poly = generate_rand_polygon(4,5,45)
	var poly2 = translate_vertices(destructor_poly, Vector2(-70,0))
	destructor_poly = generate_rand_polygon(4,5,45)
	var poly3 = translate_vertices(destructor_poly, Vector2(-30,0))
	destructor_poly = generate_rand_polygon(4,5,45)
	var poly4 = translate_vertices(destructor_poly, Vector2(10,80))
	destructor_poly = generate_rand_polygon(4,5,45)
	var poly5 = translate_vertices(destructor_poly, Vector2(90,60))
	destructor_poly = generate_rand_polygon(4,5,45)
	var poly6 = translate_vertices(destructor_poly, Vector2(5,-70))
	destructor_poly = generate_rand_polygon(4,5,45)
	var poly7 = translate_vertices(destructor_poly, Vector2(35,70))

	poly = Geometry2D.clip_polygons(poly, poly1)[0]
	poly = Geometry2D.clip_polygons(poly, poly2)[0]
	poly = Geometry2D.clip_polygons(poly, poly3)[0]
	poly = Geometry2D.clip_polygons(poly, poly4)[0]
	poly = Geometry2D.clip_polygons(poly, poly5)[0]
	poly = Geometry2D.clip_polygons(poly, poly6)[0]

	polygon_2d.polygon = poly
	polygon_2d_2.polygon = poly
	polygon_2d_3.polygon = poly
	polygon_2d_4.polygon = poly
	var area
	var centroid

	var start_time = Time.get_ticks_msec()
	for i in range(1000):
		var props = calculate_polygon_properties(poly)
		area = props.area
		centroid = props.center
	label.text = "1000 loop runtime: %s%s%s%s%s%s" % [Time.get_ticks_msec() - start_time, "ms","\narea: ",area,"\ncentroid: ",centroid]
	sprite.position = centroid

	start_time = Time.get_ticks_msec()
	for i in range(1000):
		var props = polygon_area_centroid(poly)
		area = props.area
		centroid = props.centroid
	label_2.text = "1000 loop runtime: %s%s%s%s%s%s" % [Time.get_ticks_msec() - start_time, "ms","\narea: ",area,"\ncentroid: ",centroid]
	sprite_2.position = centroid

	start_time = Time.get_ticks_msec()
	for i in range(1000):
		var poly_triangle_points = Geometry2D.triangulate_polygon(poly)
		var poly_triangles = makeTriangles(poly, poly_triangle_points)
		area = poly_triangles.area
		centroid = getPolygonCentroid(poly_triangles.triangles, area)
	label_3.text = "1000 loop runtime: %s%s%s%s%s%s" % [Time.get_ticks_msec() - start_time, "ms","\narea: ",area,"\ncentroid: ",centroid]
	sprite_3.position = centroid

	start_time = Time.get_ticks_msec()
	for i in range(1000):
		area = polygon_area(poly)
		centroid = find_midpoint(poly)
	label_4.text = "1000 loop runtime: %s%s%s%s%s%s" % [Time.get_ticks_msec() - start_time, "ms","\narea: ",area,"\ncentroid: ",centroid]
	sprite_4.position = centroid

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

func translate_vertices(vertices: PackedVector2Array, offset: Vector2):
	var new_vals = []
	for point in vertices:
		var translated_point = point + offset
		new_vals.append(translated_point)
	return PackedVector2Array(new_vals)

func polygon_area_centroid(vertices: PackedVector2Array):
	var num_vertices: int = vertices.size()
	var poly_area:= 0.0
	var poly_centroid:= Vector2.ZERO
	for i in range(num_vertices):
		var j = (i + 1) % num_vertices  # Wraps around to the first vertex
		poly_area += (vertices[i].x * vertices[j].y) - (vertices[j].x * vertices[i].y)
		poly_centroid.x += (pow(vertices[i].x, 2) + vertices[i].x * vertices[j].x + pow(vertices[j].x, 2)) * (vertices[j].y - vertices[i].y)
		poly_centroid.y -= (pow(vertices[i].y, 2) + vertices[i].y * vertices[j].y + pow(vertices[j].y, 2)) * (vertices[j].x - vertices[i].x)
	poly_area /= 2
	poly_centroid = poly_centroid / (6 * poly_area)
	return {
		"area": abs(poly_area),
		"centroid": poly_centroid
		}

func calculate_polygon_properties(points):
	var center = Vector2.ZERO
	var area = 0
	for i in points.size():
		var next = 0 if i + 1 == points.size() else i + 1
		var p = points[i]
		var q = points[next]
		area += (p.x * q.y) - (q.x * p.y)
		center.x += (pow(p.x, 2) + p.x * q.x + pow(q.x, 2)) * (q.y - p.y)
		center.y -= (pow(p.y, 2) + p.y * q.y + pow(q.y, 2)) * (q.x - p.x)
	center = (center / 6) / area
	return {
		"center": center,
		"area": area
	}
func getPolygonArea(poly: PackedVector2Array, triangle_points: Array) -> float:
	var total_area: float = 0.0
	#var triangle_points = Geometry2D.triangulate_polygon(poly)
	for i in range(triangle_points.size() / 3):
		var index: int = i * 3
		var points: Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
		total_area += getTriangleArea(points)
	return total_area

#triangulates a polygon and sums the weighted centroids of all triangles
func getPolygonCentroid(triangles: Array, total_area: float) -> Vector2:
	var weighted_centroid:= Vector2.ZERO
	for triangle in triangles:
		weighted_centroid += (triangle.centroid * triangle.area)
	return weighted_centroid / total_area

func makeTriangles(poly: PackedVector2Array, triangle_points: PackedInt32Array, with_area: bool = true, with_centroid: bool = true) -> Dictionary:
	var triangles: Array = []
	var total_area: float = 0.0
	for i in range(triangle_points.size() / 3):
		var index: int = i * 3
		var points: PackedVector2Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]

		var area: float = 0.0
		if with_area:
			area = getTriangleArea(points)

		var centroid:= Vector2.ZERO
		if with_centroid:
			centroid = getTriangleCentroid(points)

		total_area += area

		triangles.append(makeTriangle(points, area, centroid))
	return {"triangles": triangles, "area": total_area}

func makeTriangle(points: PackedVector2Array, area: float, centroid: Vector2) -> Dictionary:
	return {"points": points, "area": area, "centroid": centroid}

func getTriangleArea(points: PackedVector2Array) -> float:
	var a: float = (points[1] - points[2]).length()
	var b: float = (points[2] - points[0]).length()
	var c: float = (points[0] - points[1]).length()
	var s: float = (a + b + c) * 0.5

	var value: float = s * (s - a) * (s - b) * (s - c)
	if value < 0.0:
		return 1.0
	var area: float = sqrt(value)
	return area

func getTriangleCentroid(points: PackedVector2Array) -> Vector2:
	var ab: Vector2 = points[1] - points[0]
	var ac: Vector2 = points[2] - points[0]
	var centroid: Vector2 = points[0] + (ab + ac) / 3.0
	return centroid

func triangulatePolygon(poly: PackedVector2Array, with_area: bool = true, with_centroid: bool = true) -> Dictionary:
	var total_area: float = 0.0
	var triangle_points: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	return makeTriangles(poly, triangle_points, with_area, with_centroid)

func polygon_area(vertices: PackedVector2Array):
	var num_vertices = len(vertices)
	var poly_area = 0.0
	# Calculate the sum of (x_i * y_(i+1)) and (x_(i+1) * y_i) terms
	for i in range(num_vertices):
		var j = (i + 1) % num_vertices  # Wraps around to the first vertex
		poly_area += (vertices[i][0] * vertices[j][1]) - (vertices[j][0] * vertices[i][1])
	return abs(poly_area / 2.0)

func find_midpoint(vertices: PackedVector2Array):
	vertices = Geometry2D.convex_hull(vertices)
	var sum = Vector2.ZERO
	for vertex in vertices:
		sum += vertex
	return sum / vertices.size()
