shader_type canvas_item;

// filter_nearest est crucial pour garder des pixels nets et éviter le flou de l'interpolation
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// Paramètres du style Pixel Art
uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;   // Taille des blocs de pixels (plus c'est haut, plus c'est rétro)
uniform int color_levels : hint_range(2, 64) = 16;       // Nombre de nuances par canal (réduction de palette)
uniform bool enable_palette_reduction = true;

void fragment() {
    // Calcul de la grille de pixels en fonction de la résolution de l'écran
    vec2 screen_res = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 grid_res = screen_res / pixel_size;
    
    // Snapping des UVs sur la grille pour créer l'effet de pixelisation géométrique
    vec2 uv = floor(SCREEN_UV * grid_res) / grid_res;
    
    // Échantillonnage de l'écran avec les UVs modifiés
    vec3 col = texture(screen_texture, uv).rgb;
    
    // Réduction optionnelle de la palette de couleurs (style rétro / limitations matérielles)
    if (enable_palette_reduction) {
        col = floor(col * float(color_levels)) / float(color_levels);
    }
    
    COLOR = vec4(col, 1.0);
}