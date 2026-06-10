import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'bench_uniforms.dart';

/// One benchmark configuration: a widget tree rebuilt each frame with
/// deterministic virtual time.
class BenchConfig {
  final String id;

  /// Logical size of the shader area; null = fill the window.
  final Size? size;
  final String notes;

  /// Shader assets this config depends on (for BENCH_VALIDATE_ONLY).
  final List<String> shaderAssets;

  /// Builds the subtree. [t] is virtual time in seconds (frame / 60);
  /// [size] is the resolved logical size.
  final Widget Function(double t, Size size) builder;

  const BenchConfig({
    required this.id,
    required this.size,
    required this.notes,
    required this.shaderAssets,
    required this.builder,
  });
}

const Size kStdSize = Size(480, 640);

// ── Definitions & standard children ─────────────────────────────────────────

final _iwrapDef = shaderDefinitionsByName[ShaderNames.iridescentLiquidWrap]!;
final _furDef = shaderDefinitionsByName[ShaderNames.furPlanarMask]!;
final _iliqDef = shaderDefinitionsByName[ShaderNames.iridescentLiquid]!;

Color _opaque(Color c) =>
    Color.from(alpha: 1.0, red: c.r, green: c.g, blue: c.b);

/// Child paint color for the iridescent wrap: when passColor.a > 0 the shader
/// requires an exact color match, otherwise the child's alpha is the mask.
Color get _iwrapChildColor {
  final pc = _iwrapDef.defaults.getColor('passColor');
  return pc.a > 0 ? _opaque(pc) : Colors.white;
}

/// Child paint color for fur: must match maskColor within maskThreshold.
Color get _furChildColor => _opaque(_furDef.defaults.getColor('maskColor'));

const _iwrapAsset = 'packages/material_palette/shaders/iridescent_liquid_wrap.frag';
const _furAsset = 'packages/material_palette/shaders/fur_planar_mask.frag';
const _iliqAsset = 'packages/material_palette/shaders/iridescent_liquid.frag';
const _perlinAsset = 'packages/material_palette/shaders/perlin_gradient.frag';
const _passthroughAsset = 'shaders/profiling/bench_wrap_passthrough.frag';

String _iwrapVariant(String v) =>
    'shaders/profiling/bench_iridescent_wrap__$v.frag';
String _furVariant(String v) => 'shaders/profiling/bench_fur_mask__$v.frag';
String _iliqVariant(String v) =>
    'shaders/profiling/bench_iridescent_fill__$v.frag';

// ── Widget builders ──────────────────────────────────────────────────────────

Widget _prodIwrap(double t, {ShaderParams? params, Widget? child}) =>
    IridescentLiquidShaderWrap(
      params: params ?? _iwrapDef.defaults,
      animationMode: ShaderAnimationMode.implicit,
      time: t,
      child: child ?? benchCircle(_iwrapChildColor),
    );

Widget _prodFur(double t, {ShaderParams? params, Widget? child}) =>
    FurPlanarMaskShaderWrap(
      params: params ?? _furDef.defaults,
      animationMode: ShaderAnimationMode.implicit,
      time: t,
      interactive: false,
      child: child ?? benchCircle(_furChildColor),
    );

Widget _prodIliq(double t, Size size) => IridescentLiquidShaderFill(
      width: size.width,
      height: size.height,
      animationMode: ShaderAnimationMode.implicit,
      time: t,
    );

/// Generic-widget binding for iridescent wrap variants (and parity).
Widget _benchIwrap(double t, String asset, {ShaderParams? params}) {
  final p = params ?? _iwrapDef.defaults;
  return ShaderWrap(
    shaderPath: asset,
    uniformsCallback: (uniforms, size, time) =>
        setIridescentWrapUniforms(uniforms, size, time, p),
    animationMode: ShaderAnimationMode.implicit,
    time: t,
    child: benchCircle(_iwrapChildColor),
  );
}

/// Generic-widget binding for fur variants, with deterministic clicks.
Widget _benchFur(double t, String asset,
    {ShaderParams? params, int clicks = 0, Widget? child}) {
  final p = params ?? _furDef.defaults;
  final benchClicks = BenchClicks(clicks);
  return ShaderWrap(
    shaderPath: asset,
    uniformsCallback: (uniforms, size, time) =>
        setFurMaskUniforms(uniforms, size, time, p, benchClicks),
    animationMode: ShaderAnimationMode.implicit,
    time: t,
    child: child ?? benchCircle(_furChildColor),
  );
}

/// Generic-widget binding for iridescent fill variants.
Widget _benchIliq(double t, Size size, String asset) => ShaderFill(
      width: size.width,
      height: size.height,
      shaderPath: asset,
      uniformsCallback: (shader, size, time) => setShaderUniforms(
          shader, size, time, _iliqDef.defaults, _iliqDef.layout),
      animationMode: ShaderAnimationMode.implicit,
      time: t,
    );

