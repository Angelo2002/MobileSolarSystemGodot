@tool
extends CharacterBody3D

# First-person camera controller with mobile touch controls
# Left side of screen: movement (virtual joystick)
# Right side of screen: camera look (drag to rotate)

@export_group("Movement")
@export var move_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var gravity: float = 9.8

@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var touch_look_sensitivity: float = 0.003

@export_group("Boundary")
@export var enable_boundary: bool = true
@export var movement_radius: float = 50.0:
	set(value):
		movement_radius = value
		_update_boundary_visual()
@export var boundary_center: Vector3 = Vector3.ZERO:
	set(value):
		boundary_center = value
		_update_boundary_visual()
@export var show_boundary_in_game: bool = false

@onready var camera: Camera3D = $Camera3D

var boundary_visual: MeshInstance3D

var rotation_x: float = 0.0
var rotation_y: float = 0.0

# Touch tracking
var movement_touch_index: int = -1
var movement_touch_start: Vector2 = Vector2.ZERO
var look_touch_index: int = -1
var look_touch_last: Vector2 = Vector2.ZERO

@export_group("Touch Controls")
@export var joystick_deadzone: float = 10.0
@export var joystick_radius: float = 100.0

func _ready():
	# Ensure camera exists
	if not camera:
		camera = Camera3D.new()
		add_child(camera)
		camera.name = "Camera3D"

	# Create boundary visualization
	_create_boundary_visual()

func _create_boundary_visual():
	# Remove existing visual if it exists
	if boundary_visual:
		boundary_visual.queue_free()

	# Get the scene root to add the visual as an independent object
	var root = get_tree().get_edited_scene_root() if Engine.is_editor_hint() else get_tree().root
	if not root:
		return

	# Create a semi-transparent sphere to show the movement boundary
	boundary_visual = MeshInstance3D.new()
	boundary_visual.name = "BoundaryVisual_" + name

	# Add to scene root so it stays in place
	root.add_child(boundary_visual)
	boundary_visual.owner = root if Engine.is_editor_hint() else null

	# Set as top-level so it ignores parent transforms
	boundary_visual.top_level = true

	# Create sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = movement_radius
	sphere_mesh.height = movement_radius * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	boundary_visual.mesh = sphere_mesh

	# Create semi-transparent material
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.3, 0.6, 1.0, 0.15)  # Light blue, very transparent
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show from inside and outside
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # No lighting
	boundary_visual.material_override = material

	# Position at boundary center
	boundary_visual.global_position = boundary_center

	# Hide in game unless specified
	if not Engine.is_editor_hint():
		boundary_visual.visible = show_boundary_in_game

func _update_boundary_visual():
	if not boundary_visual or not is_instance_valid(boundary_visual):
		if Engine.is_editor_hint():
			_create_boundary_visual()
		return

	# Update sphere size
	if boundary_visual.mesh is SphereMesh:
		boundary_visual.mesh.radius = movement_radius
		boundary_visual.mesh.height = movement_radius * 2.0

	# Update position
	boundary_visual.global_position = boundary_center

# Update visualization in editor when properties change
func _process(_delta):
	if Engine.is_editor_hint():
		if boundary_visual and is_instance_valid(boundary_visual):
			boundary_visual.global_position = boundary_center

# Clean up the boundary visual when node is removed
func _exit_tree():
	if boundary_visual and is_instance_valid(boundary_visual):
		boundary_visual.queue_free()

func _input(event):
	# Handle mouse input for desktop testing
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_rotate_camera(event.relative * mouse_sensitivity)

	# Handle touch input for mobile
	if event is InputEventScreenTouch:
		var screen_size = get_viewport().get_visible_rect().size
		var half_width = screen_size.x / 2.0

		if event.pressed:
			# Touch started
			if event.position.x < half_width:
				# Left side - movement
				if movement_touch_index == -1:
					movement_touch_index = event.index
					movement_touch_start = event.position
			else:
				# Right side - camera look
				if look_touch_index == -1:
					look_touch_index = event.index
					look_touch_last = event.position
		else:
			# Touch ended
			if event.index == movement_touch_index:
				movement_touch_index = -1
			elif event.index == look_touch_index:
				look_touch_index = -1

	elif event is InputEventScreenDrag:
		if event.index == look_touch_index:
			# Camera rotation
			var delta = event.position - look_touch_last
			_rotate_camera(delta * touch_look_sensitivity)
			look_touch_last = event.position

func _rotate_camera(delta: Vector2):
	rotation_y -= delta.x
	rotation_x -= delta.y
	rotation_x = clamp(rotation_x, -PI/2, PI/2)

	rotation.y = rotation_y
	camera.rotation.x = rotation_x

func _physics_process(delta):
	# Get movement input
	var input_dir = _get_movement_input()

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Calculate movement direction relative to camera rotation
	var direction = Vector3.ZERO
	if input_dir.length() > 0:
		# Transform input relative to camera's Y rotation
		var forward = -transform.basis.z
		var right = transform.basis.x

		# Project onto XZ plane (horizontal movement only)
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()

		direction = (forward * input_dir.y + right * input_dir.x).normalized()

	# Apply movement
	var target_velocity = direction * move_speed
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z

	move_and_slide()

	# Clamp position within boundary sphere (horizontal only - XZ plane)
	if enable_boundary and not Engine.is_editor_hint():
		# Calculate horizontal distance only (ignore Y axis)
		var player_pos_xz = Vector2(global_position.x, global_position.z)
		var center_pos_xz = Vector2(boundary_center.x, boundary_center.z)
		var distance_from_center = player_pos_xz.distance_to(center_pos_xz)

		if distance_from_center > movement_radius:
			# Push player back to the boundary edge (only X and Z, keep Y unchanged)
			var direction_to_center = (center_pos_xz - player_pos_xz).normalized()
			var clamped_pos_xz = center_pos_xz - direction_to_center * movement_radius
			global_position.x = clamped_pos_xz.x
			global_position.z = clamped_pos_xz.y  # Vector2.y maps to Vector3.z

func _get_movement_input() -> Vector2:
	var input = Vector2.ZERO

	# Touch input (virtual joystick)
	if movement_touch_index != -1:
		var current_touch_pos = get_viewport().get_mouse_position()
		var delta = current_touch_pos - movement_touch_start

		# Apply deadzone
		if delta.length() > joystick_deadzone:
			# Clamp to joystick radius
			var clamped_delta = delta.limit_length(joystick_radius)
			# Normalize to -1 to 1 range
			input = clamped_delta / joystick_radius
			# Invert Y so dragging up (negative screen Y) moves forward (positive game Y)
			input.y = -input.y

	# Keyboard input (for desktop testing)
	else:
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			input.y += 1
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			input.y -= 1
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			input.x -= 1
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			input.x += 1

		if input.length() > 0:
			input = input.normalized()

	return input
