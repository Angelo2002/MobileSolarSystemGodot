extends WorldEnvironment

## Venus Sky Controller
## Updates the Venus sky shader with dynamic sun positioning
## Venus's thick atmosphere blocks stars and moon, so only sun tracking is needed
## Attach this to the WorldEnvironment node in your Venus view scene

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_group("Scene References")
## Reference to the Sun node in the scene (for sun direction calculation)
@export var sun_node: Node3D

@export_group("Sky Settings")
## Enable automatic sun direction updates
@export var update_sun_direction: bool = true

## Manual sun direction override (used if update_sun_direction is false)
@export var manual_sun_direction: Vector3 = Vector3(0.0, 1.0, 0.0)

@export_group("Atmospheric Settings")
## Cloud opacity (how dense the sulfuric acid cloud deck is)
@export_range(0.0, 1.0) var cloud_opacity: float = 0.95

## Sun diffusion (how much the sun is scattered by clouds)
@export_range(0.0, 1.0) var sun_diffusion: float = 0.85

## Day/night transition sharpness (thick atmosphere = abrupt transition)
@export_range(0.0, 1.0) var day_night_sharpness: float = 0.8

@export_group("Lightning (Future Implementation)")
## Lightning flash intensity (reserved for future particle system)
@export_range(0.0, 5.0) var lightning_intensity: float = 0.0

## Lightning position in sky (normalized coordinates)
@export var lightning_position: Vector2 = Vector2(0.5, 0.5)

# ============================================================================
# INTERNAL STATE
# ============================================================================

var sky_material: ShaderMaterial

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	# Get reference to the sky shader material
	if environment and environment.sky:
		sky_material = environment.sky.sky_material

		if not sky_material:
			push_error("Venus Sky Controller: No sky material found on Environment")
			return

		if not sky_material is ShaderMaterial:
			push_error("Venus Sky Controller: Sky material is not a ShaderMaterial")
			return
	else:
		push_error("Venus Sky Controller: WorldEnvironment has no Environment or Sky configured")
		return

	# Validate sun node reference
	if update_sun_direction and not sun_node:
		push_warning("Venus Sky Controller: update_sun_direction is enabled but sun_node is not set")

	# Set initial atmospheric parameters
	if sky_material:
		sky_material.set_shader_parameter("cloud_opacity", cloud_opacity)
		sky_material.set_shader_parameter("sun_diffusion", sun_diffusion)
		sky_material.set_shader_parameter("day_night_transition_sharpness", day_night_sharpness)

# ============================================================================
# UPDATE LOOP
# ============================================================================

func _process(_delta: float):
	if not sky_material:
		return

	# Update sun direction
	if update_sun_direction and sun_node:
		update_sun_direction_from_node()
	else:
		# Use manual direction
		sky_material.set_shader_parameter("sun_dir", manual_sun_direction.normalized())

	# Update lightning parameters (if implemented)
	if lightning_intensity > 0.0:
		sky_material.set_shader_parameter("lightning_intensity", lightning_intensity)
		sky_material.set_shader_parameter("lightning_position", lightning_position)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Calculate sun direction from sun node position
func update_sun_direction_from_node():
	# Get sun position in world space
	var sun_position = sun_node.global_position

	# Calculate direction from camera/observer to sun
	# For sky shader, we want the direction TO the sun (not from)
	var sun_direction = sun_position.normalized()

	# Update shader parameter
	sky_material.set_shader_parameter("sun_dir", sun_direction)

## Manually set sun direction (useful for testing or fixed lighting scenarios)
func set_sun_direction(direction: Vector3):
	if sky_material:
		sky_material.set_shader_parameter("sun_dir", direction.normalized())

## Set cloud opacity (0.0 = clear, 1.0 = very opaque)
## Venus typically has very high opacity (0.9-0.99)
func set_cloud_opacity(opacity: float):
	cloud_opacity = clamp(opacity, 0.0, 1.0)
	if sky_material:
		sky_material.set_shader_parameter("cloud_opacity", cloud_opacity)

## Set sun diffusion (0.0 = sharp, 1.0 = completely scattered)
## Venus has heavy diffusion due to thick sulfuric acid clouds
func set_sun_diffusion(diffusion: float):
	sun_diffusion = clamp(diffusion, 0.0, 1.0)
	if sky_material:
		sky_material.set_shader_parameter("sun_diffusion", sun_diffusion)

## Set day/night transition sharpness
## Venus's thick atmosphere causes very abrupt darkness at sunset
func set_day_night_sharpness(sharpness: float):
	day_night_sharpness = clamp(sharpness, 0.0, 1.0)
	if sky_material:
		sky_material.set_shader_parameter("day_night_transition_sharpness", day_night_sharpness)

## Trigger lightning flash (for future particle system integration)
## Call this from a particle system or procedural lightning generator
func trigger_lightning(position_2d: Vector2, intensity: float = 2.0, duration: float = 0.1):
	if sky_material:
		lightning_position = position_2d
		lightning_intensity = intensity
		sky_material.set_shader_parameter("lightning_position", lightning_position)
		sky_material.set_shader_parameter("lightning_intensity", lightning_intensity)

		# Automatically fade out lightning after duration
		await get_tree().create_timer(duration).timeout
		fade_lightning(0.2)

## Fade lightning flash out over time
func fade_lightning(fade_duration: float = 0.2):
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "lightning_intensity", 0.0, fade_duration)
	fade_tween.tween_callback(func():
		if sky_material:
			sky_material.set_shader_parameter("lightning_intensity", 0.0)
	)

## Set cloud detail strength (for future cloud texture implementation)
func set_cloud_detail_strength(strength: float):
	if sky_material:
		sky_material.set_shader_parameter("cloud_detail_strength", clamp(strength, 0.0, 0.5))

## Get current sun direction
func get_sun_direction() -> Vector3:
	if sky_material:
		return sky_material.get_shader_parameter("sun_dir")
	return Vector3.ZERO

## Simulate dust storm effect (increase cloud opacity and sun diffusion)
func simulate_dust_storm(storm_intensity: float = 1.0):
	var base_opacity = 0.95
	var base_diffusion = 0.85
	set_cloud_opacity(base_opacity + (1.0 - base_opacity) * storm_intensity)
	set_sun_diffusion(base_diffusion + (1.0 - base_diffusion) * storm_intensity * 0.5)
