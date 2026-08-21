class_name OBJLoader
extends RefCounted

## Reads an .obj file at runtime and returns an ArrayMesh
static func load_from_file(path: String) -> ArrayMesh:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot open OBJ file: " + path)
		return null

	var positions: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var normals: Array[Vector3] = []

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("#") or line.is_empty():
			continue

		var parts := line.split(" ", false)
		if parts.size() < 2:
			continue

		match parts[0]:
			"v": # Vertex position
				positions.append(Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float()))
			"vt": # UV coordinates
				uvs.append(Vector2(parts[1].to_float(), 1.0 - parts[2].to_float())) # Invert V for Godot
			"vn": # Normal vector
				normals.append(Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float()))
			"f": # Face definition
				var face_vertices := parts.slice(1)
				for i in range(1, face_vertices.size() - 1):
					_add_obj_vertex(st, face_vertices[0], positions, uvs, normals)
					_add_obj_vertex(st, face_vertices[i], positions, uvs, normals)
					_add_obj_vertex(st, face_vertices[i + 1], positions, uvs, normals)

	file.close()

	# Generate normals if not present
	if normals.is_empty():
		st.generate_normals()
	
	# Generate ID array for the stats on UI
	st.index()

	# Apply backface culling to "patch" the inverted Y when opening files from differents softwares (Blender, Maya, Max, ...)
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED # Affiche les deux côtés des faces
	mat.roughness = 0.5
	mat.metallic = 0.0

	st.index()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh

static func _add_obj_vertex(st: SurfaceTool, token: String, pos_arr: Array[Vector3], uv_arr: Array[Vector2], norm_arr: Array[Vector3]) -> void:
	var indices := token.split("/")

	var v_idx := indices[0].to_int() - 1
	var vt_idx := -1
	var vn_idx := -1

	if indices.size() > 1 and not indices[1].is_empty():
		vt_idx = indices[1].to_int() - 1
	if indices.size() > 2 and not indices[2].is_empty():
		vn_idx = indices[2].to_int() - 1

	if vt_idx >= 0 and vt_idx < uv_arr.size():
		st.set_uv(uv_arr[vt_idx])
	if vn_idx >= 0 and vn_idx < norm_arr.size():
		st.set_normal(norm_arr[vn_idx])
	if v_idx >= 0 and v_idx < pos_arr.size():
		st.add_vertex(pos_arr[v_idx])
