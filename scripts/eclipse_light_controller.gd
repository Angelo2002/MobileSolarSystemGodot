extends Node3D
## Calculates eclipse shadows when celestial bodies block the sun
## Modulates foreground lighting to simulate eclipse darkness
## Attach this to the root of your view scene

@export_group("Scene References")
## The celestial body in the sky that can block the sun (e.g., Saturn when on moon surface)
@export var sky_occluder: Node3D
## The camera in the background viewport (used to calculate direction to occluder)
@export var background_camera: Camera3D
## The DirectionalLight in the foreground viewport that lights the surface
@export var foreground_light: DirectionalLight3D

@export_group("Eclipse Parameters")
## Auto-calculate occluder radius from mesh size (recommended for dynamic scaling)
@export var auto_calculate_radius: bool = true
## Manual visual radius (only used if auto_calculate_radius is false)
@export var occluder_radius: float = 10.0
## Penumbra softness (1.0 = sharp eclipse, 1.2 = realistic, 1.5 = soft, 2.0 = very gradual)
@export_range(1.0, 3.0, 0.1) var penumbra_softness: float = 1.2
## Minimum light energy during full eclipse (0.0 = complete darkness, 0.1 = ambient twilight)
@export var min_eclipse_brightness: float = 0.05
## Maximum light energy in full sunlight
@export var max_light_energy: float = 1.0

## Cached radius to avoid recalculating every frame
var cached_radius: float = -1.0

## Gets the visual radius of the occluder
## Auto-calculates from mesh if enabled, otherwise uses manual value
func get_occluder_visual_radius() -> float:
	if not auto_calculate_radius:
		return occluder_radius

	# Return cached value if already calculated
	if cached_radius > 0.0:
		return cached_radius

	# Find MeshInstance3D (could be the node itself or a child)
	var mesh_instance: MeshInstance3D = null
	if sky_occluder is MeshInstance3D:
		mesh_instance = sky_occluder as MeshInstance3D
	else:
		# Search for MeshInstance3D in children
		for child in sky_occluder.get_children():
			if child is MeshInstance3D:
				mesh_instance = child as MeshInstance3D
				break

	if not mesh_instance or not mesh_instance.mesh:
		push_warning("Eclipse: Could not find mesh on sky_occluder, using manual radius")
		return occluder_radius

	# Get mesh AABB and calculate bounding sphere radius
	var aabb = mesh_instance.mesh.get_aabb()
	var mesh_radius = aabb.size.length() / 2.0  # Half diagonal = bounding sphere radius

	# Apply global scale
	var _global_scale = mesh_instance.global_transform.basis.get_scale()
	var avg_scale = (_global_scale.x + _global_scale.y + _global_scale.z) / 3.0

	cached_radius = mesh_radius * avg_scale
	print("Eclipse: Auto-calculated occluder radius = ", cached_radius)
	return cached_radius

func _process(_delta: float) -> void:
	if not sky_occluder or not background_camera or not foreground_light:
		return

	# Calculate direction from background camera to occluder (both in same viewport world)
	var camera_pos = background_camera.global_position
	var occluder_pos = sky_occluder.global_position
	var to_occluder = occluder_pos - camera_pos
	var distance_to_occluder = to_occluder.length()

	if distance_to_occluder < 0.001:
		# Camera inside occluder - full eclipse
		foreground_light.light_energy = min_eclipse_brightness
		return

	# Normalize to get direction
	var to_occluder_dir = to_occluder / distance_to_occluder

	# Get the effective occluder radius (auto-calculated or manual)
	var effective_radius = get_occluder_visual_radius()

	# Calculate angular size of the occluder from camera's perspective
	var angular_radius = atan(effective_radius / distance_to_occluder)

	# Calculate eclipse amount using direction-based method (works across viewport boundaries)
	var eclipse_amount = GlobalSun.calculate_eclipse_from_direction(to_occluder_dir, angular_radius, penumbra_softness)

	# Modulate light energy based on eclipse
	# Full sunlight when eclipse_amount = 0.0
	# Minimum brightness when eclipse_amount = 1.0
	foreground_light.light_energy = lerp(max_light_energy, min_eclipse_brightness, eclipse_amount)
