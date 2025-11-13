# Earth Sky Shader Setup Guide

This guide walks you through creating an Earth surface view scene with the atmospheric sky shader, including moon phases, eclipses, and stars in Godot 4.5.

## Overview

The Earth sky shader is based on the reference skybox tutorial and includes:
- ✓ Blue sky with realistic gradients (sunrise/sunset colors)
- ✓ Moon with automatic lunar phases
- ✓ Solar and lunar eclipse support
- ✓ Stars visible at night, hidden during day
- ✓ Constellation overlay
- ✓ Dynamic sun and moon positioning

## Step 1: Verify Reference Assets Were Copied

The following assets should already be in your project (copied from reference):

**Gradient Textures:**
- `textures/gradients/earth_sun_zenith_gradient.png` - Blue sky gradient based on sun height
- `textures/gradients/earth_view_zenith_gradient.png` - Horizon brightening effect
- `textures/gradients/earth_sun_view_gradient.png` - Atmospheric glow near sun

**Cubemap Textures:**
- `textures/earth/moon_color_cubemap.jpg` - Lunar surface texture
- `textures/star_color_cubemap.png` - Starfield
- `textures/star_constellation_cubemap.jpg` - Constellation overlay

**Shader:**
- `shaders/earth_sky.gdshader` - Complete Earth sky shader

**Controller Script:**
- `scripts/earth_sky_controller.gd` - Sky parameter updater

If any are missing, check that the copy step completed successfully.

## Step 2: Import Cubemap Textures

Cubemaps require special import settings in Godot:

### 2.1: Import Moon Cubemap

1. **Select texture**: In FileSystem panel, click `textures/earth/moon_color_cubemap.jpg`
2. **Open Import tab**: Next to Scene/Import tabs at top
3. **Set import type**:
   - **Importer**: Select `Cubemap` from dropdown
   - **Compress → Mode**: `VRAM Compressed`
   - **Mipmaps → Generate**: ✓ Checked (better quality at distance)
   - **Slices → Layout**: `3x2` or `2x3` (check which matches the image)
4. **Click Reimport** button at bottom of Import tab

### 2.2: Import Star Cubemaps

Repeat for both star cubemaps:
- `textures/star_color_cubemap.png`
- `textures/star_constellation_cubemap.jpg`

Same settings as moon, but you can lower quality if needed:
- **Compress → Mode**: `VRAM Compressed`
- **Mipmaps → Generate**: ✓ Checked
- **Slices → Layout**: `3x2` or `2x3`

### 2.3: Verify Gradient Textures

Select each gradient in `textures/gradients/earth_*.png` and verify:
- **Compress → Mode**: `VRAM Uncompressed` (prevents banding)
- **Mipmaps → Generate**: ✗ Unchecked (not needed for gradients)
- Click **Reimport** if you changed anything

## Step 3: Create the Earth View Scene

### 3.1: Create Base Scene Structure

1. **Create new scene**: Scene → New Scene
2. **Add root node**: Click "Other Node" and search for `Node3D`, name it `EarthView`
3. **Save scene**: Ctrl+S, save as `scenes/views/view_earth_surface.tscn`

### 3.2: Add WorldEnvironment with Sky

1. **Add WorldEnvironment**: Right-click `EarthView` → Add Child Node → search for `WorldEnvironment`
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
5. **Assign Earth Sky Shader**:
   - Click the ShaderMaterial to expand it
   - Find **Shader** property
   - Click `[empty]` → Load
   - Navigate to `shaders/earth_sky.gdshader` and select it

### 3.3: Configure Sky Shader Parameters

With the ShaderMaterial still selected, scroll down to see **Shader Parameters**:

#### Sky Gradients:
- **Sun Zenith Gradient**: Click `[empty]` → Load → `textures/gradients/earth_sun_zenith_gradient.png`
- **View Zenith Gradient**: Click `[empty]` → Load → `textures/gradients/earth_view_zenith_gradient.png`
- **Sun View Gradient**: Click `[empty]` → Load → `textures/gradients/earth_sun_view_gradient.png`

