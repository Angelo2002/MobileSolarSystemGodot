shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_front;

// Atmosphere Colors
uniform vec3 atmosphere_color : source_color = vec3(0.5, 0.7, 1.0);
uniform vec3 sunset_color : source_color = vec3(1.0, 0.4, 0.2);
uniform float atmosphere_intensity : hint_range(0.0, 5.0) = 1.5;

// Atmosphere Properties
uniform float atmosphere_thickness : hint_range(0.0, 2.0) = 0.5;
uniform float falloff : hint_range(0.1, 10.0) = 3.0;
uniform float sunset_width : hint_range(0.0, 1.0) = 0.3;

// Advanced
uniform bool use_sunset = true;
uniform float fresnel_power : hint_range(0.5, 5.0) = 2.0;

varying vec3 world_normal;
varying vec3 world_view;

void vertex() {
    // Expand the sphere
    VERTEX += NORMAL * atmosphere_thickness * 0.1;

    // Pass to fragment
    world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
    world_view = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz - (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec3 normal = normalize(world_normal);
    vec3 view = normalize(world_view);

    // Fresnel - glow at edges
    float fresnel = 1.0 - abs(dot(normal, view));
    fresnel = pow(fresnel, fresnel_power);

    ALBEDO = atmosphere_color;
    ALPHA = fresnel * atmosphere_intensity;
}

void light() {
    // Now we have access to actual LIGHT direction!
    float sun_alignment = dot(normalize(world_normal), LIGHT);

    // Sunset band at terminator
    float terminator = smoothstep(-sunset_width, sunset_width, sun_alignment);
    float sunset_band = 1.0 - abs(terminator * 2.0 - 1.0);

    vec3 atmo_color = atmosphere_color;
    if (use_sunset) {
        atmo_color = mix(atmo_color, sunset_color, sunset_band * 0.7);
    }

    // Fade on dark side
    float day_side_fade = smoothstep(-0.5, 0.5, sun_alignment);

    float final_alpha = ALPHA * day_side_fade;
    final_alpha = pow(final_alpha, falloff);

    DIFFUSE_LIGHT += atmo_color * final_alpha * LIGHT_COLOR;
}