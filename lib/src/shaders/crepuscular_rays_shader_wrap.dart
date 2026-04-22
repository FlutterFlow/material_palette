import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_definitions.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_wrap.dart';

/// A wrap shader that projects crepuscular (god) rays across a child widget,
/// using the child's alpha channel as the occlusion mask.
///
/// Algorithm follows GPU Gems 3, Chapter 13 — "Volumetric Light Scattering as
/// a Post-Process". Transparent child pixels let light pass; opaque pixels
/// occlude the sun. A synthetic sun disc is added behind the mask so rays
/// always have a source, even when the child doesn't draw one.
///
/// In `continuous` mode the sun slowly orbits `sunPos`; set `orbitRadius` to
/// 0 to pin it. In `implicit`/`explicit` modes the caller drives [time].
class CrepuscularRaysShaderWrap extends StatelessWidget {
  CrepuscularRaysShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? crepuscularRaysShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final double time;
  final ShaderAnimationConfig? animationConfig;
  final bool cache;

  static Future<void> precacheShader() => ShaderBuilder.precacheShader(
      'packages/material_palette/shaders/crepuscular_rays.frag');

  @override
  Widget build(BuildContext context) {
    final p = params;

    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/crepuscular_rays.frag',
      uniformsCallback: (uniforms, size, time) {
        final sunColor = p.getColor('sunColor');
        final sunDiscColor = p.getColor('sunDiscColor');
        final passColor = p.getColor('passColor');

        uniforms
          ..setSize(size)
          ..setFloat(time)
          ..setFloat(p.get('sunPosX'))
          ..setFloat(p.get('sunPosY'))
          ..setFloat(p.get('sunRadius'))
          ..setFloat(p.get('exposure'))
          ..setFloat(p.get('decay'))
          ..setFloat(p.get('density'))
          ..setFloat(p.get('weight'))
          ..setFloat(p.get('orbitRadius'))
          ..setFloat(p.get('orbitSpeed'))
          ..setFloat(p.get('showSun'))
          ..setFloat(sunColor.r)
          ..setFloat(sunColor.g)
          ..setFloat(sunColor.b)
          ..setFloat(sunDiscColor.r)
          ..setFloat(sunDiscColor.g)
          ..setFloat(sunDiscColor.b)
          ..setFloat(passColor.r)
          ..setFloat(passColor.g)
          ..setFloat(passColor.b)
          ..setFloat(passColor.a);
      },
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
      child: child,
    );
  }
}
