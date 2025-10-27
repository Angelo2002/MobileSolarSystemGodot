// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's StandardMaterial3D.
// Enhanced with meteor impact and lightning effects

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// Meteor Impact Controls
group_uniforms MeteorImpact;
uniform bool meteor_enabled = true;
uniform float meteor_min_size : hint_range(0.001, 0.5, 0.001) = 0.01;
uniform float meteor_max_size : hint_range(0.001, 0.5, 0.001) = 0.01;
uniform float meteor_frequency : hint_range(0.1, 10.0, 0.1) = 0.1; // Impacts per second
uniform vec3 meteor_color : source_color = vec3(1.5, 0.8, 0.3);
uniform float meteor_intensity : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform float meteor_flash_duration : hint_range(0.05, 1.0, 0.01) = 0.2; // Seconds

// Lightning Controls
group_uniforms Lightning;
uniform bool lightning_enabled = true;
uniform float lightning_min_size : hint_range(0.001, 0.5, 0.001) = 0.015;
uniform float lightning_max_size : hint_range(0.001, 0.5, 0.001) = 0.04;
uniform float lightning_frequency : hint_range(0.1, 10.0, 0.1) = 1.2; // Strikes per second
uniform vec3 lightning_color : source_color = vec3(0.5, 0.7, 2.5);
uniform float lightning_intensity : hint_range(0.0, 10.0, 0.1) = 4.0;
uniform float lightning_flash_duration : hint_range(0.05, 1.0, 0.01) = 0.1; // Seconds
uniform float lightning_strike_count : hint_range(1.0, 8.0, 1.0) = 3.0; // Localized strikes per event
uniform float lightning_cluster_radius : hint_range(0.01, 0.3, 0.01) = 0.05; // How spread out the strikes are

// Hash function for pseudo-random number generation
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Generate a random value based on time and seed
float random_time(float seed, float time_scale) {
	return hash(vec2(floor(TIME * time_scale + seed), seed));
}

// Calculate meteor impact flash at a given position
float calculate_meteor_impact(vec2 uv, float time) {
	float total_glow = 0.0;

	// Generate multiple potential impact sites
	for (float i = 0.0; i < 8.0; i++) {
		// Random timing for this impact slot
		float time_offset = hash(vec2(i * 7.123, i * 3.456)) * 100.0;
		float local_time = time * meteor_frequency + time_offset;
		float impact_cycle = floor(local_time);
		float impact_progress = fract(local_time);

		// Only show impact during flash duration
		if (impact_progress < meteor_flash_duration) {
			// Random position for this impact
			vec2 impact_pos = vec2(
				hash(vec2(impact_cycle, i * 2.1)),
				hash(vec2(impact_cycle, i * 3.7))
			);

			// Random size between min and max
			float size = mix(meteor_min_size, meteor_max_size,
				hash(vec2(impact_cycle, i * 5.3)));

			// Distance from impact center
			float dist = distance(uv, impact_pos);

			// Flash intensity (bright at start, fades quickly)
			float flash_fade = 1.0 - (impact_progress / meteor_flash_duration);
			flash_fade = pow(flash_fade, 2.0);

			// Impact glow with bright center and expanding ring
			float core_glow = exp(-dist * dist / (size * size * 0.5)) * flash_fade;
			float ring_expansion = impact_progress / meteor_flash_duration;
			float ring_dist = abs(dist - size * ring_expansion * 2.0);
			float ring_glow = exp(-ring_dist * ring_dist / (size * size * 0.2)) * flash_fade * 0.5;

			total_glow += (core_glow + ring_glow) * meteor_intensity;
		}
	}

	return total_glow;
}

// Calculate lightning strike effect (circular flashes like meteors, but sharper and clustered)
float calculate_lightning(vec2 uv, float time) {
	float total_lightning = 0.0;

	// Generate multiple potential lightning events
	for (float i = 0.0; i < 6.0; i++) {
		// Random timing for this lightning event
		float time_offset = hash(vec2(i * 9.876, i * 4.321)) * 100.0;
		float local_time = time * lightning_frequency + time_offset;
		float strike_cycle = floor(local_time);
		float strike_progress = fract(local_time);

		// Only show lightning during flash duration
		if (strike_progress < lightning_flash_duration) {
			// Random cluster center position
			vec2 cluster_center = vec2(
				hash(vec2(strike_cycle, i * 1.9)),
				hash(vec2(strike_cycle, i * 2.8))
			);

			// Create multiple localized strikes around the cluster center
			for (float strike = 0.0; strike < lightning_strike_count; strike++) {
				// Random offset from cluster center
				vec2 strike_offset = vec2(
					hash(vec2(strike_cycle, strike * 8.5 + i)) - 0.5,
					hash(vec2(strike_cycle, strike * 9.3 + i)) - 0.5
				) * lightning_cluster_radius;

				vec2 strike_pos = cluster_center + strike_offset;

				// Random size between min and max
				float size = mix(lightning_min_size, lightning_max_size,
					hash(vec2(strike_cycle, strike * 4.7 + i)));

				// Distance from strike center
				float dist = distance(uv, strike_pos);

				// Flash intensity (instant bright, very quick fade)
				float flash_fade = 1.0 - (strike_progress / lightning_flash_duration);
				flash_fade = pow(flash_fade, 4.0); // Sharper fade than meteors

				// Very sharp center core with electrical glow
				// Using much tighter exponential for the sharp center
				float sharp_core = exp(-dist * dist / (size * size * 0.1)) * flash_fade;

				// Wider electrical aura
				float electrical_aura = exp(-dist * dist / (size * size * 1.5)) * flash_fade * 0.3;

				// Add slight flickering effect within the flash duration
				float flicker = 0.7 + 0.3 * hash(vec2(strike_cycle * 10.0, strike * 7.3));

				total_lightning += (sharp_core + electrical_aura) * lightning_intensity * flicker;
			}
		}
	}

	return total_lightning;
}

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	vec3 base_color = albedo.rgb * albedo_tex.rgb;

	// Calculate atmospheric effects
	vec3 emission = vec3(0.0);

	if (meteor_enabled) {
		float meteor_glow = calculate_meteor_impact(base_uv, TIME);
		emission += meteor_color * meteor_glow;
	}

	if (lightning_enabled) {
		float lightning_glow = calculate_lightning(base_uv, TIME);
		emission += lightning_color * lightning_glow;
	}

	ALBEDO = base_color;
	EMISSION = emission;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
}
