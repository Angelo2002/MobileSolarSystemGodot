extends Node3D

## Billboard Label with Background
## Auto-creates a camera-facing Label3D with optional background quad
## Perfect for labeling planets, moons, and other 3D objects
##
## Usage:
##   1. Add an empty Node3D to your scene
##   2. Attach this script to it
##   3. Configure label text, colors, and offset in the inspector
##   4. The script will auto-create Label3D and background mesh children
##
## Example:
##   var label = Node3D.new()
##   label.set_script(preload("res://scripts/billboard_label.gd"))
##   planet_node.add_child(label)
##   label.label_text = "Earth"
##   label.label_offset = Vector3(0, 2, 0)

# ============================================================================
# EXPORTED PARAMETERS
# ============================================================================

@export_group("References")
## Camera to face (auto-detected from viewport if not set)
@export var camera: Camera3D

@export_group("Label Content")
## Text to display on the label
@export var label_text: String = "Label":
	set(value):
		label_text = value
		if label_3d:
			label_3d.text = value
			_schedule_background_update()

@export_group("Label Appearance")
## Font size in pixels
@export var font_size: int = 32:
	set(value):
		font_size = value
		if label_3d:
			label_3d.font_size = value
			_schedule_background_update()

## Size of one pixel's width in 3D units (smaller = smaller text in world space)
@export_range(0.0001, 0.01, 0.0001) var pixel_size: float = 0.001:
	set(value):
		pixel_size = value
		if label_3d:
			label_3d.pixel_size = value
			_schedule_background_update()

## Text color (foreground)
@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		if label_3d:
			label_3d.modulate = value

## Optional custom font (leave empty for default)
@export var custom_font: Font:
	set(value):
		custom_font = value
		if label_3d:
			label_3d.font = value
			_schedule_background_update()

@export_group("Background")
## Background color (alpha 0 = transparent/no background)
@export var background_color: Color = Color(0, 0, 0, 0.7):
	set(value):
		background_color = value
		if background_mesh and background_mesh.material_override:
			background_mesh.material_override.albedo_color = value
			background_mesh.visible = value.a > 0.0

## Padding around text in pixels (x = horizontal, y = vertical)
@export var padding: Vector2 = Vector2(10, 5):
	set(value):
		padding = value
		_schedule_background_update()

@export_group("Positioning")
## Position offset from parent node
@export var label_offset: Vector3 = Vector3(0, 0, 0):
	set(value):
		label_offset = value
		position = value

@export_group("Billboard Settings")
## Billboard mode - how the label faces the camera
@export_enum("Disabled:0", "Full:1", "Fixed Y:2") var billboard_mode: int = 2:
	set(value):
		billboard_mode = value
		if label_3d:
			label_3d.billboard = value
		if background_mesh and background_mesh.material_override:
			background_mesh.material_override.billboard_mode = value

## Whether text should be visible from behind
@export var double_sided: bool = false:
	set(value):
		double_sided = value
		if label_3d:
			label_3d.double_sided = value

## Text renders same size regardless of distance to camera
@export var fixed_size: bool = false:
	set(value):
		fixed_size = value
		if label_3d:
			label_3d.fixed_size = value

# ============================================================================
# INTERNAL STATE
# ============================================================================

var label_3d: Label3D
var background_mesh: MeshInstance3D
var _background_update_scheduled: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	# Set initial position from offset
	position = label_offset

	# Auto-detect camera if not set
	if not camera:
		camera = get_viewport().get_camera_3d()

	# Create the Label3D node
	_create_label()

	# Create the background mesh
	_create_background()

	# Initial background size update (delayed one frame for AABB to be ready)
	await get_tree().process_frame
	_update_background_size()

# ============================================================================
# NODE CREATION
# ============================================================================

