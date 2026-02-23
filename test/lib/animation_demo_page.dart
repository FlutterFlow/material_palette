import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

// ============ CURVE REGISTRY ============

class _CurveEntry {
  final String name;
  final ShaderAnimation Function({
    required Duration duration,
    required Duration delay,
    required bool loop,
    required bool reverse,
  }) factory;

  const _CurveEntry(this.name, this.factory);
}

final _curveEntries = <_CurveEntry>[
  _CurveEntry('linear', ({required duration, required delay, required loop, required reverse}) =>
      ShaderAnimation.linear(duration: duration, delay: delay, loop: loop, reverse: reverse)),
  _CurveEntry('easeIn', ({required duration, required delay, required loop, required reverse}) =>
      ShaderAnimation.easeIn(duration: duration, delay: delay, loop: loop, reverse: reverse)),
  _CurveEntry('easeInOut', ({required duration, required delay, required loop, required reverse}) =>
      ShaderAnimation.easeInOut(duration: duration, delay: delay, loop: loop, reverse: reverse)),
  _CurveEntry('easeOut', ({required duration, required delay, required loop, required reverse}) =>
      ShaderAnimation.easeOut(duration: duration, delay: delay, loop: loop, reverse: reverse)),
  _CurveEntry('bounce', ({required duration, required delay, required loop, required reverse}) =>
      ShaderAnimation.bounce(duration: duration, delay: delay, loop: loop, reverse: reverse)),
  _CurveEntry('elastic', ({required duration, required delay, required loop, required reverse}) =>
      ShaderAnimation.elastic(duration: duration, delay: delay, loop: loop, reverse: reverse)),
  _CurveEntry('elasticOut', ({required duration, required delay, required loop, required reverse}) =>
      ShaderAnimation.elasticOut(duration: duration, delay: delay, loop: loop, reverse: reverse)),
  _CurveEntry('elasticIn', ({required duration, required delay, required loop, required reverse}) =>
      ShaderAnimation.elasticIn(duration: duration, delay: delay, loop: loop, reverse: reverse)),
  _CurveEntry('easeInOutQuint', ({required duration, required delay, required loop, required reverse}) =>
      ShaderAnimation.easeInOutQuint(duration: duration, delay: delay, loop: loop, reverse: reverse)),
];

// ============ SHADER TYPE REGISTRY ============

enum _ShaderType { burn, smoke, pixelDissolve, radialBurn, radialSmoke, radialPixelDissolve }

extension _ShaderTypeLabel on _ShaderType {
  String get label {
    switch (this) {
      case _ShaderType.burn: return 'Burn';
      case _ShaderType.smoke: return 'Smoke';
      case _ShaderType.pixelDissolve: return 'Pixel Dissolve';
      case _ShaderType.radialBurn: return 'Radial Burn';
      case _ShaderType.radialSmoke: return 'Radial Smoke';
      case _ShaderType.radialPixelDissolve: return 'Radial Pixel Dissolve';
    }
  }
}

// ============ DEMO CONTENT ============

