shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D ring_texture : source_color;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.3;  // Inner hole
uniform float outer_radius : hint_range(0.0, 1.0) = 0.5;  // Outer edge (max 0.5 to fit in square)

void fragment() {
    vec2 centered_uv = UV - vec2(0.5);
    float distance_from_center = length(centered_uv);
    
    if (distance_from_center > outer_radius || distance_from_center < inner_radius) {
        discard;
    }
    
    float normalized_distance = (distance_from_center - inner_radius) / (outer_radius - inner_radius);
    
    ALBEDO = texture(ring_texture, vec2(normalized_distance, 0.5)).rgb;
    ALPHA = texture(ring_texture, vec2(normalized_distance, 0.5)).a;
}