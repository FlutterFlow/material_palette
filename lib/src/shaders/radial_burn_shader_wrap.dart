import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a radial burn dissolve effect to its child.
///
/// Burns outward from a configurable center point with an organic FBM-noise
/// edge and fire glow.
///
/// In `running` mode the [speed] param controls how fast the ping-pong
/// animation runs. In `animation` mode the shader receives 0-1 progress
/// directly from the provided [Animation].
class RadialBurnShaderWrap extends StatelessWidget {
  RadialBurnShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
  }) : params = params ?? radialBurnShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/radial_burn.frag');

  @override
  Widget build(BuildContext context) {
    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/radial_burn.frag',
      uniformsCallback: (uniforms, size, time) {
        final progress = animationMode == ShaderAnimationMode.running
            ? pingPong(time * params.get('speed'))
            : time;

        final fireColor = params.getColor('fireColor');
        uniforms
          ..setSize(size)
          ..setFloat(progress)
          ..setFloat(params.get('burnCenterX'))
          ..setFloat(params.get('burnCenterY'))
          ..setFloat(params.get('burnScale'))
          ..setFloat(params.get('noiseScale'))
          ..setFloat(params.get('edgeWidth'))
          ..setFloat(params.get('glowIntensity'))
          ..setFloat(fireColor.r)
          ..setFloat(fireColor.g)
          ..setFloat(fireColor.b);
      },
      animationMode: animationMode,
      animation: animation,
      cache: cache,
      child: child,
    );
  }
}
