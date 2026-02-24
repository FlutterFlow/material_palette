import 'dart:ui' as ui show FragmentShader, lerpDouble;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:material_palette/src/shader_types.dart';

// ── Core param container ─────────────────────────────────────────────────────

/// Generic immutable parameter bag for any shader.
/// All scalar values (including flattened Offset/Offset3D components) live in
/// [values]; colors live in [colors].
class ShaderParams {
  final Map<String, double> values;
  final Map<String, Color> colors;

  const ShaderParams({this.values = const {}, this.colors = const {}});

  double get(String key) => values[key] ?? 0.0;
  Color getColor(String key) => colors[key] ?? const Color(0xFF000000);

  /// Return a copy with one scalar value changed.
  ShaderParams withValue(String key, double value) {
    return ShaderParams(
      values: {...values, key: value},
      colors: colors,
    );
  }

  /// Return a copy with one color changed.
  ShaderParams withColor(String key, Color color) {
    return ShaderParams(
      values: values,
      colors: {...colors, key: color},
    );
  }

  /// Bulk merge update.
  ShaderParams copyWith({
    Map<String, double>? values,
    Map<String, Color>? colors,
  }) {
    return ShaderParams(
      values: values != null ? {...this.values, ...values} : this.values,
      colors: colors != null ? {...this.colors, ...colors} : this.colors,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShaderParams &&
          mapEquals(values, other.values) &&
          mapEquals(colors, other.colors);

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(
            values.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAllUnordered(
            colors.entries.map((e) => Object.hash(e.key, e.value))),
      );

  /// Linearly interpolate between two [ShaderParams].
  static ShaderParams lerp(ShaderParams a, ShaderParams b, double t) {
    final allValueKeys = {...a.values.keys, ...b.values.keys};
    final allColorKeys = {...a.colors.keys, ...b.colors.keys};
    return ShaderParams(
      values: {
        for (final key in allValueKeys)
          key: ui.lerpDouble(a.get(key), b.get(key), t)!,
      },
      colors: {
        for (final key in allColorKeys)
          key: Color.lerp(a.getColor(key), b.getColor(key), t)!,
      },
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    for (final e in values.entries) {
      json[e.key] = e.value;
    }
    for (final e in colors.entries) {
      json[e.key] = _colorToHex(e.value);
    }
    return json;
  }

  static String _colorToHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    final a = (color.a * 255.0).round().clamp(0, 255);
    final rgb =
        '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    if (a < 255) {
      return '${rgb}${a.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    }
    return rgb.toUpperCase();
  }
}

// ── UI Defaults ──────────────────────────────────────────────────────────────

/// Map-based slider ranges for all parameters of a shader.
class ShaderUIDefaults {
  final Map<String, SliderRange> ranges;

  const ShaderUIDefaults(this.ranges);

  SliderRange? operator [](String key) => ranges[key];
}

// ── Uniform layout ───────────────────────────────────────────────────────────

enum UniformFieldType { float, color, colorRgba }

/// A single uniform field in a shader's layout.
class UniformField {
  final String key;
  final UniformFieldType type;

  const UniformField(this.key, [this.type = UniformFieldType.float]);
  const UniformField.color(this.key) : type = UniformFieldType.color;
  const UniformField.colorRgba(this.key) : type = UniformFieldType.colorRgba;
}

/// Ordered list of uniform fields after the standard header (width, height, time).
class UniformLayout {
  final List<UniformField> fields;
  const UniformLayout(this.fields);
}

/// Write the standard header + all params to a [FragmentShader] according to [layout].
int setShaderUniforms(
  ui.FragmentShader shader,
  Size size,
  double time,
  ShaderParams params,
  UniformLayout layout,
) {
  int idx = 0;
  // Standard header
  shader
    ..setFloat(idx++, size.width)
    ..setFloat(idx++, size.height)
    ..setFloat(idx++, time);
  // Fields
  for (final field in layout.fields) {
    switch (field.type) {
      case UniformFieldType.float:
        shader.setFloat(idx++, params.get(field.key));
      case UniformFieldType.color:
        final c = params.getColor(field.key);
        shader.setFloat(idx, c.r);
        shader.setFloat(idx + 1, c.g);
        shader.setFloat(idx + 2, c.b);
        idx += 3;
      case UniformFieldType.colorRgba:
        final c = params.getColor(field.key);
        shader.setFloat(idx, c.r);
        shader.setFloat(idx + 1, c.g);
        shader.setFloat(idx + 2, c.b);
        shader.setFloat(idx + 3, c.a);
        idx += 4;
    }
  }
  return idx;
}

// ── Reusable field / default / range groups ───────────────────────────────────

/// Composable building blocks for shader definitions.
abstract class ParamGroups {
  // ── Field groups (UniformField lists) ──

  static const linearGradientFields = [
    UniformField('gradientAngle'),
    UniformField('gradientScale'),
    UniformField('gradientOffset'),
  ];

  static const radialGradientFields = [
    UniformField('gradientCenterX'),
    UniformField('gradientCenterY'),
    UniformField('gradientScale'),
    UniformField('gradientOffset'),
  ];

  static const commonNoiseFields = [
    UniformField('noiseDensity'),
    UniformField('noiseIntensity'),
    UniformField('ditherStrength'),
    UniformField('animSpeed'),
  ];

  /// Noise fields for non-gritty shaders (noiseDensity removed, absorbed into noiseScale).
  static const noiseFields = [
    UniformField('noiseIntensity'),
    UniformField('ditherStrength'),
    UniformField('animSpeed'),
  ];

  /// Noise fields for gritty shaders (keeps noiseDensity).
  static const grittyNoiseFields = [
    UniformField('noiseDensity'),
    UniformField('noiseIntensity'),
    UniformField('ditherStrength'),
    UniformField('animSpeed'),
  ];

  static const colorsFields = [
    UniformField.color('colorA'),
    UniformField.color('colorB'),
    UniformField.color('colorMid'),
    UniformField('midPosition'),
  ];

  /// RGBA color stops (10 stops x 4 floats each) + count + softness.
  static const gradientColorsFields = [
    UniformField.colorRgba('color0'),
    UniformField.colorRgba('color1'),
    UniformField.colorRgba('color2'),
    UniformField.colorRgba('color3'),
    UniformField.colorRgba('color4'),
    UniformField.colorRgba('color5'),
    UniformField.colorRgba('color6'),
    UniformField.colorRgba('color7'),
    UniformField.colorRgba('color8'),
    UniformField.colorRgba('color9'),
    UniformField('colorCount'),
    UniformField('softness'),
  ];

  static const postProcessingFields = [
    UniformField('exposure'),
    UniformField('contrast'),
  ];

  static const lightingFields = [
    UniformField('bumpStrength'),
    UniformField('lightDirX'),
    UniformField('lightDirY'),
    UniformField('lightDirZ'),
    UniformField('lightIntensity'),
    UniformField('ambient'),
    UniformField('specular'),
    UniformField('shininess'),
    UniformField('metallic'),
    UniformField('roughness'),
    UniformField('edgeFade'),
    UniformField('edgeFadeMode'),
  ];

  // ── Default value groups ──

  static const linearGradientDefaults = {
    'gradientAngle': 110.0,
    'gradientScale': 1.0,
    'gradientOffset': 0.0,
  };

  static const radialGradientDefaults = {
    'gradientCenterX': 0.5,
    'gradientCenterY': 0.5,
    'gradientScale': 1.0,
    'gradientOffset': 0.0,
  };

  static const commonNoiseDefaults = {
    'noiseDensity': 40.0,
    'noiseIntensity': 0.50,
    'ditherStrength': 0.0,
    'animSpeed': 0.5,
  };

  /// Defaults for non-gritty noise (noiseDensity removed).
  static const noiseDefaults = {
    'noiseIntensity': 0.50,
    'ditherStrength': 0.0,
    'animSpeed': 0.5,
  };

  /// Defaults for gritty noise (keeps noiseDensity).
  static const grittyNoiseDefaults = {
    'noiseDensity': 160.0,
    'noiseIntensity': 0.65,
    'ditherStrength': 0.44,
    'animSpeed': 0.0,
  };

  /// Default transparent color for unused gradient stops.
  static const Color _transparentMid = Color(0x00808080);

  /// Generate gradient color defaults for N colors.
  static Map<String, Color> gradientColorDefaults(List<Color> activeColors) {
    final colors = <String, Color>{};
    for (int i = 0; i < 10; i++) {
      colors['color$i'] =
          i < activeColors.length ? activeColors[i] : _transparentMid;
    }
    return colors;
  }

  /// Generate gradient value defaults.
  static Map<String, double> gradientColorValueDefaults({
    required int colorCount,
    double softness = 1.0,
  }) {
    return {
      'colorCount': colorCount.toDouble(),
      'softness': softness,
    };
  }

  static const postProcessingDefaults = {
    'exposure': 1.0,
    'contrast': 1.0,
  };

  static const lightingDefaults = {
    'bumpStrength': 0.0,
    'lightDirX': 0.60,
    'lightDirY': 0.40,
    'lightDirZ': 1.0,
    'lightIntensity': 1.10,
    'ambient': 0.35,
    'specular': 0.30,
    'shininess': 24.0,
    'metallic': 0.0,
    'roughness': 0.50,
    'edgeFade': 0.0,
    'edgeFadeMode': 0.0,
  };

  // ── Range groups ──

  static const linearGradientRanges = {
    'gradientAngle': SliderRange('Angle', min: 0.0, max: 360.0),
    'gradientScale': SliderRange('Scale', min: 0.5, max: 3.0),
    'gradientOffset': SliderRange('Offset', min: -1.0, max: 1.0),
  };

  static const radialGradientRanges = {
    'gradientCenterX': SliderRange('Center X', min: 0.0, max: 1.0),
    'gradientCenterY': SliderRange('Center Y', min: 0.0, max: 1.0),
    'gradientScale': SliderRange('Scale', min: 0.5, max: 3.0),
    'gradientOffset': SliderRange('Offset', min: -1.0, max: 1.0),
  };

  static const commonNoiseRanges = {
    'noiseDensity': SliderRange('Density', min: 10.0, max: 200.0),
    'noiseIntensity': SliderRange('Intensity', min: 0.0, max: 1.0),
    'ditherStrength': SliderRange('Dither', min: 0.0, max: 1.0),
    'animSpeed': SliderRange('Speed', min: 0.0, max: 2.0),
  };

  /// Ranges for non-gritty noise (noiseDensity removed).
  static const noiseRanges = {
    'noiseIntensity': SliderRange('Intensity', min: 0.0, max: 1.0),
    'ditherStrength': SliderRange('Dither', min: 0.0, max: 1.0),
    'animSpeed': SliderRange('Speed', min: 0.0, max: 2.0),
  };

  /// Gritty shaders have a wider density range.
  static const grittyNoiseRanges = {
    'noiseDensity': SliderRange('Density', min: 100.0, max: 2000.0),
    'noiseIntensity': SliderRange('Intensity', min: 0.0, max: 1.0),
    'ditherStrength': SliderRange('Dither', min: 0.0, max: 1.0),
    'animSpeed': SliderRange('Speed', min: 0.0, max: 2.0),
  };

  static const colorsRanges = {
    'midPosition': SliderRange('Mid Position', min: -1.0, max: 1.0),
  };

  /// Ranges for gradient color system.
  static const gradientColorsRanges = {
    'colorCount': SliderRange('Color Count', min: 2.0, max: 10.0),
    'softness': SliderRange('Softness', min: 0.0, max: 1.0),
  };

  static const postProcessingRanges = {
    'exposure': SliderRange('Exposure', min: 0.5, max: 2.0),
    'contrast': SliderRange('Contrast', min: 0.5, max: 2.0),
  };

  static const lightingRanges = {
    'bumpStrength': SliderRange('Bump Strength', min: 0.0, max: 2.0),
    'lightDirX': SliderRange('Light X', min: -2.0, max: 2.0),
    'lightDirY': SliderRange('Light Y', min: -2.0, max: 2.0),
    'lightDirZ': SliderRange('Light Z', min: -2.0, max: 2.0),
    'lightIntensity': SliderRange('Light Intensity', min: 0.0, max: 2.0),
    'ambient': SliderRange('Ambient', min: 0.0, max: 1.0),
    'specular': SliderRange('Specular', min: 0.0, max: 1.0),
    'shininess': SliderRange('Shininess', min: 1.0, max: 128.0),
    'metallic': SliderRange('Metallic', min: 0.0, max: 1.0),
    'roughness': SliderRange('Roughness', min: 0.0, max: 1.0),
  };

  static const edgeFadeRanges = {
    'edgeFade': SliderRange('Edge Fade', min: 0.0, max: 3.0),
  };
}

// ── Tween ───────────────────────────────────────────────────────────────────

/// A [Tween] that interpolates between two [ShaderParams] using
/// [ShaderParams.lerp].
class ShaderParamsTween extends Tween<ShaderParams> {
  ShaderParamsTween({super.begin, super.end});

  @override
  ShaderParams lerp(double t) => ShaderParams.lerp(begin!, end!, t);
}
