extends Node3D

## Planet Teleporter
## Auto-creates a proximity-based teleportation zone with visual feedback
## Attach to any 3D node (planet, landing pad, etc.) to create a teleport trigger
##
## Features:
## - Sphere detection area (configurable radius)
## - Timer that tracks time player stays in area (resets on exit)
## - Progressive VFX that intensifies as teleport approaches:
##   - White flash overlay (ColorRect)
##   - Glowing particle system
## - Automatic scene switching when timer completes
##
## Usage:
##   1. Attach this script to a Node3D (planet, StaticBody3D, etc.)
##   2. Set detection_radius (how close player must be)
##   3. Set time_to_teleport (seconds player must stay in area)
##   4. Set target_scene (path to scene to load)
##   5. Customize VFX colors if desired

# ============================================================================
# EXPORTED PARAMETERS
# ============================================================================

@export_group("Teleport Settings")
## Radius of the detection sphere (in meters/units)
@export var detection_radius: float = 5.0:
	set(value):
		detection_radius = max(0.1, value)
		if detection_area and collision_shape:
			collision_shape.shape.radius = detection_radius

## Time player must stay in area to trigger teleport (in seconds)
@export var time_to_teleport: float = 3.0:
	set(value):
		time_to_teleport = max(0.1, value)

## Scene to load when teleport completes
@export_file("*.tscn") var target_scene: String = ""

@export_group("Visual Effects")
## Color of the particle glow effect
@export var particle_color: Color = Color(1.0, 1.0, 0.8, 1.0):
	set(value):
		particle_color = value
		if particle_system and particle_system.process_material:
			particle_system.process_material.color = value

## Color of the screen flash overlay
@export var flash_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		flash_color = value
		if flash_overlay:
			flash_overlay.color = Color(value.r, value.g, value.b, flash_overlay.color.a)

## Maximum particle emission rate at full intensity
@export_range(10.0, 500.0) var particle_intensity: float = 100.0

## Enable/disable particle effects
@export var enable_particles: bool = true:
	set(value):
		enable_particles = value
		if particle_system:
			particle_system.visible = value
			particle_system.emitting = value and player_in_area

## Enable/disable flash overlay
@export var enable_flash: bool = true:
	set(value):
		enable_flash = value
		if flash_overlay:
			flash_overlay.visible = value

@export_group("Debug")
## Show debug prints for testing
@export var debug_mode: bool = false

# ============================================================================
# INTERNAL STATE
# ============================================================================

var detection_area: Area3D
var collision_shape: CollisionShape3D
var particle_system: GPUParticles3D
var flash_overlay: ColorRect
var canvas_layer: CanvasLayer

var player_in_area: bool = false
var time_in_area: float = 0.0
var teleport_progress: float = 0.0  # 0.0 to 1.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	# Create detection area
	_create_detection_area()

	# Create particle system
	_create_particle_system()

	# Create flash overlay
	_create_flash_overlay()

	# Validate configuration
	if target_scene.is_empty():
		push_warning("Planet Teleporter: target_scene is not set on node '%s'" % name)

# ============================================================================
# NODE CREATION
# ============================================================================

## Create the Area3D detection zone
func _create_detection_area():
	detection_area = Area3D.new()
	detection_area.name = "DetectionArea"
	add_child(detection_area)

	# Create sphere collision shape
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape"
	var sphere = SphereShape3D.new()
	sphere.radius = detection_radius
	collision_shape.shape = sphere
	detection_area.add_child(collision_shape)

	# Connect signals
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	if debug_mode:
		print("Planet Teleporter: Detection area created with radius %.1f" % detection_radius)

## Create the particle system for glow effect
func _create_particle_system():
	particle_system = GPUParticles3D.new()
	particle_system.name = "TeleportParticles"
	add_child(particle_system)

	# Particle settings
	particle_system.emitting = false
	particle_system.amount = 50
	particle_system.lifetime = 1.5
	particle_system.visibility_aabb = AABB(Vector3(-10, -10, -10), Vector3(20, 20, 20))
	particle_system.local_coords = false  # Emit in world space

	# Create process material
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = detection_radius * 0.8

	# Movement
	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 2.0
	material.gravity = Vector3.ZERO

	# Appearance
	material.color = particle_color
	material.scale_min = 0.1
	material.scale_max = 0.3

	# Fade out
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 1))
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	var curve = GradientTexture1D.new()
	curve.gradient = gradient
	material.alpha_curve = curve

	particle_system.process_material = material
	particle_system.visible = enable_particles

	if debug_mode:
		print("Planet Teleporter: Particle system created")

