# Mars Sky Shader Setup Guide

This guide walks you through creating a Mars surface view scene with the atmospheric sky shader in Godot 4.5.

## Step 1: Generate Placeholder Gradient Textures

1. **Open Godot Editor** with your solar system project
2. **Navigate to** `scripts/generate_mars_gradients.gd` in the FileSystem panel
3. **Run the script**: Go to **File → Run** (or press Ctrl+Shift+X)
4. **Check the output**: Look in the Output panel at the bottom - you should see:
   ```
   === Mars Gradient Generator ===
   Generated: res://textures/gradients/mars_sun_zenith_gradient.png
   Generated: res://textures/gradients/mars_view_zenith_gradient.png
   Generated: res://textures/gradients/mars_sun_view_gradient.png
   === Generation Complete ===
   ```
5. **Verify textures**: In the FileSystem panel, navigate to `textures/gradients/` - you should see three new PNG files
6. **Import settings**: Click on each gradient texture and in the Import tab (next to Scene/Import):
   - Set **Compress → Mode** to `VRAM Uncompressed` (better quality for gradients)
   - Uncheck **Mipmaps → Generate** (not needed for gradients)
   - Click **Reimport**

## Step 2: Create the Mars View Scene

### 2.1: Create Base Scene Structure

1. **Create new scene**: Scene → New Scene
2. **Add root node**: Click "Other Node" and search for `Node3D`, name it `MarsView`
3. **Save scene**: Ctrl+S, save as `scenes/views/view_mars_surface.tscn`

### 2.2: Add WorldEnvironment with Sky

1. **Add WorldEnvironment**: Right-click `MarsView` → Add Child Node → search for `WorldEnvironment`
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
5. **Assign Mars Sky Shader**:
   - Click the ShaderMaterial to expand it
   - Find **Shader** property
   - Click `[empty]` → Load
   - Navigate to `shaders/mars_sky.gdshader` and select it

### 2.3: Configure Sky Shader Parameters

With the ShaderMaterial still selected, scroll down to see **Shader Parameters**:

#### Sky Gradients:
- **Sun Zenith Gradient**: Click `[empty]` → Load → `textures/gradients/mars_sun_zenith_gradient.png`
- **View Zenith Gradient**: Click `[empty]` → Load → `textures/gradients/mars_view_zenith_gradient.png`
- **Sun View Gradient**: Click `[empty]` → Load → `textures/gradients/mars_sun_view_gradient.png`

#### Sun Parameters:
- **Sun Radius**: `0.03` (default is fine)
- **Sun Color**: Slight yellowish white `(R:1.0, G:0.95, B:0.85)`

#### Stars (Optional - if you have star cubemap):
- **Star Cubemap**: If you have a star cubemap texture, load it here
- **Star Exposure**: `1.5`
- **Star Power**: `3.0`
- **Star Latitude**: `0.0` (equator) - adjust for your Mars location
- **Star Rotation Speed**: `0.1` (day/night cycle speed)
- **Star Day Visibility**: `0.3` (30% visible during day due to thin atmosphere)
- **Constellation Cubemap**: Leave empty for now

#### Atmosphere:
- **Dust Opacity**: `0.6` (controls atmospheric haze strength)

### 2.4: Attach Sky Controller Script

1. **Select WorldEnvironment** node
2. **Attach script**: In Inspector, find **Script** property at top
3. **Load existing script**: Click `[empty]` → Load → `scripts/mars_sky_controller.gd`
4. **Configure script properties**:
   - Expand **Scene References** section
   - **Sun Node**: We'll set this after adding the Sun (next step)
   - **Update Sun Direction**: ✓ Checked
   - Leave **Manual Sun Direction** as default

## Step 3: Add Sun Reference

You have two options:

### Option A: Reference Existing Sun from Main Scene

If you want to use the main scene's Sun position:

1. **Add RemoteTransform3D**: Right-click `MarsView` → Add Child Node → `RemoteTransform3D`, name it `SunReference`
2. **Note**: You'll need to set this up to track the main Sun when the scene is instanced

### Option B: Create Local Sun (Simpler for testing)

1. **Add Node3D**: Right-click `MarsView` → Add Child Node → `Node3D`, name it `Sun`
2. **Position the Sun**:
   - Select the `Sun` node
   - In Inspector, set **Transform → Position**: `(120, 50, 0)` (or wherever you want sunlight to come from)
3. **Link to controller**:
   - Select the `WorldEnvironment` node
   - In Inspector, find **Scene References → Sun Node**
   - Drag the `Sun` node from Scene tree into this property field

## Step 4: Add Camera

1. **Add Camera3D**: Right-click `MarsView` → Add Child Node → `Camera3D`
2. **Position camera**: In Inspector, set:
   - **Transform → Position**: `(0, 2, 0)` (2 units above Mars surface)
   - **Transform → Rotation**: `(-10, 0, 0)` (looking slightly down)