/// 3×3 grid of independent shader instances (gallery scenario).
Widget _grid9(Widget Function() cell) => Column(
      children: [
        for (int r = 0; r < 3; r++)
          Expanded(
            child: Row(
              children: [
                for (int c = 0; c < 3; c++) Expanded(child: cell()),
              ],
            ),
          ),
      ],
    );

// ── Config lists ─────────────────────────────────────────────────────────────

List<BenchConfig> baseConfigs() => [
      BenchConfig(
        id: 'base.empty',
        size: kStdSize,
        notes: 'harness floor: no shader, time driver running',
        shaderAssets: const [],
        builder: (t, size) => const ColoredBox(color: Color(0xFF30343B)),
      ),
      BenchConfig(
        id: 'base.perlin',
        size: kStdSize,
        notes: 'cheap-shader reference (production PerlinGradient fill)',
        shaderAssets: const [_perlinAsset],
        builder: (t, size) => PerlinGradientShaderFill(
          width: size.width,
          height: size.height,
          animationMode: ShaderAnimationMode.implicit,
          time: t,
        ),
      ),
      BenchConfig(
        id: 'base.passthru.480',
        size: kStdSize,
        notes: 'AnimatedSampler child-capture tax: 1:1 passthrough wrap',
        shaderAssets: const [_passthroughAsset],
        builder: (t, size) => ShaderWrap(
          shaderPath: _passthroughAsset,
          uniformsCallback: setPassthroughUniforms,
          animationMode: ShaderAnimationMode.implicit,
          time: t,
          child: benchImage(),
        ),
      ),
      BenchConfig(
        id: 'base.passthru.full',
        size: null,
        notes: 'child-capture tax at full window size',
        shaderAssets: const [_passthroughAsset],
        builder: (t, size) => ShaderWrap(
          shaderPath: _passthroughAsset,
          uniformsCallback: setPassthroughUniforms,
          animationMode: ShaderAnimationMode.implicit,
          time: t,
          child: benchImage(),
        ),
      ),
      BenchConfig(
        id: 'base.iwrap.tiny',
        size: const Size(16, 16),
        notes: 'UI-thread uniform cost (~93 setFloats): read build, not raster',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) => _prodIwrap(t),
      ),
    ];

List<BenchConfig> prodConfigs() => [
      // ── iridescent_liquid_wrap ──
      BenchConfig(
        id: 'prod.iwrap.480',
        size: kStdSize,
        notes: 'defaults (contour ON), circle child',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) => _prodIwrap(t),
      ),
      BenchConfig(
        id: 'prod.iwrap.256',
        size: const Size(256, 256),
        notes: 'fill-rate scaling: small',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) => _prodIwrap(t),
      ),
      BenchConfig(
        id: 'prod.iwrap.full',
        size: null,
        notes: 'fill-rate scaling: full window',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) => _prodIwrap(t),
      ),
      BenchConfig(
        id: 'prod.iwrap.contour0',
        size: kStdSize,
        notes: 'contour=0: whole edge-distance raycast gated OFF',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) =>
            _prodIwrap(t, params: _iwrapDef.defaults.withValue('contour', 0.0)),
      ),
      BenchConfig(
        id: 'prod.iwrap.contour1',
        size: kStdSize,
        notes: 'contour=1: confirms cost is gate-shaped, not magnitude-shaped',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) =>
            _prodIwrap(t, params: _iwrapDef.defaults.withValue('contour', 1.0)),
      ),
      BenchConfig(
        id: 'prod.iwrap.edgeband48',
        size: kStdSize,
        notes: 'edgeBandPx=48: larger raycast search radius',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) => _prodIwrap(t,
            params: _iwrapDef.defaults.withValue('edgeBandPx', 48.0)),
      ),
      BenchConfig(
        id: 'prod.iwrap.child_rect',
        size: kStdSize,
        notes: 'full-coverage child: interior rays never exit (worst case)',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) => _prodIwrap(t, child: benchRect(_iwrapChildColor)),
      ),
      BenchConfig(
        id: 'prod.iwrap.child_text',
        size: kStdSize,
        notes: 'sparse glyph child: most pixels exit early (best case)',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) => _prodIwrap(t, child: benchText(_iwrapChildColor)),
      ),
      BenchConfig(
        id: 'prod.iwrap.x9',
        size: kStdSize,
        notes: '3x3 grid of independent instances (gallery scenario)',
        shaderAssets: const [_iwrapAsset],
        builder: (t, size) => _grid9(() => _prodIwrap(t)),
      ),

      // ── iridescent_liquid (fill) ──
      BenchConfig(
        id: 'prod.iliq.480',
        size: kStdSize,
        notes: 'defaults',
        shaderAssets: const [_iliqAsset],
        builder: _prodIliq,
      ),
      BenchConfig(
        id: 'prod.iliq.full',
        size: null,
        notes: 'fill-rate scaling: full window',
        shaderAssets: const [_iliqAsset],
        builder: _prodIliq,
      ),
      BenchConfig(
        id: 'prod.iliq.x9',
        size: kStdSize,
        notes: '3x3 grid of independent instances',
        shaderAssets: const [_iliqAsset],
        builder: (t, size) => _grid9(
            () => _prodIliq(t, Size(size.width / 3, size.height / 3))),
      ),

      // ── fur_planar_mask ──
      BenchConfig(
        id: 'prod.fur.480',
        size: kStdSize,
        notes: 'defaults, clicks=0 (wavelets gated OFF), circle child',
        shaderAssets: const [_furAsset],
        builder: (t, size) => _prodFur(t),
      ),
      BenchConfig(
        id: 'prod.fur.256',
        size: const Size(256, 256),
        notes: 'fill-rate scaling: small',
        shaderAssets: const [_furAsset],
        builder: (t, size) => _prodFur(t),
      ),
      BenchConfig(
        id: 'prod.fur.full',
        size: null,
        notes: 'fill-rate scaling: full window',
        shaderAssets: const [_furAsset],
        builder: (t, size) => _prodFur(t),
      ),
      BenchConfig(
        id: 'prod.fur.clicks1',
        size: kStdSize,
        notes: '1 deterministic mid-life click (wavelet path ON)',
        shaderAssets: const [_furAsset],
        builder: (t, size) => _benchFur(t, _furAsset, clicks: 1),
      ),
      BenchConfig(
        id: 'prod.fur.clicks5',
        size: kStdSize,
        notes: '5 deterministic mid-life clicks (wavelet worst case)',
        shaderAssets: const [_furAsset],
        builder: (t, size) => _benchFur(t, _furAsset, clicks: 5),
      ),
      BenchConfig(
        id: 'prod.fur.child_rect',
        size: kStdSize,
        notes: 'full-density child: no early-continue, full lighting per step',
        shaderAssets: const [_furAsset],
        builder: (t, size) => _prodFur(t, child: benchRect(_furChildColor)),
      ),
      BenchConfig(
        id: 'prod.fur.child_text',
        size: kStdSize,
        notes: 'sparse child: isolates the unconditional 5-taps/step floor',
        shaderAssets: const [_furAsset],
        builder: (t, size) => _prodFur(t, child: benchText(_furChildColor)),
      ),
      BenchConfig(
        id: 'prod.fur.noise80',
        size: kStdSize,
        notes: 'furNoiseScale=80: hash-grid frequency sensitivity',
        shaderAssets: const [_furAsset],
        builder: (t, size) => _prodFur(t,
            params: _furDef.defaults.withValue('furNoiseScale', 80.0)),
      ),
    ];

