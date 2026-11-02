shader_type canvas_item;

// Texture de l'écran capturée en arrière-plan
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Paramètres de Cell Shading
uniform int color_levels : hint_range(2, 16) = 6; // Nombre de paliers de couleurs

// Paramètres d'Effet Peinture / Contour
uniform float outline_thickness : hint_range(0.5, 3.0) = 1.0;
uniform float outline_threshold : hint_range(0.01, 0.5) = 0.08;
uniform vec4 outline_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);

// Fonction pour posteriser les couleurs (donne l'effet aplat/cell shading)
vec3 posterize(vec3 color, int levels) {
    // Conversion optionnelle en espace HSV pour un rendu de peinture plus artistique
    return floor(color * float(levels)) / float(levels);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 ps = SCREEN_PIXEL_SIZE * outline_thickness;
    
    // Échantillonnage pour la détection de contours (style Sobel simplifié)
    vec3 col_center = texture(screen_texture, uv).rgb;
    vec3 col_right  = texture(screen_texture, uv + vec2(ps.x, 0.0)).rgb;
    vec3 col_top    = texture(screen_texture, uv + vec2(0.0, ps.y)).rgb;
    
    float diff_x = length(col_center - col_right);
    float diff_y = length(col_center - col_top);
    float edge = step(outline_threshold, max(diff_x, diff_y));
    
    // Application du style peinture (quantisation des couleurs)
    vec3 painted_color = posterize(col_center, color_levels);
    
    // Mélange des contours et des aplats de peinture
    vec3 final_color = mix(painted_color, outline_color.rgb, edge);
    
    COLOR = vec4(final_color, 1.0);
}