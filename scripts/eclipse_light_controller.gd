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
	var global_scale = mesh_instance.global_transform.basis.get_scale()
	var avg_scale = (global_scale.x + global_scale.y + global_scale.z) / 3.0

	cached_radius = mesh_radius * avg_scale
	print("Eclipse: Auto-calculated occluder radius = ", cached_radius)
	return cached_radius

func _process(_delta: float) -> void:
	if not sky_occluder or not surface or not foreground_light:
		return

	# Get world positions
	var surface_pos = surface.global_position
	var occluder_pos = sky_occluder.global_position

	# Get the effective occluder radius (auto-calculated or manual)
	var effective_radius = get_occluder_visual_radius()

	# Calculate eclipse amount (0.0 = no eclipse, 1.0 = full eclipse)
	var eclipse_amount = GlobalSun.calculate_eclipse(surface_pos, occluder_pos, effective_radius, penumbra_softness)

	# Modulate light energy based on eclipse
	# Full sunlight when eclipse_amount = 0.0
	# Minimum brightness when eclipse_amount = 1.0
	foreground_light.light_energy = lerp(max_light_energy, min_eclipse_brightness, eclipse_amount)
