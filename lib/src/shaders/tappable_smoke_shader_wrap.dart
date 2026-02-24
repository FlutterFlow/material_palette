import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a tap-triggered smoke dissolve effect.
///
/// Each tap creates a radial smoke that expands outward then contracts back
/// before disappearing. Supports up to 10 simultaneous tap points.
///
/// Per-tap animation is controlled by [tapConfig]. When provided, [duration]
/// sets the one-way time (total cycle = 2× duration when [reverse] is true),
/// [curve] shapes the progress, [invert] and [rangeStart]/[rangeEnd] remap
/// the output. When null, timing comes from the `speed` and `burnLifetime`
/// shader params with a linear biphasic ramp.
class TappableSmokeShaderWrap extends StatefulWidget {
  TappableSmokeShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.tapConfig,
    this.cache = false,
    this.interactive = true,
    this.persistTaps = false,
    this.touchPoints,
  }) : params = params ?? tappableSmokeShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final double time;
  final ShaderAnimationConfig? animationConfig;

  /// Per-tap animation configuration. Controls curve, duration, delay,
  /// reverse, invert, and range for each tap's progress. The [loop] field
  /// is ignored — each tap is a one-shot effect.
  final ShaderAnimationConfig? tapConfig;
  final bool cache;
  final bool interactive;

  /// When false (default), expired taps are automatically removed after their
  /// animation completes. When true, taps persist until displaced by new taps
  /// filling the circular buffer ([maxClicks]).
  final bool persistTaps;
  final List<ShaderTouchPoint>? touchPoints;

  static const int maxClicks = 10;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/tappable_smoke.frag');

  @override
  State<TappableSmokeShaderWrap> createState() =>
      _TappableSmokeShaderWrapState();
}

class _TappableSmokeShaderWrapState
    extends State<TappableSmokeShaderWrap> {
  final List<ShaderTouchPoint> _clicks = [];

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _removeExpiredClicks();
      _clicks.add(ShaderTouchPoint(
        position: event.localPosition,
        startTime: DateTime.now(),
      ));
      if (_clicks.length > TappableSmokeShaderWrap.maxClicks) {
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
      final speed = widget.params.get('speed');
      final lifetime = widget.params.get('burnLifetime');
      return lifetime / speed;
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

  /// Computes per-tap progress using [tapConfig] when available,
  /// otherwise falls back to the legacy biphasic ramp from shader params.
  double _tapProgress(ShaderTouchPoint click) {
    final config = widget.tapConfig;

    final double elapsedSec = click.elapsed;
    final double delaySec;
    final double durationSec;
    final Curve curve;
    final bool reverse;
    final bool invert;
    final double rangeStart;
    final double rangeEnd;

    if (config != null) {
      delaySec = config.delay.inMicroseconds / 1e6;
      durationSec = config.duration.inMicroseconds / 1e6;
      curve = config.curve;
      reverse = config.reverse;
      invert = config.invert;
      rangeStart = config.rangeStart;
      rangeEnd = config.rangeEnd;
    } else {
      final speed = widget.params.get('speed');
      final lifetime = widget.params.get('burnLifetime');
      delaySec = 0.0;
      durationSec = lifetime / speed * 0.5;
      curve = Curves.linear;
      reverse = true;
      invert = false;
      rangeStart = 0.0;
      rangeEnd = 1.0;
    }

    final activeSec = elapsedSec - delaySec;
    if (activeSec < 0) {
      return invert ? rangeEnd : rangeStart;
    }
    if (durationSec <= 0) {
      return invert ? rangeStart : rangeEnd;
    }

    double linear;
    if (reverse) {
      final totalSec = durationSec * 2;
      if (activeSec >= totalSec) {
        linear = 0.0;
      } else if (activeSec <= durationSec) {
        linear = activeSec / durationSec;
      } else {
        linear = 2.0 - activeSec / durationSec;
      }
    } else {
      linear = (activeSec / durationSec).clamp(0.0, 1.0);
    }

    final curved = curve.transform(linear.clamp(0.0, 1.0));
    final start = invert ? rangeEnd : rangeStart;
    final end = invert ? rangeStart : rangeEnd;
    return start + curved * (end - start);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.params;
    final clicks = widget.touchPoints ?? _clicks;

    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/tappable_smoke.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms.setSize(size);

        // Click count
        uniforms.setFloat(clicks.length.toDouble());

        // Touch points (always send 10, padding with zeros)
        for (int i = 0; i < TappableSmokeShaderWrap.maxClicks; i++) {
          if (i < clicks.length) {
            uniforms.setFloats([clicks[i].position.dx, clicks[i].position.dy]);
          } else {
            uniforms.setFloats([0.0, 0.0]);
          }
        }

        // Per-tap progress (always send 10, padding with zeros)
        for (int i = 0; i < TappableSmokeShaderWrap.maxClicks; i++) {
          if (i < clicks.length) {
            uniforms.setFloat(_tapProgress(clicks[i]));
          } else {
            uniforms.setFloat(0.0);
          }
        }

        // Smoke parameters (no longer sending speed or burnLifetime)
        final smokeColor = p.getColor('smokeColor');
        uniforms.setFloat(p.get('noiseScale'));
        uniforms.setFloat(p.get('edgeWidth'));
        uniforms.setFloat(p.get('glowIntensity'));
        uniforms.setFloat(smokeColor.r);
        uniforms.setFloat(smokeColor.g);
        uniforms.setFloat(smokeColor.b);
        uniforms.setFloat(p.get('burnRadius'));
      },
      animationMode: widget.animationMode,
      time: widget.time,
      animationConfig: widget.animationConfig,
      cache: widget.cache,
      onPointerDown: (widget.interactive && widget.touchPoints == null)
          ? _onPointerDown
          : null,
      child: widget.child,
    );
  }
}
