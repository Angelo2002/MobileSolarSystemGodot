shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D sun_texture : source_color;
uniform vec3 sun_color : source_color = vec3(1.0, 0.8, 0.4);
uniform float emission_strength : hint_range(0.0, 10.0) = 3.0;

uniform float turbulence_speed : hint_range(0.0, 1.0) = 0.05;
uniform float turbulence_amount : hint_range(0.0, 0.1) = 0.02;


uniform vec3 uv1_scale = vec3(1,1,1);
uniform vec3 uv1_offset;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
    vec2 uv = UV;
    uv.x += sin(uv.y * 20.0 + TIME * turbulence_speed) * turbulence_amount;
    uv.y += cos(uv.x * 15.0 + TIME * turbulence_speed * 0.7) * turbulence_amount;
    vec3 sun_sample = texture(sun_texture, uv).rgb;
    vec3 base_color = sun_sample * sun_color;
    ALBEDO = base_color * emission_strength;
    EMISSION = base_color * emission_strength;
}