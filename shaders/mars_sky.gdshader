shader_type sky;

// ============================================================================
// MARS SKY SHADER
// Based on gradient skybox reference - adapted for Mars atmosphere
// Features: Dusty orange/rust atmosphere, realistic star visibility
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
uniform float sun_radius : hint_range(0.0, 1.0) = 0.03;
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.85);
group_uniforms;

// === STAR PARAMETERS ===
group_uniforms stars;
uniform samplerCube star_cubemap : hint_default_black;
uniform float star_exposure : hint_range(0.0, 5.0) = 1.5;
uniform float star_power : hint_range(0.0, 10.0) = 3.0; // Controls star sharpness
uniform float star_latitude : hint_range(-90.0, 90.0) = 0.0; // Observer latitude on Mars
uniform float star_rotation_speed : hint_range(0.0, 1.0) = 0.1; // Day/night cycle speed
uniform vec3 constellation_color : source_color = vec3(0.5, 0.7, 1.0);
uniform samplerCube constellation_cubemap : hint_default_black;
group_uniforms;

// === ATMOSPHERIC PARAMETERS ===
group_uniforms atmosphere;
uniform float dust_opacity : hint_range(0.0, 1.0) = 0.6; // Mars dust haze strength
uniform float star_day_visibility : hint_range(0.0, 1.0) = 0.3; // Stars visible during day (thin atmosphere)
group_uniforms;

// === DYNAMIC DIRECTION (Updated by script) ===
group_uniforms directions;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0); // Direction to sun (updated by controller)
group_uniforms;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get sun mask (simple circular disc)
float get_sun_mask(vec3 view_direction, vec3 sun_direction, float radius) {
	float sun_view_dot = dot(view_direction, sun_direction);
	return step(1.0 - radius, sun_view_dot);
}

// Rotation matrix around Y axis (for star field rotation)
mat3 rotate_y(float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return mat3(
		vec3(c, 0.0, -s),
		vec3(0.0, 1.0, 0.0),
		vec3(s, 0.0, c)
	);
}

// Rotation matrix around X axis (for latitude adjustment)
mat3 rotate_x(float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return mat3(
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, c, s),
		vec3(0.0, -s, c)
	);
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

	// Sample gradient textures (convert -1..1 to 0..1 UV range)
	vec3 sun_zenith_color = texture(sun_zenith_gradient, vec2((sun_zenith_dot + 1.0) * 0.5, 0.5)).rgb;
	vec3 view_zenith_color = texture(view_zenith_gradient, vec2((view_zenith_dot + 1.0) * 0.5, 0.5)).rgb;
	vec3 sun_view_color = texture(sun_view_gradient, vec2((sun_view_dot + 1.0) * 0.5, 0.5)).rgb;

	// Create masks for blending view and sun-view gradients
	// These create smooth falloffs to control where each gradient appears
	float vz_mask = pow(clamp((view_zenith_dot + 1.0) * 0.5, 0.0, 1.0), 4.0);
	float sv_mask = pow(clamp((sun_view_dot + 1.0) * 0.5, 0.0, 1.0), 4.0);

	// Combine all gradient layers additively
	vec3 sky_output = sun_zenith_color + vz_mask * view_zenith_color + sv_mask * sun_view_color;

	// Apply dust opacity (Mars atmospheric haze)
	sky_output *= dust_opacity;

	// ========================================================================
	// SUN RENDERING
	// ========================================================================

	float sun_mask = get_sun_mask(view_dir, sun_dir, sun_radius);
	vec3 sun_output = sun_mask * sun_color;

	// ========================================================================
	// STAR RENDERING (visible during day on Mars due to thin atmosphere)
	// ========================================================================

	// Calculate star field rotation based on time and latitude
	float latitude_rad = radians(star_latitude);
	float rotation_angle = TIME * star_rotation_speed;

	// Apply rotation transformations
	mat3 lat_rotation = rotate_x(latitude_rad);
	mat3 time_rotation = rotate_y(rotation_angle);
	vec3 star_dir = time_rotation * lat_rotation * view_dir;

	// Sample star cubemap
	vec3 star_sample = texture(star_cubemap, star_dir).rgb;

	// Apply power curve for star brightness control
	vec3 stars_output = pow(star_sample, vec3(star_power)) * star_exposure;

	// Stars are visible during Martian day (thin atmosphere) but dimmed
	// Calculate star visibility based on sun position
	float sun_brightness = clamp(sun_zenith_dot, 0.0, 1.0);
	float star_visibility = mix(1.0, star_day_visibility, sun_brightness);
	stars_output *= star_visibility;

	// Sample constellation layer (optional overlay)
	vec3 constellation_sample = texture(constellation_cubemap, star_dir).rgb;
	vec3 constellation_output = constellation_sample * constellation_color * star_visibility;

	// ========================================================================
	// FINAL COMPOSITION
	// ========================================================================

	COLOR = sky_output + sun_output + stars_output + constellation_output;
}
