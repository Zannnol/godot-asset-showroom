extends Control

# Signal to main_showroom.gd when a shader is selected
signal shader_override_changed(shader_id: int)

# References to the scene’s 3D nodes
@export var pedestal: Node3D
@export var asset_pivot: Node3D
@export var reference_spheres: Node3D
@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D

@export var camera_shader_rect: ColorRect

# References to UI elements
@onready var check_pedestal: CheckBox = $LeftSidebar/Content/CheckPedestal
@onready var check_spheres: CheckBox = $LeftSidebar/Content/CheckSpheres

@onready var label_hdri: Label = $LeftSidebar/Content/LabelHDRI
@onready var slider_hdri: HSlider = $LeftSidebar/Content/SliderHDRI

@onready var label_light_energy: Label = $LeftSidebar/Content/LabelLightEnergy
@onready var slider_light_energy: HSlider = $LeftSidebar/Content/SliderLightEnergy

@onready var label_light_temp: Label = $LeftSidebar/Content/LabelLightTemp
@onready var slider_light_temp: HSlider = $LeftSidebar/Content/SliderLightTemp

# References to UI elements StatsPanel
@onready var label_name: Label = $RightSidebar/VBoxContainer/StatsPanel/Content/LabelName
@onready var label_triangles: Label = $RightSidebar/VBoxContainer/StatsPanel/Content/LabelTriangles
@onready var label_vertices: Label = $RightSidebar/VBoxContainer/StatsPanel/Content/LabelVertices
@onready var label_surfaces: Label = $RightSidebar/VBoxContainer/StatsPanel/Content/LabelSurfaces
@onready var label_dimensions: Label = $RightSidebar/VBoxContainer/StatsPanel/Content/LabelDimensions

# References to UI elements UVPanel
@onready var btn_expand: Button = $RightSidebar/VBoxContainer/UVPanel/Content/HeaderContainer/BtnExpand
@onready var option_uv_surface: OptionButton = $RightSidebar/VBoxContainer/UVPanel/Content/UVSurfaceSelector
@onready var uv_texture_rect: TextureRect = $RightSidebar/VBoxContainer/UVPanel/Content/UVTextureRect

# References to UI elements MaterialPanel
@onready var option_shader: OptionButton = $RightSidebar/VBoxContainer/MaterialPanel/Content/OptionButton

# References to UI elements UVModalWindow
@onready var uv_modal: Control = $UVModalWindow
@onready var large_uv_texture_rect: TextureRect = $UVModalWindow/Content/LargeUVTextureRect
@onready var btn_close_modal: Button = $UVModalWindow/Content/BtnClose

# References to UI elements CameraShader
@onready var shader_option_button: OptionButton = $LeftSidebar/Content/ShaderOptionButton
@onready var shader_params_container: VBoxContainer = $LeftSidebar/Content/ShaderParamsContainer
@onready var btn_new_shader: Button = $LeftSidebar/Content/HBoxContainer/BtnNewShader
@onready var btn_import_shader: Button = $LeftSidebar/Content/HBoxContainer/BtnImportShader

# Dynamically store loaded shaders
var loaded_shaders: Array[Shader] = []

func _ready() -> void:
	# Connecting visibility signals
	check_pedestal.toggled.connect(_on_pedestal_toggled)
	check_spheres.toggled.connect(_on_spheres_toggled)

	# Connecting the sliders
	slider_hdri.value_changed.connect(_on_hdri_energy_changed)
	slider_light_energy.value_changed.connect(_on_light_energy_changed)
	slider_light_temp.value_changed.connect(_on_light_temp_changed)

	# Initialising default values on launch
	_on_hdri_energy_changed(slider_hdri.value)
	_on_light_energy_changed(slider_light_energy.value)
	_on_light_temp_changed(slider_light_temp.value)
	
	# Check if there's an object already on the scene
	if asset_pivot:
		update_asset_info(asset_pivot)
	
	# Setup the ShaderMat
	_setup_shader_options()
	
	# Setup UV Selector
	_setup_uv_selector()
	
	# Setup CameraShader Controls
	_setup_camera_shader_interface()
	
	# Expand and close UV layout
	btn_expand.pressed.connect(_on_expand_uv_pressed)
	btn_close_modal.pressed.connect(_on_close_modal_pressed)

func _on_pedestal_toggled(toggled_on: bool) -> void:
	if pedestal:
		pedestal.visible = toggled_on

