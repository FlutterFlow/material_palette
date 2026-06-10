// ignore_for_file: avoid_print -- console output is this tool's deliverable.

import 'dart:io' show Platform, exit;
import 'dart:ui' show FragmentProgram;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'bench_compare.dart';
import 'bench_configs.dart';
import 'bench_runner.dart';
import 'bench_snapshot.dart';
import 'bench_stats.dart';
import 'bench_survey.dart';

/// Shader benchmark entrypoint.
///
///   flutter run -d macos --profile -t lib/bench/main_bench.dart
///
/// Modes (dart-define, or environment variable for Xcode-launched runs):
///   BENCH_VALIDATE_ONLY=true   precache every shader, print PASS/FAIL, exit
///   BENCH_FILTER=[substring]   run only configs whose id contains it
///   BENCH_HOLD=[configId]      mount one config forever (GPU capture)
///   BENCH_REPEAT=[n]           run the matrix n times
///   BENCH_REVERSE=true         reverse config order (thermal-drift check)
///   BENCH_FULLSIZE=true        re-target every config at the full window
///                              (saturated-throughput mode; ids gain ".fs")

const _dFilter = String.fromEnvironment('BENCH_FILTER');
const _dHold = String.fromEnvironment('BENCH_HOLD');
const _dValidate = String.fromEnvironment('BENCH_VALIDATE_ONLY');
const _dRepeat = String.fromEnvironment('BENCH_REPEAT');
const _dReverse = String.fromEnvironment('BENCH_REVERSE');
const _dFullsize = String.fromEnvironment('BENCH_FULLSIZE');
const _dCompare = String.fromEnvironment('BENCH_COMPARE');
const _dSnapshot = String.fromEnvironment('BENCH_SNAPSHOT');
const _dSnapshotT = String.fromEnvironment('BENCH_SNAPSHOT_T');

String _opt(String defineValue, String envKey) => defineValue.isNotEmpty
    ? defineValue
    : (Platform.environment[envKey] ?? '');

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final filter = _opt(_dFilter, 'BENCH_FILTER');
  final hold = _opt(_dHold, 'BENCH_HOLD');
  // HOLD wins over VALIDATE so an instrumented launch (xctrace) can never
  // fall into validate-and-exit because of a stray environment value.
  final validate =
      hold.isEmpty && _opt(_dValidate, 'BENCH_VALIDATE_ONLY') == 'true';
  final repeat = int.tryParse(_opt(_dRepeat, 'BENCH_REPEAT')) ?? 1;
  final reverse = _opt(_dReverse, 'BENCH_REVERSE') == 'true';
  print('[bench-env] hold="$hold" validateEnv='
      '"${_opt(_dValidate, 'BENCH_VALIDATE_ONLY')}" validateDefine="$_dValidate" '
      'filter="$filter" repeat=$repeat reverse=$reverse');

  var configs = <BenchConfig>[
    ...baseConfigs(),
    ...surveyConfigs(),
    ...prodConfigs(),
    ...variantConfigs(),
  ];

  // Deterministic PNG snapshots: BENCH_SNAPSHOT=<id>[,<id>...] captures each
  // config at the virtual times in BENCH_SNAPSHOT_T (default "2.0", comma-
  // separated seconds), writes PNGs to the sandbox temp dir, prints paths,
  // exits. Same-`t` snapshots of two configs are exactly comparable.
  final snapshot = _opt(_dSnapshot, 'BENCH_SNAPSHOT');
  if (snapshot.isNotEmpty) {
    final ids = snapshot.split(',').map((s) => s.trim()).toList();
    final byId = {for (final c in configs) c.id: c};
    final unknown = ids.where((id) => !byId.containsKey(id)).toList();
    if (unknown.isNotEmpty) {
      print('BENCH_SNAPSHOT error: unknown ids: ${unknown.join(', ')}');
      exit(64);
    }
    final tSpec = _opt(_dSnapshotT, 'BENCH_SNAPSHOT_T');
    final times = (tSpec.isEmpty ? '2.0' : tSpec)
        .split(',')
        .map((s) => double.parse(s.trim()))
        .toList();
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BenchSnapshot(
        configs: [for (final id in ids) byId[id]!],
        times: times,
      ),
    ));
    return;
  }

  // Visual A/B: BENCH_COMPARE=<idLeft>,<idRight> renders two configs
  // side-by-side on the same deterministic clock. Runs forever (q to quit).
  final compare = _opt(_dCompare, 'BENCH_COMPARE');
  if (compare.isNotEmpty) {
    final ids = compare.split(',').map((s) => s.trim()).toList();
    final byId = {for (final c in configs) c.id: c};
    final missing = [
      if (ids.length != 2) 'need exactly two ids, got ${ids.length}',
      for (final id in ids)
        if (!byId.containsKey(id)) 'unknown id "$id"',
    ];
    if (missing.isNotEmpty) {
      print('BENCH_COMPARE error: ${missing.join('; ')}');
      print('Valid ids:');
      for (final id in byId.keys) {
        print('  $id');
      }
      exit(64);
    }
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BenchCompare(left: byId[ids[0]]!, right: byId[ids[1]]!),
    ));
    return;
  }
  if (filter.isNotEmpty) {
    configs = configs.where((c) => c.id.contains(filter)).toList();
  }
  if (reverse) {
    configs = configs.reversed.toList();
  }
  // Full-size mode: re-target every config at the whole window so the GPU
  // saturates. At saturation the GPU clock pins high and achieved fps is a
  // direct throughput measure, immune to the DVFS plateau that makes
  // sub-budget GPU interval durations incomparable.
  if (_opt(_dFullsize, 'BENCH_FULLSIZE') == 'true') {
    configs = [
      for (final c in configs)
        BenchConfig(
          id: '${c.id}.fs',
          size: null,
          notes: c.notes,
          shaderAssets: c.shaderAssets,
          builder: c.builder,
        ),
    ];
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: validate
        ? const _ValidatePage()
        : BenchRunner(
            configs: configs,
            repeat: repeat,
            holdId: hold.isNotEmpty ? hold : null,
            onComplete: _printResults,
          ),
  ));
}

