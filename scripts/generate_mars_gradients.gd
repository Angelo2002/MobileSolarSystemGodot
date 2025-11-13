@tool
extends EditorScript

## Mars Gradient Texture Generator
## Run this script in Godot Editor via File -> Run to generate placeholder gradients
## This creates three gradient textures for the Mars sky shader

const OUTPUT_DIR = "res://textures/gradients/"
const GRADIENT_WIDTH = 256
const GRADIENT_HEIGHT = 4

func _run():
	print("=== Mars Gradient Generator ===")

	# Ensure output directory exists
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	# Generate the three gradients
	generate_sun_zenith_gradient()
	generate_view_zenith_gradient()
	generate_sun_view_gradient()

	print("=== Generation Complete ===")
	print("Gradients saved to: ", OUTPUT_DIR)
	print("Remember to import them in Godot (check the FileSystem panel)")

# ============================================================================
# GRADIENT GENERATORS
# ============================================================================

## Sun-Zenith Gradient: Sky color based on sun height
## Left (sun low/sunset) -> Right (sun high/noon)
## Colors: Deep rust/terracotta -> Dusty orange/tan
func generate_sun_zenith_gradient():
	var image = Image.create(GRADIENT_WIDTH, GRADIENT_HEIGHT, false, Image.FORMAT_RGB8)

	# Define Mars sky colors
	var horizon_color = Color(0.82, 0.52, 0.35)  # Rust/terracotta (sun low)
	var zenith_color = Color(0.85, 0.65, 0.45)   # Dusty orange/tan (sun high)

	# Fill gradient
	for x in range(GRADIENT_WIDTH):
		var t = float(x) / float(GRADIENT_WIDTH - 1)
		var color = horizon_color.lerp(zenith_color, t)

		# Fill vertical strip (make it a few pixels tall for easier viewing)
		for y in range(GRADIENT_HEIGHT):
			image.set_pixel(x, y, color)

	# Save
	var path = OUTPUT_DIR + "mars_sun_zenith_gradient.png"
	image.save_png(path)
	print("Generated: ", path)

## View-Zenith Gradient: Sky color based on viewing angle
## Left (looking down) -> Right (looking up)
## Colors: Darker pinkish -> Subtle pink rim
func generate_view_zenith_gradient():
	var image = Image.create(GRADIENT_WIDTH, GRADIENT_HEIGHT, false, Image.FORMAT_RGB8)

	# Define atmospheric rim colors
	var down_color = Color(0.3, 0.25, 0.22)      # Darker when looking down
	var up_color = Color(0.65, 0.45, 0.40)       # Pinkish rim when looking up

	# Fill gradient
	for x in range(GRADIENT_WIDTH):
		var t = float(x) / float(GRADIENT_WIDTH - 1)
		# Use power curve for stronger rim effect at horizon
		var t_curved = pow(t, 0.5)
		var color = down_color.lerp(up_color, t_curved)

		for y in range(GRADIENT_HEIGHT):
			image.set_pixel(x, y, color)

	# Save
	var path = OUTPUT_DIR + "mars_view_zenith_gradient.png"
	image.save_png(path)
	print("Generated: ", path)

## Sun-View Gradient: Atmospheric glow near sun
## Left (looking away from sun) -> Right (looking at sun)
## Colors: Transparent/minimal -> Orange atmospheric glow
func generate_sun_view_gradient():
	var image = Image.create(GRADIENT_WIDTH, GRADIENT_HEIGHT, false, Image.FORMAT_RGB8)

	# Define atmospheric glow
	var away_color = Color(0.1, 0.08, 0.06)      # Minimal contribution away from sun
	var toward_color = Color(0.95, 0.65, 0.35)   # Orange glow near sun

	# Fill gradient
	for x in range(GRADIENT_WIDTH):
		var t = float(x) / float(GRADIENT_WIDTH - 1)
		# Use strong power curve for concentrated glow near sun
		var t_curved = pow(t, 3.0)
		var color = away_color.lerp(toward_color, t_curved)

		for y in range(GRADIENT_HEIGHT):
			image.set_pixel(x, y, color)

	# Save
	var path = OUTPUT_DIR + "mars_sun_view_gradient.png"
	image.save_png(path)
	print("Generated: ", path)

# ============================================================================
# COLOR REFERENCE (for manual texture creation)
# ============================================================================

## Mars Atmosphere Color Palette:
##
## HORIZON (Sun low, looking at horizon):
## - Rust/Terracotta: RGB(210, 133, 89) or Color(0.82, 0.52, 0.35)
## - Peachy Pink: RGB(220, 150, 120) or Color(0.86, 0.59, 0.47)
##
## ZENITH (Sun high, looking up):
## - Dusty Orange/Tan: RGB(217, 166, 115) or Color(0.85, 0.65, 0.45)
## - Pale Butterscotch: RGB(230, 185, 140) or Color(0.90, 0.73, 0.55)
##
## ATMOSPHERIC GLOW (Near sun):
## - Warm Orange: RGB(242, 166, 89) or Color(0.95, 0.65, 0.35)
## - Peachy Glow: RGB(255, 200, 140) or Color(1.0, 0.78, 0.55)
##
## SHADOWS (Looking down/away):
## - Dark Rust: RGB(77, 64, 56) or Color(0.3, 0.25, 0.22)
## - Dusty Brown: RGB(102, 85, 70) or Color(0.4, 0.33, 0.27)
##
## Reference: Mars sky colors based on Viking, Spirit, Curiosity, and Perseverance rover images
