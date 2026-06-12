import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

/// Smoke check for the four uniform-heavy shaders that exceed(ed) iOS Metal's
/// buffer-slot limits (31 on device, 14 on the simulator). Run on a simulator
/// or device:
///
///   flutter run -t lib/main_shader_smoke.dart
///
/// All four tiles must render, with no `ImpellerValidationBreak` /
/// "Failed to build runtime effect" / "constant buffers" lines in the logs.
void main() => runApp(const ShaderSmokeApp());

/// When non-null, only the tile with this label is mounted — handy for
/// isolating one shader (a failing pipeline can crash the whole app).
const String? _only = null;

class ShaderSmokeApp extends StatelessWidget {
  const ShaderSmokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <String, Widget Function()>{
      'Fur (fill)': () => FurPlanarShaderFill(width: 160, height: 160),
      'Fur Mask (wrap)': () => FurPlanarMaskShaderWrap(
            child: Container(width: 160, height: 160, color: Colors.black),
          ),
      'Iridescent Liquid Fill': () =>
          IridescentLiquidShaderFill(width: 160, height: 160),
      'Iridescent Liquid (wrap)': () => IridescentLiquidShaderWrap(
            child: const SizedBox(
              width: 160,
              height: 160,
              child: Center(
                child: Text(
                  'IRIDESCENT',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF202024),
        body: SafeArea(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(12),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final e in tiles.entries)
                if (_only == null || e.key == _only) _tile(e.key, e.value()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String label, Widget shader) {
    return Column(
      children: [
        Expanded(child: Center(child: shader)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
