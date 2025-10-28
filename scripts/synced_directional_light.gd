extends DirectionalLight3D
## Synchronizes DirectionalLight with GlobalSun autoload
## Use this for cross-viewport lighting scenarios where viewports have "own world" enabled
## Unlike sun_light_sync.gd, this doesn't require direct node references

@export_group("Light Behavior")
## Light rays come FROM the sun (true) or TO the sun (false)
@export var light_from_sun: bool = true
## Additional rotation offset in degrees (applied after sun direction calculation)
@export var rotation_offset: Vector3 = Vector3.ZERO

func _process(_delta: float) -> void:
	# Get the global sun direction from autoload
	var sun_dir = GlobalSun.sun_direction

	# Determine light direction based on configuration
	var light_direction = -sun_dir if light_from_sun else sun_dir

	# DirectionalLight points in -Z local direction, so we look at the target
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
