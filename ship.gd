extends RigidBody2D

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var projectile_container: Node = $ProjectileContainer
@onready var projectile_position: Marker2D = $ProjectilePosition

var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")

const SPEED = 2000

func _ready():
	collision_polygon.polygon = polygon.polygon

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed('left_click'):
		var projectile = projectile_scene.instantiate()
		projectile_container.add_child(projectile)
		projectile.global_position = projectile_position.global_position
		#projectile.direction = (get_global_mouse_position() - projectile_position.global_position).normalized()
		projectile.direction = (Vector2.RIGHT.rotated(rotation)).normalized()



func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	var input_vector = Input.get_vector("left","right","up","down")
	if input_vector.is_zero_approx():
		constant_force = Vector2.ZERO
	else:
		set_constant_force(input_vector * SPEED)

	var angle = get_angle_to(get_global_mouse_position())
	set_constant_torque(angle * SPEED)

