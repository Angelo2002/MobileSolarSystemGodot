extends Camera3D

@export var target_camera: Camera3D

func _process(_delta: float) -> void:
	if not target_camera or not is_inside_tree() or not target_camera.is_inside_tree():
		return
	
	rotation = target_camera.global_rotation
