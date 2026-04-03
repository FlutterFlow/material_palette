import 'package:flutter/material.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_definitions.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_wrap.dart';

/// A wrap shader that applies 4x4 Bayer ordered dithering to a child widget.
///
/// Quantizes sampling into a cell grid controlled by [ditherScale] and applies
/// ordered dither thresholds, producing a retro/risograph pixelation effect.
class DitherShaderWrap extends StatelessWidget {
  DitherShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.implicit,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? ditherWrapShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final double time;
  final ShaderAnimationConfig? animationConfig;
  final bool cache;

  @override
  Widget build(BuildContext context) {
    final p = params;

    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/dither_wrap.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms.setSize(size);
        uniforms.setFloat(time);

        uniforms.setFloat(p.get('ditherScale'));
        uniforms.setFloat(p.get('colorSteps'));
      },
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
      child: child,
    );
  }
}
