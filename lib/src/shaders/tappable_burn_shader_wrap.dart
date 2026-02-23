import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a tap-triggered burn dissolve effect.
///
/// Each tap creates a radial burn that expands outward then contracts back
/// before disappearing. Supports up to 10 simultaneous tap points.
///
/// Per-tap progress (biphasic expand/contract ramp) is computed in Dart.
/// If the [animation] is a [ShaderAnimation], its [Curve] is applied to
/// each tap's progress for eased per-tap animation.
class TappableBurnShaderWrap extends StatefulWidget {
  TappableBurnShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
    this.interactive = true,
    this.touchPoints,
  }) : params = params ?? tappableBurnShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;
  final bool interactive;
  final List<ShaderTouchPoint>? touchPoints;

  static const int maxClicks = 10;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/tappable_burn.frag');

  @override
  State<TappableBurnShaderWrap> createState() =>
      _TappableBurnShaderWrapState();
}

class _TappableBurnShaderWrapState
    extends State<TappableBurnShaderWrap> {
  final List<ShaderTouchPoint> _clicks = [];

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _removeExpiredClicks();
      _clicks.add(ShaderTouchPoint(
        position: event.localPosition,
        startTime: DateTime.now(),
      ));
      if (_clicks.length > TappableBurnShaderWrap.maxClicks) {
        _clicks.removeAt(0);
      }
    });
  }

  void _removeExpiredClicks() {
    final speed = widget.params.get('speed');
    final lifetime = widget.params.get('burnLifetime');
    _clicks.removeWhere((click) =>
        click.elapsed > lifetime / speed);
  }

  /// Computes 0-1 biphasic progress for a single tap.
  double _tapProgress(ShaderTouchPoint click) {
    final speed = widget.params.get('speed');
    final lifetime = widget.params.get('burnLifetime');
    final rawTime = click.elapsed * speed;
    final halfLife = lifetime * 0.5;
    double linear;
    if (rawTime < halfLife) {
      linear = rawTime / halfLife;
    } else {
      linear = 1.0 - (rawTime - halfLife) / halfLife;
    }
    linear = linear.clamp(0.0, 1.0);

    // Apply curve from ShaderAnimation if available
    final curve = (widget.animation is ShaderAnimation)
        ? (widget.animation as ShaderAnimation).curve
        : Curves.linear;
    return curve.transform(linear);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.params;
    final clicks = widget.touchPoints ?? _clicks;

    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/tappable_burn.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms.setSize(size);

        // Click count
        uniforms.setFloat(clicks.length.toDouble());

        // Touch points (always send 10, padding with zeros)
        for (int i = 0; i < TappableBurnShaderWrap.maxClicks; i++) {
          if (i < clicks.length) {
            uniforms.setFloats([clicks[i].position.dx, clicks[i].position.dy]);
          } else {
            uniforms.setFloats([0.0, 0.0]);
          }
        }

        // Per-tap progress (always send 10, padding with zeros)
        for (int i = 0; i < TappableBurnShaderWrap.maxClicks; i++) {
          if (i < clicks.length) {
            uniforms.setFloat(_tapProgress(clicks[i]));
          } else {
            uniforms.setFloat(0.0);
          }
        }

        // Burn parameters (no longer sending speed or burnLifetime)
        final fireColor = p.getColor('fireColor');
        uniforms.setFloat(p.get('noiseScale'));
        uniforms.setFloat(p.get('edgeWidth'));
        uniforms.setFloat(p.get('glowIntensity'));
        uniforms.setFloat(fireColor.r);
        uniforms.setFloat(fireColor.g);
        uniforms.setFloat(fireColor.b);
        uniforms.setFloat(p.get('burnRadius'));
      },
      animationMode: widget.animationMode,
      animation: widget.animation,
      cache: widget.cache,
      onPointerDown: (widget.interactive && widget.touchPoints == null)
          ? _onPointerDown
          : null,
      child: widget.child,
    );
  }
}
