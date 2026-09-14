shader_type spatial;
render_mode unshaded, cull_disabled;

void fragment() {
	vec3 world_normal = NORMAL;
	// If the face is viewed from the inside, the normal is reversed for display purposes
	if (!FRONT_FACING) {
		world_normal = -world_normal;
	}
	ALBEDO = world_normal * 0.5 + 0.5;
}