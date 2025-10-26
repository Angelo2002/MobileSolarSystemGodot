extends WorldEnvironment

# Rotates the skybox slowly over time
# Useful for creating a subtle sense of motion in space scenes

@export_group("Rotation Speed (degrees per second)")
@export var rotation_speed_x: float = 2.0
@export var rotation_speed_y: float = 3.0
@export var rotation_speed_z: float = 1.0

func _process(delta):
	if not environment:
		return

	# Convert degrees to radians and apply rotation
	var rotation_delta = Vector3(
		deg_to_rad(rotation_speed_x) * delta,
		deg_to_rad(rotation_speed_y) * delta,
		deg_to_rad(rotation_speed_z) * delta
	)

	# Apply rotation to the sky rotation property
	environment.sky_rotation += rotation_delta
