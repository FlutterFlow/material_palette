import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a click/touch-triggered ripple effect.
///
/// Per-tap timing is normalized to 0-1 progress in Dart and sent to the
/// shader alongside [rippleDuration] so that wave propagation still works
/// correctly in real-time units.
class ClickableRippleShaderWrap extends StatefulWidget {
  ClickableRippleShaderWrap({
    super.key,
    required this.child,
    this.backgroundColor = Colors.transparent,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
    this.interactive = true,
    this.touchPoints,
  }) : params = params ?? clickRippleShaderDef.defaults;

  final Widget child;
  final Color backgroundColor;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;
  final bool interactive;
  final List<ShaderTouchPoint>? touchPoints;

  static const int maxClicks = 10;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/click_ripple.frag');

  @override
  State<ClickableRippleShaderWrap> createState() =>
      _ClickableRippleShaderWrapState();
}

class _ClickableRippleShaderWrapState
    extends State<ClickableRippleShaderWrap> {
  final List<ShaderTouchPoint> _clicks = [];

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _removeExpiredClicks();
      _clicks.add(ShaderTouchPoint(
        position: event.localPosition,
        startTime: DateTime.now(),
      ));
      if (_clicks.length > ClickableRippleShaderWrap.maxClicks) {
        _clicks.removeAt(0);
      }
    });
  }

  void _removeExpiredClicks() {
    final duration = widget.params.get('rippleDuration');
    _clicks.removeWhere((click) => click.elapsed > duration);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.params;
    final clicks = widget.touchPoints ?? _clicks;
    final rippleDuration = p.get('rippleDuration');

    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/click_ripple.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms.setSize(size);

        // Click count
        uniforms.setFloat(clicks.length.toDouble());

        // Touch points (always send 10, padding with zeros)
        for (int i = 0; i < ClickableRippleShaderWrap.maxClicks; i++) {
          if (i < clicks.length) {
            uniforms.setFloats([clicks[i].position.dx, clicks[i].position.dy]);
          } else {
            uniforms.setFloats([0.0, 0.0]);
          }
        }

        // Per-tap progress normalized to 0-1 (always send 10, padding with zeros)
        for (int i = 0; i < ClickableRippleShaderWrap.maxClicks; i++) {
          if (i < clicks.length) {
            uniforms.setFloat(
                (clicks[i].elapsed / rippleDuration).clamp(0.0, 1.0));
          } else {
            uniforms.setFloat(0.0);
          }
        }

        // Controllable ripple parameters
        uniforms.setFloat(p.get('amplitude'));
        uniforms.setFloat(p.get('frequency'));
        uniforms.setFloat(p.get('decay'));
        uniforms.setFloat(p.get('speed'));
        uniforms.setFloat(rippleDuration);

        // Background color (RGBA)
        uniforms.setFloat(widget.backgroundColor.r);
        uniforms.setFloat(widget.backgroundColor.g);
        uniforms.setFloat(widget.backgroundColor.b);
        uniforms.setFloat(widget.backgroundColor.a);
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
