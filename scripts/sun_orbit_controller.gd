extends Node3D
## Controls the Sun's orbital position in the background viewport
## Calculates 3D position based on skybox rotation to simulate planetary day/year cycles

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

@export_group("Orbit Parameters")
## Distance from the center (automatically set from initial position if 0)
@export var orbit_distance: float = 0.0

## Initial position - stored on first frame to calculate orbit distance and starting angle
var initial_position: Vector3
var initial_rotation: Vector3
var orbit_initialized: bool = false

## Accumulated orbital offset (separate from skybox rotation)
var orbital_offset: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	if not is_inside_tree():
		print("ERROR: sun_orbit_controller.gd _process() - node not in tree yet")
		return

	# Initialize orbit parameters from starting position on first frame
	if not orbit_initialized:
		initial_position = global_position
		initial_rotation = rotation
		if orbit_distance == 0.0:
			orbit_distance = initial_position.length()
		orbit_initialized = true

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

	# Convert angular rotation to orbital position
	# We apply rotations in order: Y (primary), then X, then Z
	var new_position = Vector3(orbit_distance, 0, 0)

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
	global_position = new_position

	# Update global sun direction for cross-viewport synchronization
	GlobalSun.update_sun_direction(global_position)
