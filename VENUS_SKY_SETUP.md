# Venus Sky Shader Setup Guide

This guide walks you through creating a Venus surface view scene with the atmospheric sky shader in Godot 4.5.

## Overview

The Venus sky shader creates a thick, oppressive sulfuric acid atmosphere with:
- ✓ Thick yellow/greenish cloud deck
- ✓ Heavily diffused sun (barely visible glow)
- ✓ No stars visible (blocked by dense atmosphere)
- ✓ No moon visibility (Venus has no moon + clouds would block it anyway)
- ✓ Almost pitch black at night
- ✓ Abrupt day/night transition
- ✓ Reserved parameters for future lightning effects

## Scientific Background

Venus atmosphere:
- 96.5% CO₂ with thick sulfuric acid (H₂SO₄) cloud deck
- Cloud layer at 45-70km altitude, ~20km thick
- Surface pressure: 92 bars (92x Earth's atmospheric pressure)
- Light transmission to surface: <1% (very dark at surface)
- Yellow/green color from sulfur compounds absorbing blue light
- Extremely abrupt sunset/sunrise due to thick clouds

## Step 1: Generate Venus Gradient Textures

1. **Open Godot Editor** with your solar system project
2. **Navigate to** `scripts/generate_venus_gradients.gd` in the FileSystem panel
3. **Run the script**: Go to **File → Run** (or press Ctrl+Shift+X)
4. **Check the output**: Look in the Output panel at the bottom - you should see:
   ```
   === Venus Gradient Generator ===
   Generated: res://textures/gradients/venus_sun_zenith_gradient.png
   Generated: res://textures/gradients/venus_view_zenith_gradient.png
   Generated: res://textures/gradients/venus_sun_view_gradient.png
   === Generation Complete ===
   ```
5. **Verify textures**: In the FileSystem panel, navigate to `textures/gradients/` - you should see three new PNG files
6. **Import settings**: Click on each gradient texture and in the Import tab (next to Scene/Import):
   - Set **Compress → Mode** to `VRAM Uncompressed` (better quality for gradients)
   - Uncheck **Mipmaps → Generate** (not needed for gradients)
   - Click **Reimport**

## Step 2: Create the Venus View Scene

### 2.1: Create Base Scene Structure

1. **Create new scene**: Scene → New Scene
2. **Add root node**: Click "Other Node" and search for `Node3D`, name it `VenusView`
3. **Save scene**: Ctrl+S, save as `scenes/views/view_venus_surface.tscn`

### 2.2: Add WorldEnvironment with Sky

1. **Add WorldEnvironment**: Right-click `VenusView` → Add Child Node → search for `WorldEnvironment`
2. **Create Environment**:
   - Select the `WorldEnvironment` node
   - In the Inspector, find the **Environment** property
   - Click `[empty]` → New Environment
3. **Create Sky**:
   - Click on the newly created Environment to expand its properties
   - Find **Sky** section
   - Click `[empty]` next to **Sky** → New Sky
4. **Create Sky Material**:
   - Click the newly created Sky resource to expand it
   - Find **Sky Material** property
   - Click `[empty]` → New ShaderMaterial
5. **Assign Venus Sky Shader**:
   - Click the ShaderMaterial to expand it
   - Find **Shader** property
   - Click `[empty]` → Load
   - Navigate to `shaders/venus_sky.gdshader` and select it

### 2.3: Configure Sky Shader Parameters

With the ShaderMaterial still selected, scroll down to see **Shader Parameters**:

#### Sky Gradients:
- **Sun Zenith Gradient**: Click `[empty]` → Load → `textures/gradients/venus_sun_zenith_gradient.png`
- **View Zenith Gradient**: Click `[empty]` → Load → `textures/gradients/venus_view_zenith_gradient.png`
- **Sun View Gradient**: Click `[empty]` → Load → `textures/gradients/venus_sun_view_gradient.png`

#### Sun Parameters:
- **Sun Diffusion**: `0.85` (sun is heavily scattered by clouds)
- **Sun Color**: Muted yellow `(R:0.70, G:0.60, B:0.40)`
- **Sun Glow Power**: `8.0` (how concentrated the sun glow is)
- **Sun Intensity**: `0.3` (sun is very dim due to cloud absorption)

#### Venus Atmosphere:
- **Cloud Opacity**: `0.95` (very opaque sulfuric acid clouds)
- **Cloud Color Day**: Yellowish-brown `(R:0.65, G:0.55, B:0.35)`
- **Cloud Color Night**: Near-black `(R:0.02, G:0.015, B:0.01)`
- **Day Night Transition Sharpness**: `0.8` (abrupt transition, 0=gradual, 1=instant)
- **Cloud Detail Strength**: `0.0` (reserved for future cloud texture)

#### Lightning (Reserved for Future):
- **Lightning Intensity**: `0.0` (no lightning yet)
- **Lightning Color**: Light blue `(R:0.8, G:0.9, B:1.0)`
- **Lightning Position**: `(0.5, 0.5)` (normalized screen coordinates)
- **Lightning Falloff**: `5.0` (how spread out lightning flash is)

### 2.4: Attach Sky Controller Script

1. **Select WorldEnvironment** node
2. **Attach script**: In Inspector, find **Script** property at top
3. **Load existing script**: Click `[empty]` → Load → `scripts/venus_sky_controller.gd`
4. **Configure script properties**:
   - Expand **Scene References** section
   - **Sun Node**: We'll set this after adding the Sun (next step)
   - **Update Sun Direction**: ✓ Checked
   - Expand **Atmospheric Settings** section
   - **Cloud Opacity**: `0.95`
   - **Sun Diffusion**: `0.85`
   - **Day Night Sharpness**: `0.8`

## Step 3: Add Sun Reference

Venus's thick atmosphere blocks all other celestial objects, so we only need the sun:

1. **Add Node3D**: Right-click `VenusView` → Add Child Node → `Node3D`, name it `Sun`
2. **Position the Sun**:
   - Select the `Sun` node
   - In Inspector, set **Transform → Position**: `(150, 60, 0)` (or wherever you want the sun glow to come from)
3. **Link to controller**:
   - Select the `WorldEnvironment` node
   - In Inspector, find **Scene References → Sun Node**
   - Drag the `Sun` node from Scene tree into this property field

## Step 4: Add Camera

1. **Add Camera3D**: Right-click `VenusView` → Add Child Node → `Camera3D`
2. **Position camera**: In Inspector, set:
   - **Transform → Position**: `(0, 2, 0)` (2 units above Venus surface)
   - **Transform → Rotation**: `(-5, 0, 0)` (looking slightly up at the sky)
3. **Configure camera**:
   - **Fov**: `75` (or your preference)
   - **Near**: `0.1`
   - **Far**: `500` (visibility is limited on Venus due to thick atmosphere)

## Step 5: Add Venus Ground (Optional Visual Reference)

To help visualize the scene:

1. **Add MeshInstance3D**: Right-click `VenusView` → Add Child Node → `MeshInstance3D`, name it `Ground`
2. **Create plane mesh**:
   - In Inspector, find **Mesh** property
   - Click `[empty]` → New PlaneMesh
   - Click the PlaneMesh to expand it
   - Set **Size**: `(500, 500)` (Venus visibility is limited - smaller ground plane)
3. **Create material** (volcanic rock surface):
   - In Inspector, find **Material Override** under Geometry
   - Click `[empty]` → New StandardMaterial3D
   - Click the material to expand it
   - Set **Albedo → Color**: Dark volcanic gray `(R:0.3, G:0.27, B:0.25)`
   - Set **Roughness**: `0.9` (very rough terrain)
   - Set **Metallic**: `0.0` (rock, not metal)

## Step 6: Configure Environment Settings

Select the `WorldEnvironment` node, then in Inspector expand the Environment resource:

### Background:
- **Mode**: Sky (should already be set)

### Ambient Light:
Venus surface is VERY dark due to thick clouds blocking most sunlight:
- **Source**: Color (use custom color, not sky)
- **Color**: Dark yellow-brown `(R:0.15, G:0.13, B:0.10)`
- **Energy**: `0.2` (very low - Venus surface receives <1% of sunlight)

### Fog (Optional - Creates Atmospheric Haze):
Venus has extremely thick atmosphere with limited visibility:
- **Enabled**: ✓ Checked
- **Light Color**: Yellowish `(R:0.6, G:0.5, B:0.3)`
- **Light Energy**: `0.3`
- **Density**: `0.01` (thick haze)
- **Sky Affect**: `0.0` (fog shouldn't affect sky)

### Tonemap (Important for Venus):
- **Mode**: Filmic or ACES
- **Exposure**: `0.8` (darker than Earth due to low light)
- **White**: `8.0`

### Glow (Optional - for sun glow effect):
- **Enabled**: ✓ Checked (makes the barely-visible sun glow more visible)
- **Blend Mode**: Additive
- **Intensity**: `1.0` (higher than Earth to compensate for dim sun)
- **Bloom**: `0.5`

## Step 7: Test the Scene

1. **Make camera current**: Select Camera3D node, click **Preview** button at top of 3D viewport (or Ctrl+P in scene)
2. **Run scene**: Press F6 to run current scene
3. **Verify**:
   - You should see a thick yellowish-brown sky (like looking through dirty mustard)
   - Horizon should be fairly uniform (no dramatic color changes like Earth)
   - Sun should be barely visible as a very soft glow (not a sharp disc)
   - No stars should be visible
   - Ground should be dark gray volcanic rock
   - Overall scene should feel oppressive and dim

## Step 8: Testing Day/Night Transition

Venus has very abrupt day/night transitions due to thick atmosphere:

1. **Select Sun node**
2. **Move sun below horizon**: Set **Position Y** to negative value (e.g., `-50`)
3. **Run scene**: Sky should become almost pitch black very suddenly
4. **Move sun back up**: Set **Position Y** to positive value (e.g., `60`)
5. **Run scene**: Sky should brighten to yellowish-brown

The transition happens much faster than on Earth or Mars!

## Step 9: Fine-Tuning

### Adjust Atmospheric Density:
Select `WorldEnvironment` → Inspector → Script Variables:
- **Cloud Opacity**: Higher (0.98-0.99) = darker, more oppressive
- **Cloud Opacity**: Lower (0.85-0.90) = lighter, more visibility
- Try different values to get the look you want

### Adjust Sun Visibility:
Select `WorldEnvironment` → Inspector → Shader Parameters:
- **Sun Diffusion**: Higher (0.90-0.95) = sun almost invisible
- **Sun Diffusion**: Lower (0.70-0.80) = sun more visible (less realistic)
- **Sun Intensity**: Higher (0.5-1.0) = brighter sun glow
- **Sun Glow Power**: Higher (12-20) = more concentrated glow
- **Sun Glow Power**: Lower (4-6) = more spread out glow

### Adjust Day/Night Transition:
Select `WorldEnvironment` → Inspector → Script Variables:
- **Day Night Sharpness**: Higher (0.9-1.0) = more abrupt transition
- **Day Night Sharpness**: Lower (0.5-0.7) = more gradual transition

### Adjust Fog Thickness (Optional):
If you enabled fog, adjust density:
- **Fog → Density**: Higher (0.02-0.05) = very thick, limited visibility
- **Fog → Density**: Lower (0.005-0.01) = clearer atmosphere

### Change Sky Colors:
If you want to tweak the Venus atmosphere colors:
1. Edit `scripts/generate_venus_gradients.gd`
2. Modify the color values in the generator functions
3. Run the script again (**File → Run**)
4. Reload your scene to see the new colors

## Step 10: Testing Lightning (Future Implementation)

The shader has reserved parameters for lightning effects. To test the placeholder:

1. **Select WorldEnvironment** node
2. **In Inspector → Script Variables**:
   - Set **Lightning Intensity**: `2.0` (or higher)
   - Set **Lightning Position**: `(0.3, 0.7)` (coordinates in screen space)
3. **Run scene**: You should see a subtle flash in the sky at that position

To properly implement lightning:
- Create a particle system or procedural lightning generator
- Call `trigger_lightning(position, intensity)` from controller script
- Lightning will automatically fade out

Example script for random lightning:
```gdscript
# Attach to WorldEnvironment or a Timer node
func _on_lightning_timer_timeout():
    var random_pos = Vector2(randf(), randf())
    $WorldEnvironment.trigger_lightning(random_pos, randf_range(1.0, 3.0))
```

## Troubleshooting

### Sky is too bright:
- Increase **Cloud Opacity** (try 0.98-0.99)
- Decrease **Sun Intensity** (try 0.1-0.2)
- Increase **Sun Diffusion** (try 0.90-0.95)
- Check Environment → Tonemap → Exposure (lower it to 0.5-0.7)

### Sky is completely black:
- Check that all three gradient textures are assigned in Shader Parameters
- Verify sun is above horizon (positive Y position)
- Decrease **Cloud Opacity** (don't go below 0.85)
- Increase **Sun Intensity**

### Sun is too visible:
Venus's sun should be barely visible - more of a glow than a disc:
- Increase **Sun Diffusion** (0.85-0.95)
- Decrease **Sun Intensity** (0.2-0.3)
- Increase **Sun Glow Power** (8-12) for more concentrated glow

### Sky doesn't look yellowish:
- Verify gradient textures were generated and imported correctly
- Check that **Cloud Color Day** is yellowish-brown
- Regenerate gradients with different color values if needed

### Day/night transition is too slow:
- Increase **Day Night Transition Sharpness** (0.8-0.9)
- This is intentional for Venus - thick atmosphere causes abrupt darkness

### Scene is too dark overall:
- Increase Environment → Ambient Light → Energy (try 0.3-0.5)
- Adjust Environment → Tonemap → Exposure (try 1.0-1.2)
- Add artificial lighting to the scene (DirectionalLight3D or OmniLight3D)

### Can see stars:
Stars should NOT be visible on Venus. If you see them:
- Verify you're using `venus_sky.gdshader` not `earth_sky.gdshader` or `mars_sky.gdshader`
- The Venus shader has no star rendering code

## Scientific Accuracy Notes

**Realistic Venus Surface Conditions:**
- Surface temperature: ~462°C (864°F) - hot enough to melt lead
- Atmospheric pressure: 92 bars (crushing pressure)
- Wind speed: Minimal at surface (hurricane-force at cloud tops)
- Visibility: Very limited (<100m on bad days, few km on clear days)
- Sky color: Yellowish/greenish during day, almost black at night
- Sunlight: Diffuse, shadowless glow (like a very overcast day on Earth)

**This shader simulates:**
- ✓ Thick cloud deck blocking most light
- ✓ Heavily diffused sun (no sharp shadows)
- ✓ Yellowish-brown color from sulfur compounds
- ✓ Very dark nights (no stars/moon visible)
- ✓ Abrupt sunset/sunrise
- ✓ Limited visibility (use fog for this)

**Not simulated (yet):**
- Cloud detail/banding from super-rotation winds
- Lightning flashes (Venus has frequent lightning)
- Subtle greenish tint in shadows
- Heat distortion effects

## Next Steps

- **Add Venus terrain**: Volcanic plains, impact craters
- **Add atmospheric particles**: Dust/haze particles in air
- **Implement lightning**: Random lightning flashes in clouds
- **Add heat distortion**: Screen-space shader for heat shimmer
- **Create transition**: Link this view to Venus planet in main scene
- **Add cloud detail**: Subtle banding patterns in sky texture
- **Sound design**: Rumbling atmosphere, wind sounds

## File References

Created files:
- `shaders/venus_sky.gdshader` - Main Venus sky shader
- `scripts/venus_sky_controller.gd` - Sky parameter controller
- `scripts/generate_venus_gradients.gd` - Gradient generator tool
- `textures/gradients/venus_sun_zenith_gradient.png` - Generated gradient
- `textures/gradients/venus_view_zenith_gradient.png` - Generated gradient
- `textures/gradients/venus_sun_view_gradient.png` - Generated gradient
- `scenes/views/view_venus_surface.tscn` - Venus view scene (you create this)

Reference:
- Based on Mars shader pattern from `MARS_SKY_SETUP.md`
- Venera, Mariner, Pioneer Venus, Venus Express, Akatsuki mission data
