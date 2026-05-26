import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_definitions.dart';
import 'package:material_palette/src/shader_fill.dart';
import 'package:material_palette/src/shader_params.dart';

/// A procedural fill shader rendering an animated iridescent liquid pattern:
/// stripes blended with an fbm domain warp, palette-mapped with optional
/// chromatic aberration.
///
/// Fill variant of the iridescent liquid family — no mask and no edge-driven
/// contour bending. See [iridescentLiquidShaderDef] for default values.
class IridescentLiquidShaderFill extends StatelessWidget {
  IridescentLiquidShaderFill({
    super.key,
    required this.width,
    required this.height,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? iridescentLiquidShaderDef.defaults;

  final double width;
  final double height;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final double time;
  final ShaderAnimationConfig? animationConfig;
  final bool cache;

  static Future<void> precacheShader() => ShaderBuilder.precacheShader(
      'packages/material_palette/shaders/iridescent_liquid.frag');

  void _setUniforms(FragmentShader shader, Size size, double time) {
    setShaderUniforms(
        shader, size, time, params, iridescentLiquidShaderDef.layout);
  }

  @override
  Widget build(BuildContext context) {
    return ShaderFill(
      width: width,
      height: height,
      shaderPath: 'packages/material_palette/shaders/iridescent_liquid.frag',
      uniformsCallback: _setUniforms,
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
    );
  }
}
