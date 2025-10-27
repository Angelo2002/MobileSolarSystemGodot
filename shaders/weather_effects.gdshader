shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Base texture uniforms (set to match the primary shader's texture)
uniform sampler2D base_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 base_albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Meteor impact zones
uniform bool enable_meteors = false;
uniform vec2 meteor_uv = vec2(0.5, 0.5); // UV position on sphere
uniform float meteor_radius = 0.1;
uniform vec3 meteor_color = vec3(1.0, 0.5, 0.0);
uniform float meteor_intensity = 1.0;

// Storms
uniform bool enable_lightning = false;
uniform float lightning_intensity = 1.0;
uniform bool enable_wobble = false;
uniform float wobble_strength = 0.01;

// Aurora
uniform bool enable_aurora = false;
uniform vec3 aurora_color = vec3(0.0, 1.0, 1.0);
uniform float aurora_intensity = 0.5;

void vertex() {
    // No changes needed here
}

void fragment() {
    vec2 uv = UV;

    // Apply wobble distortion if enabled
    if (enable_wobble) {
        uv += vec2(sin(TIME * 5.0 + uv.y * 20.0) * wobble_strength, cos(TIME * 3.0 + uv.x * 15.0) * wobble_strength * 0.5);
        uv = clamp(uv, vec2(0.0), vec2(1.0)); // Prevent UV from going out of bounds
    }

    // Sample base texture
    vec4 albedo_tex = texture(base_texture, uv);
    ALBEDO = albedo_tex.rgb * base_albedo.rgb;

    // Initialize emission
    vec3 emission = vec3(0.0);

    // Meteor impact zones
    if (enable_meteors) {
        float dist = distance(uv, meteor_uv);
        if (dist < meteor_radius) {
            float falloff = 1.0 - (dist / meteor_radius);
            emission += meteor_color * meteor_intensity * falloff;
        }
    }

    // Lightning flashes (random based on time and position)
    if (enable_lightning) {
        float lightning_flash = sin(TIME * 10.0 + uv.x * 50.0 + uv.y * 30.0) * 0.5 + 0.5;
        if (lightning_flash > 0.8) {
            emission += vec3(1.0, 1.0, 0.8) * lightning_intensity * (lightning_flash - 0.8) * 5.0;
        }
    }

    // Aurora effect (polar regions)
    if (enable_aurora) {
        float aurora_factor = smoothstep(0.4, 0.8, uv.y) * sin(TIME * 2.0 + uv.x * 10.0);
        emission += aurora_color * aurora_intensity * aurora_factor;
    }

    EMISSION = emission;

    // Keep other properties default or as needed
    ROUGHNESS = 0.5;
    METALLIC = 0.0;
    SPECULAR = 0.5;
}

