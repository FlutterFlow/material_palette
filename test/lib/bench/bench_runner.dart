import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'bench_configs.dart';
import 'bench_stats.dart';

/// Frames per phase. Virtual time advances 1/60 s per produced frame, so the
/// measure window is ~6 s of virtual time regardless of refresh rate.
const int kSettleFrames = 30;
const int kWarmupFrames = 90;
const int kMeasureFrames = 360;

enum _Phase { settle, warmup, measure, hold, done }

class BenchRunner extends StatefulWidget {
  const BenchRunner({
    super.key,
    required this.configs,
    required this.repeat,
    this.holdId,
    required this.onComplete,
  });

  final List<BenchConfig> configs;
  final int repeat;

  /// When set, mounts this config and loops virtual time forever
  /// (for Xcode GPU capture / Instruments).
  final String? holdId;

  final void Function(List<BenchResult> results, BenchEnvironment env)
      onComplete;

  @override
  State<BenchRunner> createState() => _BenchRunnerState();
}

class BenchEnvironment {
  double refreshRate = 0;
  double dpr = 0;
  Size windowSize = Size.zero;

  double get vsyncBudgetMs => refreshRate > 1 ? 1000.0 / refreshRate : 1000.0 / 60.0;
}

class _BenchRunnerState extends State<BenchRunner>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<FrameTiming> _timings = [];
  final List<BenchResult> _results = [];
  final BenchEnvironment _env = BenchEnvironment();

  _Phase _phase = _Phase.settle;
  int _phaseFrame = 0;
  int _frame = 0; // virtual-time frame counter, reset per config
  int _configIndex = 0;
  int _runIndex = 0;
  Size _resolvedSize = Size.zero;

  BenchConfig? get _config {
    if (widget.holdId != null) {
      return widget.configs.where((c) => c.id == widget.holdId).firstOrNull;
    }
    if (_configIndex >= widget.configs.length) return null;
    return widget.configs[_configIndex];
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    if (widget.holdId != null) {
      _phase = _Phase.hold;
    }
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_phase == _Phase.measure || _phase == _Phase.hold) {
      _timings.addAll(timings);
    }
  }

  void _onTick(Duration elapsed) {
    if (_phase == _Phase.done) return;
    setState(() {
      _frame++;
      _phaseFrame++;
      switch (_phase) {
        case _Phase.settle:
          if (_phaseFrame >= kSettleFrames) {
            _phase = _Phase.warmup;
            _phaseFrame = 0;
            _frame = 0; // virtual time restarts for every config
          }
        case _Phase.warmup:
          if (_phaseFrame >= kWarmupFrames) {
            _phase = _Phase.measure;
            _phaseFrame = 0;
            _timings.clear();
          }
        case _Phase.measure:
          if (_phaseFrame >= kMeasureFrames) {
            _recordResult();
            _advance();
          }
        case _Phase.hold:
          // Periodic line so external GPU samplers can correlate achieved
          // fps / raster time with their own utilization readings.
          if (_phaseFrame % 600 == 0 && _timings.length > 20) {
            final r = summarize(
              id: _config?.id ?? 'hold',
              notes: '',
              runIndex: 0,
              timings: List.of(_timings),
              vsyncBudgetMs: _env.vsyncBudgetMs,
              dpr: _env.dpr,
              logicalW: _resolvedSize.width,
              logicalH: _resolvedSize.height,
            );
            // ignore: avoid_print -- machine-readable hold-mode telemetry.
            print('[hold] id=${r.id} fps=${r.fps.toStringAsFixed(1)} '
                'raster_p50=${r.raster.p50.toStringAsFixed(2)} '
                'raster_p90=${r.raster.p90.toStringAsFixed(2)}');
            _timings.clear();
          }
        case _Phase.done:
          break;
      }
    });
  }

  void _recordResult() {
    final config = _config!;
    _results.add(summarize(
      id: config.id,
      notes: config.notes,
      runIndex: _runIndex,
      timings: List.of(_timings),
      vsyncBudgetMs: _env.vsyncBudgetMs,
      dpr: _env.dpr,
      logicalW: _resolvedSize.width,
      logicalH: _resolvedSize.height,
    ));
    _timings.clear();
    final done = _results.length;
    final total = widget.configs.length * widget.repeat;
    debugPrint('[bench] $done/$total ${config.id} '
        'raster p50=${_results.last.raster.p50.toStringAsFixed(2)}ms '
        'p90=${_results.last.raster.p90.toStringAsFixed(2)}ms '
        'fps=${_results.last.fps.toStringAsFixed(0)}');
  }

  void _advance() {
    _phase = _Phase.settle;
    _phaseFrame = 0;
    _configIndex++;
    if (_configIndex >= widget.configs.length) {
      _runIndex++;
      if (_runIndex >= widget.repeat) {
        _phase = _Phase.done;
        _ticker.stop();
        widget.onComplete(_results, _env);
      } else {
        _configIndex = 0;
      }
    }
  }

  void _captureEnv(BuildContext context) {
    final view = View.of(context);
    _env
      ..refreshRate = view.display.refreshRate
      ..dpr = view.devicePixelRatio
      ..windowSize = view.physicalSize / view.devicePixelRatio;
  }

  @override
  Widget build(BuildContext context) {
    _captureEnv(context);
    final config = _config;
    final t = _frame / 60.0;

    final showConfig =
        config != null && (_phase != _Phase.settle) && (_phase != _Phase.done);

    return Scaffold(
      backgroundColor: const Color(0xFF15171B),
      body: Stack(
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!showConfig) {
                  return const SizedBox.shrink();
                }
                final size = config.size ?? constraints.biggest;
                _resolvedSize = size;
                return SizedBox(
                  width: size.width,
                  height: size.height,
                  child: config.builder(t, size),
                );
              },
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: IgnorePointer(
              child: Text(
                _phase == _Phase.done
                    ? 'DONE'
                    : '${config?.id ?? "-"}  ${_phase.name}'
                        '  [${_configIndex + 1 + _runIndex * widget.configs.length}'
                        '/${widget.configs.length * widget.repeat}]'
                        '${kDebugMode ? "  ⚠ DEBUG MODE" : ""}',
                style: const TextStyle(
                  color: Color(0xFF8A93A6),
                  fontSize: 11,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
