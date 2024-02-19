extends Camera2D

var default_zoom: Vector2 = Vector2(1,1)
var current_zoom: Vector2

func _ready():
	current_zoom = default_zoom

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mw_up"):
		current_zoom += Vector2(0.2,0.2)
	if event.is_action_pressed("mw_down"):
		current_zoom -= Vector2(0.2,0.2)
	current_zoom = clamp(current_zoom,Vector2(0.15,0.15),Vector2(6,6))

func _process(delta):
	if current_zoom != zoom:
		zoom = lerp(zoom,current_zoom,5 * delta)
