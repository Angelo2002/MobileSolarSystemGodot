extends WorldEnvironment

## Earth Sky Controller
## Updates the Earth sky shader with dynamic sun and moon positioning
## Supports lunar phases and eclipses based on celestial positions
## Attach this to the WorldEnvironment node in your Earth view scene

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_group("Scene References")
## Reference to the Sun node in the scene (for sun direction calculation)
@export var sun_node: Node3D

## Reference to the Moon node in the scene (for moon direction and orientation)
@export var moon_node: Node3D

@export_group("Sky Settings")
## Enable automatic sun direction updates
@export var update_sun_direction: bool = true

## Enable automatic moon direction updates (for lunar phases)
@export var update_moon_direction: bool = true

## Manual sun direction override (used if update_sun_direction is false)
@export var manual_sun_direction: Vector3 = Vector3(0.0, 1.0, 0.0)

## Manual moon direction override (used if update_moon_direction is false)
@export var manual_moon_direction: Vector3 = Vector3(0.0, 1.0, 0.5)

@export_group("Star Field Settings")
## Star rotation speed (simulates Earth's rotation for day/night cycle)
@export var star_rotation_enabled: bool = true

## Star latitude (observer's latitude on Earth, affects star field orientation)
@export_range(-90.0, 90.0) var latitude: float = 0.0

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
			push_error("Earth Sky Controller: No sky material found on Environment")
			return

		if not sky_material is ShaderMaterial:
			push_error("Earth Sky Controller: Sky material is not a ShaderMaterial")
			return
	else:
		push_error("Earth Sky Controller: WorldEnvironment has no Environment or Sky configured")
		return

	# Validate node references
	if update_sun_direction and not sun_node:
		push_warning("Earth Sky Controller: update_sun_direction is enabled but sun_node is not set")

	if update_moon_direction and not moon_node:
		push_warning("Earth Sky Controller: update_moon_direction is enabled but moon_node is not set")

	# Set initial latitude
	if sky_material:
		sky_material.set_shader_parameter("star_latitude", latitude)

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

	# Update moon direction and orientation
	if update_moon_direction and moon_node:
		update_moon_from_node()
	else:
		# Use manual direction
		sky_material.set_shader_parameter("moon_dir", manual_moon_direction.normalized())

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

## Calculate moon direction and orientation matrix from moon node
func update_moon_from_node():
	# Get moon's global transform
	var moon_transform = moon_node.global_transform
	var moon_basis = moon_transform.basis

	# Moon direction: forward vector (basis.z)
	# This is the direction from observer to moon
	var moon_direction = moon_basis.z

	# Moon world-to-object matrix: inverse of basis
	# This is used to sample the moon cubemap with correct orientation
	var moon_world_to_object = moon_basis.inverse()

	# Update shader parameters
	sky_material.set_shader_parameter("moon_dir", moon_direction)
	sky_material.set_shader_parameter("moon_world_to_object", moon_world_to_object)

## Manually set sun direction (useful for testing or fixed lighting scenarios)
func set_sun_direction(direction: Vector3):
	if sky_material:
		sky_material.set_shader_parameter("sun_dir", direction.normalized())

## Manually set moon direction (useful for testing lunar phases)
func set_moon_direction(direction: Vector3):
	if sky_material:
		sky_material.set_shader_parameter("moon_dir", direction.normalized())

## Set moon world-to-object matrix manually (for moon texture orientation)
func set_moon_world_to_object(matrix: Basis):
	if sky_material:
		sky_material.set_shader_parameter("moon_world_to_object", matrix)

## Set star field rotation speed (for day/night cycle)
func set_star_rotation_speed(speed: float):
	if sky_material:
		sky_material.set_shader_parameter("star_rotation_speed", speed)

## Set observer latitude on Earth (affects star field rotation)
func set_latitude(latitude_degrees: float):
	latitude = clamp(latitude_degrees, -90.0, 90.0)
	if sky_material:
		sky_material.set_shader_parameter("star_latitude", latitude)

## Set star visibility during day (0.0 = hidden, 1.0 = full brightness)
func set_star_day_visibility(visibility: float):
	if sky_material:
		sky_material.set_shader_parameter("star_day_visibility", clamp(visibility, 0.0, 1.0))

## Set moon exposure (brightness adjustment)
func set_moon_exposure(exposure: float):
	if sky_material:
		sky_material.set_shader_parameter("moon_exposure", exposure)

## Get current sun direction
func get_sun_direction() -> Vector3:
	if sky_material:
		return sky_material.get_shader_parameter("sun_dir")
	return Vector3.ZERO

## Get current moon direction
func get_moon_direction() -> Vector3:
	if sky_material:
		return sky_material.get_shader_parameter("moon_dir")
	return Vector3.ZERO
