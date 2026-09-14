shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 clay_color : source_color = vec4(0.72, 0.67, 0.62, 1.0);

void fragment() {
	vec3 view_normal = (VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	if (!FRONT_FACING) {
		view_normal = -view_normal;
	}
	
	float diffuse = clamp(dot(view_normal, normalize(vec3(0.3, 0.5, 0.8))), 0.0, 1.0);
	float ambient = 0.25;
	float rim = pow(1.0 - clamp(dot(view_normal, vec3(0.0, 0.0, 1.0)), 0.0, 1.0), 2.5) * 0.3;
	
	ALBEDO = clay_color.rgb * (diffuse * 0.75 + ambient) + vec3(rim);
}