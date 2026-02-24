import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_types.dart';

export 'package:material_palette/src/shader_types.dart';

/// Callback for setting shader uniforms on a fill (procedural) shader.
/// Receives the [FragmentShader], current [Size], and elapsed [time] in seconds.
typedef FillUniformsCallback = void Function(
    FragmentShader shader, Size size, double time);

/// A generic, reusable wrapper for procedural shaders that use CustomPaint.
/// Unlike [ShaderWrap], this doesn't sample a child widget - it renders
/// procedurally generated content directly.
///
/// Manages its own ticker for animation and provides the elapsed time to the
/// uniforms callback.
class ShaderFill extends StatefulWidget {
  const ShaderFill({
    super.key,
    required this.width,
    required this.height,
    required this.shaderPath,
    required this.uniformsCallback,
    this.backgroundColor = Colors.transparent,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.cache = true,
  });

  final double width;
  final double height;
  final String shaderPath;
  final FillUniformsCallback uniformsCallback;
  final Color? backgroundColor;

  /// Optional pointer down callback for interactive shaders.
  final void Function(PointerDownEvent event)? onPointerDown;
  final void Function(PointerMoveEvent event)? onPointerMove;
  final void Function(PointerUpEvent event)? onPointerUp;
  final void Function(PointerCancelEvent event)? onPointerCancel;

  /// Controls how time is driven. Defaults to [ShaderAnimationMode.continuous].
  final ShaderAnimationMode animationMode;

  /// External time value used when [animationMode] == [ShaderAnimationMode.implicit].
  final double time;

  /// Animation configuration used when
  /// [animationMode] == [ShaderAnimationMode.explicit].
  final ShaderAnimationConfig? animationConfig;

  /// Wraps the shader subtree in a [RepaintBoundary] to isolate repaints in
  /// both directions.
  ///
  /// Unlike [ShaderWrap], the underlying [CustomPainter] has no inner repaint
  /// boundary. Without this flag, every frame's repaint propagates up to the
  /// nearest ancestor boundary — potentially repainting a much larger area.
  /// With it, shader repaints stay contained *and* ancestor repaints skip the
  /// shader subtree entirely.
  ///
  /// Defaults to `true` because the default [animationMode] is [continuous],
  /// and without the boundary every frame's repaint propagates up to the
  /// nearest ancestor boundary. Set to `false` only for [implicit] shaders in a
  /// stable parent tree, or when you intentionally want to merge compositing
  /// layers.
  final bool cache;

  @override
  State<ShaderFill> createState() => _ShaderFillState();
}

class _ShaderFillState extends State<ShaderFill>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _startTimeSource();
  }

  // -- Ticker callback -------------------------------------------------------

  void _onTick(Duration elapsed) {
    switch (widget.animationMode) {
      case ShaderAnimationMode.continuous:
        const rolloverMs = 24 * 60 * 60 * 1000; // 24 hours to avoid fp error accumulation
        _time.value = (elapsed.inMilliseconds % rolloverMs) / 1000.0;
        break;
      case ShaderAnimationMode.explicit:
        _time.value =
            _computeProgress(elapsed, widget.animationConfig!);
        break;
      case ShaderAnimationMode.implicit:
        break;
    }
  }

  /// Converts raw elapsed time into progress using [ShaderAnimationConfig].
  ///
  /// The output respects [ShaderAnimationConfig.rangeStart],
  /// [ShaderAnimationConfig.rangeEnd], and [ShaderAnimationConfig.invert].
  double _computeProgress(Duration elapsed, ShaderAnimationConfig config) {
    final start = config.invert ? config.rangeEnd : config.rangeStart;
    final end = config.invert ? config.rangeStart : config.rangeEnd;

    final delayUs = config.delay.inMicroseconds.toDouble();
    final durationUs = config.duration.inMicroseconds.toDouble();
    final elapsedUs = elapsed.inMicroseconds.toDouble();

    if (elapsedUs < delayUs) return start;
    if (durationUs <= 0) return end;

    final activeUs = elapsedUs - delayUs;

    double linear;
    if (config.loop) {
      if (config.reverse) {
        // Ping-pong: 0→1→0→1→0…
        final cycleUs = durationUs * 2;
        final pos = activeUs % cycleUs;
        linear = pos <= durationUs
            ? pos / durationUs
            : 2.0 - pos / durationUs;
      } else {
        // Sawtooth: 0→1, 0→1, 0→1…
        linear = (activeUs % durationUs) / durationUs;
      }
    } else {
      linear = (activeUs / durationUs).clamp(0.0, 1.0);
    }

    final curved = config.curve.transform(linear.clamp(0.0, 1.0));
    return start + curved * (end - start);
  }

  // -- Time source management ------------------------------------------------

  void _startTimeSource() {
    switch (widget.animationMode) {
      case ShaderAnimationMode.implicit:
        _time.value = widget.time;
        break;
      case ShaderAnimationMode.continuous:
        _ticker.start();
        break;
      case ShaderAnimationMode.explicit:
        _ticker.start();
        break;
    }
  }

  void _stopTimeSource() {
    switch (widget.animationMode) {
      case ShaderAnimationMode.continuous:
      case ShaderAnimationMode.explicit:
        _ticker.stop();
        _time.value = 0.0;
        break;
      case ShaderAnimationMode.implicit:
        break;
    }
  }

  // -- Lifecycle -------------------------------------------------------------

  @override
  void didUpdateWidget(ShaderFill oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationMode != widget.animationMode ||
        oldWidget.animationConfig != widget.animationConfig) {
      _stopTimeSource();
      _startTimeSource();
    } else if (widget.animationMode == ShaderAnimationMode.implicit &&
        oldWidget.time != widget.time) {
      _time.value = widget.time;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  // -- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = Size(widget.width, widget.height);

    Widget shaderWidget = ShaderBuilder(
      (context, shader, child) {
        return CustomPaint(
          size: size,
          painter: _FillShaderPainter(
            shader: shader,
            time: _time,
            uniformsCallback: widget.uniformsCallback,
          ),
        );
      },
      assetKey: widget.shaderPath,
    );

    if (widget.cache) {
      shaderWidget = RepaintBoundary(child: shaderWidget);
    }

    if (widget.onPointerDown != null ||
        widget.onPointerMove != null ||
        widget.onPointerUp != null ||
        widget.onPointerCancel != null) {
      shaderWidget = Listener(
        onPointerDown: widget.onPointerDown,
        onPointerMove: widget.onPointerMove,
        onPointerUp: widget.onPointerUp,
        onPointerCancel: widget.onPointerCancel,
        child: shaderWidget,
      );
    }

    return shaderWidget;
  }
}

class _FillShaderPainter extends CustomPainter {
  _FillShaderPainter({
    required this.shader,
    required this.time,
    required this.uniformsCallback,
  }) : super(repaint: time);

  final FragmentShader shader;
  final ValueNotifier<double> time;
  final FillUniformsCallback uniformsCallback;

  @override
  void paint(Canvas canvas, Size size) {
    uniformsCallback(shader, size, time.value);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_FillShaderPainter oldDelegate) {
    // Repaint listenable handles time-driven repaints.
    // Repaint here only when painter config changes (e.g. new params).
    return shader != oldDelegate.shader ||
        uniformsCallback != oldDelegate.uniformsCallback;
  }
}
