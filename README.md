# material_palette

[![pub package](https://img.shields.io/pub/v/material_palette.svg)](https://pub.dev/packages/material_palette)

A collection of **material effects** implemented with shaders for Flutter.

[**Live Demo**](https://flutterflow.github.io/material_palette/)

## Gen1 Materials

### Gradient Fills (linear + radial variants)
- **Gritty Gradient** - Risograph-style stippled gradient
- **Perlin Gradient** - Classic Perlin noise with bump lighting
- **Simplex Gradient** - Simplex noise with fewer artifacts
- **FBM Gradient** - Fractional Brownian Motion layered noise
- **Turbulence Gradient** - Turbulent ridge-like patterns
- **Voronoi Gradient** - Cellular Voronoi noise
- **Voronoise Gradient** - Blend of Voronoi and noise
### Special Effects
- **Marble Smear** - Animated marble with drag-to-smudge
- **Ripple** - Animated wave distortion (wrap)
- **Clickable Ripple** - Tap-triggered ripple effects (wrap)

### Burn Effects
- **Burn** - Directional burn dissolve with animated fire edge (wrap)
- **Burn Radial** - Radial burn dissolve expanding from a center point (wrap)
- **Burn Tap** - Tap to create a burn dissolve effects (wrap)

### Smoke Effects
- **Smoke** - Directional smoke dissolve (wrap)
- **Smoke Radial** - Radial smoke dissolve expanding from a center point (wrap)
- **Smoke Tap** - Tap to create a smoke dissolve effects (wrap)

### Pixel Dissolve Effects
- **Pixel Dissolve** - Directional pixel disintegration dissolve (wrap)
- **Pixel Dissolve Radial** - Radial pixel dissolve expanding from a center point (wrap)
- **Pixel Dissolve Tap** - Tap to create a pixel dissolve effects (wrap)

### Slurp Effects
- **Slurp Tap** - Tap to create a 'slurp' effect (wrap)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  material_palette: ^0.1.0
```

**Important:** Fragment shaders from packages must be declared in your app's `pubspec.yaml`.
You can list only the ones you need, or include all of them:

```yaml
flutter:
  shaders:
    # Gradient fills (linear)
    - packages/material_palette/shaders/gritty_gradient.frag
    - packages/material_palette/shaders/perlin_gradient.frag
    - packages/material_palette/shaders/simplex_gradient.frag
    - packages/material_palette/shaders/fbm_gradient.frag
    - packages/material_palette/shaders/turbulence_gradient.frag
    - packages/material_palette/shaders/voronoi_gradient.frag
    - packages/material_palette/shaders/voronoise_gradient.frag
    # Gradient fills (radial)
    - packages/material_palette/shaders/radial_gritty_gradient.frag
    - packages/material_palette/shaders/radial_perlin_gradient.frag
    - packages/material_palette/shaders/radial_simplex_gradient.frag
    - packages/material_palette/shaders/radial_fbm_gradient.frag
    - packages/material_palette/shaders/radial_turbulence_gradient.frag
    - packages/material_palette/shaders/radial_voronoi_gradient.frag
    - packages/material_palette/shaders/radial_voronoise_gradient.frag
    # Special effects
    - packages/material_palette/shaders/marble_smear.frag
    - packages/material_palette/shaders/ripple.frag
    - packages/material_palette/shaders/click_ripple.frag
    # Burn effects
    - packages/material_palette/shaders/burn.frag
    - packages/material_palette/shaders/radial_burn.frag
    - packages/material_palette/shaders/tappable_burn.frag
    # Smoke effects
    - packages/material_palette/shaders/smoke.frag
    - packages/material_palette/shaders/radial_smoke.frag
    - packages/material_palette/shaders/tappable_smoke.frag
    # Pixel dissolve effects
    - packages/material_palette/shaders/pixel_dissolve.frag
    - packages/material_palette/shaders/radial_pixel_dissolve.frag
    - packages/material_palette/shaders/tappable_pixel_dissolve.frag
    # Slurp effects
    - packages/material_palette/shaders/tappable_slurp.frag
```

## Quick Start

Include the package, then add one of the following widgets to your flutter project.

### ShaderFill

Fills the widget area with the shader effect.

```dart
import 'package:material_palette/material_palette.dart';

GrittyGradientShaderFill(
  width: 300,
  height: 200,
  params: grittyGradientDef.defaults.copyWith(
    colors: {'colorA': Colors.blue, 'colorB': Colors.purple},
  ),
)
```

### ShaderWrap

Wraps an existing flutter widget an applies the shader effect to it.

```dart
import 'package:material_palette/material_palette.dart';

RippleShaderWrap(
  child: Image.asset('assets/photo.jpg'),
)
```

## ShaderParams

All shaders are configured via `ShaderParams`, an immutable parameter bag:

```dart
// Start from defaults
final params = perlinGradientDef.defaults;

// Modify individual values
final custom = params
  .withValue('noiseDensity', 60.0)
  .withColor('colorA', Colors.teal);
```

## Animation Modes

Every shader widget supports three animation modes:

- `ShaderAnimationMode.running` - Internal ticker causes the shader to animate over time (default).
- `ShaderAnimationMode.static` - Renders once and caches.
- `ShaderAnimationMode.animation` - External `Animation<double>` drives the shader animation.

```dart
GrittyGradientShaderFill(
  width: 300,
  height: 200,
  animationMode: ShaderAnimationMode.static,
)
```

## All Shaders

| Shader | Type | Description |
|--------|------|-------------|
| `GrittyGradientShaderFill` | Fill | Risograph-style stippled gradient |
| `RadialGrittyGradientShaderFill` | Fill | Radial stippled gradient |
| `PerlinGradientShaderFill` | Fill | Classic Perlin noise gradient |
| `RadialPerlinGradientShaderFill` | Fill | Radial Perlin noise gradient |
| `SimplexGradientShaderFill` | Fill | Simplex noise gradient |
| `RadialSimplexGradientShaderFill` | Fill | Radial Simplex noise gradient |
| `FbmGradientShaderFill` | Fill | Fractional Brownian Motion gradient |
| `RadialFbmGradientShaderFill` | Fill | Radial FBM gradient |
| `TurbulenceGradientShaderFill` | Fill | Turbulent ridge-like gradient |
| `RadialTurbulenceGradientShaderFill` | Fill | Radial turbulence gradient |
| `VoronoiGradientShaderFill` | Fill | Cellular Voronoi noise gradient |
| `RadialVoronoiGradientShaderFill` | Fill | Radial Voronoi gradient |
| `VoronoiseGradientShaderFill` | Fill | Voronoi + noise blend gradient |
| `RadialVoronoiseGradientShaderFill` | Fill | Radial Voronoise gradient |
| `MarbleSmearShaderFill` | Fill | Marble with drag smudge |
| `RippleShaderWrap` | Wrap | Animated wave distortion |
| `ClickableRippleShaderWrap` | Wrap | Tap-triggered ripples |
| `BurnShaderWrap` | Wrap | Directional burn dissolve |
| `RadialBurnShaderWrap` | Wrap | Radial burn dissolve from center |
| `TappableBurnShaderWrap` | Wrap | Tap-triggered burn dissolves |
| `SmokeShaderWrap` | Wrap | Directional smoke dissolve |
| `RadialSmokeShaderWrap` | Wrap | Radial smoke dissolve from center |
| `TappableSmokeShaderWrap` | Wrap | Tap-triggered smoke dissolves |
| `PixelDissolveShaderWrap` | Wrap | Directional pixel disintegration dissolve |
| `RadialPixelDissolveShaderWrap` | Wrap | Radial pixel dissolve from center |
| `TappablePixelDissolveShaderWrap` | Wrap | Tap-triggered pixel dissolves |
| `TappableSlurpShaderWrap` | Wrap | Tap-triggered slurp dissolves |

## Running the Demo

```bash
cd example
flutter pub get
flutter run -d chrome    # or macos, etc.
```

## License

MIT
