extends Node3D
## Controls sun glare visibility and intensity based on distance and occlusion
## Attach this to the Sun node alongside sun_positioning.gd
## Requires a child billboard node (Sprite3D or MeshInstance3D with QuadMesh)

@export_group("References")
## Camera to calculate distance and direction from
@export var camera: Camera3D
## Billboard node (Sprite3D or MeshInstance3D) that displays the glare effect
@export var billboard: Node3D
## Optional: Reference to the sun's MeshInstance3D for surface shader adjustments
@export var sun_mesh: MeshInstance3D

@export_group("Distance Scaling")
## Minimum distance where glare starts to appear
@export var min_distance: float = 100.0
## Maximum distance where glare reaches full size
@export var max_distance: float = 10000.0
## Billboard scale at minimum distance
@export var min_scale: float = 1.0
## Billboard scale at maximum distance (larger = more visible when far)
@export var max_scale: float = 50.0
## How billboard size scales with distance (linear, quadratic, etc)
@export_enum("Linear", "Quadratic", "Sqrt") var scale_curve: int = 0

@export_group("Intensity Scaling")
## Enable distance-based intensity falloff
@export var enable_distance_fade: bool = true
## Distance where intensity starts to fade
@export var fade_start_distance: float = 100.0
## Distance where intensity reaches minimum
@export var fade_end_distance: float = 50000.0
## Minimum intensity at maximum distance
@export var min_intensity: float = 0.3
## Intensity curve power
@export var intensity_curve: float = 1.0

@export_group("Occlusion Detection")
## Enable occlusion detection (angular blocking by planets)
@export var enable_occlusion: bool = true
## List of potential occluders (planets, moons, etc.)
@export var occluders: Array[Node3D] = []
## Auto-detect occluders from parent scene
@export var auto_detect_occluders: bool = true
## Minimum angular size (degrees) for an object to be considered an occluder
@export var min_occluder_angular_size: float = 0.1

@export_group("Debug")
@export var debug_info: bool = false

## Cached shader material reference
var billboard_material: ShaderMaterial
var sun_material: ShaderMaterial

## Current fade values
var current_distance_fade: float = 1.0
var current_occlusion_fade: float = 1.0


func _ready() -> void:
	# Get billboard material
	if billboard:
		if billboard is Sprite3D:
			billboard_material = billboard.material_override as ShaderMaterial
		elif billboard is MeshInstance3D:
			billboard_material = billboard.get_active_material(0) as ShaderMaterial

	# Get sun mesh material if provided
	if sun_mesh:
		sun_material = sun_mesh.get_active_material(0) as ShaderMaterial

	# Auto-detect occluders if enabled
	if auto_detect_occluders and occluders.is_empty():
		_auto_detect_occluders()


func _process(_delta: float) -> void:
	if not camera:
		return

	# Calculate distance from camera to sun (use parent position if this is a child node)
	var sun_position = get_parent().global_position if get_parent() else global_position
	var camera_position = camera.global_position
	var distance = sun_position.distance_to(camera_position)

	# Update billboard scale based on distance
	if billboard:
		_update_billboard_scale(distance)

	# Calculate distance fade
	_update_distance_fade(distance)

	# Calculate occlusion fade
	if enable_occlusion:
		_update_occlusion_fade()

	# Apply to shader materials
	_apply_shader_parameters()

	# Debug output
	if debug_info:
		_print_debug_info(distance)


func _update_billboard_scale(distance: float) -> void:
	# Calculate scale factor based on distance
	var t = clamp((distance - min_distance) / (max_distance - min_distance), 0.0, 1.0)

	# Apply curve
	match scale_curve:
		0: # Linear
			pass
		1: # Quadratic
			t = t * t
		2: # Square root
			t = sqrt(t)

	# Interpolate scale
	var target_scale = lerp(min_scale, max_scale, t)

	# Apply uniform scale to billboard
	billboard.scale = Vector3(target_scale, target_scale, target_scale)


func _update_distance_fade(distance: float) -> void:
	if not enable_distance_fade:
		current_distance_fade = 1.0
		return

	# Calculate fade based on distance
	var t = clamp((distance - fade_start_distance) / (fade_end_distance - fade_start_distance), 0.0, 1.0)

	# Apply curve
	t = pow(t, intensity_curve)

	# Calculate fade (1.0 at close, min_intensity at far)
	current_distance_fade = lerp(1.0, min_intensity, t)


