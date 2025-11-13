shader_type sky;

// ============================================================================
// VENUS SKY SHADER
// Based on gradient skybox reference - adapted for Venus thick atmosphere
// Features: Sulfuric acid clouds, heavily diffused sun, no stars/moon visible
// ============================================================================

// === SKY GRADIENT TEXTURES ===
// These control the atmospheric color based on viewing angles
group_uniforms sky_gradients;
uniform sampler2D sun_zenith_gradient : hint_default_black; // Sky color based on sun height
uniform sampler2D view_zenith_gradient : hint_default_black; // Sky color based on view angle
uniform sampler2D sun_view_gradient : hint_default_black; // Atmospheric glow near sun
group_uniforms;

// === SUN PARAMETERS ===
group_uniforms sun;
uniform float sun_diffusion : hint_range(0.0, 1.0) = 0.85; // How diffused the sun appears
uniform vec3 sun_color : source_color = vec3(0.70, 0.60, 0.40); // Muted yellow (filtered through clouds)
uniform float sun_glow_power : hint_range(1.0, 20.0) = 8.0; // Sun glow concentration
uniform float sun_intensity : hint_range(0.0, 2.0) = 0.3; // Sun brightness (heavily attenuated)
group_uniforms;

// === VENUS ATMOSPHERE PARAMETERS ===
group_uniforms venus_atmosphere;
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.95; // Cloud deck density (very opaque)
uniform vec3 cloud_color_day : source_color = vec3(0.65, 0.55, 0.35); // Yellowish-brown clouds
uniform vec3 cloud_color_night : source_color = vec3(0.02, 0.015, 0.01); // Near-black night
uniform float day_night_transition_sharpness : hint_range(0.0, 1.0) = 0.8; // How abrupt the day/night transition is
uniform float cloud_detail_strength : hint_range(0.0, 0.5) = 0.0; // Future: cloud texture detail visibility
group_uniforms;

// === LIGHTNING EFFECTS (Reserved for future implementation) ===
group_uniforms lightning;
uniform float lightning_intensity : hint_range(0.0, 5.0) = 0.0; // Lightning flash intensity
uniform vec3 lightning_color : source_color = vec3(0.8, 0.9, 1.0); // Lightning flash color
uniform vec2 lightning_position : hint_range(0.0, 1.0) = vec2(0.5, 0.5); // Lightning location in sky
uniform float lightning_falloff : hint_range(1.0, 20.0) = 5.0; // Lightning spread
group_uniforms;

// === DYNAMIC DIRECTION (Updated by script) ===
group_uniforms directions;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0); // Direction to sun (updated by controller)
group_uniforms;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get diffused sun glow (no sharp disc - sun is heavily scattered by clouds)
float get_sun_glow(vec3 view_direction, vec3 sun_direction, float power) {
	float sun_view_dot = dot(view_direction, sun_direction);
	// Use power curve for concentrated but soft glow
	return pow(max(sun_view_dot, 0.0), power);
}

// ============================================================================
// MAIN SKY FUNCTION
// ============================================================================

void sky() {
	vec3 view_dir = EYEDIR;

	// ========================================================================
	// SKY ATMOSPHERIC GRADIENT
	// ========================================================================

	// Calculate angular relationships
	float sun_view_dot = dot(sun_dir, view_dir); // Angle between sun and view direction
	float sun_zenith_dot = sun_dir.y; // Sun height in sky (-1 to 1)
	float view_zenith_dot = view_dir.y; // View angle upward component (-1 to 1)

	// Calculate day/night amount with sharp transition (thick atmosphere = abrupt darkness)
	// Adjust transition point and sharpness
	float transition_threshold = mix(-0.1, 0.1, day_night_transition_sharpness);
	float day_amount = smoothstep(transition_threshold - 0.15, transition_threshold + 0.05, sun_zenith_dot);

	// Sample gradient textures (convert -1..1 to 0..1 UV range)
	vec3 sun_zenith_color = texture(sun_zenith_gradient, vec2((sun_zenith_dot + 1.0) * 0.5, 0.5)).rgb;
	vec3 view_zenith_color = texture(view_zenith_gradient, vec2((view_zenith_dot + 1.0) * 0.5, 0.5)).rgb;
	vec3 sun_view_color = texture(sun_view_gradient, vec2((sun_view_dot + 1.0) * 0.5, 0.5)).rgb;

	// Create masks for blending view and sun-view gradients
	float vz_mask = pow(clamp((view_zenith_dot + 1.0) * 0.5, 0.0, 1.0), 4.0);
	float sv_mask = pow(clamp((sun_view_dot + 1.0) * 0.5, 0.0, 1.0), 8.0); // More concentrated than Earth/Mars

	// Combine all gradient layers additively
	vec3 sky_output = sun_zenith_color + vz_mask * view_zenith_color + sv_mask * sun_view_color;

	// Apply cloud opacity
	sky_output *= cloud_opacity;

	// Mix day/night colors (Venus gets VERY dark at night)
	sky_output = mix(cloud_color_night, sky_output, day_amount);

	// ========================================================================
	// SUN RENDERING (Heavily Diffused - No Sharp Disc)
	// ========================================================================

	// Calculate diffused sun glow (barely visible through thick clouds)
	float sun_glow = get_sun_glow(view_dir, sun_dir, sun_glow_power);

	// Apply sun diffusion (higher = more scattered, less visible)
	sun_glow *= (1.0 - sun_diffusion);

	// Sun only visible during day
	sun_glow *= day_amount;

	vec3 sun_output = sun_glow * sun_color * sun_intensity;

	// ========================================================================
	// LIGHTNING EFFECTS (Future Implementation)
	// ========================================================================

	// Calculate lightning flash position relative to view direction
	// This is reserved for future particle system or procedural lightning
	vec3 lightning_output = vec3(0.0);

	if (lightning_intensity > 0.0) {
		// Placeholder: Simple radial lightning flash
		// In future, this could be driven by a 2D noise texture or particle positions
		float lightning_dist = length(view_dir.xz - lightning_position);
		float lightning_mask = exp(-lightning_dist * lightning_falloff);
		lightning_output = lightning_color * lightning_intensity * lightning_mask;
	}

	// ========================================================================
	// CLOUD DETAIL (Future Enhancement)
	// ========================================================================

	// Reserved for cloud texture detail (subtle banding patterns from super-rotation)
	// In future, sample a noise texture here for visible cloud features
	float cloud_detail = 0.0;
	if (cloud_detail_strength > 0.0) {
		// Placeholder: Would sample cloud_noise_texture here
		// cloud_detail = texture(cloud_noise_texture, view_dir.xz * scale).r;
		// sky_output += cloud_detail * cloud_detail_strength * day_amount;
	}

	// ========================================================================
	// NO STARS OR MOON
	// ========================================================================
	// Venus's thick sulfuric acid cloud deck blocks ALL celestial objects
	// Stars are not visible even at night
	// Moon (if Venus had one) would be completely obscured

	// ========================================================================
	// FINAL COMPOSITION
	// ========================================================================

	COLOR = sky_output + sun_output + lightning_output;
}
