import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'bench_configs.dart';
import 'bench_uniforms.dart';

/// All-shader survey: one config per registered shader, constructed via the
/// production widgets with `shaderDefinitionsByName` defaults — mirroring how
/// the example app's carousel cards build them (fills standalone, wraps
/// around a static photo). Time is driven deterministically:
/// - time-based shaders get virtual seconds,
/// - progress-based dissolves get a ping-pong sweep (their continuous-mode
///   behavior), so the effect is actually exercised mid-transition,
/// - interaction-gated shaders run in their passive default state and are
///   flagged `[inactive-interaction]` in the notes.

/// Shaders whose tap/drag-activated cost is NOT exercised passively.
const _interactionGated = {
  ShaderNames.taplets,
  ShaderNames.smarble,
  ShaderNames.tapBurn,
  ShaderNames.tapSmoke,
  ShaderNames.tapPixelDissolve,
  ShaderNames.tapSlurp,
  ShaderNames.furPlanar,
  ShaderNames.furPlanarMask,
};

/// Progress-based wraps: in implicit mode `time` is the 0-1 progress.
const _progressBased = {
  ShaderNames.burn,
  ShaderNames.radialBurn,
  ShaderNames.smoke,
  ShaderNames.radialSmoke,
  ShaderNames.pixelDissolve,
  ShaderNames.radialPixelDissolve,
  ShaderNames.peelWrap,
};

String _slug(String name) =>
    name.toLowerCase().replaceAll(' ', '_');

double _progress(double t, ShaderParams p) {
  final speed = p.get('speed');
  return pingPong(t * (speed > 0 ? speed : 0.5));
}

List<BenchConfig> surveyConfigs() {
  return [
    for (final name in allShaderNames)
      () {
        final def = shaderDefinitionsByName[name]!;
        final flags = [
          def.hasChildren ? 'wrap' : 'fill',
          if (_interactionGated.contains(name)) '[inactive-interaction]',
          if (_progressBased.contains(name)) '[progress ping-pong]',
        ].join(' ');
        return BenchConfig(
          id: 'survey.${_slug(name)}',
          size: kStdSize,
          notes: 'defaults; $flags',
          shaderAssets: [def.assetPath],
          builder: (t, size) => _buildSurveyWidget(name, def, t, size),
        );
      }(),
  ];
}

Widget _buildSurveyWidget(
    String name, ShaderDefinition def, double t, Size size) {
  const mode = ShaderAnimationMode.implicit;
  final p = def.defaults;
  final w = size.width, h = size.height;
  final tt = _progressBased.contains(name) ? _progress(t, p) : t;

  switch (name) {
    // ── Gradient fills ──
    case ShaderNames.gritient:
      return GrittyGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.radient:
      return RadialGrittyGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.perlin:
      return PerlinGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.radialPerlin:
      return RadialPerlinGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.simplex:
      return SimplexGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.radialSimplex:
      return RadialSimplexGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.fbm:
      return FbmGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.radialFbm:
      return RadialFbmGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.turbulence:
      return TurbulenceGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.radialTurbulence:
      return RadialTurbulenceGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.voronoi:
      return VoronoiGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.radialVoronoi:
      return RadialVoronoiGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.voronoise:
      return VoronoiseGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.radialVoronoise:
      return RadialVoronoiseGradientShaderFill(
          width: w, height: h, animationMode: mode, time: tt);

    // ── Special fills ──
    case ShaderNames.smarble:
      return MarbleSmearShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.liquidPatina:
      return LiquidPatinaShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.metalSmoke:
      return MetalSmokeShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.iridescentLiquid:
      return IridescentLiquidShaderFill(
          width: w, height: h, animationMode: mode, time: tt);
    case ShaderNames.furPlanar:
      return FurPlanarShaderFill(
          width: w, height: h, animationMode: mode, time: tt);

    // ── Wraps around a photo (as the example cards do) ──
    case ShaderNames.ripples:
      return RippleShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.taplets:
      return ClickableRippleShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.burn:
      return BurnShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.radialBurn:
      return RadialBurnShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.tapBurn:
      return TappableBurnShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.smoke:
      return SmokeShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.radialSmoke:
      return RadialSmokeShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.tapSmoke:
      return TappableSmokeShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.pixelDissolve:
      return PixelDissolveShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.radialPixelDissolve:
      return RadialPixelDissolveShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.tapPixelDissolve:
      return TappablePixelDissolveShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.tapSlurp:
      return TappableSlurpShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.turbulenceWrap:
      return TurbulenceShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.ditherWrap:
      return DitherShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.peelWrap:
      return PeelShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.crepuscularRays:
      return CrepuscularRaysShaderWrap(
          animationMode: mode, time: tt, child: benchImage());
    case ShaderNames.kuwaharaWrap:
      return KuwaharaShaderWrap(
          animationMode: mode, time: tt, child: benchImage());

    // ── Mask-driven wraps: child painted in the exact mask/pass color ──
    case ShaderNames.furPlanarMask:
      final mask = def.defaults.getColor('maskColor');
      return FurPlanarMaskShaderWrap(
        animationMode: mode,
        time: tt,
        interactive: false,
        child: benchCircle(Color.from(
            alpha: 1.0, red: mask.r, green: mask.g, blue: mask.b)),
      );
    case ShaderNames.iridescentLiquidWrap:
      return IridescentLiquidShaderWrap(
          animationMode: mode, time: tt, child: benchText(Colors.white));

    default:
      throw StateError('Survey has no builder for shader "$name"');
  }
}