func _on_spheres_toggled(toggled_on: bool) -> void:
	if reference_spheres:
		reference_spheres.visible = toggled_on

func _on_hdri_energy_changed(value: float) -> void:
	label_hdri.text = "HDRI Energy: %.1f" % value
	if world_environment and world_environment.environment:
		var env := world_environment.environment
		# Adjusts the intensity of the sky/panorama background
		env.background_energy_multiplier = value
		# Adjusts the intensity of the ambient light emitted by the HDRI
		env.ambient_light_energy = value

func _on_light_energy_changed(value: float) -> void:
	label_light_energy.text = "Light Energy: %.1f" % value
	if directional_light:
		directional_light.light_energy = value

func _on_light_temp_changed(value: float) -> void:
	label_light_temp.text = "Color Temp: %d K" % int(value)
	if directional_light:
		directional_light.light_color = kelvin_to_rgb(value)

# Algorithm for converting Kelvin (1000K – 40000K) to colour (RGB)
func kelvin_to_rgb(k: float) -> Color:
	var temp := k / 100.0
	var red: float
	var green: float
	var blue: float

	# Red
	if temp <= 66.0:
		red = 255.0
	else:
		red = temp - 60.0
		red = 329.698727446 * pow(red, -0.1332047592)
		red = clamp(red, 0.0, 255.0)

	# Green
	if temp <= 66.0:
		green = temp
		green = 99.4708025861 * log(green) - 161.1195681661
		green = clamp(green, 0.0, 255.0)
	else:
		green = temp - 60.0
		green = 288.1221695283 * pow(green, -0.0755148492)
		green = clamp(green, 0.0, 255.0)

	# Blue
	if temp >= 66.0:
		blue = 255.0
	elif temp <= 19.0:
		blue = 0.0
	else:
		blue = temp - 10.0
		blue = 138.5177312231 * log(blue) - 305.0447927307
		blue = clamp(blue, 0.0, 255.0)

	return Color(red / 255.0, green / 255.0, blue / 255.0)

# ---------------- Stats panel & UV functions ---------------------
# Function called each time a new object is loaded onto the base
func update_asset_info(target_node: Node3D) -> void:
	if not target_node:
		return

	var total_triangles := 0
	var total_vertices := 0
	var total_surfaces := 0
	var combined_aabb := AABB()
	var has_mesh := false

	# Retrieves all MeshInstance3D objects in the node (including children)
	var mesh_nodes := target_node.find_children("*", "MeshInstance3D", true, false)

	for mesh_node in mesh_nodes:
		var instance := mesh_node as MeshInstance3D
		if not instance or not instance.mesh:
			continue

		var mesh := instance.mesh
		var surfaces := mesh.get_surface_count()
		total_surfaces += surfaces

		for i in range(surfaces):
			var arrays := mesh.surface_get_arrays(i)
			if arrays.is_empty():
				continue

			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

			total_vertices += vertices.size()

			if indices.size() > 0:
				total_triangles += int(indices.size() / 3.0)
			else:
				total_triangles += int(vertices.size() / 3.0)

		# Calculating the size of the object (Bounding Box)
		# Transforms the local AABB into the target node's space
		var mesh_aabb := instance.transform * instance.get_aabb()
		if not has_mesh:
			combined_aabb = mesh_aabb
			has_mesh = true
		else:
			combined_aabb = combined_aabb.merge(mesh_aabb)

	# Updating the UI display
	# Retrieving the asset name (from the source file or the child node)
	var display_name := target_node.name

	if target_node.get_child_count() > 0:
		var child := target_node.get_child(0)
		if child.scene_file_path != "":
			display_name = child.scene_file_path.get_file().get_basename()
		else:
			display_name = child.name
	label_name.text = "Name: %s" % display_name
	label_triangles.text = "Triangles: %s" % _format_number(total_triangles)
	label_vertices.text = "Vertices: %s" % _format_number(total_vertices)
	label_surfaces.text = "Surfaces: %s" % total_surfaces
	
	var bounds_size := combined_aabb.size
	label_dimensions.text = "Size: %.2fm x %.2fm x %.2fm" % [bounds_size.x, bounds_size.y, bounds_size.z]
	
	# Clear previous UV textures
	uv_texture_rect.texture = null
	option_uv_surface.clear()
	
	if not mesh_nodes.is_empty():
		var uv_bg_color := Color(0.1, 0.1, 0.1, 1.0)
		var uv_line_color := Color(1.0, 1.0, 1.0, 0.35)
		
		# 1. Generate combined UV texture (All surfaces)
		var combined_uv: Texture2D = await UVGenerator.generate_uv_texture(mesh_nodes, Vector2i(512, 512), uv_bg_color, uv_line_color)
		
		# 2. Generate individual surface UV textures
		var surface_data: Dictionary = await UVGenerator.generate_surface_uv_textures(target_node, Vector2i(512, 512), uv_bg_color, uv_line_color)
		
		# Populate OptionButton
		option_uv_surface.add_item("All Surfaces (Combined)")
		option_uv_surface.set_item_metadata(0, combined_uv)
		
		var surface_names: Array[String] = surface_data.get("names", [])
		var surface_textures: Array[Texture2D] = surface_data.get("textures", [])
		
		for i in range(surface_textures.size()):
			option_uv_surface.add_item(surface_names[i])
			option_uv_surface.set_item_metadata(i + 1, surface_textures[i])
			
		option_uv_surface.select(0)
		_on_uv_surface_selected(0)

