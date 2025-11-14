shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

// === CORE GLARE PROPERTIES ===
uniform vec3 glare_color : source_color = vec3(1.0, 0.95, 0.85);
uniform float glare_intensity : hint_range(0.0, 10.0) = 1.0;
uniform float billboard_scale : hint_range(0.1, 20.0) = 5.0; // Controls the actual drawable size

// === RADIAL BLOOM ===
uniform bool enable_bloom = true;
uniform float bloom_radius : hint_range(0.1, 2.0) = 1.0;
uniform float bloom_softness : hint_range(0.1, 5.0) = 2.0;
uniform float bloom_intensity : hint_range(0.0, 5.0) = 2.0;

// === STARBURST / CROSS STREAKS ===
uniform bool enable_starburst = true;
uniform int ray_count : hint_range(4, 12) = 4;
uniform float ray_length : hint_range(0.5, 3.0) = 1.5;
uniform float ray_width : hint_range(0.01, 0.2) = 0.05;
uniform float ray_intensity : hint_range(0.0, 5.0) = 1.5;
uniform float ray_rotation : hint_range(0.0, 360.0) = 0.0;

// === ANIMATION ===
uniform bool enable_rotation = false;
uniform float rotation_speed : hint_range(-2.0, 2.0) = 0.1;

// === DISTANCE SCALING (controlled by script) ===
uniform float distance_fade : hint_range(0.0, 1.0) = 1.0;
uniform float occlusion_fade : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	// Full billboard - quad always faces camera from all angles
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);

	// Scale the billboard to control drawable area size
	// This allows the glare to extend beyond the base mesh geometry
	VERTEX *= billboard_scale;
}

void fragment() {
    // Center UV coordinates (-0.5 to 0.5)
    vec2 centered_uv = UV - vec2(0.5);

    // Apply rotation animation if enabled
    float rotation_angle = radians(ray_rotation);
    if (enable_rotation) {
        rotation_angle += TIME * rotation_speed;
    }

    float cos_rot = cos(rotation_angle);
    float sin_rot = sin(rotation_angle);
    vec2 rotated_uv = vec2(
        centered_uv.x * cos_rot - centered_uv.y * sin_rot,
        centered_uv.x * sin_rot + centered_uv.y * cos_rot
    );

    // Calculate polar coordinates
    float dist = length(centered_uv);
    float angle = atan(rotated_uv.y, rotated_uv.x);

    // === RADIAL BLOOM ===
    float bloom = 0.0;
    if (enable_bloom) {
        // Smooth falloff from center
        bloom = 1.0 - smoothstep(0.0, bloom_radius, dist);
        bloom = pow(bloom, bloom_softness);
        bloom *= bloom_intensity;
    }

    // === STARBURST RAYS ===
    float starburst = 0.0;
    if (enable_starburst && ray_count > 0) {
        // Calculate angular position for rays
        float ray_angle_step = (2.0 * PI) / float(ray_count);

        // Find nearest ray angle
        float nearest_ray_angle = round(angle / ray_angle_step) * ray_angle_step;
        float angle_diff = abs(angle - nearest_ray_angle);

        // Calculate ray intensity based on distance and angle
        float ray_dist_falloff = 1.0 - smoothstep(0.0, ray_length, dist);
        float ray_angular_width = smoothstep(ray_width, 0.0, angle_diff);

        // Combine with distance taper
        starburst = ray_angular_width * ray_dist_falloff * ray_intensity;

        // Add slight glow at ray center
        starburst *= (1.0 + (1.0 - dist / ray_length) * 0.5);
    }

    // === COMBINE EFFECTS ===
    float combined_intensity = max(bloom, starburst);

    // Apply color and intensity
    vec3 final_color = glare_color * combined_intensity * glare_intensity;

    // Apply distance and occlusion fading
    final_color *= distance_fade * occlusion_fade;

    // Output
    ALBEDO = final_color;
    EMISSION = final_color;
    ALPHA = combined_intensity * distance_fade * occlusion_fade;
}