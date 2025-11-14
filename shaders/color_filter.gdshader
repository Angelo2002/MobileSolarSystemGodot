shader_type spatial;

// ============================================================================
// COLOR FILTER SHADER
// ============================================================================
// Apply color transformations to deceive players into thinking they've loaded
// a different area using the same texture with modified colors.
// ============================================================================

// === TEXTURE ===
uniform sampler2D base_texture : source_color;
uniform sampler2D normal_map : hint_normal;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

// === HUE SHIFT ===
// Rotate colors on the color wheel (0-360 degrees)
// Examples: 180 = opposite colors, 120 = shift to next primary
uniform float hue_shift : hint_range(0.0, 360.0) = 0.0;

// === TINT/OVERLAY ===
// Apply a color wash over the texture
uniform vec3 tint_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float tint_intensity : hint_range(0.0, 1.0) = 0.0;

// === SATURATION ===
// Adjust color intensity (0 = grayscale, 1 = normal, 2+ = vivid)
uniform float saturation : hint_range(0.0, 3.0) = 1.0;

// === BRIGHTNESS & CONTRAST ===
// Brightness: -1 to 1 (negative = darker, positive = brighter)
// Contrast: 0.5 to 3.0 (lower = flat, higher = punchy)
uniform float brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.5, 3.0) = 1.0;

// === SURFACE PROPERTIES ===
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;

// ============================================================================
// COLOR SPACE CONVERSION FUNCTIONS
// ============================================================================

// Convert RGB to HSV color space
vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Convert HSV to RGB color space
vec3 hsv_to_rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// ============================================================================
// COLOR TRANSFORMATION FUNCTIONS
// ============================================================================

// Apply hue shift by rotating color wheel
vec3 apply_hue_shift(vec3 color, float shift) {
    if (shift == 0.0) return color;

    vec3 hsv = rgb_to_hsv(color);
    hsv.x = fract(hsv.x + shift / 360.0); // Normalize shift to 0-1 range
    return hsv_to_rgb(hsv);
}

// Apply saturation adjustment
vec3 apply_saturation(vec3 color, float sat) {
    if (sat == 1.0) return color;

    vec3 hsv = rgb_to_hsv(color);
    hsv.y *= sat;
    hsv.y = clamp(hsv.y, 0.0, 1.0);
    return hsv_to_rgb(hsv);
}

// Apply brightness and contrast
vec3 apply_brightness_contrast(vec3 color, float bright, float cont) {
    // Apply contrast first (around midpoint 0.5)
    color = (color - 0.5) * cont + 0.5;

    // Then apply brightness
    color += bright;

    return clamp(color, 0.0, 1.0);
}

// Apply color tint overlay
vec3 apply_tint(vec3 color, vec3 tint, float intensity) {
    if (intensity == 0.0) return color;
    return mix(color, color * tint, intensity);
}

// ============================================================================
// SHADER MAIN FUNCTIONS
// ============================================================================

void fragment() {
    // Sample base texture
    vec4 tex = texture(base_texture, UV);
    vec3 color = tex.rgb;

    // === APPLY COLOR TRANSFORMATIONS (in order) ===

    // 1. Hue shift (changes fundamental colors)
    color = apply_hue_shift(color, hue_shift);

    // 2. Saturation (adjust color intensity)
    color = apply_saturation(color, saturation);

    // 3. Brightness & Contrast (adjust luminosity)
    color = apply_brightness_contrast(color, brightness, contrast);

    // 4. Tint overlay (color wash on top)
    color = apply_tint(color, tint_color, tint_intensity);

    // === SET MATERIAL PROPERTIES ===
    ALBEDO = color;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    SPECULAR = specular;

    // Apply normal map if provided
    if (normal_strength > 0.0) {
        vec3 normal_tex = texture(normal_map, UV).rgb;
        NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), normal_tex, normal_strength);
        NORMAL_MAP_DEPTH = normal_strength;
    }
}

void light() {
    // Standard diffuse lighting with proper Godot integration
    float NdotL = max(dot(NORMAL, LIGHT), 0.0);
    DIFFUSE_LIGHT += ALBEDO * NdotL * ATTENUATION * LIGHT_COLOR;

    // Simple specular highlights for shiny surfaces
    if (metallic > 0.1 || (1.0 - roughness) > 0.3) {
        vec3 H = normalize(LIGHT + VIEW);
        float NdotH = max(dot(NORMAL, H), 0.0);
        float spec_power = mix(8.0, 128.0, 1.0 - roughness);
        float spec = pow(NdotH, spec_power) * (1.0 - roughness) * specular;
        SPECULAR_LIGHT += spec * ATTENUATION * LIGHT_COLOR;
    }
}
