extends Node3D

@export var asset_pivot: Node3D
@export var ui_overlay: Control
@export var camera_3d: Camera3D

func _ready() -> void:
	# Listen for the drag-and-drop file event on the window
	get_window().files_dropped.connect(_on_files_dropped)

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

	# Updates the statistics in the right-hand panel
	if ui_overlay and ui_overlay.has_method("update_asset_info"):
		ui_overlay.update_asset_info(asset_pivot)
	
	# Adjust the camera's focus and distance
	_frame_asset(new_asset)

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
		# Visée sur le centre vertical du modèle (mi-hauteur)
		var focus_center := Vector3(0, combined_aabb.size.y * 0.5, 0)
		
		# Calcul de la distance idéale basée sur la plus grande dimension
		var max_dim := maxf(combined_aabb.size.x, maxf(combined_aabb.size.y, combined_aabb.size.z))
		var ideal_distance := max_dim * 2.2

		# Transmet les valeurs à orbit_camera.gd via focus_on()
		if camera_3d.has_method("focus_on"):
			camera_3d.focus_on(focus_center, ideal_distance)
