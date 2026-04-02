import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a fur effect to masked regions of a child widget.
///
/// The child widget is captured as a texture. The shader grows fur on regions
/// whose color matches [maskColor] (within [maskThreshold]). Fur at mask edges
/// leans outward based on [edgeLeanStrength]. Tapping creates wavelet ripples.
/// Supports up to 5 simultaneous tap points.
class FurPlanarMaskShaderWrap extends StatefulWidget {
  FurPlanarMaskShaderWrap({
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
  }) : params = params ?? furPlanarMaskedShaderDef.defaults;

  final Widget child;
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
      ShaderBuilder.precacheShader('packages/material_palette/shaders/fur_planar_mask.frag');

  @override
  State<FurPlanarMaskShaderWrap> createState() =>
      _FurPlanarMaskShaderWrapState();
}

class _FurPlanarMaskShaderWrapState extends State<FurPlanarMaskShaderWrap> {
  final List<ShaderTouchPoint> _clicks = [];

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _removeExpiredClicks();
      _clicks.add(ShaderTouchPoint(
        position: event.localPosition,
        startTime: DateTime.now(),
      ));
      if (_clicks.length > FurPlanarMaskShaderWrap.maxClicks) {
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
  Offset _normalizePosition(Offset localPosition, Size size) {
    final minDim = size.width < size.height ? size.width : size.height;
    return Offset(
      (localPosition.dx - 0.5 * size.width) / minDim,
      (localPosition.dy - 0.5 * size.height) / minDim,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.params;
    final clicks = widget.touchPoints ?? _clicks;

    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/fur_planar_mask.frag',
      uniformsCallback: (uniforms, size, time) {
        if (widget.touchPoints == null) {
          _removeExpiredClicks();
        }

        uniforms.setSize(size);
        uniforms.setFloat(time);

        // bgColor (vec3)
        final bg = p.getColor('bgColor');
        uniforms.setFloats([bg.r, bg.g, bg.b]);

        // Plane shape
        uniforms.setFloat(p.get('planeOffset'));
        uniforms.setFloat(p.get('furThickness'));

        // Fur pattern
        uniforms.setFloat(p.get('furNoiseStrength'));
        uniforms.setFloat(p.get('furNoiseScale'));
        uniforms.setFloat(p.get('furWaveAmplitude'));
        uniforms.setFloat(p.get('furWaveFreqX'));
        uniforms.setFloat(p.get('furWaveFreqY'));
        uniforms.setFloat(p.get('furAnimationSpeed'));

        // Key light (dir vec3 + color vec3 + intensity)
        uniforms.setFloats([p.get('keyLightDirX'), p.get('keyLightDirY'), p.get('keyLightDirZ')]);
        final keyColor = p.getColor('keyLightColor');
        uniforms.setFloats([keyColor.r, keyColor.g, keyColor.b]);
        uniforms.setFloat(p.get('keyLightIntensity'));

        // Fill light
        uniforms.setFloats([p.get('fillLightDirX'), p.get('fillLightDirY'), p.get('fillLightDirZ')]);
        final fillColor = p.getColor('fillLightColor');
        uniforms.setFloats([fillColor.r, fillColor.g, fillColor.b]);
        uniforms.setFloat(p.get('fillLightIntensity'));

        // Rim light
        uniforms.setFloats([p.get('rimLightDirX'), p.get('rimLightDirY'), p.get('rimLightDirZ')]);
        final rimColor = p.getColor('rimLightColor');
        uniforms.setFloats([rimColor.r, rimColor.g, rimColor.b]);
        uniforms.setFloat(p.get('rimLightIntensity'));

        // Fur color (vec3)
        final furColor = p.getColor('furColor');
        uniforms.setFloats([furColor.r, furColor.g, furColor.b]);

        // Gradient epsilon + wavelet params
        uniforms.setFloat(p.get('gradientEps'));
        uniforms.setFloat(p.get('waveletSpeed'));
        uniforms.setFloat(p.get('waveletFreq'));
        uniforms.setFloat(p.get('waveletAmplitude'));
        uniforms.setFloat(p.get('waveletDecay'));
        uniforms.setFloat(p.get('waveletWidth'));

        // Mask params
        final maskColor = p.getColor('maskColor');
        uniforms.setFloats([maskColor.r, maskColor.g, maskColor.b]);
        uniforms.setFloat(p.get('maskThreshold'));
        uniforms.setFloat(p.get('edgeLeanStrength'));

        // Click count
        uniforms.setFloat(clicks.length.toDouble());

        // Click positions (always send 5, padding with zeros)
        for (int i = 0; i < FurPlanarMaskShaderWrap.maxClicks; i++) {
          if (i < clicks.length) {
            final pos = _normalizePosition(clicks[i].position, size);
            uniforms.setFloats([pos.dx, pos.dy]);
          } else {
            uniforms.setFloats([0.0, 0.0]);
          }
        }

        // Click times — raw elapsed seconds
        for (int i = 0; i < FurPlanarMaskShaderWrap.maxClicks; i++) {
          uniforms.setFloat(i < clicks.length ? clicks[i].elapsed : 0.0);
        }
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
