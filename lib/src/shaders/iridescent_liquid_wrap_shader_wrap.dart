import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_definitions.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_wrap.dart';

/// A wrap shader that paints an animated chrome-over-fbm "iridescent liquid"
/// material onto its child, masked by the child's pixels.
///
/// The mask uses a [ShaderParams] `passColor` (RGBA). When alpha is 0 the
/// child's alpha channel drives the mask; any non-transparent colour requires
/// an exact match, so opaque text or filled shapes can be turned into
/// iridescent surfaces while the rest of the child stays transparent.
class IridescentLiquidShaderWrap extends StatelessWidget {
  IridescentLiquidShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? iridescentLiquidWrapShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final double time;
  final ShaderAnimationConfig? animationConfig;
  final bool cache;

  static Future<void> precacheShader() => ShaderBuilder.precacheShader(
      'packages/material_palette/shaders/iridescent_liquid_wrap.frag');

  @override
  Widget build(BuildContext context) {
    final p = params;

    return ShaderWrap(
      shaderPath:
          'packages/material_palette/shaders/iridescent_liquid_wrap.frag',
      uniformsCallback: (uniforms, size, time) {
        final colorBack = p.getColor('colorBack');
        final colorTint = p.getColor('colorTint');
        final passColor = p.getColor('passColor');

        uniforms
          ..setSize(size)
          ..setFloat(time)
          // Pattern tuning
          ..setFloat(p.get('repetition'))
          ..setFloat(p.get('softness'))
          ..setFloat(p.get('distortion'))
          ..setFloat(p.get('contour'))
          ..setFloat(p.get('angleDeg'))
          ..setFloat(p.get('stripeDiagaBias'))
          ..setFloat(p.get('stripeTwist'))
          // Bump tuning
          ..setFloat(p.get('bumpRadius'))
          ..setFloat(p.get('bumpExponent'))
          ..setFloat(p.get('bumpShearX'))
          ..setFloat(p.get('bumpShearY'))
          // Chromatic aberration
          ..setFloat(p.get('shiftRed'))
          ..setFloat(p.get('shiftBlue'))
          // Composition
          ..setFloat(colorBack.r)
          ..setFloat(colorBack.g)
          ..setFloat(colorBack.b)
          ..setFloat(colorBack.a)
          ..setFloat(colorTint.r)
          ..setFloat(colorTint.g)
          ..setFloat(colorTint.b)
          ..setFloat(colorTint.a)
          // Mask
          ..setFloat(passColor.r)
          ..setFloat(passColor.g)
          ..setFloat(passColor.b)
          ..setFloat(passColor.a)
          ..setFloat(p.get('edgeBandPx'))
          ..setFloat(p.get('edgeSmoothness'))
          // Domain warp
          ..setFloat(p.get('warpTimeScale'))
          ..setFloat(p.get('warpFreqInner'))
          ..setFloat(p.get('warpFreqMiddle'))
          ..setFloat(p.get('warpFreqHigh'))
          ..setFloat(p.get('fbmScaleFactor'))
          ..setFloat(p.get('stripeRippleStrength'))
          ..setFloat(p.get('bumpWarpWeight'))
          // Palette
          ..setFloat(p.get('paletteStops'));
        for (int i = 0; i < 10; i++) {
          final c = p.getColor('color$i');
          uniforms
            ..setFloat(c.r)
            ..setFloat(c.g)
            ..setFloat(c.b)
            ..setFloat(c.a);
        }
      },
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
      child: child,
    );
  }
}
