class_name UVGenerator
extends Node

## Generates a 2D texture representing the UV layout of one or more meshes.
static func generate_uv_texture(
	mesh_data: Variant,
	resolution: Vector2i = Vector2i(512, 512),
	background_color: Color = Color(0.1, 0.1, 0.1, 1.0),
	line_color: Color = Color.WHITE
) -> Variant:
	
	# Input Normalization (Single Mesh, MeshInstance3D, or Array)
	var meshes_to_render: Array[Mesh] = []
	
	if mesh_data is Mesh:
		meshes_to_render.append(mesh_data)
	elif mesh_data is MeshInstance3D and mesh_data.mesh:
		meshes_to_render.append(mesh_data.mesh)
	elif mesh_data is Array:
		for item in mesh_data:
			if item is Mesh:
				meshes_to_render.append(item)
			elif item is MeshInstance3D and item.mesh:
				meshes_to_render.append(item.mesh)

	if meshes_to_render.is_empty():
		push_warning("UVGenerator: No valid mesh was provided.")
		return null

	# 1. Creating a Temporary SubViewport
	var viewport := SubViewport.new()
	viewport.size = resolution
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.transparent_bg = (background_color.a < 1.0)
	viewport.world_3d = World3D.new()
	
	# Creating an orthographic camera to capture the 2D plane [-1, 1]
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.0
	camera.position = Vector3(0, 0, 1)
	viewport.add_child(camera)

	# 2. Preparing the shader material
	var shader := load("res://shaders/production/uv_renderer.gdshader") as Shader
	if not shader:
		push_error("UVGenerator: Unable to load shader res://shaders/production/uv_renderer.gdshader")
		viewport.queue_free()
		return null

	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = shader
	shader_mat.set_shader_parameter("line_color", line_color)

	# 3. Create MeshInstance3D objects for each provided mesh
	for mesh in meshes_to_render:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.material_override = shader_mat
		viewport.add_child(mesh_instance)

	# 4. Temporary addition to the main scene tree
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		viewport.queue_free()
		return null

	tree.root.add_child(viewport)
	
	# Waiting for the GPU to complete rendering the frame
	await tree.process_frame
	await tree.process_frame

	# 5. Texture Extraction and Conversion
	var texture_rect := viewport.get_texture()
	var img := texture_rect.get_image()
	var texture := ImageTexture.create_from_image(img)

	# Cleaning
	viewport.queue_free()

	return texture


## Generates an array of textures and names, one for each individual surface/sub-mesh.
static func generate_surface_uv_textures(
	node: Node,
	resolution: Vector2i = Vector2i(512, 512),
	background_color: Color = Color(0.1, 0.1, 0.1, 1.0),
	line_color: Color = Color.WHITE
) -> Dictionary:
	var result := {
		"names": [] as Array[String],
		"textures": [] as Array[Texture2D]
	}

	var mesh_nodes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		mesh_nodes.append(node)

	for mesh_node in mesh_nodes:
		var instance := mesh_node as MeshInstance3D
		if not instance or not instance.mesh:
			continue

		var mesh := instance.mesh
		for surface_idx in range(mesh.get_surface_count()):
			# Extracting a Single Surface
			var single_surface_mesh := _extract_single_surface(mesh, surface_idx)
			if not single_surface_mesh:
				continue

			# Explicit String typing for the surface name
			var surf_name: String = mesh.surface_get_name(surface_idx)
			if surf_name.is_empty():
				surf_name = "%s (Surf %d)" % [instance.name, surface_idx + 1]

			var tex: Texture2D = await generate_uv_texture(single_surface_mesh, resolution, background_color, line_color)
			if tex:
				(result["names"] as Array[String]).append(surf_name)
				(result["textures"] as Array[Texture2D]).append(tex)

	return result


## Isolates a single surface in a temporary ArrayMesh
static func _extract_single_surface(mesh: Mesh, surface_idx: int) -> ArrayMesh:
	var arrays: Array = mesh.surface_get_arrays(surface_idx)
	if arrays.is_empty():
		return null

	var single_mesh := ArrayMesh.new()
	var primitive_type: Mesh.PrimitiveType = mesh.surface_get_primitive_type(surface_idx)
	var format: int = mesh.surface_get_format(surface_idx)

	single_mesh.add_surface_from_arrays(primitive_type, arrays, [], {}, format)
	return single_mesh
