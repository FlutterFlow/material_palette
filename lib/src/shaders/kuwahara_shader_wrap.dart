import 'package:flutter/material.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_definitions.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_wrap.dart';

/// A wrap shader that applies an anisotropic Kuwahara filter to a child widget.
///
/// The filter produces a painterly / edge-preserving smoothing effect by
/// sampling oriented sectors around each pixel and outputting the mean colour
/// of the lowest-variance sector. `kernelRadius` controls brush size;
/// `sharpness` biases how elongated the sampling kernel becomes along
/// detected edges.
class KuwaharaShaderWrap extends StatelessWidget {
  KuwaharaShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.implicit,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? kuwaharaShaderDef.defaults;

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
      shaderPath: 'packages/material_palette/shaders/kuwahara.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms.setSize(size);
        uniforms.setFloat(time);

        uniforms.setFloat(p.get('kernelRadius'));
        uniforms.setFloat(p.get('sharpness'));
      },
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
      child: child,
    );
  }
}
