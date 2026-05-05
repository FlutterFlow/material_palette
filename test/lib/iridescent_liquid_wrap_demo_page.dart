import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

/// Demo page that wraps a very-large "FF" text in the iridescent liquid shader.
///
/// The text is rendered in the same colour the shader is configured to treat
/// as its mask pass colour, so the shader paints the iridescent material
/// inside the letterforms while the rest of the canvas stays transparent.
class IridescentLiquidWrapDemoPage extends StatefulWidget {
  const IridescentLiquidWrapDemoPage({super.key});

  @override
  State<IridescentLiquidWrapDemoPage> createState() =>
      _IridescentLiquidWrapDemoPageState();
}

class _IridescentLiquidWrapDemoPageState
    extends State<IridescentLiquidWrapDemoPage> {
  static const Color _maskColor = Color(0xFFFFFFFF);

  ShaderParams _params = iridescentLiquidWrapShaderDef.defaults
      .withColor('passColor', _maskColor);

  ShaderUIDefaults get _ui => iridescentLiquidWrapShaderDef.uiDefaults;

  int get _stops => _params.get('paletteStops').round().clamp(2, 10);

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Iridescent Liquid Wrap Demo'),
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
                  child: Container(
                    color: const Color(0xFF101218),
                    child: IridescentLiquidShaderWrap(
                      params: _params,
                      child: Center(
                        child: Text(
                          'F',
                          style: TextStyle(
                            color: _params.getColor('passColor'),
                            fontSize: 360,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -16,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
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
                    _slider('contour'),
                    _slider('angleDeg'),
                    _slider('stripeDiagaBias'),
                    _slider('stripeTwist'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Bump'),
                    _slider('bumpRadius'),
                    _slider('bumpExponent'),
                    _slider('bumpShearX'),
                    _slider('bumpShearY'),
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
                    const ControlSectionTitle('Mask'),
                    ControlColorPicker(
                      label: 'Pass Color',
                      color: _params.getColor('passColor'),
                      onChanged: (c) => setState(() =>
                          _params = _params.withColor('passColor', c)),
                    ),
                    _slider('edgeBandPx'),
                    _slider('edgeSmoothness'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Composition'),
                    ControlColorPicker(
                      label: 'Backdrop',
                      color: _params.getColor('colorBack'),
                      onChanged: (c) => setState(() =>
                          _params = _params.withColor('colorBack', c)),
                    ),
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
                      onPressed: () => setState(() => _params =
                          iridescentLiquidWrapShaderDef.defaults
                              .withColor('passColor', _maskColor)),
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
