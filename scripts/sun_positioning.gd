extends "res://scripts/planet_positioning.gd"
## Sun positioning script combining apparent size controls with orbital motion
## Allows setting distance/apparent size while also supporting orbital animation
## Perfect for creating Sun instances visible from different planetary surfaces

@export_group("Skybox Synchronization")
## Reference to the WorldEnvironment node with rotating_skybox.gd script
@export var skybox: WorldEnvironment
## Follow the skybox's rotation as a base
@export var follow_skybox: bool = true
## Invert the orbital direction (true for realistic surface view - planet rotates one way, sun moves opposite)
@export var invert_direction: bool = true

@export_group("Orbital Motion (simulates planet's orbit)")
## Enable independent orbital rotation (set to false for distant planets like Saturn)
@export var orbit_enabled: bool = true
## Orbital rotation speed in degrees per second (added on top of skybox rotation)
@export var orbital_speed_x: float = 0.0
@export var orbital_speed_y: float = 1.0
@export var orbital_speed_z: float = 0.0

## Accumulated orbital offset (separate from skybox rotation)
var orbital_offset: Vector3 = Vector3.ZERO

## Override to prevent static positioning from parent
var _orbit_active: bool = false


func _ready() -> void:
	super._ready()
	_orbit_active = orbit_enabled or follow_skybox


func _process(delta: float) -> void:
	if not _orbit_active:
		return

	# Calculate the angular rotation from skybox and orbital motion
	var angle_rotation = Vector3.ZERO

	# Get base rotation from skybox if enabled
	if follow_skybox and skybox and skybox.environment:
		angle_rotation = skybox.environment.sky_rotation

	# Add independent orbital motion if enabled
	if orbit_enabled:
		var orbital_delta = Vector3(
			deg_to_rad(orbital_speed_x) * delta,
			deg_to_rad(orbital_speed_y) * delta,
			deg_to_rad(orbital_speed_z) * delta
		)
		orbital_offset += orbital_delta
		angle_rotation += orbital_offset

	# Invert direction if needed (for realistic surface view)
	if invert_direction:
		angle_rotation = -angle_rotation

	# Calculate orbital position at the configured distance
	# Start with direction vector at the specified distance
	var orbit_radius = distance_from_surface * scale_factor
	var new_position = direction * orbit_radius

	# Apply rotations: Y (primary day/night), then X (tilt), then Z (variation)

	# Rotate around Y axis (main day/night cycle)
	if angle_rotation.y != 0:
		var cos_y = cos(angle_rotation.y)
		var sin_y = sin(angle_rotation.y)
		new_position = Vector3(
			new_position.x * cos_y - new_position.z * sin_y,
			new_position.y,
			new_position.x * sin_y + new_position.z * cos_y
		)

	# Rotate around X axis (seasonal tilt)
	if angle_rotation.x != 0:
		var cos_x = cos(angle_rotation.x)
		var sin_x = sin(angle_rotation.x)
		new_position = Vector3(
			new_position.x,
			new_position.y * cos_x - new_position.z * sin_x,
			new_position.y * sin_x + new_position.z * cos_x
		)

	# Rotate around Z axis (additional variation)
	if angle_rotation.z != 0:
		var cos_z = cos(angle_rotation.z)
		var sin_z = sin(angle_rotation.z)
		new_position = Vector3(
			new_position.x * cos_z - new_position.y * sin_z,
			new_position.x * sin_z + new_position.y * cos_z,
			new_position.z
		)

	# Apply the calculated orbital position
	position = new_position

	# Update global sun direction for cross-viewport synchronization
	GlobalSun.update_sun_direction(global_position)


## Override parent's transform update to work with orbital motion
func _update_planet_transform() -> void:
	if _updating:
		return
	_updating = true

	# Calculate actual radius from apparent size if needed
	if not use_actual_radius:
		var apparent_size_rad = deg_to_rad(apparent_size_degrees)
		var required_diameter = 2.0 * distance_from_surface * tan(apparent_size_rad / 2.0)
		actual_radius = required_diameter / 2.0

	# Scale the mesh to match the required diameter
	var required_scale = (actual_radius * 2.0 * scale_factor) / mesh_diameter
	scale = Vector3(required_scale, required_scale, required_scale)

	# Position is handled by _process() if orbit is active
	if not _orbit_active:
		var scaled_distance = distance_from_surface * scale_factor
		position = direction * scaled_distance

	_updating = false
