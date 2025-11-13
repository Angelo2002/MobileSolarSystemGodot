@tool
extends EditorScript

## Venus Gradient Texture Generator
## Run this script in Godot Editor via File -> Run to generate placeholder gradients
## This creates three gradient textures for the Venus sky shader

const OUTPUT_DIR = "res://textures/gradients/"
const GRADIENT_WIDTH = 256
const GRADIENT_HEIGHT = 4

func _run():
	print("=== Venus Gradient Generator ===")

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
## Left (sun low/night) -> Right (sun high/noon)
## Colors: Near-black -> Thick yellow-brown clouds
func generate_sun_zenith_gradient():
	var image = Image.create(GRADIENT_WIDTH, GRADIENT_HEIGHT, false, Image.FORMAT_RGB8)

	# Define Venus sky colors (sulfuric acid atmosphere)
	var night_color = Color(0.02, 0.015, 0.01)      # Near-black night (pitch dark)
	var day_color = Color(0.65, 0.55, 0.35)         # Yellowish-brown cloud deck

	# Fill gradient with sharp transition (thick atmosphere = abrupt day/night)
	for x in range(GRADIENT_WIDTH):
		var t = float(x) / float(GRADIENT_WIDTH - 1)
		# Use power curve for sharper transition
		var t_curved = pow(t, 0.4)  # Faster transition than Earth/Mars
		var color = night_color.lerp(day_color, t_curved)

		# Fill vertical strip
		for y in range(GRADIENT_HEIGHT):
			image.set_pixel(x, y, color)

	# Save
	var path = OUTPUT_DIR + "venus_sun_zenith_gradient.png"
	image.save_png(path)
	print("Generated: ", path)

## View-Zenith Gradient: Sky color based on viewing angle
## Left (looking down) -> Right (looking up)
## Colors: Minimal variation (uniform thick cloud deck)
func generate_view_zenith_gradient():
	var image = Image.create(GRADIENT_WIDTH, GRADIENT_HEIGHT, false, Image.FORMAT_RGB8)

	# Venus has very uniform cloud deck - minimal variation by view angle
	var down_color = Color(0.55, 0.50, 0.30)        # Slightly darker brownish
	var up_color = Color(0.60, 0.52, 0.33)          # Slightly lighter yellow-brown

	# Fill gradient (very subtle variation)
	for x in range(GRADIENT_WIDTH):
		var t = float(x) / float(GRADIENT_WIDTH - 1)
		var color = down_color.lerp(up_color, t)

		for y in range(GRADIENT_HEIGHT):
			image.set_pixel(x, y, color)

	# Save
	var path = OUTPUT_DIR + "venus_view_zenith_gradient.png"
	image.save_png(path)
	print("Generated: ", path)

## Sun-View Gradient: Atmospheric glow near sun
## Left (looking away from sun) -> Right (looking at sun)
## Colors: Minimal glow (sun heavily diffused by thick clouds)
func generate_sun_view_gradient():
	var image = Image.create(GRADIENT_WIDTH, GRADIENT_HEIGHT, false, Image.FORMAT_RGB8)

	# Sun is heavily diffused through sulfuric acid clouds - barely visible
	var away_color = Color(0.05, 0.04, 0.02)        # Minimal contribution away from sun
	var toward_color = Color(0.70, 0.60, 0.40)      # Muted yellow glow (heavily diffused)

	# Fill gradient
	for x in range(GRADIENT_WIDTH):
		var t = float(x) / float(GRADIENT_WIDTH - 1)
		# Use extreme power curve for very concentrated, weak glow
		var t_curved = pow(t, 8.0)  # Much more concentrated than Mars/Earth
		var color = away_color.lerp(toward_color, t_curved)

		for y in range(GRADIENT_HEIGHT):
			image.set_pixel(x, y, color)

	# Save
	var path = OUTPUT_DIR + "venus_sun_view_gradient.png"
	image.save_png(path)
	print("Generated: ", path)

# ============================================================================
# COLOR REFERENCE (for manual texture creation)
# ============================================================================

## Venus Atmosphere Color Palette:
##
## CLOUD DECK (Day):
## - Yellowish-Brown: RGB(166, 140, 89) or Color(0.65, 0.55, 0.35)
## - Greenish-Yellow: RGB(153, 140, 102) or Color(0.60, 0.55, 0.40)
## - Pale Sulfur: RGB(178, 165, 115) or Color(0.70, 0.65, 0.45)
##
## NIGHT SKY (Almost pitch black):
## - Near-Black: RGB(5, 4, 3) or Color(0.02, 0.015, 0.01)
## - Dark Brown: RGB(13, 10, 6) or Color(0.05, 0.04, 0.02)
##
## SUN GLOW (Heavily diffused):
## - Muted Yellow: RGB(178, 153, 102) or Color(0.70, 0.60, 0.40)
## - Dim Gold: RGB(191, 166, 115) or Color(0.75, 0.65, 0.45)
##
## CLOUD SHADOWS:
## - Dark Sulfur: RGB(140, 128, 77) or Color(0.55, 0.50, 0.30)
## - Brown-Green: RGB(128, 115, 77) or Color(0.50, 0.45, 0.30)
##
## SCIENTIFIC BASIS:
## - Venus atmosphere is 96.5% CO₂ with sulfuric acid clouds (H₂SO₄)
## - Cloud deck at 45-70km altitude, ~20km thick
## - Yellow color from sulfur compounds absorbing blue/violet light
## - Greenish tint from trace sulfur compounds and UV absorption
## - Atmospheric pressure at surface: 92 bars (92x Earth's)
## - Light transmission to surface: <1% (very dark at surface)
##
## Reference: Venera, Mariner 10, Pioneer Venus, Venus Express, Akatsuki missions