void _printResults(List<BenchResult> results, BenchEnvironment env) {
  // print() (not debugPrint) — debugPrint throttles and drops lines.
  print('');
  print('==== BENCH ENVIRONMENT ====');
  print('mode: ${kReleaseMode ? "release" : kProfileMode ? "profile" : "DEBUG"}');
  print('os: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
  print('refreshRate: ${env.refreshRate.toStringAsFixed(1)} Hz '
      '(vsync budget ${env.vsyncBudgetMs.toStringAsFixed(2)} ms)');
  print('dpr: ${env.dpr}');
  print('window: ${env.windowSize.width.toStringAsFixed(0)}x'
      '${env.windowSize.height.toStringAsFixed(0)} logical');
  print('phases: settle=$kSettleFrames warmup=$kWarmupFrames '
      'measure=$kMeasureFrames frames; virtual time = frame/60');

  if (kDebugMode) {
    print('');
    print('!!!! DEBUG MODE — numbers are invalid; results table suppressed.');
    print('!!!! Re-run with: flutter run -d macos --profile -t lib/bench/main_bench.dart');
    return;
  }

  print('');
  print('==== BENCH RESULTS (markdown) ====');
  print(BenchResult.markdownHeader());
  for (final r in results) {
    print(r.toMarkdownRow());
  }
  print('');
  print('==== BENCH RESULTS (csv) ====');
  print(BenchResult.csvHeader());
  for (final r in results) {
    print(r.toCsvRow());
  }
  print('');
  print('BENCH COMPLETE (${results.length} results)');

  // Give stdout a beat to flush through the flutter tool, then quit so the
  // `flutter run` session ends on its own.
  Future<void>.delayed(const Duration(seconds: 1), () => exit(0));
}

/// Loads every shader program through the real runtime pipeline. This is the
/// only reliable compile check: `flutter build` validates GLSL→SPIR-V but the
/// strict SPIR-V→SkSL transpile only happens at runtime.
class _ValidatePage extends StatefulWidget {
  const _ValidatePage();

  @override
  State<_ValidatePage> createState() => _ValidatePageState();
}

class _ValidatePageState extends State<_ValidatePage> {
  String _status = 'validating…';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final assets = <String>{
      for (final def in shaderDefinitionsByName.values) def.assetPath,
      for (final c in [
        ...baseConfigs(),
        ...surveyConfigs(),
        ...prodConfigs(),
        ...variantConfigs()
      ])
        ...c.shaderAssets,
    }.toList()
      ..sort();

    var failures = 0;
    for (final asset in assets) {
      try {
        await FragmentProgram.fromAsset(asset);
        print('PASS $asset');
      } catch (e) {
        failures++;
        final msg = e.toString().replaceAll('\n', ' | ');
        print('FAIL $asset :: $msg');
      }
    }
    print(failures == 0
        ? 'VALIDATE OK (${assets.length} shaders)'
        : 'VALIDATE FAILED ($failures of ${assets.length})');
    setState(() => _status = failures == 0 ? 'OK' : 'FAILED ($failures)');
    Future<void>.delayed(
        const Duration(seconds: 1), () => exit(failures == 0 ? 0 : 1));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF15171B),
        body: Center(
          child: Text(_status,
              style: const TextStyle(color: Colors.white, fontSize: 24)),
        ),
      );
}
