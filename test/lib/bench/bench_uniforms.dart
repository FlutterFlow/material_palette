import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart' show UniformsSetter;
import 'package:material_palette/material_palette.dart';

/// Hand-rolled uniform writers for the bench variant shaders.
///
/// These MUST mirror the uniform order of the production widgets byte-for-byte
/// (`lib/src/shaders/iridescent_liquid_wrap_shader_wrap.dart` and
/// `fur_planar_mask_shader_wrap.dart`). The `base.parity.*` configs verify
/// this: a production-widget config and a hand-rolled `__base` variant config
/// must produce identical visuals and timings.

/// Iridescent liquid wrap layout (~93 floats), identical to
/// [IridescentLiquidShaderWrap]'s uniformsCallback.
void setIridescentWrapUniforms(
    UniformsSetter uniforms, Size size, double time, ShaderParams p) {
  final colorBack = p.getColor('colorBack');
  final colorTint = p.getColor('colorTint');
  final passColor = p.getColor('passColor');

  uniforms
    ..setSize(size)
    ..setFloat(time)
    ..setFloat(p.get('repetition'))
    ..setFloat(p.get('softness'))
    ..setFloat(p.get('distortion'))
    ..setFloat(p.get('contour'))
    ..setFloat(p.get('angleDeg'))
    ..setFloat(p.get('stripeDiagaBias'))
    ..setFloat(p.get('stripeTwist'))
    ..setFloat(p.get('stripeCount'))
    ..setFloat(p.get('stripeThickness'))
    ..setFloat(p.get('stripeOffset'))
    ..setFloat(p.get('stripeFalloff'))
    ..setFloat(p.get('stripeSpeed'))
    ..setFloat(p.get('shiftRed'))
    ..setFloat(p.get('shiftBlue'))
    ..setFloat(colorBack.r)
    ..setFloat(colorBack.g)
    ..setFloat(colorBack.b)
    ..setFloat(colorBack.a)
    ..setFloat(colorTint.r)
    ..setFloat(colorTint.g)
    ..setFloat(colorTint.b)
    ..setFloat(colorTint.a)
    ..setFloat(passColor.r)
    ..setFloat(passColor.g)
    ..setFloat(passColor.b)
    ..setFloat(passColor.a)
    ..setFloat(p.get('edgeBandPx'))
    ..setFloat(p.get('edgeSmoothness'))
    ..setFloat(p.get('warpTimeScale'))
    ..setFloat(p.get('warpFreqInner'))
    ..setFloat(p.get('warpFreqMiddle'))
    ..setFloat(p.get('warpFreqHigh'))
    ..setFloat(p.get('fbmScaleFactor'))
    ..setFloat(p.get('stripeRippleStrength'))
    ..setFloat(p.get('bumpWarpWeight'))
    ..setFloat(p.get('paletteStops'));
  for (int i = 0; i < 10; i++) {
    final c = p.getColor('color$i');
    uniforms
      ..setFloat(c.r)
      ..setFloat(c.g)
      ..setFloat(c.b)
      ..setFloat(c.a);
  }
}

/// Deterministic synthetic clicks for the fur mask shader.
///
/// The production widget derives click elapsed time from wall-clock
/// `DateTime.now()`, which is non-reproducible. Here each click's elapsed
/// time cycles in [0.3, 1.8] s of *virtual* time, so wavelets stay
/// mid-life (and therefore active) for the whole measurement window of
/// every run.
class BenchClicks {
  final int count;
  const BenchClicks(this.count);

  static const List<Offset> _fracs = [
    Offset(0.30, 0.30),
    Offset(0.70, 0.30),
    Offset(0.50, 0.50),
    Offset(0.30, 0.70),
    Offset(0.70, 0.70),
  ];

  /// Position in the shader's normalized space (matches the production
  /// widget's `_normalizePosition`).
  Offset normPos(int i, Size size) {
    final f = _fracs[i];
    final local = Offset(f.dx * size.width, f.dy * size.height);
    final minDim = size.width < size.height ? size.width : size.height;
    return Offset(
      (local.dx - 0.5 * size.width) / minDim,
      (local.dy - 0.5 * size.height) / minDim,
    );
  }

  double elapsed(int i, double t) => 0.3 + ((t + i * 0.37) % 1.5);
}