# Formats large numbers with " ' " (e.g. 12'450)
func _format_number(number: int) -> String:
	var string := str(number)
	var formatted := ""
	var count := 0
	for i in range(string.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "'" + formatted
		formatted = string[i] + formatted
		count += 1
	return formatted

# ---------------- Material & UV panel functions ---------------------
## Initializes the list of shaders in the OptionButton
func _setup_shader_options() -> void:
	# Selects the first option by default
	option_shader.select(0)
	# Connects the native OptionButton signal if not already connected
	if not option_shader.item_selected.is_connected(_on_shader_item_selected):
		option_shader.item_selected.connect(_on_shader_item_selected)

## Callback triggered when the user changes an option
func _on_shader_item_selected(index: int) -> void:
	var selected_id: int = option_shader.get_item_id(index)
	shader_override_changed.emit(selected_id)

## Utility method to be called when loading a new asset
func reset_shader_selection() -> void:
	option_shader.select(0)
	shader_override_changed.emit(0)

func _setup_uv_selector() -> void:
	if option_uv_surface and not option_uv_surface.item_selected.is_connected(_on_uv_surface_selected):
		option_uv_surface.item_selected.connect(_on_uv_surface_selected)

func _on_uv_surface_selected(index: int) -> void:
	var tex := option_uv_surface.get_item_metadata(index) as Texture2D
	uv_texture_rect.texture = tex
	if uv_modal.visible:
		large_uv_texture_rect.texture = tex

# ---------------- Modal Window functions ---------------------
func _on_expand_uv_pressed() -> void:
	if uv_texture_rect.texture != null:
		large_uv_texture_rect.texture = uv_texture_rect.texture
		uv_modal.show()

func _on_close_modal_pressed() -> void:
	uv_modal.hide()

# Close the modal window with "Esc" key
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and uv_modal.visible:
		uv_modal.hide()
		get_viewport().set_input_as_handled()

# ---------------- Camera Shader Functions ---------------------
# Setup the Camera Shader interface
func _setup_camera_shader_interface() -> void:
	shader_option_button.clear()
	shader_option_button.add_item("Disabled (No Shader)")
	shader_option_button.set_item_metadata(0, null)

	shader_option_button.item_selected.connect(_on_camera_shader_selected)
	btn_new_shader.pressed.connect(_on_new_shader_pressed)
	btn_import_shader.pressed.connect(_on_import_shader_pressed)

# Called on a Shader selection
func _on_camera_shader_selected(index: int) -> void:
	if not camera_shader_rect:
		return
		
	# Clear the old parameter settings
	for child in shader_params_container.get_children():
		child.queue_free()
		
	var shader := shader_option_button.get_item_metadata(index) as Shader
	if shader == null:
		camera_shader_rect.material = null
		camera_shader_rect.visible = false
		return
		
	var mat := ShaderMaterial.new()
	mat.shader = shader
	camera_shader_rect.material = mat
	camera_shader_rect.visible = true

	# Dynamically generate controls based on the shader code
	_generate_shader_controls(shader.code, mat)

# Create a new default template of a shader
func _on_new_shader_pressed() -> void:
	# Create a basic camera shader template
	var default_code := """
		shader_type canvas_item;
		uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
		
		group_uniforms Desaturation;
		uniform float saturation_amount : hint_range(0.0, 1.0) = 0.2;
		
		void fragment() {
			vec4 col = texture(SCREEN_TEXTURE, SCREEN_UV);
			// Light saturation
			float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
			col.rgb = mix(col.rgb, vec3(gray), saturation_amount);
			COLOR = col;
		}
		"""
	var shader := Shader.new()
	shader.code = default_code

	loaded_shaders.append(shader)
	var idx = shader_option_button.item_count
	shader_option_button.add_item("Custom Shader %d" % idx)
	shader_option_button.set_item_metadata(idx, shader)
	shader_option_button.select(idx)
	_on_camera_shader_selected(idx)

# Import external shaders
func _on_import_shader_pressed() -> void:
	# Opens a native FileDialog to import a .gdshader file
	var file_dialog := FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.gdshader ; Godot Shader Files"])
	file_dialog.title = "Import Camera Shader"

	file_dialog.file_selected.connect(func(path: String):
		var code := FileAccess.get_file_as_string(path)
		if not code.is_empty():
			var shader := Shader.new()
			shader.code = code

			loaded_shaders.append(shader)
			var idx = shader_option_button.item_count
			var filename = path.get_file().get_basename()
			shader_option_button.add_item(filename)
			shader_option_button.set_item_metadata(idx, shader)
			shader_option_button.select(idx)
			_on_camera_shader_selected(idx)
		file_dialog.queue_free()
	)
	
	file_dialog.canceled.connect(func():
		file_dialog.queue_free()
	)
	
	get_tree().root.add_child(file_dialog)
	file_dialog.popup_centered_ratio(0.5)

func _generate_shader_controls(code: String, material: ShaderMaterial) -> void:
	# Regex to capture lines of the following type: uniform float name: hint_range(...) = val;
	# or uniform vec4 name: source_color = vec4(...);
	var regex = RegEx.new()
	regex.compile("uniform\\s+(?<type>\\w+)\\s+(?<name>\\w+)(\\s*:\\s*(?<hint>[^=;]+))?\\s*=\\s*(?<default>[^;]+);")

	var results = regex.search_all(code)
	for result in results:
		var p_type = result.get_string("type")
		var p_name = result.get_string("name")
		var p_hint = result.get_string("hint")
		var p_default_str = result.get_string("default").strip_edges()

		# Creating a horizontal container for the label and the control
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = p_name.capitalize()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)
		
		# Case 1: Color (source_color)
		if p_type == "vec4" and "source_color" in p_hint:
			var color_picker = ColorPickerButton.new()
			color_picker.custom_minimum_size = Vector2(60, 25)
			
			var current_color = material.get_shader_parameter(p_name)
			if current_color is Color:
				color_picker.color = current_color
			else:
				# Parse la valeur par défaut du type vec4(r, g, b, a)
				if "vec4" in p_default_str:
					var inner = p_default_str.get_slice("(", 1).get_slice(")", 0)
					var parts = inner.split(",")
					if parts.size() >= 3:
						var col = Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), parts[3].to_float() if parts.size() > 3 else 1.0)
						color_picker.color = col
						material.set_shader_parameter(p_name, col) # Initialise la valeur dans le mat
					else:
						color_picker.color = Color.WHITE
				else:
					color_picker.color = Color.WHITE
			
			color_picker.color_changed.connect(func(c: Color):
				material.set_shader_parameter(p_name, c)
			)
			hbox.add_child(color_picker)
			
		# Case 2: Floating-point with range (hint_range)
		elif p_type == "float" and "hint_range" in p_hint:
			var slider = HSlider.new()
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var range_regex = RegEx.new()
			range_regex.compile("hint_range\\s*\\((?<min>[-\\d.]+)\\s*,\\s*(?<max>[-\\d.]+)")
			var range_match = range_regex.search(p_hint)
			if range_match:
				slider.min_value = range_match.get_string("min").to_float()
				slider.max_value = range_match.get_string("max").to_float()
				slider.step = 0.001 if (slider.max_value - slider.min_value) < 2.0 else 0.01
			
			var current_val = material.get_shader_parameter(p_name)
			if current_val != null:
				slider.value = current_val
			else:
				var def_val = p_default_str.to_float()
				slider.value = def_val
				material.set_shader_parameter(p_name, def_val) # Initialise la valeur dans le mat
			
			slider.value_changed.connect(func(val: float):
				material.set_shader_parameter(p_name, val)
			)
			hbox.add_child(slider)
			
		shader_params_container.add_child(hbox)
