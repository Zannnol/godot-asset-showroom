shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

group_uniforms Palette_Stylisee;
uniform vec4 shadow_color : source_color = vec4(0.08, 0.06, 0.05, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.85, 0.78, 0.68, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.6;          // Intensité globale du virage
uniform float shadow_threshold : hint_range(0.0, 0.5) = 0.35;      // Limite d'action sur les ombres
uniform float highlight_threshold : hint_range(0.5, 1.0) = 0.65;   // Limite d'action sur les hautes lumières

group_uniforms Touche_De_Pinceau;
uniform float brush_intensity : hint_range(0.0, 0.02) = 0.005;
uniform float brush_scale : hint_range(5.0, 100.0) = 35.0;
uniform float sfumato_softness : hint_range(0.0, 4.0) = 1.2;
uniform float canvas_grain : hint_range(0.0, 0.15) = 0.04;

vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

float value_noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = dot(hash22(i), vec2(1.0));
    float b = dot(hash22(i + vec2(1.0, 0.0)), vec2(1.0));
    float c = dot(hash22(i + vec2(0.0, 1.0)), vec2(1.0));
    float d = dot(hash22(i + vec2(1.0, 1.0)), vec2(1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = SCREEN_UV;

    // 1. Calcul des coups de pinceau
    float n1 = value_noise(uv * brush_scale);
    float n2 = value_noise(uv * brush_scale + vec2(7.3, 2.8));
    vec2 brush_offset = vec2(n1 - 0.5, n2 - 0.5) * brush_intensity;

    // 2. Échantillonnage directionnel (Smear)
    vec2 p_size = SCREEN_PIXEL_SIZE * sfumato_softness;
    vec2 stroke_uv = uv + brush_offset;

    vec4 col = texture(screen_texture, stroke_uv) * 0.35;
    col += texture(screen_texture, stroke_uv + brush_offset * 1.5) * 0.25;
    col += texture(screen_texture, stroke_uv - brush_offset * 1.5) * 0.25;
    col += texture(screen_texture, stroke_uv + vec2(p_size.x, -p_size.y)) * 0.075;
    col += texture(screen_texture, stroke_uv - vec2(p_size.x, -p_size.y)) * 0.075;

    // 3. Extraction de la luminance
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));

    // 4. Grain de toile / pigment
    float grain = (hash22(uv * 800.0).x - 0.5) * canvas_grain;
    lum = clamp(lum + grain, 0.0, 1.0);

    // 5. Virage colorimétrique partiel (Split Toning)
    vec3 base_color = col.rgb + grain; // Conservation des couleurs avec grain léger

    // Masques d'influence basés sur la luminance
    float shadow_factor = smoothstep(shadow_threshold, 0.0, lum) * tint_strength;
    float highlight_factor = smoothstep(highlight_threshold, 1.0, lum) * tint_strength;

    // Application de la teinte dans les ombres (multiplication pour assombrir proprement)
    vec3 tinted_color = mix(base_color, base_color * shadow_color.rgb * 2.0, shadow_factor);

    // Application de la teinte dans les hautes lumières
    vec3 final_color = mix(tinted_color, mix(tinted_color, highlight_color.rgb, 0.7), highlight_factor);

    COLOR = vec4(final_color, 1.0);
}