## Creates the Label3D child node
func _create_label():
	label_3d = Label3D.new()
	label_3d.name = "Label3D"
	add_child(label_3d)

	# Apply settings
	label_3d.text = label_text
	label_3d.font_size = font_size
	label_3d.pixel_size = pixel_size
	label_3d.modulate = text_color
	label_3d.billboard = billboard_mode
	label_3d.double_sided = double_sided
	label_3d.fixed_size = fixed_size

	# Optional custom font
	if custom_font:
		label_3d.font = custom_font

	# Rendering settings
	label_3d.shaded = false  # Don't respond to lighting (UI element)
	label_3d.alpha_cut = BaseMaterial3D.ALPHA_CUT_DISABLED  # Smooth alpha
	label_3d.render_priority = 0  # Default render order

## Creates the background mesh child node
func _create_background():
	background_mesh = MeshInstance3D.new()
	background_mesh.name = "BackgroundMesh"
	add_child(background_mesh)

	# Move background in hierarchy to render first (before label)
	move_child(background_mesh, 0)

	# Create QuadMesh
	var quad = QuadMesh.new()
	quad.size = Vector2(1, 1)  # Will be scaled to fit text
	background_mesh.mesh = quad

	# Create material with background color
	var mat = StandardMaterial3D.new()
	mat.albedo_color = background_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = billboard_mode  # Match label billboard mode
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # Don't respond to lights
	mat.depth_draw_mode = StandardMaterial3D.DEPTH_DRAW_ALWAYS  # Ensure proper depth testing

	background_mesh.material_override = mat
	background_mesh.render_priority = -1  # Render before label

	# Position slightly behind text to prevent z-fighting
	background_mesh.position.z = 0.001

	# Hide background if fully transparent
	background_mesh.visible = background_color.a > 0.0

# ============================================================================
# BACKGROUND SIZING
# ============================================================================

## Schedule a background size update on the next frame
## This is necessary because AABB doesn't update immediately after text changes
func _schedule_background_update():
	if not _background_update_scheduled:
		_background_update_scheduled = true
		# Wait one frame for AABB to update
		await get_tree().process_frame
		_update_background_size()
		_background_update_scheduled = false

## Update background mesh size to match text dimensions + padding
func _update_background_size():
	if not label_3d or not background_mesh:
		return

	if background_color.a <= 0.0:
		# Background is fully transparent - no need to update size
		background_mesh.visible = false
		return

	background_mesh.visible = true

	# Get text dimensions in 3D space
	var aabb = label_3d.get_aabb()

	if aabb.size == Vector3.ZERO:
		# No text or AABB not ready yet
		return

	# Convert pixel padding to 3D units
	var padding_3d = padding * pixel_size

	# Calculate background size (text size + padding on all sides)
	var width = aabb.size.x + (padding_3d.x * 2)
	var height = aabb.size.y + (padding_3d.y * 2)

	# Scale the background quad to fit
	background_mesh.scale = Vector3(width, height, 1.0)

	# Center the background on the text
	# AABB position is relative to label's origin, so we offset to center
	background_mesh.position.x = aabb.get_center().x
	background_mesh.position.y = aabb.get_center().y
	# Keep Z slightly behind text
	background_mesh.position.z = 0.001

# ============================================================================
# PUBLIC METHODS
# ============================================================================

## Set the label text (convenience method)
func set_text(new_text: String):
	label_text = new_text

## Set the text color (convenience method)
func set_color(new_color: Color):
	text_color = new_color

## Set the background color (convenience method)
func set_background(new_bg_color: Color):
	background_color = new_bg_color

## Set the position offset (convenience method)
func set_offset(new_offset: Vector3):
	label_offset = new_offset

## Get the Label3D node for direct manipulation
func get_label_node() -> Label3D:
	return label_3d

## Get the background mesh node for direct manipulation
func get_background_node() -> MeshInstance3D:
	return background_mesh

## Enable or disable the background
func set_background_visible(visible: bool):
	if background_mesh:
		if visible:
			# Restore background color alpha if it was set to 0
			if background_color.a <= 0.0:
				background_color.a = 0.7  # Default semi-transparent
		else:
			background_color.a = 0.0  # Fully transparent

## Update background immediately (useful if you need sync update)
func update_background_now():
	_update_background_size()
