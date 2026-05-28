import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

/// Demo page for the (non-wrap) iridescent liquid fill shader. Renders the
/// pattern across a fixed rectangle and exposes every uniform — including
/// the full palette — as live controls.
class IridescentLiquidDemoPage extends StatefulWidget {
  const IridescentLiquidDemoPage({super.key});

  @override
  State<IridescentLiquidDemoPage> createState() =>
      _IridescentLiquidDemoPageState();
}

class _IridescentLiquidDemoPageState extends State<IridescentLiquidDemoPage> {
  ShaderParams _params = iridescentLiquidShaderDef.defaults;

  ShaderUIDefaults get _ui => iridescentLiquidShaderDef.uiDefaults;

  int get _stops => _params.get('paletteStops').round().clamp(2, 10);

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Iridescent Liquid Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 480,
                height: 640,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(kShaderCardBorderRadius),
                  child: IridescentLiquidShaderFill(
                    width: 480,
                    height: 640,
                    params: _params,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: dimensions.controlsWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D23),
              border: Border(
                left: BorderSide(color: Colors.grey.shade800, width: 1),
              ),
            ),
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ControlSectionTitle('Pattern'),
                    _slider('repetition'),
                    _slider('softness'),
                    _slider('distortion'),
                    _slider('angleDeg'),
                    _slider('stripeDiagaBias'),
                    _slider('stripeTwist'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Stripes'),
                    _slider('stripeCount'),
                    _slider('stripeThickness'),
                    _slider('stripeOffset'),
                    _slider('stripeFalloff'),
                    _slider('stripeSpeed'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Domain Warp'),
                    _slider('warpTimeScale'),
                    _slider('warpFreqInner'),
                    _slider('warpFreqMiddle'),
                    _slider('warpFreqHigh'),
                    _slider('fbmScaleFactor'),
                    _slider('stripeRippleStrength'),
                    _slider('bumpWarpWeight'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Chromatic'),
                    _slider('shiftRed'),
                    _slider('shiftBlue'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Composition'),
                    ControlColorPicker(
                      label: 'Tint',
                      color: _params.getColor('colorTint'),
                      onChanged: (c) => setState(() =>
                          _params = _params.withColor('colorTint', c)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Palette'),
                    _intSlider('paletteStops'),
                    for (int i = 0; i < _stops; i++)
                      ControlColorPicker(
                        label: 'Stop $i',
                        color: _params.getColor('color$i'),
                        onChanged: (c) => setState(() =>
                            _params = _params.withColor('color$i', c)),
                      ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() =>
                          _params = iridescentLiquidShaderDef.defaults),
                      child: const Text('Reset'),
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

  Widget _slider(String key) => ControlSlider.fromRange(
        range: _ui[key]!,
        value: _params.get(key),
        onChanged: (v) => setState(() => _params = _params.withValue(key, v)),
      );

  Widget _intSlider(String key) => ControlSlider.fromRange(
        range: _ui[key]!,
        value: _params.get(key),
        onChanged: (v) => setState(
            () => _params = _params.withValue(key, v.roundToDouble())),
      );
}