Widget _buildDemoContent(double width, double height) {
  return SizedBox(
    width: width,
    height: height,
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/earth.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Earth',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.8)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Animation Demo',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  shadows: [
                    Shadow(blurRadius: 6, color: Colors.black.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildShaderWidget({
  required _ShaderType shaderType,
  required ShaderAnimation animation,
  required double width,
  required double height,
}) {
  final child = _buildDemoContent(width, height);
  switch (shaderType) {
    case _ShaderType.burn:
      return BurnShaderWrap(
        animationMode: ShaderAnimationMode.animation,
        animation: animation,
        child: child,
      );
    case _ShaderType.smoke:
      return SmokeShaderWrap(
        animationMode: ShaderAnimationMode.animation,
        animation: animation,
        child: child,
      );
    case _ShaderType.pixelDissolve:
      return PixelDissolveShaderWrap(
        animationMode: ShaderAnimationMode.animation,
        animation: animation,
        child: child,
      );
    case _ShaderType.radialBurn:
      return RadialBurnShaderWrap(
        animationMode: ShaderAnimationMode.animation,
        animation: animation,
        child: child,
      );
    case _ShaderType.radialSmoke:
      return RadialSmokeShaderWrap(
        animationMode: ShaderAnimationMode.animation,
        animation: animation,
        child: child,
      );
    case _ShaderType.radialPixelDissolve:
      return RadialPixelDissolveShaderWrap(
        animationMode: ShaderAnimationMode.animation,
        animation: animation,
        child: child,
      );
  }
}

// ============ ANIMATION DEMO PAGE ============

class AnimationDemoPage extends StatefulWidget {
  const AnimationDemoPage({super.key});

  @override
  State<AnimationDemoPage> createState() => _AnimationDemoPageState();
}

class _AnimationDemoPageState extends State<AnimationDemoPage> {
  _ShaderType _shaderType = _ShaderType.burn;
  int _curveIndex = 2; // easeInOut
  double _durationSec = 3.0;
  double _delaySec = 0.0;
  bool _loop = true;
  bool _reverse = true;

  // Track a key to force rebuild when animation params change
  int _animKey = 0;

  ShaderAnimation _buildAnimation() {
    return _curveEntries[_curveIndex].factory(
      duration: Duration(milliseconds: (_durationSec * 1000).round()),
      delay: Duration(milliseconds: (_delaySec * 1000).round()),
      loop: _loop,
      reverse: _reverse,
    );
  }

  void _rebuild() {
    setState(() => _animKey++);
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Animation Curves Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          // Preview
          Expanded(
            child: Center(
              child: ShaderCardContent(
                width: dimensions.width,
                height: dimensions.height,
                child: KeyedSubtree(
                  key: ValueKey(_animKey),
                  child: _buildShaderWidget(
                    shaderType: _shaderType,
                    animation: _buildAnimation(),
                    width: dimensions.width,
                    height: dimensions.height,
                  ),
                ),
              ),
            ),
          ),

          // Controls panel
          Container(
            width: dimensions.controlsWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D23),
              border: Border(
                left: BorderSide(color: Colors.grey.shade800, width: 1),
              ),
            ),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ControlSectionTitle('Shader Type'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _ShaderType.values.map((type) {
                        final selected = type == _shaderType;
                        return ChoiceChip(
                          label: Text(type.label, style: const TextStyle(fontSize: 11)),
                          selected: selected,
                          onSelected: (_) {
                            _shaderType = type;
                            _rebuild();
                          },
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),
                    const ControlSectionTitle('Curve'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_curveEntries.length, (i) {
                        final selected = i == _curveIndex;
                        return ChoiceChip(
                          label: Text(_curveEntries[i].name, style: const TextStyle(fontSize: 11)),
                          selected: selected,
                          onSelected: (_) {
                            _curveIndex = i;
                            _rebuild();
                          },
                          visualDensity: VisualDensity.compact,
                        );
                      }),
                    ),

                    const SizedBox(height: 20),
                    const ControlSectionTitle('Timing'),
                    ControlSlider(
                      label: 'Duration (s)',
                      value: _durationSec,
                      min: 0.5,
                      max: 10.0,
                      onChanged: (v) {
                        _durationSec = v;
                        _rebuild();
                      },
                    ),
                    ControlSlider(
                      label: 'Delay (s)',
                      value: _delaySec,
                      min: 0.0,
                      max: 3.0,
                      onChanged: (v) {
                        _delaySec = v;
                        _rebuild();
                      },
                    ),

                    const SizedBox(height: 20),
                    const ControlSectionTitle('Playback'),
                    SwitchListTile(
                      title: const Text('Loop', style: TextStyle(fontSize: 13)),
                      value: _loop,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        _loop = v;
                        _rebuild();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Reverse (ping-pong)', style: TextStyle(fontSize: 13)),
                      value: _reverse,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        _reverse = v;
                        _rebuild();
                      },
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: FilledButton.icon(
                        onPressed: _rebuild,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Restart Animation'),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const ControlSectionTitle('Side-by-Side Comparison'),
                    _CurveComparisonGrid(
                      shaderType: _shaderType,
                      durationSec: _durationSec,
                      animKey: _animKey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ CURVE COMPARISON GRID ============

class _CurveComparisonGrid extends StatelessWidget {
  const _CurveComparisonGrid({
    required this.shaderType,
    required this.durationSec,
    required this.animKey,
  });

  final _ShaderType shaderType;
  final double durationSec;
  final int animKey;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: (durationSec * 1000).round());
    const thumbWidth = 100.0;
    const thumbHeight = 80.0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _curveEntries.map((entry) {
        final animation = entry.factory(
          duration: duration,
          delay: Duration.zero,
          loop: true,
          reverse: true,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: thumbWidth,
              height: thumbHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: KeyedSubtree(
                  key: ValueKey('${entry.name}_$animKey'),
                  child: _buildShaderWidget(
                    shaderType: shaderType,
                    animation: animation,
                    width: thumbWidth,
                    height: thumbHeight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.name,
              style: const TextStyle(fontSize: 9, color: Colors.white54),
            ),
          ],
        );
      }).toList(),
    );
  }
}
