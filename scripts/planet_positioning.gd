extends "res://scripts/planet_rotation.gd"
## Planet positioning script that allows setting distance and apparent size
## Attach this to a planet node to position it at a specific distance with a specific apparent size
## Inherits rotation functionality from planet_rotation.gd

## Distance from the observer (0,0,0) in your chosen units (e.g., kilometers or scene units)
@export var distance_from_surface: float = 186000.0:
	set(value):
		distance_from_surface = value
		_update_planet_transform()

## Apparent angular size in degrees (how big the planet appears from the observer's position)
@export var apparent_size_degrees: float = 17.5:
	set(value):
		apparent_size_degrees = value
		_update_planet_transform()

## The actual radius of the planet in the same units as distance
## This is calculated automatically based on distance and apparent size
@export var actual_radius: float = 58232.0:
	set(value):
		actual_radius = value
		_update_from_actual_size()

## Direction vector from origin (normalized). Default is along negative Z axis (away from camera at origin)
@export var direction: Vector3 = Vector3(0, 0, -1):
	set(value):
		direction = value.normalized()
		_update_planet_transform()

## Use actual radius instead of apparent size for calculations
@export var use_actual_radius: bool = false:
	set(value):
		use_actual_radius = value
		_update_planet_transform()

## Scale factor to convert between your scene units and the units used for distance/size
## For example, if distance is in km but your scene uses 1 unit = 1000 km, set this to 0.001
@export var scale_factor: float = 1.0:
	set(value):
		scale_factor = value
		_update_planet_transform()

## Reference size of the planet mesh (the diameter of the mesh at scale 1,1,1)
## Default assumes a sphere mesh with diameter of 2 units
@export var mesh_diameter: float = 2.0:
	set(value):
		mesh_diameter = value
		_update_planet_transform()

var _updating: bool = false


func _ready() -> void:
	_update_planet_transform()


func _update_planet_transform() -> void:
	"""Update the planet's position and scale based on current parameters"""
	if _updating:
		return
	_updating = true
	
	# Position the planet at the specified distance along the direction vector
	var scaled_distance = distance_from_surface * scale_factor
	position = direction * scaled_distance
	
	# Calculate the required actual diameter to achieve the apparent size at this distance
	if not use_actual_radius:
		# Convert apparent size from degrees to radians
		var apparent_size_rad = deg_to_rad(apparent_size_degrees)
		
		# Calculate actual diameter needed: diameter = 2 * distance * tan(angular_diameter / 2)
		var required_diameter = 2.0 * distance_from_surface * tan(apparent_size_rad / 2.0)
		actual_radius = required_diameter / 2.0
	
	# Scale the mesh to match the required diameter
	var required_scale = (actual_radius * 2.0 * scale_factor) / mesh_diameter
	scale = Vector3(required_scale, required_scale, required_scale)
	
	_updating = false


func _update_from_actual_size() -> void:
	"""Update apparent size based on actual radius and distance"""
	if _updating:
		return
	_updating = true
	
	if use_actual_radius:
		# Calculate apparent size from actual radius and distance
		var angular_diameter_rad = 2.0 * atan(actual_radius / distance_from_surface)
		apparent_size_degrees = rad_to_deg(angular_diameter_rad)
		_update_planet_transform()
	
	_updating = false


## Calculate and return the apparent size in degrees for a given actual radius and distance
func calculate_apparent_size(radius: float, dist: float) -> float:
	var angular_diameter_rad = 2.0 * atan(radius / dist)
	return rad_to_deg(angular_diameter_rad)


## Calculate and return the required actual radius for a given apparent size and distance
func calculate_required_radius(apparent_deg: float, dist: float) -> float:
	var apparent_rad = deg_to_rad(apparent_deg)
	var diameter = 2.0 * dist * tan(apparent_rad / 2.0)
	return diameter / 2.0


## Get current angular size in various units
func get_apparent_size_info() -> Dictionary:
	var rad = deg_to_rad(apparent_size_degrees)
	return {
		"degrees": apparent_size_degrees,
		"radians": rad,
		"arcminutes": apparent_size_degrees * 60.0,
		"arcseconds": apparent_size_degrees * 3600.0
	}


## Print debug information about the current configuration
func print_info() -> void:
	var info = get_apparent_size_info()
	print("=== Planet Configuration ===")
	print("Distance from surface: ", distance_from_surface)
	print("Actual radius: ", actual_radius)
	print("Actual diameter: ", actual_radius * 2.0)
	print("Apparent size: ", info.degrees, "° (", info.arcminutes, "', ", info.arcseconds, "\")")
	print("Position: ", position)
	print("Scale: ", scale)
	print("==========================")
