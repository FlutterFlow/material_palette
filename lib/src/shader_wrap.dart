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
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
  });

  final Widget child;
  final String shaderPath;
  final UniformsCallback uniformsCallback;
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
  State<ShaderWrap> createState() => _ShaderWrapState();
}

class _ShaderWrapState extends State<ShaderWrap>
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
          _time.value = elapsed.inMilliseconds.toDouble() / 1000;
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
  void didUpdateWidget(ShaderWrap oldWidget) {
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
