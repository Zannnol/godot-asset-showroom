extends Camera3D

@export var target_path: NodePath = "../Stage/AssetPivot"
@export_group("Limits")
@export var min_distance: float = 0.5
@export var max_distance: float = 20.0
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

@export_group("Sensitivity")
@export var orbit_sensitivity: float = 0.25
@export var zoom_sensitivity: float = 0.5
@export var pan_sensitivity: float = 0.003

var _target: Node3D
var _distance: float = 6.5
var _yaw: float = 0.0
var _pitch: float = -10.0
var _focus_offset: Vector3 = Vector3.ZERO
var _is_orbiting: bool = false
var _is_panning: bool = false

func _ready() -> void:
	if has_node(target_path):
		_target = get_node(target_path)
	_update_camera_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Dynamic adjust of zoom step based on the actual distance
			var step := maxf(zoom_sensitivity, _distance * 0.05)
			_distance = clamp(_distance - step, min_distance, max_distance)
			_update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var step := maxf(zoom_sensitivity, _distance * 0.05)
			_distance = clamp(_distance + step, min_distance, max_distance)
			_update_camera_position()

	elif event is InputEventMouseMotion:
		if _is_orbiting:
			_yaw -= event.relative.x * orbit_sensitivity
			_pitch = clamp(_pitch - event.relative.y * orbit_sensitivity, min_pitch, max_pitch)
			_update_camera_position()
		elif _is_panning and _target:
			var right := global_transform.basis.x
			var up := global_transform.basis.y
			# Shift the camera's viewpoint rather than moving the 3D node
			_focus_offset -= (right * event.relative.x - up * event.relative.y) * pan_sensitivity * _distance
			_update_camera_position()

## Dynamically recalculates the zoom bounds and the ideal distance based on the model's AABB
func focus_on_aabb(aabb: AABB) -> void:
	# Reset pan at the import
	_focus_offset = Vector3.ZERO
	
	var max_size := aabb.get_longest_axis_size()
	if max_size <= 0.001:
		max_size = 1.0

	# Dynamically adjusts the min/max limits based on the scale
	min_distance = max_size * 0.1
	max_distance = max_size * 10.0
	
	# Adjust the camera's Far Clip range if the object is huge
	far = maxf(far, max_distance * 2.0)

	# Sets the ideal zoom to approximately 1.8 times the object's maximum size
	_distance = max_size * 1.8
	_update_camera_position()

## Adjusts the camera's focus point and distance (called during import)
func focus_on(focus_point: Vector3, new_distance: float = -1.0) -> void:
	_focus_offset = focus_point
	if new_distance > 0.0:
		_distance = clamp(new_distance, min_distance, max_distance)
	_update_camera_position()

func _update_camera_position() -> void:
	if not _target:
		return
	
	# The camera is aimed at the pivot point plus the user offset
	var target_center := _target.global_position + _focus_offset
	var rot_yaw := Quaternion(Vector3.UP, deg_to_rad(_yaw))
	var rot_pitch := Quaternion(Vector3.RIGHT, deg_to_rad(_pitch))
	var combined_rot := rot_yaw * rot_pitch
	
	var offset := combined_rot * Vector3(0, 0, _distance)
	global_position = target_center + offset
	look_at(target_center, Vector3.UP)
