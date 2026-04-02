import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_fill.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that renders an interactive volumetric fur surface.
///
/// Renders a raymarched fur plane with 3-point lighting and procedural noise.
/// Tapping creates wavelet ripples that propagate across the fur. Supports up
/// to 5 simultaneous tap points.
///
/// Per-tap animation is controlled by [tapConfig]. When null, wavelet timing
/// is derived from shader params (waveletDecay controls lifetime).
class FurPlanarShaderFill extends StatefulWidget {
  FurPlanarShaderFill({
    super.key,
    required this.width,
    required this.height,
    this.backgroundColor = Colors.transparent,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.tapConfig,
    this.cache = false,
    this.interactive = true,
    this.persistTaps = false,
    this.touchPoints,
  }) : params = params ?? furPlanarShaderDef.defaults;

  final double width;
  final double height;
  final Color? backgroundColor;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final double time;
  final ShaderAnimationConfig? animationConfig;
  final ShaderAnimationConfig? tapConfig;
  final bool cache;
  final bool interactive;
  final bool persistTaps;
  final List<ShaderTouchPoint>? touchPoints;

  static const int maxClicks = 5;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/fur_planar.frag');

  @override
  State<FurPlanarShaderFill> createState() => _FurPlanarShaderFillState();
}

class _FurPlanarShaderFillState extends State<FurPlanarShaderFill> {
  final List<ShaderTouchPoint> _clicks = [];

  bool get _isInternalInteraction =>
      widget.interactive && widget.touchPoints == null;

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _removeExpiredClicks();
      _clicks.add(ShaderTouchPoint(
        position: event.localPosition,
        startTime: DateTime.now(),
      ));
      if (_clicks.length > FurPlanarShaderFill.maxClicks) {
        _clicks.removeAt(0);
      }
    });
    if (!widget.persistTaps) {
      _scheduleCleanup();
    }
  }

  double _tapLifetimeSec() {
    final config = widget.tapConfig;
    if (config != null) {
      final delaySec = config.delay.inMicroseconds / 1e6;
      final durationSec = config.duration.inMicroseconds / 1e6;
      return delaySec + (config.reverse ? durationSec * 2 : durationSec);
    } else {
      final decay = widget.params.get('waveletDecay');
      return decay > 0 ? 6.9 / decay : 8.0;
    }
  }

  void _removeExpiredClicks() {
    if (widget.persistTaps) return;
    final lifetimeSec = _tapLifetimeSec();
    _clicks.removeWhere((click) => click.elapsed > lifetimeSec);
  }

  void _scheduleCleanup() {
    final delayMs = (_tapLifetimeSec() * 1000).ceil() + 50;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        setState(() => _removeExpiredClicks());
      }
    });
  }

  /// Normalizes a screen-space tap position into the shader's coordinate system.
  /// The fur shader uses UV coords: (fragCoord - 0.5*uSize) / min(uSize).
  Offset _normalizePosition(Offset localPosition, Size size) {
    final minDim = size.width < size.height ? size.width : size.height;
    return Offset(
      (localPosition.dx - 0.5 * size.width) / minDim,
      (localPosition.dy - 0.5 * size.height) / minDim,
    );
  }

  void _setUniforms(FragmentShader shader, Size size, double time) {
    final clicks = widget.touchPoints ?? _clicks;

    if (widget.touchPoints == null) {
      _removeExpiredClicks();
    }

    final bgColor = widget.backgroundColor ?? Colors.transparent;
    final mergedParams = widget.params.withColor('bgColor', bgColor);
    int idx = setShaderUniforms(shader, size, time, mergedParams, furPlanarShaderDef.layout);

    // Click count
    shader.setFloat(idx++, clicks.length.toDouble());

    // Click positions (always send 5, padding with zeros)
    for (int i = 0; i < FurPlanarShaderFill.maxClicks; i++) {
      if (i < clicks.length) {
        final pos = _normalizePosition(clicks[i].position, size);
        shader.setFloat(idx++, pos.dx);
        shader.setFloat(idx++, pos.dy);
      } else {
        shader.setFloat(idx++, 0.0);
        shader.setFloat(idx++, 0.0);
      }
    }

    // Click times — raw elapsed seconds (GLSL handles wavelet physics)
    for (int i = 0; i < FurPlanarShaderFill.maxClicks; i++) {
      shader.setFloat(idx++, i < clicks.length ? clicks[i].elapsed : 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShaderFill(
      width: widget.width,
      height: widget.height,
      shaderPath: 'packages/material_palette/shaders/fur_planar.frag',
      backgroundColor: widget.backgroundColor,
      uniformsCallback: _setUniforms,
      onPointerDown: _isInternalInteraction ? _onPointerDown : null,
      animationMode: widget.animationMode,
      time: widget.time,
      animationConfig: widget.animationConfig,
      cache: widget.cache,
    );
  }
}
