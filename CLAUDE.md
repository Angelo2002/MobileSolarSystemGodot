# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a solar system simulation game built with **Godot 4.5** using the mobile rendering backend. The project demonstrates advanced shader techniques for realistic celestial bodies with day/night cycles, atmospheric effects, and interactive camera controls.

**Key Tech:**
- Godot Engine 4.5
- GDScript 2.0
- Custom spatial shaders with proper lighting integration
- Mobile renderer (optimized for performance)

## Development Workflow

### Running the Project
Open the project in Godot 4.5+ editor:
```bash
godot project.godot
```
Press F5 to run, or use the "Play" button in the editor.

### Testing Changes
- For shader changes: Save the `.gdshader` file and Godot will automatically recompile
- For script changes: Use F6 to run the current scene being edited
- For scene changes: The user prefers to edit scenes manually in the Godot editor - **only modify `.gd` script files and `.gdshader` shader files**

## Architecture

### Scene Organization

The project uses a **modular scene composition pattern**:

```
main.tscn (Root orchestrator)
├── Earth (PackedScene instance from earth.tscn)
│   ├── EarthSurface - Main planet with day/night shader
│   ├── EarthClouds - Transparent cloud layer
│   └── Atmosphere overlay - Fresnel glow effect
├── Sun (PackedScene instance from sun.tscn)
│   ├── MeshInstance3D with emission shader
│   └── OmniLight3D for dynamic lighting
├── Camera3D with camera_orbit.gd script
└── WorldEnvironment with starfield skybox
```

Each celestial body is a **self-contained scene** that can be instanced multiple times. Follow this pattern when adding new planets.

### Shader System

The project uses a **multi-layer shader architecture** with proper Godot lighting integration:

1. **earth_surface.gdshader** - Day/night texture blending with proper lighting
   - Uses `light()` function to receive lighting data automatically from Godot
   - Blends `day_texture` and `night_texture` based on `dot(NORMAL, LIGHT)`
   - Day side: Proper diffuse lighting with `LIGHT_COLOR` and `ATTENUATION`
   - Night side: City lights emission (independent of lighting)
   - Specular highlights for water reflection using half-vector
   - Normal mapping via `NORMAL_MAP` and `NORMAL_MAP_DEPTH`
   - **No manual light direction needed** - Godot provides it automatically

2. **atmosphere.gdshader** - Atmospheric rim lighting
   - Applied as `material_overlay` on planet mesh
   - Uses fresnel effect for edge glow
   - Sunset color band at day/night terminator
   - Render mode: `blend_add, cull_front`

3. **clouds.gdshader** - Animated cloud layer
   - Simple scrolling UV animation
   - Alpha transparency based on texture brightness
   - Applied to slightly larger sphere (scale 1.01x)

4. **sun.gdshader** - Self-illuminated star
   - Unshaded emission-based rendering
   - Animated turbulence distortion
   - No lighting dependency

### Lighting Integration Pattern

When creating planet shaders that respond to light:

```glsl
shader_type spatial;

void fragment() {
    // Set base properties
    NORMAL_MAP = texture(normal_map, UV).rgb;
    ALBEDO = vec3(1.0);
    ROUGHNESS = 0.8;
}

void light() {
    // Godot automatically provides:
    // - LIGHT: normalized light direction
    // - NORMAL: surface normal (with normal map applied)
    // - ATTENUATION: light falloff
    // - LIGHT_COLOR: light's color
    // - VIEW: view direction

    float light_amount = max(dot(NORMAL, LIGHT), 0.0);

    DIFFUSE_LIGHT += your_calculation * ATTENUATION * LIGHT_COLOR;
    SPECULAR_LIGHT += your_specular * ATTENUATION * LIGHT_COLOR;
}
```

The `light()` function is called per-light, allowing proper multi-light scenes. **Do not manually set light direction uniforms** - use the built-in `LIGHT` variable.

### Material Application Pattern

Shaders are applied via material overrides:
```gdscript
# Single material
material_override = ShaderMaterial with shader

# Dual-layer rendering (surface + overlay)
surface_material_override/0 = ShaderMaterial (base)
material_overlay = ShaderMaterial (additive layer)
```

### Scripting Patterns

**camera_orbit.gd** demonstrates the standard pattern:
- Use `@export` variables for designer-configurable parameters
- Separate `_input()` for event handling from `_process()` for continuous updates
- Clamp values for safety (distance, rotation limits)
- Use spherical coordinates for orbital calculations

When creating new scripts:
- Always use type hints (`: float`, `: Node3D`, etc.)
- Export important parameters for editor tweaking
- Keep input handling separate from logic updates

## Important Constraints

### Scene File Editing
**CRITICAL**: The user prefers to edit `.tscn` scene files and Godot objects manually in the editor.
- **DO**: Modify `.gd` script files and `.gdshader` shader files
- **DO NOT**: Edit `.tscn` files directly
- When changes require scene modifications, provide clear instructions for the user to make those changes in the Godot editor

### Texture Assets
The `textures/` directory is ignored by git (large binary files). When referencing textures:
- Use `res://textures/` paths in scripts/shaders
- Assume textures exist at runtime
- Available texture sets: Earth (day/night/clouds/normal/specular), Sun (8k), planets (Mercury through Neptune), starmap (4k)

## Shader Development Notes

### Using Godot's Built-in Lighting
All planet shaders use the `light()` function which Godot calls automatically for each light source. The shader receives:
- `LIGHT` - normalized direction from surface to light
- `NORMAL` - surface normal (after normal mapping)
- `ATTENUATION` - light distance falloff
- `LIGHT_COLOR` - RGB color of the light

Always multiply contributions by `ATTENUATION * LIGHT_COLOR` for proper lighting response.

### Atmosphere Overlay Technique
For planetary atmospheres, use the dual-material pattern:
1. Base material on `surface_material_override/0`
2. Atmosphere on `material_overlay` with `blend_add` mode
3. Use `cull_front` on atmosphere shader to render from inside

This allows the atmosphere to additively blend without obscuring the surface.

### Shader Parameter Naming
Follow Godot conventions:
- Use `uniform` for exposed parameters
- Use `hint_range` for numeric sliders in editor
- Use `: source_color` hint for texture parameters
- Use `: hint_normal` for normal map textures
- Name textures descriptively: `day_texture`, `night_texture`, `normal_map`

## Project Structure

```
scenes/           - Godot scene files (.tscn)
  ├── main.tscn   - Root scene (orchestrator)
  ├── earth.tscn  - Earth system with surface/clouds/atmosphere
  └── sun.tscn    - Sun with light and emission shader

scripts/          - GDScript files (.gd)
  └── camera_orbit.gd - Orbital camera controller

shaders/          - Custom shader files (.gdshader)
  ├── earth_surface.gdshader - Day/night with proper lighting
  ├── atmosphere.gdshader    - Fresnel rim glow
  ├── clouds.gdshader        - Animated clouds
  └── sun.gdshader           - Solar surface

textures/         - Image assets (gitignored)
```

## Expansion Roadmap

The project has texture assets prepared for additional planets (Mars, Jupiter, Saturn, etc.). When adding new planets:

1. Create a new scene file following the `earth.tscn` pattern
2. Create or adapt shaders for planet-specific effects (gas giants vs rocky planets)
3. Instance the new scene in `main.tscn`
4. Position appropriately in the solar system layout
5. Lighting from the Sun's OmniLight3D will automatically work with shaders using `light()` function

For gas giants (Jupiter, Saturn), the day/night shader won't apply - create specialized shaders for their unique atmospheric effects.
