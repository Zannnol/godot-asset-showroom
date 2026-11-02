shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Paramètres de style BSL
uniform float saturation : hint_range(0.0, 2.0) = 1.25;
uniform float contrast : hint_range(0.5, 2.0) = 1.1;
uniform vec4 tint_highlights : source_color = vec4(1.08, 1.03, 0.92, 1.0); // Lumière chaude (soleil)
uniform vec4 tint_shadows : source_color = vec4(0.88, 0.94, 1.05, 1.0);     // Ombres bleutées (ciel)
uniform float bloom_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;

// Approximation de l'ACES Tonemapping (la patte visuelle des BSL Shaders)
vec3 aces_tonemap(vec3 color) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec3 col = texture(screen_texture, uv).rgb;
    
    // 1. Simulation d'un Bloom léger sur les zones lumineuses
    vec3 bloom = vec3(0.0);
    float blur_size = 0.003;
    for(float x = -2.0; x <= 2.0; x += 2.0) {
        for(float y = -2.0; y <= 2.0; y += 2.0) {
            bloom += texture(screen_texture, uv + vec2(x, y) * blur_size).rgb;
        }
    }
    bloom /= 9.0;
    vec3 bloom_color = max(vec3(0.0), bloom - 0.55) * bloom_intensity;
    col += bloom_color;

    // 2. Color Grading BSL : Split-Toning (Chaud dans les lumières, Froid dans les ombres)
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 graded = mix(col * tint_shadows.rgb, col * tint_highlights.rgb, lum);
    
    // 3. Ajustement de la Saturation et du Contraste
    vec3 gray = vec3(dot(graded, vec3(0.299, 0.587, 0.114)));
    col = mix(gray, graded, saturation);
    col = mix(vec3(0.5), col, contrast);

    // 4. Application du Tonemapping ACES pour éviter la saturation excessive des blancs
    col = aces_tonemap(col);

    // 5. Vignette cinématique discrète
    vec2 center = uv - 0.5;
    float dist = length(center);
    float vignette = smoothstep(0.8, 0.2, dist * vignette_strength * 2.0);
    col *= vignette;

    COLOR = vec4(col, 1.0);
}