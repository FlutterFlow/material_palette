import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

// ============ TAPPABLE SHADER TYPE ============

enum _TappableType { burn, smoke, pixelDissolve }

extension _TappableTypeLabel on _TappableType {
  String get label {
    switch (this) {
      case _TappableType.burn:
        return 'Burn';
      case _TappableType.smoke:
        return 'Smoke';
      case _TappableType.pixelDissolve:
        return 'Pixel Dissolve';
    }
  }
}

// ============ CURVE ENTRIES ============

class _CurveEntry {
  final String name;
  final Curve curve;

  const _CurveEntry(this.name, this.curve);
}

const _curveEntries = <_CurveEntry>[
  _CurveEntry('linear', Curves.linear),
  _CurveEntry('easeIn', Curves.easeIn),
  _CurveEntry('easeInOut', Curves.easeInOut),
  _CurveEntry('easeOut', Curves.easeOut),
  _CurveEntry('bounce', Curves.bounceOut),
  _CurveEntry('elastic', Curves.elasticInOut),
];

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
                'Tap to interact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.8)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tappable Shader Demo',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  shadows: [
                    Shadow(
                        blurRadius: 6,
                        color: Colors.black.withValues(alpha: 0.8)),
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

// ============ TAPPABLE DEMO PAGE ============

class TappableDemoPage extends StatefulWidget {
  const TappableDemoPage({super.key});

  @override
  State<TappableDemoPage> createState() => _TappableDemoPageState();
}

class _TappableDemoPageState extends State<TappableDemoPage> {
  _TappableType _shaderType = _TappableType.burn;
  int _curveIndex = 0; // linear
  double _durationSec = 1.5;
  double _delaySec = 0.0;
  bool _reverse = true;
  bool _invert = false;
  bool _persistTaps = false;
  double _rangeStart = 0.0;
  double _rangeEnd = 1.0;

  late ShaderParams _currentParams;
  late ShaderDefinition _definition;

  // Key to force remount when shader type changes
  int _shaderKey = 0;

  @override
  void initState() {
    super.initState();
    _definition = _getDefinition(_shaderType);
    _currentParams = _definition.defaults;
  }

  ShaderDefinition _getDefinition(_TappableType type) {
    switch (type) {
      case _TappableType.burn:
        return tappableBurnShaderDef;
      case _TappableType.smoke:
        return tappableSmokeShaderDef;
      case _TappableType.pixelDissolve:
        return tappablePixelDissolveShaderDef;
    }
  }

  void _onTypeChanged(_TappableType type) {
    setState(() {
      _shaderType = type;
      _definition = _getDefinition(type);
      _currentParams = _definition.defaults;
      _shaderKey++;
    });
  }

  void _resetParams() {
    setState(() {
      _currentParams = _definition.defaults;
      _shaderKey++;
    });
  }

  ShaderAnimationConfig _buildTapConfig() {
    return ShaderAnimationConfig(
      curve: _curveEntries[_curveIndex].curve,
      duration: Duration(milliseconds: (_durationSec * 1000).round()),
      delay: Duration(milliseconds: (_delaySec * 1000).round()),
      reverse: _reverse,
      invert: _invert,
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
    );
  }

  Widget _buildShaderWidget(double width, double height) {
    final child = _buildDemoContent(width, height);
    final tapConfig = _buildTapConfig();
    switch (_shaderType) {
      case _TappableType.burn:
        return TappableBurnShaderWrap(
          key: ValueKey('burn_$_shaderKey'),
          params: _currentParams,
          tapConfig: tapConfig,
          persistTaps: _persistTaps,
          child: child,
        );
      case _TappableType.smoke:
        return TappableSmokeShaderWrap(
          key: ValueKey('smoke_$_shaderKey'),
          params: _currentParams,
          tapConfig: tapConfig,
          persistTaps: _persistTaps,
          child: child,
        );
      case _TappableType.pixelDissolve:
        return TappablePixelDissolveShaderWrap(
          key: ValueKey('pixel_$_shaderKey'),
          params: _currentParams,
          tapConfig: tapConfig,
          persistTaps: _persistTaps,
          child: child,
        );
    }
  }

  void _rebuild() {
    setState(() => _shaderKey++);
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);
    final ranges = _definition.uiDefaults.ranges;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Tappable Shaders Demo'),
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
                child:
                    _buildShaderWidget(dimensions.width, dimensions.height),
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
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ControlSectionTitle('Shader Type'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _TappableType.values.map((type) {
                        final selected = type == _shaderType;
                        return ChoiceChip(
                          label: Text(type.label,
                              style: const TextStyle(fontSize: 11)),
                          selected: selected,
                          onSelected: (_) => _onTypeChanged(type),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),
                    const ControlSectionTitle('Tap Curve'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_curveEntries.length, (i) {
                        final selected = i == _curveIndex;
                        return ChoiceChip(
                          label: Text(_curveEntries[i].name,
                              style: const TextStyle(fontSize: 11)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _curveIndex = i;
                              _shaderKey++;
                            });
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
                      min: 0.2,
                      max: 5.0,
                      onChanged: (v) {
                        _durationSec = v;
                        _rebuild();
                      },
                    ),
                    ControlSlider(
                      label: 'Delay (s)',
                      value: _delaySec,
                      min: 0.0,
                      max: 2.0,
                      onChanged: (v) {
                        _delaySec = v;
                        _rebuild();
                      },
                    ),

                    const SizedBox(height: 20),
                    const ControlSectionTitle('Playback'),
                    SwitchListTile(
                      title: const Text('Reverse (expand & contract)',
                          style: TextStyle(fontSize: 13)),
                      value: _reverse,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        _reverse = v;
                        _rebuild();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Invert',
                          style: TextStyle(fontSize: 13)),
                      value: _invert,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        _invert = v;
                        _rebuild();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Persist taps',
                          style: TextStyle(fontSize: 13)),
                      subtitle: const Text(
                          'Keep taps until buffer wraps',
                          style: TextStyle(fontSize: 11, color: Colors.white54)),
                      value: _persistTaps,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        _persistTaps = v;
                        _rebuild();
                      },
                    ),

                    const SizedBox(height: 20),
                    const ControlSectionTitle('Range'),
                    ControlSlider(
                      label: 'Start',
                      value: _rangeStart,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) {
                        _rangeStart = v;
                        _rebuild();
                      },
                    ),
                    ControlSlider(
                      label: 'End',
                      value: _rangeEnd,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) {
                        _rangeEnd = v;
                        _rebuild();
                      },
                    ),

                    const SizedBox(height: 20),
                    if (ranges.isNotEmpty) ...[
                      const ControlSectionTitle('Shader Parameters'),
                      for (final entry in ranges.entries)
                        ControlSlider.fromRange(
                          range: entry.value,
                          value: _currentParams.get(entry.key),
                          onChanged: (v) {
                            setState(() {
                              _currentParams =
                                  _currentParams.withValue(entry.key, v);
                            });
                          },
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Color pickers
                    if (_currentParams.colors.isNotEmpty) ...[
                      const ControlSectionTitle('Colors'),
                      for (final entry in _currentParams.colors.entries)
                        ControlColorPicker(
                          label: entry.key,
                          color: entry.value,
                          onChanged: (c) {
                            setState(() {
                              _currentParams =
                                  _currentParams.withColor(entry.key, c);
                            });
                          },
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Reset button
                    Center(
                      child: TextButton.icon(
                        onPressed: _resetParams,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset to Defaults'),
                      ),
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
