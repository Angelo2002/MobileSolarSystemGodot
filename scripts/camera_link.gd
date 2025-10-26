extends Camera3D
## Links this camera's rotation to a target camera without copying position
## This creates a rotation-only viewport that eliminates parallax for distant objects

## The camera to copy rotation from (typically your main gameplay camera)
@export var target_camera: Camera3D

@export_group("Rotation Offset")
## Initial rotation offset in degrees (applied on top of target camera rotation)
## Use this to set where the background "starts" looking
@export var rotation_offset_x: float = 0.0
@export var rotation_offset_y: float = 0.0
@export var rotation_offset_z: float = 0.0

func _process(_delta: float) -> void:
	if not target_camera:
		return

	# Copy rotation from target camera
	var final_rotation = target_camera.global_rotation

	# Add the offset in radians
	final_rotation.x += deg_to_rad(rotation_offset_x)
	final_rotation.y += deg_to_rad(rotation_offset_y)
	final_rotation.z += deg_to_rad(rotation_offset_z)

	global_rotation = final_rotation
