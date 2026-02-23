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
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
  });

  final double width;
  final double height;
  final String shaderPath;
  final FillUniformsCallback uniformsCallback;
  final Color? backgroundColor;

  /// Optional pointer down callback for interactive shaders.
  final void Function(PointerDownEvent event)? onPointerDown;

  /// Controls how time is driven. Defaults to [ShaderAnimationMode.running].
  final ShaderAnimationMode animationMode;

  /// External animation that drives time when
  /// [animationMode] == [ShaderAnimationMode.animation].
  final Animation<double>? animation;

  /// When true, wraps the shader output in a [RepaintBoundary].
  final bool cache;

  @override
  State<ShaderFill> createState() => _ShaderFillState();
}

class _ShaderFillState extends State<ShaderFill>
    with TickerProviderStateMixin {
  Ticker? _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _setupTimeSource();
  }

  void _setupTimeSource() {
    switch (widget.animationMode) {
      case ShaderAnimationMode.running:
        _ticker = createTicker((elapsed) {
          _time.value = elapsed.inMilliseconds / 1000.0;
        });
        _ticker!.start();
        break;
      case ShaderAnimationMode.animation:
        final anim = widget.animation!;
        if (anim is ShaderAnimation) {
          anim.attach(this);
        }
        anim.addListener(_onAnimationTick);
        break;
      case ShaderAnimationMode.static:
        break;
    }
  }

  void _onAnimationTick() {
    _time.value = widget.animation!.value;
  }

  @override
  void didUpdateWidget(ShaderFill oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationMode != widget.animationMode ||
        oldWidget.animation != widget.animation) {
      // Tear down old source
      switch (oldWidget.animationMode) {
        case ShaderAnimationMode.running:
          _ticker?.stop();
          _ticker?.dispose();
          _ticker = null;
          _time.value = 0.0;
          break;
        case ShaderAnimationMode.animation:
          final oldAnim = oldWidget.animation;
          oldAnim?.removeListener(_onAnimationTick);
          if (oldAnim is ShaderAnimation) {
            oldAnim.detach();
          }
          break;
        case ShaderAnimationMode.static:
          break;
      }

      // Set up new source
      _setupTimeSource();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    if (widget.animationMode == ShaderAnimationMode.animation) {
      final anim = widget.animation;
      anim?.removeListener(_onAnimationTick);
      if (anim is ShaderAnimation) {
        anim.detach();
      }
    }
    _time.dispose();
    super.dispose();
  }

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

    if (widget.onPointerDown != null) {
      shaderWidget = Listener(
        onPointerDown: widget.onPointerDown,
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
