extends Camera3D

@export var target_camera: Camera3D

func _process(_delta: float) -> void:
	if not target_camera:
		return


	global_rotation = target_camera.global_rotation