3. **Configure camera**:
   - **Fov**: `75` (or your preference)
   - **Near**: `0.1`
   - **Far**: `1000`

## Step 5: Add Mars Ground (Optional Visual Reference)

To help visualize the scene:

1. **Add MeshInstance3D**: Right-click `MarsView` → Add Child Node → `MeshInstance3D`, name it `Ground`
2. **Create plane mesh**:
   - In Inspector, find **Mesh** property
   - Click `[empty]` → New PlaneMesh
   - Click the PlaneMesh to expand it
   - Set **Size**: `(1000, 1000)` (large ground plane)
3. **Create material** (simple Mars-colored ground):
   - In Inspector, find **Material Override** under Geometry
   - Click `[empty]` → New StandardMaterial3D
   - Click the material to expand it
   - Set **Albedo → Color**: Rusty orange `(R:0.7, G:0.45, B:0.3)`
   - Set **Roughness**: `0.9` (rough Mars terrain)

## Step 6: Configure Environment Settings

Select the `WorldEnvironment` node, then in Inspector expand the Environment resource:

### Background:
- **Mode**: Sky (should already be set)

### Ambient Light:
- **Source**: Sky
- **Sky Contribution**: `0.5` (mix of sky color and custom)
- **Color**: Slight orange tint `(R:1.0, G:0.9, B:0.8)`
- **Energy**: `0.3`

### Tonemap (Optional - for better visuals):
- **Mode**: ACES
- **Exposure**: `1.0`
- **White**: `6.0`

### Glow (Optional - makes sun glow):
- **Enabled**: ✓ Checked
- **Blend Mode**: Additive
- **Intensity**: `0.5`

## Step 7: Test the Scene

1. **Make camera current**: Select Camera3D node, click **Preview** button at top of 3D viewport (or Ctrl+P in scene)
2. **Run scene**: Press F6 to run current scene
3. **Verify**:
   - You should see a dusty orange/rust colored Martian sky
   - Horizon should have peachy/terracotta tones
   - Sun should be visible as a bright disc
   - Stars should be faintly visible (if you set up star cubemap)
   - Ground should be reddish-orange

## Step 8: Fine-Tuning

### Adjust Sky Colors:
If you want to tweak the Mars atmosphere colors:
1. Run `scripts/generate_mars_gradients.gd` again after editing the color values in the script
2. Or create your own gradient textures in an image editor (256x4 pixels, horizontal gradient)

### Adjust Atmosphere Settings:
Select `WorldEnvironment` → Inspector → Shader Parameters:
- Increase **Dust Opacity** for hazier atmosphere (dust storm effect)
- Decrease **Star Day Visibility** to hide stars more during day
- Adjust **Star Rotation Speed** to change day/night cycle speed

### Move the Sun:
Select the `Sun` node and change its position in the Inspector to see how the sky colors change based on sun position.

## Troubleshooting

### Sky is black:
- Check that all three gradient textures are assigned in Shader Parameters
- Verify the gradient textures were generated and imported correctly
- Check that **Dust Opacity** isn't set to 0

### Sun direction doesn't update:
- Verify `Sun Node` is assigned in the WorldEnvironment's script properties
- Check that `Update Sun Direction` is checked
- Make sure the controller script is attached to WorldEnvironment

### Stars aren't visible:
- You need to assign a star cubemap texture (not included in placeholders)
- Check **Star Exposure** and **Star Power** aren't too low
- Verify the cubemap is imported as a Cubemap (not regular texture)

### Scene is too dark/bright:
- Adjust Environment → Tonemap → Exposure
- Adjust Environment → Ambient Light → Energy
- Check Dust Opacity (lower = brighter sky)

## Next Steps

- **Add Mars terrain**: Import Mars terrain models or heightmaps
- **Add surface details**: Rocks, rovers, habitats
- **Create transition**: Link this view to the Mars planet in main scene using `scene_switcher.gd`
- **Improve gradients**: Replace placeholders with artistically crafted gradient textures
- **Add Phobos/Deimos**: Extend shader to include Mars's moons
- **Dust particles**: Add particle effects for dust devils or atmosphere

## File References

Created files:
- `shaders/mars_sky.gdshader` - Main sky shader
- `scripts/mars_sky_controller.gd` - Sky parameter controller
- `scripts/generate_mars_gradients.gd` - Gradient generator tool
- `textures/gradients/mars_sun_zenith_gradient.png` - Generated gradient
- `textures/gradients/mars_view_zenith_gradient.png` - Generated gradient
- `textures/gradients/mars_sun_view_gradient.png` - Generated gradient
- `scenes/views/view_mars_surface.tscn` - Mars view scene (you create this)

Reference:
- `reference_skybox/skybox-tutorial-godot-master/` - Original skybox tutorial
