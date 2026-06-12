import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_palette/material_palette.dart';

/// Guards the package's shader registry invariants: every shader definition
/// must be represented in the utility finals (and vice versa), carry a
/// stableVersion, and have its asset declared in the package pubspec. Catches
/// the "added a shader, forgot a registry surface" class of mistake.
void main() {
  final defs = shaderDefinitionsByName;

  test('allShaderNames matches the definitions map exactly', () {
    expect(allShaderNames.toSet(), defs.keys.toSet());
    expect(allShaderNames.length, defs.length,
        reason: 'duplicate entries in allShaderNames');
  });

  test('every shader has a ShaderCardData entry in allShaders', () {
    expect(allShaders.map((c) => c.title).toSet(), defs.keys.toSet());
  });

  test('every definition declares a stableVersion', () {
    final missing = [
      for (final e in defs.entries)
        if (e.value.stableVersion == null) e.key,
    ];
    expect(missing, isEmpty,
        reason: 'definitions without stableVersion: $missing');
  });

  test('allParamNames is exactly the union of definition params', () {
    // A shader's params surface in its uniform layout, its defaults
    // (tappable shaders carry widget-driven params that never appear as
    // layout fields), and its slider ranges.
    final used = <String>{
      for (final def in defs.values) ...[
        ...def.layout.fields.map((f) => f.key),
        ...def.defaults.values.keys,
        ...def.defaults.colors.keys,
        ...def.uiDefaults.ranges.keys,
      ],
    };
    expect(used.difference(allParamNames.toSet()), isEmpty,
        reason: 'params used by definitions but missing from allParamNames');
    expect(allParamNames.toSet().difference(used), isEmpty,
        reason: 'orphan allParamNames entries used by no definition');
  });

  test('every definition asset is declared in the package pubspec', () {
    // Test-app cwd is test/; the package pubspec lives one level up.
    final pubspec = File('../pubspec.yaml').readAsStringSync();
    final undeclared = [
      for (final e in defs.entries)
        if (!pubspec.contains(e.value.assetPath
            .replaceFirst('packages/material_palette/', 'lib/')))
          '${e.key} -> ${e.value.assetPath}',
    ];
    expect(undeclared, isEmpty,
        reason: 'shader assets missing from pubspec: $undeclared');
  });

  test('every shader fits the Metal uniform buffer caps', () {
    // Impeller's Metal runtime-effect path binds each uniform declaration —
    // float, vecN, and matN alike — to its own [[buffer(N)]] slot. Two caps
    // apply on iOS:
    //  - Devices reject more than 31 declarations at MSL compile time
    //    ("'buffer' attribute parameter is out of bounds: must be between 0
    //    and 30") — the runtime effect never builds.
    //  - The iOS *Simulator* additionally rejects more than 14 at pipeline
    //    creation ("only 14 constant buffers binding are supported in the
    //    simulator") — the shader draws nothing there.
    // A mat4 costs one slot but carries 16 floats, so scalars are packed into
    // vec4/mat4 declarations with #define aliases and an unchanged flat float
    // order (Dart writers untouched) — see fur_planar*.frag and
    // iridescent_liquid*.frag. Keep new shaders within the Simulator cap.
    const deviceCap = 31;
    const simulatorCap = 14;
    // Pre-existing shaders over the Simulator cap (fine on devices; on the
    // iOS Simulator the pipeline fails and can crash the app — verified with
    // marble_smear, 2026-06-11). Pack one the same way to remove its entry;
    // don't add new ones.
    const overSimulatorCap = <String>{
      'fbm_gradient.frag',
      'gritty_gradient.frag',
      'liquid_patina.frag',
      'marble_smear.frag',
      'metal_smoke.frag',
      'perlin_gradient.frag',
      'radial_fbm_gradient.frag',
      'radial_gritty_gradient.frag',
      'radial_perlin_gradient.frag',
      'radial_simplex_gradient.frag',
      'radial_turbulence_gradient.frag',
      'radial_voronoi_gradient.frag',
      'radial_voronoise_gradient.frag',
      'simplex_gradient.frag',
      'turbulence_gradient.frag',
      'voronoi_gradient.frag',
      'voronoise_gradient.frag',
    };
    final decl = RegExp(r'^\s*uniform\s+(?!sampler)', multiLine: true);
    final offenders = <String>[];
    for (final f in Directory('../lib/shaders')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.frag'))) {
      final name = f.uri.pathSegments.last;
      final n = decl.allMatches(f.readAsStringSync()).length;
      if (n > deviceCap) {
        offenders.add('$name ($n declarations — broken on iOS devices)');
      } else if (n > simulatorCap && !overSimulatorCap.contains(name)) {
        offenders.add('$name ($n declarations — fails on the iOS Simulator)');
      } else if (n <= simulatorCap && overSimulatorCap.contains(name)) {
        offenders.add('$name ($n declarations — stale overSimulatorCap entry)');
      }
    }
    expect(offenders, isEmpty,
        reason: 'shaders violating Metal buffer caps: $offenders');
  });
}
