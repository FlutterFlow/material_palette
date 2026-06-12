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
}
