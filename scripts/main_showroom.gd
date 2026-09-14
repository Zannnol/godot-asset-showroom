extends Node3D

@export var asset_pivot: Node3D
@export var ui_overlay: Control
@export var camera_3d: Camera3D

# Loading Shader Resources
const SHADER_UV_CHECKER = preload("res://shaders/production/uv_checker.gdshader")
const SHADER_WORLD_NORMALS = preload("res://shaders/production/world_normals.gdshader")
const SHADER_CLAY = preload("res://shaders/production/clay_matcap.gdshader")

# Dictionary of Pre-Instantiated Override Materials
var _override_materials: Dictionary = {}
var _current_shader_id: int = 0

func _ready() -> void:
	# Material Initialization
	_init_override_materials()
	
	# Listen for the drag-and-drop file event on the window
	get_window().files_dropped.connect(_on_files_dropped)
	
	# Listening for the shader-change signal emitted by the UI
	if ui_overlay and ui_overlay.has_signal("shader_override_changed"):
		ui_overlay.shader_override_changed.connect(_on_shader_override_changed)

func _init_override_materials() -> void:
	var mat_uv := ShaderMaterial.new()
	mat_uv.shader = SHADER_UV_CHECKER
	_override_materials[1] = mat_uv

	var mat_normals := ShaderMaterial.new()
	mat_normals.shader = SHADER_WORLD_NORMALS
	_override_materials[2] = mat_normals

	var mat_clay := ShaderMaterial.new()
	mat_clay.shader = SHADER_CLAY
	_override_materials[4] = mat_clay

func _on_files_dropped(files: PackedStringArray) -> void:
	if files.is_empty():
		return
	load_asset(files[0])

func load_asset(path: String) -> void:
	var new_asset := AssetImporter.import_from_path(path)
	if not new_asset:
		return

	# Removes the object currently under the pivot
	for child in asset_pivot.get_children():
		child.queue_free()

	# Add the new 3D model
	asset_pivot.add_child(new_asset)

	# Reset the UI selection to “Default (PBR)”
	if ui_overlay and ui_overlay.has_method("reset_shader_selection"):
		ui_overlay.reset_shader_selection()
	else:
		_on_shader_override_changed(0)

	# Updates the statistics in the right-hand panel
	if ui_overlay and ui_overlay.has_method("update_asset_info"):
		ui_overlay.update_asset_info(asset_pivot)
	
	# Adjust the camera's focus and distance
	_frame_asset(new_asset)

## Callback that responds to the signal from ui_overlay.gd
func _on_shader_override_changed(shader_id: int) -> void:
	_current_shader_id = shader_id
	if not asset_pivot:
		return

	# If WireFrame is selected (ID 3)
	if shader_id == 3:
		# Resets material overrides
		# Apply the neutral Clay (MatCap) material underneath
		var clay_mat: Material = _override_materials.get(4, null) # ID 4 = Clay / MatCap
		_apply_material_override_recursive(asset_pivot, clay_mat)
		# Enables the Viewport's native wireframe mode
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
		return
	else:
		# Turns off Wireframe mode for all other modes
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED

	var mat_override: Material = _override_materials.get(shader_id, null)
	_apply_material_override_recursive(asset_pivot, mat_override)

## Application / Recursive removal of `material_override` from all `MeshInstance3D` instances
func _apply_material_override_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
		# If the mesh has explicitly assigned surface materials
		if node.mesh:
			for i in range(node.mesh.get_surface_count()):
				node.set_surface_override_material(i, mat)

	for child in node.get_children():
		_apply_material_override_recursive(child, mat)

## Calculates the center and size of the model to orient the camera
func _frame_asset(node: Node3D) -> void:
	if not camera_3d:
		return

	var combined_aabb := AABB()
	var has_mesh := false

	var mesh_nodes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		mesh_nodes.append(node)

	for mesh_node in mesh_nodes:
		var instance := mesh_node as MeshInstance3D
		if instance and instance.mesh:
			var mesh_aabb := instance.get_aabb()
			if not has_mesh:
				combined_aabb = mesh_aabb
				has_mesh = true
			else:
				combined_aabb = combined_aabb.merge(mesh_aabb)

	if has_mesh:
		# Adjusts the size of the UV map to match the actual size of the imported model
		_adjust_checker_scale(combined_aabb)
		# If the camera has `focus_on_aabb`, we dynamically adjust the bounds and distance
		if camera_3d.has_method("focus_on_aabb"):
			camera_3d.focus_on_aabb(combined_aabb)
		elif camera_3d.has_method("focus_on"):
			var focus_center := Vector3(0, combined_aabb.size.y * 0.5, 0)
			var max_dim := maxf(combined_aabb.size.x, maxf(combined_aabb.size.y, combined_aabb.size.z))
			camera_3d.focus_on(focus_center, max_dim * 2.2)

## Adjusts the density of the UV checkerboard pattern to prevent moiré patterns on very large or very small objects
func _adjust_checker_scale(aabb: AABB) -> void:
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var mat_uv := _override_materials.get(1, null) as ShaderMaterial
	
	if mat_uv:
		# Calculates a responsive scale: the smaller the object, the finer the minimum UV density remains
		# For an object that is 1 m long -> scale = ~16.0
		# For an object that is 10 cm -> scale = ~10.0
		# For an object that is 100 m long -> scale = ~150.0
		var calculated_scale := clampf(max_dim * 1.5 + 8.0, 10.0, 300.0)
		mat_uv.set_shader_parameter("grid_scale", calculated_scale)
