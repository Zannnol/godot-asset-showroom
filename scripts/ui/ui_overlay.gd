extends Control

# References to the scene’s 3D nodes
@export var pedestal: Node3D
@export var asset_pivot: Node3D
@export var reference_spheres: Node3D
@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D

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
@onready var uv_texture_rect: TextureRect = $RightSidebar/VBoxContainer/UVPanel/Content/UVTextureRect

# References to UI elements UVModalWindow
@onready var uv_modal: Control = $UVModalWindow
@onready var large_uv_texture_rect: TextureRect = $UVModalWindow/Content/LargeUVTextureRect
@onready var btn_close_modal: Button = $UVModalWindow/Content/BtnClose

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

# ---------------- Stats panel functions ---------------------
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
		var mesh_aabb := instance.get_aabb()
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
	
	# Generate and assign UV texture
	uv_texture_rect.texture = null
	if not mesh_nodes.is_empty():
		var uv_bg_color := Color(0.1, 0.1, 0.1, 1.0)
		var uv_line_color := Color(1.0, 1.0, 1.0, 0.35)
		
		var uv_tex = await UVGenerator.generate_uv_texture(mesh_nodes, Vector2i(512, 512), uv_bg_color, uv_line_color)
		if uv_tex is Texture2D:
			uv_texture_rect.texture = uv_tex

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

# ---------------- UV panel functions ---------------------
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
