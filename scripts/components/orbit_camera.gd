extends Node3D

@export var sensitivity: float = 0.005
@export var zoom_speed: float = 0.3
@export var min_zoom: float = 1.0
@export var max_zoom: float = 8.0

@onready var camera: Camera3D = $Camera3D

var _is_rotating: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_rotating = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z = clamp(camera.position.z - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z = clamp(camera.position.z + zoom_speed, min_zoom, max_zoom)

	if event is InputEventMouseMotion and _is_rotating:
		rotate_y(-event.relative.x * sensitivity)
		var new_rot_x = rotation.x - event.relative.y * sensitivity
		rotation.x = clamp(new_rot_x, deg_to_rad(-80), deg_to_rad(80))
