import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_definitions.dart';
import 'package:material_palette/src/shader_fill.dart';
import 'package:material_palette/src/shader_params.dart';

/// A procedural fill shader rendering an animated liquid-metal heat-map:
/// a triple-nested domain warp over 4-octave value noise, coloured through a
/// 10-stop RGBA palette and shaded as a heightfield with a warm edge glow.
///
/// Every top-level constant in the original shader is exposed as a tunable
/// uniform — see [liquidMetalShaderDef] for the default values.
class LiquidMetalShaderFill extends StatelessWidget {
  LiquidMetalShaderFill({
    super.key,
    required this.width,
    required this.height,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? liquidMetalShaderDef.defaults;

  final double width;
  final double height;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final double time;
  final ShaderAnimationConfig? animationConfig;
  final bool cache;

  static Future<void> precacheShader() => ShaderBuilder.precacheShader(
      'packages/material_palette/shaders/liquid_metal.frag');

  void _setUniforms(FragmentShader shader, Size size, double time) {
    setShaderUniforms(shader, size, time, params, liquidMetalShaderDef.layout);
  }

  @override
  Widget build(BuildContext context) {
    return ShaderFill(
      width: width,
      height: height,
      shaderPath: 'packages/material_palette/shaders/liquid_metal.frag',
      uniformsCallback: _setUniforms,
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
    );
  }
}
