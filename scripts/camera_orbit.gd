extends Camera3D

@export var target: Node3D
@export var rotation_speed: float = 1.0
@export var zoom_speed: float = 1.0
@export var min_distance: float = 2.0
@export var max_distance: float = 50.0
@export var mouse_sensitivity: float = 0.003
@export var touch_sensitivity: float = 0.003
@export var pinch_zoom_sensitivity: float = 0.05

var distance: float = 10.0
var rotation_x: float = 0.0
var rotation_y: float = 0.0
var is_rotating: bool = false

# Touch tracking
var touch_points: Dictionary = {}  # Stores active touch points
var last_touch_distance: float = 0.0  # For pinch zoom

func _ready():
	if target:
		distance = global_position.distance_to(target.global_position)
		look_at(target.global_position)

func _input(event):
	# Mouse button for rotation (right click)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
			if is_rotating:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		# Mouse wheel for zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - zoom_speed, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + zoom_speed, min_distance, max_distance)

	# Mouse motion for rotation
	elif event is InputEventMouseMotion and is_rotating:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, -PI/2, PI/2)

	# Touch input for mobile
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Touch started
			touch_points[event.index] = event.position
		else:
			# Touch ended
			touch_points.erase(event.index)

		# Reset pinch tracking when touch count changes
		if touch_points.size() != 2:
			last_touch_distance = 0.0

	elif event is InputEventScreenDrag:
		# Update touch position
		touch_points[event.index] = event.position

		if touch_points.size() == 1:
			# Single finger drag - rotate camera
			rotation_y -= event.relative.x * touch_sensitivity
			rotation_x -= event.relative.y * touch_sensitivity
			rotation_x = clamp(rotation_x, -PI/2, PI/2)

		elif touch_points.size() == 2:
			# Two finger pinch - zoom
			var touch_positions = touch_points.values()
			var current_distance = touch_positions[0].distance_to(touch_positions[1])

			if last_touch_distance > 0:
				var delta = current_distance - last_touch_distance
				distance = clamp(distance - delta * pinch_zoom_sensitivity, min_distance, max_distance)

			last_touch_distance = current_distance

func _process(delta):
	if not target:
		return

	# Keyboard rotation (arrow keys or WASD)
	var rotate_input = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		rotate_input.x -= 1
	if Input.is_action_pressed("ui_right"):
		rotate_input.x += 1
	if Input.is_action_pressed("ui_up"):
		rotate_input.y -= 1
	if Input.is_action_pressed("ui_down"):
		rotate_input.y += 1

	if rotate_input.length() > 0:
		rotation_y += rotate_input.x * rotation_speed * delta
		rotation_x += rotate_input.y * rotation_speed * delta
		rotation_x = clamp(rotation_x, -PI/2, PI/2)

	# Calculate camera position based on rotation and distance
	var offset = Vector3(
		cos(rotation_y) * cos(rotation_x),
		sin(rotation_x),
		sin(rotation_y) * cos(rotation_x)
	) * distance

	global_position = target.global_position + offset
	look_at(target.global_position)
