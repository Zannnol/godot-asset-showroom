shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Paramètres d'ambiance fantastique et de peinture
uniform float paint_blend : hint_range(0.0, 1.0) = 0.35; // Douceur de l'effet peinture (mélange local)
uniform vec4 torch_tint : source_color = vec4(1.2, 1.08, 0.85, 1.0); // Lumière chaude / dorée (torche)
uniform vec4 shadow_tint : source_color = vec4(0.08, 0.05, 0.04, 1.0); // Ombres profondes brun/sépia
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.55; // Intensité des coins sombres (cave)

void fragment() {
    vec2 uv = SCREEN_UV;
    
    vec3 col = texture(screen_texture, uv).rgb;
    
    // Effet peinture : léger lissage/mélange de voisinage (imite les coups de pinceau)
    vec2 ps = SCREEN_PIXEL_SIZE * 1.5;
    vec3 col_blur = (
        texture(screen_texture, uv + vec2(ps.x, 0.0)).rgb +
        texture(screen_texture, uv + vec2(-ps.x, 0.0)).rgb +
        texture(screen_texture, uv + vec2(0.0, ps.y)).rgb +
        texture(screen_texture, uv + vec2(0.0, -ps.y)).rgb
    ) * 0.25;
    
    col = mix(col, col_blur, paint_blend);
    
    // Calcul de la luminance pour séparer les zones éclairées des zones d'ombre
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    
    // Color Grading "Feu de torche" :
    // Les parties éclairées tirent sur le jaune/or chaleureux, les ombres s'enfoncent dans le sépia
    vec3 lit_color = col * torch_tint.rgb;
    vec3 dark_color = shadow_tint.rgb * (lum * 3.5);
    
    vec3 final_color = mix(dark_color, lit_color, smoothstep(0.05, 0.55, lum));
    
    // Vignette prononcée pour accentuer l'effet de cave fermée et oppressante
    vec2 center_uv = uv - 0.5;
    float dist = length(center_uv);
    float vignette = smoothstep(0.75, 0.75 - vignette_intensity * 0.4, dist);
    final_color *= vignette;

    COLOR = vec4(final_color, 1.0);
}