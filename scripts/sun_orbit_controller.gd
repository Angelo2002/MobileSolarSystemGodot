extends Node3D
## Controls the Sun's rotation in the background viewport
## Combines skybox rotation with independent orbital motion to simulate planetary years

@export_group("Skybox Synchronization")
## Reference to the WorldEnvironment node with rotating_skybox.gd script
@export var skybox: WorldEnvironment
## Follow the skybox's rotation as a base
@export var follow_skybox: bool = true

@export_group("Orbital Motion (simulates planet's orbit)")
## Enable independent orbital rotation (set to false for distant planets like Saturn)
@export var orbit_enabled: bool = true
## Orbital rotation speed in degrees per second (added on top of skybox rotation)
@export var orbital_speed_x: float = 0.0
@export var orbital_speed_y: float = 1.0
@export var orbital_speed_z: float = 0.0

## Accumulated orbital offset (separate from skybox rotation)
var orbital_offset: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	var final_rotation = Vector3.ZERO

	# Get base rotation from skybox if enabled
	if follow_skybox and skybox and skybox.environment:
		final_rotation = skybox.environment.sky_rotation

	# Add independent orbital motion if enabled
	if orbit_enabled:
		var orbital_delta = Vector3(
			deg_to_rad(orbital_speed_x) * delta,
			deg_to_rad(orbital_speed_y) * delta,
			deg_to_rad(orbital_speed_z) * delta
		)
		orbital_offset += orbital_delta
		final_rotation += orbital_offset

	# Apply the combined rotation
	rotation = final_rotation
