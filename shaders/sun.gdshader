shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

// === TEXTURE ===
uniform sampler2D sun_texture : source_color;

// === COLOR & BRIGHTNESS ===
uniform vec3 sun_color : source_color = vec3(1.0, 0.9, 0.7);
uniform float brightness : hint_range(0.0, 20.0) = 5.0;
uniform float core_intensity : hint_range(0.0, 5.0) = 1.5;

// === SURFACE ANIMATION ===
uniform float turbulence_speed : hint_range(0.0, 2.0) = 0.1;
uniform float turbulence_amount : hint_range(0.0, 0.2) = 0.03;
uniform float flow_scale : hint_range(1.0, 50.0) = 20.0;

// === PULSATION ===
uniform bool enable_pulsation = false;
uniform float pulse_speed : hint_range(0.0, 5.0) = 0.5;
uniform float pulse_amount : hint_range(0.0, 0.5) = 0.1;

// === FRESNEL FLARE (Edge Glow) ===
uniform bool enable_flare = true;
uniform vec3 flare_color : source_color = vec3(1.0, 0.6, 0.2);
uniform float flare_intensity : hint_range(0.0, 10.0) = 2.0;
uniform float flare_power : hint_range(0.1, 10.0) = 3.0;

// === CHROMATIC ABERRATION (Edge Color Shift) ===
uniform bool enable_chromatic = false;
uniform float chromatic_strength : hint_range(0.0, 0.1) = 0.02;

// === UV TRANSFORM ===
uniform vec3 uv1_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 uv1_offset = vec3(0.0, 0.0, 0.0);

// Noise function for surface detail
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
    UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
    // Calculate view-dependent fresnel for flare effect
    float fresnel = 0.0;
    if (enable_flare) {
        fresnel = pow(1.0 - abs(dot(VIEW, NORMAL)), flare_power);
    }

    // Pulsation effect
    float pulse = 1.0;
    if (enable_pulsation) {
        pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
    }

    // Animated UV distortion for turbulent surface
    vec2 uv = UV;
    float time_offset = TIME * turbulence_speed;

    // Multi-layered turbulence
    uv.x += sin(uv.y * flow_scale + time_offset) * turbulence_amount;
    uv.y += cos(uv.x * flow_scale * 0.75 + time_offset * 0.7) * turbulence_amount;

    // Add secondary noise layer for more detail
    float noise_val = noise(uv * flow_scale * 0.5 + time_offset * 0.3);
    uv += (noise_val - 0.5) * turbulence_amount * 0.5;

    // Sample texture with chromatic aberration (optional)
    vec3 sun_sample;
    if (enable_chromatic && enable_flare) {
        // Shift RGB channels slightly at edges for color fringing
        float shift = fresnel * chromatic_strength;
        float r = texture(sun_texture, uv + vec2(shift, 0.0)).r;
        float g = texture(sun_texture, uv).g;
        float b = texture(sun_texture, uv - vec2(shift, 0.0)).b;
        sun_sample = vec3(r, g, b);
    } else {
        sun_sample = texture(sun_texture, uv).rgb;
    }

    // Add subtle brightness variation based on noise for solar activity
    float activity = noise(uv * 10.0 + time_offset * 0.2) * 0.3 + 0.7;

    // Calculate base color with center brightening
    vec2 center_dist_uv = UV - vec2(0.5);
    float center_dist = length(center_dist_uv);
    float core_boost = (1.0 - smoothstep(0.0, 0.5, center_dist)) * core_intensity;

    vec3 base_color = sun_sample * sun_color * (1.0 + core_boost) * activity;

    // Apply brightness and pulsation
    vec3 final_color = base_color * brightness * pulse;

    // Add fresnel flare at edges
    if (enable_flare) {
        vec3 flare = flare_color * fresnel * flare_intensity;
        final_color += flare;
    }

    // Output
    ALBEDO = final_color;
    EMISSION = final_color;
}