func _update_occlusion_fade() -> void:
	if not camera:
		current_occlusion_fade = 1.0
		return

	var sun_position = get_parent().global_position if get_parent() else global_position
	var camera_position = camera.global_position

	# Direction from camera to sun
	var sun_direction = (sun_position - camera_position).normalized()
	var sun_distance = sun_position.distance_to(camera_position)

	# Calculate sun's angular size
	var sun_radius = _get_sun_radius()
	var sun_angular_size = 0.0
	if sun_distance > 0.0:
		sun_angular_size = 2.0 * atan(sun_radius / sun_distance)

	# Check each occluder
	var max_occlusion = 0.0

	for occluder in occluders:
		if not occluder or occluder == self:
			continue

		var occluder_position = occluder.global_position
		var occluder_distance = camera_position.distance_to(occluder_position)

		# Skip if occluder is behind the sun
		if occluder_distance > sun_distance:
			continue

		# Direction from camera to occluder
		var occluder_direction = (occluder_position - camera_position).normalized()

		# Angular separation between sun and occluder
		var angular_separation = acos(clamp(sun_direction.dot(occluder_direction), -1.0, 1.0))

		# Get occluder radius and calculate angular size
		var occluder_radius = _get_node_radius(occluder)
		var occluder_angular_size = 0.0
		if occluder_distance > 0.0:
			occluder_angular_size = 2.0 * atan(occluder_radius / occluder_distance)

		# Skip if occluder is too small
		if rad_to_deg(occluder_angular_size) < min_occluder_angular_size:
			continue

		# Calculate occlusion amount
		# If angular separation < occluder angular radius, there's occlusion
		var occluder_angular_radius = occluder_angular_size / 2.0
		var sun_angular_radius = sun_angular_size / 2.0

		if angular_separation < (occluder_angular_radius + sun_angular_radius):
			# Calculate overlap fraction
			var occlusion = 1.0 - clamp(angular_separation / occluder_angular_radius, 0.0, 1.0)
			max_occlusion = max(max_occlusion, occlusion)

	# Apply occlusion (1.0 = no occlusion, 0.0 = fully occluded)
	current_occlusion_fade = 1.0 - max_occlusion


func _apply_shader_parameters() -> void:
	# Update billboard shader
	if billboard_material:
		billboard_material.set_shader_parameter("distance_fade", current_distance_fade)
		billboard_material.set_shader_parameter("occlusion_fade", current_occlusion_fade)

	# Optionally update sun surface shader
	if sun_material:
		# Could adjust glow intensity based on distance/occlusion if needed
		pass


func _get_sun_radius() -> float:
	# Try to get radius from sun_positioning.gd script
	var positioning_script = get_node_or_null(".")
	if positioning_script and positioning_script.has_method("get"):
		var actual_radius = positioning_script.get("actual_radius")
		if actual_radius:
			var scale_factor = positioning_script.get("scale_factor")
			if scale_factor:
				return actual_radius * scale_factor

	# Fallback: use mesh AABB if available
	if sun_mesh and sun_mesh.mesh:
		var aabb = sun_mesh.mesh.get_aabb()
		return aabb.get_longest_axis_size() / 2.0 * sun_mesh.scale.x

	# Default fallback
	return 1.0


func _get_node_radius(node: Node3D) -> float:
	# Try to get radius from positioning script
	if node.has_method("get"):
		var actual_radius = node.get("actual_radius")
		if actual_radius:
			var scale_factor = node.get("scale_factor")
			if scale_factor:
				return actual_radius * scale_factor

	# Try MeshInstance3D with AABB
	if node is MeshInstance3D and node.mesh:
		var aabb = node.mesh.get_aabb()
		return aabb.get_longest_axis_size() / 2.0 * node.scale.x

	# Try getting first MeshInstance3D child
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh:
			var aabb = child.mesh.get_aabb()
			return aabb.get_longest_axis_size() / 2.0 * child.scale.x * node.scale.x

	# Default fallback
	return 1.0


func _auto_detect_occluders() -> void:
	# Search parent scene for potential occluders
	var root = get_tree().current_scene
	if not root:
		return

	_search_for_occluders(root)


func _search_for_occluders(node: Node) -> void:
	# Skip self
	if node == self or node == get_parent():
		return

	# Check if node has positioning script (likely a planet)
	if node is Node3D and node.has_method("get"):
		if node.get("actual_radius") != null:
			occluders.append(node)

	# Recursively search children
	for child in node.get_children():
		_search_for_occluders(child)


func _print_debug_info(distance: float) -> void:
	print("=== Sun Glare Debug ===")
	print("Distance: ", distance)
	print("Distance fade: ", current_distance_fade)
	print("Occlusion fade: ", current_occlusion_fade)
	print("Occluders found: ", occluders.size())
	if billboard:
		print("Billboard scale: ", billboard.scale.x)
	print("=====================")
