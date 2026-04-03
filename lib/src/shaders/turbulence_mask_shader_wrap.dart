import 'package:flutter/material.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_definitions.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_wrap.dart';

/// A wrap shader that applies animated turbulence-driven UV displacement
/// uniformly across a child widget.
///
/// The child texture is warped by turbulence noise, creating organic,
/// shimmer-like distortion.
class TurbulenceMaskShaderWrap extends StatelessWidget {
  TurbulenceMaskShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? turbulenceMaskShaderDef.defaults;

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
      shaderPath: 'packages/material_palette/shaders/turbulence_mask.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms.setSize(size);
        uniforms.setFloat(time);

        uniforms.setFloat(p.get('octaves'));
        uniforms.setFloat(p.get('baseFrequency'));
        uniforms.setFloat(p.get('noiseScale'));
        uniforms.setFloat(p.get('animSpeed'));
        uniforms.setFloat(p.get('displacementStrength'));
      },
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
      child: child,
    );
  }
}
