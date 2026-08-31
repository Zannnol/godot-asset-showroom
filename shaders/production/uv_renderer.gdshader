shader_type spatial;
render_mode unshaded, wireframe, cull_disabled;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
	// Retrieves the UV0 channel of the vertex
	vec2 uv = UV;
	
	// Converts UV coordinates (0..1) to normalized device coordinates (-1..1)
	// (By inverting the Y axis, since in 2D screen space/the viewport, the Y axis is inverted)
	vec3 position_uv = vec3(uv.x * 2.0 - 1.0, (1.0 - uv.y) * 2.0 - 1.0, 0.0);
	
	// Replaces the vertex's position with its position in UV space
	POSITION = vec4(position_uv, 1.0);
}

void fragment() {
	ALBEDO = line_color.rgb;
	ALPHA = line_color.a;
}