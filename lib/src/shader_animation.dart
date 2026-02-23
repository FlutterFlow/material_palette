import 'package:flutter/animation.dart';

/// A custom easing curve: quintic ease-in-out (t^5 polynomial).
///
/// Flutter doesn't include this built-in. The curve accelerates sharply
/// at the start and decelerates sharply at the end, producing a more
/// pronounced "snap" than the cubic [Curves.easeInOut].
class EaseInOutQuintCurve extends Curve {
  const EaseInOutQuintCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.5) {
      return 16 * t * t * t * t * t;
    } else {
      final p = -2.0 * t + 2.0;
      return 1.0 - p * p * p * p * p / 2.0;
    }
  }
}

/// A pre-configured, self-managing animation that drives shader progress
/// from 0 to 1.
///
/// Extends [Animation<double>] so it fits directly into the existing
/// `animation` parameter on [ShaderWrap], [ShaderFill], and all shader
/// wrapper widgets.
///
/// Unlike a raw [AnimationController], [ShaderAnimation] is "lazy": it
/// doesn't need a [TickerProvider] at construction time. Instead, the
/// hosting widget (e.g. [ShaderWrap]) calls [attach] to provide one, and
/// [detach] to clean up.
///
/// ```dart
/// BurnShaderWrap(
///   animationMode: ShaderAnimationMode.animation,
///   animation: ShaderAnimation.easeInOut(duration: Duration(seconds: 2)),
///   child: myWidget,
/// )
/// ```
class ShaderAnimation extends Animation<double> {
  /// Creates a shader animation with full control over every parameter.
  ShaderAnimation({
    this.duration = const Duration(seconds: 3),
    this.delay = Duration.zero,
    this.curve = Curves.linear,
    this.loop = false,
    this.reverse = false,
  });

  /// Linear animation (no easing).
  ShaderAnimation.linear({
    Duration duration = const Duration(seconds: 3),
    Duration delay = Duration.zero,
    bool loop = false,
    bool reverse = false,
  }) : this(
          duration: duration,
          delay: delay,
          curve: Curves.linear,
          loop: loop,
          reverse: reverse,
        );

  /// Ease-in animation (starts slow, accelerates).
  ShaderAnimation.easeIn({
    Duration duration = const Duration(seconds: 3),
    Duration delay = Duration.zero,
    bool loop = false,
    bool reverse = false,
  }) : this(
          duration: duration,
          delay: delay,
          curve: Curves.easeIn,
          loop: loop,
          reverse: reverse,
        );

  /// Ease-in-out animation (slow start and end, fast middle).
  ShaderAnimation.easeInOut({
    Duration duration = const Duration(seconds: 3),
    Duration delay = Duration.zero,
    bool loop = false,
    bool reverse = false,
  }) : this(
          duration: duration,
          delay: delay,
          curve: Curves.easeInOut,
          loop: loop,
          reverse: reverse,
        );

  /// Ease-out animation (starts fast, decelerates).
  ShaderAnimation.easeOut({
    Duration duration = const Duration(seconds: 3),
    Duration delay = Duration.zero,
    bool loop = false,
    bool reverse = false,
  }) : this(
          duration: duration,
          delay: delay,
          curve: Curves.easeOut,
          loop: loop,
          reverse: reverse,
        );

  /// Bounce animation (bounces at the end).
  ShaderAnimation.bounce({
    Duration duration = const Duration(seconds: 3),
    Duration delay = Duration.zero,
    bool loop = false,
    bool reverse = false,
  }) : this(
          duration: duration,
          delay: delay,
          curve: Curves.bounceOut,
          loop: loop,
          reverse: reverse,
        );

  /// Elastic animation (overshoots with spring-like motion at both ends).
  ShaderAnimation.elastic({
    Duration duration = const Duration(seconds: 3),
    Duration delay = Duration.zero,
    bool loop = false,
    bool reverse = false,
  }) : this(
          duration: duration,
          delay: delay,
          curve: Curves.elasticInOut,
          loop: loop,
          reverse: reverse,
        );

  /// Elastic-out animation (overshoots then settles).
  ShaderAnimation.elasticOut({
    Duration duration = const Duration(seconds: 3),
    Duration delay = Duration.zero,
    bool loop = false,
    bool reverse = false,
  }) : this(
          duration: duration,
          delay: delay,
          curve: Curves.elasticOut,
          loop: loop,
          reverse: reverse,
        );

  /// Elastic-in animation (pulls back before moving forward).
  ShaderAnimation.elasticIn({
    Duration duration = const Duration(seconds: 3),
    Duration delay = Duration.zero,
    bool loop = false,
    bool reverse = false,
  }) : this(
          duration: duration,
          delay: delay,
          curve: Curves.elasticIn,
          loop: loop,
          reverse: reverse,
        );

  /// Quintic ease-in-out (sharper snap than standard easeInOut).
  ShaderAnimation.easeInOutQuint({
    Duration duration = const Duration(seconds: 3),
    Duration delay = Duration.zero,
    bool loop = false,
    bool reverse = false,
  }) : this(
          duration: duration,
          delay: delay,
          curve: const EaseInOutQuintCurve(),
          loop: loop,
          reverse: reverse,
        );

  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool loop;
  final bool reverse;

  // Internal state (created when attached by ShaderWrap/ShaderFill)
  AnimationController? _controller;
  CurvedAnimation? _curved;

  /// Called by the hosting widget to provide a [TickerProvider] and start
  /// the animation.
  void attach(TickerProvider vsync) {
    if (_controller != null) return; // already attached

    final totalMs = delay.inMilliseconds + duration.inMilliseconds;
    _controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: totalMs),
    );

    final delayFraction = totalMs > 0 ? delay.inMilliseconds / totalMs : 0.0;
    _curved = CurvedAnimation(
      parent: _controller!,
      curve: Interval(delayFraction, 1.0, curve: curve),
    );

    if (loop) {
      _controller!.repeat(reverse: reverse);
    } else {
      _controller!.forward();
    }
  }

  /// Called by the hosting widget to tear down the animation.
  void detach() {
    _curved?.dispose();
    _controller?.dispose();
    _curved = null;
    _controller = null;
  }

  @override
  double get value => _curved?.value ?? 0.0;

  @override
  AnimationStatus get status =>
      _controller?.status ?? AnimationStatus.dismissed;

  @override
  void addListener(VoidCallback listener) {
    _curved?.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _curved?.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    _controller?.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    _controller?.removeStatusListener(listener);
  }

  /// Returns a copy with [loop] set to true.
  ShaderAnimation looped() => ShaderAnimation(
        duration: duration,
        delay: delay,
        curve: curve,
        loop: true,
        reverse: reverse,
      );

  /// Returns a copy with [reverse] set to true.
  ShaderAnimation reversed() => ShaderAnimation(
        duration: duration,
        delay: delay,
        curve: curve,
        loop: loop,
        reverse: true,
      );

  /// Returns a copy with both [loop] and [reverse] set to true (ping-pong).
  ShaderAnimation loopedReversed() => ShaderAnimation(
        duration: duration,
        delay: delay,
        curve: curve,
        loop: true,
        reverse: true,
      );

  /// Returns a copy with any subset of parameters overridden.
  ShaderAnimation copyWith({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    bool? loop,
    bool? reverse,
  }) =>
      ShaderAnimation(
        duration: duration ?? this.duration,
        delay: delay ?? this.delay,
        curve: curve ?? this.curve,
        loop: loop ?? this.loop,
        reverse: reverse ?? this.reverse,
      );
}
