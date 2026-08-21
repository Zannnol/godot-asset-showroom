class_name AssetImporter
extends RefCounted

## Loads a 3D file (.glb / .gltf / .obj) at runtime and centers it on its base
static func import_from_path(path: String) -> Node3D:
	var new_node: Node3D = null
	var ext := path.get_extension().to_lower()

	# Native GLTF/GLB support at runtime
	if ext in ["glb", "gltf"]:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(path, state) == OK:
			new_node = doc.generate_scene(state)
	
	# Custom runtime OBJ support
	elif ext == "obj":
		var mesh := OBJLoader.load_from_file(path)
		if mesh:
			var instance := MeshInstance3D.new()
			instance.mesh = mesh
			new_node = instance
	
	# Support for Godot project-internal files (res://)
	elif path.begins_with("res://"):
		var res = ResourceLoader.load(path)
		if res is PackedScene:
			new_node = res.instantiate()
		elif res is Mesh:
			var instance := MeshInstance3D.new()
			instance.mesh = res
			new_node = instance

	if not new_node:
		push_error("Format not supported at runtime or invalid file : " + path)
		return null

	new_node.name = path.get_file().get_basename()
	align_to_bottom_center(new_node)
	return new_node

## Calculates the bounding box and centers the object so that its base is at Y=0
static func align_to_bottom_center(node: Node3D) -> void:
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
		var center := combined_aabb.get_center()
		var bottom_y := combined_aabb.position.y
		node.position = Vector3(-center.x, -bottom_y, -center.z)
