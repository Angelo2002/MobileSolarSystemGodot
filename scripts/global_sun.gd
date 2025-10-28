extends Node
## Global autoload singleton for sun direction tracking
## Allows all scenes and viewports to access synchronized sun lighting data
## This is essential for "own world" viewport scenarios where nodes can't reference each other

# Global sun direction (normalized vector pointing FROM origin TO the sun)
var sun_direction: Vector3 = Vector3(1, 0, 0)

# Optional: sun intensity for shader/atmospheric effects
var sun_intensity: float = 1.0

## Updates the global sun direction
## Call this from your sun orbit controller every frame
## @param new_direction: The sun's world position (will be normalized automatically)
func update_sun_direction(new_direction: Vector3) -> void:
	if new_direction.length_squared() > 0.0:
		sun_direction = new_direction.normalized()

## Calculates eclipse shadow amount based on occluder position
## Returns 0.0 (no eclipse) to 1.0 (full eclipse)
## @param observer_pos: Position of the surface being lit (e.g., moon position)
## @param occluder_pos: Position of the object blocking light (e.g., Saturn position)
## @param occluder_radius: Visual radius of the occluder for eclipse penumbra
## @param penumbra_softness: Multiplier for penumbra size (1.0 = sharp, 1.5 = soft, 2.0 = very soft)
func calculate_eclipse(observer_pos: Vector3, occluder_pos: Vector3, occluder_radius: float = 1.0, penumbra_softness: float = 1.5) -> float:
	# Direction from observer to occluder
	var to_occluder = occluder_pos - observer_pos
	var distance_to_occluder = to_occluder.length()

	if distance_to_occluder < 0.001:
		return 1.0  # Observer inside occluder

	var to_occluder_dir = to_occluder / distance_to_occluder

	# Calculate angle between sun direction and occluder direction
	var angle = sun_direction.angle_to(to_occluder_dir)

	# Calculate angular size of the occluder from observer's perspective
	# angular_radius ≈ arctan(radius / distance) for small angles
	var angular_radius = atan(occluder_radius / distance_to_occluder)

	# Add a soft penumbra region (multiplied by softness parameter)
	var eclipse_threshold = angular_radius * penumbra_softness

	if angle < angular_radius:
		# Full eclipse - occluder completely blocks sun
		return 1.0
	elif angle < eclipse_threshold:
		# Partial eclipse - smooth penumbra transition
		var t = (angle - angular_radius) / (eclipse_threshold - angular_radius)
		return 1.0 - t  # Linear falloff (could use smoothstep for softer)
	else:
		# No eclipse
		return 0.0
