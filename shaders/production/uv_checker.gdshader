shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float grid_scale : hint_range(1.0, 500.0, 1.0) = 20.0;
uniform vec4 color_a : source_color = vec4(0.85, 0.85, 0.85, 1.0);
uniform vec4 color_b : source_color = vec4(0.15, 0.15, 0.15, 1.0);

void fragment() {
	vec2 uv = UV;
	vec2 check_uv = floor(uv * grid_scale);
	float checker = mod(check_uv.x + check_uv.y, 2.0);
	ALBEDO = mix(color_a.rgb, color_b.rgb, checker);
}