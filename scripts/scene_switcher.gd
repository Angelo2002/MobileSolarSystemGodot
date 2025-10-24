extends Node3D

# Makes a 3D object clickable to switch to a different scene
# Attach this to any MeshInstance3D or other 3D node you want to be clickable

@export_file("*.tscn") var target_scene: String
@export var clickable_mesh: MeshInstance3D

func _ready():
	# If no mesh is specified, try to find one in children
	if not clickable_mesh:
		clickable_mesh = get_node_or_null(".")
		if clickable_mesh is MeshInstance3D:
			pass  # Good, we found it
		else:
			# Try to find first MeshInstance3D child
			for child in get_children():
				if child is MeshInstance3D:
					clickable_mesh = child
					break

	if not clickable_mesh:
		push_error("scene_switcher.gd: No MeshInstance3D found. Please assign clickable_mesh.")

func _input(event):
	
	if not clickable_mesh or not target_scene:
		return

	var camera = get_viewport().get_camera_3d()
	if not camera:
		return

	# Handle mouse click
	if event is InputEventMouseButton:
		
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_check_click(event.position, camera)

	# Handle touch
	elif event is InputEventScreenTouch:
		if event.pressed:
			_check_click(event.position, camera)

func _check_click(screen_pos: Vector2, camera: Camera3D):
	# Cast ray from camera through click position
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 1000.0

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		# Check if we hit the mesh directly, or if we hit a physics body that contains the mesh
		var hit_node = result.collider
		if hit_node == clickable_mesh or hit_node.is_ancestor_of(clickable_mesh) or (clickable_mesh.get_parent() == hit_node):
			_switch_scene()

func _switch_scene():
	if target_scene:
		get_tree().change_scene_to_file(target_scene)
	else:
		push_error("scene_switcher.gd: No target scene specified!")
