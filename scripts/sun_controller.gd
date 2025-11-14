extends "res://scripts/sun_positioning.gd"
## Combined sun controller: positioning + glare effects
## Inherits orbital positioning from sun_positioning.gd and adds visual glare control

@export_group("Glare References")
## Camera to calculate distance and direction from
@export var camera: Camera3D
## Billboard node (Sprite3D or MeshInstance3D) that displays the glare effect
@export var billboard: Node3D
## Optional: Reference to the sun's MeshInstance3D for surface shader adjustments
@export var sun_mesh: MeshInstance3D

@export_group("Billboard Scaling")
## Fixed base scale for the billboard glare (e.g., 5.0 = 5 units in size)
@export var billboard_base_scale: float = 5.0
## Enable distance-based scaling (if false, uses fixed billboard_base_scale only)
@export var enable_distance_scaling: bool = true
## Minimum distance where glare starts to appear (only used if distance scaling enabled)
@export var min_distance: float = 100.0
## Maximum distance where glare reaches full size (only used if distance scaling enabled)
@export var max_distance: float = 10000.0
## Billboard scale multiplier at minimum distance (only used if distance scaling enabled)
@export var min_scale: float = 1.0
## Billboard scale multiplier at maximum distance (only used if distance scaling enabled)
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
## Enable occlusion detection (raycast from sun to camera - DISABLED by default, GPU depth testing is simpler)
@export var enable_occlusion: bool = false
## Physics collision mask to check against (set to match planet collision layers)
@export_flags_3d_physics var occlusion_mask: int = 1

@export_group("Debug")
@export var debug_info: bool = false

## Cached shader material reference
var billboard_material: ShaderMaterial
var sun_material: ShaderMaterial

## Current fade values
var current_distance_fade: float = 1.0
var current_occlusion_fade: float = 1.0


func _ready() -> void:
	# Call parent positioning setup
	super._ready()

	# Initialize glare system
	_ready_glare()


func _ready_glare() -> void:
	# Get billboard material
	if billboard:
		if billboard is Sprite3D:
			billboard_material = billboard.material_override as ShaderMaterial
		elif billboard is MeshInstance3D:
			billboard_material = billboard.get_active_material(0) as ShaderMaterial

	# Get sun mesh material if provided
	if sun_mesh:
		sun_material = sun_mesh.get_active_material(0) as ShaderMaterial


func _process(delta: float) -> void:
	# Call parent positioning update
	super._process(delta)

	# Update glare effects
	_process_glare(delta)


func _process_glare(_delta: float) -> void:
	if not camera:
		return

	# Calculate distance from camera to sun
	var sun_position = global_position
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
	# Start with fixed base scale
	var final_scale = billboard_base_scale

	# Optional: Apply distance-based scaling multiplier
	if enable_distance_scaling:
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

		# Interpolate distance-based multiplier
		var distance_multiplier = lerp(min_scale, max_scale, t)

		# Apply distance scaling to base scale
		final_scale *= distance_multiplier

	# Apply uniform scale to billboard
	billboard.scale = Vector3(final_scale, final_scale, final_scale)


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

	var sun_pos = global_position
	var cam_pos = camera.global_position

	# Simple raycast from sun to camera
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(sun_pos, cam_pos)
	query.collision_mask = occlusion_mask
	query.exclude = [self]  # Don't collide with sun itself

	var result = space_state.intersect_ray(query)

	if result:
		# Something is blocking the sun - fade out the glare
		current_occlusion_fade = 0.0
	else:
		# Clear line of sight - full brightness
		current_occlusion_fade = 1.0


func _apply_shader_parameters() -> void:
	# Update billboard shader
	if billboard_material:
		billboard_material.set_shader_parameter("distance_fade", current_distance_fade)
		billboard_material.set_shader_parameter("occlusion_fade", current_occlusion_fade)

	# Optionally update sun surface shader
	if sun_material:
		# Could adjust glow intensity based on distance/occlusion if needed
		pass


func _print_debug_info(distance: float) -> void:
	print("=== Sun Controller Debug ===")
	print("Distance: ", distance)
	print("Distance fade: ", current_distance_fade)
	print("Occlusion fade: ", current_occlusion_fade)
	if billboard:
		print("Billboard scale: ", billboard.scale.x)
	print("===========================")