#### Sun Parameters:
- **Sun Radius**: `0.03` (angular size of sun disc)
- **Sun Color**: White `(R:1.0, G:1.0, B:1.0)`

#### Moon Parameters:
- **Moon Dir**: `(0, 1, 0)` (will be updated by script)
- **Moon Radius**: `0.05` (angular size of moon - slightly larger than sun)
- **Moon Exposure**: `0.0` (brightness adjustment, 0 = neutral)
- **Moon Cubemap**: Click `[empty]` → Load → `textures/earth/moon_color_cubemap.jpg`
- **Moon World to Object**: Leave as default (will be updated by script)

#### Stars:
- **Star Cubemap**: Click `[empty]` → Load → `textures/star_color_cubemap.png`
- **Star Exposure**: `1.5` (star brightness)
- **Star Power**: `3.0` (star sharpness/concentration)
- **Star Latitude**: `0.0` (equator) - adjust for your location on Earth
- **Star Rotation Speed**: `0.1` (day/night cycle speed)
- **Star Day Visibility**: `0.0` (stars hidden during day on Earth)
- **Constellation Color**: Light blue `(R:0.5, G:0.7, B:1.0)`
- **Constellation Cubemap**: Click `[empty]` → Load → `textures/star_constellation_cubemap.jpg`

### 3.4: Attach Sky Controller Script

1. **Select WorldEnvironment** node
2. **Attach script**: In Inspector, find **Script** property at top
3. **Load existing script**: Click `[empty]` → Load → `scripts/earth_sky_controller.gd`
4. **Configure script properties**:
   - Expand **Scene References** section
   - **Sun Node**: We'll set this after adding the Sun (next step)
   - **Moon Node**: We'll set this after adding the Moon (next step)
   - **Update Sun Direction**: ✓ Checked
   - **Update Moon Direction**: ✓ Checked

## Step 4: Add Sun and Moon References

### 4.1: Create Sun Node

1. **Add Node3D**: Right-click `EarthView` → Add Child Node → `Node3D`, name it `Sun`
2. **Position the Sun**:
   - Select the `Sun` node
   - In Inspector, set **Transform → Position**: `(150, 80, 0)` (or wherever you want sunlight to come from)
3. **Link to controller**:
   - Select the `WorldEnvironment` node
   - In Inspector, find **Scene References → Sun Node**
   - Drag the `Sun` node from Scene tree into this property field

### 4.2: Create Moon Node

1. **Add Node3D**: Right-click `EarthView` → Add Child Node → `Node3D`, name it `Moon`
2. **Position the Moon**:
   - Select the `Moon` node
   - In Inspector, set **Transform → Position**: `(100, 50, 80)` (different from sun for interesting lunar phase)
3. **Moon Orientation** (IMPORTANT for texture mapping):
   - Set **Transform → Rotation**: `(0, 180, 0)` (face the moon texture toward Earth)
   - The moon's -Z axis should point toward the viewer for correct texture orientation
4. **Link to controller**:
   - Select the `WorldEnvironment` node
   - In Inspector, find **Scene References → Moon Node**
   - Drag the `Moon` node from Scene tree into this property field

## Step 5: Add Camera

1. **Add Camera3D**: Right-click `EarthView` → Add Child Node → `Camera3D`
2. **Position camera**: In Inspector, set:
   - **Transform → Position**: `(0, 2, 0)` (2 units above Earth surface)
   - **Transform → Rotation**: `(-5, 0, 0)` (looking slightly up at the sky)
3. **Configure camera**:
   - **Fov**: `75` (or your preference)
   - **Near**: `0.1`
   - **Far**: `1000`

## Step 6: Add Earth Ground (Optional Visual Reference)

To help visualize the scene:

