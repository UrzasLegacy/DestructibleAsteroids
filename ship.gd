extends RigidBody2D

@export var laser_sound1: AudioStream

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var projectile_container: Node = $ProjectileContainer
@onready var projectile_position: Marker2D = $ProjectilePosition
@onready var weapon_cooldown: Timer = $WeaponCooldown


var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
var can_fire := true
const SPEED = 2000

func _ready():
	collision_polygon.polygon = polygon.polygon
	weapon_cooldown.timeout.connect(on_weapon_cooldown)

func _physics_process(_delta: float) -> void:
	if can_fire and Input.is_action_pressed('left_click'):
		weapon_cooldown.start()
		can_fire = false
		var projectile = projectile_scene.instantiate()
		projectile_container.add_child(projectile)
		projectile.global_position = projectile_position.global_position
		#projectile.direction = (get_global_mouse_position() - projectile_position.global_position).normalized()
		projectile.direction = (Vector2.RIGHT.rotated(rotation)).normalized()
		SFX.play(laser_sound1, -20)


func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	var input_vector = Input.get_vector("left","right","up","down")
	if input_vector.is_zero_approx():
		constant_force = Vector2.ZERO
	else:
		set_constant_force(input_vector * SPEED)
	var angle = get_angle_to(get_global_mouse_position())
	set_constant_torque(angle * SPEED)

func on_weapon_cooldown():
	can_fire = true
