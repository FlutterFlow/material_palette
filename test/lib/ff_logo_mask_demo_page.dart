import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

/// Demo that uses a black-on-white logo mask to drive two shader wraps at once:
/// the fur shader grows on the white pixels (the background of the mask), and
/// the iridescent liquid shader paints the black pixels (the logo shape).
///
/// Both wraps capture the same image as their child. The iridescent layer is
/// at the bottom and the fur layer sits on top of it; the fur shader's new
/// `uBgOpacity = 0` setting makes the non-mask area transparent so the
/// iridescent layer below shows through the logo cutout.
class FfLogoMaskDemoPage extends StatefulWidget {
  const FfLogoMaskDemoPage({super.key});

  @override
  State<FfLogoMaskDemoPage> createState() => _FfLogoMaskDemoPageState();
}

class _FfLogoMaskDemoPageState extends State<FfLogoMaskDemoPage> {
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);

  ShaderParams _furParams = furPlanarMaskedShaderDef.defaults
      .copyWith(
        values: {
          ...furPlanarMaskedShaderDef.defaults.values,
          'bgOpacity': 0.0,
        },
        colors: {
          ...furPlanarMaskedShaderDef.defaults.colors,
          'maskColor': _white,
        },
      );

  ShaderParams _iridParams = iridescentLiquidWrapShaderDef.defaults
      .withColor('passColor', _black);

  ShaderUIDefaults get _furUi => furPlanarMaskedShaderDef.uiDefaults;
  ShaderUIDefaults get _iridUi => iridescentLiquidWrapShaderDef.uiDefaults;

  Widget _maskImage() => Image.asset(
        'assets/images/ff_logo_mask.png',
        fit: BoxFit.contain,
      );

  Widget _furSlider(String key) => ControlSlider.fromRange(
        range: _furUi[key]!,
        value: _furParams.get(key),
        onChanged: (v) =>
            setState(() => _furParams = _furParams.withValue(key, v)),
      );

  Widget _iridSlider(String key) => ControlSlider.fromRange(
        range: _iridUi[key]!,
        value: _iridParams.get(key),
        onChanged: (v) =>
            setState(() => _iridParams = _iridParams.withValue(key, v)),
      );

  static String _formatNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toStringAsFixed(2);

  static String _formatColor(Color c) {
    final a = c.a;
    final aStr =
        a == 1.0 ? '1' : a == 0.0 ? '0' : a.toStringAsFixed(2);
    return 'Color.fromRGBO('
        '${(c.r * 255).round().clamp(0, 255)}, '
        '${(c.g * 255).round().clamp(0, 255)}, '
        '${(c.b * 255).round().clamp(0, 255)}, '
        '$aStr)';
  }

  static String _paramsToDart(ShaderParams p) {
    final sb = StringBuffer('ShaderParams(\n  values: {\n');
    for (final e in p.values.entries) {
      sb.writeln("    '${e.key}': ${_formatNum(e.value)},");
    }
    sb.write('  },\n  colors: {\n');
    for (final e in p.colors.entries) {
      sb.writeln("    '${e.key}': ${_formatColor(e.value)},");
    }
    sb.write('  },\n)');
    return sb.toString();
  }

  Future<void> _exportSettings() async {
    final out = StringBuffer()
      ..writeln('// Fur params')
      ..writeln(_paramsToDart(_furParams))
      ..writeln()
      ..writeln('// Iridescent params')
      ..writeln(_paramsToDart(_iridParams));
    await Clipboard.setData(ClipboardData(text: out.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetAll() {
    setState(() {
      _furParams = furPlanarMaskedShaderDef.defaults.copyWith(
        values: {
          ...furPlanarMaskedShaderDef.defaults.values,
          'bgOpacity': 0.0,
        },
        colors: {
          ...furPlanarMaskedShaderDef.defaults.colors,
          'maskColor': _white,
        },
      );
      _iridParams = iridescentLiquidWrapShaderDef.defaults
          .withColor('passColor', _black);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('FF Logo Mask Demo'),
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
                width: 520,
                height: 520,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Bottom: iridescent paints over black logo pixels.
                    IridescentLiquidShaderWrap(
                      params: _iridParams,
                      child: _maskImage(),
                    ),
                    // Top: fur grows on white pixels. uBgOpacity=0 keeps the
                    // non-mask area transparent so iridescent shows through.
                    FurPlanarMaskShaderWrap(
                      params: _furParams,
                      child: _maskImage(),
                    ),
                  ],
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
                    // ── Fur layer (top, on white) ────────────────────────
                    const ControlSectionTitle('Fur — Mask & Stacking'),
                    _furSlider('bgOpacity'),
                    _furSlider('maskThreshold'),
                    _furSlider('edgeLeanStrength'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Fur — Properties'),
                    _furSlider('planeOffset'),
                    _furSlider('furThickness'),
                    _furSlider('furNoiseStrength'),
                    _furSlider('furNoiseScale'),
                    ControlColorPicker(
                      label: 'Fur Color',
                      color: _furParams.getColor('furColor'),
                      onChanged: (c) => setState(() =>
                          _furParams = _furParams.withColor('furColor', c)),
                    ),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Fur — Animation'),
                    _furSlider('furWaveAmplitude'),
                    _furSlider('furAnimationSpeed'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Fur — Lighting'),
                    _furSlider('keyLightIntensity'),
                    _furSlider('fillLightIntensity'),
                    _furSlider('rimLightIntensity'),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),

                    // ── Iridescent layer (bottom, on black) ───────────────
                    const ControlSectionTitle('Iridescent — Pattern'),
                    _iridSlider('repetition'),
                    _iridSlider('softness'),
                    _iridSlider('distortion'),
                    _iridSlider('contour'),
                    _iridSlider('angleDeg'),
                    _iridSlider('stripeDiagaBias'),
                    _iridSlider('stripeTwist'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Iridescent — Stripes'),
                    _iridSlider('stripeCount'),
                    _iridSlider('stripeThickness'),
                    _iridSlider('stripeOffset'),
                    _iridSlider('stripeFalloff'),
                    _iridSlider('stripeSpeed'),
                    _iridSlider('stripeRippleStrength'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Iridescent — Chromatic'),
                    _iridSlider('shiftRed'),
                    _iridSlider('shiftBlue'),
                    const SizedBox(height: 12),
                    const ControlSectionTitle('Iridescent — Edge'),
                    _iridSlider('edgeBandPx'),
                    _iridSlider('edgeSmoothness'),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _resetAll,
                            child: const Text('Reset Both'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportSettings,
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Export'),
                          ),
                        ),
                      ],
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
