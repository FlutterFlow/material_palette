import 'package:flutter/material.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_registry.dart';
import 'package:material_palette/src/shader_material.dart';

/// Bundles layout + defaults + uiDefaults for one shader.
class ShaderDefinition {
  final UniformLayout layout;
  final ShaderParams defaults;
  final ShaderUIDefaults uiDefaults;

  /// Whether this shader wraps a child widget (true) or renders procedurally (false).
  final bool hasChildren;

  /// The asset path to the compiled fragment shader.
  final String assetPath;

  /// Maps each parameter name to a brief description of its role in this shader.
  final Map<String, String> paramDescriptions;

  /// The last version of the material_palette package in which this shader's
  /// GLSL implementation was changed. When set, the shader's GLSL source is
  /// not expected to be changed.
  final String? stableVersion;

  const ShaderDefinition({
    required this.layout,
    required this.defaults,
    required this.uiDefaults,
    required this.hasChildren,
    required this.assetPath,
    this.paramDescriptions = const {},
    this.stableVersion,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRITTY GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final grittyGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/gritty_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.linearGradientFields,
    ...ParamGroups.grittyNoiseFields,
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientAngle': 110.41, 'gradientScale': 0.60, 'gradientOffset': -0.24,
      'noiseDensity': 160.70, 'noiseIntensity': 0.65,
      'stippleStrength': 0.0, 'ditherStrength': 3.66, 'ditherScale': 0.40,
      'animSpeed': 0.0,
      'colorCount': 2.0, 'softness': 0.0,
      'exposure': 1.0, 'contrast': 1.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(235, 200, 216, 1),
        const Color.fromRGBO(115, 140, 191, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.linearGradientRanges,
    ...ParamGroups.grittyNoiseRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.linearGradientDescriptions,
    ...ParamGroups.grittyNoiseDescriptions,
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// GRITTY GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialGrittyGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/radial_gritty_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.radialGradientFields,
    ...ParamGroups.grittyNoiseFields,
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientCenterX': 0.17, 'gradientCenterY': 0.03,
      'gradientScale': 1.29, 'gradientOffset': -0.32,
      'noiseDensity': 800.0, 'noiseIntensity': 0.35,
      'stippleStrength': 0.56, 'ditherStrength': 0.0, 'ditherScale': 0.95,
      'animSpeed': 0.0,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(255, 230, 180, 1),
        const Color.fromRGBO(230, 140, 120, 1),
        const Color.fromRGBO(100, 80, 140, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.radialGradientRanges,
    ...ParamGroups.grittyNoiseRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.radialGradientDescriptions,
    ...ParamGroups.grittyNoiseDescriptions,
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// PERLIN GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final perlinGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/perlin_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.linearGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('noiseScale'),
    const UniformField('noiseContrast'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientAngle': 110.03, 'gradientScale': 0.85, 'gradientOffset': 0.01,
      'noiseIntensity': 0.46, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.91,
      'noiseScale': 15.28, 'noiseContrast': 3.00,
      'colorCount': 2.0, 'softness': 0.74,
      'exposure': 1.0, 'contrast': 1.00,
      'bumpStrength': 0.0,
      'lightDirX': 0.60, 'lightDirY': 0.40, 'lightDirZ': 1.0,
      'lightIntensity': 1.10, 'ambient': 0.35, 'specular': 0.30,
      'shininess': 24.0, 'metallic': 0.0, 'roughness': 0.50,
      'edgeFade': 0.0, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(37, 146, 244, 1),
        const Color.fromRGBO(242, 252, 252, 1),
        const Color.fromRGBO(20, 24, 133, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.linearGradientRanges,
    ...ParamGroups.noiseRanges,
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 60.0),
    'noiseContrast': const SliderRange('Noise Contrast', min: 0.5, max: 3.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.linearGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'noiseScale': 'Frequency scale of the Perlin noise',
    'noiseContrast': 'Contrast sharpening of the noise pattern',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// PERLIN GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialPerlinGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/radial_perlin_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.radialGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('noiseScale'),
    const UniformField('noiseContrast'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientCenterX': 0.61, 'gradientCenterY': 0.26,
      'gradientScale': 1.47, 'gradientOffset': 0.0,
      'noiseIntensity': 0.57, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.86,
      'noiseScale': 24.0, 'noiseContrast': 0.66,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 1.05,
      'lightDirX': 0.50, 'lightDirY': 0.50, 'lightDirZ': 1.0,
      'lightIntensity': 1.10, 'ambient': 0.35, 'specular': 0.03,
      'shininess': 26.71, 'metallic': 0.0, 'roughness': 0.26,
      'edgeFade': 0.0, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(200, 230, 201, 1),
        const Color.fromRGBO(76, 175, 80, 1),
        const Color.fromRGBO(27, 94, 32, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.radialGradientRanges,
    ...ParamGroups.noiseRanges,
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 60.0),
    'noiseContrast': const SliderRange('Noise Contrast', min: 0.5, max: 3.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.radialGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'noiseScale': 'Frequency scale of the Perlin noise',
    'noiseContrast': 'Contrast sharpening of the noise pattern',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// SIMPLEX GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final simplexGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/simplex_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.linearGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('noiseScale'),
    const UniformField('sharpness'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientAngle': 185.08, 'gradientScale': 0.89, 'gradientOffset': 0.0,
      'noiseIntensity': 0.32, 'ditherStrength': 2.51, 'ditherScale': 0.29,
      'animSpeed': 1.46,
      'noiseScale': 6.36, 'sharpness': 2.20,
      'colorCount': 6.76, 'softness': 0.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.0,
      'lightDirX': 0.55, 'lightDirY': 0.45, 'lightDirZ': 1.0,
      'lightIntensity': 1.15, 'ambient': 0.70, 'specular': 0.29,
      'shininess': 40.76, 'metallic': 1.0, 'roughness': 1.0,
      'edgeFade': 1.72, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(139, 226, 243, 1),
        const Color.fromRGBO(101, 160, 236, 1),
        const Color.fromRGBO(64, 70, 227, 1),
        const Color.fromRGBO(98, 36, 209, 1),
        const Color.fromRGBO(134, 33, 166, 1),
        const Color.fromRGBO(125, 28, 109, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.linearGradientRanges,
    ...ParamGroups.noiseRanges,
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 60.0),
    'sharpness': const SliderRange('Sharpness', min: 0.5, max: 3.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.linearGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'noiseScale': 'Frequency scale of the simplex noise',
    'sharpness': 'Edge sharpness of the noise features',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// SIMPLEX GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialSimplexGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/radial_simplex_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.radialGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('noiseScale'),
    const UniformField('sharpness'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientCenterX': 0.40, 'gradientCenterY': 0.50,
      'gradientScale': 0.75, 'gradientOffset': -0.42,
      'noiseIntensity': 0.36, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.35,
      'noiseScale': 19.2, 'sharpness': 1.27,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.33,
      'lightDirX': 0.00, 'lightDirY': -0.02, 'lightDirZ': 1.10,
      'lightIntensity': 1.0, 'ambient': 1.0, 'specular': 0.55,
      'shininess': 36.03, 'metallic': 1.0, 'roughness': 0.02,
      'edgeFade': 0.0, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(246, 187, 77, 1),
        const Color.fromRGBO(211, 211, 211, 1),
        const Color.fromRGBO(23, 45, 144, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.radialGradientRanges,
    ...ParamGroups.noiseRanges,
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 60.0),
    'sharpness': const SliderRange('Sharpness', min: 0.5, max: 3.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.radialGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'noiseScale': 'Frequency scale of the simplex noise',
    'sharpness': 'Edge sharpness of the noise features',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// FBM GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final fbmGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/fbm_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.linearGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('octaves'),
    const UniformField('lacunarity'),
    const UniformField('persistence'),
    const UniformField('noiseScale'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientAngle': 123.64, 'gradientScale': 1.27, 'gradientOffset': 0.19,
      'noiseIntensity': 0.81, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.33,
      'octaves': 6.06, 'lacunarity': 2.35, 'persistence': 0.50, 'noiseScale': 4.50,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.10,
      'lightDirX': 0.50, 'lightDirY': 0.60, 'lightDirZ': 0.90,
      'lightIntensity': 0.89, 'ambient': 0.29, 'specular': 0.16,
      'shininess': 3.06, 'metallic': 0.0, 'roughness': 0.49,
      'edgeFade': 0.0, 'edgeFadeMode': 1.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(141, 110, 99, 1),
        const Color.fromRGBO(188, 170, 164, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.linearGradientRanges,
    ...ParamGroups.noiseRanges,
    'octaves': const SliderRange('Octaves', min: 1.0, max: 8.0),
    'lacunarity': const SliderRange('Lacunarity', min: 1.0, max: 4.0),
    'persistence': const SliderRange('Persistence', min: 0.1, max: 1.0),
    'noiseScale': const SliderRange('Noise Scale', min: 0.5, max: 40.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.linearGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'octaves': 'Number of noise layers summed together',
    'lacunarity': 'Frequency multiplier between successive octaves',
    'persistence': 'Amplitude decay between successive octaves',
    'noiseScale': 'Base frequency scale of the FBM noise',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// FBM GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialFbmGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/radial_fbm_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.radialGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('octaves'),
    const UniformField('lacunarity'),
    const UniformField('persistence'),
    const UniformField('noiseScale'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientCenterX': 0.74, 'gradientCenterY': 1.00,
      'gradientScale': 1.96, 'gradientOffset': -0.43,
      'noiseIntensity': 0.38, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.30,
      'octaves': 6.12, 'lacunarity': 1.93, 'persistence': 0.53, 'noiseScale': 6.4,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.52,
      'lightDirX': 0.50, 'lightDirY': 0.50, 'lightDirZ': 1.0,
      'lightIntensity': 1.20, 'ambient': 0.11, 'specular': 0.02,
      'shininess': 21.63, 'metallic': 0.0, 'roughness': 0.20,
      'edgeFade': 0.0, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(215, 216, 226, 1),
        const Color.fromRGBO(161, 136, 127, 1),
        const Color.fromRGBO(62, 39, 35, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.radialGradientRanges,
    ...ParamGroups.noiseRanges,
    'octaves': const SliderRange('Octaves', min: 1.0, max: 8.0),
    'lacunarity': const SliderRange('Lacunarity', min: 1.0, max: 4.0),
    'persistence': const SliderRange('Persistence', min: 0.1, max: 1.0),
    'noiseScale': const SliderRange('Noise Scale', min: 0.5, max: 40.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.radialGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'octaves': 'Number of noise layers summed together',
    'lacunarity': 'Frequency multiplier between successive octaves',
    'persistence': 'Amplitude decay between successive octaves',
    'noiseScale': 'Base frequency scale of the FBM noise',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// TURBULENCE GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final turbulenceGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/turbulence_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.linearGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('octaves'),
    const UniformField('baseFrequency'),
    const UniformField('noiseScale'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientAngle': 233.23, 'gradientScale': 0.87, 'gradientOffset': 0.27,
      'noiseIntensity': 0.33, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.61,
      'octaves': 6.22, 'baseFrequency': 1.28, 'noiseScale': 8.84,
      'colorCount': 3.35, 'softness': 0.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.0,
      'lightDirX': 0.40, 'lightDirY': 0.60, 'lightDirZ': 0.80,
      'lightIntensity': 1.29, 'ambient': 0.25, 'specular': 0.42,
      'shininess': 14.73, 'metallic': 0.37, 'roughness': 0.29,
      'edgeFade': 0.0, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(255, 138, 101, 1),
        const Color.fromRGBO(255, 87, 34, 1),
        const Color.fromRGBO(183, 28, 28, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.linearGradientRanges,
    ...ParamGroups.noiseRanges,
    'octaves': const SliderRange('Octaves', min: 1.0, max: 8.0),
    'baseFrequency': const SliderRange('Base Freq', min: 0.5, max: 4.0),
    'noiseScale': const SliderRange('Noise Scale', min: 0.5, max: 30.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.linearGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'octaves': 'Number of turbulence layers summed together',
    'baseFrequency': 'Base frequency of the turbulence pattern',
    'noiseScale': 'Frequency scale of the turbulence noise',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// TURBULENCE GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialTurbulenceGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/radial_turbulence_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.radialGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('octaves'),
    const UniformField('baseFrequency'),
    const UniformField('noiseScale'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientCenterX': 0.24, 'gradientCenterY': 0.27,
      'gradientScale': 2.03, 'gradientOffset': -0.02,
      'noiseIntensity': 0.51, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.75,
      'octaves': 3.02, 'baseFrequency': 1.94, 'noiseScale': 3.9,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 1.68,
      'lightDirX': 0.17, 'lightDirY': 0.50, 'lightDirZ': 1.0,
      'lightIntensity': 1.62, 'ambient': 0.67, 'specular': 0.06,
      'shininess': 35.72, 'metallic': 0.0, 'roughness': 1.0,
      'edgeFade': 2.30, 'edgeFadeMode': 1.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(75, 65, 216, 1),
        const Color.fromRGBO(162, 187, 221, 1),
        const Color.fromRGBO(82, 36, 117, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.radialGradientRanges,
    ...ParamGroups.noiseRanges,
    'octaves': const SliderRange('Octaves', min: 1.0, max: 8.0),
    'baseFrequency': const SliderRange('Base Freq', min: 0.5, max: 4.0),
    'noiseScale': const SliderRange('Noise Scale', min: 0.5, max: 30.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.radialGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'octaves': 'Number of turbulence layers summed together',
    'baseFrequency': 'Base frequency of the turbulence pattern',
    'noiseScale': 'Frequency scale of the turbulence noise',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// VORONOI GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final voronoiGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/voronoi_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.linearGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('cellScale'),
    const UniformField('cellJitter'),
    const UniformField('distanceType'),
    const UniformField('outputMode'),
    const UniformField('cellSmoothness'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientAngle': 84.68, 'gradientScale': 0.73, 'gradientOffset': 0.22,
      'noiseIntensity': 0.12, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.5,
      'cellScale': 20.3, 'cellJitter': 1.0, 'distanceType': 0.45,
      'outputMode': 0.0, 'cellSmoothness': 0.54,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.19,
      'lightDirX': 0.26, 'lightDirY': 0.50, 'lightDirZ': 1.0,
      'lightIntensity': 1.0, 'ambient': 0.30, 'specular': 0.22,
      'shininess': 40.0, 'metallic': 0.54, 'roughness': 0.83,
      'edgeFade': 1.31, 'edgeFadeMode': 2.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(251, 255, 220, 1),
        const Color.fromRGBO(77, 225, 203, 1),
        const Color.fromRGBO(0, 83, 87, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.linearGradientRanges,
    ...ParamGroups.noiseRanges,
    'animSpeed': const SliderRange('Speed', min: 0.0, max: 1.0),
    'cellScale': const SliderRange('Cell Scale', min: 1.0, max: 80.0),
    'cellJitter': const SliderRange('Cell Jitter', min: 0.0, max: 1.0),
    'distanceType': const SliderRange('Distance', min: 0.0, max: 2.0),
    'outputMode': const SliderRange('Output Mode', min: 0.0, max: 2.0),
    'cellSmoothness': const SliderRange('Smoothness', min: 0.0, max: 2.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.linearGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'cellScale': 'Size of the Voronoi cells',
    'cellJitter': 'Randomness of cell point placement',
    'distanceType': 'Distance metric used for cell boundaries',
    'outputMode': 'Which Voronoi distance value to visualize',
    'cellSmoothness': 'Smoothing applied to cell edges',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// VORONOI GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialVoronoiGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/radial_voronoi_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.radialGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('cellScale'),
    const UniformField('cellJitter'),
    const UniformField('distanceType'),
    const UniformField('outputMode'),
    const UniformField('cellSmoothness'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientCenterX': 0.50, 'gradientCenterY': 0.36,
      'gradientScale': 0.80, 'gradientOffset': 0.0,
      'noiseIntensity': 0.56, 'ditherStrength': 2.19, 'ditherScale': 0.21,
      'animSpeed': 0.05,
      'cellScale': 14.80, 'cellJitter': 0.07, 'distanceType': 0.0,
      'outputMode': 0.0, 'cellSmoothness': 0.42,
      'colorCount': 3.0, 'softness': 0.79,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.69,
      'lightDirX': -0.04, 'lightDirY': 0.23, 'lightDirZ': 1.03,
      'lightIntensity': 0.87, 'ambient': 0.65, 'specular': 0.61,
      'shininess': 106.58, 'metallic': 0.43, 'roughness': 0.26,
      'edgeFade': 0.0, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(255, 208, 39, 1),
        const Color.fromRGBO(0, 150, 136, 1),
        const Color.fromRGBO(0, 77, 64, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.radialGradientRanges,
    ...ParamGroups.noiseRanges,
    'animSpeed': const SliderRange('Speed', min: 0.0, max: 1.0),
    'cellScale': const SliderRange('Cell Scale', min: 1.0, max: 80.0),
    'cellJitter': const SliderRange('Cell Jitter', min: 0.0, max: 1.0),
    'distanceType': const SliderRange('Distance', min: 0.0, max: 2.0),
    'outputMode': const SliderRange('Output Mode', min: 0.0, max: 2.0),
    'cellSmoothness': const SliderRange('Smoothness', min: 0.0, max: 2.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.radialGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'cellScale': 'Size of the Voronoi cells',
    'cellJitter': 'Randomness of cell point placement',
    'distanceType': 'Distance metric used for cell boundaries',
    'outputMode': 'Which Voronoi distance value to visualize',
    'cellSmoothness': 'Smoothing applied to cell edges',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// VORONOISE GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final voronoiseGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/voronoise_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.linearGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('cellScale'),
    const UniformField('noiseBlend'),
    const UniformField('edgeSmoothness'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientAngle': 171.90, 'gradientScale': 0.68, 'gradientOffset': -0.07,
      'noiseIntensity': 0.55, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.00,
      'cellScale': 37.8, 'noiseBlend': 0.38, 'edgeSmoothness': 0.11,
      'colorCount': 2.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.0,
      'lightDirX': 0.55, 'lightDirY': 0.45, 'lightDirZ': 1.00,
      'lightIntensity': 1.63, 'ambient': 0.35, 'specular': 0.10,
      'shininess': 20.0, 'metallic': 0.0, 'roughness': 0.40,
      'edgeFade': 0.0, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(244, 221, 37, 1),
        const Color.fromRGBO(44, 8, 71, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.linearGradientRanges,
    ...ParamGroups.noiseRanges,
    'animSpeed': const SliderRange('Speed', min: 0.0, max: 1.0),
    'cellScale': const SliderRange('Cell Scale', min: 1.0, max: 100.0),
    'noiseBlend': const SliderRange('Noise Blend', min: 0.0, max: 1.0),
    'edgeSmoothness': const SliderRange('Edge Smooth', min: 0.0, max: 1.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.linearGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'cellScale': 'Size of the Voronoise cells',
    'noiseBlend': 'Blend between Voronoi structure and noise',
    'edgeSmoothness': 'Smoothing applied to cell edges',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// VORONOISE GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialVoronoiseGradientDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/radial_voronoise_gradient.frag',
  layout: UniformLayout([
    ...ParamGroups.radialGradientFields,
    ...ParamGroups.noiseFields,
    const UniformField('cellScale'),
    const UniformField('noiseBlend'),
    const UniformField('edgeSmoothness'),
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
    ...ParamGroups.lightingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientCenterX': 0.46, 'gradientCenterY': 0.69,
      'gradientScale': 0.80, 'gradientOffset': -0.42,
      'noiseIntensity': 0.34, 'ditherStrength': 0.0, 'ditherScale': 1.0,
      'animSpeed': 0.0,
      'cellScale': 14.6, 'noiseBlend': 0.07, 'edgeSmoothness': 0.29,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 1.19,
      'lightDirX': 0.50, 'lightDirY': 0.42, 'lightDirZ': 0.80,
      'lightIntensity': 2.0, 'ambient': 0.97, 'specular': 0.82,
      'shininess': 65.54, 'metallic': 0.61, 'roughness': 0.61,
      'edgeFade': 1.85, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(63, 95, 218, 1),
        const Color.fromRGBO(161, 204, 221, 1),
        const Color.fromRGBO(59, 35, 118, 1),
      ]),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.radialGradientRanges,
    ...ParamGroups.noiseRanges,
    'animSpeed': const SliderRange('Speed', min: 0.0, max: 1.0),
    'cellScale': const SliderRange('Cell Scale', min: 1.0, max: 100.0),
    'noiseBlend': const SliderRange('Noise Blend', min: 0.0, max: 1.0),
    'edgeSmoothness': const SliderRange('Edge Smooth', min: 0.0, max: 1.0),
    ...ParamGroups.edgeFadeRanges,
    ...ParamGroups.gradientColorsRanges,
    ...ParamGroups.postProcessingRanges,
    ...ParamGroups.lightingRanges,
  }),
  paramDescriptions: {
    ...ParamGroups.radialGradientDescriptions,
    ...ParamGroups.noiseDescriptions,
    'cellScale': 'Size of the Voronoise cells',
    'noiseBlend': 'Blend between Voronoi structure and noise',
    'edgeSmoothness': 'Smoothing applied to cell edges',
    ...ParamGroups.gradientColorsDescriptions,
    ...ParamGroups.postProcessingDescriptions,
    ...ParamGroups.lightingDescriptions,
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// MARBLE SMEAR SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final marbleSmearShaderDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/marble_smear.frag',
  layout: UniformLayout([
    const UniformField.color('bgColor'),
    const UniformField('warp1Scale'),
    const UniformField('warp2Scale'),
    const UniformField('finalScale'),
    const UniformField('warpStrength'),
    const UniformField('contrastPower'),
    const UniformField('finalContrast'),
    const UniformField('animSpeedInputX'),
    const UniformField('animSpeedInputY'),
    const UniformField('animSpeedWarpX'),
    const UniformField('animSpeedWarpY'),
    const UniformField('animAmpInput'),
    const UniformField('animAmpWarp'),
    const UniformField.color('color0'), // cream / lightest vein
    const UniformField.color('color1'), // tan / mid-tone base
    const UniformField.color('color2'), // brown / dark base
    const UniformField.color('color3'), // teal / accent edge
    const UniformField.color('color4'), // dark / valley shadow
    const UniformField('lightIntensity'),
    const UniformField('smudgeRadius'),
    const UniformField('smudgeStrength'),
    const UniformField('smudgeFalloff'),
    // Smudge data written manually after layout (count + 10 times + 10x4 positions)
  ]),
  defaults: ShaderParams(
    values: {
      'warp1Scale': 1.3, 'warp2Scale': 4.0, 'finalScale': 2.8,
      'warpStrength': 6.8, 'contrastPower': 3.5, 'finalContrast': 1.1,
      'animSpeedInputX': 0.27, 'animSpeedInputY': 0.23,
      'animSpeedWarpX': 0.12, 'animSpeedWarpY': 0.14,
      'animAmpInput': 0.02, 'animAmpWarp': 0.02,
      'lightIntensity': 1.0,
      'smudgeRadius': 0.4, 'smudgeStrength': 0.5, 'smudgeFalloff': 3.0,
    },
    colors: {
      'bgColor': const Color(0xFF202329),
      'color0': const Color.fromRGBO(217, 212, 204, 1), // cream
      'color1': const Color.fromRGBO(140, 128, 115, 1), // tan
      'color2': const Color.fromRGBO(77, 64, 56, 1),    // brown
      'color3': const Color.fromRGBO(89, 115, 133, 1),  // teal
      'color4': const Color.fromRGBO(31, 36, 46, 1),    // dark
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'warp1Scale': const SliderRange('Warp 1 Scale', min: 0.5, max: 3.0),
    'warp2Scale': const SliderRange('Warp 2 Scale', min: 1.0, max: 8.0),
    'finalScale': const SliderRange('Final Scale', min: 1.0, max: 6.0),
    'warpStrength': const SliderRange('Warp Strength', min: 1.0, max: 15.0),
    'contrastPower': const SliderRange('Contrast Power', min: 1.0, max: 6.0),
    'finalContrast': const SliderRange('Final Contrast', min: 0.5, max: 2.0),
    'animSpeedInputX': const SliderRange('Anim Speed X', min: 0.0, max: 1.0),
    'animSpeedInputY': const SliderRange('Anim Speed Y', min: 0.0, max: 1.0),
    'animAmpInput': const SliderRange('Anim Amp Input', min: 0.0, max: 0.1),
    'animAmpWarp': const SliderRange('Anim Amp Warp', min: 0.0, max: 0.1),
    'lightIntensity': const SliderRange('Intensity', min: 0.0, max: 2.0),
    'smudgeRadius': const SliderRange('Smudge Radius', min: 0.1, max: 1.0),
    'smudgeStrength': const SliderRange('Smudge Strength', min: 0.1, max: 2.0),
    'smudgeFalloff': const SliderRange('Smudge Falloff', min: 0.5, max: 10.0),
  }),
  paramDescriptions: {
    'bgColor': 'Background fill color behind the marble',
    'warp1Scale': 'Scale of the first domain-warp layer',
    'warp2Scale': 'Scale of the second domain-warp layer',
    'finalScale': 'Scale of the final marble pattern',
    'warpStrength': 'Intensity of the domain warping distortion',
    'contrastPower': 'Contrast curve applied to marble veins',
    'finalContrast': 'Overall contrast of the final image',
    'animSpeedInputX': 'Horizontal animation speed of the input noise',
    'animSpeedInputY': 'Vertical animation speed of the input noise',
    'animSpeedWarpX': 'Horizontal animation speed of the warp noise',
    'animSpeedWarpY': 'Vertical animation speed of the warp noise',
    'animAmpInput': 'Amplitude of input noise animation',
    'animAmpWarp': 'Amplitude of warp noise animation',
    'color0': 'Lightest vein',
    'color1': 'Mid-tone base',
    'color2': 'Dark base',
    'color3': 'Accent edge',
    'color4': 'Valley shadow',
    'lightIntensity': 'Brightness of the surface lighting',
    'smudgeRadius': 'Radius of the touch-drag smudge brush',
    'smudgeStrength': 'Strength of the smudge distortion',
    'smudgeFalloff': 'Falloff curve of the smudge effect',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// RIPPLE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final rippleShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/ripple.frag',
  layout: UniformLayout([
    const UniformField.color('bgColor'),
    const UniformField('origin1X'),
    const UniformField('origin1Y'),
    const UniformField('origin2X'),
    const UniformField('origin2Y'),
    const UniformField('frequency'),
    const UniformField('numWaves'),
    const UniformField('amplitude'),
    const UniformField('speed'),
  ]),
  defaults: ShaderParams(
    values: {
      'frequency': 1.5, 'numWaves': 5.0, 'amplitude': 1.0, 'speed': 1.0,
      'origin1X': 1.0, 'origin1Y': -1.0,
      'origin2X': -1.0, 'origin2Y': 1.0,
      'originScale': 1.5,
    },
    colors: {
      'bgColor': const Color(0xFF202329),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'frequency': const SliderRange('Frequency', min: 0.5, max: 5.0),
    'numWaves': const SliderRange('Num Waves', min: 1.0, max: 15.0),
    'amplitude': const SliderRange('Amplitude', min: 0.1, max: 3.0),
    'speed': const SliderRange('Speed', min: 0.1, max: 3.0),
    'origin1X': const SliderRange('Origin X', min: -2.0, max: 2.0),
    'origin1Y': const SliderRange('Origin Y', min: -2.0, max: 2.0),
    'origin2X': const SliderRange('Origin X', min: -2.0, max: 2.0),
    'origin2Y': const SliderRange('Origin Y', min: -2.0, max: 2.0),
    'originScale': const SliderRange('Origin Scale', min: 0.5, max: 3.0),
  }),
  paramDescriptions: {
    'bgColor': 'Background color behind the ripple effect',
    'origin1X': 'Horizontal position of the first wave origin',
    'origin1Y': 'Vertical position of the first wave origin',
    'origin2X': 'Horizontal position of the second wave origin',
    'origin2Y': 'Vertical position of the second wave origin',
    'frequency': 'Wave frequency (number of ripples per unit)',
    'numWaves': 'Number of concentric wave rings',
    'amplitude': 'Height of the wave distortion',
    'speed': 'Propagation speed of the ripple waves',
    'originScale': 'Distance scale applied to wave origins',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// CLICK RIPPLE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final clickRippleShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/click_ripple.frag',
  layout: const UniformLayout([]),  // Click ripple has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'amplitude': 0.07, 'frequency': 15.0, 'decay': 4.0,
      'speed': 2.0, 'rippleDuration': 3.0,
    },
    colors: {
      'bgColor': const Color(0xFF202329),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'amplitude': const SliderRange('Amplitude', min: 0.01, max: 0.2),
    'frequency': const SliderRange('Frequency', min: 5.0, max: 40.0),
    'decay': const SliderRange('Decay', min: 1.0, max: 10.0),
    'speed': const SliderRange('Speed', min: 0.5, max: 5.0),
    'rippleDuration': const SliderRange('Duration', min: 1.0, max: 8.0),
  }),
  paramDescriptions: {
    'bgColor': 'Background color behind the ripple effect',
    'amplitude': 'Height of each tap ripple distortion',
    'frequency': 'Wave frequency of each tap ripple',
    'decay': 'How quickly each ripple fades out',
    'speed': 'Propagation speed of tap ripples',
    'rippleDuration': 'Lifetime of each tap ripple in seconds',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// BURN SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final burnShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/burn.frag',
  layout: const UniformLayout([]),  // Burn has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'angle': 90.0, 'scale': 1.0, 'offset': 0.0,
      'noiseScale': 8.85, 'edgeWidth': 0.18, 'glowIntensity': 3.56,
      'speed': 0.30,
    },
    colors: {
      'fireColor': const Color.fromRGBO(255, 127, 0, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.dissolveDirectionRanges,
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.0, max: 1.0),
    'glowIntensity': const SliderRange('Glow Intensity', min: 0.0, max: 5.0),
    'speed': const SliderRange('Speed', min: 0.01, max: 1.0),
  }),
  paramDescriptions: {
    ...ParamGroups.dissolveDirectionDescriptions,
    'noiseScale': 'Frequency scale of the burn edge noise',
    'edgeWidth': 'Width of the glowing burn edge',
    'glowIntensity': 'Brightness of the fire glow at the edge',
    'speed': 'Speed of the burn dissolve progression',
    'fireColor': 'Color of the fire glow at the burn edge',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// RADIAL BURN SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final radialBurnShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/radial_burn.frag',
  layout: const UniformLayout([]),  // Radial burn has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'burnCenterX': 0.83, 'burnCenterY': 0.81, 'burnScale': 0.78,
      'noiseScale': 3.82, 'edgeWidth': 0.50, 'glowIntensity': 4.41,
      'speed': 0.12,
    },
    colors: {
      'fireColor': const Color.fromRGBO(81, 77, 75, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'burnCenterX': const SliderRange('Center X', min: 0.0, max: 1.0),
    'burnCenterY': const SliderRange('Center Y', min: 0.0, max: 1.0),
    'burnScale': const SliderRange('Burn Scale', min: 0.5, max: 3.0),
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.0, max: 1.0),
    'glowIntensity': const SliderRange('Glow Intensity', min: 0.0, max: 5.0),
    'speed': const SliderRange('Speed', min: 0.01, max: 1.0),
  }),
  paramDescriptions: {
    'burnCenterX': 'Horizontal center of the radial burn origin',
    'burnCenterY': 'Vertical center of the radial burn origin',
    'burnScale': 'Radius scale of the radial burn',
    'noiseScale': 'Frequency scale of the burn edge noise',
    'edgeWidth': 'Width of the glowing burn edge',
    'glowIntensity': 'Brightness of the fire glow at the edge',
    'speed': 'Speed of the burn dissolve progression',
    'fireColor': 'Color of the fire glow at the burn edge',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// TAPPABLE BURN SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final tappableBurnShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/tappable_burn.frag',
  layout: const UniformLayout([]),  // Tappable burn has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'noiseScale': 18.29, 'edgeWidth': 1.0, 'glowIntensity': 4.01,
      'speed': 0.89, 'burnRadius': 0.16, 'burnLifetime': 1.55,
    },
    colors: {
      'fireColor': const Color.fromRGBO(255, 226, 198, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.0, max: 1.0),
    'glowIntensity': const SliderRange('Glow Intensity', min: 0.0, max: 5.0),
    'speed': const SliderRange('Speed', min: 0.1, max: 3.0),
    'burnRadius': const SliderRange('Burn Radius', min: 0.001, max: 3.0),
    'burnLifetime': const SliderRange('Lifetime', min: 1.0, max: 8.0),
  }),
  paramDescriptions: {
    'noiseScale': 'Frequency scale of the burn edge noise',
    'edgeWidth': 'Width of the glowing burn edge',
    'glowIntensity': 'Brightness of the fire glow at the edge',
    'speed': 'Speed of each tap burn expansion',
    'burnRadius': 'Radius of each tap burn spot',
    'burnLifetime': 'Lifetime of each tap burn in seconds',
    'fireColor': 'Color of the fire glow at the burn edge',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// SMOKE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final smokeShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/smoke.frag',
  layout: const UniformLayout([]),  // Smoke has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'angle': 90.0, 'scale': 1.0, 'offset': 0.0,
      'noiseScale': 6.0, 'edgeWidth': 0.25, 'glowIntensity': 2.5,
      'speed': 0.20,
    },
    colors: {
      'smokeColor': const Color.fromRGBO(200, 200, 210, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.dissolveDirectionRanges,
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.0, max: 1.0),
    'glowIntensity': const SliderRange('Glow Intensity', min: 0.0, max: 5.0),
    'speed': const SliderRange('Speed', min: 0.01, max: 1.0),
  }),
  paramDescriptions: {
    ...ParamGroups.dissolveDirectionDescriptions,
    'noiseScale': 'Frequency scale of the smoke edge noise',
    'edgeWidth': 'Width of the wispy smoke edge',
    'glowIntensity': 'Brightness of the smoke glow at the edge',
    'speed': 'Speed of the smoke dissolve progression',
    'smokeColor': 'Color of the smoke wisps at the dissolve edge',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// RADIAL SMOKE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final radialSmokeShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/radial_smoke.frag',
  layout: const UniformLayout([]),  // Radial smoke has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'burnCenterX': 0.50, 'burnCenterY': 0.50, 'burnScale': 1.0,
      'noiseScale': 5.0, 'edgeWidth': 0.40, 'glowIntensity': 2.8,
      'speed': 0.15,
    },
    colors: {
      'smokeColor': const Color.fromRGBO(180, 185, 195, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'burnCenterX': const SliderRange('Center X', min: 0.0, max: 1.0),
    'burnCenterY': const SliderRange('Center Y', min: 0.0, max: 1.0),
    'burnScale': const SliderRange('Burn Scale', min: 0.5, max: 3.0),
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.0, max: 1.0),
    'glowIntensity': const SliderRange('Glow Intensity', min: 0.0, max: 5.0),
    'speed': const SliderRange('Speed', min: 0.01, max: 1.0),
  }),
  paramDescriptions: {
    'burnCenterX': 'Horizontal center of the radial smoke origin',
    'burnCenterY': 'Vertical center of the radial smoke origin',
    'burnScale': 'Radius scale of the radial smoke',
    'noiseScale': 'Frequency scale of the smoke edge noise',
    'edgeWidth': 'Width of the wispy smoke edge',
    'glowIntensity': 'Brightness of the smoke glow at the edge',
    'speed': 'Speed of the smoke dissolve progression',
    'smokeColor': 'Color of the smoke wisps at the dissolve edge',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// TAPPABLE SMOKE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final tappableSmokeShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/tappable_smoke.frag',
  layout: const UniformLayout([]),  // Tappable smoke has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'noiseScale': 12.0, 'edgeWidth': 0.8, 'glowIntensity': 3.0,
      'speed': 0.70, 'burnRadius': 0.20, 'burnLifetime': 2.0,
    },
    colors: {
      'smokeColor': const Color.fromRGBO(220, 220, 230, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.0, max: 1.0),
    'glowIntensity': const SliderRange('Glow Intensity', min: 0.0, max: 5.0),
    'speed': const SliderRange('Speed', min: 0.1, max: 3.0),
    'burnRadius': const SliderRange('Burn Radius', min: 0.001, max: 3.0),
    'burnLifetime': const SliderRange('Lifetime', min: 1.0, max: 8.0),
  }),
  paramDescriptions: {
    'noiseScale': 'Frequency scale of the smoke edge noise',
    'edgeWidth': 'Width of the wispy smoke edge',
    'glowIntensity': 'Brightness of the smoke glow at the edge',
    'speed': 'Speed of each tap smoke expansion',
    'burnRadius': 'Radius of each tap smoke spot',
    'burnLifetime': 'Lifetime of each tap smoke in seconds',
    'smokeColor': 'Color of the smoke wisps at the dissolve edge',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// PIXEL DISSOLVE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final pixelDissolveShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/pixel_dissolve.frag',
  layout: const UniformLayout([]),  // Pixel dissolve has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'angle': 14.0, 'scale': 1.0, 'offset': 0.0,
      'pixelSize': 5.11, 'edgeWidth': 0.35,
      'scatter': 0.36, 'noiseAmount': 0.93,
      'speed': 0.21,
    },
    colors: {},
  ),
  uiDefaults: ShaderUIDefaults({
    ...ParamGroups.dissolveDirectionRanges,
    'pixelSize': const SliderRange('Pixel Size', min: 3.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.05, max: 1.0),
    'scatter': const SliderRange('Scatter', min: 0.0, max: 3.0),
    'noiseAmount': const SliderRange('Noise', min: 0.0, max: 1.0),
    'speed': const SliderRange('Speed', min: 0.01, max: 1.0),
  }),
  paramDescriptions: {
    ...ParamGroups.dissolveDirectionDescriptions,
    'pixelSize': 'Size of each dissolving pixel block',
    'edgeWidth': 'Width of the dissolve transition edge',
    'scatter': 'Randomness of pixel dissolve positions',
    'noiseAmount': 'Amount of noise added to the dissolve pattern',
    'speed': 'Speed of the pixel dissolve progression',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// RADIAL PIXEL DISSOLVE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final radialPixelDissolveShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/radial_pixel_dissolve.frag',
  layout: const UniformLayout([]),  // Radial pixel dissolve has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'centerX': 0.50, 'centerY': 0.50, 'scale': 1.0,
      'pixelSize': 5.11, 'edgeWidth': 0.35,
      'scatter': 0.36, 'noiseAmount': 0.93,
      'speed': 0.21,
    },
    colors: {},
  ),
  uiDefaults: ShaderUIDefaults({
    'centerX': const SliderRange('Center X', min: 0.0, max: 1.0),
    'centerY': const SliderRange('Center Y', min: 0.0, max: 1.0),
    'scale': const SliderRange('Scale', min: 0.5, max: 3.0),
    'pixelSize': const SliderRange('Pixel Size', min: 3.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.05, max: 1.0),
    'scatter': const SliderRange('Scatter', min: 0.0, max: 3.0),
    'noiseAmount': const SliderRange('Noise', min: 0.0, max: 1.0),
    'speed': const SliderRange('Speed', min: 0.01, max: 1.0),
  }),
  paramDescriptions: {
    'centerX': 'Horizontal center of the radial dissolve',
    'centerY': 'Vertical center of the radial dissolve',
    'scale': 'Radius scale of the radial dissolve',
    'pixelSize': 'Size of each dissolving pixel block',
    'edgeWidth': 'Width of the dissolve transition edge',
    'scatter': 'Randomness of pixel dissolve positions',
    'noiseAmount': 'Amount of noise added to the dissolve pattern',
    'speed': 'Speed of the pixel dissolve progression',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// TAPPABLE PIXEL DISSOLVE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final tappablePixelDissolveShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/tappable_pixel_dissolve.frag',
  layout: const UniformLayout([]),  // Tappable pixel dissolve has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'pixelSize': 5.11, 'edgeWidth': 0.35,
      'scatter': 0.36, 'noiseAmount': 0.93,
      'speed': 0.89, 'radius': 0.20, 'lifetime': 2.0,
    },
    colors: {},
  ),
  uiDefaults: ShaderUIDefaults({
    'pixelSize': const SliderRange('Pixel Size', min: 3.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.05, max: 1.0),
    'scatter': const SliderRange('Scatter', min: 0.0, max: 3.0),
    'noiseAmount': const SliderRange('Noise', min: 0.0, max: 1.0),
    'speed': const SliderRange('Speed', min: 0.1, max: 3.0),
    'radius': const SliderRange('Radius', min: 0.001, max: 3.0),
    'lifetime': const SliderRange('Lifetime', min: 1.0, max: 8.0),
  }),
  paramDescriptions: {
    'pixelSize': 'Size of each dissolving pixel block',
    'edgeWidth': 'Width of the dissolve transition edge',
    'scatter': 'Randomness of pixel dissolve positions',
    'noiseAmount': 'Amount of noise added to the dissolve pattern',
    'speed': 'Speed of each tap dissolve expansion',
    'radius': 'Radius of each tap dissolve spot',
    'lifetime': 'Lifetime of each tap dissolve in seconds',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// TAPPABLE SLURP
// ═══════════════════════════════════════════════════════════════════════════════

final tappableSlurpShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/tappable_slurp.frag',
  layout: const UniformLayout([]),  // Tappable slurp has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'gravity': 0.52, 'easing': 8.27,
      'wrinkles': 7.23, 'wrinkleDepth': 0.36, 'foldShading': 0.74,
      'speed': 0.70, 'lifetime': 3.0,
    },
    colors: {},
  ),
  uiDefaults: ShaderUIDefaults({
    'gravity': const SliderRange('Gravity', min: 0.0, max: 1.0),
    'easing': const SliderRange('Easing', min: 1.0, max: 20.0),
    'wrinkles': const SliderRange('Wrinkles', min: 0.0, max: 20.0),
    'wrinkleDepth': const SliderRange('Wrinkle Depth', min: 0.0, max: 0.5),
    'foldShading': const SliderRange('Fold Shading', min: 0.0, max: 1.0),
    'speed': const SliderRange('Speed', min: 0.1, max: 3.0),
    'lifetime': const SliderRange('Lifetime', min: 1.0, max: 8.0),
  }),
  paramDescriptions: {
    'gravity': 'Strength of the slurp effect',
    'easing': 'Easing curve steepness for the suction animation',
    'wrinkles': 'Number of radial wrinkle folds',
    'wrinkleDepth': 'Depth of the wrinkle fold distortion',
    'foldShading': 'Shading intensity on wrinkle folds',
    'speed': 'Speed of each tap slurp animation',
    'lifetime': 'Lifetime of each tap slurp in seconds',
  },
  stableVersion: '1.2.0',
);

// ═══════════════════════════════════════════════════════════════════════════════
// FUR PLANAR SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final furPlanarShaderDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/fur_planar.frag',
  layout: UniformLayout([
    const UniformField.color('bgColor'),
    const UniformField('planeOffset'),
    const UniformField('furThickness'),
    const UniformField('furNoiseStrength'),
    const UniformField('furNoiseScale'),
    const UniformField('furWaveAmplitude'),
    const UniformField('furWaveFreqX'),
    const UniformField('furWaveFreqY'),
    const UniformField('furAnimationSpeed'),
    const UniformField('keyLightDirX'),
    const UniformField('keyLightDirY'),
    const UniformField('keyLightDirZ'),
    const UniformField.color('keyLightColor'),
    const UniformField('keyLightIntensity'),
    const UniformField('fillLightDirX'),
    const UniformField('fillLightDirY'),
    const UniformField('fillLightDirZ'),
    const UniformField.color('fillLightColor'),
    const UniformField('fillLightIntensity'),
    const UniformField('rimLightDirX'),
    const UniformField('rimLightDirY'),
    const UniformField('rimLightDirZ'),
    const UniformField.color('rimLightColor'),
    const UniformField('rimLightIntensity'),
    const UniformField.color('furColor'),
    const UniformField('gradientEps'),
    const UniformField('waveletSpeed'),
    const UniformField('waveletFreq'),
    const UniformField('waveletAmplitude'),
    const UniformField('waveletDecay'),
    const UniformField('waveletWidth'),
  ]),
  defaults: ShaderParams(
    values: {
      'planeOffset': 0.0, 'furThickness': 0.30,
      'furNoiseStrength': 0.10, 'furNoiseScale': 50.0,
      'furWaveAmplitude': 0.04, 'furWaveFreqX': 4.0, 'furWaveFreqY': 15.0,
      'furAnimationSpeed': 3.0,
      'keyLightDirX': 1.28, 'keyLightDirY': -0.17, 'keyLightDirZ': -1.16,
      'keyLightIntensity': 0.37,
      'fillLightDirX': -0.80, 'fillLightDirY': -0.20, 'fillLightDirZ': -70.00,
      'fillLightIntensity': 0.21,
      'rimLightDirX': -0.69, 'rimLightDirY': -3.38, 'rimLightDirZ': 3.26,
      'rimLightIntensity': 0.46,
      'gradientEps': 0.07,
      'waveletSpeed': 1.43, 'waveletFreq': 6.98,
      'waveletAmplitude': 0.10, 'waveletDecay': 1.76, 'waveletWidth': 0.59,
    },
    colors: {
      'bgColor': const Color(0xFF202329),
      'keyLightColor': const Color.fromRGBO(255, 242, 230, 1),
      'fillLightColor': const Color.fromRGBO(230, 242, 255, 1),
      'rimLightColor': const Color.fromRGBO(255, 255, 255, 1),
      'furColor': const Color.fromRGBO(255, 230, 204, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'planeOffset': const SliderRange('Plane Offset', min: -2.0, max: 2.0),
    'furThickness': const SliderRange('Thickness', min: 0.05, max: 0.8),
    'furNoiseStrength': const SliderRange('Noise Strength', min: 0.0, max: 0.3),
    'furNoiseScale': const SliderRange('Noise Scale', min: 30.0, max: 80.0),
    'furWaveAmplitude': const SliderRange('Wave Amp', min: 0.0, max: 0.15),
    'furWaveFreqX': const SliderRange('Wave Freq X', min: 0.0, max: 20.0),
    'furWaveFreqY': const SliderRange('Wave Freq Y', min: 0.0, max: 30.0),
    'furAnimationSpeed': const SliderRange('Anim Speed', min: 0.0, max: 10.0),
    'gradientEps': const SliderRange('Gradient Eps', min: 0.01, max: 0.2),
    'keyLightDirX': const SliderRange('Key X', min: -5.0, max: 5.0),
    'keyLightDirY': const SliderRange('Key Y', min: -5.0, max: 5.0),
    'keyLightDirZ': const SliderRange('Key Z', min: -5.0, max: 5.0),
    'keyLightIntensity': const SliderRange('Key Intensity', min: 0.0, max: 1.0),
    'fillLightDirX': const SliderRange('Fill X', min: -5.0, max: 5.0),
    'fillLightDirY': const SliderRange('Fill Y', min: -5.0, max: 5.0),
    'fillLightDirZ': const SliderRange('Fill Z', min: -5.0, max: 5.0),
    'fillLightIntensity': const SliderRange('Fill Intensity', min: 0.0, max: 0.5),
    'rimLightDirX': const SliderRange('Rim X', min: -5.0, max: 5.0),
    'rimLightDirY': const SliderRange('Rim Y', min: -5.0, max: 5.0),
    'rimLightDirZ': const SliderRange('Rim Z', min: -5.0, max: 5.0),
    'rimLightIntensity': const SliderRange('Rim Intensity', min: 0.0, max: 0.5),
    'waveletSpeed': const SliderRange('Wavelet Speed', min: 0.5, max: 5.0),
    'waveletFreq': const SliderRange('Wavelet Freq', min: 5.0, max: 30.0),
    'waveletAmplitude': const SliderRange('Wavelet Amp', min: 0.0, max: 0.3),
    'waveletDecay': const SliderRange('Wavelet Decay', min: 0.3, max: 3.0),
    'waveletWidth': const SliderRange('Wavelet Width', min: 0.1, max: 1.0),
  }),
  paramDescriptions: {
    'planeOffset': 'Z-offset of the fur plane from the camera',
    'furThickness': 'Thickness of the fur layer',
    'furNoiseStrength': 'Strength of procedural noise on fur strands',
    'furNoiseScale': 'Scale of fur noise (higher = thinner hairs)',
    'furWaveAmplitude': 'Amplitude of the fur wave animation',
    'furWaveFreqX': 'Horizontal wave frequency',
    'furWaveFreqY': 'Vertical wave frequency',
    'furAnimationSpeed': 'Speed of the fur wave animation',
    'keyLightDirX': 'Key light direction X',
    'keyLightDirY': 'Key light direction Y',
    'keyLightDirZ': 'Key light direction Z',
    'keyLightIntensity': 'Key light brightness',
    'fillLightDirX': 'Fill light direction X',
    'fillLightDirY': 'Fill light direction Y',
    'fillLightDirZ': 'Fill light direction Z',
    'fillLightIntensity': 'Fill light brightness',
    'rimLightDirX': 'Rim light direction X',
    'rimLightDirY': 'Rim light direction Y',
    'rimLightDirZ': 'Rim light direction Z',
    'rimLightIntensity': 'Rim light brightness',
    'gradientEps': 'Epsilon for normal estimation',
    'waveletSpeed': 'Propagation speed of tap wavelets',
    'waveletFreq': 'Frequency of wavelet oscillations',
    'waveletAmplitude': 'Amplitude of wavelet displacement',
    'waveletDecay': 'Exponential decay rate of wavelets',
    'waveletWidth': 'Width of the wavelet ring',
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// FUR PLANAR MASKED SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final furPlanarMaskedShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/fur_planar_mask.frag',
  layout: UniformLayout([
    const UniformField.color('bgColor'),
    const UniformField('planeOffset'),
    const UniformField('furThickness'),
    const UniformField('furNoiseStrength'),
    const UniformField('furNoiseScale'),
    const UniformField('furWaveAmplitude'),
    const UniformField('furWaveFreqX'),
    const UniformField('furWaveFreqY'),
    const UniformField('furAnimationSpeed'),
    const UniformField('keyLightDirX'),
    const UniformField('keyLightDirY'),
    const UniformField('keyLightDirZ'),
    const UniformField.color('keyLightColor'),
    const UniformField('keyLightIntensity'),
    const UniformField('fillLightDirX'),
    const UniformField('fillLightDirY'),
    const UniformField('fillLightDirZ'),
    const UniformField.color('fillLightColor'),
    const UniformField('fillLightIntensity'),
    const UniformField('rimLightDirX'),
    const UniformField('rimLightDirY'),
    const UniformField('rimLightDirZ'),
    const UniformField.color('rimLightColor'),
    const UniformField('rimLightIntensity'),
    const UniformField.color('furColor'),
    const UniformField('gradientEps'),
    const UniformField('waveletSpeed'),
    const UniformField('waveletFreq'),
    const UniformField('waveletAmplitude'),
    const UniformField('waveletDecay'),
    const UniformField('waveletWidth'),
    const UniformField.color('maskColor'),
    const UniformField('maskThreshold'),
    const UniformField('edgeLeanStrength'),
  ]),
  defaults: ShaderParams(
    values: {
      'planeOffset': -0.96, 'furThickness': 0.24,
      'furNoiseStrength': 0.10, 'furNoiseScale': 50.0,
      'furWaveAmplitude': 0.04, 'furWaveFreqX': 4.0, 'furWaveFreqY': 15.0,
      'furAnimationSpeed': 3.0,
      'keyLightDirX': 1.28, 'keyLightDirY': -0.17, 'keyLightDirZ': -1.16,
      'keyLightIntensity': 0.37,
      'fillLightDirX': -0.80, 'fillLightDirY': -0.20, 'fillLightDirZ': -70.00,
      'fillLightIntensity': 0.21,
      'rimLightDirX': -0.69, 'rimLightDirY': -3.38, 'rimLightDirZ': 3.26,
      'rimLightIntensity': 0.46,
      'gradientEps': 0.07,
      'waveletSpeed': 1.43, 'waveletFreq': 6.98,
      'waveletAmplitude': 0.10, 'waveletDecay': 1.76, 'waveletWidth': 0.59,
      'maskThreshold': 0.16, 'edgeLeanStrength': 0.07,
    },
    colors: {
      'bgColor': const Color(0xFF202329),
      'keyLightColor': const Color.fromRGBO(255, 255, 255, 1),
      'fillLightColor': const Color.fromRGBO(230, 242, 255, 1),
      'rimLightColor': const Color.fromRGBO(255, 255, 255, 1),
      'furColor': const Color.fromRGBO(122, 235, 95, 1),
      'maskColor': const Color.fromRGBO(0, 0, 0, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'planeOffset': const SliderRange('Plane Offset', min: -2.0, max: 2.0),
    'furThickness': const SliderRange('Thickness', min: 0.05, max: 0.8),
    'furNoiseStrength': const SliderRange('Noise Strength', min: 0.0, max: 0.3),
    'furNoiseScale': const SliderRange('Noise Scale', min: 30.0, max: 80.0),
    'furWaveAmplitude': const SliderRange('Wave Amp', min: 0.0, max: 0.15),
    'furWaveFreqX': const SliderRange('Wave Freq X', min: 0.0, max: 20.0),
    'furWaveFreqY': const SliderRange('Wave Freq Y', min: 0.0, max: 30.0),
    'furAnimationSpeed': const SliderRange('Anim Speed', min: 0.0, max: 10.0),
    'gradientEps': const SliderRange('Gradient Eps', min: 0.01, max: 0.2),
    'keyLightDirX': const SliderRange('Key X', min: -5.0, max: 5.0),
    'keyLightDirY': const SliderRange('Key Y', min: -5.0, max: 5.0),
    'keyLightDirZ': const SliderRange('Key Z', min: -5.0, max: 5.0),
    'keyLightIntensity': const SliderRange('Key Intensity', min: 0.0, max: 1.0),
    'fillLightDirX': const SliderRange('Fill X', min: -5.0, max: 5.0),
    'fillLightDirY': const SliderRange('Fill Y', min: -5.0, max: 5.0),
    'fillLightDirZ': const SliderRange('Fill Z', min: -5.0, max: 5.0),
    'fillLightIntensity': const SliderRange('Fill Intensity', min: 0.0, max: 0.5),
    'rimLightDirX': const SliderRange('Rim X', min: -5.0, max: 5.0),
    'rimLightDirY': const SliderRange('Rim Y', min: -5.0, max: 5.0),
    'rimLightDirZ': const SliderRange('Rim Z', min: -5.0, max: 5.0),
    'rimLightIntensity': const SliderRange('Rim Intensity', min: 0.0, max: 0.5),
    'waveletSpeed': const SliderRange('Wavelet Speed', min: 0.5, max: 5.0),
    'waveletFreq': const SliderRange('Wavelet Freq', min: 5.0, max: 30.0),
    'waveletAmplitude': const SliderRange('Wavelet Amp', min: 0.0, max: 0.3),
    'waveletDecay': const SliderRange('Wavelet Decay', min: 0.3, max: 3.0),
    'waveletWidth': const SliderRange('Wavelet Width', min: 0.1, max: 1.0),
    'maskThreshold': const SliderRange('Mask Threshold', min: 0.0, max: 1.0),
    'edgeLeanStrength': const SliderRange('Edge Lean', min: 0.0, max: 0.5),
  }),
  paramDescriptions: {
    'planeOffset': 'Z-offset of the fur plane from the camera',
    'furThickness': 'Thickness of the fur layer',
    'furNoiseStrength': 'Strength of procedural noise on fur strands',
    'furNoiseScale': 'Scale of fur noise (higher = thinner hairs)',
    'furWaveAmplitude': 'Amplitude of the fur wave animation',
    'furWaveFreqX': 'Horizontal wave frequency',
    'furWaveFreqY': 'Vertical wave frequency',
    'furAnimationSpeed': 'Speed of the fur wave animation',
    'keyLightDirX': 'Key light direction X',
    'keyLightDirY': 'Key light direction Y',
    'keyLightDirZ': 'Key light direction Z',
    'keyLightIntensity': 'Key light brightness',
    'fillLightDirX': 'Fill light direction X',
    'fillLightDirY': 'Fill light direction Y',
    'fillLightDirZ': 'Fill light direction Z',
    'fillLightIntensity': 'Fill light brightness',
    'rimLightDirX': 'Rim light direction X',
    'rimLightDirY': 'Rim light direction Y',
    'rimLightDirZ': 'Rim light direction Z',
    'rimLightIntensity': 'Rim light brightness',
    'gradientEps': 'Epsilon for normal estimation',
    'waveletSpeed': 'Propagation speed of tap wavelets',
    'waveletFreq': 'Frequency of wavelet oscillations',
    'waveletAmplitude': 'Amplitude of wavelet displacement',
    'waveletDecay': 'Exponential decay rate of wavelets',
    'waveletWidth': 'Width of the wavelet ring',
    'maskThreshold': 'Color distance threshold for mask matching',
    'edgeLeanStrength': 'How much fur leans outward at mask edges',
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// TURBULENCE MASK (wrap shader)
// ═══════════════════════════════════════════════════════════════════════════════

final turbulenceMaskShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/turbulence_mask.frag',
  layout: UniformLayout([
    const UniformField('octaves'),
    const UniformField('baseFrequency'),
    const UniformField('noiseScale'),
    const UniformField('animSpeed'),
    const UniformField('displacementStrength'),
  ]),
  defaults: ShaderParams(
    values: {
      'octaves': 5.0,
      'baseFrequency': 2.26,
      'noiseScale': 16.26,
      'animSpeed': 1.86,
      'displacementStrength': 0.05,
    },
    colors: {},
  ),
  uiDefaults: ShaderUIDefaults({
    'octaves': const SliderRange('Octaves', min: 1.0, max: 8.0),
    'baseFrequency': const SliderRange('Base Freq', min: 0.5, max: 4.0),
    'noiseScale': const SliderRange('Noise Scale', min: 0.5, max: 30.0),
    'animSpeed': const SliderRange('Anim Speed', min: 0.0, max: 3.0),
    'displacementStrength': const SliderRange('Displacement', min: 0.0, max: 0.1),
  }),
  paramDescriptions: {
    'octaves': 'Number of turbulence layers summed together',
    'baseFrequency': 'Base frequency of the turbulence pattern',
    'noiseScale': 'Frequency scale of the turbulence noise in UV space',
    'animSpeed': 'Speed multiplier for noise evolution over time',
    'displacementStrength': 'Maximum UV displacement strength',
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// DITHER WRAP
// ═══════════════════════════════════════════════════════════════════════════════

final ditherWrapShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/dither_wrap.frag',
  layout: UniformLayout([
    const UniformField('ditherScale'),
    const UniformField('colorSteps'),
  ]),
  defaults: ShaderParams(
    values: {
      'ditherScale': 0.4,
      'colorSteps': 4.0,
    },
    colors: {},
  ),
  uiDefaults: ShaderUIDefaults({
    'ditherScale': const SliderRange('Dither Scale', min: 0.05, max: 1.0),
    'colorSteps': const SliderRange('Color Steps', min: 1.0, max: 16.0),
  }),
  paramDescriptions: {
    'ditherScale': 'Cell size for dither grid (lower = larger pixels)',
    'colorSteps': 'Number of discrete luminance levels for quantization',
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// PEEL WRAP
// ═══════════════════════════════════════════════════════════════════════════════

final peelWrapShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/peel_wrap.frag',
  layout: UniformLayout([
    const UniformField('curlRadius'),
    const UniformField('shadowStrength'),
  ]),
  defaults: ShaderParams(
    values: {
      'curlRadius': 80.0,
      'shadowStrength': 0.5,
    },
    colors: {},
  ),
  uiDefaults: ShaderUIDefaults({
    'curlRadius': const SliderRange('Curl Radius', min: 10.0, max: 200.0),
    'shadowStrength': const SliderRange('Shadow', min: 0.0, max: 1.0),
  }),
  paramDescriptions: {
    'curlRadius': 'Radius of the curl cylinder in pixels',
    'shadowStrength': 'Darkness of shadow behind the curl',
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// CREPUSCULAR RAYS (God Rays) WRAP
// ═══════════════════════════════════════════════════════════════════════════════

final crepuscularRaysShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/crepuscular_rays.frag',
  layout: UniformLayout([
    const UniformField('sunPosX'),
    const UniformField('sunPosY'),
    const UniformField('sunRadius'),
    const UniformField('exposure'),
    const UniformField('decay'),
    const UniformField('density'),
    const UniformField('weight'),
    const UniformField('orbitRadius'),
    const UniformField('orbitSpeed'),
    const UniformField('showSun'),
    const UniformField.color('sunColor'),
    const UniformField.color('sunDiscColor'),
    const UniformField.colorRgba('passColor'),
  ]),
  defaults: ShaderParams(
    values: {
      'sunPosX': 0.52,
      'sunPosY': 0.43,
      'sunRadius': 0.15,
      'exposure': 0.27,
      'decay': 0.95,
      'density': 1.40,
      'weight': 0.26,
      'orbitRadius': 0.14,
      'orbitSpeed': 0.28,
      'showSun': 1.0,
    },
    colors: {
      'sunColor': const Color.fromRGBO(255, 217, 140, 1),
      'sunDiscColor': const Color.fromRGBO(255, 245, 220, 1),
      'passColor': const Color.fromRGBO(0, 0, 0, 0),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'sunPosX': const SliderRange('Sun X', min: 0.0, max: 1.0),
    'sunPosY': const SliderRange('Sun Y', min: 0.0, max: 1.0),
    'sunRadius': const SliderRange('Sun Radius', min: 0.0, max: 0.4),
    'exposure': const SliderRange('Exposure', min: 0.0, max: 1.5),
    'decay': const SliderRange('Decay', min: 0.85, max: 1.0),
    'density': const SliderRange('Density', min: 0.1, max: 2.0),
    'weight': const SliderRange('Weight', min: 0.0, max: 1.0),
    'orbitRadius': const SliderRange('Orbit Radius', min: 0.0, max: 0.3),
    'orbitSpeed': const SliderRange('Orbit Speed', min: 0.0, max: 1.5),
    'showSun': const SliderRange('Show Sun', min: 0.0, max: 1.0),
  }),
  paramDescriptions: {
    'sunPosX': 'Horizontal anchor of the sun in UV space',
    'sunPosY': 'Vertical anchor of the sun in UV space',
    'sunRadius': 'Soft sun disc radius in screen units',
    'exposure': 'Overall brightness of the rays',
    'decay': 'Per-step falloff along each ray (higher = longer rays)',
    'density': 'Step length along each ray (higher = rays spread further)',
    'weight': 'Per-sample contribution to the accumulated ray sum',
    'orbitRadius': 'Amplitude of the sun orbit around its anchor (0 = pinned)',
    'orbitSpeed': 'Angular speed of the sun orbit in radians per second',
    'showSun':
        'Opacity of the explicit sun disc drawn behind the wrapped widget',
    'sunColor': 'Tint of the sunlight passing through the mask',
    'sunDiscColor': 'Tint of the explicit sun disc overlay',
    'passColor':
        'Color that counts as "light passes" in the mask. Transparent (alpha=0, default) uses the classic alpha-driven mask — partial pass for semi-transparent pixels. Any non-transparent color requires an exact match to pass (all-or-nothing); everything else blocks.',
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// KUWAHARA WRAP (anisotropic painterly filter)
// ═══════════════════════════════════════════════════════════════════════════════

final kuwaharaShaderDef = ShaderDefinition(
  hasChildren: true,
  assetPath: 'packages/material_palette/shaders/kuwahara.frag',
  layout: UniformLayout([
    const UniformField('kernelRadius'),
    const UniformField('sharpness'),
  ]),
  defaults: ShaderParams(
    values: {
      'kernelRadius': 6.0,
      'sharpness': 25.0,
    },
    colors: {},
  ),
  uiDefaults: ShaderUIDefaults({
    'kernelRadius': const SliderRange('Kernel Radius', min: 1.0, max: 16.0),
    'sharpness': const SliderRange('Sharpness', min: 1.0, max: 50.0),
  }),
  paramDescriptions: {
    'kernelRadius':
        'Brush size in pixels (1 = subtle smoothing, 16 = pronounced painterly strokes). Higher values are more expensive — each +1 adds a ring of sector samples',
    'sharpness':
        'Anisotropic ellipse bias. Higher values keep the kernel rounder (more uniform blobs); lower values allow strong elongation along detected edges (streak-like brush strokes)',
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// LIQUID METAL (procedural fill — domain-warped FBM + heightfield shading)
// ═══════════════════════════════════════════════════════════════════════════════

final liquidMetalShaderDef = ShaderDefinition(
  hasChildren: false,
  assetPath: 'packages/material_palette/shaders/liquid_metal.frag',
  layout: UniformLayout([
    // Pattern / animation
    const UniformField('rotAngle'),
    const UniformField('patternScale'),
    const UniformField('timeScale'),
    const UniformField('warpFreqInner'),
    const UniformField('warpFreqMiddle'),
    const UniformField('warpFreqHigh'),
    // Lighting
    const UniformField('sampleEps'),
    const UniformField('ambientGain'),
    const UniformField('rimGain'),
    // Edge glow
    const UniformField('edgeGain'),
    const UniformField.color('edgeTint'),
    const UniformField.color('lumaWeights'),
    // Palette
    const UniformField('paletteStops'),
    const UniformField.colorRgba('color0'),
    const UniformField.colorRgba('color1'),
    const UniformField.colorRgba('color2'),
    const UniformField.colorRgba('color3'),
    const UniformField.colorRgba('color4'),
    const UniformField.colorRgba('color5'),
    const UniformField.colorRgba('color6'),
    const UniformField.colorRgba('color7'),
    const UniformField.colorRgba('color8'),
    const UniformField.colorRgba('color9'),
  ]),
  defaults: ShaderParams(
    values: {
      'rotAngle': 0.78,
      'patternScale': 1.0,
      'timeScale': 0.05,
      'warpFreqInner': 3.0,
      'warpFreqMiddle': 2.0,
      'warpFreqHigh': 1.3,
      'sampleEps': 0.005,
      'ambientGain': 0.2,
      'rimGain': 0.05,
      'edgeGain': 7.0,
      'paletteStops': 3.0,
    },
    colors: {
      'edgeTint': const Color.fromRGBO(255, 179, 153, 1.0),
      'lumaWeights': const Color.fromRGBO(54, 182, 18, 1.0),
      'color0': const Color.fromRGBO(0, 0, 77, 1.0),
      'color1': const Color.fromRGBO(97, 0, 0, 1.0),
      'color2': const Color.fromRGBO(255, 189, 77, 1.0),
      'color3': const Color.fromRGBO(140, 31, 20, 1.0),
      'color4': const Color.fromRGBO(230, 102, 38, 1.0),
      'color5': const Color.fromRGBO(255, 191, 89, 1.0),
      'color6': const Color.fromRGBO(255, 235, 153, 1.0),
      'color7': const Color.fromRGBO(255, 247, 217, 1.0),
      'color8': const Color.fromRGBO(179, 204, 255, 1.0),
      'color9': const Color.fromRGBO(64, 89, 140, 1.0),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'rotAngle': const SliderRange('Rotation', min: 0.0, max: 6.28318),
    'patternScale': const SliderRange('Pattern Scale', min: 0.2, max: 4.0),
    'timeScale': const SliderRange('Flow Speed', min: 0.0, max: 0.5),
    'warpFreqInner':
        const SliderRange('Warp Freq (Inner)', min: 0.5, max: 8.0),
    'warpFreqMiddle':
        const SliderRange('Warp Freq (Middle)', min: 0.5, max: 6.0),
    'warpFreqHigh':
        const SliderRange('Warp Freq (Outer)', min: 0.3, max: 4.0),
    'sampleEps': const SliderRange('Bump Eps', min: 0.0005, max: 0.02),
    'ambientGain': const SliderRange('Ambient', min: 0.0, max: 1.0),
    'rimGain': const SliderRange('Rim', min: 0.0, max: 0.5),
    'edgeGain': const SliderRange('Edge Glow', min: 0.0, max: 20.0),
    'paletteStops': const SliderRange('Palette Stops', min: 2.0, max: 10.0),
  }),
  paramDescriptions: {
    'rotAngle':
        'Rotation angle (radians) of the FBM lattice per octave. Changes the overall grain direction of the noise',
    'patternScale':
        'Global zoom on the noise pattern. Smaller values produce coarser, larger features',
    'timeScale':
        'Animation flow speed; two warp layers counter-drift at ±this rate. 0 freezes the pattern',
    'warpFreqInner':
        'Frequency of the innermost (fastest) domain-warp layer',
    'warpFreqMiddle': 'Frequency of the middle domain-warp layer',
    'warpFreqHigh':
        'Frequency of the outermost (slowest) domain-warp layer',
    'sampleEps':
        'Offset used when sampling the forward-difference normal. Smaller values produce bumpier-looking surfaces',
    'ambientGain':
        'Strength of the quadratic ambient lift applied to upward-facing normals',
    'rimGain':
        'Strength of the cubic rim-highlight applied on top of the ambient lift',
    'edgeGain':
        'Intensity multiplier on the edge/ridge highlight (a 3-sample luminance edge detector)',
    'edgeTint':
        'Colour of the edge/ridge highlight that reads as glowing cracks',
    'lumaWeights':
        'Perceptual luminance weights used for the heightfield. RGB channels map to R/G/B weights (default: Rec. 709)',
    'paletteStops':
        'Number of active palette stops; the first N of color0..color9 are interpolated across the pattern. Clamped to [2, 10]',
    'color0': 'Palette stop 0 (deepest shadow)',
    'color1': 'Palette stop 1',
    'color2': 'Palette stop 2',
    'color3': 'Palette stop 3',
    'color4': 'Palette stop 4',
    'color5': 'Palette stop 5',
    'color6': 'Palette stop 6',
    'color7': 'Palette stop 7',
    'color8': 'Palette stop 8',
    'color9': 'Palette stop 9 (brightest highlight)',
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// REGISTRY: maps ShaderMaterialType → ShaderDefinition
// ═══════════════════════════════════════════════════════════════════════════════

/// Maps each ShaderMaterialType to its definition.
/// Only contains the 14 material types (excludes interactive-only shaders).
Map<ShaderMaterialType, ShaderDefinition> get shaderDefinitions => {
  ShaderMaterialType.grittyGradient: grittyGradientDef,
  ShaderMaterialType.radialGrittyGradient: radialGrittyGradientDef,
  ShaderMaterialType.perlinGradient: perlinGradientDef,
  ShaderMaterialType.radialPerlinGradient: radialPerlinGradientDef,
  ShaderMaterialType.simplexGradient: simplexGradientDef,
  ShaderMaterialType.radialSimplexGradient: radialSimplexGradientDef,
  ShaderMaterialType.fbmGradient: fbmGradientDef,
  ShaderMaterialType.radialFbmGradient: radialFbmGradientDef,
  ShaderMaterialType.turbulenceGradient: turbulenceGradientDef,
  ShaderMaterialType.radialTurbulenceGradient: radialTurbulenceGradientDef,
  ShaderMaterialType.voronoiGradient: voronoiGradientDef,
  ShaderMaterialType.radialVoronoiGradient: radialVoronoiGradientDef,
  ShaderMaterialType.voronoiseGradient: voronoiseGradientDef,
  ShaderMaterialType.radialVoronoiseGradient: radialVoronoiseGradientDef,
};

/// Maps shader card names to their definitions.
Map<String, ShaderDefinition> get shaderDefinitionsByName => {
  ShaderNames.gritient: grittyGradientDef,
  ShaderNames.radient: radialGrittyGradientDef,
  ShaderNames.perlin: perlinGradientDef,
  ShaderNames.radialPerlin: radialPerlinGradientDef,
  ShaderNames.simplex: simplexGradientDef,
  ShaderNames.radialSimplex: radialSimplexGradientDef,
  ShaderNames.fbm: fbmGradientDef,
  ShaderNames.radialFbm: radialFbmGradientDef,
  ShaderNames.turbulence: turbulenceGradientDef,
  ShaderNames.radialTurbulence: radialTurbulenceGradientDef,
  ShaderNames.voronoi: voronoiGradientDef,
  ShaderNames.radialVoronoi: radialVoronoiGradientDef,
  ShaderNames.voronoise: voronoiseGradientDef,
  ShaderNames.radialVoronoise: radialVoronoiseGradientDef,
  ShaderNames.smarble: marbleSmearShaderDef,
  ShaderNames.ripples: rippleShaderDef,
  ShaderNames.taplets: clickRippleShaderDef,
  ShaderNames.burn: burnShaderDef,
  ShaderNames.radialBurn: radialBurnShaderDef,
  ShaderNames.tapBurn: tappableBurnShaderDef,
  ShaderNames.smoke: smokeShaderDef,
  ShaderNames.radialSmoke: radialSmokeShaderDef,
  ShaderNames.tapSmoke: tappableSmokeShaderDef,
  ShaderNames.pixelDissolve: pixelDissolveShaderDef,
  ShaderNames.radialPixelDissolve: radialPixelDissolveShaderDef,
  ShaderNames.tapPixelDissolve: tappablePixelDissolveShaderDef,
  ShaderNames.tapSlurp: tappableSlurpShaderDef,
  ShaderNames.furPlanar: furPlanarShaderDef,
  ShaderNames.furPlanarMask: furPlanarMaskedShaderDef,
  ShaderNames.turbulenceMask: turbulenceMaskShaderDef,
  ShaderNames.ditherWrap: ditherWrapShaderDef,
  ShaderNames.peelWrap: peelWrapShaderDef,
  ShaderNames.crepuscularRays: crepuscularRaysShaderDef,
  ShaderNames.kuwaharaWrap: kuwaharaShaderDef,
  ShaderNames.liquidMetal: liquidMetalShaderDef,
};

/// Canonical list of all shader names in display order.
const List<String> allShaderNames = [
  ShaderNames.gritient,
  ShaderNames.radient,
  ShaderNames.perlin,
  ShaderNames.radialPerlin,
  ShaderNames.simplex,
  ShaderNames.radialSimplex,
  ShaderNames.fbm,
  ShaderNames.radialFbm,
  ShaderNames.turbulence,
  ShaderNames.radialTurbulence,
  ShaderNames.voronoi,
  ShaderNames.radialVoronoi,
  ShaderNames.voronoise,
  ShaderNames.radialVoronoise,
  ShaderNames.smarble,
  ShaderNames.ripples,
  ShaderNames.taplets,
  ShaderNames.burn,
  ShaderNames.radialBurn,
  ShaderNames.tapBurn,
  ShaderNames.smoke,
  ShaderNames.radialSmoke,
  ShaderNames.tapSmoke,
  ShaderNames.pixelDissolve,
  ShaderNames.radialPixelDissolve,
  ShaderNames.tapPixelDissolve,
  ShaderNames.tapSlurp,
  ShaderNames.furPlanar,
  ShaderNames.furPlanarMask,
  ShaderNames.turbulenceMask,
  ShaderNames.ditherWrap,
  ShaderNames.peelWrap,
  ShaderNames.crepuscularRays,
  ShaderNames.kuwaharaWrap,
  ShaderNames.liquidMetal,
];

/// Every unique parameter name string used across all shader definitions.
const List<String> allParamNames = [
  'ambient',
  'ambientGain',
  'amplitude',
  'angle',
  'animAmpInput',
  'animAmpWarp',
  'animSpeed',
  'animSpeedInputX',
  'animSpeedInputY',
  'animSpeedWarpX',
  'animSpeedWarpY',
  'baseFrequency',
  'bgColor',
  'bumpStrength',
  'burnCenterX',
  'burnCenterY',
  'burnLifetime',
  'burnRadius',
  'burnScale',
  'cellJitter',
  'cellScale',
  'cellSmoothness',
  'centerX',
  'centerY',
  'color0',
  'color1',
  'color2',
  'color3',
  'color4',
  'color5',
  'color6',
  'color7',
  'color8',
  'color9',
  'colorCount',
  'contrast',
  'contrastPower',
  'curlRadius',
  'decay',
  'density',
  'displacementStrength',
  'distanceType',
  'ditherScale',
  'ditherStrength',
  'easing',
  'edgeFade',
  'edgeFadeMode',
  'edgeGain',
  'edgeLeanStrength',
  'edgeSmoothness',
  'edgeTint',
  'edgeWidth',
  'exposure',
  'fillLightColor',
  'fillLightDirX',
  'fillLightDirY',
  'fillLightDirZ',
  'fillLightIntensity',
  'finalContrast',
  'finalScale',
  'fireColor',
  'foldShading',
  'frequency',
  'furAnimationSpeed',
  'furColor',
  'furNoiseScale',
  'furNoiseStrength',
  'furThickness',
  'furWaveAmplitude',
  'furWaveFreqX',
  'furWaveFreqY',
  'glowIntensity',
  'gradientAngle',
  'gradientCenterX',
  'gradientCenterY',
  'gradientEps',
  'gradientOffset',
  'gradientScale',
  'gravity',
  'keyLightColor',
  'keyLightDirX',
  'keyLightDirY',
  'keyLightDirZ',
  'keyLightIntensity',
  'kernelRadius',
  'lacunarity',
  'lifetime',
  'lightDirX',
  'lightDirY',
  'lightDirZ',
  'lightIntensity',
  'lumaWeights',
  'maskColor',
  'maskThreshold',
  'metallic',
  'noiseAmount',
  'noiseBlend',
  'noiseContrast',
  'noiseDensity',
  'noiseIntensity',
  'noiseScale',
  'numWaves',
  'octaves',
  'offset',
  'orbitRadius',
  'orbitSpeed',
  'origin1X',
  'origin1Y',
  'origin2X',
  'origin2Y',
  'originScale',
  'outputMode',
  'paletteStops',
  'passColor',
  'patternScale',
  'persistence',
  'pixelSize',
  'planeOffset',
  'radius',
  'rimGain',
  'rimLightColor',
  'rimLightDirX',
  'rimLightDirY',
  'rimLightDirZ',
  'rimLightIntensity',
  'rippleDuration',
  'rotAngle',
  'roughness',
  'sampleEps',
  'scale',
  'scatter',
  'shadowStrength',
  'sharpness',
  'shininess',
  'showSun',
  'smokeColor',
  'smudgeFalloff',
  'smudgeRadius',
  'smudgeStrength',
  'softness',
  'specular',
  'speed',
  'stippleStrength',
  'sunColor',
  'sunDiscColor',
  'sunPosX',
  'sunPosY',
  'sunRadius',
  'timeScale',
  'warp1Scale',
  'warp2Scale',
  'warpFreqHigh',
  'warpFreqInner',
  'warpFreqMiddle',
  'warpStrength',
  'waveletAmplitude',
  'waveletDecay',
  'waveletFreq',
  'waveletSpeed',
  'waveletWidth',
  'weight',
  'wrinkleDepth',
  'wrinkles',
];
