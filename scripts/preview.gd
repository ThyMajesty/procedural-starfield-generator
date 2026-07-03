extends SubViewportContainer

@onready var camera: Camera2D = get_node("SubViewport/Node2D/Camera2D")

# Render to Sprite2D, camera controls zoom/drag

var dragging := false
var drag_start_mouse: Vector2
var drag_start_cam_pos: Vector2

func _ready() -> void:
	$SubViewport.size = size

func _on_resized() -> void:
	$SubViewport.size = size

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(event.position, 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(event.position, 1.1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			drag_start_mouse = event.position
			drag_start_cam_pos = camera.position

	elif event is InputEventMouseMotion and dragging:
		camera.position -= event.relative / camera.zoom

	# elif event is InputEventMouseMotion and dragging:
	# 	var delta = (event.position - drag_start_mouse) * camera.zoom
	# 	camera.position = drag_start_cam_pos - delta

func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := _screen_to_world(screen_pos)
	camera.zoom *= factor
	camera.zoom = camera.zoom.clamp(Vector2(0.05, 0.05), Vector2(10, 10))
	var after := _screen_to_world(screen_pos)
	camera.position += before - after

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var center := size / 2.0
	return camera.position + (screen_pos - center) / camera.zoom