extends Node3D

## Planet self-rotation script
## Attach this to any planet to make it spin on its own axis

@export var rotation_speed: float = 10.0  ## Rotation speed in degrees per second
@export var rotation_axis: Vector3 = Vector3(0, 1, 0)  ## Axis of rotation (default: Y-axis/vertical)
@export var clockwise: bool = false  ## If true, rotates clockwise when viewed from above


func _process(delta: float) -> void:
	# Convert degrees to radians
	var angle_delta: float = deg_to_rad(rotation_speed) * delta

	if clockwise:
		angle_delta = -angle_delta

	rotate_object_local(rotation_axis.normalized(), angle_delta)
