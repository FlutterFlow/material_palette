export 'package:material_palette/src/shader_params.dart' show ShaderParams, ShaderUIDefaults;
export 'package:material_palette/src/shader_types.dart' show SliderRange;
export 'package:material_palette/src/shader_definitions.dart';

/// Shader name constants
abstract class ShaderNames {
  static const String ripples = 'Ripples';
  static const String taplets = 'Taplets';
  static const String smarble = 'Smarble';
  static const String gritient = 'Grit';
  static const String radient = 'Grit Radial';
  static const String perlin = 'Perlin';
  static const String radialPerlin = 'Perlin Radial';
  static const String simplex = 'Simplex';
  static const String radialSimplex = 'Simplex Radial';
  static const String fbm = 'FBM';
  static const String radialFbm = 'FBM Radial';
  static const String turbulence = 'Turbulence';
  static const String radialTurbulence = 'Turbulence Radial';
  static const String voronoi = 'Voronoi';
  static const String radialVoronoi = 'Voronoi Radial';
  static const String voronoise = 'Voronoise';
  static const String radialVoronoise = 'Voronoise Radial';
  static const String burn = 'Burn';
  static const String radialBurn = 'Burn Radial';
  static const String tapBurn = 'Burn Tap';
  static const String smoke = 'Smoke';
  static const String radialSmoke = 'Smoke Radial';
  static const String tapSmoke = 'Smoke Tap';
  static const String pixelDissolve = 'Pixel Dissolve';
  static const String radialPixelDissolve = 'Pixel Dissolve Radial';
  static const String tapPixelDissolve = 'Pixel Dissolve Tap';
  static const String tapSlurp = 'Slurp Tap';
}

/// Data for a shader card
class ShaderCardData {
  final String title;
  final String description;

  const ShaderCardData({
    required this.title,
    required this.description,
  });
}

/// All available shaders
const List<ShaderCardData> allShaders = [
  ShaderCardData(
    title: ShaderNames.ripples,
    description: 'Animated ripple distortion effect',
  ),
  ShaderCardData(
    title: ShaderNames.taplets,
    description: 'Tap to create ripple effects',
  ),
  ShaderCardData(
    title: ShaderNames.smarble,
    description: 'Marble pattern with drag smudge',
  ),
  ShaderCardData(
    title: ShaderNames.gritient,
    description: 'Risograph-style stippled gradient',
  ),
  ShaderCardData(
    title: ShaderNames.radient,
    description: 'Radial stippled gradient effect',
  ),
  ShaderCardData(
    title: ShaderNames.perlin,
    description: 'Classic Perlin noise gradient',
  ),
  ShaderCardData(
    title: ShaderNames.radialPerlin,
    description: 'Radial Perlin noise gradient',
  ),
  ShaderCardData(
    title: ShaderNames.simplex,
    description: 'Simplex noise with fewer artifacts',
  ),
  ShaderCardData(
    title: ShaderNames.radialSimplex,
    description: 'Radial Simplex noise gradient',
  ),
  ShaderCardData(
    title: ShaderNames.fbm,
    description: 'Fractional Brownian Motion layers',
  ),
  ShaderCardData(
    title: ShaderNames.radialFbm,
    description: 'Radial FBM noise gradient',
  ),
  ShaderCardData(
    title: ShaderNames.turbulence,
    description: 'Turbulent ridge-like patterns',
  ),
  ShaderCardData(
    title: ShaderNames.radialTurbulence,
    description: 'Radial turbulence gradient',
  ),
  ShaderCardData(
    title: ShaderNames.voronoi,
    description: 'Cellular Voronoi noise pattern',
  ),
  ShaderCardData(
    title: ShaderNames.radialVoronoi,
    description: 'Radial Voronoi cell gradient',
  ),
  ShaderCardData(
    title: ShaderNames.voronoise,
    description: 'Blend of Voronoi and noise',
  ),
  ShaderCardData(
    title: ShaderNames.radialVoronoise,
    description: 'Radial Voronoise gradient',
  ),
  ShaderCardData(
    title: ShaderNames.burn,
    description: 'Diagonal burn dissolve effect',
  ),
  ShaderCardData(
    title: ShaderNames.radialBurn,
    description: 'Radial burn dissolve from center',
  ),
  ShaderCardData(
    title: ShaderNames.tapBurn,
    description: 'Tap to create burn dissolve effects',
  ),
  ShaderCardData(
    title: ShaderNames.smoke,
    description: 'Directional smoke dissolve effect',
  ),
  ShaderCardData(
    title: ShaderNames.radialSmoke,
    description: 'Radial smoke dissolve from center',
  ),
  ShaderCardData(
    title: ShaderNames.tapSmoke,
    description: 'Tap to create smoke dissolve effects',
  ),
  ShaderCardData(
    title: ShaderNames.pixelDissolve,
    description: 'Pixel disintegration dissolve effect',
  ),
  ShaderCardData(
    title: ShaderNames.radialPixelDissolve,
    description: 'Radial pixel dissolve from center',
  ),
  ShaderCardData(
    title: ShaderNames.tapPixelDissolve,
    description: 'Tap to create pixel dissolve effects',
  ),
  ShaderCardData(
    title: ShaderNames.tapSlurp,
    description: 'Tap to create cloth vacuum effects',
  ),
];