1. **Add MeshInstance3D**: Right-click `EarthView` → Add Child Node → `MeshInstance3D`, name it `Ground`
2. **Create plane mesh**:
   - In Inspector, find **Mesh** property
   - Click `[empty]` → New PlaneMesh
   - Click the PlaneMesh to expand it
   - Set **Size**: `(1000, 1000)` (large ground plane)
3. **Create material** (simple grass-colored ground):
   - In Inspector, find **Material Override** under Geometry
   - Click `[empty]` → New StandardMaterial3D
   - Click the material to expand it
   - Set **Albedo → Color**: Grass green `(R:0.3, G:0.6, B:0.3)`
   - Set **Roughness**: `0.8` (fairly rough terrain)

## Step 7: Configure Environment Settings

Select the `WorldEnvironment` node, then in Inspector expand the Environment resource:

### Background:
- **Mode**: Sky (should already be set)

### Ambient Light:
- **Source**: Sky
- **Sky Contribution**: `0.8` (Earth's bright blue sky provides good ambient)
- **Color**: White `(R:1.0, G:1.0, B:1.0)`
- **Energy**: `0.5`

### Tonemap (Optional - for better visuals):
- **Mode**: ACES
- **Exposure**: `1.0`
- **White**: `6.0`

### Glow (Optional - makes sun/moon glow):
- **Enabled**: ✓ Checked
- **Blend Mode**: Additive
- **Intensity**: `0.5`
- **Bloom**: `0.2`

## Step 8: Test the Scene

1. **Make camera current**: Select Camera3D node, click **Preview** button at top of 3D viewport (or Ctrl+P in scene)
2. **Run scene**: Press F6 to run current scene
3. **Verify**:
   - You should see a blue Earth sky
   - Horizon should show sunrise/sunset colors (orange/pink gradient)
   - Sun should be visible as a bright white disc
   - Moon should be visible with proper lunar phase based on sun position
   - Stars should be visible at night, hidden during day
   - Ground should be green

## Step 9: Testing Lunar Phases

The lunar phase is automatically calculated based on the angle between sun and moon. To test different phases:

1. **Select Moon node**
2. **Move moon around** to different positions:
   - **New Moon**: Move moon near sun (same general direction)
   - **Full Moon**: Move moon opposite from sun
   - **Crescent**: Moon 45° from sun
   - **Quarter**: Moon 90° from sun
   - **Gibbous**: Moon 135° from sun
3. **Run scene** to see the phase change

The shader calculates `dot(moon_surface_normal, sun_direction)` to determine how much of the moon is illuminated.

## Step 10: Testing Eclipses

### Solar Eclipse:
1. **Position moon directly between camera and sun**
2. **Align moon and sun directions** (move moon to block sun)
3. **Run scene** - sky should darken, sun should show corona effect

### Lunar Eclipse:
1. **Position moon opposite from sun** (full moon position)
2. **Move sun below horizon** (y position negative)
3. **Run scene** - moon should turn reddish-brown (blood moon)

## Fine-Tuning

### Adjust Sky Colors:
If you want to tweak the Earth atmosphere colors:
- Edit the gradient textures in an image editor
- Or replace them with the reference originals if you prefer

### Adjust Moon Brightness:
Select `WorldEnvironment` → Inspector → Shader Parameters → **Moon Exposure**:
- Increase for brighter moon (try 0.5 to 2.0)
- Decrease for dimmer moon (try -1.0 to -0.5)

### Adjust Star Visibility:
- **Star Exposure**: Higher = brighter stars
- **Star Power**: Higher = sharper, more focused stars
- **Star Day Visibility**: Set to 0.1-0.3 if you want faint stars during day

### Move Sun/Moon:
Change positions of Sun and Moon nodes to:
- Test different times of day (sun height)
- Test different lunar phases (moon position relative to sun)
- Create eclipses (alignment)

### Star Rotation:
Select `WorldEnvironment` → Inspector → Script Variables:
- **Star Rotation Enabled**: Toggle star field rotation
- **Latitude**: Change observer latitude (-90 to +90)

## Orbital Moon Animation (Advanced)

To make the moon orbit Earth realistically:

1. **Attach script to Moon node**: Create `scripts/moon_orbit.gd`
2. **Add orbital logic**:
```gdscript
extends Node3D

@export var orbit_radius: float = 100.0
@export var orbit_speed: float = 0.1
@export var orbit_target: Node3D

var angle: float = 0.0

func _process(delta: float):
    angle += orbit_speed * delta
    if orbit_target:
        global_position = orbit_target.global_position + Vector3(
            cos(angle) * orbit_radius,
            0.0,
            sin(angle) * orbit_radius
        )
        # Face toward Earth (important for texture orientation)
        look_at(orbit_target.global_position, Vector3.UP)
```
3. **Configure**: Set **Orbit Target** to the camera or Earth center point

## Troubleshooting

### Sky is black:
- Check that all three gradient textures are assigned in Shader Parameters
- Verify the gradient textures were imported correctly (PNG format)
- Make sure shader parameter names match exactly

### Moon doesn't show:
- Verify moon cubemap is imported as **Cubemap** type (not regular Texture2D)
- Check **Moon Radius** isn't too small (try 0.05 to 0.1)
- Verify **Moon Node** is assigned in WorldEnvironment script properties
- Check moon position isn't too far away or behind camera

### Moon texture is wrong orientation:
- Adjust Moon node **Rotation** (try different Y rotations: 0, 90, 180, 270)
- The shader uses `moon_world_to_object` matrix to sample cubemap correctly

### Stars don't appear:
- Verify star cubemaps are imported as **Cubemap** type
- Check **Star Exposure** and **Star Power** aren't too low
- Make sure sun is below horizon (stars are hidden during day)
- Verify **Star Day Visibility** is 0.0 (for realistic Earth)

### No lunar phases:
- Verify both **Sun Node** and **Moon Node** are assigned in WorldEnvironment
- Check that **Update Sun Direction** and **Update Moon Direction** are enabled
- Make sure sun and moon are in different positions (phase depends on angle)

### Scene is too dark/bright:
- Adjust Environment → Tonemap → Exposure
- Adjust Environment → Ambient Light → Energy
- Check sun position (if sun is below horizon, scene will be dark)

### Eclipses don't work:
- Solar eclipse requires moon to block sun (very precise alignment needed)
- Lunar eclipse requires sun below horizon and moon opposite
- Adjust **Sun Radius** and **Moon Radius** for easier eclipse triggering

## Next Steps

- **Add Earth terrain**: Import heightmaps or terrain models
- **Add clouds**: Separate cloud layer with animated shader
- **Add atmosphere glow**: Fresnel rim lighting for atmosphere edge
- **Create transition**: Link this view to the Earth planet in main scene
- **Add day/night cycle**: Animate sun position over time
- **Add weather effects**: Rain, fog, storms
- **Moon orbit**: Implement realistic lunar orbit animation

## File References

Created/Copied files:
- `shaders/earth_sky.gdshader` - Main sky shader (copied from reference)
- `scripts/earth_sky_controller.gd` - Sky parameter controller
- `textures/gradients/earth_sun_zenith_gradient.png` - Sky gradient
- `textures/gradients/earth_view_zenith_gradient.png` - Sky gradient
- `textures/gradients/earth_sun_view_gradient.png` - Sky gradient
- `textures/earth/moon_color_cubemap.jpg` - Moon texture
- `textures/star_color_cubemap.png` - Starfield
- `textures/star_constellation_cubemap.jpg` - Constellations
- `scenes/views/view_earth_surface.tscn` - Earth view scene (you create this)

Reference:
- `reference_skybox/skybox-tutorial-godot-master/` - Original skybox tutorial
