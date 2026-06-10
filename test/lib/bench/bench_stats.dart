import 'dart:ui' show FrameTiming, FramePhase;

/// Summary statistics for one benchmark config run.
class BenchResult {
  final String id;
  final String notes;
  final int runIndex;
  final int frames;
  final double windowSeconds;
  final double fps;

  // All durations in milliseconds.
  final Stats build;
  final Stats raster;
  final Stats span;

  final double jankPct; // % of frames with totalSpan > 1.5 * vsync budget
  final double headroom; // 1 - p90(raster) / vsync budget
  final double vsyncBudgetMs;
  final double dpr;
  final double logicalW;
  final double logicalH;

  BenchResult({
    required this.id,
    required this.notes,
    required this.runIndex,
    required this.frames,
    required this.windowSeconds,
    required this.fps,
    required this.build,
    required this.raster,
    required this.span,
    required this.jankPct,
    required this.headroom,
    required this.vsyncBudgetMs,
    required this.dpr,
    required this.logicalW,
    required this.logicalH,
  });

  double get physicalMpx => (logicalW * dpr) * (logicalH * dpr) / 1e6;

  /// Median raster cost per physical pixel, in nanoseconds.
  double get nsPerPx =>
      physicalMpx > 0 ? raster.p50 * 1e6 / (physicalMpx * 1e6) * 1000 : 0;

  static String csvHeader() => [
        'run', 'id', 'frames', 'window_s', 'fps',
        'build_avg_ms', 'build_p50_ms', 'build_p90_ms', 'build_p99_ms',
        'raster_avg_ms', 'raster_p50_ms', 'raster_p90_ms', 'raster_p99_ms',
        'span_p50_ms', 'span_p99_ms',
        'jank_pct', 'headroom', 'vsync_budget_ms',
        'dpr', 'logical_w', 'logical_h', 'physical_mpx', 'ns_per_px',
        'notes',
      ].join(',');

  String toCsvRow() => [
        '$runIndex', id, '$frames', windowSeconds.toStringAsFixed(2),
        fps.toStringAsFixed(1),
        build.avg.toStringAsFixed(3), build.p50.toStringAsFixed(3),
        build.p90.toStringAsFixed(3), build.p99.toStringAsFixed(3),
        raster.avg.toStringAsFixed(3), raster.p50.toStringAsFixed(3),
        raster.p90.toStringAsFixed(3), raster.p99.toStringAsFixed(3),
        span.p50.toStringAsFixed(3), span.p99.toStringAsFixed(3),
        jankPct.toStringAsFixed(1), headroom.toStringAsFixed(3),
        vsyncBudgetMs.toStringAsFixed(2),
        dpr.toStringAsFixed(2), logicalW.toStringAsFixed(0),
        logicalH.toStringAsFixed(0), physicalMpx.toStringAsFixed(3),
        nsPerPx.toStringAsFixed(2),
        '"$notes"',
      ].join(',');

  String toMarkdownRow() => '| $id '
      '| ${raster.p50.toStringAsFixed(2)} | ${raster.p90.toStringAsFixed(2)} '
      '| ${raster.p99.toStringAsFixed(2)} | ${build.p50.toStringAsFixed(2)} '
      '| ${fps.toStringAsFixed(0)} | ${(headroom * 100).toStringAsFixed(0)}% '
      '| ${jankPct.toStringAsFixed(0)}% | ${nsPerPx.toStringAsFixed(1)} |';

  static String markdownHeader() =>
      '| id | raster p50 (ms) | raster p90 | raster p99 | build p50 | fps '
      '| headroom | jank | ns/px |\n'
      '|---|---|---|---|---|---|---|---|---|';
}

class Stats {
  final double avg, p50, p90, p99;
  const Stats(this.avg, this.p50, this.p90, this.p99);

  static Stats of(List<double> values) {
    if (values.isEmpty) return const Stats(0, 0, 0, 0);
    final sorted = [...values]..sort();
    double pct(double p) {
      final idx = (p * (sorted.length - 1)).round();
      return sorted[idx];
    }

    final avg = sorted.reduce((a, b) => a + b) / sorted.length;
    return Stats(avg, pct(0.50), pct(0.90), pct(0.99));
  }
}

/// Compute a [BenchResult] from raw frame timings collected in a window.
BenchResult summarize({
  required String id,
  required String notes,
  required int runIndex,
  required List<FrameTiming> timings,
  required double vsyncBudgetMs,
  required double dpr,
  required double logicalW,
  required double logicalH,
}) {
  // Drop edge frames (state-transition slop).
  final trimmed = timings.length > 12
      ? timings.sublist(5, timings.length - 5)
      : timings;

  double ms(Duration d) => d.inMicroseconds / 1000.0;
  final build = trimmed.map((t) => ms(t.buildDuration)).toList();
  final raster = trimmed.map((t) => ms(t.rasterDuration)).toList();
  final span = trimmed.map((t) => ms(t.totalSpan)).toList();

  double windowSeconds = 0;
  if (trimmed.length >= 2) {
    final first =
        trimmed.first.timestampInMicroseconds(FramePhase.buildStart);
    final last = trimmed.last.timestampInMicroseconds(FramePhase.buildStart);
    windowSeconds = (last - first) / 1e6;
  }
  final fps =
      windowSeconds > 0 ? (trimmed.length - 1) / windowSeconds : 0.0;

  final jankCount =
      span.where((s) => s > 1.5 * vsyncBudgetMs).length;
  final rasterStats = Stats.of(raster);

  return BenchResult(
    id: id,
    notes: notes,
    runIndex: runIndex,
    frames: trimmed.length,
    windowSeconds: windowSeconds,
    fps: fps,
    build: Stats.of(build),
    raster: rasterStats,
    span: Stats.of(span),
    jankPct: span.isEmpty ? 0 : 100.0 * jankCount / span.length,
    headroom: 1.0 - rasterStats.p90 / vsyncBudgetMs,
    vsyncBudgetMs: vsyncBudgetMs,
    dpr: dpr,
    logicalW: logicalW,
    logicalH: logicalH,
  );
}
