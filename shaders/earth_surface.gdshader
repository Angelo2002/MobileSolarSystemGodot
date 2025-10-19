shader_type spatial;

uniform sampler2D day_texture : source_color;
uniform sampler2D night_texture : source_color;
uniform sampler2D normal_map : hint_normal;
uniform sampler2D specular_map : source_color;
uniform float transition_sharpness : hint_range(1.0, 20.0) = 5.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform float specular_intensity : hint_range(0.0, 5.0) = 1.0;
uniform float specular_shininess : hint_range(1.0, 128.0) = 32.0;
uniform float city_lights_intensity : hint_range(0.0, 3.0) = 1.0;

varying vec2 uv_interp;

void vertex() {
    uv_interp = UV;
}

void fragment() {
    // Sample and apply normal map
    vec3 normal_map_color = texture(normal_map, UV).rgb;
    NORMAL_MAP = normal_map_color;
    NORMAL_MAP_DEPTH = normal_strength;
    
    // Set base properties
    ALBEDO = vec3(1.0);
    ROUGHNESS = 0.8;
}

void light() {
    // Sample textures
    vec4 day_color = texture(day_texture, uv_interp);
    vec4 night_color = texture(night_texture, uv_interp);
    vec3 spec_map = texture(specular_map, uv_interp).rgb;
    
    // Calculate day/night blend based on light direction
    float light_amount = max(dot(NORMAL, LIGHT), 0.0);
    float blend = smoothstep(0.0, 0.2, light_amount);
    blend = pow(blend, transition_sharpness);
    
    // Day side: normal diffuse lighting
    vec3 day_contribution = day_color.rgb * blend * light_amount * ATTENUATION * LIGHT_COLOR;
    
    // Night side: city lights glow (emission-like, independent of lighting)
    // Only add for the main light to avoid double-counting
    vec3 night_contribution = night_color.rgb * (1.0 - blend) * city_lights_intensity;
    
    DIFFUSE_LIGHT += day_contribution + night_contribution;
    
    // Specular highlights (oceans on day side)
    vec3 half_vector = normalize(LIGHT + VIEW);
    float specular = pow(max(dot(NORMAL, half_vector), 0.0), specular_shininess);
    SPECULAR_LIGHT += spec_map * specular * specular_intensity * blend * ATTENUATION * LIGHT_COLOR;
}