/// Fur planar mask layout, identical to [FurPlanarMaskShaderWrap]'s
/// uniformsCallback, with deterministic click uniforms.
void setFurMaskUniforms(UniformsSetter uniforms, Size size, double time,
    ShaderParams p, BenchClicks clicks) {
  uniforms.setSize(size);
  uniforms.setFloat(time);

  final bg = p.getColor('bgColor');
  uniforms.setFloats([bg.r, bg.g, bg.b]);
  uniforms.setFloat(p.get('bgOpacity'));

  uniforms.setFloat(p.get('planeOffset'));
  uniforms.setFloat(p.get('furThickness'));

  uniforms.setFloat(p.get('furNoiseStrength'));
  uniforms.setFloat(p.get('furNoiseScale'));
  uniforms.setFloat(p.get('furWaveAmplitude'));
  uniforms.setFloat(p.get('furWaveFreqX'));
  uniforms.setFloat(p.get('furWaveFreqY'));
  uniforms.setFloat(p.get('furAnimationSpeed'));

  uniforms.setFloats(
      [p.get('keyLightDirX'), p.get('keyLightDirY'), p.get('keyLightDirZ')]);
  final keyColor = p.getColor('keyLightColor');
  uniforms.setFloats([keyColor.r, keyColor.g, keyColor.b]);
  uniforms.setFloat(p.get('keyLightIntensity'));

  uniforms.setFloats(
      [p.get('fillLightDirX'), p.get('fillLightDirY'), p.get('fillLightDirZ')]);
  final fillColor = p.getColor('fillLightColor');
  uniforms.setFloats([fillColor.r, fillColor.g, fillColor.b]);
  uniforms.setFloat(p.get('fillLightIntensity'));

  uniforms.setFloats(
      [p.get('rimLightDirX'), p.get('rimLightDirY'), p.get('rimLightDirZ')]);
  final rimColor = p.getColor('rimLightColor');
  uniforms.setFloats([rimColor.r, rimColor.g, rimColor.b]);
  uniforms.setFloat(p.get('rimLightIntensity'));

  final furColor = p.getColor('furColor');
  uniforms.setFloats([furColor.r, furColor.g, furColor.b]);

  uniforms.setFloat(p.get('gradientEps'));
  uniforms.setFloat(p.get('waveletSpeed'));
  uniforms.setFloat(p.get('waveletFreq'));
  uniforms.setFloat(p.get('waveletAmplitude'));
  uniforms.setFloat(p.get('waveletDecay'));
  uniforms.setFloat(p.get('waveletWidth'));

  final maskColor = p.getColor('maskColor');
  uniforms.setFloats([maskColor.r, maskColor.g, maskColor.b]);
  uniforms.setFloat(p.get('maskThreshold'));
  uniforms.setFloat(p.get('edgeLeanStrength'));

  uniforms.setFloat(clicks.count.toDouble());

  for (int i = 0; i < 5; i++) {
    if (i < clicks.count) {
      final pos = clicks.normPos(i, size);
      uniforms.setFloats([pos.dx, pos.dy]);
    } else {
      uniforms.setFloats([0.0, 0.0]);
    }
  }
  for (int i = 0; i < 5; i++) {
    uniforms.setFloat(i < clicks.count ? clicks.elapsed(i, time) : 0.0);
  }
}

/// Passthrough wrap: header only (uSize, uTime, sampler).
void setPassthroughUniforms(UniformsSetter uniforms, Size size, double time) {
  uniforms
    ..setSize(size)
    ..setFloat(time);
}

// ── Standard children for wrap configs ──────────────────────────────────────
//
// All const-stable: rebuilt every frame by the time driver, but identical
// widgets, so the child layer itself never repaints.

/// Full-coverage opaque rect. Interior pixels never find a mask edge —
/// worst case for the iridescent wrap's raycast, full-density for fur.
Widget benchRect(Color color) => ColoredBox(color: color);

/// Centered circle covering ~50% of the area (0.8 fraction → π/4·0.64 ≈ 0.5).
Widget benchCircle(Color color) => Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        heightFactor: 0.8,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );

/// Large glyph: ~15% coverage, lots of edges. Best case for early
/// mask-exit paths.
Widget benchText(Color color) => Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          'F',
          style: TextStyle(
            color: color,
            fontSize: 360,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

/// Static photo child, as the example app uses for its wrap cards.
Widget benchImage() => Image.asset(
      'assets/images/sunset.jpg',
      fit: BoxFit.cover,
    );
