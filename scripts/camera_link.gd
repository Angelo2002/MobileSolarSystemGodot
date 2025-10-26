extends Camera3D
## Links this camera's rotation to a target camera without copying position
## This creates a rotation-only viewport that eliminates parallax for distant objects

## The camera to copy rotation from (typically your main gameplay camera)
@export var target_camera: Camera3D

func _process(_delta: float) -> void:
	if not target_camera:
		return


	rotation = target_camera.rotation