List<BenchConfig> variantConfigs() {
  const iwrapVariants = {
    'base': 'parity anchor (byte-copy of production)',
    'dirs16': 'NUM_DIRS 32->16',
    'dirs8': 'NUM_DIRS 32->8',
    'coarse4': 'NUM_COARSE 8->4 (search span kept)',
    'warp1': '1 warpMap instead of 3 (no chromatic aberration)',
    'nobump': 'bump warpShape tap stubbed (4th warpShape)',
    'fbm2oct': 'fbm 4->2 octaves',
    'noise_const': 'fbm()->0: total noise floor',
  };
  const furVariants = {
    'base': 'parity anchor (byte-copy of production)',
    'steps32': 'RAY_STEPS 64->32, RAY_STEP x2 (span kept)',
    'steps16': 'RAY_STEPS 64->16, RAY_STEP x4 (span kept)',
    'noedgelean': '4 mask-gradient taps/step dropped',
    'gradstub': 'fastGradient -> constant normal',
    'lightstub': '4-light shading -> ambient only',
    'noise_const': 'proceduralNoise()->0.5',
  };
  const iliqVariants = {
    'base': 'parity anchor (byte-copy of production)',
    'warp1': '1 warpMap instead of 3',
    'fbm2oct': 'fbm 4->2 octaves',
    'noise_const': 'fbm()->0: total noise floor',
  };

  return [
    for (final e in iwrapVariants.entries)
      BenchConfig(
        id: 'bench.iwrap.${e.key}',
        size: kStdSize,
        notes: e.value,
        shaderAssets: [_iwrapVariant(e.key)],
        builder: (t, size) => _benchIwrap(t, _iwrapVariant(e.key)),
      ),
    for (final e in furVariants.entries)
      BenchConfig(
        id: 'bench.fur.${e.key}',
        size: kStdSize,
        notes: e.value,
        shaderAssets: [_furVariant(e.key)],
        builder: (t, size) => _benchFur(t, _furVariant(e.key)),
      ),
    for (final e in iliqVariants.entries)
      BenchConfig(
        id: 'bench.iliq.${e.key}',
        size: kStdSize,
        notes: e.value,
        shaderAssets: [_iliqVariant(e.key)],
        builder: (t, size) => _benchIliq(t, size, _iliqVariant(e.key)),
      ),
  ];
}
