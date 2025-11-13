extends WorldEnvironment

## Mars Sky Controller
## Updates the Mars sky shader with dynamic sun positioning
## Attach this to the WorldEnvironment node in your Mars view scene

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
			push_error("Mars Sky Controller: No sky material found on Environment")
			return

		if not sky_material is ShaderMaterial:
			push_error("Mars Sky Controller: Sky material is not a ShaderMaterial")
			return
	else:
		push_error("Mars Sky Controller: WorldEnvironment has no Environment or Sky configured")
		return

	# Validate sun node reference
	if update_sun_direction and not sun_node:
		push_warning("Mars Sky Controller: update_sun_direction is enabled but sun_node is not set")

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

## Set star visibility during day (0.0 = hidden, 1.0 = full brightness)
func set_star_day_visibility(visibility: float):
	if sky_material:
		sky_material.set_shader_parameter("star_day_visibility", clamp(visibility, 0.0, 1.0))

## Set atmospheric dust opacity (0.0 = clear, 1.0 = very dusty)
func set_dust_opacity(opacity: float):
	if sky_material:
		sky_material.set_shader_parameter("dust_opacity", clamp(opacity, 0.0, 1.0))

## Set star rotation speed (for day/night cycle)
func set_star_rotation_speed(speed: float):
	if sky_material:
		sky_material.set_shader_parameter("star_rotation_speed", speed)

## Set observer latitude on Mars (affects star field rotation)
func set_latitude(latitude_degrees: float):
	if sky_material:
		sky_material.set_shader_parameter("star_latitude", clamp(latitude_degrees, -90.0, 90.0))
