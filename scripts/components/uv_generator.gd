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
	viewport.transparent_bg = false
	viewport.world_3d = World3D.new()
	#Apply the background color if it is transparent; otherwise, use an opaque background
	if background_color.a < 1.0:
		viewport.transparent_bg = true
	else:
		viewport.transparent_bg = false
	
	# Creating an orthographic camera to capture the 2D plane [-1, 1]
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.0
	camera.position = Vector3(0, 0, 1)
	viewport.add_child(camera)

	# 2. Preparing the shader material
	var shader := load("res://shaders/production/uv_renderer.gdshader") as Shader
	if not shader:
		push_error("UVGenerator: Unable to load the shader at the location res://shaders/production/uv_renderer.gdshader")
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
