import 'package:flutter/material.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_definitions.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_wrap.dart';

/// A wrap shader that creates a 3D page-curl/peel effect on a child widget.
///
/// The image curls up from the right edge like a page being turned,
/// revealing transparency behind. Progress is driven by [time] (0=flat,
/// 1=fully peeled), typically via [ShaderAnimationMode.explicit].
class PeelShaderWrap extends StatelessWidget {
  PeelShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.explicit,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? peelWrapShaderDef.defaults;

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
      shaderPath: 'packages/material_palette/shaders/peel_wrap.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms.setSize(size);
        uniforms.setFloat(time);

        uniforms.setFloat(p.get('curlRadius'));
        uniforms.setFloat(p.get('shadowStrength'));
      },
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
      child: child,
    );
  }
}
