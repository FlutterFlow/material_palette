import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/animated_sampler_repaint.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_types.dart';

export 'package:material_palette/src/shader_types.dart';

/// Callback for setting shader uniforms.
/// Receives the [UniformsSetter], current [Size], and elapsed [time] in seconds.
typedef UniformsCallback = void Function(
    UniformsSetter uniforms, Size size, double time);

/// A generic, reusable wrapper that applies a fragment shader to its child.
/// Subclasses or users can provide a [uniformsCallback] to set arbitrary uniforms.
///
/// Manages its own ticker for animation and provides the elapsed time to the
/// uniforms callback.
class ShaderWrap extends StatefulWidget {
  const ShaderWrap({
    super.key,
    required this.child,
    required this.shaderPath,
    required this.uniformsCallback,
    this.backgroundColor = Colors.transparent,
    this.onPointerDown,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  });

  final Widget child;
  final String shaderPath;
  final UniformsCallback uniformsCallback;
  final Color? backgroundColor;

  /// Optional pointer down callback for interactive shaders.
  final void Function(PointerDownEvent event)? onPointerDown;

  /// Controls how time is driven. Defaults to [ShaderAnimationMode.continuous].
  final ShaderAnimationMode animationMode;

  /// External time value used when [animationMode] == [ShaderAnimationMode.implicit].
  final double time;

  /// Animation configuration used when
  /// [animationMode] == [ShaderAnimationMode.explicit].
  final ShaderAnimationConfig? animationConfig;

  /// Wraps the shader subtree in a [RepaintBoundary] to isolate it from
  /// ancestor repaints.
  ///
  /// The shader's own per-frame updates already stay contained (the inner
  /// render object is its own repaint boundary). This flag adds isolation in
  /// the other direction: when an ancestor repaints, the cached composited
  /// layer is reused instead of walking into the shader subtree.
  ///
  /// **When to enable:** the shader is static or slow-moving and lives inside
  /// a parent that repaints often (a scrollable list, a screen with other
  /// animations, a rebuilding layout). Safe to leave `false` when the shader
  /// is the only thing animating or the parent tree is stable.
  final bool cache;

  @override
  State<ShaderWrap> createState() => _ShaderWrapState();
}

class _ShaderWrapState extends State<ShaderWrap>
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
        _time.value = (elapsed.inMilliseconds % rolloverMs).toDouble() / 1000;
        break;
      case ShaderAnimationMode.explicit:
        _time.value =
            _computeProgress(elapsed, widget.animationConfig!);
        break;
      case ShaderAnimationMode.implicit:
        break;
    }
  }

  /// Converts raw elapsed time into 0-1 progress using [ShaderAnimationConfig].
  double _computeProgress(Duration elapsed, ShaderAnimationConfig config) {
    final delayUs = config.delay.inMicroseconds.toDouble();
    final durationUs = config.duration.inMicroseconds.toDouble();
    final elapsedUs = elapsed.inMicroseconds.toDouble();

    if (elapsedUs < delayUs) return 0.0;
    if (durationUs <= 0) return 1.0;

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

    return config.curve.transform(linear.clamp(0.0, 1.0));
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
  void didUpdateWidget(ShaderWrap oldWidget) {
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
    Widget result = ShaderBuilder(
      (context, shader, child) {
        return AnimatedSamplerRepaint(
          (image, size, canvas) {
            shader
              ..setFloatUniforms((uniforms) {
                widget.uniformsCallback(uniforms, size, _time.value);
              })
              ..setImageSampler(0, image);

            canvas.drawRect(
              Rect.fromLTWH(0, 0, size.width, size.height),
              Paint()..shader = shader,
            );
          },
          repaint: _time,
          child: widget.child,
        );
      },
      assetKey: widget.shaderPath,
    );

    if (widget.onPointerDown != null) {
      result = Listener(
        onPointerDown: widget.onPointerDown,
        child: result,
      );
    }

    if (widget.cache) {
      result = RepaintBoundary(child: result);
    }

    return result;
  }
}
