import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'bench_configs.dart';

/// Side-by-side visual comparison of two bench configs.
///
/// Both panes are driven by the SAME virtual-time frame counter, so the
/// shaders stay perfectly in sync (uniform trajectories are identical) even
/// if the combined GPU load drops the frame rate. Runs forever; quit with q.
class BenchCompare extends StatefulWidget {
  const BenchCompare({super.key, required this.left, required this.right});

  final BenchConfig left;
  final BenchConfig right;

  @override
  State<BenchCompare> createState() => _BenchCompareState();
}

class _BenchCompareState extends State<BenchCompare>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() => _frame++))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Widget _pane(BenchConfig config, double t) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  config.notes,
                  style: const TextStyle(color: Color(0xFF8A93A6), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                return SizedBox(
                  width: size.width,
                  height: size.height,
                  child: config.builder(t, size),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _frame / 60.0;
    return Scaffold(
      backgroundColor: const Color(0xFF15171B),
      body: Row(
        children: [
          _pane(widget.left, t),
          Container(width: 2, color: const Color(0xFF30343B)),
          _pane(widget.right, t),
        ],
      ),
    );
  }
}
