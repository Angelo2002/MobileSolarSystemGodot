// Cloud shader (on a slightly larger sphere, scale ~1.02x)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D cloud_texture : source_color, hint_default_white;

uniform float cloud_speed : hint_range(0.0, 1.0) = 0.0004;
uniform float cloud_opacity : hint_range(0.0, 1.0) = 1;

void fragment() {
    vec2 cloud_uv = UV + vec2(TIME * cloud_speed, 0.0);
    vec3 cloud = texture(cloud_texture, cloud_uv).rgb;
    
    float alpha = max(cloud.r, max(cloud.g, cloud.b)); // Or use dot() for luminance
    
    ALBEDO = vec3(1.0); // Pure white clouds lit by sun
    ALPHA = alpha * cloud_opacity;
}