## Create the screen flash overlay
func _create_flash_overlay():
	# Create CanvasLayer to render on top
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "TeleportUI"
	canvas_layer.layer = 100  # High layer to ensure it's on top
	add_child(canvas_layer)

	# Create ColorRect for full-screen flash
	flash_overlay = ColorRect.new()
	flash_overlay.name = "FlashOverlay"
	flash_overlay.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)  # Start transparent
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input

	# Set to fill entire screen
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_overlay.offset_left = 0
	flash_overlay.offset_top = 0
	flash_overlay.offset_right = 0
	flash_overlay.offset_bottom = 0

	flash_overlay.visible = enable_flash
	canvas_layer.add_child(flash_overlay)

	if debug_mode:
		print("Planet Teleporter: Flash overlay created")

# ============================================================================
# UPDATE LOOP
# ============================================================================

func _process(delta: float):
	if not player_in_area:
		return

	# Increment timer
	time_in_area += delta
	teleport_progress = clamp(time_in_area / time_to_teleport, 0.0, 1.0)

	# Update VFX based on progress
	_update_particle_intensity()
	_update_flash_intensity()

	# Check if teleport should trigger
	if time_in_area >= time_to_teleport:
		_trigger_teleport()

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_body_entered(body: Node3D):
	# Check if it's the player (CharacterBody3D in surface scenes)
	if not body is CharacterBody3D:
		return

	player_in_area = true
	time_in_area = 0.0
	teleport_progress = 0.0

	# Start particle emission
	if enable_particles and particle_system:
		particle_system.emitting = true

	if debug_mode:
		print("Planet Teleporter: Player entered area")

func _on_body_exited(body: Node3D):
	# Check if it's the player
	if not body is CharacterBody3D:
		return

	player_in_area = false
	time_in_area = 0.0
	teleport_progress = 0.0

	# Stop particle emission
	if particle_system:
		particle_system.emitting = false

	# Reset flash overlay
	if flash_overlay:
		flash_overlay.color.a = 0.0

	if debug_mode:
		print("Planet Teleporter: Player exited area (timer reset)")

# ============================================================================
# VFX UPDATES
# ============================================================================

## Update particle emission based on teleport progress
func _update_particle_intensity():
	if not particle_system or not enable_particles:
		return

	# Scale emission amount based on progress (0% to 100%)
	var target_amount = int(particle_intensity * teleport_progress)
	particle_system.amount = max(10, target_amount)  # Minimum 10 particles

	# Increase particle velocity as we get closer
	if particle_system.process_material:
		var intensity_multiplier = 1.0 + (teleport_progress * 2.0)  # 1x to 3x
		particle_system.process_material.initial_velocity_max = 2.0 * intensity_multiplier

## Update flash overlay alpha based on teleport progress
func _update_flash_intensity():
	if not flash_overlay or not enable_flash:
		return

	# Fade in from 0% to 80% alpha (don't go fully opaque until teleport)
	var target_alpha = teleport_progress * 0.8
	flash_overlay.color.a = target_alpha

# ============================================================================
# TELEPORTATION
# ============================================================================

## Trigger the scene change
func _trigger_teleport():
	if target_scene.is_empty():
		push_error("Planet Teleporter: Cannot teleport - target_scene is not set")
		player_in_area = false  # Reset to prevent spam
		return

	if debug_mode:
		print("Planet Teleporter: Teleporting to %s" % target_scene)

	# Full white flash
	if flash_overlay and enable_flash:
		flash_overlay.color.a = 1.0

	# Change scene
	# Small delay to show full flash
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file(target_scene)

# ============================================================================
# PUBLIC METHODS
# ============================================================================

## Get current teleport progress (0.0 to 1.0)
func get_progress() -> float:
	return teleport_progress

## Check if player is currently in the teleport area
func is_player_in_area() -> bool:
	return player_in_area

## Get time remaining until teleport
func get_time_remaining() -> float:
	if not player_in_area:
		return time_to_teleport
	return max(0.0, time_to_teleport - time_in_area)

## Manually trigger teleport (bypass timer)
func force_teleport():
	if target_scene.is_empty():
		push_error("Planet Teleporter: Cannot force teleport - target_scene is not set")
		return
	_trigger_teleport()

## Reset the timer
func reset_timer():
	time_in_area = 0.0
	teleport_progress = 0.0
	if flash_overlay:
		flash_overlay.color.a = 0.0
