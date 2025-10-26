extends DirectionalLight3D
## Synchronizes this directional light with the Sun position in the background viewport
## This makes planets in the main scene receive proper lighting and cast shadows

@export_group("Sun Reference")
## Reference to the Sun node in the background viewport
## This should be the Node3D with sun_orbit_controller.gd attached
@export var background_sun: Node3D

@export_group("Light Settings")
## Invert the light direction (useful if your Sun is positioned opposite to desired light direction)
@export var invert_direction: bool = false
## Additional rotation offset in degrees (applied after sun direction calculation)
@export var rotation_offset: Vector3 = Vector3.ZERO

func _process(_delta: float) -> void:
	if not background_sun:
		return

	# Get the sun's position in world space
	# For a directional light, we only care about direction, not distance
	var sun_position = background_sun.global_position

	# Calculate the direction from origin to sun
	var light_direction = sun_position.normalized()

	# Invert if needed (light rays come FROM the sun)
	if invert_direction:
		light_direction = -light_direction

	# Convert direction vector to rotation
	# Look at the sun's position (or away from it if inverted)
	var target_position = global_position + light_direction
	look_at(target_position, Vector3.UP)

	# Apply any additional rotation offset
	if rotation_offset != Vector3.ZERO:
		var offset_rad = Vector3(
			deg_to_rad(rotation_offset.x),
			deg_to_rad(rotation_offset.y),
			deg_to_rad(rotation_offset.z)
		)
		rotation += offset_rad
