import 'package:flutter/material.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_registry.dart';
import 'package:material_palette/src/shader_material.dart';

/// Bundles layout + defaults + uiDefaults for one shader.
class ShaderDefinition {
  final UniformLayout layout;
  final ShaderParams defaults;
  final ShaderUIDefaults uiDefaults;

  const ShaderDefinition({
    required this.layout,
    required this.defaults,
    required this.uiDefaults,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRITTY GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final grittyGradientDef = ShaderDefinition(
  layout: UniformLayout([
    ...ParamGroups.linearGradientFields,
    ...ParamGroups.grittyNoiseFields,
    ...ParamGroups.gradientColorsFields,
    ...ParamGroups.postProcessingFields,
  ]),
  defaults: ShaderParams(
    values: {
      'gradientAngle': 110.41, 'gradientScale': 0.60, 'gradientOffset': -0.38,
      'noiseDensity': 160.70, 'noiseIntensity': 0.65, 'ditherStrength': 0.44,
      'animSpeed': 0.0,
      'colorCount': 2.0, 'softness': 1.0,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// GRITTY GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialGrittyGradientDef = ShaderDefinition(
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
      'noiseDensity': 800.0, 'noiseIntensity': 0.35, 'ditherStrength': 0.50,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// PERLIN GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final perlinGradientDef = ShaderDefinition(
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
      'gradientAngle': 110.03, 'gradientScale': 1.20, 'gradientOffset': 0.0,
      'noiseIntensity': 0.46, 'ditherStrength': 0.0,
      'animSpeed': 0.91,
      'noiseScale': 12.6, 'noiseContrast': 3.00,
      'colorCount': 3.0, 'softness': 1.0,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// PERLIN GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialPerlinGradientDef = ShaderDefinition(
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
      'noiseIntensity': 0.57, 'ditherStrength': 0.0,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// SIMPLEX GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final simplexGradientDef = ShaderDefinition(
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
      'gradientAngle': 158.56, 'gradientScale': 0.94, 'gradientOffset': 0.0,
      'noiseIntensity': 0.32, 'ditherStrength': 0.25,
      'animSpeed': 0.35,
      'noiseScale': 8.0, 'sharpness': 2.20,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.45,
      'lightDirX': 0.55, 'lightDirY': 0.45, 'lightDirZ': 1.0,
      'lightIntensity': 1.15, 'ambient': 0.70, 'specular': 0.29,
      'shininess': 40.76, 'metallic': 1.0, 'roughness': 1.0,
      'edgeFade': 1.96, 'edgeFadeMode': 0.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(103, 58, 183, 1),
        const Color.fromRGBO(179, 136, 255, 1),
        const Color.fromRGBO(49, 27, 146, 1),
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// SIMPLEX GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialSimplexGradientDef = ShaderDefinition(
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
      'noiseIntensity': 0.36, 'ditherStrength': 0.0,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// FBM GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final fbmGradientDef = ShaderDefinition(
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
      'gradientAngle': 124.86, 'gradientScale': 1.0, 'gradientOffset': 0.0,
      'noiseIntensity': 0.88, 'ditherStrength': 0.0,
      'animSpeed': 0.33,
      'octaves': 5.0, 'lacunarity': 2.10, 'persistence': 0.50, 'noiseScale': 4.5,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.10,
      'lightDirX': 0.50, 'lightDirY': 0.60, 'lightDirZ': 0.90,
      'lightIntensity': 0.89, 'ambient': 0.29, 'specular': 0.16,
      'shininess': 3.06, 'metallic': 0.0, 'roughness': 0.49,
      'edgeFade': 0.56, 'edgeFadeMode': 1.0,
    },
    colors: {
      ...ParamGroups.gradientColorDefaults([
        const Color.fromRGBO(141, 110, 99, 1),
        const Color.fromRGBO(188, 170, 164, 1),
        const Color.fromRGBO(62, 39, 35, 1),
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// FBM GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialFbmGradientDef = ShaderDefinition(
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
      'noiseIntensity': 0.38, 'ditherStrength': 0.0,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// TURBULENCE GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final turbulenceGradientDef = ShaderDefinition(
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
      'gradientAngle': 267.09, 'gradientScale': 1.14, 'gradientOffset': 0.09,
      'noiseIntensity': 0.51, 'ditherStrength': 0.0,
      'animSpeed': 0.50,
      'octaves': 2.00, 'baseFrequency': 0.81, 'noiseScale': 2.9,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.77,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// TURBULENCE GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialTurbulenceGradientDef = ShaderDefinition(
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
      'noiseIntensity': 0.51, 'ditherStrength': 0.0,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// VORONOI GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final voronoiGradientDef = ShaderDefinition(
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
      'noiseIntensity': 0.12, 'ditherStrength': 0.02,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// VORONOI GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialVoronoiGradientDef = ShaderDefinition(
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
      'noiseIntensity': 0.26, 'ditherStrength': 0.0,
      'animSpeed': 0.5,
      'cellScale': 14.8, 'cellJitter': 0.07, 'distanceType': 0.0,
      'outputMode': 0.0, 'cellSmoothness': 0.50,
      'colorCount': 3.0, 'softness': 1.0,
      'exposure': 1.0, 'contrast': 1.0,
      'bumpStrength': 0.68,
      'lightDirX': -0.04, 'lightDirY': 0.23, 'lightDirZ': 1.03,
      'lightIntensity': 1.29, 'ambient': 0.12, 'specular': 0.61,
      'shininess': 106.58, 'metallic': 0.43, 'roughness': 0.20,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// VORONOISE GRADIENT (linear)
// ═══════════════════════════════════════════════════════════════════════════════

final voronoiseGradientDef = ShaderDefinition(
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
      'noiseIntensity': 0.55, 'ditherStrength': 0.0,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// VORONOISE GRADIENT (radial)
// ═══════════════════════════════════════════════════════════════════════════════

final radialVoronoiseGradientDef = ShaderDefinition(
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
      'noiseIntensity': 0.34, 'ditherStrength': 0.0,
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// MARBLE SMEAR SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final marbleSmearShaderDef = ShaderDefinition(
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
    const UniformField('lightDirX'),
    const UniformField('lightDirY'),
    const UniformField('lightDirZ'),
    const UniformField.color('lightSky'),
    const UniformField.color('lightSun'),
    const UniformField('lightAmbient'),
    const UniformField('lightDiffuse'),
    const UniformField('lightIntensity'),
    const UniformField('smudgeRadius'),
    const UniformField('smudgeStrength'),
    const UniformField('smudgeFalloff'),
  ]),
  defaults: ShaderParams(
    values: {
      'warp1Scale': 1.3, 'warp2Scale': 4.0, 'finalScale': 2.8,
      'warpStrength': 6.8, 'contrastPower': 3.5, 'finalContrast': 1.1,
      'animSpeedInputX': 0.27, 'animSpeedInputY': 0.23,
      'animSpeedWarpX': 0.12, 'animSpeedWarpY': 0.14,
      'animAmpInput': 0.02, 'animAmpWarp': 0.02,
      'lightDirX': 0.9, 'lightDirY': 0.2, 'lightDirZ': -0.4,
      'lightAmbient': 0.3, 'lightDiffuse': 0.7, 'lightIntensity': 1.0,
      'smudgeRadius': 0.4, 'smudgeStrength': 0.5, 'smudgeFalloff': 3.0,
    },
    colors: {
      'bgColor': const Color(0xFF202329),
      'color0': const Color.fromRGBO(217, 212, 204, 1), // cream
      'color1': const Color.fromRGBO(140, 128, 115, 1), // tan
      'color2': const Color.fromRGBO(77, 64, 56, 1),    // brown
      'color3': const Color.fromRGBO(89, 115, 133, 1),  // teal
      'color4': const Color.fromRGBO(31, 36, 46, 1),    // dark
      'lightSky': const Color.fromRGBO(255, 255, 255, 1),
      'lightSun': const Color.fromRGBO(38, 26, 13, 1),
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
    'lightDirX': const SliderRange('Light X', min: -2.0, max: 2.0),
    'lightDirY': const SliderRange('Light Y', min: -2.0, max: 2.0),
    'lightDirZ': const SliderRange('Light Z', min: -2.0, max: 2.0),
    'lightAmbient': const SliderRange('Ambient', min: 0.0, max: 1.0),
    'lightDiffuse': const SliderRange('Diffuse', min: 0.0, max: 1.0),
    'lightIntensity': const SliderRange('Intensity', min: 0.0, max: 2.0),
    'smudgeRadius': const SliderRange('Smudge Radius', min: 0.1, max: 1.0),
    'smudgeStrength': const SliderRange('Smudge Strength', min: 0.1, max: 2.0),
    'smudgeFalloff': const SliderRange('Smudge Falloff', min: 0.5, max: 10.0),
  }),
);

// ═══════════════════════════════════════════════════════════════════════════════
// RIPPLE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final rippleShaderDef = ShaderDefinition(
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// CLICK RIPPLE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final clickRippleShaderDef = ShaderDefinition(
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// BURN SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final burnShaderDef = ShaderDefinition(
  layout: const UniformLayout([]),  // Burn has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'dirX': -0.00, 'dirY': 0.06,
      'noiseScale': 8.85, 'edgeWidth': 0.18, 'glowIntensity': 3.56,
      'speed': 0.30,
    },
    colors: {
      'fireColor': const Color.fromRGBO(255, 127, 0, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'dirX': const SliderRange('Direction X', min: -1.0, max: 1.0),
    'dirY': const SliderRange('Direction Y', min: -1.0, max: 1.0),
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.0, max: 1.0),
    'glowIntensity': const SliderRange('Glow Intensity', min: 0.0, max: 5.0),
    'speed': const SliderRange('Speed', min: 0.01, max: 1.0),
  }),
);

// ═══════════════════════════════════════════════════════════════════════════════
// RADIAL BURN SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final radialBurnShaderDef = ShaderDefinition(
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// TAPPABLE BURN SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final tappableBurnShaderDef = ShaderDefinition(
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// SMOKE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final smokeShaderDef = ShaderDefinition(
  layout: const UniformLayout([]),  // Smoke has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'dirX': -0.00, 'dirY': 0.06,
      'noiseScale': 6.0, 'edgeWidth': 0.25, 'glowIntensity': 2.5,
      'speed': 0.20,
    },
    colors: {
      'smokeColor': const Color.fromRGBO(200, 200, 210, 1),
    },
  ),
  uiDefaults: ShaderUIDefaults({
    'dirX': const SliderRange('Direction X', min: -1.0, max: 1.0),
    'dirY': const SliderRange('Direction Y', min: -1.0, max: 1.0),
    'noiseScale': const SliderRange('Noise Scale', min: 1.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.0, max: 1.0),
    'glowIntensity': const SliderRange('Glow Intensity', min: 0.0, max: 5.0),
    'speed': const SliderRange('Speed', min: 0.01, max: 1.0),
  }),
);

// ═══════════════════════════════════════════════════════════════════════════════
// RADIAL SMOKE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final radialSmokeShaderDef = ShaderDefinition(
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// TAPPABLE SMOKE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final tappableSmokeShaderDef = ShaderDefinition(
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// PIXEL DISSOLVE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final pixelDissolveShaderDef = ShaderDefinition(
  layout: const UniformLayout([]),  // Pixel dissolve has fully manual uniform layout
  defaults: ShaderParams(
    values: {
      'dirX': 0.41, 'dirY': 0.10,
      'pixelSize': 5.11, 'edgeWidth': 0.35,
      'scatter': 0.36, 'noiseAmount': 0.93,
      'speed': 0.21,
    },
    colors: {},
  ),
  uiDefaults: ShaderUIDefaults({
    'dirX': const SliderRange('Direction X', min: -1.0, max: 1.0),
    'dirY': const SliderRange('Direction Y', min: -1.0, max: 1.0),
    'pixelSize': const SliderRange('Pixel Size', min: 3.0, max: 30.0),
    'edgeWidth': const SliderRange('Edge Width', min: 0.05, max: 1.0),
    'scatter': const SliderRange('Scatter', min: 0.0, max: 3.0),
    'noiseAmount': const SliderRange('Noise', min: 0.0, max: 1.0),
    'speed': const SliderRange('Speed', min: 0.01, max: 1.0),
  }),
);

// ═══════════════════════════════════════════════════════════════════════════════
// RADIAL PIXEL DISSOLVE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final radialPixelDissolveShaderDef = ShaderDefinition(
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
);

// ═══════════════════════════════════════════════════════════════════════════════
// TAPPABLE PIXEL DISSOLVE SHADER
// ═══════════════════════════════════════════════════════════════════════════════

final tappablePixelDissolveShaderDef = ShaderDefinition(
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

/// Maps shader card names to their definitions (for all 17 shaders).
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
};
