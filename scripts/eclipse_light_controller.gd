extends Node3D
## Calculates eclipse shadows when celestial bodies block the sun
## Modulates foreground lighting to simulate eclipse darkness
## Attach this to the root of your view scene

@export_group("Scene References")
## The celestial body in the sky that can block the sun (e.g., Saturn when on moon surface)
@export var sky_occluder: Node3D
## The surface being lit (typically the landing site/moon)
@export var surface: Node3D
## The DirectionalLight in the foreground viewport that lights the surface
@export var foreground_light: DirectionalLight3D

@export_group("Eclipse Parameters")
## Visual radius of the occluder for eclipse calculation (adjust based on apparent size)
## For Saturn viewed from its moon, this should be Saturn's visual scale
@export var occluder_radius: float = 10.0
## Minimum light energy during full eclipse (0.0 = complete darkness, 0.1 = ambient twilight)
@export var min_eclipse_brightness: float = 0.05
## Maximum light energy in full sunlight
@export var max_light_energy: float = 1.0

func _process(_delta: float) -> void:
	if not sky_occluder or not surface or not foreground_light:
		return

	# Get world positions
	var surface_pos = surface.global_position
	var occluder_pos = sky_occluder.global_position

	# Calculate eclipse amount (0.0 = no eclipse, 1.0 = full eclipse)
	var eclipse_amount = GlobalSun.calculate_eclipse(surface_pos, occluder_pos, occluder_radius)

	# Modulate light energy based on eclipse
	# Full sunlight when eclipse_amount = 0.0
	# Minimum brightness when eclipse_amount = 1.0
	foreground_light.light_energy = lerp(max_light_energy, min_eclipse_brightness, eclipse_amount)
