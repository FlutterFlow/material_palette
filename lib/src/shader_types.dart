import 'dart:ui' show FragmentShader;

import 'package:flutter/material.dart';

/// Controls how a shader widget drives its time uniform.
enum ShaderAnimationMode {
  /// The shader animation is set based on the value of [time] passed to the widget.
  /// No internal ticker is created and the shader is not animated unless the widget is rebuilt.
  implicit,

  /// The shader animation runs continuously via an internal ticker without rebuilding the widget.
  /// Interactive shaders (pointer-driven) require this mode.
  continuous,

  /// An exact animation behavior runs based on the settings passed as a [ShaderAnimationConfig]
  /// without rebuilding the widget.
  explicit,
}

/// A single touch/tap point for interactive shaders.
class ShaderTouchPoint {
  final Offset position;
  final DateTime startTime;

  const ShaderTouchPoint({required this.position, required this.startTime});

  /// Returns time in seconds since this touch started.
  double get elapsed =>
      DateTime.now().difference(startTime).inMilliseconds / 1000.0;
}

/// Simple 3D offset class for light direction.
class Offset3D {
  final double x;
  final double y;
  final double z;

  const Offset3D(this.x, this.y, this.z);
}

/// Helpers for setting multi-component uniforms on a [FragmentShader].
extension FragmentShaderHelpers on FragmentShader {
  /// Sets r, g, b floats from [c] starting at [idx]. Returns next index.
  int setColor(int idx, Color c) {
    setFloat(idx, c.r);
    setFloat(idx + 1, c.g);
    setFloat(idx + 2, c.b);
    return idx + 3;
  }

  /// Sets x, y, z floats from [o] starting at [idx]. Returns next index.
  int setOffset3D(int idx, Offset3D o) {
    setFloat(idx, o.x);
    setFloat(idx + 1, o.y);
    setFloat(idx + 2, o.z);
    return idx + 3;
  }

  /// Sets dx, dy floats from [o] starting at [idx]. Returns next index.
  int setOffset2D(int idx, Offset o) {
    setFloat(idx, o.dx);
    setFloat(idx + 1, o.dy);
    return idx + 2;
  }
}

/// Defines the label and min/max range for a single slider control.
class SliderRange {
  final String label;
  final double min;
  final double max;
  const SliderRange(this.label, {required this.min, required this.max});
}

/// Converts a monotonically increasing value into a 0→1→0 ping-pong wave.
///
/// Useful for converting raw elapsed time (scaled by speed) into an
/// oscillating progress value in `continuous` animation mode.
double pingPong(double t) {
  final mod = t % 2.0;
  return mod <= 1.0 ? mod : 2.0 - mod;
}

/// A smudge gesture for interactive shaders (start → end drag).
class ShaderSmudgeData {
  final Offset startPosition;
  final Offset endPosition;
  final DateTime startTime;

  const ShaderSmudgeData({
    required this.startPosition,
    required this.endPosition,
    required this.startTime,
  });

  /// Returns time in seconds since this smudge started.
  double get elapsed =>
      DateTime.now().difference(startTime).inMilliseconds / 1000.0;

  /// Create a copy with an updated end position.
  ShaderSmudgeData copyWithEnd(Offset newEnd) => ShaderSmudgeData(
        startPosition: startPosition,
        endPosition: newEnd,
        startTime: startTime,
      );
}
