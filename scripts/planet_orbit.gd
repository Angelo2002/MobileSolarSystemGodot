extends "res://scripts/planet_rotation.gd"

## Orbital motion script for celestial bodies
## Attach this to any planet/moon to make it orbit around a target object
## Position the object in the editor - the script will maintain that orbital radius
## Inherits rotation functionality from planet_rotation.gd

@export var orbit_target: Node3D  ## The object to orbit around (e.g., Sun)
@export var orbital_speed: float = 1.0  ## Speed of orbit in radians per second
@export var orbit_clockwise: bool = false  ## If true, orbits clockwise; if false, counter-clockwise

var orbit_radius: float = 0.0  ## Calculated from initial position
var current_angle: float = 0.0  ## Current orbital angle in radians
var orbit_center: Vector3 = Vector3.ZERO  ## Center point of orbit


func _ready() -> void:
	if orbit_target == null:
		push_warning("planet_orbit.gd: No orbit_target set for " + name)
		return

	# Calculate initial orbital parameters based on editor position
	orbit_center = orbit_target.global_position
	var offset: Vector3 = global_position - orbit_center
	orbit_radius = offset.length()

	# Calculate starting angle in the XZ plane (assuming Y is up)
	current_angle = atan2(offset.z, offset.x)

	if orbit_radius < 0.01:
		push_warning("planet_orbit.gd: " + name + " is too close to orbit center")


func _process(delta: float) -> void:
	# Call parent's rotation logic first
	super._process(delta)

	if orbit_target == null or orbit_radius < 0.01:
		return

	# Update orbit center in case target moves
	orbit_center = orbit_target.global_position

	# Update orbital angle based on speed and direction
	var angle_delta: float = orbital_speed * delta
	if orbit_clockwise:
		current_angle -= angle_delta
	else:
		current_angle += angle_delta

	# Calculate new position in circular orbit (XZ plane)
	var new_x: float = orbit_center.x + orbit_radius * cos(current_angle)
	var new_z: float = orbit_center.z + orbit_radius * sin(current_angle)

	# Maintain Y position (height) from initial setup
	global_position = Vector3(new_x, global_position.y, new_z)
