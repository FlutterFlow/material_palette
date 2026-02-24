import 'package:flutter/material.dart';
import 'package:material_palette/src/shader_params.dart';

/// An [ImplicitlyAnimatedWidget] that smoothly transitions [ShaderParams]
/// (and an optional [backgroundColor]) whenever they change.
///
/// Wrap any preset shader widget with this to get Flutter-style implicit
/// animation of shader parameters:
///
/// ```dart
/// AnimatedShaderParams(
///   params: currentParams,
///   backgroundColor: bgColor,
///   duration: Duration(milliseconds: 500),
///   curve: Curves.easeInOut,
///   builder: (params, backgroundColor) => GrittyGradientShaderFill(
///     params: params,
///     backgroundColor: backgroundColor,
///   ),
/// )
/// ```
class AnimatedShaderParams extends ImplicitlyAnimatedWidget {
  const AnimatedShaderParams({
    super.key,
    required this.params,
    this.backgroundColor,
    required this.builder,
    required super.duration,
    super.curve = Curves.linear,
  });

  /// The target shader parameters. When these change, the widget animates
  /// from the previous values to the new ones.
  final ShaderParams params;

  /// Optional background color to animate alongside the params.
  final Color? backgroundColor;

  /// Builder that receives the currently-animated param and background color
  /// values and returns the shader widget to render.
  final Widget Function(ShaderParams params, Color? backgroundColor) builder;

  @override
  AnimatedShaderParamsState createState() => AnimatedShaderParamsState();
}

/// State for [AnimatedShaderParams].
class AnimatedShaderParamsState
    extends AnimatedWidgetBaseState<AnimatedShaderParams> {
  ShaderParamsTween? _paramsTween;
  ColorTween? _bgColorTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _paramsTween = visitor(
      _paramsTween,
      widget.params,
      (value) => ShaderParamsTween(begin: value as ShaderParams),
    ) as ShaderParamsTween?;
    if (widget.backgroundColor != null) {
      _bgColorTween = visitor(
        _bgColorTween,
        widget.backgroundColor,
        (value) => ColorTween(begin: value as Color?),
      ) as ColorTween?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      _paramsTween!.evaluate(animation),
      _bgColorTween?.evaluate(animation) ?? widget.backgroundColor,
    );
  }
}
