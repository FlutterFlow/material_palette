// ignore_for_file: avoid_print -- console output is this tool's deliverable.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'bench_configs.dart';

/// Deterministic config snapshots for visual review.
///
/// Mounts each config at fixed *virtual* times (same clock the matrix and
/// BENCH_COMPARE use), lets the child-capture pipeline settle for a few
/// frames, then captures the RepaintBoundary and writes a PNG. Because the
/// uniforms are a pure function of virtual time, two configs snapped at the
/// same `t` are exactly comparable — and runs are reproducible bit-for-bit.
/// Writes into the app container's temp dir (the bench app is sandboxed)
/// and prints each absolute path.
class BenchSnapshot extends StatefulWidget {
  const BenchSnapshot({
    super.key,
    required this.configs,
    required this.times,
  });

  final List<BenchConfig> configs;
  final List<double> times;

  @override
  State<BenchSnapshot> createState() => _BenchSnapshotState();
}

class _BenchSnapshotState extends State<BenchSnapshot> {
  final GlobalKey _boundary = GlobalKey();
  late final Directory _outDir;
  int _job = 0;
  int _settleFrames = 0;

  /// Frames pumped before capture so AnimatedSampler's child capture and
  /// shader warmup have flushed through.
  static const int _kSettle = 20;

  int get _jobCount => widget.configs.length * widget.times.length;
  bool get _done => _job >= _jobCount;
  BenchConfig get _config => widget.configs[_job ~/ widget.times.length];
  double get _t => widget.times[_job % widget.times.length];

  @override
  void initState() {
    super.initState();
    _outDir = Directory(
        '${Directory.systemTemp.path}/bench_snapshots_${DateTime.now().millisecondsSinceEpoch}')
      ..createSync(recursive: true);
    print('[snapshot] writing to ${_outDir.path}');
    WidgetsBinding.instance.addPostFrameCallback(_tick);
  }

  Future<void> _tick(Duration _) async {
    if (!mounted || _done) return;
    if (_settleFrames < _kSettle) {
      setState(() => _settleFrames++);
      WidgetsBinding.instance.addPostFrameCallback(_tick);
      return;
    }

    final boundary = _boundary.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${_outDir.path}/'
        '${_config.id.replaceAll('.', '_')}__t${_t.toStringAsFixed(1)}.png');
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    print('[snapshot] wrote ${file.path} (${image.width}x${image.height})');
    image.dispose();

    setState(() {
      _job++;
      _settleFrames = 0;
    });
    if (_done) {
      print('SNAPSHOT COMPLETE ($_jobCount files in ${_outDir.path})');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      exit(0);
    }
    WidgetsBinding.instance.addPostFrameCallback(_tick);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final size = _config.size ?? kStdSize;
    return Scaffold(
      backgroundColor: const Color(0xFF15171B),
      body: Center(
        child: RepaintBoundary(
          key: _boundary,
          child: SizedBox(
            width: size.width,
            height: size.height,
            // Fixed virtual time: the widget is rebuilt every settle frame
            // with the same t, so animation state is frozen deterministically.
            child: _config.builder(_t, size),
          ),
        ),
      ),
    );
  }
}
